module regfile (
    input wire clk,
    input wire WEn3,
    input wire [4:0] A1,
    input wire [4:0] A2,
    input wire [4:0] A3,
    input wire [31:0] WD3,
    output wire [31:0] RD1,
    output wire [31:0] RD2
);
    // 32 registers, each 32 bits
    reg [31:0] regs [31:0];

    // Read ports (combinational)
    // x0 is hardwired to 32'b0.
    assign RD1 = (A1 == 5'd0) ? 32'b0 : regs[A1];
    assign RD2 = (A2 == 5'd0) ? 32'b0 : regs[A2];

    // Write port (synchronous)
    always @(posedge clk) begin
        if (WEn3 && (A3 != 5'd0)) begin
            regs[A3] <= WD3;
        end
    end

endmodule