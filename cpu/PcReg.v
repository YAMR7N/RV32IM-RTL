module pc_reg (
    input         clk, reset,
    input         en,        // Enable (for stalling, e.g., ~StallF)
    input  [31:0] PCNext,
    output reg [31:0] PC
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'h0;
        else if (en)
            PC <= PCNext;
    end
endmodule