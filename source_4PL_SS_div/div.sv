`ifndef div_macros_vh
`define div_macros_vh
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

`endif //macros_vh

module div #( parameter MSB ) (
    input     logic         Clk,
    input     logic         Reset,
    input     logic [MSB:0] InDivident,
    input     logic [MSB:0] InDivisor,
    output    logic [MSB:0] OutReminder,
    output    logic [MSB:0] OutQuotient,
    input     logic         Start,
    output    logic         Done
);

logic [4:0]   Count       , NextCount;
logic         State       , NextState;
logic [MSB:0] FF_Divident , NextDivident;
logic [MSB:0] FF_Divsor   , NextDivsor  ;
logic [MSB:0] FF_Reminder , NextReminder;
logic [MSB:0] FF_Quotient , NextQuotient;
logic [MSB:0] SubDivFromRem;
logic         Negetive;
assign OutReminder = FF_Reminder;
assign OutQuotient = FF_Quotient;

`RST_MSFF(FF_Divident, NextDivident, Clk, Reset)
`RST_MSFF(FF_Divsor,   NextDivsor,   Clk, Reset)
`RST_MSFF(FF_Reminder, NextReminder, Clk, Reset)
`RST_MSFF(FF_Quotient, NextQuotient, Clk, Reset)
`RST_MSFF(State,       NextState,    Clk, Reset)
`RST_MSFF(Count,       NextCount,    Clk, Reset)
always_comb begin
    unique casez (State)
        1'b0    : NextState = Start            ? 2'b01 : 2'b00;
        1'b1    : NextState = (Count == MSB+1) ? 2'b10 : 2'b01;
        default : NextState = State;
    endcase 
    SubDivFromRem   = FF_Reminder - FF_Divsor;
    Negetive        = SubDivFromRem[MSB];
    if(State == 1'b0) begin
        Done         = 1'b1;
        NextCount    = '0;
        NextDivident = Start ? InDivident : FF_Divident;
        NextDivsor   = Start ? InDivisor  : FF_Divsor;
        NextReminder = Start ? '0       : FF_Reminder;
        NextQuotient = Start ? '0       : FF_Quotient;
    end else begin // (State == 1'b1)
        Done         = 1'b0;
        NextCount    = (Count + 1);
        NextDivident = {FF_Divident[MSB-1:0],1'b0} ;
        NextDivsor   = FF_Divsor ;
        NextQuotient = {FF_Quotient[MSB-1:0],(~Negetive)}; //shift Left - add 1'b1 incase the sub is positive.
        NextReminder = (Count == MSB+1) && Negetive    ? FF_Reminder                                : //Last Cycle
                       (Count == MSB+1) && (!Negetive) ? SubDivFromRem[MSB:0]                       : //Last Cycle
                       Negetive                        ? {FF_Reminder[MSB-1:0]  , FF_Divident[MSB]} : // Simple Shift
                                                         {SubDivFromRem[MSB-1:0], FF_Divident[MSB]} ; // (Reminder - Divisor) and Shift 
    end //else
end //always comb

endmodule