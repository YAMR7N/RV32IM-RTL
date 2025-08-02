/*
module gpio #(
    parameter DATA_BITS    = 32,
    parameter ADDR_BITS    = 8,

    // Memory-mapped register base address
    parameter BASE_ADDR    = 32'h1000_0000,

    // Register Offsets
    parameter RGPIO_IN_OFFSET    = 32'h00,
    parameter RGPIO_OUT_OFFSET   = 32'h04,
    parameter RGPIO_OE_OFFSET    = 32'h08,
    parameter RGPIO_INTE_OFFSET  = 32'h0C,
    parameter RGPIO_PTRIG_OFFSET = 32'h10,
    parameter RGPIO_AUX_OFFSET   = 32'h14,
    parameter RGPIO_CTRL_OFFSET  = 32'h18,
    parameter RGPIO_INTS_OFFSET  = 32'h1C) 
    (
    input                   clk,
    input                   gpio_eclk, // Edge clock for GPIO input sampling
    input                   reset_n,
    input                   we,        // Write enable
    input                   re,        // Read enable
    input  [ADDR_BITS-1:0]  addr,      // Offset-based local address
    input  [DATA_BITS-1:0]  wdata,     // Write data
    input  [DATA_BITS-1:0]  alt_func_out, // Alternate function output (optional)
    output   irq,    // Interrupt request signal
    output reg [DATA_BITS-1:0] rdata,  // Read data output
    // Physical GPIO Pins
    inout  [DATA_BITS-1:0]  gpio_pins
);

//==============================
// Internal Registers
//==============================
reg  [DATA_BITS-1:0] rgpio_out;     // Output data (what we drive to pins)
reg  [DATA_BITS-1:0] rgpio_oe;      // Output enable (1 = output, 0 = input)
reg  [DATA_BITS-1:0] rgpio_in;
reg  [DATA_BITS-1:0] rgpio_in_prev; // Sampled input values (from gpio_pins)
reg  [DATA_BITS-1:0] rgpio_inte;    // Interrupt enable per pin
reg  [DATA_BITS-1:0] rgpio_ptrig;   // Interrupt trigger type (0 = falling, 1 = rising)
reg  [DATA_BITS-1:0] rgpio_aux;     // Alternate input source selection (optional)
reg  [3:0]           rgpio_ctrl;    // Control register (2-bit for now)
reg  [DATA_BITS-1:0] rgpio_ints;    // Interrupt status flags (sticky bits)
reg eclk_d1, eclk_d2;               // Edge clock for synchronizing input sampling
reg irq_reg;                        // Interrupt request register

//==============================
// Wires
//==============================
wire [DATA_BITS-1:0] rgpio_ints_next; // Next state of interrupt status flags
wire [DATA_BITS-1:0] pin_input_values; // Raw physical GPIO inputs
wire [DATA_BITS-1:0] rising_edge;      // Rising edge detection
wire [DATA_BITS-1:0] falling_edge;     // Falling edge detection
wire rising_edge_eclk;                 // Rising edge of gpio_eclk
wire falling_edge_eclk;                // Falling edge of gpio_eclk

//==============================
// GPIO Input Sampling
//==============================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) 
    begin
        rgpio_in <= 0;
        rgpio_out <= 0;
        rgpio_oe <= 0;
        rgpio_inte <= 0;
        rgpio_ptrig <= 0;
        rgpio_aux <= 0;
        rgpio_ctrl <= 0;
        rgpio_ints <= 0;
        eclk_d1 <= 0;
        eclk_d2 <= 0;
        rgpio_in_prev <= 0;
        rdata <= 0;
        irq_reg <= 0;
    end 
    else
    begin
        eclk_d1 <= gpio_eclk;
        eclk_d2 <= eclk_d1;
        rgpio_in_prev <= rgpio_in; // Store previous input state
        rgpio_ints <= rgpio_ints_next; // Update interrupt status flags
        
        // Safe interrupt detection (avoids unknowns)
        irq_reg <= (|rgpio_ints_next) ? 1'b1 : 
                  (rgpio_ints == 0) ? 1'b0 : irq_reg;
        
        // Sample GPIO inputs based on control settings
        if (rgpio_ctrl[0]) // Edge sampling mode
        begin
            if (rgpio_ctrl[1]) // Sample on rising edge
            begin
                if (rising_edge_eclk) 
                begin
                    rgpio_in <= gpio_pins;
                end
            end 
            else // Sample on falling edge
            begin
                if (falling_edge_eclk) 
                begin
                    rgpio_in <= gpio_pins;
                end
            end
        end
        else // Continuous sampling
        begin
            rgpio_in <= gpio_pins;
        end
        
        // Register read/write operations
        case(addr)
            RGPIO_IN_OFFSET: begin
                if (re) rdata <= rgpio_in;
            end

            RGPIO_OUT_OFFSET: begin
                if (we) rgpio_out <= wdata;
                else if (re) rdata <= rgpio_out;
            end

            RGPIO_OE_OFFSET: begin
                if (we) rgpio_oe <= wdata;
                else if (re) rdata <= rgpio_oe;
            end

            RGPIO_INTE_OFFSET: begin
                if (we) rgpio_inte <= wdata;
                else if (re) rdata <= rgpio_inte;
            end

            RGPIO_PTRIG_OFFSET: begin
                if (we) rgpio_ptrig <= wdata;
                else if (re) rdata <= rgpio_ptrig;
            end

            RGPIO_AUX_OFFSET: begin
                if (we) rgpio_aux <= wdata;
                else if (re) rdata <= rgpio_aux;
            end

            RGPIO_CTRL_OFFSET: begin
                if (we) rgpio_ctrl <= wdata[3:0];
                else if (re) rdata <= {{(DATA_BITS-4){1'b0}}, rgpio_ctrl};
            end

            RGPIO_INTS_OFFSET: begin 
                if (re) rdata <= rgpio_ints;
                if (we) rgpio_ints <= rgpio_ints & ~wdata;
            end

            default: rdata <= 0;
        endcase
    end
end

assign irq = irq_reg;

// Edge detection for the edge clock
assign rising_edge_eclk = (~eclk_d2 & eclk_d1);
assign falling_edge_eclk = (eclk_d2 & ~eclk_d1);
assign pin_input_values = gpio_pins;

// Generate per-pin logic
generate
    genvar i;
    for (i = 0; i < DATA_BITS; i = i + 1) 
    begin : rgpio_gen
        // Edge detection with known-safe logic
        reg rising_edge_bit, falling_edge_bit;
        
        always @(posedge clk or negedge reset_n) begin
            if (!reset_n) begin
                rising_edge_bit <= 0;
                falling_edge_bit <= 0;
            end else begin
                rising_edge_bit <= rgpio_in[i] && !rgpio_in_prev[i] && rgpio_ptrig[i];
                falling_edge_bit <= !rgpio_in[i] && rgpio_in_prev[i] && !rgpio_ptrig[i];
            end
        end
        
        // Interrupt status with protection against unknowns
        assign rgpio_ints_next[i] = (rgpio_ints[i] || 
                                    (rgpio_inte[i] && rgpio_ctrl[2] && 
                                    (rising_edge_bit || falling_edge_bit)));
        
        // Pin driver
        assign gpio_pins[i] = rgpio_aux[i] ? alt_func_out[i] : 
                             (rgpio_oe[i] ? rgpio_out[i] : 1'bz);
    end 
endgenerate

endmodule*/

module gpio #(
    parameter DATA_BITS    = 32,
    parameter ADDR_BITS    = 8,

    // Memory-mapped register base address
    parameter BASE_ADDR    = 32'h1000_0000,

    // Register Offsets
    parameter RGPIO_IN_OFFSET    = 32'h00,
    parameter RGPIO_OUT_OFFSET   = 32'h04,
    parameter RGPIO_OE_OFFSET    = 32'h08,
    parameter RGPIO_INTE_OFFSET  = 32'h0C,
    parameter RGPIO_PTRIG_OFFSET = 32'h10,
    parameter RGPIO_AUX_OFFSET   = 32'h14,
    parameter RGPIO_CTRL_OFFSET  = 32'h18,
    parameter RGPIO_INTS_OFFSET  = 32'h1C) 
    (
    input                   clk,
    input                   gpio_eclk, // Edge clock for GPIO input sampling
    input                   reset_n,
    input                   we,        // Write enable
    input                   re,        // Read enable
    input  [ADDR_BITS-1:0]  addr,      // Offset-based local address
    input  [DATA_BITS-1:0]  wdata,     // Write data
    input  [DATA_BITS-1:0]  alt_func_out, // Alternate function output (optional)
    output   irq,    // Interrupt request signal
    output reg [DATA_BITS-1:0] rdata,  // Read data output
    // Physical GPIO Pins
    inout  [DATA_BITS-1:0]  gpio_pins
);

//==============================
// Internal Registers
//==============================
reg  [DATA_BITS-1:0] rgpio_out;     // Output data (what we drive to pins)
reg  [DATA_BITS-1:0] rgpio_oe;      // Output enable (1 = output, 0 = input)
reg  [DATA_BITS-1:0] rgpio_in;
reg  [DATA_BITS-1:0] rgpio_in_prev;      // Sampled input values (from gpio_pins)
reg  [DATA_BITS-1:0] rgpio_inte;    // Interrupt enable per pin
reg  [DATA_BITS-1:0] rgpio_ptrig;   // Interrupt trigger type (0 = falling, 1 = rising)
reg  [DATA_BITS-1:0] rgpio_aux;     // Alternate input source selection (optional)
reg  [3:0]           rgpio_ctrl;    // Control register (2-bit for now)
reg  [DATA_BITS-1:0] rgpio_ints;    // Interrupt status flags (sticky bits)
reg eclk_d1, eclk_d2; // Edge clock for synchronizing input sampling
reg irq_reg; // Interrupt request register

//==============================
// Wires
//==============================
wire [DATA_BITS-1:0]rgpio_ints_next; // Next state of interrupt status flags
wire [DATA_BITS-1:0] pin_input_values;   // Raw physical GPIO inputs
wire [DATA_BITS-1:0] irq_condition;      // Triggered interrupt condition
wire [DATA_BITS-1:0] rising_edge; // Rising edge detection
wire [DATA_BITS-1:0] falling_edge; // Falling edge detection'
wire  rising_edge_eclk; // Physical GPIO pins
wire  falling_edge_eclk; // Physical GPIO pins

//==============================
// GPIO Input Sampling
//==============================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) 
    begin
        rgpio_in <= 0;
        rgpio_out <= 0;
        rgpio_oe <= 0;
        rgpio_inte <= 0;
        rgpio_ptrig <= 0;
        rgpio_aux <= 0;
        rgpio_ctrl <= 0;
        rgpio_ints <= 0;
        eclk_d1 <= 0;
        eclk_d2 <= 0;
        rgpio_in_prev <= 0; // Initialize previous input state
        rdata <= 0; // Initialize read data output
        irq_reg <= 0; // Initialize interrupt request signal

        
    end 
    else
    begin
        eclk_d1 <= gpio_eclk;
        eclk_d2 <= eclk_d1;
        rgpio_in_prev <= rgpio_in; // Store previous input state
        rgpio_ints <= rgpio_ints_next; // Update interrupt status flags
        irq_reg <= |rgpio_ints_next ; // Set IRQ if any interrupt is active
        // Sample GPIO inputs on the edge clock
        if (rgpio_ctrl[0]) // If control register bit 0 is set, sample inputs
        begin
            if (rgpio_ctrl[1]) // If control register bit 1 is set, sample on rising edge
            begin
                if (falling_edge_eclk) 
                begin
                    rgpio_in <= gpio_pins; // Sample GPIO inputs on rising edge of eclk
                end
            end 
            else // Sample on falling edge
            begin
                if (rising_edge_eclk) 
                begin
                    rgpio_in <= gpio_pins; // Sample GPIO inputs on falling edge of eclk
                end
            end
        end
        else // If control register bit 0 is not set, sample inputs on every clock cycle
        begin
            rgpio_in <= gpio_pins; // Sample GPIO inputs directly
        end
        
        case(addr)
            RGPIO_IN_OFFSET: begin
                if (re) begin
                    rdata <= rgpio_in; // Read input values
                end
            end

            RGPIO_OUT_OFFSET: 
                            begin
                                if (we) 
                                begin
                                    rgpio_out <= wdata; // Write output values
                                end 
                                else if (re) 
                                begin
                                    rdata <= rgpio_out; // Read output values
                                end
                            end

            RGPIO_OE_OFFSET: 
            begin
                if (we) 
                begin
                    rgpio_oe <= wdata; // Write output enable values
                end 
                else if (re) 
                begin
                    rdata <= rgpio_oe; // Read output enable values
                end
            end

            RGPIO_INTE_OFFSET: begin
                if (we) 
                begin
                    rgpio_inte <= wdata; // Write interrupt enable values
                    //rgpio_ctrl[2] <= |wdata; // Set control register bit 2 if any interrupt is enabled
                end 
                else if (re) 
                begin
                    rdata <= rgpio_inte; // Read interrupt enable values
                end
            end

            RGPIO_PTRIG_OFFSET: begin
                if (we) 
                begin
                    rgpio_ptrig <= wdata; // Write interrupt trigger type values
                end 
                else if (re) 
                begin
                    rdata <= rgpio_ptrig; // Read interrupt trigger type values
                end
            end

            RGPIO_AUX_OFFSET: begin
                if (we) 
                begin
                    rgpio_aux <= wdata; // Write auxiliary input source selection values
                end 
                else if (re) 
                begin
                    rdata <= rgpio_aux; // Read auxiliary input source selection values
                end
            end

            RGPIO_CTRL_OFFSET: begin
                if (we) 
                begin
                    rgpio_ctrl <= wdata[3:0]; // Write control register values (2 bits)
                end 
                else if (re) 
                begin
                    rdata <= {{(DATA_BITS-4){1'b0}}, rgpio_ctrl};  // generic zero-extension, rgpio_ctrl}; // Read control register values, zero-extend to DATA_BITS width
                end
            end

            RGPIO_INTS_OFFSET: begin 
                if (re) 
                begin
                    rdata <= rgpio_ints; // Read interrupt status flags 
                end 
                if (we) 
                begin
                    rgpio_ints <= rgpio_ints & ~wdata ; // Clear interrupt status on write
                   // irq_reg <= irq_reg & |(rgpio_ints & ~wdata); // Update IRQ based on cleared bits
                end
            end

            default: rdata <= 0; // Default case for unrecognized addresses
        endcase
    end
end

    assign irq = irq_reg; // Assign the interrupt request signal

    // Edge detection for the edge clock
    assign rising_edge_eclk = (~eclk_d2 & eclk_d1) ; // Rising edge detection with edge clock
    assign falling_edge_eclk = (eclk_d2 & ~eclk_d1);  // Falling edge detection with edge clock
    assign pin_input_values = gpio_pins;
            // Detect rising edge based on current and previous input values
           // assign rising_edge = (rgpio_in & ~rgpio_in_prev) & rgpio_ptrig;
            // Detect falling edge based on current and previous input values
            //assign falling_edge = (~rgpio_in & rgpio_in_prev) & ~rgpio_ptrig;
            // Set interrupt status if enabled and edge detected
            //assign rgpio_ints_next = (rgpio_inte & rgpio_ctrl[2] & (rising_edge | falling_edge));
    
    generate
        genvar i;
        for (i = 0; i < DATA_BITS; i = i + 1) 
        begin : rgpio_gen            
            // Use alternate function output if selected, otherwise drive output or high impedance
            assign gpio_pins[i] = rgpio_aux[i] ? alt_func_out[i] : (rgpio_oe[i] ? rgpio_out[i] : 1'bz);
            assign rgpio_ints_next[i] = (~rgpio_oe[i] & rgpio_inte[i] & rgpio_ctrl[2] & (rising_edge[i] | falling_edge[i]));
            assign rising_edge[i]  = (rgpio_in[i] & ~rgpio_in_prev[i]) & rgpio_ptrig[i];
            assign falling_edge[i] = (~rgpio_in[i] & rgpio_in_prev[i]) & ~rgpio_ptrig[i];

        end 
    endgenerate
    

endmodule