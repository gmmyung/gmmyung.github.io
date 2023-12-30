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
[Eerie](https://github.com/gmmyung/eerie) is a Rust binding for IREE, an end-to-end compiler and runtime based on MLIR (Multi-Level Intermediate Representation). It serves as a transformative bridge for Machine Learning (ML) models, converting them into a unified Intermediate Representation (IR). For those unfamiliar with the ML compiler space, this process involves exporting models from frontend frameworks such as PyTorch, TensorFlow, and JAX into MLIR as a series of tensor operations. Subsequently, these models are compiled into IREE's own IR. The runtime executes the model by interpreting the IR. For more information, you can refer to the [IREE Website](https://iree.dev). In essence, Eerie provides a fully modular, ahead-of-time (AOT) compiled, lightweight ML engine!/
IREE can be seen as the LLVM of ML compilers. It supports many different backends including:
- Vulkan, CUDA, Metal
- ROCm, WebGPU, AMD AIE (experimental)
- CPU (ARM, x86, RISC-V)
- Linux, Windows, macOS, Android, iOS, Bare metal

Adding to that, the binary size can be as low as 30KB on embedded systems. Indeed, IREE can run the same model using a microcontroller, an iPhone, and a Nvidia graphics card, which succeeds Rust's ethos: "Write once, Compile everywhere".
## Why Rust?
I wanted to make something cool with IREE, and discovered that IREE and Rust make a lot of sense together. Rust has a few ML frameworks such as [Candle](https://github.com/huggingface/candle) and [Burn](https://github.com/tracel-ai/burn), but none of them fully supports JIT/AOT kernel fusion. By using the IREE compiler/runtime, one can build a full blown ML library that can seamlessly generate AOT compiled models in runtime using the powerful macro system of Rust. Also, Rust is used extensively in the embedded space, which means that IREE can smoothly integrate into the Embedded Rust ecosystem. To top it off, it can also be used to run ML models on the web using Rust compiled in WASM, leveraging the WebGPU API to accelerate operations.
### Solving the AI fragmentation problem
There is a well-known fragmentation issue in the ML space: machine learning models are written in Python with libraries like PyTorch, TensorFlow, and JAX, which are written in C++. These libraries also use CUDA/ROCm and occasionally Numba or Triton. This situation is a hot mess. Mojo attempts to fix this using a whole new systems language that utilizes MLIR, but there is already a compiled language that runs pretty much everywhere: Rust. I truly believe that merging IREE and Rust has the potential to reshape how neural nets are written and executed.
# Unveiling the Work 
[Eerie](https://github.com/gmmyung/eerie) is what I have been working on for the past few months. The library is still experimental and needs a bit more polishing, but feel free to try it out and provide your valuable feedback on the GitHub Issues page!
