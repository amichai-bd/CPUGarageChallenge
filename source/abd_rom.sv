`include "definitions.sv"
module abd_rom #(
              parameter INSTR_WIDTH         ,
              parameter ROM_REGISTER_COUNT 
              )
               (input  logic                    clock,
                input  logic [9:0]              address,
                output logic [INSTR_WIDTH-1:0]     q
               );
logic [INSTR_WIDTH-1:0]  mem     [ROM_REGISTER_COUNT-1:0];
logic [INSTR_WIDTH-1:0]  next_mem[ROM_REGISTER_COUNT-1:0];
logic [INSTR_WIDTH-1:0] pre_q;  

//=======================================
//          the memory Array
//=======================================
`MSFF(mem, next_mem, clock)

//=======================================
//          reading the memory
//=======================================
assign pre_q = mem[address];
// sample the read - synchorus read
`MSFF(q, pre_q, clock)

endmodule

