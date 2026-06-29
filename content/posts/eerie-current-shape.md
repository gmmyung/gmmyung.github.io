---
title: "Eerie Reaches v0.5"
date: 2026-06-30T00:00:00+09:00
slug: 2026-06-30-eerie-reaches-v0-5
type: posts
draft: false
categories:
  - Development Log
tags:
  - Eerie
  - Rust
  - IREE
  - Bare Metal
---
# Eerie Reaches v0.5
When I first wrote about [Eerie](https://github.com/gmmyung/eerie), it was still mostly an experiment. The goal was to build Rust bindings around IREE and see whether the compiler/runtime stack could fit naturally into a Rust project.

FFI calls compiling only proved that the C API was reachable from Rust. The harder part was deciding which parts should become safe Rust APIs and which parts should stay behind an unsafe boundary.

Eerie v0.5 is a checkpoint for that design. It is not complete, and I still expect the API to change. The main boundaries are clearer now: where Rust owns the abstraction, where IREE owns global state, and where the unsafe parts need to stay contained.

## A runtime API that looks like Rust
The most visible change is the runtime API. The low-level IREE pieces are still there underneath, but common usage now looks like this:

```rust
let runtime = Runtime::new(DeviceSpec::local_sync())?;
let program = runtime.load_vmfb(vmfb)?;

let lhs = runtime.buffer_view(&[4], &[1.0, 2.0, 3.0, 4.0])?;
let rhs = runtime.buffer_view(&[4], &[4.0, 3.0, 2.0, 1.0])?;

let function = program.function("arithmetic.simple_mul")?;
let outputs = function.invoke([&lhs, &rhs])?;

let output: BufferView<f32> = outputs[0].clone().try_into()?;
let values = output.read()?;
```

The API is still a thin layer over IREE. It does not try to hide the runtime model. It hides the parts that should not be normal user code: VM instance setup, HAL device wiring, module registration, context creation, and teardown ordering.

If the Rust API exposes too much of the low-level setup, every user has to handle the same lifecycle rules. If it exposes too little, it cannot map cleanly to IREE's actual model. The v0.5 API keeps the main IREE concepts visible while keeping the unsafe setup path private.

## Soundness is not just pointer wrapping
One lesson from this work is that a Rust abstraction can look sound locally and still create an unsound binding globally.

The obvious unsafe problems are raw pointers, borrowed buffers, external allocation, and C APIs that return status codes instead of structured errors. Those are normal FFI problems. They still need care, but they are visible at the call site.

The more subtle problems come from process-wide state. IREE has runtime registration paths, global tables, and lifecycle assumptions that are not naturally expressed in Rust ownership types. If two safe-looking Rust values can initialize, mutate, or tear down the same global C state in the wrong order, the wrapper is not safe just because each method signature looks reasonable.

The v0.5 runtime layer keeps more of the VM/HAL construction private. The safe API has to represent not only who owns a pointer, but also which global assumptions have already been established. In some places, the right Rust abstraction is not a direct wrapper around an IREE handle. It is a narrower object that prevents invalid combinations from being constructed.

I am cautious about calling the binding "sound." The goal is a sound Rust abstraction over the parts Eerie exposes, but that requires more than checking that each `Drop` implementation releases the right handle. With C libraries, global variables and hidden registration state are part of the API whether or not they appear in the header file.

## Bare metal without newlib
The bare-metal path also changed quite a bit since the earlier [bare-metal support post](/posts/2024-01-17-bare-metal-support-of-eerie-part1/).

At first, the practical path involved leaning on the embedded GNU toolchain and newlib-style runtime pieces. That worked for linking, but it was not a good dependency model for Eerie. If the crate needs a C runtime to appear from the outside, users have to solve too much toolchain-specific setup before they get to the ML part.

The v0.5 approach removes the newlib dependency from Eerie's bare-metal support. Instead, the missing C runtime surface is covered through Rust-side pieces: `compiler_builtins`, `libm`, tinyrlibc, and a small synchronization layer backed by `critical-section`.

Bare metal is still not automatic. A target still needs a linker script, startup code, a global allocator, and a board-specific runtime. Eerie no longer depends on a full external C runtime, so the required environment is smaller and fits embedded Rust projects better.

A Rust binding needs more than generated FFI here. The C library expects pieces of a hosted environment. On embedded targets, those pieces either have to be supplied explicitly or removed from the dependency chain. tinyrlibc made that boundary cleaner.

## Allocators are part of the API
The allocator boundary is another FFI detail that affects the public design.

Rust allocators care about layout. C APIs usually do not hand that layout back when asking you to free a pointer. If Eerie lets IREE allocate through one path and deallocate through another, or if it loses size and alignment information, the bug may not show up until much later.

I wrote about that in more detail in [Rust Malloc Handling in External FFI](/posts/2023-12-30-rust-malloc-handling-in-external-ffi/). Allocation cannot be treated as an implementation detail. It affects what can be safely exposed. The wrapper has to be explicit about ownership, alignment, and which side is responsible for freeing memory.

This pushed Eerie toward a smaller public API. Covering every C function immediately is less important than exposing the parts that can be made coherent in Rust.

## Where this leaves Eerie
Eerie has reached v0.5. The library is not done, and the API may still change.

The project is no longer just a set of bindings. The runtime path has a clearer ownership model. Device selection has a public API. Tensor-like runtime values are typed. Bare-metal support no longer depends on pulling in newlib. The unsafe pieces are still there, but more of them now sit behind APIs that encode the constraints I have found so far.

There is still work left: more target testing, better examples, documentation, and feedback from real use cases. The main design boundaries are visible now, and Eerie can be evaluated more directly as a Rust interface to IREE.
