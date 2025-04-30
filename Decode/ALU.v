module alu (
    input  [31:0] A,          // First 32-bit input
    input  [31:0] B,          // Second 32-bit input
    input  [4:0]  ALUControl, // 5-bit control signal
    output [31:0] Result,     // 32-bit result
    output        Zero        // Zero flag (1 if Result == 0)
);

    // ALU operation codes (matching control_unit)
    localparam [4:0]
        OP_ADD    = 5'b00000,
        OP_SUB    = 5'b00010,
        OP_SLL    = 5'b00100,
        OP_SLT    = 5'b01000,
        OP_SLTU   = 5'b01100,
        OP_XOR    = 5'b10000,
        OP_SRL    = 5'b10100,
        OP_SRA    = 5'b10110,
        OP_OR     = 5'b11000,
        OP_AND    = 5'b11100,
        // M extension
        OP_MUL    = 5'b00001,
        OP_MULH   = 5'b00101,
        OP_MULHSU = 5'b01101,
        OP_MULHU  = 5'b01001,
        OP_DIV    = 5'b10001,
        OP_DIVU   = 5'b10101,
        OP_REM    = 5'b11001,
        OP_REMU   = 5'b11101,
        OP_NOP    = 5'b11111;

    reg [31:0] result_reg; // Internal result register
    wire [63:0] mul_result; // For multiplication results (64-bit)
    wire [31:0] div_result, rem_result; // For division and remainder

    // Main ALU logic
    always @(*) begin
        case (ALUControl)
            OP_ADD:    result_reg = A + B;                            // Addition
            OP_SUB:    result_reg = A - B;                            // Subtraction
            OP_SLL:    result_reg = A << B[4:0];                      // Shift Left Logical
            OP_SLT:    result_reg = ($signed(A) < $signed(B)) ? 32'h1 : 32'h0; // Set Less Than (signed)
            OP_SLTU:   result_reg = (A < B) ? 32'h1 : 32'h0;          // Set Less Than (unsigned)
            OP_XOR:    result_reg = A ^ B;                            // XOR
            OP_SRL:    result_reg = A >> B[4:0];                      // Shift Right Logical
            OP_SRA:    result_reg = $signed(A) >>> B[4:0];            // Shift Right Arithmetic
            OP_OR:     result_reg = A | B;                            // OR
            OP_AND:    result_reg = A & B;                            // AND
            OP_MUL:    result_reg = mul_result[31:0];                 // Multiplication (lower 32 bits)
            OP_MULH:   result_reg = mul_result[63:32];                // Multiplication (upper 32 bits, signed)
            OP_MULHSU: result_reg = mul_result[63:32];                // Multiplication (upper 32 bits, signed * unsigned)
            OP_MULHU:  result_reg = mul_result[63:32];                // Multiplication (upper 32 bits, unsigned)
            OP_DIV:    result_reg = div_result;                       // Division (signed)
            OP_DIVU:   result_reg = div_result;                       // Division (unsigned)
            OP_REM:    result_reg = rem_result;                       // Remainder (signed)
            OP_REMU:   result_reg = rem_result;                       // Remainder (unsigned)
            OP_NOP:    result_reg = 32'h0;                            // No operation
            default:   result_reg = 32'h0;                            // Default: output 0
        endcase
    end

    // Multiplication (64-bit result to handle MUL, MULH, MULHSU, MULHU)
    assign mul_result = (ALUControl == OP_MULHU) ? A * B :                          // Unsigned * Unsigned
                        (ALUControl == OP_MULHSU) ? $signed(A) * $unsigned(B) :     // Signed * Unsigned
                        $signed(A) * $signed(B);                                    // Signed * Signed (MUL, MULH)

    // Division and Remainder
    assign div_result = (ALUControl == OP_DIV) ? ($signed(A) / $signed(B)) :        // Signed division
                        (ALUControl == OP_DIVU) ? (A / B) : 32'h0;                  // Unsigned division
    assign rem_result = (ALUControl == OP_REM) ? ($signed(A) % $signed(B)) :        // Signed remainder
                        (ALUControl == OP_REMU) ? (A % B) : 32'h0;                  // Unsigned remainder

    // Assign outputs
    assign Result = result_reg;
    assign Zero = (result_reg == 32'h0);

endmodule