---
title: "PrintDynamic: Peek at Mass, COM & Inertia Before You Hit Print"
date: 2025-04-20T16:53:05+09:00
slug: 2025-04-20-printdynamic
type: posts
math: true
draft: false
categories:
  - Projects
tags:
  - 3D Printing
  - Rust
  - Leptos
---

Modern robotics workflows lean heavily on simulation—**Gazebo**, **Mujoco**, **Isaac Sim**, and others—long before a single screw is tightened.  
3‑D‑printed components dominate proof‑of‑concept builds because they **reduce cost and iteration time**, yet we often treat them as *massless* placeholders in URDF or SDF files.  
Neglecting the real **mass, center of mass (COM), and inertia tensor** may appear harmless, but the error propagates into:

* unstable controllers that *seem* correct in simulation,  
* mis‑tuned balance algorithms in legged or mobile platforms,  
* gripper payload limits that differ from reality.

This post introduces **PrintDynamic**, a small Rust → WASM application that parses G‑code and computes **true dynamic parameters** of an extruded part. We will explore why the project is written with the **Leptos** front‑end framework, and how you can integrate it into your own workflow.

For the complete source code, see [GitHub](https://github.com/gmmyung/printdynamic).

---

## 1. From G‑code to Tensors: Methodological Notes

PrintDynamic treats every extrusion move as either:

| G‑code motion | Mathematical model              |
|---------------|---------------------------------|
| `G0` / `G1`   | Straight **line segment**       |
| `G2` / `G3`   | Circular **arc segment**        |

Each segment implements a common **`Segment`** trait:

```rust
pub trait Segment {
    fn center(&self)   -> Vector3<f32>; // first moment
    fn mass(&self)     -> f32;
    fn inertia(&self)  -> Matrix3<f32>; // second moment
}
```

The underlying integrals are analytic:

* **LineSeg**: slender‑rod inertia with endpoints \(\mathbf{r}_0, \mathbf{r}_1\), shifted to origin.  
* **ArcSeg**: plane circular arc of radius \(r\) swept by angle \(\Delta\theta\).

After summing all segments we apply the **parallel‑axis theorem** to obtain the inertia tensor at the part’s COM:

\[
I_{\mathrm{COM}} = I_0 - m\bigl(\| \mathbf{c}\|^2\, \mathbf{I}_{3} - \mathbf{c}\,\mathbf{c}^\top\bigr)
\]

where \(I_0\) is the inertia about the printer origin and i\(\mathbf{c}\) is the COM.

---

## 2. Why Leptos + WebAssembly?

| Requirement                         | Traditional SPA | Leptos (Rust) |
|------------------------------------|-----------------|---------------|
| **Numerical accuracy** (`f32`/`f64`)| JS `number`     | Native LLVM   |
| **Zero‑copy math libraries**       | Hard            | `nalgebra`    |
| **Single‑file deployment**         | ✔︎              | ✔︎           |
| **Type safety from parser → UI**   | Weak            | End‑to‑end    |

Leptos provides a **reactive component model** comparable to React or Solid, but runs on Rust’s type system. Printing enthusiasts therefore get:

* **compile once** to WASM and host on GitHub Pages—no backend,
* the same business logic reused in a CLI or desktop GUI,
* the borrow checker ensuring the async file‑loader and math kernels remain race‑free.

---

## 3. Project Structure

```
printdynamic/
├── Cargo.toml            # workspace root
├── src/
│   ├── segments.rs       # LineSeg & ArcSeg implementations
│   ├── interpreter.rs    # G‑code → Segment parser
│   └── main.rs           # Leptos app (WASM entry point)
├── dist/                 # HTML, JS, WASM emitted by Trunk
└── .github/workflows/
    └── gh-pages.yml      # CI: build & deploy to GitHub Pages
```

*`segments.rs` and `interpreter.rs` compile to both native and WASM targets; only `main.rs` is web‑specific.*

---

## 4. Usage Guide

### 4.1. Online Demo

1. Open **<https://gmmyung.github.io/printdynamic/>**.  
2. Click **“Select G‑code file.”**  
3. Adjust filament diameter (mm) and density (g / cm³) if needed.  
4. Press **Parse**.  
5. Read off:
   * total mass (g),  
   * COM vector (mm, printer coordinates),  
   * inertia tensor about origin,  
   * inertia tensor about COM.

### 4.2. Local Build

```bash
rustup component add wasm32-unknown-unknown
cargo install trunk
git clone https://github.com/gmmyung/printdynamic.git
cd printdynamic
trunk serve           # dev server on 127.0.0.1:8080
```

Production build:

```bash
trunk build --release --public-url /printdynamic/
```

The `dist/` folder is now portable to any static host (GitHub Pages, Netlify, S3, …).

### 5.3. CLI Integration (optional)

Because the parsing core is pure Rust, you can embed it in a headless tool:

```rust
use printdynamic::{parse_segments, Segment};
use nalgebra::{Matrix3, Vector3};

let gcode = std::fs::read_to_string("part.gcode")?;
let segs  = parse_segments(&gcode, 1.75, 1.24);

let m_total: f32 = segs.iter().map(|s| s.mass()).sum();
println!("Mass: {:.2} g", m_total);
```

---

## 5. Conclusion

Accurate dynamics for 3‑D‑printed parts close the loop between *low‑cost prototyping* and *high‑fidelity simulation*.  
By pairing Rust’s numerics with Leptos’s ergonomic front‑end, **PrintDynamic** lets engineers obtain trustworthy mass properties **before** the printer even heats up. Drop in a file, fetch the numbers, and feed them straight into your URDF or parameter server—no more guessing.

Questions or feature requests? Open an issue or reach out on the project GitHub. Happy printing and simulating!
