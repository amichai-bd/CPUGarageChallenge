
`include "definitions.sv"
module abd_ram #(
              parameter DATA_WIDTH         ,
              parameter RAM_REGISTER_COUNT 
              )
               (input  logic                    clock_a    ,
                input  logic                    clock_b    ,
                input  logic [9:0]              address_a  ,
                input  logic [9:0]              address_b  ,
                input  logic [DATA_WIDTH-1:0]   data_a     ,
                input  logic [DATA_WIDTH-1:0]   data_b     ,
                input  logic                    wren_a     ,
                input  logic                    wren_b     ,
                output logic [DATA_WIDTH-1:0]   q_a        ,
                output logic [DATA_WIDTH-1:0]   q_b   
               );
logic [DATA_WIDTH-1:0]  mem     [RAM_REGISTER_COUNT-1:0];
logic [DATA_WIDTH-1:0]  next_mem[RAM_REGISTER_COUNT-1:0];
logic [DATA_WIDTH-1:0] pre_q_a;  

//=======================================
//          Writing to memory
//=======================================
always_comb begin
    next_mem = mem;
    if(wren_a) next_mem [address_a]= data_a;
    if(wren_b) next_mem [address_b]= data_b;
end 

//=======================================
//          the memory Array
//=======================================
`MSFF(mem, next_mem, clock_a)

//=======================================
//          reading the memory
//=======================================
assign pre_q_a = mem[address_a];
assign pre_q_b = mem[address_b];
// sample the read - synchorus read
`MSFF(q_a, pre_q_a, clock_a)
`MSFF(q_b, pre_q_b, clock_b)

endmodule
