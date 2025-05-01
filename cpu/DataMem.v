module data_memory (
    input         clk, WE,      
    input  [31:0] A, WD,       
    output [31:0] RD           
);

    // Memory array: 256 words (1 KB, 256 * 32 bits)
    reg [31:0] mem [0:255];

    
    // Zero initialization
    initial begin
    for (integer i = 0; i < 256; i = i + 1)
        mem[i] = 32'h0;
    end

    // Combinational read (word-aligned)
    assign RD = mem[A[31:2]];

    // Synchronous write on positive clock edge
    always @(posedge clk)
        if (WE)
            mem[A[31:2]] <= WD;

endmodule