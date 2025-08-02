module add_dec (
    input [31:0] add_in , 
    output [31:0] add_out 
);

assign add_out = {add_in[31:16],1'b1,add_in[14:0]};
    
endmodule