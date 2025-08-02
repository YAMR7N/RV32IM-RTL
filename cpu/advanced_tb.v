`timescale 1ns / 1ps

module advanced_tb;
    // Inputs to the DUT
    reg clk;
    reg reset;
    wire done;

    // Instantiate the Device Under Test (DUT)
    rv32im_processor dut(
        .clk(clk),
        .reset(reset),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        #2;
        reset = 1;
        #20; // Hold reset for 20 ns
        reset = 0;
        
        // Wait for completion or timeout
        wait(done == 1);
        repeat(20) @(posedge clk);
        $display("=== ADVANCED RISC-V TEST COMPLETED ===");
        $display("Program finished successfully at time %0t", $time);
        $finish;
    end

    // Timeout protection
    initial begin
        #2000000; // 2ms timeout
        $display("TIMEOUT: Simulation terminated at %0t", $time);
        $finish;
    end

    // Monitor key signals
    always @(posedge clk) begin
        if (!reset) begin
            $monitor("Time=%0t PC=%h Instr=%h", 
                     $time, dut.PCF, dut.InstrF);
        end
    end

    // Dump waveform for debugging
    initial begin
        $dumpfile("advanced_test.vcd");
        $dumpvars(0, advanced_tb);
    end

endmodule 