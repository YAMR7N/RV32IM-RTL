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
`include "Address_Decoder.v"
`include "gpio.v"
`include "Interconnect.v"


module rv32im_processor #(
    parameter PROGRAM_FILE = "advanced_test_clean.hex", 
    parameter LAST_INSTRUCTION = 32'h00008067 
)
(
    input clk, reset ,
    output reg done,
    // GPIO interface
    inout  [31:0] gpio_pins,
    output        gpio_irq
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

    // // Instruction Memory
    // instruction_memory 
    // imem (
    //     .A(PCF),
    //     .RD(InstrF)
    // );
    
    
    wire MemWriteM ; 
    wire [31:0] ReadDataM, WriteDataM, ALUResultM;
    // Instruction Memory Interconnect
    memory_interconnect  #(
        .PROGRAM_FILE(PROGRAM_FILE),
        .LAST_INSTRUCTION(LAST_INSTRUCTION)
    )
    mem_intc
    (
    .clk(clk),
    .reset(reset),
    .pc(PCF),
    .inst_rd(InstrF),
    .mem_we(MemWriteM),
    .addr(ALUResultM),
    .wdata(WriteDataM),
    .rdata(ReadDataM),
    .gpio_pins(gpio_pins),
    .gpio_irq(gpio_irq)
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
    assign PCD = PCF; // Use current fetch PC

    

    // Decode Stage
    wire [4:0] Rs1D, Rs2D, RdD;
    wire [31:0] RD1D, RD2D, ImmExtD;
    wire RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, ALUSrcAD;
    wire [1:0] ResultSrcD;
    wire [4:0] ALUControlD;
    wire [2:0] ImmSrcD;

    // Extract instruction fields
    assign Rs1D = (InstrD[6:0] == 7'b0110111) ? 5'd0 : InstrD[19:15]; // Force x0 for LUI
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
    integer i ; 

    // Initialize registers to 0 (not in regfile module, added here for simulation)
    initial begin
        for (i = 0; i < 32; i = i + 1)
            rf.regs[i] = 32'h0;
    end

    // Control Unit
    wire BranchInvertD;
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
        .ALUSrcA(ALUSrcAD),
        .ImmSrc(ImmSrcD),
        .BranchInvert(BranchInvertD)
    );

    // Immediate Extension
    imm_ext immext (
        .IMM_SEL(ImmSrcD),
        .IN(InstrD[31:7]),
        .OUT(ImmExtD)
    );

    // ID/EX Register
    wire RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, ALUSrcAE, ZeroE;
    wire BranchInvertE;
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
        .ALUSrcAD(ALUSrcAD),
        .BranchInvertD(BranchInvertD),
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
        .ALUSrcAE(ALUSrcAE),
        .BranchInvertE(BranchInvertE),
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
    wire [31:0] ALUResultE , PCTargetE;
    wire [1:0] FwdAE, FwdBE;
    wire [31:0] SrcAE, SrcBE;
    wire [31:0] WriteDataE;

    // Forwarding Muxes
    wire [31:0] ResultM; // ALUResultM forwarded from Memory stage
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [1:0] ResultSrcW;
    wire [31:0] ForwardedB; // Intermediate signal for forwarded B value
    wire [31:0] ForwardedA; // Intermediate signal for forwarded A value
    
    mux3 fwdA (
        .d0(RD1E),
        .d1(ResultW),
        .d2(ALUResultM),
        .s(FwdAE),
        .y(ForwardedA)
    );
    
    // ALU Source A Mux (select between forwarded register value and PC)
    mux2 alu_srcA (
        .d0(ForwardedA),
        .d1(PCE),
        .s(ALUSrcAE),
        .y(SrcAE)
    );

    mux3 fwdB (
        .d0(RD2E),
        .d1(ResultW),
        .d2(ALUResultM),
        .s(FwdBE),
        .y(ForwardedB)  // FIXED: Output forwarded B value to intermediate signal
    );

    // ALU Source Mux for B input
    mux2 alu_srcB (
        .d0(ForwardedB),  // FIXED: Use forwarded B value instead of WriteDataE
        .d1(ImmExtE),
        .s(ALUSrcE),
        .y(SrcBE)
    );
    
    // WriteDataE should be the forwarded B value (for store operations)
    assign WriteDataE = ForwardedB;

    // ALU
    alu alu (
        .A(SrcAE),
        .B(SrcBE),
        .ALUControlE(ALUControlE),
        .ALUResultE(ALUResultE),
        .ZeroE(ZeroE)
    );

    // Branch Target (using adder)
    adder branch_target_adder (
        .a(PCE),
        .b(ImmExtE),
        .y(PCTargetE)
    );

    // EX/MEM Register
    wire RegWriteM , PCSrcE ;
    wire [1:0] ResultSrcM;
    wire [4:0] RdM;
    wire [31:0] PCPlus4M;
    ex_mem_reg exmem (
        .clk(clk),
        .reset(reset),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),

        
        //error corrected it was MemWriteM so there was a short circuit
        .MemWriteE(MemWriteE),
        //error conrrected it was ALUResultM there was a short circuit
        .ALUResultE(ALUResultE),

        .WriteDataE(WriteDataE),
        .RdE(RdE),
        .PCPlus4E(PCPlus4E),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .RdM(RdM),
        .PCPlus4M(PCPlus4M)
    );
    // Simpler branch logic using BranchInvert
    wire BranchCondition;
    // For SUB (used by BEQ/BNE): use Zero flag
    // For SLT/SLTU (used by BLT/BGE/BLTU/BGEU): use ALU result (1 if less, 0 if greater/equal)
    assign BranchCondition = (ALUControlE == 5'b00010) ? ZeroE :    // SUB: use Zero flag
                             ALUResultE[0];                          // SLT/SLTU: use result bit 0
    
    wire BranchTakenE;
    assign BranchTakenE = BranchInvertE ? ~BranchCondition : BranchCondition;
    
    assign PCSrcE = (BranchE & BranchTakenE) | JumpE; 




    // Memory Stage
    
    // Done signal logic (FIXED to trigger on JALR execution)
    initial begin
        done = 1'b0;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            done <= 0;
        end else if (MemWriteM && (ALUResultM == 32'h000000ff)) begin
            // METHOD 1: Software-controlled done signal
            done <= WriteDataM[0];
        end else if (InstrF == LAST_INSTRUCTION) begin
            // METHOD 2: Hardware detection of JALR execution
            $display("[%0t] JALR instruction (0x%08h) detected - terminating program", $time, InstrF);
            done <= 1;
        end
    end


    // data_memory dmem (
    //     .clk(clk),
    //     .WE(MemWriteM),
    //     .A(ALUResultM),
    //     .WD(WriteDataM),
    //     .RD(ReadDataM)
    // );



    // MEM/WB Register
    mem_wb_reg memwb (
        .clk(clk),
        .reset(reset),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
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