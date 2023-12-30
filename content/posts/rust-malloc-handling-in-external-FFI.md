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
# How did I encounter this problem?
While building [Eerie](https://github.com/gmmyung/eerie), a Rust binding for IREE, I encountered a seemingly precarious aspect of a C API:
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
Pass the memory allocator? Sure, we could just use:
```c
// Default C allocator controller using malloc/free.
IREE_API_EXPORT iree_status_t
iree_allocator_system_ctl(void* self, iree_allocator_command_t command,
                          const void* params, void** inout_ptr);
```
However, it feels dubious to interoperate between the Rust allocator and the system default allocator. The Rust user might use custom malloc implementations such as [Jemalloc](https://github.com/jemalloc/jemalloc), or the user might be using an environment such as bare metal, where there is no global allocator at all. This [Redis Dev Blog Article](https://redis.com/blog/using-the-redis-allocator-in-rust/) also encountered a similar problem, and points out similar roadblocks. So, I thought that I could easily solve the problem by writing a wrapper function to the [Rust Allocator](https://doc.rust-lang.org/std/alloc/trait.Allocator.html), but things were a bit more complicated than expected.

## Rust std::alloc::Allocator
Rust's standard library defines the `allocate`/`free` function as
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
This implies that the size and alignment of the memory block should be known at runtime when both allocating and deallocating the memory. In C/C++, this information is not needed when freeing the memory block. There are several ways to overcome this problem. The first one is to maintain a static hashmap that stores all the memory sizes, but this comes with a performance penalty. The second workaround is allocating extra memory to store the size, but it also comes with its own issues.
## Memory alignment fix
If we try to append the memory size to the memory block, it is impossible to retrieve the size from the pointer, since the caller does not know where that size value is located. Thus, the memory size should be prepended to the memory block. Now, here comes another issue. In IREE, all allocated memory blocks should be aligned at a platform-specific value since SIMD operations are affected by alignment. However, it is impossible to allocate a partially aligned value; for example, the memory is offset from 16-byte alignment by 3 bytes, so only addresses such as 0x3, 0x13, 0x23 are possible. The fix is to allocate `ALIGNMENT` bytes more memory and store the size of the value `ALIGNMENT` bytes before the memory block's pointer. Here is the fixed version of the final code:
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
While this solution introduces some overhead, it is minimal compared to the CPU cycles consumed by std::alloc::alloc itself. Problem solved.
