// Top-level memory interconnect for RISC-V processor for memory mapping
module memory_interconnect #(
    parameter PROGRAM_FILE = "program.hex", 
    parameter LAST_INSTRUCTION = 32'h00008067 
)

(
    input         clk,
    input         reset,      // Reset signal for GPIO
    // Instruction fetch interface
    input  [31:0] pc,        // Program counter
    output [31:0] inst_rd,   // Fetched instruction

    // Data load/store interface
    input         mem_we,    // Write-enable for data memory
    input  [31:0] addr,      // Data address bus
    input  [31:0] wdata,     // Data write bus
    output [31:0] rdata,     // Data read bus
    
    // GPIO interface
    inout  [31:0] gpio_pins, // GPIO pins
    output        gpio_irq   // GPIO interrupt
);

    //----------------------------------------------------------------------  
    // Address map: 
    // IMEM @ 0x0000_0000–0x0000_7FFF
    // DMEM @ 0x0000_8000–0x0000_FFFF  
    // GPIO @ 0x1000_0000–0x1000_00FF
    //----------------------------------------------------------------------  

    // Always fetch from instruction memory
    wire imem_sel = 1'b1;

    // Select data memory when addr[31:15]==0x0001
    wire dmem_sel = (addr[31:15] == 17'b0_0000_0000_0000_0001);
    
    // Select GPIO when addr[31:8]==0x100000 (GPIO base address 0x10000000)
    wire gpio_sel = (addr[31:8] == 24'h100000);

    //----------------------------------------------------------------------  
    // Wires to capture each memory's read‑data  
    //----------------------------------------------------------------------  
    wire [31:0] data_rd;
    wire [31:0] inst_rd_int;
    wire [31:0] gpio_rd;

    //----------------------------------------------------------------------  
    // Instantiate instruction memory  
    //----------------------------------------------------------------------  
    instruction_memory  #(
        .PROGRAM_FILE(PROGRAM_FILE),
        .LAST_INSTRUCTION(LAST_INSTRUCTION)
    )   
    imem_inst  
    (
        .A(pc),
        .RD(inst_rd_int)
    );
    //----------------------------------------------------------------------  
    // Address decoder for data memory 
    //----------------------------------------------------------------------  
    wire [31:0] decoded_addr;
    add_dec addr_decoder (
        .add_in(addr),
        .add_out(decoded_addr) 
    );
    //----------------------------------------------------------------------  
    // Instantiate data memory  
    //----------------------------------------------------------------------  
    data_memory dmem_inst (
        .clk(clk),
        .WE(mem_we & dmem_sel),
        .A(decoded_addr),
        .WD(wdata),
        .RD(data_rd)
    );

    //----------------------------------------------------------------------  
    // Instantiate GPIO module  
    //----------------------------------------------------------------------  
    gpio #(
        .DATA_BITS(32),
        .ADDR_BITS(8),
        .BASE_ADDR(32'h10000000)
    ) gpio_inst (
        .clk(clk),
        .gpio_eclk(clk),       // Use system clock for GPIO edge detection
        .reset_n(~reset),      // GPIO uses active-low reset
        .we(mem_we & gpio_sel),
        .re(~mem_we & gpio_sel), // Read enable when not writing and GPIO selected
        .addr(addr[7:0]),      // Use lower 8 bits for GPIO register addressing
        .wdata(wdata),
        .alt_func_out(32'h0),  // No alternate function for now
        .irq(gpio_irq),
        .rdata(gpio_rd),
        .gpio_pins(gpio_pins)
    );

    //----------------------------------------------------------------------  
    // Final output multiplexers  
    //----------------------------------------------------------------------  
    // Priority: GPIO > DMEM > default zero
    assign rdata   = gpio_sel ? gpio_rd : 
                    dmem_sel ? data_rd : 
                    32'h00000000;
    assign inst_rd = inst_rd_int;

endmodule
