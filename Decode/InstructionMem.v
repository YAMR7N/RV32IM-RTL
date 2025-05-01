module instruction_memory (
    input  [31:0] A,   // Address input (32-bit)
    output [31:0] RD   // Instruction output (32-bit)
);

    // Memory array: 256 words (1 KB, 256 * 32 bits)
    reg [31:0] mem [0:255];

    // Initialize memory from external hex file
    initial begin
    $readmemh("program.hex", mem);
    for (integer i = 0; i < 256; i = i + 1) begin
        if (mem[i] === 32'hx) begin
            mem[i] = 32'h00000000;
        end
    end
end
    // Read instruction (word-aligned access)
    assign RD = mem[A[31:2]];

endmodule