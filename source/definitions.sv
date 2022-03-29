`ifndef macros_vh
`define macros_vh

////=== PLL
//// Uncomment the following line to use a PLL. Set the multiplication and division factors however you like.
////`define USE_PLL
//// max settings that worked for me:
//// kiwi -       250/100
//// de10-lite -  260/100
//`define PLL_MULTIPLY 240
//`define PLL_DIVIDE 100
//
//
////KIWI or DE10_LITE
//`include "platform.sv"
//
//`ifdef KIWI
//    `define SEG7_ACTIVE_LOW
//`endif
//==============================================
//      Usful Master Slave FliFlop macros
//==============================================
`define  MSFF(q,i,clk)              \
         always_ff @(posedge clk)   \
            q<=i;

`define  EN_MSFF(q,i,clk,en)        \
         always_ff @(posedge clk)   \
            if(en) q<=i;

`define  RST_MSFF(q,i,clk,rst)          \
         always_ff @(posedge clk) begin \
            if (rst) q <='0;            \
            else     q <= i;            \
         end

`define  EN_RST_MSFF(q,i,clk,en,rst)\
         always_ff @(posedge clk)   \
            if (rst)    q <='0;     \
            else if(en) q <= i;
`define  RST_VAL_MSFF(q,i,clk,rst,val) \
         always_ff @(posedge clk) begin    \
            if (rst) q <= val;             \
            else     q <= i;               \
         end
`endif