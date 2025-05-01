module ex_mem_reg (
    input         clk,
    input         reset,
    input         RegWriteE,
    input  [1:0]  ResultSrcE,
    input         MemWriteE,
    input  [31:0] ALUResultE,
    input  [31:0] WriteDataE,
    input  [4:0]  RdE,
    input  [31:0] PCPlus4E,
    output reg    RegWriteM,
    output reg [1:0] ResultSrcM,
    output reg    MemWriteM,
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,
    output reg [4:0]  RdM,
    output reg [31:0] PCPlus4M
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteM   <= 0;
            ResultSrcM  <= 0;
            MemWriteM   <= 0;
            ALUResultM  <= 0;
            WriteDataM  <= 0;
            RdM         <= 0;
            PCPlus4M    <= 0;
        end else begin
            RegWriteM   <= RegWriteE;
            ResultSrcM  <= ResultSrcE;
            MemWriteM   <= MemWriteE;
            ALUResultM  <= ALUResultE;
            WriteDataM  <= WriteDataE;
            RdM         <= RdE;
            PCPlus4M    <= PCPlus4E;
        end
    end
endmodule
