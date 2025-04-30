module imm_ext (
    input wire [1:0]  immsrc,
    input wire [24:0] in, //Instruction[31:7]
    output reg [31:0] ImmExt
);

    always @(*) begin
        case (immsrc)
            2'b00: ImmExt = {{20{in[24]}}, in[24:13]}; // S-type (stores)
            2'b01: ImmExt = {{20{in[24]}}, in[24:18], in[4:0]}; // B-type (branches)
            2'b10: ImmExt = {{20{in[24]}}, in[0], in[23:18], in[4:1], 1'b0}; // J-type (JAL)
            2'b11: ImmExt = {{12{in[24]}}, in[12:5], in[13], in[23:14], 1'b0}; 
            default: ImmExt = 32'bx; // Undefined
        endcase
    end

endmodule
