//-----------------------------------------------------------------------------
// Title            : cpu top.
// Project          : Intel CPU Garrage challange
//-----------------------------------------------------------------------------
// File             : cpu.sv
// Original Author  : Amichai Ben-David
// Created          : 4/2022
//-----------------------------------------------------------------------------
// Description :
// A 4 stage pipeline of the Nand2Tetris HACK CPU.
// The memory is merrored to the outside the core for VGA & other to observe.
// Added Accelerator to detect division operation and excecute them with ditcated logic.
// Able to excecute 2 instruciton per cycle  A type + C Type.
// Able to excecute 8/10 instructions in parralel incase of specific match.

`include "definitions.sv"
module cpu 
import cpu_pkg::*; 
(
        input  logic         clk,
        input  logic [3:0]   SW, //Not in Use.
        input  logic [20:0][15:0]  inst,
        input  logic [15:0]  in_m,
        input  logic         resetN,
        output logic [15:0] out_m,
        output logic        write_m,
        output logic [14:0] data_addr,
        output logic [14:0] inst_addr
    );


//==============================================
//      Signal Declaration
//==============================================
//  === Ctrl Bits ===
logic        StartDiv102;
logic        Clock;
logic        Reset;
logic        D_WrEn102 ,A_WrEn102 ,A_WrEnImm101 , M_WrEn102 , M_WrEn103, M_WrEn104, OutM_WrEn103;
logic        SelAType101 ;
logic        JmpCondMet102,JmpCondMet103;
logic        RstCtrlJmp103;
logic        CtrlDataHzrdM103,CtrlDataHzrdM104;
logic        SelMorA102;
logic        SsHit101;
logic        SelImmAsAluOut102;
logic        less_than_zero, greater_than_zero, zero;
logic        SelPcAcc;
logic        SelSs8Calc101,  SelSs8Calc102;
logic        SelSs10Calc101, SelSs10Calc102;
logic        M1WrEn102  , M4WrEn102  , M555WrEn102;
logic        Done;
logic        SelAccInst101;
logic  [5:0] CtrlAluOp102;
t_jmp_cond   JmpCond102  ; 
t_state      State;
//  === Data Path ===
logic [15:0] Quotient     , Remainder;
logic [15:0] Divident     , Divisor;
logic [15:0] NextD_Data102, PreD_Data101, D_Data101   , D_Data102   ;
logic [15:0] PreM_Data102 , M_Data102   , FwrM_Data103, FwrM_Data104;
logic [15:0] NextA_Data102, PreA_Data101, A_Data101   , A_Data102     , A_Data103,   A_Data104;
logic [15:0] AluIn1_102   , AluIn2_102  , AluData102  , PreAluData102 , AluData103 , OutAluData103;
logic [15:0] Immediate101 , Immediate102, Inst6_101   , Inst8_101;
logic [9:0]  AccPc        , PC100 , PC101  , NextPC100;
logic [15:0] Inst0FromAcc101, Inst1FromAcc101;
logic [15:0] Sequence[19:0];
logic [15:0] Ss8Calc102, Ss10Calc102;
logic [15:0] M1Data102 , M4Data102 , M555Data102;
logic [15:0] M1Data101 , M4Data101 , M555Data101;
logic [15:0] PreM1Data101 , PreM4Data101 , PreM555Data101;
logic [15:0] NextM1Data102 , NextM4Data102 , NextM555Data102;
//==== IO =====
assign Reset      = ~resetN;
assign Clock      = clk;
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
assign NextPC100 =  SelPcAcc       ? AccPc           :
                    JmpCondMet102  ? A_Data102[9:0]  :
                    SelSs8Calc101  ? (PC100 + 10'd8) :
                    SelSs10Calc101 ? (PC100 + 10'd10) :
                    SsHit101       ? (PC100 + 10'd2) :
                                     (PC100 + 10'd1) ;
`RST_MSFF(PC100 , NextPC100, Clock, Reset)
`RST_MSFF(PC101 , PC100, Clock, Reset)

// ========================
// === Decode Cycle 101 ===
// ========================
ctrl ctrl (
    .Clk              (Clock),              //input     logic        
    .Reset            (Reset),              //input     logic        
    .inst             (inst),             //input     logic [15:0] 
    .InstFromAcc101   ({Inst1FromAcc101,Inst0FromAcc101}),    //input     logic [15:0] 
    .State            (State),              //input     t_state      
    .SelAccInst101    (SelAccInst101),      //input     logic        
    .RstCtrlJmp103    (RstCtrlJmp103),      //input     logic
    .Immediate101     (Immediate101),       //output    logic [15:0] 
    .Inst6_101        (Inst6_101),          //output    logic [15:0] 
    .Inst8_101        (Inst8_101),          //output    logic [15:0] 
    .Divident         (Divident),           //output    logic [15:0] 
    .Divisor          (Divisor),            //output    logic [15:0] 
    .StartDiv102      (StartDiv102),        //output    logic        
    .M_WrEn102        (M_WrEn102),          //output    logic        
    .D_WrEn102        (D_WrEn102),          //output    logic        
    .A_WrEn102        (A_WrEn102),          //output    logic        
    .A_WrEnImm101     (A_WrEnImm101),       //output    logic        
    .JmpCond102       (JmpCond102),         //output    logic        
    .SelAType101      (SelAType101),        //output    logic        
    .CtrlAluOp102     (CtrlAluOp102),       //output    logic [5:0]  
    .SelMorA102       (SelMorA102),         //output    logic        
    .SsHit101         (SsHit101),           //output    logic        
    .SelSs8Calc101    (SelSs8Calc101),      //output    logic        
    .SelSs8Calc102    (SelSs8Calc102),      //output    logic        
    .SelSs10Calc101   (SelSs10Calc101),     //output    logic        
    .SelSs10Calc102   (SelSs10Calc102),     //output    logic        
    .SelImmAsAluOut102(SelImmAsAluOut102)   //output    logic        
);

acc_machine acc_machine (
    .Clk            (Clock),            //input    logic        
    .Reset          (Reset),            //input    logic    
    .Divident       (Divident),         //input    logic [MSB:0] 
    .Divisor        (Divisor),          //input    logic [MSB:0] 
    .Inst0FromAcc101(Inst0FromAcc101),  //output   logic [15:0] 
    .Inst1FromAcc101(Inst1FromAcc101),  //output   logic [15:0] 
    .SelAccInst101  (SelAccInst101),    //output   logic        
    .State          (State),            //output   t_state      
    .StartDiv102    (StartDiv102),      //input    logic        
    .PC100          (PC100),            //input    logic [9:0]  
    .AccPc          (AccPc),            //output   logic [9:0]  
    .Remainder      (Remainder),        //input    logic [MSB:0] 
    .Quotient       (Quotient),         //input    logic [MSB:0] 
    .Done           (Done),             //input    logic   
    .SelPcAcc       (SelPcAcc)          //output   logic        
);

div #( .MSB(15) ) div (
    .Clk            (Clock),      //input     logic         
    .Reset          (Reset),      //input     logic         
    .InDivident     (Divident),   //input     logic [MSB:0] 
    .InDivisor      (Divisor),    //input     logic [MSB:0] 
    .OutRemainder   (Remainder),  //output    logic [MSB:0] 
    .OutQuotient    (Quotient),   //output    logic [MSB:0] 
    .Start          (StartDiv102),//input     logic         
    .Done           (Done)        //output    logic   
    );       


// -- Data Path -- 
assign NextA_Data102 = SelAType101 ? Immediate101 : AluData102;
assign NextD_Data102 = AluData102;
`EN_MSFF(PreA_Data101 , NextA_Data102, Clock, A_WrEn102 || A_WrEnImm101)
`EN_MSFF(PreD_Data101 , NextD_Data102, Clock, D_WrEn102)
// Forwording unit:
assign A_Data101    =   A_WrEn102      ? NextA_Data102   :
                        SelSs8Calc101  ? Inst6_101       : 
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
//Local Copy of the M[4], M[1], M[555] -> Used to accelerate Calculations
assign NextM1Data102   = AluData102;
assign NextM4Data102   = AluData102;
assign NextM555Data102 = AluData102;
assign M1WrEn102       = M_WrEn102 && (A_Data102[9:0] == 10'd1);
assign M4WrEn102       = M_WrEn102 && (A_Data102[9:0] == 10'd4);
assign M555WrEn102     = M_WrEn102 && (A_Data102[9:0] == 10'd555);
`EN_MSFF(PreM1Data101    , NextM1Data102,    Clock , M1WrEn102)
`EN_MSFF(PreM4Data101    , NextM4Data102,    Clock , M4WrEn102)
`EN_MSFF(PreM555Data101  , NextM555Data102,  Clock , M555WrEn102)
assign M1Data101       = M1WrEn102   ? NextM1Data102   : PreM1Data101;
assign M4Data101       = M4WrEn102   ? NextM4Data102   : PreM4Data101;
assign M555Data101     = M555WrEn102 ? NextM555Data102 : PreM555Data101;

// Sample Data Path 101 -> 102 
`MSFF(M1Data102    , M1Data101    , Clock)
`MSFF(M4Data102    , M4Data101    , Clock)
`MSFF(M555Data102  , M555Data101  , Clock)
`MSFF(D_Data102    , D_Data101    , Clock)
`MSFF(A_Data102    , A_Data101    , Clock)
`MSFF(Immediate102 , Immediate101 , Clock)

// ======================================
// === Execute & Write Back Cycle 102 ===
// ======================================
//Hazard detection
assign CtrlDataHzrdM103 = (A_Data103 == A_Data102) && M_WrEn103;
assign CtrlDataHzrdM104 = (A_Data104 == A_Data102) && M_WrEn104;
//Forwording unit 103->102
assign M_Data102 = CtrlDataHzrdM103 ? FwrM_Data103 : 
                   CtrlDataHzrdM104 ? FwrM_Data104 :
                                      PreM_Data102 ;

//ALU module instantiation
assign   AluIn1_102      = D_Data102;
assign   AluIn2_102      = SelMorA102 ? M_Data102 : A_Data102;
alu alu0(
    .x      (AluIn1_102),
    .y      (AluIn2_102),
    .out    (PreAluData102),
    .fn     (CtrlAluOp102),
    .zero   (zero)
);
assign  Ss8Calc102  = Immediate102 - M1Data102 - M4Data102;
assign  Ss10Calc102 = Immediate102 - M1Data102 - M4Data102 + M555Data102;
assign  AluData102  = SelSs8Calc102     ? Ss8Calc102   :
                      SelSs10Calc102    ? Ss10Calc102  :
                      SelImmAsAluOut102 ? Immediate102 : 
                                          PreAluData102;
// Jump condition:
assign  less_than_zero    = AluData102[15];
assign  greater_than_zero = !(less_than_zero   || zero);
assign  JmpCondMet102     = (less_than_zero    && JmpCond102[2]) || 
                            (zero              && JmpCond102[1]) || 
                            (greater_than_zero && JmpCond102[0]);
//RstCtrlJmp103 used to "flush" the pipe when jmp -> Rst the 102 CTRL for 2 cycles. (Sync Reset)
`RST_MSFF( JmpCondMet103, JmpCondMet102 ,  Clock, Reset)
assign RstCtrlJmp103 = (JmpCondMet103 || JmpCondMet102) && (State == S_CHECK);
//RstCtrlJmp103 used to "flush" the pipe when jmp -> Rst the 102 CTRL for 2 cycles. (Sync Reset)
`RST_MSFF( JmpCondMet103, JmpCondMet102 ,  Clock, Reset)
assign RstCtrlJmp103 = (JmpCondMet103 || JmpCondMet102) && (State == S_CHECK);
// Sample Data Path 102 -> 103 (Used for Forwording unit & Hazard on the D_MEM read after Write
`RST_MSFF(     A_Data103    , A_Data102 , Clock, Reset)
`MSFF(     FwrM_Data103 , AluData102    , Clock)
// Local Memory
`RST_MSFF(     AluData103   , AluData102    , Clock, Reset)
`RST_VAL_MSFF( M_WrEn103    , M_WrEn102     , Clock, Reset, 1'b1)
// Merror Memory output (for VGA)
`MSFF(     OutAluData103, AluData102    , Clock)
`RST_MSFF( OutM_WrEn103 , M_WrEn102     , Clock, Reset)
// Sample Data Path 103 -> 104 (Used for Forwording unit & Hazard on the D_MEM read after Write
`RST_MSFF(     A_Data104    , A_Data103     , Clock, Reset)
`RST_MSFF(     FwrM_Data104 , FwrM_Data103  , Clock, Reset)
`RST_VAL_MSFF( M_WrEn104    , M_WrEn103     , Clock, Reset, 1'b1)

endmodule

