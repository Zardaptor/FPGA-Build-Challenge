# V-SPACE FPGA Build Challenge: Team Suraj Final Report

## Executive Summary
This report summarizes the journey, technical achievements, and learnings of Team Suraj throughout the V-SPACE FPGA Build Challenge. Over the course of 5 experiments, the team progressed from fundamental digital logic concepts to advanced, complex digital systems. A core philosophy for the team was pushing beyond the basic beginner specifications for each experiment, challenging ourselves to design more robust, feature-rich, and performant hardware.

## Summary of Experiments

* **Experiment 1: Basic Logic & Combinational Circuits**
  Established the foundation of digital design using hardware description languages, implementing basic logic gates and combinational circuits to understand synthesis and simulation flows.
  
* **Experiment 2: Sequential Logic & State Machines**
  Explored flip-flops, registers, and Finite State Machines (FSMs). This laid the essential groundwork for the complex control logic used in later communication protocols and processors.
  
* **Experiment 3: Communication Interfaces (SPI)**
  Designed and implemented an SPI controller. Instead of a basic fixed-mode SPI, the team pushed for a **multi-mode SPI implementation**, supporting different clock polarities and phases (CPOL/CPHA), demonstrating a much deeper understanding of serial communication protocols.
  
* **Experiment 4: Memory Controllers & DSP**
  Integrated block RAMs and implemented basic Digital Signal Processing (DSP) blocks, focusing heavily on efficient resource utilization and timing closure within the FPGA fabric.
  
* **Experiment 5: Advanced Processor Design (RISC-V)**
  The capstone project involved designing a RISC-V processor. Rather than settling for a simple single-cycle architecture, the team successfully engineered a **5-stage pipelined CPU (RV32I)** complete with a Forwarding Unit and Hazard Detection Unit to resolve data and control hazards, significantly maximizing instruction throughput.

## Hardware Learning Curve & Challenges

Transitioning from standard software programming to hardware design presented a steep but ultimately rewarding learning curve:

* **Vivado Synthesis & Implementation:** We learned early on that writing code that simply simulates correctly is not enough. Understanding how RTL constructs synthesize into underlying lookup tables (LUTs), flip-flops, and block RAMs was crucial. We spent significant time analyzing synthesis reports, understanding timing constraints, and resolving critical setup/hold time violations.
* **PYNQ-Z2 Constraints:** Deploying designs to the PYNQ-Z2 board required carefully managing physical constraints. This involved meticulous pin mapping via XDC files, understanding the limitations of the available logic resources, and successfully interfacing the Programmable Logic (PL) with the Processing System (PS).
* **Hardware vs. Software Bugs:** Debugging hardware proved fundamentally different from software. Software executes sequentially, while hardware is inherently parallel. Issues like race conditions, clock domain crossings, and uninitialized states required a complete shift in mindset. We heavily relied on simulation testbenches, waveform analysis, and Integrated Logic Analyzers (ILAs) for on-chip debugging, discovering that a "fix" in hardware often meant rethinking the entire architecture rather than just patching a line of code.

## Conclusion
The V-SPACE FPGA Build Challenge was an invaluable experience. By actively choosing to tackle advanced specifications like a fully pipelined RISC-V processor and multi-mode SPI interfaces, Team Suraj gained profound, practical knowledge of RTL design, FPGA architecture, and the complete hardware development lifecycle.
