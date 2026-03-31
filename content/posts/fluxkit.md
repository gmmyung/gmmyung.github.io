---
title: "Fluxkit: Hardware-Agnostic FOC in Embedded Rust"
date: 2026-03-31T23:15:00+09:00
slug: 2026-03-31-fluxkit
type: posts
draft: false
categories:
  - Projects
tags:
  - Rust
  - Embedded
  - Motor Control
  - FOC
---
Most motor-control codebases are glued directly to one MCU, one timer layout, one ADC scheme, and one bring-up sequence. That is fine until you want to change boards, add a calibration routine, or test a controller without touching hardware. Then everything is entangled at once: control law, interrupt ownership, sampling timing, logging, board support, and whatever half-finished bench setup you currently have.

[Fluxkit](https://github.com/gmmyung/fluxkit) is my attempt to attack that problem directly. It is a `no_std` Rust toolkit for BLDC / PMSM field-oriented control that tries to keep the control stack portable, testable, and explicit about ownership. The core library covers the pieces I actually care about in real actuator projects: current loop, velocity loop, position loop, open-loop voltage mode, calibration routines, actuator-side friction compensation, and a narrow HAL surface for hardware integration.

{{< youtube PZlf3Gy1KJw >}}

It is not an RTOS, not an embedded framework, and not a giant pile of macros pretending to be one. The goal is much simpler: make the motor-control stack reusable across boards without making it vague.

## The structure

The workspace is split into a few crates with clear boundaries:

- `fluxkit_math` for units, transforms, modulation, and estimator primitives
- `fluxkit_core` for the deterministic control engine and pure calibration logic
- `fluxkit_hal` for small synchronous hardware traits
- `fluxkit` for the project-facing runtime and calibration wrappers
- `fluxkit_pmsm_sim` for simulator-backed tests and examples

That split matters because it keeps the control code from collapsing into board code. The runtime only asks for a few concrete capabilities: phase PWM, current sampling, bus voltage sensing, temperature sensing, rotor sensing, and output sensing. Everything else stays on the application side.

The ownership model is also deliberate. Main-context code owns `MotorRuntime`. IRQ-side code runs it through `MotorTicker`. Other code talks to it through `MotorHandle`. The same shape is used for calibration with `MotorCalibrationRuntime` and `ActuatorCalibrationRuntime`. That sounds like a small detail, but it solves a very real embedded problem: who owns the controller state, who is allowed to tick it, and how phase transitions happen without hidden aliasing, races, or "just trust me" globals.

## Why I cared about host-side execution

The hard part of this project was not writing another controller. The hard part was making the implementation run cleanly on both an MCU and a consumer OS.

That is still unusual in embedded work. A lot of firmware code is written as if `no_std` means "only meaningful on bare metal." I do not think that model scales well. `no_std` crates still work perfectly well on host targets, and that opens up a much better testing story if you lean into it.

In Fluxkit, the same core crates are exercised in unit tests and integration tests on the host. Things like `critical-section`, `portable-atomic`, and lightweight math crates such as `micromath` are not exclusive to MCUs, so they can stay in the stack during test runs as well. That makes it possible to keep the real code path under test instead of building a fake "desktop version" that gradually diverges from firmware reality.

Plumbing that split is annoying. You have to be disciplined about what depends on `std`, what owns timing, what is synchronous, and what stays pure. But once that work is done, the payoff is huge.

## Simulation as a real development tool

The biggest payoff is [the in-repo PMSM simulator](https://github.com/gmmyung/fluxkit/tree/main/crates/fluxkit_pmsm_sim).

`fluxkit_pmsm_sim` is an allocation-free ideal plant model for PMSM systems. It models the standard `d/q` electrical dynamics, torque production, rigid-shaft mechanics, thermal behavior, and actuator-side effects such as reflected inertia and friction. It also accepts different input forms, including `d/q` voltage, `alpha/beta` voltage, phase voltage, and PWM duty plus bus voltage.

It is important to be precise here: this is not a switching-accurate inverter simulation. It is an idealized plant model for controller validation. That is exactly what I wanted. I do not need transistor-level switching edges to validate runtime ownership, calibration state machines, or closed-loop behavior.

Because of that simulator, the integration tests are much more than smoke tests. They exercise full runtime flows, calibration flows, and controller behavior against a deterministic plant. The current loop is tested against the simulator. Calibration routines recover motor parameters from simulated hardware. Actuator-side routines fit friction and breakaway terms against a modeled drivetrain. The project is also heavily unit-tested underneath that.

This is a very different workflow from the usual "flash firmware, spin the motor, and see what exploded" loop. Hardware still matters, obviously. But a large amount of development can happen before hardware enters the picture, and when hardware does enter the loop, the remaining unknowns are narrower.

## Why this works well with AI agents

Fluxkit was also written with AI-assisted development in mind.

I do not mean that in the shallow "AI wrote the code" sense. I mean the architecture is shaped so that an agent can work on the codebase without needing constant supervision at every line. The contracts are narrow, the ownership model is explicit, and there is a simulator-backed test harness that exercises real control paths.

That matters a lot for systems code. If you ask an agent to change embedded firmware in the usual tightly coupled style, you are mostly asking for trouble. Too many assumptions live in invisible hardware behavior. With Fluxkit, a new calibration routine or controller tweak can be implemented and validated against deterministic integration tests before it ever gets near a board.

That does not remove the need for hardware validation. It just changes the risk profile. The simulator is good enough that I can let an agent work more aggressively on controller features and refactors with tighter guardrails instead of treating every edit like a blind jump.

## Hardware is still first-class

Being hardware-agnostic does not mean pretending hardware details do not exist. It means making those details local.

The companion project [fluxkit_drv8302_example](https://github.com/gmmyung/fluxkit_drv8302_example) is one concrete example. It targets a `NUCLEO-G431KB + AS5048A + DRV8302` setup and wires Fluxkit into a real Embassy STM32 firmware stack. That repo handles the board-specific parts: TIM1-based 3-PWM output, ADC injected current sampling, DMA-driven encoder reads, current zeroing, fault monitoring, and the rest of the bring-up sequence.

What I like about that split is that the example stays honest about board reality without leaking those decisions back into the library surface. Timer hierarchy, ADC triggering, logging strategy, and calibration wiring are visible in the support crate, but the control layer does not become "the STM32G4 implementation." If someone wants to use a different MCU, different timer topology, or different communication path, they should be able to do that by implementing the same narrow HAL contracts and keeping the application-level ownership model intact.

That is the point of the whole project.

## Where I think this goes

I do not think Fluxkit is "finished" in any meaningful sense. The interesting parts are exactly the ones that are hard to get right: calibration confidence, more actuator models, more hardware examples, and more coverage around real-world failure cases.

But the core idea already feels right to me. Embedded motor control does not have to be a pile of board-specific state machines that can only be validated on the bench. A `no_std` Rust stack can still be modular, test-heavy, and pleasant to evolve on the host. Once that is true, features like calibration, friction compensation, and higher-level loop control become much easier to iterate on.

That is what Fluxkit is trying to be: not a demo, but a motor-control codebase that is actually structured to survive iteration.
