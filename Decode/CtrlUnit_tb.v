`timescale 1ns / 1ps
`include "CtrlUnit.v"
module control_unit_tb;

    // Inputs
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg funct7b5;
    reg funct7b0;

    // Outputs
    wire RegWrite;
    wire [1:0] ResultSrc;
    wire MemWrite;
    wire Jump;
    wire Branch;
    wire [4:0] ALUControl;
    wire ALUSrc;
    wire [2:0] ImmSrc;

    // Instantiate the Unit Under Test (UUT)
    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .funct7b0(funct7b0),
        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .Jump(Jump),
        .Branch(Branch),
        .ALUControl(ALUControl),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc)
    );

    // Logging function to display signals
    task log_signals;
        input [31:0] test_num;
        input [99:0] instr_name;
        begin
            $display("Test %0d: %s", test_num, instr_name);
            $display("  Inputs:  opcode=0x%h, funct3=0x%h, funct7b5=%b, funct7b0=%b",
                     opcode, funct3, funct7b5, funct7b0);
            $display("  Outputs: RegWrite=%b, ResultSrc=0x%h, MemWrite=%b, Jump=%b, Branch=%b, ALUControl=0x%h, ALUSrc=%b, ImmSrc=0x%h",
                     RegWrite, ResultSrc, MemWrite, Jump, Branch, ALUControl, ALUSrc, ImmSrc);
            $display("--------------------------------------------------");
        end
    endtask

    initial begin
        // Initialize VCD dump
        $dumpfile("control_unit_tb.vcd");
        $dumpvars(0, control_unit_tb);

        // Initialize inputs
        opcode = 7'b0;
        funct3 = 3'b0;
        funct7b5 = 1'b0;
        funct7b0 = 1'b0;

        // Test cases
        #10;
        // Test 1: R-type ADD (opcode=0110011, funct3=000, funct7=0000000)
        opcode = 7'b0110011; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(1, "R-type ADD");
        // Expected: RegWrite=1, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=00000, ALUSrc=0, ImmSrc=100

        // Test 2: R-type MUL (opcode=0110011, funct3=000, funct7=0000001)
        opcode = 7'b0110011; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b1;
        #10;
        log_signals(2, "R-type MUL");
        // Expected: RegWrite=1, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=00001, ALUSrc=0, ImmSrc=100

        // Test 3: I-type ADDI (opcode=0010011, funct3=000)
        opcode = 7'b0010011; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(3, "I-type ADDI");
        // Expected: RegWrite=1, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=00000, ALUSrc=1, ImmSrc=100

        // Test 4: I-type SRAI (opcode=0010011, funct3=101, funct7b5=1)
        opcode = 7'b0010011; funct3 = 3'b101; funct7b5 = 1'b1; funct7b0 = 1'b0;
        #10;
        log_signals(4, "I-type SRAI");
        // Expected: RegWrite=1, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=10110, ALUSrc=1, ImmSrc=101

        // Test 5: Load (opcode=0000011, funct3=010)
        opcode = 7'b0000011; funct3 = 3'b010; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(5, "Load (LW)");
        // Expected: RegWrite=1, ResultSrc=01, MemWrite=0, Jump=0, Branch=0, ALUControl=00000, ALUSrc=1, ImmSrc=100

        // Test 6: Store (opcode=0100011, funct3=010)
        opcode = 7'b0100011; funct3 = 3'b010; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(6, "Store (SW)");
        // Expected: RegWrite=0, ResultSrc=00, MemWrite=1, Jump=0, Branch=0, ALUControl=00000, ALUSrc=1, ImmSrc=011

        // Test 7: Branch BEQ (opcode=1100011, funct3=000)
        opcode = 7'b1100011; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(7, "Branch (BEQ)");
        // Expected: RegWrite=0, ResultSrc=00, MemWrite=0, Jump=0, Branch=1, ALUControl=00010, ALUSrc=0, ImmSrc=010

        // Test 8: JAL (opcode=1101111)
        opcode = 7'b1101111; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(8, "JAL");
        // Expected: RegWrite=1, ResultSrc=11, MemWrite=0, Jump=1, Branch=0, ALUControl=00000, ALUSrc=0, ImmSrc=001

        // Test 9: JALR (opcode=1100111)
        opcode = 7'b1100111; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(9, "JALR");
        // Expected: RegWrite=1, ResultSrc=11, MemWrite=0, Jump=1, Branch=0, ALUControl=00000, ALUSrc=1, ImmSrc=100

        // Test 10: LUI (opcode=0110111)
        opcode = 7'b0110111; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(10, "LUI");
        // Expected: RegWrite=1, ResultSrc=10, MemWrite=0, Jump=0, Branch=0, ALUControl=00000, ALUSrc=0, ImmSrc=000

        // Test 11: AUIPC (opcode=0010111)
        opcode = 7'b0010111; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(11, "AUIPC");
        // Expected: RegWrite=1, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=00000, ALUSrc=1, ImmSrc=000

        // Test 12: Invalid opcode
        opcode = 7'b1111111; funct3 = 3'b000; funct7b5 = 1'b0; funct7b0 = 1'b0;
        #10;
        log_signals(12, "Invalid Opcode");
        // Expected: RegWrite=0, ResultSrc=00, MemWrite=0, Jump=0, Branch=0, ALUControl=11111, ALUSrc=0, ImmSrc=100

        // End simulation
        #10;
        $finish;
    end

endmodule