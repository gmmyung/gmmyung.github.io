---
title: "Bare Metal Support of Eerie (Part1)"
date: 2024-01-17T23:50:08+09:00
slug: 2024-01-17-bare-metal-support-of-eerie-part1
type: posts
draft: false
categories:
  - Development Log
tags:
  - Libc
  - Bare Metal
  - Embedded
---
# Navigating the Challenges of `#![no-std]` in Eerie
The quest for `#![no-std]` support in Eerie has proven to be more challenging than anticipated, particularly when delving into embedded development nuances that were not initially apparent.

# Unraveling Linker errors
Rust brings many advantages, one of which is freedom from dealing with traditional C/C++ linker errors. However, linking Rust and C in an embedded environment has presented a unique set of challenges. A particularly vexing issue arose when encountering a linker error that looked like this:
```
rust-lld: error: undefined symbol: ceilf
>>> referenced by ops.h:551 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime/src/iree/vm/ops.h:551)
>>> dispatch.c.obj:(vm_ceil_f32) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build
/lib/libiree.a
>>> referenced by elementwise.c:173 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime
/src/iree/modules/vmvx/elementwise.c:173)
>>> elementwise.c.obj:(iree_uk_generic_x32u_op) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build/lib/libiree.a
```
This pointed to the fact that `libm` was not being linked with the `rust-lld` linker. In non-embedded targets, the Rust linker automatically incorporates the pre-built standard library. However, in embedded targets, standard library symbols are not provided by default, leading to three potential solutions.

1. Specify the exact location of the precompiled binaries of `libm` in the linker flags.
2. Use the `arm-none-eabi` linker to link the precompiled `libm` binaries.
3. Rewrite all `libm` functions in Rust.

While the first option seemed obvious, there were nuances, such as precompiled binaries for the `thumbv7em` architecture, requiring manual configuration for the specific FPU type. The second option, involving the `arm-none-eabi ` linker, presented transitive challenges for users setting up the linker in the crate's dependency graph, making it less suitable for minimal configuration distribution. The third option, rewriting libc in Rust, became the chosen path.

## Tackling libm linker errors
Fortunately, multiple implementations of `libc`, `libm`, and other compiler builtins exist. The [libm](https://github.com/rust-lang/libm) crate is a MUSL libm port to Rust, serves as a drop-in replacement for GNU `libm`. Wrapper crates like [externc-libm](https://github.com/HaruxOS/externc-libm) provide `#[no_mangle]` symbols to libm functions.

## Unveiling Further Challenges
As the journey progressed, another linker error surfaced:
```
rust-lld: error: undefined symbol: lroundf
>>> referenced by ops.h:606 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime/src/iree/vm/ops.h:606)
>>> dispatch.c.obj:(vm_cast_f32si32) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build/lib/libiree.a
```
The `lroundf` function, part of `<tgmath.h>`, an extension to `<math.h>` and `<complex.h>`, posed a challenge. This necessitated the implementation of functions like `lroundf` from scratch.
## Embarking on libc Implementation
Various attempts at re-implementing libc in Rust, such as [rusl](https://github.com/anp/rusl), [c-ward](https://github.com/sunfishcode/c-ward), and [relibc](https://gitlab.redox-os.org/redox-os/relibc/-/tree/master?ref_type=heads) used for the [Redox OS project](https://www.redox-os.org), did not support bare metal. The need arose to implement libc functions from the ground up. [Tinyrlibc](https://github.com/rust-embedded-community/tinyrlibc), a `libc` implementation for embedded targets, served as a starting point, though incomplete. The journey began with implementing fundamental functions like `memcpy`, `memset`, and `memcmp`, ensuring compatibility with the C standard. Additionally, `malloc` and `free` functions, requiring `extern crate alloc` in Rust crates, were successfully implemented.

# Concluding Strides
While the path to implementing libc in Rust posed numerous challenges, solutions were found and basic libc functions were successfully implemented. The current workaround involves manual linking using the GNU toolchain, but continuous efforts towards a pure Rust libc implementation promise a smoother user experience. The journey continues, with plans to implement more functions in the pursuit of progress.