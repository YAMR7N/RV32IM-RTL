# Clean up and set up libraries
vlib work
vmap work work



vlog InstructionMem.v
vlog DataMem.v
vlog CtrlUnit.v
vlog ALU.v
vlog Adder.v
vlog TwoInMUX.v
vlog ThreeInMUX.v
vlog if_id_reg.v
vlog id_ex_reg.v
vlog ex_mem_reg.v
vlog mem_wb_reg.v
vlog HazardCtrl.v
vlog RegFile.v
vlog ImmExtend.v
vlog PcReg.v
vlog top.v
vlog top_tb.sv

# Start simulation
vsim -voptargs=+acc work.rv32im_top_tb

# Add waveform window
view wave

# Add signals to waveform
add wave -divider "Clock & Reset"
add wave -hex sim:/rv32im_top_tb/clk
add wave -hex sim:/rv32im_top_tb/reset
add wave -hex sim:/rv32im_top_tb/done

add wave -divider "Program Counter"
add wave -hex sim:/rv32im_top_tb/dut/PCF
add wave -hex sim:/rv32im_top_tb/dut/PCD
add wave -hex sim:/rv32im_top_tb/dut/PCE
add wave -hex sim:/rv32im_top_tb/dut/PCNext
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4F
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4D
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4M
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4W

add wave -divider "EX"
add wave -hex sim:/rv32im_top_tb/dut/FlushE
add wave -hex sim:/rv32im_top_tb/dut/RegWriteE
add wave -hex sim:/rv32im_top_tb/dut/ResultSrcE
add wave -hex sim:/rv32im_top_tb/dut/MemWriteE
add wave -hex sim:/rv32im_top_tb/dut/JumpE
add wave -hex sim:/rv32im_top_tb/dut/BranchE
add wave -hex sim:/rv32im_top_tb/dut/ALUControlE
add wave -hex sim:/rv32im_top_tb/dut/ALUSrcE
add wave -hex sim:/rv32im_top_tb/dut/RD1E
add wave -hex sim:/rv32im_top_tb/dut/RD2E
add wave -hex sim:/rv32im_top_tb/dut/PCE
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4E
add wave -hex sim:/rv32im_top_tb/dut/ImmExtE
add wave -hex sim:/rv32im_top_tb/dut/Rs1E
add wave -hex sim:/rv32im_top_tb/dut/Rs2E
add wave -hex sim:/rv32im_top_tb/dut/RdE


add wave -divider "ID"
add wave -hex sim:/rv32im_top_tb/dut/RegWriteD
add wave -hex sim:/rv32im_top_tb/dut/ResultSrcD
add wave -hex sim:/rv32im_top_tb/dut/MemWriteD
add wave -hex sim:/rv32im_top_tb/dut/JumpD
add wave -hex sim:/rv32im_top_tb/dut/BranchD
add wave -hex sim:/rv32im_top_tb/dut/ALUControlD
add wave -hex sim:/rv32im_top_tb/dut/ALUSrcD
add wave -hex sim:/rv32im_top_tb/dut/RD1D
add wave -hex sim:/rv32im_top_tb/dut/RD2D
add wave -hex sim:/rv32im_top_tb/dut/PCD
add wave -hex sim:/rv32im_top_tb/dut/PCPlus4D
add wave -hex sim:/rv32im_top_tb/dut/ImmExtD
add wave -hex sim:/rv32im_top_tb/dut/Rs1D
add wave -hex sim:/rv32im_top_tb/dut/Rs2D
add wave -hex sim:/rv32im_top_tb/dut/RdD




add wave -divider "Instruction Fetch"
add wave -hex sim:/rv32im_top_tb/dut/InstrF
add wave -hex sim:/rv32im_top_tb/dut/InstrD

add wave -divider "Register File"
add wave -hex sim:/rv32im_top_tb/dut/rf/regs
add wave -hex sim:/rv32im_top_tb/dut/RD1D
add wave -hex sim:/rv32im_top_tb/dut/RD2D

add wave -divider "ALU Signals"
add wave -hex sim:/rv32im_top_tb/dut/ALUResultM
add wave -hex sim:/rv32im_top_tb/dut/SrcAE
add wave -hex sim:/rv32im_top_tb/dut/SrcBE
add wave -hex sim:/rv32im_top_tb/dut/ALUSrcE
#add wave -hex sim:/rv32im_top_tb/dut/ALUControlE

add wave -divider "Control Signals"
add wave -hex sim:/rv32im_top_tb/dut/RegWriteW
add wave -hex sim:/rv32im_top_tb/dut/MemWriteM
add wave -hex sim:/rv32im_top_tb/dut/PCSrcE

add wave -divider "Hazard Unit"
add wave -hex sim:/rv32im_top_tb/dut/StallF
add wave -hex sim:/rv32im_top_tb/dut/StallD
add wave -hex sim:/rv32im_top_tb/dut/FlushD
add wave -hex sim:/rv32im_top_tb/dut/FlushE
add wave -hex sim:/rv32im_top_tb/dut/FwdAE
add wave -hex sim:/rv32im_top_tb/dut/FwdBE

add wave -divider "Immediate Extender"
add wave -hex sim:/rv32im_top_tb/dut/ImmExtD
add wave -hex sim:/rv32im_top_tb/dut/ImmExtE

# Run simulation
run 1000 ns

# Zoom waveform to fit
wave zoom full