---
title: "Project Eerie"
date: 2023-12-24T01:47:45+09:00
slug: 2023-12-24-project-eerie
type: posts
draft: false 
categories:
  - Projects
tags:
  - Eerie
  - Rust
  - IREE
---
# What is Eerie?
[Eerie](https://github.com/gmmyung/eerie) is a Rust binding for IREE, a compiler and runtime stack built on MLIR. The short version is that you can take models from frameworks like PyTorch, TensorFlow, or JAX, lower them through MLIR, compile them with IREE, and run the result through a fairly small runtime.

If you are not deep into ML compiler tooling, IREE is worth thinking of as infrastructure rather than a framework. It gives you a way to move from model code to something that can actually run on the target you care about.

IREE can be seen as the LLVM of ML compilers. It supports many different backends including:
- Vulkan, CUDA, Metal
- ROCm, WebGPU, AMD AIE (experimental)
- CPU (ARM, x86, RISC-V)
- Linux, Windows, macOS, Android, iOS, Bare metal

The runtime can also get surprisingly small on embedded targets. That part is what initially caught my attention.

## Why Rust?
Rust and IREE fit together better than I expected. Rust already has ML projects like [Candle](https://github.com/huggingface/candle) and [Burn](https://github.com/tracel-ai/burn), but I was interested in the compiler/runtime side of the stack: ahead-of-time compilation, target portability, and a runtime that could plausibly work on embedded systems as well as desktops.

Rust also already lives in a lot of the environments I care about, especially embedded and systems work. That makes a Rust binding around IREE feel more natural than trying to bolt it onto a language stack that is not already used there.

### The fragmentation problem
The ML toolchain is fragmented in a very practical way. You write models in Python, the heavy lifting happens in C++ or GPU runtimes, deployment depends on which backend you target, and the final story often changes again on embedded or web platforms.

I do not think Eerie magically fixes all of that, but I do think Rust is a good place to experiment with a cleaner stack around IREE.

# Current state
[Eerie](https://github.com/gmmyung/eerie) is the result of that experiment so far. It is still early and still rough around the edges, but it is usable enough to explore the idea seriously. If you try it and hit something broken, feel free to open an issue.
