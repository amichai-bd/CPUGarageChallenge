//-----------------------------------------------------------------------------
// Title            : Core controller
// Project          : Intel CPU Garrage challange
//-----------------------------------------------------------------------------
// File             : ctrl.sv
// Original Author  : Amichai Ben-David
// Created          : 4/2022
//-----------------------------------------------------------------------------
// Description :
// This logic will get the Instruction & Decode acordangly.
// will set all the relevant Ctrl Bits & triger the Accelerator.

`include "definitions.sv"

module ctrl
import cpu_pkg::*; 
(
    input     logic        Clk,
    input     logic        Reset,
    input     logic [15:0] inst_0,
    input     logic [15:0] inst_1,
    input     logic [15:0] inst_2,
    input     logic [15:0] inst_3,
    input     logic [15:0] inst_4,
    input     logic [15:0] inst_5,
    input     logic [15:0] inst_6,
    input     logic [15:0] inst_7,
    input     logic [15:0] inst_8,
    input     logic [15:0] inst_9,
    input     logic [15:0] Inst0FromAcc101,
    input     logic [15:0] Inst1FromAcc101,
    input   t_state        State,
    input     logic        SelAccInst101,
    input     logic        RstCtrlJmp103,
    output    logic [15:0] Immediate101,
    output    logic [15:0] Inst6_101,
    output    logic [15:0] Inst8_101,
    output    logic [15:0] Divident,
    output    logic [15:0] Divisor,
    output    logic        StartDiv102,
    output    logic        M_WrEn102, 
    output    logic        D_WrEn102,
    output    logic        A_WrEn102,
    output    logic        A_WrEnImm101,
    output    t_jmp_cond   JmpCond102,
    output    logic        SelAType101,
    output    logic [5:0]  CtrlAluOp102,
    output    logic        SelMorA102,
    output    logic        SsHit101, 
    output    logic        SelSs8Calc101,
    output    logic        SelSs8Calc102,
    output    logic        SelSs10Calc101,
    output    logic        SelSs10Calc102,
    output    logic        SelImmAsAluOut102
);
// -- ctrl bits --
logic [15:0]Inst0_101,Inst1_101;
logic       JmpSSHit101, JmpSSHit102;
logic       SsHit102 ;
logic [15:0] Inst2_101, Inst3_101, Inst4_101;
logic [15:0] Inst5_101, Inst7_101, Inst9_101;
logic       M_WrEn101, D_WrEn101, A_WrEn101;
t_jmp_cond  JmpCond101;
logic [5:0] CtrlAluOp101 ;
logic       SelMorA101   ;
logic       LoadDfromA101       ;
logic       LoadMfromD101       ;
logic       LoadDfromM101       ;
logic       LoadDfromDminusM101 ;
logic       LoadDfromDplusM101  ;
logic       LoadMfromMplusOne101;
logic       PreLoadDM_ImmMinuseMinuseM;
logic       PreLoadDM_ImmMinuseMinusePlusM;
logic       LoadDM_ImmMinuseMinuseM;
logic       LoadDM_ImmMinuseMinusePlusM;
logic       MatchP1Div101, MatchP2Div101, MatchP3Div101, MatchP4Div101;
logic       MatchP1Div102, MatchP2Div102, MatchP3Div102, MatchP4Div102;
logic       SelImmAsAluOut101;
logic [23:0] [15:0] History;
t_inst_type InstType101;

assign Inst0_101  = SelAccInst101   ? Inst0FromAcc101: 
                    JmpSSHit102     ? '0             :
                    SsHit102        ? inst_1         : 
                                      inst_0         ;
assign Inst1_101  = SelAccInst101   ? Inst1FromAcc101: 
                    JmpSSHit102     ? '0             :
                    SsHit102        ? inst_2         :
                                      inst_1         ;
assign Inst2_101  = inst_2;
assign Inst3_101  = inst_3;
assign Inst4_101  = inst_4;
assign Inst5_101  = inst_5;
assign Inst6_101  = inst_6;
assign Inst7_101  = inst_7;
assign Inst8_101  = inst_8;
assign Inst9_101  = inst_9;
always_comb begin
    InstType101  = (Inst0_101[15] == 1'b0) ? A_TYPE : C_TYPE; // (Inst0_101[15:13] == 3'b111) -> C_TYPE
    M_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[3];
    D_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[4];
    A_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[5];
    A_WrEnImm101 = (InstType101 == A_TYPE);
    JmpCond101   = (InstType101 == C_TYPE) ? t_jmp_cond'(Inst0_101[2:0]) : NO_JMP;// Cast enum if C_TYPE.
    SelAType101  = (InstType101 == A_TYPE);
    CtrlAluOp101 = Inst0_101[11:6];  // See Spec for details. Inst0_101[11:6] = Operation.
    SelMorA101   = Inst0_101[12];    // See Spec for details. Inst0_101[12] = A_vs_M.
    LoadDfromA101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1110110000010000); // "@xxx" && "D = A"
    LoadMfromD101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1110001100001000); // "@xxx" && "M = D"
    LoadDfromM101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111110000010000); // "@xxx" && "D = M"
    LoadDfromDminusM101  = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111010011010000); // "@xxx" && "D = D - M"
    LoadDfromDplusM101   = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111000010010000); // "@xxx" && "D = D + M"
    LoadMfromMplusOne101 = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111110111001000); // "@xxx" && "M = M + 1"
    
    PreLoadDM_ImmMinuseMinuseM =  (Inst0_101[15] == 1'b0                ) && // @XXX
                                  (Inst1_101     == 16'b1110110000010000) && // D = A
                                  (Inst2_101     == 16'b0000000000000001) && // @1
                                  (Inst3_101     == 16'b1111010011010000) && // D = D - M
                                  (Inst4_101     == 16'b0000000000000100) && // @4
                                  (Inst5_101     == 16'b1111010011010000) && // D = D - M
                                  (Inst6_101[15] == 1'b0                ) && // @XXX
                                  (Inst7_101     == 16'b1110001100001000) ;  // M = D

    PreLoadDM_ImmMinuseMinusePlusM =(Inst0_101[15] == 1'b0                ) && // @XXX
                                    (Inst1_101     == 16'b1110110000010000) && // D = A
                                    (Inst2_101     == 16'b0000000000000001) && // @1
                                    (Inst3_101     == 16'b1111010011010000) && // D = D - M
                                    (Inst4_101     == 16'b0000000000000100) && // @4
                                    (Inst5_101     == 16'b1111010011010000) && // D = D - M
                                    (Inst6_101     == 16'b0000001000101011) && // @555
                                    (Inst7_101     == 16'b1111000010010000) && // D = D + M
                                    (Inst8_101[15] == 1'b0                ) && // @XXX
                                    (Inst9_101     == 16'b1110001100001000) ; // M = D

    LoadDM_ImmMinuseMinuseM       = PreLoadDM_ImmMinuseMinuseM       && (State == S_CHECK);
    LoadDM_ImmMinuseMinusePlusM   = PreLoadDM_ImmMinuseMinusePlusM   && (State == S_CHECK);
    SelSs8Calc101                 = LoadDM_ImmMinuseMinuseM;
    SelSs10Calc101                = LoadDM_ImmMinuseMinusePlusM;
    JmpSSHit101                   = (SelSs8Calc101 || SelSs10Calc101);

    SsHit101 = (LoadDfromA101       || LoadMfromD101      || LoadDfromM101  || 
                LoadDfromDminusM101 || LoadDfromDplusM101 || LoadMfromMplusOne101) 
                && (!RstCtrlJmp103);
    Immediate101 = Inst0_101;
    SelImmAsAluOut101     = 1'b0;   //default
    if(LoadDfromA101) begin         // "@xxx" && "D = A"
        D_WrEn101         = 1'b1;
        A_WrEnImm101      = 1'b1;
        SelImmAsAluOut101 = 1'b1;
    end
    if(LoadMfromD101) begin         // "@xxx" && "M = D"
        M_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b001100;   // AluOut = D;
    end
    if(LoadMfromMplusOne101) begin  // "@xxx" && "M = M + 1"
        M_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b110111;   // AluOut = D;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromM101) begin         // "@xxx" && "D = M"
        D_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b110000;   // AluOut = M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromDminusM101) begin   // "@xxx" && "D = D - M"
        D_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b010011;   // AluOut = D - M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromDplusM101) begin    // "@xxx" && "D = D - M"
        D_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b000010;   // AluOut = D + M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDM_ImmMinuseMinuseM || LoadDM_ImmMinuseMinusePlusM ) begin         // "@xxx" && "M = D"
        M_WrEn101    = 1'b1;
        D_WrEn101    = 1'b1;
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b101010;   // AluOut = 0; - not in use for this operation
    end
end// always_comb
// ========================================================================
// === accelerator to detect & calc the Quation && Remainder             ===
// ========================================================================
assign History[0] = Inst1_101;
assign History[1] = Inst0_101;
`EN_RST_MSFF(History[23:2] , History[21:0], Clk, (State == S_CHECK), Reset) //Shift 2 every Cycle
assign MatchP1Div101 =  (History[23]     == 16'b00) && (History[22] == 16'b1110110000010000) && //D     = 0             | (LIP) @0  , D = A
                        (History[21]     == 16'b01) && (History[20] == 16'b1110001100001000) && //M[X1] = D  | Quation  | @1        , M = D
                        (History[19][15] == 1'b0  ) && (History[18] == 16'b1110110000010000) ;  //D     = Divident      | @20000    , D = A
assign MatchP2Div101 =  (History[17]     == 16'b10) && (History[16] == 16'b1110001100001000) && //M[x2] = D             | @2        , M = D
                        (History[15][15] == 1'b0  ) && (History[14] == 16'b1110110000010000) && //D     = Deviser       | @10       , D = A
                        (History[13]     == 16'b11) && (History[12] == 16'b1110001100001000) ;  //M[x3] = D             | @3        , M = D
assign MatchP3Div101 =  (History[11]     == 16'b01) && (History[10] == 16'b1111110111001000) && //M[x1] = M[x1] + 1     | (LOOP) @1 , M = M + 1
                        (History[9]      == 16'b10) && (History[8]  == 16'b1111110000010000) && //D     = M[x2]         | @2        , D = M
                        (History[7]      == 16'b11) && (History[6]  == 16'b1111010011010000) ;  //D     = D - M[x3]     | @3        , D = D - M 
assign MatchP4Div101 =  (History[5]      == 16'b10) && (History[4]  == 16'b1110001100001000) && //M[x2] = D             | @2        , M = D
                        (History[3]      == 16'b10) && (History[2]  == 16'b1111110000010000) && //D     = M[x2]         | @2        , D = M
                        (History[1] [15] == 1'b0)   && (History[0]  == 16'b1110001100000001) ;  //(D>0) = Jump          | @LOOP     , D ;JGT
assign Divident = History[19+2];
assign Divisor  = History[15+2];
`RST_MSFF(MatchP1Div102, MatchP1Div101,  Clk, Reset)
`RST_MSFF(MatchP2Div102, MatchP2Div101,  Clk, Reset)
`RST_MSFF(MatchP3Div102, MatchP3Div101,  Clk, Reset)
`RST_MSFF(MatchP4Div102, MatchP4Div101,  Clk, Reset)
assign StartDiv102 = MatchP1Div102 && MatchP2Div102 && MatchP3Div102 && MatchP4Div102;

// Sample Ctrl Bits 101 -> 102
`MSFF(         SelImmAsAluOut102,  SelImmAsAluOut101,  Clk)
`MSFF(         SelMorA102  ,       SelMorA101   ,      Clk)
`MSFF(         CtrlAluOp102,       CtrlAluOp101 ,      Clk)
`RST_MSFF(     D_WrEn102   ,       D_WrEn101    ,      Clk, (Reset || RstCtrlJmp103) )
`RST_MSFF(     A_WrEn102   ,       A_WrEn101    ,      Clk, (Reset || RstCtrlJmp103) )
`RST_MSFF(     M_WrEn102   ,       M_WrEn101    ,      Clk, (Reset || RstCtrlJmp103) )
`RST_MSFF(     JmpSSHit102 ,       JmpSSHit101  ,      Clk, Reset)
`RST_MSFF(     SsHit102    ,       SsHit101     ,      Clk, Reset)
`RST_VAL_MSFF( JmpCond102  ,       JmpCond101   ,      Clk, (Reset || RstCtrlJmp103) , NO_JMP)
`RST_MSFF(SelSs8Calc102 ,SelSs8Calc101  ,  Clk, Reset)
`RST_MSFF(SelSs10Calc102,SelSs10Calc101 ,  Clk, Reset)

endmodule