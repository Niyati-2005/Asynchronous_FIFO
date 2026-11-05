# Asynchronous FIFO — RTL to GDSII

An end-to-end implementation of an **Asynchronous FIFO**, covering RTL design, functional verification, CDC analysis, synthesis, static timing analysis, and physical design through **GDSII generation**.

This project started as a personal RTL design exercise to strengthen my understanding of **clock-domain crossing, FIFO architecture, SystemVerilog, and digital design implementation**. I extended it beyond RTL by taking the design through an open-source RTL-to-GDSII flow.

## Why Asynchronous FIFO?

Asynchronous FIFOs are a practical application of several important digital design concepts, particularly when data needs to be transferred safely between two independent clock domains.

The design incorporates:

- Independent read and write clock domains
- Gray-code based read/write pointers
- Clock-domain synchronization
- Full and empty detection
- Dual-port memory architecture
- CDC-safe pointer transfer
- Reset handling across clock domains

## Verification

A SystemVerilog verification environment was developed to validate the FIFO functionality across different clock relationships and operating conditions.

Verification includes:

- Write/read functionality
- Simultaneous read and write operations
- FIFO full and empty conditions
- Pointer wrap-around
- Different read/write clock frequencies
- Reset scenarios
- Boundary and corner-case testing

I used **AI/Codex as a development and learning aid while building the verification environment**, particularly because Design Verification is an area I am still actively learning. The FIFO architecture, RTL implementation, debugging, analysis, and overall flow were developed and understood as part of the project.

## CDC Analysis

The design was analyzed for clock-domain crossing issues, with particular attention to the transfer of FIFO pointers between asynchronous clock domains.

The CDC architecture uses **Gray-coded pointers and synchronizer stages** to ensure that only one pointer bit changes between consecutive states during clock-domain transfer.

## RTL Quality

The RTL was analyzed using lint and CDC checks.

Current status:

- Lint: Clean after review of reported warnings
- CDC: Clean after analysis and review
- Design constraints: Defined using a custom SDC
- Timing: Positive slack observed in the current implementation

Warnings that were intentionally waived were reviewed individually rather than blindly suppressed.

## RTL-to-GDSII Flow

The design was taken through an open-source physical implementation flow:

```text
SystemVerilog RTL
       ↓
RTL Simulation
       ↓
Lint Analysis
       ↓
CDC Analysis
       ↓
Synthesis
       ↓
Static Timing Analysis
       ↓
Floorplanning
       ↓
Placement
       ↓
Clock Tree Synthesis
       ↓
Routing
       ↓
Physical Verification
       ↓
GDSII
```

The physical design flow was performed using **OpenROAD**.

Custom SDC constraints were created for timing analysis, including clock definitions and relevant I/O constraints.

## Results

The current implementation shows:

| Metric | Result |
|---|---|
| RTL | Asynchronous FIFO |
| Verification | SystemVerilog testbench |
| CDC | Analyzed |
| Lint | Reviewed / Clean |
| Timing | Positive slack |
| Constraints | Custom SDC |
| Physical Design | OpenROAD |
| Final Target | GDSII |

The current results are still being analyzed further, particularly the **timing, area, and power characteristics** of the physical implementation. The goal is to use these results to identify opportunities for optimization rather than treating the first successful GDSII run as the final implementation.

## Repository Structure

```text
Asynchronous_FIFO/
│
├── rtl/
│   ├── async_fifo.sv
│   ├── fifo_memory.sv
│   ├── gray_sync.sv
│   └── fifo_Read_ctrl.sv
|   └── fifo_write_ctrl.sv
│
├── tb/
│   ├── tb_async_fifo.sv
│   
│
├── constraints/
│   └── fifo.sdc
│
├── reports/
│   └── cdc_reports/
|   └── lint_reports/
|   └── sta_reports/
|   └── synthesis_reports/
|   └── floorplanning_reports/
|   └── cts_reports/
|   └── routing_reports/
|   └── gds_reports/
|   └── waived off
│
└── README.md
```

**RTL → GDSII flow completed with further optimization and analysis ongoing.**

The next stage is to investigate the implementation results in greater depth and explore possible improvements in **PPA (Power, Performance, Area)** while maintaining CDC and functional correctness.
