`timescale 1ns / 1ps
`include "top.v"
`include "InstructionMem.v"
module rv32im_top_tb;
    // Inputs to the DUT
    reg clk;
    reg reset;
    wire done ; 

    // Instantiate the Device Under Test (DUT)
    rv32im_processor 
    dut(
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

        fork
            begin: program_completion
                wait(done == 1);
                repeat(20) @(posedge clk);
                $display("Program completed successfully!");
                disable timeout;  // Disable the timeout process
            end

            begin: timeout
                #1000000; 
                $display("Simulation timed out!");
                disable program_completion;  // Disable the completion process
            end
        join_any
        $stop;
    
    end


    

    //monitoring 
     initial begin
        $monitor("Time=%0t clk=%b reset=%b PCF=%h InstrF=%h", 
                 $time, clk, reset, dut.PCF, dut.InstrF);
     end

    // Dump waveform for debugging
    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, rv32im_top_tb);
    end



// assertions\\
// ============


// assertions to check the properties of the pipline registers 
// ------------------------------------------------------------
// IF_ID_PIPELINE_REG
property if_id_pipeline_reg_reset_checking; 
    @(posedge clk) $rose(reset) |-> ((dut.ifid.PCPlus4D == 0) && (dut.ifid.InstrD == 0));
endproperty 

property if_id_pipeline_reg_clr_checking;
    @(posedge clk) $rose(dut.ifid.clr) |=> ((dut.ifid.PCPlus4D == 0) && (dut.ifid.InstrD == 0));
endproperty

property if_id_pipeline_reg_pcplus4_propagation_checking;
    @(posedge clk) disable iff(reset | ^(dut.pcreg.PC) === 1'bx) (dut.ifid.en) |=> (dut.ifid.PCPlus4D == $past(dut.PCPlus4F));
endproperty

property if_id_pipeline_reg_instr_propagation_checking;
    @(posedge clk) disable iff(reset | ^(dut.pcreg.PC) === 1'bx) (dut.ifid.en) |=> (dut.ifid.InstrD == $past(dut.InstrF));
endproperty

assert property(if_id_pipeline_reg_reset_checking) 
    $info("Assertion passed: Reset correctly cleared PCPlus4D and InstrD at time %0t", $time);
    else $fatal("Assertion failed: Reset did not clear PCPlus4D and InstrD at time %0t", $time);

assert property(if_id_pipeline_reg_clr_checking)
    $info("Assertion passed: Clear correctly cleared PCPlus4D and InstrD at time %0t", $time);
    else $fatal("Assertion failed: Clear did not clear PCPlus4D and InstrD at time %0t", $time);

assert property(if_id_pipeline_reg_pcplus4_propagation_checking)
    $info("Assertion passed: PCPlus4D propagated correctly from PCPlus4F at time %0t", $time);
    else $fatal("Assertion failed: PCPlus4D did not propagate correctly from PCPlus4F at time %0t", $time);

assert property(if_id_pipeline_reg_instr_propagation_checking)
    $info("Assertion passed: InstrD propagated correctly from InstrF at time %0t", $time);
    else $fatal("Assertion failed: InstrD did not propagate correctly from InstrF at time %0t", $time);



//ID_EX_PIPELINE_REG 
property id_ex_pipeline_reg_reset_checking;
    @(posedge clk) $rose(reset) |-> (
        (dut.idex.RegWriteE == 0) &&
        (dut.idex.ResultSrcE == 0) &&
        (dut.idex.MemWriteE == 0) &&
        (dut.idex.JumpE == 0) &&
        (dut.idex.BranchE == 0) &&
        (dut.idex.ALUControlE == 5'b11111) &&
        (dut.idex.ALUSrcE == 0) &&
        (dut.idex.RD1E == 0) &&
        (dut.idex.RD2E == 0) &&
        (dut.idex.PCE == 0) &&
        (dut.idex.PCPlus4E == 0) &&
        (dut.idex.ImmExtE == 0) &&
        (dut.idex.Rs1E == 0) &&
        (dut.idex.Rs2E == 0) &&
        (dut.idex.RdE == 0)
    );
endproperty

property if_ex_pipeline_reg_clr_checking;
    @(posedge clk) $rose(dut.idex.clr) |=> (
        (dut.idex.RegWriteE == 0) &&
        (dut.idex.ResultSrcE == 0) &&
        (dut.idex.MemWriteE == 0) &&
        (dut.idex.JumpE == 0) &&
        (dut.idex.BranchE == 0) &&
        (dut.idex.ALUControlE == 5'b11111) &&
        (dut.idex.ALUSrcE == 0) &&
        (dut.idex.RD1E == 0) &&
        (dut.idex.RD2E == 0) &&
        (dut.idex.PCE == 0) &&
        (dut.idex.PCPlus4E == 0) &&
        (dut.idex.ImmExtE == 0) &&
        (dut.idex.Rs1E == 0) &&
        (dut.idex.Rs2E == 0) &&
        (dut.idex.RdE == 0)
    );
endproperty

property id_ex_pipeline_reg_propagation_checking;
    @(posedge clk) disable iff(reset | dut.idex.clr) (dut.idex.en && !dut.idex.clr) |=> (
        (dut.idex.RegWriteE == $past(dut.idex.RegWriteD)) &&
        (dut.idex.ResultSrcE == $past(dut.idex.ResultSrcD)) &&
        (dut.idex.MemWriteE == $past(dut.idex.MemWriteD)) &&
        (dut.idex.JumpE == $past(dut.idex.JumpD)) &&
        (dut.idex.BranchE == $past(dut.idex.BranchD)) &&
        (dut.idex.ALUControlE == $past(dut.idex.ALUControlD)) &&
        (dut.idex.ALUSrcE == $past(dut.idex.ALUSrcD)) &&
        (dut.idex.RD1E == $past(dut.idex.RD1D)) &&
        (dut.idex.RD2E == $past(dut.idex.RD2D)) &&
        (dut.idex.PCE == $past(dut.idex.PCD)) &&
        (dut.idex.PCPlus4E == $past(dut.idex.PCPlus4D)) &&
        (dut.idex.ImmExtE == $past(dut.idex.ImmExtD)) &&
        (dut.idex.Rs1E == $past(dut.idex.Rs1D)) &&
        (dut.idex.Rs2E == $past(dut.idex.Rs2D)) &&
        (dut.idex.RdE == $past(dut.idex.RdD))
    );
endproperty

assert property(id_ex_pipeline_reg_reset_checking)
    $info("Assertion passed: Reset correctly cleared all signals and set ALUControlE to 5'b11111 at time %0t", $time);
    else $fatal("Assertion failed: Reset did not clear all signals or set ALUControlE to 5'b11111 at time %0t", $time);

assert property(if_ex_pipeline_reg_clr_checking)
    $info("Assertion passed: Clear correctly cleared all signals and set ALUControlE to 5'b11111 at time %0t", $time);
    else $fatal("Assertion failed: Clear did not clear all signals or set ALUControlE to 5'b11111 at time %0t", $time);


assert property(id_ex_pipeline_reg_propagation_checking)
    $info("Assertion passed: Signals propagated correctly from D to E stage at time %0t", $time);
    else $fatal("Assertion failed: Signals did not propagate correctly from D to E stage at time %0t", $time);



//EX_MEM_PIPELINE_REG  & MEM_WB_PIPELINE_REG
//no stailing here or flushing 
property ex_mem_wb_pipeline_reg_reset_checking;
    @(posedge clk) $rose(reset) |-> (
        (dut.memwb.RegWriteW == 0) &&
        (dut.memwb.ResultSrcW == 0) &&
        (dut.memwb.ALUResultW == 0) &&
        (dut.memwb.ReadDataW == 0) &&
        (dut.memwb.RdW == 0) &&
        (dut.memwb.PCPlus4W == 0) &&

        (dut.exmem.RegWriteM == 0) &&
        (dut.exmem.ResultSrcM == 0) &&
        (dut.exmem.MemWriteM == 0) &&
        (dut.exmem.ALUResultM == 0) &&
        (dut.exmem.WriteDataM == 0) &&
        (dut.exmem.RdM == 0) &&
        (dut.exmem.PCPlus4M == 0)
    );
endproperty

property ex_mem_pipeline_reg_propagation_checking;
    @(posedge clk) disable iff(reset) (
        (dut.exmem.RegWriteM == $past(dut.exmem.RegWriteE)) &&
        (dut.exmem.ResultSrcM == $past(dut.exmem.ResultSrcE)) &&
        (dut.exmem.MemWriteM == $past(dut.exmem.MemWriteE)) &&
        (dut.exmem.ALUResultM == $past(dut.exmem.ALUResultE)) &&
        (dut.exmem.WriteDataM == $past(dut.exmem.WriteDataE)) &&
        (dut.exmem.RdM == $past(dut.exmem.RdE)) &&
        (dut.exmem.PCPlus4M == $past(dut.exmem.PCPlus4E))
    );
endproperty

property mem_wb_pipeline_reg_propagation_checking;
    @(posedge clk) disable iff(reset) (
        (dut.memwb.RegWriteW == $past(dut.memwb.RegWriteM)) &&
        (dut.memwb.ResultSrcW == $past(dut.memwb.ResultSrcM)) &&
        (dut.memwb.ALUResultW == $past(dut.memwb.ALUResultM)) &&
        (dut.memwb.ReadDataW == $past(dut.memwb.ReadDataM)) &&
        (dut.memwb.RdW == $past(dut.memwb.RdM)) &&
        (dut.memwb.PCPlus4W == $past(dut.memwb.PCPlus4M))
    );
endproperty

assert property(ex_mem_wb_pipeline_reg_reset_checking)
    $info("Assertion passed: Reset correctly cleared all MEM/WB signals at time %0t", $time);
    else $fatal("Assertion failed: Reset did not clear all EX/MEM/WB signals at time %0t", $time);

assert property(ex_mem_pipeline_reg_propagation_checking)
    $info("Assertion passed: Signals propagated correctly from EX to MEM stage at time %0t", $time);
    else $fatal("Assertion failed: Signals did not propagate correctly from EX to MEM stage at time %0t", $time);

assert property(mem_wb_pipeline_reg_propagation_checking)
    $info("Assertion passed: Signals propagated correctly from MEM to WB stage at time %0t", $time);
    else $fatal("Assertion failed: Signals did not propagate correctly from MEM to WB stage at time %0t", $time);






// assertions to check the properties of The Hazard Control Unit 
// --------------------------------------------------------------

data hazard
when the stallloading the pc stay the same and the content of the first pipeline reg stays the same and the content of the second pipeline reg flushes 
property load_store_hazard;
    @(posedge clk) (dut.hazard.ResultSrcb0E && ((dut.hazard.Rs1D == dut.hazard.RdE) || (dut.hazard.Rs2D == dut.hazard.RdE))) |=> 
    ($stable(dut.pcreg.PC) && $stable(dut.ifid.PCPlus4D) && $stable(dut.ifid.InstrD) && dut.idex.clr);
endproperty

property forwardingA_form_mem;
    @(posedge clk) (dut.hazard.Rs1E == dut.hazard.RdM && dut.hazard.RegWriteM && dut.hazard.Rs1E != 5'h0) |-> (dut.FwdAE == 10);
endproperty

property forwardingA_form_wb;
    @(posedge clk) (dut.hazard.Rs1E == dut.hazard.RdM && dut.hazard.RegWriteW && dut.hazard.Rs1E != 5'h0) |-> (dut.FwdAE == 01);
endproperty

property forwardingB_from_mem;
    @(posedge clk) (dut.hazard.Rs2E == dut.hazard.RdM && dut.hazard.RegWriteM && dut.hazard.Rs2E != 5'h0) |-> (dut.FwdBE == 10));
endproperty

property forwardingB_from_wb;
    @(posedge clk) ((dut.hazard.Rs2E == dut.hazard.RdM && dut.hazard.RegWriteW && dut.hazard.Rs2E != 5'h0) && dut.ALUSrcE == 0) |-> (dut.FwdBE == 01);
endproperty

property control_hazard;
    @(posedge clk) dut.hazard.PCSrcE |=> (dut.ifid.clr && dut.idex.clr);
endproperty


assert property(load_store_hazard)
    $info("Assertion passed: Load/store hazard handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Load/store hazard not handled correctly at time %0t", $time);

assert property(forwardingA_form_mem)
    $info("Assertion passed: Forwarding A from MEM handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Forwarding A from MEM not handled correctly at time %0t", $time);

assert property(forwardingA_form_wb)
    $info("Assertion passed: Forwarding A from WB handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Forwarding A from WB not handled correctly at time %0t", $time);

assert property(forwardingB_from_mem)
    $info("Assertion passed: Forwarding B from MEM handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Forwarding B from MEM not handled correctly at time %0t", $time);

assert property(forwardingB_from_wb)
    $info("Assertion passed: Forwarding B from WB handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Forwarding B from WB not handled correctly at time %0t", $time);

assert property(control_hazard)
    $info("Assertion passed: Control hazard handled correctly at time %0t", $time);
    else $fatal("Assertion failed: Control hazard not handled correctly at time %0t", $time);




// assertion checking the completing singal 
// ----------------------------------------
property done_signal_checking;
    @(posedge clk) disable iff(reset) 
    ((dut.MemWriteM && dut.ALUResultM == 32'h000000ff) || dut.imem.program_Done) ##1 done;
endproperty

assert property(done_signal_checking)
    $info("Assertion Passed: Done signal correctly asserted at time %0t", $time);
    else $fatal("Assertion Failed: Done signal not asserted after program completion at time %0t", $time);




//assertion to check Braching 
//----------------------------
property branch_checking;
    @(posedge clk) disable iff(reset) 
    ((dut.BranchE && dut.ZeroE) || dut.JumpE) |-> (dut.PCSrcE && (dut.PCNext == dut.PCTargetE));
endproperty

assert property(branch_checking)
    $info("Assertion Passed: branch signal correctly asserted at time %0t", $time);
    else $fatal("Assertion Failed: branch signal not asserted or PC not updated correctly at time %0t", $time);



endmodule
