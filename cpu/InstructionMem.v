module instruction_memory #(
    parameter PROGRAM_FILE = "program.hex",
    parameter LAST_INSTRUCTION = 32'h00008067
)(
    input  [31:0] A,   // Address input (32-bit)
    output [31:0] RD    // Instruction output (32-bit)
);

    // Memory array: 256 words (1 KB, 256 * 32 bits)
    reg [31:0] mem [0:255];
    integer i;

    // Initialize memory from external hex file
    initial begin    
        $display("Reading instructions from file: %s", PROGRAM_FILE);
        $readmemh(PROGRAM_FILE, mem);
        
        for (i = 0; i < 256; i = i + 1) begin
            // Initialize undefined locations to 0
            if (mem[i] === 32'hx) begin
                mem[i] = 32'h00000000;
            end
        end
        $display("Program loaded successfully with %0d instructions", i);
    end

    // Read instruction (word-aligned access)
    assign RD = mem[A[31:2]];

endmodule