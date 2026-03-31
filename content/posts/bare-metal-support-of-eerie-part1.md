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
# Getting Eerie Running on `#![no_std]`
I started adding `#![no_std]` support to Eerie expecting the usual embedded cleanup work. Instead, most of the time went into linker issues and missing C runtime pieces that desktop targets quietly provide for you.

# First blocker: linker errors
The first real problem showed up when linking Rust and C code on an embedded target. The error looked like this:
```
rust-lld: error: undefined symbol: ceilf
>>> referenced by ops.h:551 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime/src/iree/vm/ops.h:551)
>>> dispatch.c.obj:(vm_ceil_f32) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build
/lib/libiree.a
>>> referenced by elementwise.c:173 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime
/src/iree/modules/vmvx/elementwise.c:173)
>>> elementwise.c.obj:(iree_uk_generic_x32u_op) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build/lib/libiree.a
```
This was a `libm` problem. On non-embedded targets, a lot of this gets pulled in for free. On bare metal, it does not.

At that point I had three options:

1. Specify the exact location of the precompiled binaries of `libm` in the linker flags.
2. Use the `arm-none-eabi` linker to link the precompiled `libm` binaries.
3. Rewrite all `libm` functions in Rust.

The first option sounds easy until you get into target-specific details like the exact `thumbv7em` variant and FPU settings. The second option works, but it pushes extra linker setup onto downstream users. I wanted something that would be easier to ship as part of the crate, so I ended up going down the Rust reimplementation route.

## Replacing `libm`
Luckily, a lot of the groundwork already exists. The [libm](https://github.com/rust-lang/libm) crate ports MUSL's math library to Rust, and wrapper crates such as [externc-libm](https://github.com/HaruxOS/externc-libm) export `#[no_mangle]` symbols that can stand in for the usual C functions.

That got me past the first batch of missing symbols, but it was not the end of the story.

## Then `lroundf` showed up
The next linker error was:
```
rust-lld: error: undefined symbol: lroundf
>>> referenced by ops.h:606 (/Users/gmmyung/Developer/eerie/iree-sys/iree/runtime/src/iree/vm/ops.h:606)
>>> dispatch.c.obj:(vm_cast_f32si32) in archive /Users/gmmyung/Developer/eerie-embedded/target/thumbv7em-none-eabihf/debug/build/iree-sys-a5c1d2279731491b/out/runtime_build/build/lib/libiree.a
```
`lroundf` comes from the C math stack as well, and in my case it was easier to implement the missing pieces than to keep chasing toolchain-specific ways to link them in.

## Filling in libc pieces
There have been several attempts at implementing libc in Rust, including [rusl](https://github.com/anp/rusl), [c-ward](https://github.com/sunfishcode/c-ward), and [relibc](https://gitlab.redox-os.org/redox-os/relibc/-/tree/master?ref_type=heads) from the [Redox OS project](https://www.redox-os.org). None of them quite matched what I needed for bare metal.

[Tinyrlibc](https://github.com/rust-embedded-community/tinyrlibc) was a useful starting point, even though it is still incomplete. From there I started implementing the basics myself: `memcpy`, `memset`, `memcmp`, and eventually allocator-related pieces like `malloc` and `free` with `extern crate alloc`.

## Where this left me
Right now the practical workaround is still manual linking with the GNU toolchain. That is good enough to keep moving, but the longer-term goal is the same: make the embedded path work without asking users to hand-assemble their toolchain setup.

There is still a lot left to implement, but at least the problem is clearer now than it was when I started.
