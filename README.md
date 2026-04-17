<div align="center">

# 🚀 RV32I Single-Cycle Processor Core

[![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-blue.svg)](https://riscv.org/)
[![Language](https://img.shields.io/badge/Language-SystemVerilog-brightgreen.svg)]()
[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange.svg)]()

*A 32-bit single-cycle RISC-V CPU core designed from scratch.*

</div>

## 📖 Overview
This project implements a single-cycle processor architecture based on the **RISC-V (RV32I)** Base Integer Instruction Set. It is designed with a focus on digital IC design flow, RTL modeling, and functional verification. 

---

## 🏗️ Hardware Architecture & Datapath

The core follows a classic single-cycle datapath layout. It integrates essential components including the Program Counter (PC), Instruction Memory, Register File, ALU, Data Memory, and a Control Unit to decode instructions and manage data routing.

<div align="center">
  <img width="850" alt="RISC-V Datapath" src="https://github.com/user-attachments/assets/de6d36b7-e479-4b10-8c32-dd630c18e295" />
  <p><i>Figure 1: Single-Cycle RV32I Datapath Architecture</i></p>
</div>

---

## 🧩 Instruction Formats

The Control Unit is designed to decode and execute the base 32-bit instruction formats as defined by the standard RISC-V ISA specification. 

<div align="center">
  <img width="800" alt="RISC-V Instruction Formats" src="https://github.com/user-attachments/assets/fff457b9-adf3-4bec-a929-c51a0afdf2b2" />
  <p><i>Figure 2: Supported 32-bit RISC-V Instruction Formats (R, I, S, B, U, J)</i></p>
</div>

---

## 🛠️ Technologies & Tools

* **Hardware Description Language:** SystemVerilog
* **Simulation & Verification:** ModelSim / Verilator
* **Logic Synthesis:** Yosys
* **Physical Design (RTL-to-GDSII):** OpenLane
* **Target Technology:** SkyWater 130nm PDK

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the necessary simulation tools installed (e.g., ModelSim).

### Running Simulations
1. Clone this repository:
   ```bash
   git clone [https://github.com/your-username/your-repo-name.git](https://github.com/your-username/your-repo-name.git)
