`timescale 1ns / 1ps
`include "top.v"
module rv32im_top_tb;
    // Inputs to the DUT
    reg clk;
    reg reset;

    // Instantiate the Device Under Test (DUT)
    rv32im_processor dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        #20; // Hold reset for 20 ns
        reset = 0;

        // Run simulation for a fixed time
        #1000; // Simulate for 1000 ns
        $finish;
    end

    // Monitor signals (optional, for debugging)
    initial begin
        $monitor("Time=%0t clk=%b reset=%b PCF=%h InstrF=%h", 
                 $time, clk, reset, dut.PCF, dut.InstrF);
    end

    // Dump waveform for debugging
    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, rv32im_top_tb);
    end
endmodule