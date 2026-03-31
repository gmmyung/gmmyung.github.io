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

In robotics, simulation usually starts long before the hardware is finished. A lot of those early parts are 3D-printed, and in practice they often get dropped into URDF or SDF files with guessed mass properties or no mass properties at all.

That shortcut is fine until it is not. Bad estimates for mass, center of mass (COM), and inertia can show up as:

* unstable controllers that *seem* correct in simulation,  
* mis‑tuned balance algorithms in legged or mobile platforms,  
* gripper payload limits that differ from reality.

That was the motivation for **PrintDynamic**, a small Rust-to-WASM tool that parses G-code and estimates the actual dynamic properties of an extruded part.

For the complete source code, see [GitHub](https://github.com/gmmyung/printdynamic).

---

## 1. From G-code to tensors

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

The integrals are analytic:

* **LineSeg**: slender‑rod inertia with endpoints \(\mathbf{r}_0, \mathbf{r}_1\), shifted to origin.  
* **ArcSeg**: plane circular arc of radius \(r\) swept by angle \(\Delta\theta\).

After summing all segments we apply the **parallel‑axis theorem** to obtain the inertia tensor at the part’s COM:

\[
I_{\mathrm{COM}} = I_0 - m\bigl(\| \mathbf{c}\|^2\, \mathbf{I}_{3} - \mathbf{c}\,\mathbf{c}^\top\bigr)
\]

where \(I_0\) is the inertia about the printer origin and \(\mathbf{c}\) is the COM.

---

## 2. Why Leptos + WebAssembly?

| Requirement                         | Traditional SPA | Leptos (Rust) |
|------------------------------------|-----------------|---------------|
| **Numerical accuracy** (`f32`/`f64`)| JS `number`     | Native LLVM   |
| **Zero‑copy math libraries**       | Hard            | `nalgebra`    |
| **Single‑file deployment**         | ✔︎              | ✔︎           |
| **Type safety from parser → UI**   | Weak            | End‑to‑end    |

I picked Leptos because the parser and math code were already in Rust, and I did not want to split the project into "real logic in Rust" plus "UI glue in JavaScript." That gives me:

* **compile once** to WASM and host on GitHub Pages—no backend,
* the same business logic reused in a CLI or desktop GUI,
* end-to-end type checking from the parser to the UI.

---

## 3. Project structure

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

## 4. Usage

### 4.1. Online demo

1. Open **<https://gmmyung.github.io/printdynamic/>**.  
2. Click **“Select G‑code file.”**  
3. Adjust filament diameter (mm) and density (g / cm³) if needed.  
4. Press **Parse**.  
5. Read off:
   * total mass (g),  
   * COM vector (mm, printer coordinates),  
   * inertia tensor about origin,  
   * inertia tensor about COM.

### 4.2. Local build

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

### 4.3. CLI integration

Because the parsing core is plain Rust, it is easy to reuse in a headless tool:

```rust
use printdynamic::{parse_segments, Segment};
use nalgebra::{Matrix3, Vector3};

let gcode = std::fs::read_to_string("part.gcode")?;
let segs  = parse_segments(&gcode, 1.75, 1.24);

let m_total: f32 = segs.iter().map(|s| s.mass()).sum();
println!("Mass: {:.2} g", m_total);
```

---

## 5. Closing

The point of PrintDynamic is simple: if a printed part is going into simulation, I want better numbers than "close enough." Parsing G-code turned out to be a practical way to get there without building a full CAD pipeline.

If you want to try it or add features, the source is on GitHub.
