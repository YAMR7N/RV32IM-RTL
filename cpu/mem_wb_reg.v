module mem_wb_reg (
    input         clk,
    input         reset,
    input         RegWriteM,
    input  [1:0]  ResultSrcM,
    input  [31:0] ALUResultM,
    input  [31:0] ReadDataM,
    input  [4:0]  RdM,
    input  [31:0] PCPlus4M,
    output reg    RegWriteW,
    output reg [1:0] ResultSrcW,
    output reg [31:0] ALUResultW,
    output reg [31:0] ReadDataW,
    output reg [4:0]  RdW,
    output reg [31:0] PCPlus4W
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteW   <= 0;
            ResultSrcW  <= 0;
            ALUResultW  <= 0;
            ReadDataW   <= 0;
            RdW         <= 0;
            PCPlus4W    <= 0;
        end else begin
            RegWriteW   <= RegWriteM;
            ResultSrcW  <= ResultSrcM;
            ALUResultW  <= ALUResultM;
            ReadDataW   <= ReadDataM;
            RdW         <= RdM;
            PCPlus4W    <= PCPlus4M;
        end
    end
endmodule
