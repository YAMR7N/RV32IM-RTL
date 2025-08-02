module imm_ext (
    input wire [2:0]  IMM_SEL, // Immediate select op (from control_unit)
    input wire [24:0] IN,      // Instruction[31:7]
    output reg [31:0] OUT      // Sign-extended 32-bit value
);
    // Immediate selection codes (matching control_unit)
    localparam [2:0]
        IMM_U      = 3'b000,  // U-type (LUI, AUIPC)
        IMM_J      = 3'b001,  // J-type (JAL)
        IMM_B      = 3'b010,  // B-type (branches)
        IMM_S      = 3'b011,  // S-type (stores)
        IMM_I      = 3'b100,  // I-type (loads, JALR, ALU)
        IMM_I_SHFT = 3'b101,  // I-type (shifts: SLLI, SRLI, SRAI)
        IMM_IU     = 3'b111;  // I-type unsigned (not used in RV32IM)

    wire [31:0] U_OUT, J_OUT, B_OUT, I_SIGN_OUT, I_UNSIGN_OUT, S_OUT, I_SHIFT_OUT;

    // U-Type Immediate (LUI, AUIPC)
    assign U_OUT[11:0]  = {12{1'b0}};
    assign U_OUT[31:12] = IN[24:5];

    // J-Type Immediate (JAL)
    assign J_OUT[1:0]   = 2'b00;
    assign J_OUT[11:2]  = IN[23:14];
    assign J_OUT[12]    = IN[13];
    assign J_OUT[20:13] = IN[12:5];
    assign J_OUT[31:21] = {11{IN[24]}};

    // B-Type Immediate (branches)
    assign B_OUT[0]     = 1'b0;          // Always 0 (2-byte aligned)
    assign B_OUT[4:1]   = IN[4:1];       // imm[4:1] from instr[11:8]
    assign B_OUT[10:5]  = IN[23:18];     // imm[10:5] from instr[30:25]
    assign B_OUT[11]    = IN[0];         // imm[11] from instr[7]
    assign B_OUT[12]    = IN[24];        // imm[12] from instr[31]
    assign B_OUT[31:13] = {19{IN[24]}};

    // I-Type Immediate (signed, for loads, JALR, ALU ops)
    assign I_SIGN_OUT[11:0]  = IN[24:13];
    assign I_SIGN_OUT[31:12] = {20{IN[24]}};

    // I-Type Immediate (unsigned, not used in RV32IM)
    assign I_UNSIGN_OUT[11:0]  = IN[24:13];
    assign I_UNSIGN_OUT[31:12] = {20{1'b0}};

    // S-Type Immediate (stores)
    assign S_OUT[4:0]   = IN[4:0];
    assign S_OUT[11:5]  = IN[24:18];
    assign S_OUT[31:12] = {20{IN[24]}};

    // I-Type Immediate for Shifts (SLLI, SRLI, SRAI)
    assign I_SHIFT_OUT[4:0]  = IN[17:13];
    assign I_SHIFT_OUT[31:5] = {27{1'b0}};

    // Select the appropriate immediate
    always @(*) begin
        case (IMM_SEL)
            IMM_U:      OUT = U_OUT;        // U-type
            IMM_J:      OUT = J_OUT;        // J-type
            IMM_B:      OUT = B_OUT;        // B-type
            IMM_S:      OUT = S_OUT;        // S-type
            IMM_I:      OUT = I_SIGN_OUT;   // I-type (signed)
            IMM_I_SHFT: OUT = I_SHIFT_OUT;  // I-type (shifts)
            IMM_IU:     OUT = I_UNSIGN_OUT; // I-type (unsigned)
            default:    OUT = 32'h0;        // Undefined
        endcase
    end
endmodule