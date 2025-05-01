module id_ex_reg (
    input         clk,
    input         reset,
    input         en,         // Enable (for stalling, e.g., ~StallE)
    input         clr,        // FlushE
    input         RegWriteD,
    input  [1:0]  ResultSrcD,
    input         MemWriteD,
    input         JumpD,
    input         BranchD,
    input  [2:0]  ALUControlD,
    input         ALUSrcD,
    input  [31:0] RD1D,
    input  [31:0] RD2D,
    input  [31:0] PCD,
    input  [31:0] PCPlus4D,
    input  [31:0] ImmExtD,
    input  [4:0]  Rs1D,
    input  [4:0]  Rs2D,
    input  [4:0]  RdD,
    output reg    RegWriteE,
    output reg [1:0] ResultSrcE,
    output reg    MemWriteE,
    output reg    JumpE,
    output reg    BranchE,
    output reg [2:0] ALUControlE,
    output reg    ALUSrcE,
    output reg [31:0] RD1E,
    output reg [31:0] RD2E,
    output reg [31:0] PCE,
    output reg [31:0] PCPlus4E,
    output reg [31:0] ImmExtE,
    output reg [4:0]  Rs1E,
    output reg [4:0]  Rs2E,
    output reg [4:0]  RdE
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteE   <= 0;
            ResultSrcE  <= 0;
            MemWriteE   <= 0;
            JumpE       <= 0;
            BranchE     <= 0;
            ALUControlE <= 0;
            ALUSrcE     <= 0;
            RD1E        <= 0;
            RD2E        <= 0;
            PCE         <= 0;
            PCPlus4E    <= 0;
            ImmExtE     <= 0;
            Rs1E        <= 0;
            Rs2E        <= 0;
            RdE         <= 0;
		  end else if (clr) begin
            RegWriteE   <= 0;
            ResultSrcE  <= 0;
            MemWriteE   <= 0;
            JumpE       <= 0;
            BranchE     <= 0;
            ALUControlE <= 0;
            ALUSrcE     <= 0;
            RD1E        <= 0;
            RD2E        <= 0;
            PCE         <= 0;
            PCPlus4E    <= 0;
            ImmExtE     <= 0;
            Rs1E        <= 0;
            Rs2E        <= 0;
            RdE         <= 0;
        end else if (en) begin
            RegWriteE   <= RegWriteD;
            ResultSrcE  <= ResultSrcD;
            MemWriteE   <= MemWriteD;
            JumpE       <= JumpD;
            BranchE     <= BranchD;
            ALUControlE <= ALUControlD;
            ALUSrcE     <= ALUSrcD;
            RD1E        <= RD1D;
            RD2E        <= RD2D;
            PCE         <= PCD;
            PCPlus4E    <= PCPlus4D;
            ImmExtE     <= ImmExtD;
            Rs1E        <= Rs1D;
            Rs2E        <= Rs2D;
            RdE         <= RdD;
        end
    end
endmodule
