module if_id_reg (
    input         clk,
    input         reset,
    input         en,        // StallD
    input         clr,       // FlushD
    input  [31:0] PCPlus4F,
    input  [31:0] InstrF,
    output reg [31:0] PCPlus4D,
    output reg [31:0] InstrD
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PCPlus4D <= 0;
            InstrD   <= 0;
        end else if (clr) begin
            PCPlus4D <= 0;
            InstrD   <= 0;
        end else if (en) begin
            PCPlus4D <= PCPlus4F;
            InstrD   <= InstrF;
        end
        // else: hold previous value (stall)
    end
endmodule
