//-----------------------------------------------------------------------------
// Title            : cpu top.
// Project          : Intel CPU Garrage channge
//-----------------------------------------------------------------------------
// File             : cpu.sv
// Original Author  : Amichai Ben-David
// Created          : 3/2022
//-----------------------------------------------------------------------------
// Description :
// A 4 stage pipeline of the Nand2Tetris HACK CPU.
// The memory is merrored to the outside the core for VGA & other to observe.
// Added Accelerator to detect division operation and excecute them with ditcated logic.
// Able to excecute 2 instruciton per cycle  A type + C Type.

`include "definitions.sv"
module cpu (
        input logic         clk,
        input logic [3:0]   SW, //Not in Use.
        input logic [15:0]  inst_0,
        input logic [15:0]  inst_1,
        input logic [15:0]  inst_2,
        input logic [15:0]  inst_3,
        input logic [15:0]  inst_4,
        input logic [15:0]  inst_5,
        input logic [15:0]  inst_6,
        input logic [15:0]  inst_7,
        input logic [15:0]  inst_8,
        input logic [15:0]  inst_9,
        //input logic [15:0]  inst_3,
        input logic [15:0]  in_m,
        input logic         resetN,
			
        output logic [15:0] out_m,
        output logic        write_m,
        output logic [14:0] data_addr,
        output logic [14:0] inst_addr
    );

//==============================================
//      paramters and typdefs
//==============================================

typedef enum logic [2:0] {
    NO_JMP = 3'b000,
    JGT	   = 3'b001,
    JEG	   = 3'b010,
    JGE	   = 3'b011,
    JLT	   = 3'b100,
    JNE	   = 3'b101,
    JLE	   = 3'b110,
    JMP	   = 3'b111
} t_jmp_cond ;
typedef enum logic {
    A_TYPE = 1'b0,
    C_TYPE = 1'b1 
} t_inst_type;
typedef enum logic [3:0] {
    S_CHECK   = 4'b0000,
    S_SET1_P1 = 4'b0001,
    S_SET1_P2 = 4'b0010,
    S_SET2_P1 = 4'b0101,
    S_SET2_P2 = 4'b0110,
    S_DIV     = 4'b1000
} t_state;
//==============================================
//      Signal Declaration
//==============================================
//  === Ctrl Bits ===
logic           D_WrEn101   ,   D_WrEn102   ;
logic           A_WrEn101   ,   A_WrEn102   ,A_WrEnImm101;
logic           M_WrEn101   ,   M_WrEn102   , M_WrEn103, M_WrEn104, OutM_WrEn103;
logic           SelAType101 ;
logic           JmpCondMet102,      JmpCondMet103;
logic           RstCtrlJmp103;
logic           CtrlDataHzrdM102,   CtrlDataHzrdM103;
logic  [5:0]    CtrlAluOp101,       CtrlAluOp102;
logic           SelMorA101,         SelMorA102;
t_inst_type     InstType101 ;
t_jmp_cond      JmpCond101  ,   JmpCond102  ; 

//  === Data Path ===
logic  [15:0]   NextD_Data102,  PreD_Data101,   D_Data101  ,   D_Data102   ;
logic  [15:0]   PreM_Data102,   M_Data102   ,   FwrM_Data103, FwrM_Data104;
logic  [15:0]   NextA_Data102,  PreA_Data101,   A_Data101  , A_Data102   , A_Data103, A_Data104;
logic  [9:0]    NextPC100;
logic  [15:0]   AluIn1_102;
logic  [15:0]   AluIn2_102;
logic  [15:0]   AluData102;
logic  [15:0]   PreAluData102;
logic  [15:0]   AluData103;
logic  [15:0]   OutAluData103;
logic  [15:0]   Immediate101,   Immediate102;

//assign interface to naming convention
logic           Clock;
logic           Reset;
logic [9:0]     NextAccPc;
logic [9:0]     AccPc;
logic [9:0]     PC100;
logic [9:0]     PC101;
logic [15:0]    Inst0_101;
logic [15:0]    Inst1_101;
logic [15:0]    Inst2_101;
logic [15:0]    Inst3_101;
logic [15:0]    Inst4_101;
logic [15:0]    Inst5_101;
logic [15:0]    Inst6_101;
logic [15:0]    Inst7_101;
logic [15:0]    Inst8_101;
logic [15:0]    Inst9_101;
logic SsHit101, SsHit102, LoadDfromA101, LoadMfromD101, LoadDfromM101, LoadDfromDminusM101, LoadDfromDplusM101, LoadMfromMplusOne101;
logic SelImmAsAluOut102,   SelImmAsAluOut101;
logic less_than_zero, greater_than_zero, zero;
logic SelPcAcc;
//logic          Match0;
//logic          Match1;
logic          SelAccInst101;
logic          EnAccPc;
logic [15:0]   Inst0FromAcc101;
logic [15:0]   Inst1FromAcc101;
logic [15:0]   Sequence[19:0];
//logic [4:0]    Count, NextCount;
t_state        State, NextState;
logic PreLoadDM_ImmMinuseMinuseM;
logic PreLoadDM_ImmMinuseMinusePlusM;
logic LoadDM_ImmMinuseMinuseM;
logic LoadDM_ImmMinuseMinusePlusM;
logic JmpSSHit101;
logic JmpSSHit102;
logic SelSs8Calc101;
logic SelSs10Calc101;
logic SelSs8Calc102;
logic SelSs10Calc102;
logic [15:0] Ss8Calc102  ;
logic [15:0] Ss10Calc102 ;
logic [15:0] M1Data102 , M4Data102 , M555Data102;
logic [15:0] M1Data101 , M4Data101 , M555Data101;
logic   M1WrEn102  , M4WrEn102  , M555WrEn102;
logic [15:0] PreM1Data101 , PreM4Data101 , PreM555Data101;
logic [15:0] NextM1Data102 , NextM4Data102 , NextM555Data102;
assign Reset      = ~resetN;
assign Clock      = clk;
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
//==== output =====
assign out_m      = OutAluData103;
assign write_m    = OutM_WrEn103 ;
assign data_addr  = A_Data103[14:0];
assign inst_addr  = {5'b0,PC100};
//==============================================
//      Module Content
//==============================================

// =======================
// === Fetch Cycle 100 ===
// =======================

assign SelPcAcc = ~(State == S_CHECK);
assign NextPC100 =  SelPcAcc      ? AccPc           :
                    JmpCondMet102 ? A_Data102[9:0]  :
                    SelSs8Calc101 ? (PC100 + 10'd7) :
                    SelSs10Calc101? (PC100 + 10'd9) :
                    SsHit101      ? (PC100 + 10'd2) :
                                    (PC100 + 10'd1) ;
`RST_MSFF(PC100 ,    NextPC100, Clock, Reset)
`MSFF(PC101 ,    PC100    , Clock)

// ========================
// === Decode Cycle 101 ===
// ========================
// -- ctrl bits --

always_comb begin
    InstType101  = (Inst0_101[15] == 1'b0) ? A_TYPE : C_TYPE; // (Inst0_101[15:13] == 3'b111) -> C_TYPE
    M_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[3];
    D_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[4];
    A_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[5];
    A_WrEnImm101 = (InstType101 == A_TYPE);
    JmpCond101   = (InstType101 == C_TYPE) ? t_jmp_cond'(Inst0_101[2:0]) : NO_JMP;// Cast enum if C_TYPE.
    SelAType101  = (InstType101 == A_TYPE);
    CtrlAluOp101 = Inst0_101[11:6];  // See Spec for details. Inst0_101[11:6] = Operation.
    SelMorA101  = Inst0_101[12];    // See Spec for details. Inst0_101[12] = A_vs_M.
    LoadDfromA101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1110110000010000); // "@xxx" && "D = A"
    LoadMfromD101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1110001100001000); // "@xxx" && "M = D"
    LoadDfromM101        = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111110000010000); // "@xxx" && "D = M"
    LoadDfromDminusM101  = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111010011010000); // "@xxx" && "D = D - M"
    LoadDfromDplusM101   = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111000010010000); // "@xxx" && "D = D + M"
    LoadMfromMplusOne101 = (Inst0_101[15] == 1'b0) && (Inst1_101 == 16'b1111110111001000); // "@xxx" && "M = M + 1"
    
    PreLoadDM_ImmMinuseMinuseM =   (Inst0_101[15] == 1'b0                ) && // @XXX
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
                && 
                (!RstCtrlJmp103);
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
        A_WrEnImm101 = 1'b1;
        CtrlAluOp101 = 6'b101010;   // AluOut = 0; - not in use for this operation
    end
end// always_comb

`RST_MSFF(SsHit102 ,     SsHit101,  Clock, Reset)
`RST_MSFF(SelSs8Calc102 ,SelSs8Calc101  ,  Clock, Reset)
`RST_MSFF(SelSs10Calc102,SelSs10Calc101 ,  Clock, Reset)
`RST_MSFF(JmpSSHit102 , JmpSSHit101,  Clock, Reset)
// ========================================================================
// === accelerator to detect & calc the Quation && Remainder             ===
// ========================================================================
logic [23:0] [15:0] History;
logic MatchP1Div101, MatchP2Div101, MatchP3Div101, MatchP4Div101;
logic MatchP1Div102, MatchP2Div102, MatchP3Div102, MatchP4Div102;
logic StartDiv102;
assign History[0] = Inst1_101;
assign History[1] = Inst0_101;
`EN_RST_MSFF(History[23:2] , History[21:0], Clock, (State == S_CHECK), Reset) //Shift 2 every Cycle
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

`RST_MSFF(MatchP1Div102, MatchP1Div101,  Clock, Reset)
`RST_MSFF(MatchP2Div102, MatchP2Div101,  Clock, Reset)
`RST_MSFF(MatchP3Div102, MatchP3Div101,  Clock, Reset)
`RST_MSFF(MatchP4Div102, MatchP4Div101,  Clock, Reset)
assign StartDiv102 = MatchP1Div102 && MatchP2Div102 && MatchP3Div102 && MatchP4Div102;
logic Done;
logic [15:0] Quotient;
logic [15:0] Remainder;
div #( .MSB(15) ) div (
    .Clk            (Clock),        //input     logic         
    .Reset          (Reset),        //input     logic         
    .InDivident     (History[19+2]),//input     logic [MSB:0] 
    .InDivisor      (History[15+2]),//input     logic [MSB:0] 
    .OutRemainder    (Remainder),     //output    logic [MSB:0] 
    .OutQuotient    (Quotient),     //output    logic [MSB:0] 
    .Start          (StartDiv102),  //input     logic         
    .Done           (Done)          //output    logic   
    );       
localparam BYPASS_DIV = 1;
logic BypassDivMatch; 
logic PreBypassDivMatch; 
logic SetBypassDivMatch; 
always_comb begin
   if(BYPASS_DIV == 1) SetBypassDivMatch = (History[19+2] == 16'd20000) && (History[15+2] == 16'd10);
   if(BYPASS_DIV == 0) SetBypassDivMatch = 0;
end
`EN_RST_MSFF(PreBypassDivMatch , 1'b1, Clock, SetBypassDivMatch, Reset || (State == S_SET2_P2) ) //Shift 2 every Cycle
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

assign NextAccPc = (PC100);
//`RST_MSFF(     Count, NextCount, Clock , Reset )
`EN_MSFF (     AccPc, NextAccPc, Clock , EnAccPc)
`RST_VAL_MSFF( State, NextState, Clock , Reset, S_CHECK)

// -- Data Path -- 
assign NextA_Data102 = SelAType101 ? Immediate101 : AluData102;
assign NextD_Data102 = AluData102;
`EN_MSFF(PreA_Data101    , NextA_Data102,    Clock, A_WrEn102 || A_WrEnImm101)
`EN_MSFF(PreD_Data101    , NextD_Data102,    Clock, D_WrEn102)
// Forwording unit:
assign A_Data101    =   SelSs8Calc101  ? Inst6_101       : 
                        SelSs10Calc101 ? Inst8_101       :
                        SsHit101       ? Immediate101    : PreA_Data101;
assign D_Data101    =   D_WrEn102      ? NextD_Data102   : PreD_Data101;

// Reading & Writing from Memory using A_Register as address.
ram #(.DATA_WIDTH          (16),
     .RAM_REGISTER_COUNT   (2**10))
        ram_inst1 (
    .address_a  (A_Data101[9:0]),//Read
    .address_b  (A_Data103[9:0]),//Write
    .clock_a    (Clock),
    .clock_b    (Clock),
    .data_a     ('0),
    .data_b     (AluData103),
    .wren_a     ('0),
    .wren_b     (M_WrEn103),
    .q_a        (PreM_Data102),
    .q_b        ()//Second port is for writing only!
);

assign NextM1Data102   = AluData102;
assign NextM4Data102   = AluData102;
assign NextM555Data102 = AluData102;
assign M1WrEn102    = M_WrEn102 && (A_Data102[9:0] == 10'd1);
assign M4WrEn102    = M_WrEn102 && (A_Data102[9:0] == 10'd4);
assign M555WrEn102  = M_WrEn102 && (A_Data102[9:0] == 10'd555);
`EN_MSFF(PreM1Data101    , NextM1Data102,    Clock , M1WrEn102)
`EN_MSFF(PreM4Data101    , NextM4Data102,    Clock , M4WrEn102)
`EN_MSFF(PreM555Data101  , NextM555Data102,  Clock , M555WrEn102)
assign M1Data101    = M1WrEn102   ? NextM1Data102   : PreM1Data101;
assign M4Data101    = M4WrEn102   ? NextM4Data102   : PreM4Data101;
assign M555Data101  = M555WrEn102 ? NextM555Data102 : PreM555Data101;
`MSFF(M1Data102    , M1Data101    , Clock)
`MSFF(M4Data102    , M4Data101    , Clock)
`MSFF(M555Data102  , M555Data101  , Clock)



// Sample Ctrl Bits 101 -> 102
`MSFF(         SelImmAsAluOut102,   SelImmAsAluOut101,  Clock)
`MSFF(         SelMorA102,         SelMorA101  ,      Clock)
`MSFF(         CtrlAluOp102,        CtrlAluOp101 ,      Clock)
`RST_MSFF(     D_WrEn102   ,        D_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     A_WrEn102   ,        A_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     M_WrEn102   ,        M_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_VAL_MSFF( JmpCond102  ,        JmpCond101   ,      Clock , (Reset || RstCtrlJmp103) , NO_JMP)
// Sample Data Path 101 -> 102 
`MSFF(D_Data102    , D_Data101    , Clock)
`MSFF(A_Data102    , A_Data101    , Clock)
`MSFF(Immediate102 , Immediate101 , Clock)


// ======================================
// === Execute & Write Back Cycle 102 ===
// ======================================
//Hazard detection
assign CtrlDataHzrdM102 = (A_Data103 == A_Data102) && M_WrEn103;
assign CtrlDataHzrdM103 = (A_Data104 == A_Data102) && M_WrEn104;
//Forwording unit 103->102
assign M_Data102 = CtrlDataHzrdM102 ? FwrM_Data103 : 
                   CtrlDataHzrdM103 ? FwrM_Data104 :
                                      PreM_Data102 ;

// input  D_Data102 , SelMorA102 , M_Data102 , 
// input  A_Data102, Immediate102, SelImmAsAluOut102, JmpCond102, 
// output JmpCondMet102, AluData102

    //ALU module instantiation
assign   AluIn1_102      = D_Data102;
assign   AluIn2_102      = SelMorA102 ? M_Data102 : A_Data102;
    alu alu0(
            .x(AluIn1_102),
            .y(AluIn2_102),
            .out(PreAluData102),
            .fn(CtrlAluOp102),
            .zero(zero)
        );
assign  Ss8Calc102  = Immediate102 - M1Data102 - M4Data102;
assign  Ss10Calc102 = Immediate102 - M1Data102 - M4Data102 + M555Data102;
assign  AluData102          = SelSs8Calc102     ? Ss8Calc102   :
                              SelSs10Calc102    ? Ss10Calc102  :
                              SelImmAsAluOut102 ? Immediate102 : 
                                                  PreAluData102;
// Jump condition:
assign  less_than_zero      = AluData102[15];
assign  greater_than_zero   = !(less_than_zero || zero);
assign  JmpCondMet102       = (less_than_zero && JmpCond102[2]) || 
                              (zero && JmpCond102[1])           || 
                              (greater_than_zero && JmpCond102[0]);

// Sample Data Path 102 -> 103 (Used for Forwording unit & Hazard on the D_MEM read after Write
`MSFF(     A_Data103    , A_Data102     ,  Clock)
`MSFF(     FwrM_Data103 , AluData102    ,  Clock)
//Local Memory
`MSFF(     AluData103 , AluData102    , Clock)
`RST_MSFF( M_WrEn103  , M_WrEn102     ,  Clock, Reset)
//Merror Memory output (for VGA)
`MSFF(     OutAluData103 , AluData102    , Clock)
`RST_MSFF( OutM_WrEn103  , M_WrEn102     ,  Clock, Reset)
//RstCtrlJmp103 used to "flush" the pipe when jmp -> Rst the 102 CTRL for 2 cycles. (Sync Reset)
`RST_MSFF( JmpCondMet103, JmpCondMet102 ,  Clock, Reset)
assign RstCtrlJmp103 = (JmpCondMet103 || JmpCondMet102) && (State == S_CHECK);

// Sample Data Path 103 -> 104 (Used for Forwording unit & Hazard on the D_MEM read after Write
`MSFF(     A_Data104    , A_Data103     ,  Clock)
`MSFF(     FwrM_Data104 , FwrM_Data103  ,  Clock)
`RST_MSFF( M_WrEn104    , M_WrEn103     ,  Clock, Reset)

endmodule
