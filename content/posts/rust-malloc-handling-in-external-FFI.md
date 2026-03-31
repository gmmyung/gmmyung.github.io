---
title: "Rust Malloc Handling in External FFI"
date: 2023-12-30T22:14:18+09:00
slug: 2023-12-30-rust-malloc-handling-in-external-ffi
type: posts
draft: false
categories:
  - Development Log 
tags:
  - Eerie
  - Rust
  - Unsafe
---
# Where this came from
While working on [Eerie](https://github.com/gmmyung/eerie), I ran into a C API that lets the caller pass in an allocator:
```c
// Creates a new session forced to use the given |device|.
// This bypasses any device enumeration performed by the loaded modules but
// the loaded modules will still verify that the device matches their
// requirements.
//
// A base set of modules may be added by the runtime during creation based on
// |options| and users may load additional modules - such as the one containing
// their user code - by using the iree_vm_context_t provided by
// iree_runtime_session_context.
//
// |host_allocator| will be used to allocate the session and any associated
// resources. |out_session| must be released by the caller.
IREE_API_EXPORT iree_status_t iree_runtime_session_create_with_device(
    iree_runtime_instance_t* instance,
    const iree_runtime_session_options_t* options, iree_hal_device_t* device,
    iree_allocator_t host_allocator, iree_runtime_session_t** out_session);
```

At first glance, the obvious answer is to hand it the default C allocator:
```c
// Default C allocator controller using malloc/free.
IREE_API_EXPORT iree_status_t
iree_allocator_system_ctl(void* self, iree_allocator_command_t command,
                          const void* params, void** inout_ptr);
```

That works, but it is not a great fit if the Rust side is using a custom allocator such as [Jemalloc](https://github.com/jemalloc/jemalloc), or if the target is bare metal and there is no comfortable "system allocator" story at all. The [Redis allocator write-up](https://redis.com/blog/using-the-redis-allocator-in-rust/) runs into a similar issue.

My first thought was: fine, just wrap Rust's allocator interface and pass that through. It turned out to be a bit more awkward than that.

## Rust std::alloc::Allocator
Rust's standard library defines allocation like this:
```rust
pub unsafe trait Allocator {
    // Required methods
    fn allocate(&self, layout: Layout) -> Result<NonNull<[u8]>, AllocError>;
    unsafe fn deallocate(&self, ptr: NonNull<u8>, layout: Layout);

    // Provided methods
    // ...
}
```
The struct Layout is defined as:
```rust
pub const fn from_size_align(size: usize, align: usize) -> Result<Self, LayoutError> 
```

The catch is that Rust needs the size and alignment again when deallocating. C APIs usually do not. Once a foreign library hands you back a raw pointer to free, that metadata is gone unless you store it yourself.

There are a couple of ways to deal with that:

1. Keep a side table that maps pointers to allocation sizes.
2. Store the size alongside the allocation itself.

The first option works, but I did not love paying for a global lookup on every free. So I went with the second option.

## Fixing alignment
Appending the size to the end of the block does not help, because the caller only gives you the original pointer back. The size has to live before the pointer.

That immediately creates an alignment problem. IREE expects allocations to follow platform-specific alignment requirements for SIMD-friendly access. If I just shove metadata in front of the returned pointer, I can easily break that alignment.

The fix was to allocate `ALIGNMENT` bytes of extra space, store the size `ALIGNMENT` bytes before the returned pointer, and make sure the pointer I hand back still satisfies the required alignment. The final version looked like this:
```rust
unsafe extern "C" fn rust_allocator_ctl(
    _self_: *mut c_void,
    command: sys::iree_allocator_command_e,
    params: *const c_void,
    inout_ptr: *mut *mut c_void,
) -> sys::iree_status_t {
    // use Rust Global Allocator
    match command {
        sys::iree_allocator_command_e_IREE_ALLOCATOR_COMMAND_MALLOC => {
            let size = (*(params as *const sys::iree_allocator_alloc_params_t)).byte_length;
            if size > std::isize::MAX as usize {
                return Status::from_code(StatusErrorKind::OutOfRange).ctx;
            }
            let ptr = std::alloc::alloc(std::alloc::Layout::from_size_align_unchecked(
                size + ALIGNMENT,
                ALIGNMENT,
            ));
            *(ptr as *mut usize) = size;
            *inout_ptr = ptr.wrapping_add(ALIGNMENT) as *mut c_void;
            std::ptr::null_mut() as *mut c_void as sys::iree_status_t
        }
        sys::iree_allocator_command_e_IREE_ALLOCATOR_COMMAND_FREE => {
            let ptr = (*inout_ptr).wrapping_sub(ALIGNMENT);
            let size = unsafe { *(ptr as *mut usize) };
            std::alloc::dealloc(
                ptr as *mut u8,
                std::alloc::Layout::from_size_align_unchecked(size + ALIGNMENT, ALIGNMENT),
            );
            std::ptr::null_mut() as *mut c_void as sys::iree_status_t
        }
        _ => Status::from_code(StatusErrorKind::Unimplemented).ctx,
    }
}
```

This does add a little overhead, but it is tiny compared to the cost of the allocation itself, and it keeps the allocator boundary explicit instead of relying on allocator mixing by accident.
