module alu (
    input  [31:0] A,          // First 32-bit input (RD1E after forwarding)
    input  [31:0] B,          // Second 32-bit input (RD2E/ImmExtE after forwarding)
    input  [4:0]  ALUControlE, // 5-bit control signal (from ID/EX)
    output [31:0] ALUResultM, // 32-bit result (to EX/MEM)
    output        ZeroE       // Zero flag (1 if ALUResultM == 0, for branches)
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
    reg [63:0] mul_result; // For multiplication results (64-bit)
    reg [31:0] div_result, rem_result; // For division and remainder

    // Multiplication (64-bit result to handle MUL, MULH, MULHSU, MULHU)
    always @(*) begin
        case (ALUControlE)
            OP_MUL:    mul_result = $signed(A) * $signed(B);      // Signed * Signed (MUL)
            OP_MULH:   mul_result = $signed(A) * $signed(B);      // Signed * Signed (MULH)
            OP_MULHSU: mul_result = $signed(A) * $unsigned(B);    // Signed * Unsigned
            OP_MULHU:  mul_result = $unsigned(A) * $unsigned(B);  // Unsigned * Unsigned
            default:   mul_result = 64'h0;
        endcase
    end

    // Division and Remainder (with division-by-zero handling)
    always @(*) begin
        if (B == 32'h0) begin
            // RISC-V behavior for division by zero
            div_result = 32'hffffffff; // DIV, DIVU return -1
            rem_result = A;            // REM, REMU return the dividend
        end
        else begin
            case (ALUControlE)
                OP_DIV: begin
                    div_result = $signed(A) / $signed(B); // Signed division
                    rem_result = $signed(A) % $signed(B); // Signed remainder
                end
                OP_DIVU: begin
                    div_result = $unsigned(A) / $unsigned(B); // Unsigned division
                    rem_result = $unsigned(A) % $unsigned(B); // Unsigned remainder
                end
                OP_REM: begin
                    div_result = $signed(A) / $signed(B);
                    rem_result = $signed(A) % $signed(B);
                end
                OP_REMU: begin
                    div_result = $unsigned(A) / $unsigned(B);
                    rem_result = $unsigned(A) % $unsigned(B);
                end
                default: begin
                    div_result = 32'h0;
                    rem_result = 32'h0;
                end
            endcase
        end
    end

    // Main ALU logic
    always @(*) begin
        case (ALUControlE)
            OP_ADD:    result_reg = A + B;                            // Addition
            OP_SUB:    result_reg = A - B;                            // Subtraction
            OP_SLL:    result_reg = A << B[4:0];                      // Shift Left Logical
            OP_SLT:    result_reg = ($signed(A) < $signed(B)) ? 32'h1 : 32'h0; // Set Less Than (signed)
            OP_SLTU:   result_reg = ($unsigned(A) < $unsigned(B)) ? 32'h1 : 32'h0; // Set Less Than (unsigned)
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

    // Assign outputs
    assign ALUResultM = result_reg;
    assign ZeroE = (result_reg == 32'h0);
endmodule