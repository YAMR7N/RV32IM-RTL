`include "InstructionMem.v"
`include "DataMem.v"
`include "CtrlUnit.v"
`include "ALU.v"
`include "Adder.v"
`include "TwoInMUX.v"
`include "ThreeInMUX.v"
`include "if_id_reg.v"
`include "id_ex_reg.v"
`include "ex_mem_reg.v"
`include "mem_wb_reg.v"
`include "HazardCtrl.v"
`include "RegFile.v"
`include "ImmExtend.v"
`include "PcReg.v"

module rv32im_processor (
    input clk, reset
);
    // Fetch Stage
    wire [31:0] PCF, PCNext, PCPlus4F, InstrF;
    wire StallF;

    // PC Register
    pc_reg pcreg (
        .clk(clk),
        .reset(reset),
        .en(~StallF),
        .PCNext(PCNext),
        .PC(PCF)
    );

    // PC + 4 (using adder)
    adder pc_adder (
        .a(PCF),
        .b(32'd4),
        .y(PCPlus4F)
    );

    // Instruction Memory
    instruction_memory imem (
        .A(PCF),
        .RD(InstrF)
    );

    // IF/ID Register
    wire [31:0] InstrD, PCPlus4D, PCD;
    wire StallD, FlushD;
    if_id_reg ifid (
        .clk(clk),
        .reset(reset),
        .en(~StallD),
        .clr(FlushD),
        .PCPlus4F(PCPlus4F),
        .InstrF(InstrF),
        .PCPlus4D(PCPlus4D),
        .InstrD(InstrD)
    );
    assign PCD = PCF; // Not explicitly stored in IF/ID, but needed in Decode

    // Decode Stage
    wire [4:0] Rs1D, Rs2D, RdD;
    wire [31:0] RD1D, RD2D, ImmExtD;
    wire RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
    wire [1:0] ResultSrcD;
    wire [4:0] ALUControlD;
    wire [2:0] ImmSrcD;

    // Extract instruction fields
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD  = InstrD[11:7];

    // Register File (updated to regfile)
    wire [31:0] ResultW;
    wire [4:0] RdW;
    wire RegWriteW;
    regfile rf (
        .clk(clk),
        .WEn3(RegWriteW),
        .A1(Rs1D),
        .A2(Rs2D),
        .A3(RdW),
        .WD3(ResultW),
        .RD1(RD1D),
        .RD2(RD2D)
    );
    // Initialize registers to 0 (not in regfile module, added here for simulation)
    initial begin
        for (integer i = 0; i < 32; i = i + 1)
            rf.regs[i] = 32'h0;
    end

    // Control Unit
    control_unit cu (
        .opcode(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7b5(InstrD[30]),
        .funct7b0(InstrD[25]),
        .RegWrite(RegWriteD),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ALUControl(ALUControlD),
        .ALUSrc(ALUSrcD),
        .ImmSrc(ImmSrcD)
    );

    // Immediate Extension
    imm_ext immext (
        .IMM_SEL(ImmSrcD),
        .IN(InstrD[31:7]),
        .OUT(ImmExtD)
    );

    // ID/EX Register
    wire RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, ZeroE;
    wire [1:0] ResultSrcE;
    wire [4:0] ALUControlE;
    wire [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE;
    wire [4:0] Rs1E, Rs2E, RdE;
    wire FlushE;
    id_ex_reg idex (
        .clk(clk),
        .reset(reset),
        .en(1'b1), // No StallE in diagram
        .clr(FlushE),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ALUControlD(ALUControlD),
        .ALUSrcD(ALUSrcD),
        .RD1D(RD1D),
        .RD2D(RD2D),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .ImmExtD(ImmExtD),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdD(RdD),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .ALUSrcE(ALUSrcE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .ImmExtE(ImmExtE),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE)
    );

    // Execute Stage
    wire [31:0] ALUResultM, WriteDataM, PCTargetE;
    wire [1:0] FwdAE, FwdBE;
    wire [31:0] SrcAE, SrcBE;

    // Forwarding Muxes
    wire [31:0] ResultM; // ALUResultM forwarded from Memory stage
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [1:0] ResultSrcW;
    mux3 fwdA (
        .d0(RD1E),
        .d1(ResultW),
        .d2(ResultM),
        .s(FwdAE),
        .y(SrcAE)
    );
    mux3 fwdB (
        .d0(RD2E),
        .d1(ResultW),
        .d2(ResultM),
        .s(FwdBE),
        .y(WriteDataM)
    );

    // ALU Source Mux (extended for PCE)
    wire [1:0] ALUSrcE_extended;
    assign ALUSrcE_extended = {JumpE, ALUSrcE}; // 2'b00: RD2E, 2'b01: ImmExtE, 2'b1x: PCE
    mux3 alu_srcB (
        .d0(WriteDataM),
        .d1(ImmExtE),
        .d2(PCE),
        .s(ALUSrcE_extended),
        .y(SrcBE)
    );

    // ALU
    alu alu (
        .A(SrcAE),
        .B(SrcBE),
        .ALUControlE(ALUControlE),
        .ALUResultM(ALUResultM),
        .ZeroE(ZeroE)
    );

    // Branch Target (using adder)
    adder branch_target_adder (
        .a(PCE),
        .b(ImmExtE),
        .y(PCTargetE)
    );

    // EX/MEM Register
    wire RegWriteM, MemWriteM, PCSrcE;
    wire [1:0] ResultSrcM;
    wire [4:0] RdM;
    wire [31:0] PCPlus4M;
    ex_mem_reg exmem (
        .clk(clk),
        .reset(reset),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .ALUResultE(ALUResultM),
        .WriteDataE(WriteDataM),
        .RdE(RdE),
        .PCPlus4E(PCPlus4E),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ResultM),
        .WriteDataM(WriteDataM),
        .RdM(RdM),
        .PCPlus4M(PCPlus4M)
    );
    assign PCSrcE = (BranchE & ZeroE) | JumpE; // Compute PCSrcE

    // Memory Stage
    wire [31:0] ReadDataM;
    data_memory dmem (
        .clk(clk),
        .WE(MemWriteM),
        .A(ResultM),
        .WD(WriteDataM),
        .RD(ReadDataM)
    );

    // MEM/WB Register
    mem_wb_reg memwb (
        .clk(clk),
        .reset(reset),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ResultM),
        .ReadDataM(ReadDataM),
        .RdM(RdM),
        .PCPlus4M(PCPlus4M),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .RdW(RdW),
        .PCPlus4W(PCPlus4W)
    );

    // Writeback Stage
    mux3 wb_mux (
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .s(ResultSrcW),
        .y(ResultW)
    );

    // Hazard Control
    hazard_control hazard (
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .RdM(RdM),
        .RdW(RdW),
        .PCSrcE(PCSrcE),
        .ResultSrcb0E(ResultSrcE[0]),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .FwdAE(FwdAE),
        .FwdBE(FwdBE)
    );

    // PC Selection
    mux2 pc_mux (
        .d0(PCPlus4F),
        .d1(PCTargetE),
        .s(PCSrcE),
        .y(PCNext)
    );
endmodule