ALU UVM Verification Environment
A complete SystemVerilog UVM testbench for verifying a 4-bit ALU. This project demonstrates the implementation of a constrained random verification environment, automated scoreboard checking, and functional coverage reporting using Cadence Xcelium.

🚀 Project Overview
The goal of this project was to verify a 4-bit ALU supporting four operations (ADD, SUB, AND, OR) using the industry-standard UVM methodology. The testbench generates random stimuli, monitors the DUT (Device Under Test) interfaces, predicts expected results, and tracks functional coverage to ensure all corner cases are tested.

🛠 Features
Constrained Random Stimulus: Automated generation of operands and opcodes using uvm_sequence.

Self-Checking Scoreboard: Real-time comparison of DUT output against a golden reference model.

Functional Coverage: Custom covergroups tracking:

Operation coverage (ADD, SUB, AND, OR).

Input edge cases (Zero and Max values).

Cross-coverage between operations and inputs.

Automated Reporting: Coverage metrics and test results are printed directly to the simulation log.
**********************************************************************************************************************************************************************
HOW RO RUN 
********************************************************************************************************************************************************************

This project is configured for the Cadence Xcelium simulator.

Prerequisites
Cadence Xcelium (xrun)

UVM 1.1d or 1.2 Library

Execution
To run the simulation and view the coverage results in the terminal:

xrun -uvm design.sv uvm.sv +UVM_TESTNAME=alu_test -coverage all -l sim.log

*****************************************************************************************
RESULTS
*****************************************************************************************

UVM_INFO @ 495: uvm_test_top.env.scb [PASS] OP:2 A:15 B:11 | RES:11
...
UVM_INFO @ 495: uvm_test_top.env.cov [COV_RESULTS] ==============================================
UVM_INFO @ 495: uvm_test_top.env.cov [COV_RESULTS]   TOTAL COVERAGE: 95.83%
UVM_INFO @ 495: uvm_test_top.env.cov [COV_RESULTS]   OP Coverpoint:  100.00%
UVM_INFO @ 495: uvm_test_top.env.cov [COV_RESULTS] ==============================================
