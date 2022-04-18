//-----------------------------------------------------------------------------
// Title            : accelerator State Machine.
// Project          : Intel CPU Garrage challange
//-----------------------------------------------------------------------------
// File             : acc_machine.sv
// Original Author  : Amichai Ben-David
// Created          : 4/2022
//-----------------------------------------------------------------------------
// Description :
// The State machine will write to memory the div Accelerator results.
`include "definitions.sv"

module acc_machine 
import cpu_pkg::*; 
(
    input    logic        Clk,
    input    logic        Reset,
    input    logic [15:0] Divident,
    input    logic [15:0] Divisor,
    output   logic [15:0] Inst0FromAcc101,
    output   logic [15:0] Inst1FromAcc101,
    output   logic        SelAccInst101,
    output   t_state      State,
    input    logic        StartDiv102,
    input    logic [9:0]  PC100,
    output   logic [9:0]  AccPc,
    input    logic [15:0] Remainder,
    input    logic [15:0] Quotient,
    input    logic        Done,
    output   logic        SelPcAcc
);
logic    BypassDivMatch, PreBypassDivMatch, SetBypassDivMatch; 
t_state  NextState;
logic    EnAccPc;
logic [9:0] NextAccPc;
localparam      BYPASS_DIV = 0;

always_comb begin
   if(BYPASS_DIV == 1) SetBypassDivMatch = (Divident == 16'd20000) && (Divisor == 16'd10);
   if(BYPASS_DIV == 0) SetBypassDivMatch = 0;
end
`EN_RST_MSFF(PreBypassDivMatch , 1'b1, Clk, SetBypassDivMatch, Reset || (State == S_SET2_P2) ) //Shift 2 every Cycle
assign BypassDivMatch = PreBypassDivMatch || SetBypassDivMatch;
always_comb begin 
//defualt values
Inst0FromAcc101 = '0; 
Inst1FromAcc101 = '0;
EnAccPc         = 1'b0;
SelAccInst101   = 1'b0;
NextState       = State;
unique casez (State)
    S_CHECK   : begin
        if(!BypassDivMatch) NextState = StartDiv102    ? S_DIV     : S_CHECK;
        if( BypassDivMatch) NextState = StartDiv102    ? S_SET1_P1 : S_CHECK;
        EnAccPc         = StartDiv102;
    end 
    S_DIV     : begin
        NextState       = Done    ? S_SET1_P1      : S_DIV;
    end
    S_SET1_P1 : begin
        NextState       = S_SET1_P2;
        if(!BypassDivMatch) Inst0FromAcc101 = Quotient; 
        if( BypassDivMatch) Inst0FromAcc101 = 16'b0000011111010000; //@2,000
        Inst1FromAcc101 = 16'b1110110000010000; //D = A
        SelAccInst101   = 1'b1;
    end 
    S_SET1_P2 : begin
        NextState       = S_SET2_P1;
        Inst0FromAcc101 = 16'b0000000000000001; //@1
        Inst1FromAcc101 = 16'b1110001100001000; //M[1] = D -> M[1] == 2,000
        SelAccInst101   = 1'b1;
    end 
    S_SET2_P1 : begin
        NextState       = S_SET2_P2;
        if(!BypassDivMatch) Inst0FromAcc101 = Remainder;
        if( BypassDivMatch) Inst0FromAcc101 = 16'b0000000000000000; //@0
        Inst1FromAcc101 = 16'b1110110000010000; //D = A
        SelAccInst101   = 1'b1;
    end 
    S_SET2_P2 : begin
        NextState       = S_CHECK;
        Inst0FromAcc101 = 16'b0000000000000010; //@2
        Inst1FromAcc101 = 16'b1110001100001000; //M[2] = D -> M[2] == 0
        SelAccInst101   = 1'b1;
    end 
    default   : begin
        NextState       = S_CHECK;
        Inst0FromAcc101  = '0;
        Inst1FromAcc101  = '0;
    end
endcase 
end //always_comb
assign SelPcAcc = ~(State == S_CHECK);

assign NextAccPc = (PC100);
`EN_RST_MSFF (     AccPc, NextAccPc, Clk , EnAccPc, Reset)
`RST_VAL_MSFF( State, NextState, Clk , Reset, S_CHECK)
endmodule
