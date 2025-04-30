// module control_unit (
//     input  [6:0] opcode,
//     input  [2:0] funct3,
//     input        funct7b5,
//     input        funct7b0,
//     output reg       RegWrite,
//     output reg [1:0] ResultSrc,
//     output reg       MemWrite,
//     output reg       Jump,
//     output reg       Branch,
//     output reg [4:0] ALUControl,
//     output reg       ALUSrc,
//     output reg [2:0] ImmSrc
// );

//     // ALU operation codes (based on ALU.txt and control_unit.txt)
//     localparam [4:0]
//         OP_ADD    = 5'b00000,
//         OP_SUB    = 5'b00010,
//         OP_SLL    = 5'b00100,
//         OP_SLT    = 5'b01000,
//         OP_SLTU   = 5'b01100,
//         OP_XOR    = 5'b10000,
//         OP_SRL    = 5'b10100,
//         OP_SRA    = 5'b10110,
//         OP_OR     = 5'b11000,
//         OP_AND    = 5'b11100,
//         // M extension
//         OP_MUL    = 5'b00001,
//         OP_MULH   = 5'b00101,
//         OP_MULHSU = 5'b01101,
//         OP_MULHU  = 5'b01001,
//         OP_DIV    = 5'b10001,
//         OP_DIVU   = 5'b10101,
//         OP_REM    = 5'b11001,
//         OP_REMU   = 5'b11101,
//         OP_NOP    = 5'b11111;

//     // Immediate selection codes (see Immediate_extender.txt)
//     localparam [2:0]
//         IMM_U      = 3'b000,
//         IMM_J      = 3'b001,
//         IMM_B      = 3'b010,
//         IMM_S      = 3'b011,
//         IMM_I      = 3'b100,
//         IMM_I_SHFT = 3'b101,
//         IMM_IU     = 3'b111;

//     // ResultSrc codes
//     localparam [1:0]
//         RES_ALU  = 2'b00,
//         RES_MEM  = 2'b01,
//         RES_IMM  = 2'b10,
//         RES_PC4  = 2'b11;

//     always @* begin
//         // Default values
//         RegWrite   = 1'b0;
//         ResultSrc  = RES_ALU;
//         MemWrite   = 1'b0;
//         Jump       = 1'b0;
//         Branch     = 1'b0;
//         ALUControl = OP_NOP;
//         ALUSrc     = 1'b0;
//         ImmSrc     = IMM_I;

//         case (opcode)
//             7'b0110011: begin // R-type (including M extension)
//                 RegWrite = 1'b1;
//                 ALUSrc   = 1'b0;
//                 case (funct3)
//                     3'b000: begin
//                         if      (funct7b0 == 1'b0 && funct7b5 == 1'b0) ALUControl = OP_ADD;    // ADD
//                         else if (funct7b0 == 1'b0 && funct7b5 == 1'b1) ALUControl = OP_SUB;    // SUB
//                         else if (funct7b0 == 1'b1 && funct7b5 == 1'b0) ALUControl = OP_MUL;    // MUL
//                         else ALUControl = OP_NOP;
//                     end
//                     3'b001: ALUControl = (funct7b0 == 1'b0) ? OP_SLL : OP_MULH;                // SLL/MULH
//                     3'b010: ALUControl = (funct7b0 == 1'b0) ? OP_SLT : OP_MULHSU;              // SLT/MULHSU
//                     3'b011: ALUControl = (funct7b0 == 1'b0) ? OP_SLTU : OP_MULHU;              // SLTU/MULHU
//                     3'b100: ALUControl = (funct7b0 == 1'b0) ? OP_XOR : OP_DIV;                 // XOR/DIV
//                     3'b101: begin
//                         if      (funct7b0 == 1'b0 && funct7b5 == 1'b0) ALUControl = OP_SRL;    // SRL
//                         else if (funct7b0 == 1'b0 && funct7b5 == 1'b1) ALUControl = OP_SRA;    // SRA
//                         else if (funct7b0 == 1'b1 && funct7b5 == 1'b0) ALUControl = OP_DIVU;   // DIVU
//                         else ALUControl = OP_NOP;
//                     end
//                     3'b110: ALUControl = (funct7b0 == 1'b0) ? OP_OR : OP_REM;                  // OR/REM
//                     3'b111: ALUControl = (funct7b0 == 1'b0) ? OP_AND : OP_REMU;                // AND/REMU
//                     default: ALUControl = OP_NOP;
//                 endcase
//             end
//             7'b0010011: begin // I-type ALU
//                 RegWrite = 1'b1;
//                 ALUSrc   = 1'b1;
//                 case (funct3)
//                     3'b000: ALUControl = OP_ADD; ImmSrc = IMM_I;
//                     3'b010: ALUControl = OP_SLT; ImmSrc = IMM_I;
//                     3'b011: ALUControl = OP_SLTU; ImmSrc = IMM_IU;
//                     3'b100: ALUControl = OP_XOR; ImmSrc = IMM_I;
//                     3'b110: ALUControl = OP_OR;  ImmSrc = IMM_I;
//                     3'b111: ALUControl = OP_AND; ImmSrc = IMM_I;
//                     3'b001: ALUControl = OP_SLL; ImmSrc = IMM_I_SHFT;
//                     3'b101: begin
//                         ImmSrc = IMM_I_SHFT;
//                         if (funct7b5 == 1'b0) ALUControl = OP_SRL;
//                         else                  ALUControl = OP_SRA;
//                     end
//                     default: ALUControl = OP_NOP;
//                 endcase
//             end
//             7'b0000011: begin // Loads
//                 RegWrite  = 1'b1;
//                 ALUSrc    = 1'b1;
//                 ResultSrc = RES_MEM;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_I;
//             end
//             7'b0100011: begin // Stores
//                 MemWrite  = 1'b1;
//                 ALUSrc    = 1'b1;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_S;
//             end
//             7'b1100011: begin // Branches
//                 Branch    = 1'b1;
//                 ALUControl= OP_SUB;
//                 ImmSrc    = IMM_B;
//             end
//             7'b1101111: begin // JAL
//                 RegWrite  = 1'b1;
//                 Jump      = 1'b1;
//                 ResultSrc = RES_PC4;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_J;
//             end
//             7'b1100111: begin // JALR
//                 RegWrite  = 1'b1;
//                 Jump      = 1'b1;
//                 ResultSrc = RES_PC4;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_I;
//             end
//             7'b0110111: begin // LUI
//                 RegWrite  = 1'b1;
//                 ResultSrc = RES_IMM;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_U;
//             end
//             7'b0010111: begin // AUIPC
//                 RegWrite  = 1'b1;
//                 ResultSrc = RES_ALU;
//                 ALUControl= OP_ADD;
//                 ImmSrc    = IMM_U;
//             end
//             default: begin
//                 RegWrite   = 1'b0;
//                 ResultSrc  = RES_ALU;
//                 MemWrite   = 1'b0;
//                 Jump       = 1'b0;
//                 Branch     = 1'b0;
//                 ALUControl = OP_NOP;
//                 ALUSrc     = 1'b0;
//                 ImmSrc     = IMM_I;
//             end
//         endcase
//     end
// endmodule












module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input        funct7b5,
    input        funct7b0,
    output reg       RegWrite,
    output reg [1:0] ResultSrc,
    output reg       MemWrite,
    output reg       Jump,
    output reg       Branch,
    output reg [4:0] ALUControl,
    output reg       ALUSrc,
    output reg [2:0] ImmSrc
);

    // ALU operation codes
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

    // Immediate selection codes
    localparam [2:0]
        IMM_U      = 3'b000,
        IMM_J      = 3'b001,
        IMM_B      = 3'b010,
        IMM_S      = 3'b011,
        IMM_I      = 3'b100,
        IMM_I_SHFT = 3'b101,
        IMM_IU     = 3'b111;

    // ResultSrc codes
    localparam [1:0]
        RES_ALU  = 2'b00,
        RES_MEM  = 2'b01,
        RES_IMM  = 2'b10,
        RES_PC4  = 2'b11;

    always @* begin
        // Default values
        RegWrite   = 1'b0;
        ResultSrc  = RES_ALU;
        MemWrite   = 1'b0;
        Jump       = 1'b0;
        Branch     = 1'b0;
        ALUControl = OP_NOP;
        ALUSrc     = 1'b0;
        ImmSrc     = IMM_I;

        case (opcode)
            7'b0110011: begin // R-type (including M extension)
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                if (funct7b5 == 1'b0 && funct7b0 == 1'b1) begin // M-extension (funct7 = 7'b0000001)
                    case (funct3)
                        3'b000: ALUControl = OP_MUL;    // MUL
                        3'b001: ALUControl = OP_MULH;   // MULH
                        3'b010: ALUControl = OP_MULHSU; // MULHSU
                        3'b011: ALUControl = OP_MULHU;  // MULHU
                        3'b100: ALUControl = OP_DIV;    // DIV
                        3'b101: ALUControl = OP_DIVU;   // DIVU
                        3'b110: ALUControl = OP_REM;    // REM
                        3'b111: ALUControl = OP_REMU;   // REMU
                        default: ALUControl = OP_NOP;
                    endcase
                end else begin // Standard R-type
                    case (funct3)
                        3'b000: begin
                            if (funct7b5 == 1'b0) ALUControl = OP_ADD; // ADD
                            else ALUControl = OP_SUB;                  // SUB
                        end
                        3'b001: ALUControl = OP_SLL;   // SLL
                        3'b010: ALUControl = OP_SLT;   // SLT
                        3'b011: ALUControl = OP_SLTU;  // SLTU
                        3'b100: ALUControl = OP_XOR;   // XOR
                        3'b101: begin
                            if (funct7b5 == 1'b0) ALUControl = OP_SRL; // SRL
                            else ALUControl = OP_SRA;                  // SRA
                        end
                        3'b110: ALUControl = OP_OR;    // OR
                        3'b111: ALUControl = OP_AND;   // AND
                        default: ALUControl = OP_NOP;
                    endcase
                end
            end
            7'b0010011: begin // I-type ALU
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                case (funct3)
                    3'b000: begin
                        ALUControl = OP_ADD;
                        ImmSrc = IMM_I;
                    end
                    3'b010: begin
                        ALUControl = OP_SLT;
                        ImmSrc = IMM_I;
                    end
                    3'b011: begin
                        ALUControl = OP_SLTU;
                        ImmSrc = IMM_I;
                    end
                    3'b100: begin
                        ALUControl = OP_XOR;
                        ImmSrc = IMM_I;
                    end
                    3'b110: begin
                        ALUControl = OP_OR;
                        ImmSrc = IMM_I;
                    end
                    3'b111: begin
                        ALUControl = OP_AND;
                        ImmSrc = IMM_I;
                    end
                    3'b001: begin
                        ALUControl = OP_SLL;
                        ImmSrc = IMM_I_SHFT;
                    end
                    3'b101: begin
                        ImmSrc = IMM_I_SHFT;
                        if (funct7b5 == 1'b0) ALUControl = OP_SRL; // SRLI
                        else ALUControl = OP_SRA;                  // SRAI
                    end
                    default: ALUControl = OP_NOP;
                endcase
            end
            7'b0000011: begin // Loads
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ResultSrc = RES_MEM;
                ALUControl= OP_ADD;
                ImmSrc    = IMM_I;
            end
            7'b0100011: begin // Stores
                MemWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ALUControl= OP_ADD;
                ImmSrc    = IMM_S;
            end
            7'b1100011: begin // Branches
                Branch    = 1'b1;
                ALUSrc    = 1'b0;
                ImmSrc    = IMM_B;
                case (funct3)
                    3'b000: ALUControl = OP_SUB; // BEQ
                    3'b001: ALUControl = OP_SUB; // BNE
                    3'b100: ALUControl = OP_SLT; // BLT
                    3'b101: ALUControl = OP_SLT; // BGE
                    3'b110: ALUControl = OP_SLTU; // BLTU
                    3'b111: ALUControl = OP_SLTU; // BGEU
                    default: ALUControl = OP_NOP;
                endcase
            end
            7'b1101111: begin // JAL
                RegWrite  = 1'b1;
                Jump      = 1'b1;
                ResultSrc = RES_PC4;
                ALUControl= OP_ADD;
                ImmSrc    = IMM_J;
            end
            7'b1100111: begin // JALR
                RegWrite  = 1'b1;
                Jump      = 1'b1;
                ResultSrc = RES_PC4;
                ALUControl= OP_ADD;
                ALUSrc    = 1'b1;
                ImmSrc    = IMM_I;
            end
            7'b0110111: begin // LUI
                RegWrite  = 1'b1;
                ResultSrc = RES_IMM;
                ALUControl= OP_ADD;
                ImmSrc    = IMM_U;
            end
            7'b0010111: begin // AUIPC
                RegWrite  = 1'b1;
                ResultSrc = RES_ALU;
                ALUControl= OP_ADD;
                ALUSrc    = 1'b1;
                ImmSrc    = IMM_U;
            end
            default: begin
                RegWrite   = 1'b0;
                ResultSrc  = RES_ALU;
                MemWrite   = 1'b0;
                Jump       = 1'b0;
                Branch     = 1'b0;
                ALUControl = OP_NOP;
                ALUSrc     = 1'b0;
                ImmSrc     = IMM_I;
            end
        endcase
    end
endmodule