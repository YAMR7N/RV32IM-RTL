module hazard_control (
    input  [4:0] Rs1D,        // Source register 1 (Decode)
    input  [4:0] Rs2D,        // Source register 2 (Decode)
    input  [4:0] Rs1E,        // Source register 1 (Execute)
    input  [4:0] Rs2E,        // Source register 2 (Execute)
    input  [4:0] RdE,         // Destination register (Execute)
    input  [4:0] RdM,         // Destination register (Memory)
    input  [4:0] RdW,         // Destination register (Writeback)
    input        PCSrcE,      // Branch taken signal (Execute)
    input        ResultSrcb0E,// ResultSrc[0] (Execute, 1 for loads)
    input        RegWriteM,   // Register write enable (Memory)
    input        RegWriteW,   // Register write enable (Writeback)
    output       StallF,      // Stall Fetch stage
    output       StallD,      // Stall Decode stage
    output       FlushD,      // Flush Decode stage
    output       FlushE,      // Flush Execute stage
    output [1:0] FwdAE,       // Forwarding control for ALU input A
    output [1:0] FwdBE        // Forwarding control for ALU input B
);

    // Internal signal for load hazard
    wire lwStall;

    // Load hazard detection
    // lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE))
    assign lwStall = ResultSrcb0E & ((Rs1D == RdE) | (Rs2D == RdE));

    // Stall signals
    assign StallF = lwStall;
    assign StallD = lwStall;

    // Flush signals
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;

    // Forwarding logic for ALU input A (FwdAE)
    assign FwdAE = ((Rs1E == RdM) & RegWriteM & (Rs1E != 5'h0)) ? 2'b10 : // Forward from Memory
                   ((Rs1E == RdW) & RegWriteW & (Rs1E != 5'h0)) ? 2'b01 : // Forward from Writeback
                   2'b00;                                                // No forwarding

    // Forwarding logic for ALU input B (FwdBE)
    assign FwdBE = ((Rs2E == RdM) & RegWriteM & (Rs2E != 5'h0)) ? 2'b10 : // Forward from Memory
                   ((Rs2E == RdW) & RegWriteW & (Rs2E != 5'h0)) ? 2'b01 : // Forward from Writeback
                   2'b00;                                                // No forwarding

endmodule