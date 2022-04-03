//-----------------------------------------------------------------------------
// Title            : cpu top.
// Project          : Intel CPU Garrage channge
//-----------------------------------------------------------------------------
// File             : cpu.sv
// Original Author  : Amichai Ben-David
// Created          : 3/2022
//-----------------------------------------------------------------------------
// Description :
// A 4 stage pipeline with the memory in the CPU.
// The memory is merrored to the outside the core for VGA & other to observe.


`include "definitions.sv"
module cpu (
        input logic         clk,
        input logic [3:0]   SW,
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

//==============================================
//      Signal Declaration
//==============================================
//  === Ctrl Bits ===
logic           D_WrEn101   ,   D_WrEn102   ;
logic           A_WrEn101   ,   A_WrEn102   ;
logic           M_WrEn101   ,   M_WrEn102   , M_WrEn103, M_WrEn104, OutM_WrEn103;
logic           SelAType101 ,   SelAType102 ;
logic           JmpCondMet102, JmpCondMet103;
logic           RstCtrlJmp103;
logic           CtrlDataHzrdM1_102, CtrlDataHzrdM1_103;
logic  [5:0]    CtrlAluOp101,   CtrlAluOp102;
logic           SelMorA101,   SelMorA102;
t_inst_type     InstType101 ;
t_jmp_cond      JmpCond101  ,   JmpCond102  ; 

//  === Data Path ===
logic  [15:0]   NextD_Data102,  PreD_Data101,   D_Data101  ,   D_Data102   ;
logic  [15:0]   PreM1_Data102,   M1_Data102   ,   FwrM_Data103, FwrM_Data104, M2_Data102, PreM2_Data102;
logic  [15:0]   PreA_Data101,   A_Data101  , NextA_Data101 ,  A_Data102   , A_Data103, A_Data104;
logic  [9:0]    NextPC100;
logic  [15:0]   AluIn1_102;
logic  [15:0]   AluIn2_102;
logic  [15:0]   AluData102;
logic  [15:0]   PreAluData102;
logic  [15:0]   AluData103;
logic  [15:0]   OutAluData103;
logic  [15:0]   Immediate101,   Immediate102;
logic  [15:0]   RegSrc1_101;
logic  [15:0]   RegSrc2_101;
logic  [15:0]   RegSrc2_102;
logic  [15:0]   RegDest_101;

//assign interface to naming convention
logic           Clock;
logic           Reset;
logic [9:0]    PC100;
logic [15:0]    Inst0_101, Inst1_101, Inst2_101, Inst3_101, Inst4_101, Inst5_101, Inst6_101, Inst7_101 ;
logic LoadDfromA101, LoadMfromD101, LoadDfromM101, LoadDfromDminusM101, LoadDfromDplusM101, LoadMfromMplusOne101, LoadMDfromMminusM101, LoadMDfromMminusM102;
logic SsHit101, SsHit102;
logic SuperSsHit101, SuperSsHit102;
logic SelImmAsAluOut102,   SelImmAsAluOut101;
logic less_than_zero, greater_than_zero, zero;
//==== input =====
assign Clock      = clk;
assign Inst0_101    =   SuperSsHit102 ? inst_7 :
                        SsHit102      ? inst_1 : 
                                        inst_0 ;
assign Inst1_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_2 : 
                                        inst_1 ;
assign Inst2_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_3  : 
                                        inst_2 ;
assign Inst3_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_4 : 
                                        inst_3 ;
assign Inst4_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_5 : 
                                        inst_4 ;
assign Inst5_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_6 : 
                                        inst_5 ;
assign Inst6_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_7 : 
                                        inst_6 ;
assign Inst7_101    =   SuperSsHit102 ? 16'b0  :
                        SsHit102      ? inst_8 : 
                                        inst_7 ;
assign Reset      = ~resetN;
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
assign NextPC100 = JmpCondMet102 ?  A_Data102[9:0]  :
                   SuperSsHit101 ?  (PC100 + 10'd8) :
                   SsHit101      ?  (PC100 + 10'd2) :
                                    (PC100 + 10'd1) ;

`RST_MSFF(PC100 ,    NextPC100, Clock, Reset)

// ========================
// === Decode Cycle 101 ===
// ========================
// -- ctrl bits --
always_comb begin
    InstType101  = (Inst0_101[15] == 1'b0) ? A_TYPE : C_TYPE; // (Inst0_101[15:13] == 3'b111) -> C_TYPE
    M_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[3];
    D_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[4];
    A_WrEn101    = (InstType101 == C_TYPE) && Inst0_101[5] || (InstType101 == A_TYPE);
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

    //This is 8 line SuperScalar
    //D,M[2] = M[2]-M[3]
    LoadMDfromMminusM101 = (Inst0_101[15]   == 1'b0)                 && //  @xSrc1
                           (Inst1_101[15:0] == 16'b1111110000010000) && //  D = M
                           (Inst2_101[15]   == 1'b0)                 && //  @xSrc2
                           (Inst3_101[15:0] == 16'b1111010011010000) && //  D = D - M 
                           (Inst4_101[15]   == 1'b0)                 && //  @xDest
                           (Inst5_101[15:0] == 16'b1110001100001000) && //  M = D
                           (Inst6_101[15:0] == Inst4_101[15:0]     ) && //  @xDest
                           (Inst7_101[15:0] == 16'b1111110000010000) ;  //  D = M
    RegSrc1_101  = Inst0_101;
    RegSrc2_101  = Inst2_101;
    RegDest_101  = Inst4_101;
    SuperSsHit101        = LoadMDfromMminusM101;

    SsHit101 = (LoadDfromA101       || LoadMfromD101      || LoadDfromM101  || 
                LoadDfromDminusM101 || LoadDfromDplusM101 || LoadMfromMplusOne101) && 
                (!RstCtrlJmp103) && 
                (!SuperSsHit101);
    Immediate101 = Inst0_101;
    SelImmAsAluOut101     = 1'b0;   //default
    if(LoadDfromA101) begin         // "@xxx" && "D = A"
        D_WrEn101         = 1'b1;
        A_WrEn101         = 1'b1;
        SelImmAsAluOut101 = 1'b1;
    end
    if(LoadMfromD101) begin         // "@xxx" && "M = D"
        M_WrEn101    = 1'b1;
        A_WrEn101    = 1'b1;
        CtrlAluOp101 = 6'b001100;   // AluOut = D;
    end
    if(LoadMfromMplusOne101) begin  // "@xxx" && "M = M + 1"
        M_WrEn101    = 1'b1;
        A_WrEn101    = 1'b1;
        CtrlAluOp101 = 6'b110111;   // AluOut = D;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromM101) begin         // "@xxx" && "D = M"
        D_WrEn101    = 1'b1;
        A_WrEn101    = 1'b1;
        CtrlAluOp101 = 6'b110000;   // AluOut = M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromDminusM101) begin   // "@xxx" && "D = D - M"
        D_WrEn101    = 1'b1;
        A_WrEn101    = 1'b1;
        CtrlAluOp101 = 6'b010011;   // AluOut = D - M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadDfromDplusM101) begin    // "@xxx" && "D = D - M"
        D_WrEn101    = 1'b1;
        A_WrEn101    = 1'b1;
        CtrlAluOp101 = 6'b000010;   // AluOut = D + M;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
    end
    if(LoadMDfromMminusM101) begin 
        D_WrEn101    = 1'b1;
        M_WrEn101    = 1'b1;
        SelMorA101   = 1'b1;        // Sel M as ALU Input
        CtrlAluOp101 = 6'b000111;   // 
    end
end// always_comb


`RST_MSFF(SsHit102             , SsHit101,              Clock, Reset)
`RST_MSFF(SuperSsHit102        , SuperSsHit101,         Clock, Reset)
`RST_MSFF(LoadMDfromMminusM102 , LoadMDfromMminusM101,  Clock, Reset)
// -- Data Path -- 
//assign NextA_Data102 = SelAType102 ? Immediate102 : AluData102;
assign NextA_Data101 = Immediate101;//TODO - Not supporting Load from ALU Out.
assign NextD_Data102 = AluData102;
`EN_MSFF(PreA_Data101,  NextA_Data101,   Clock, A_WrEn101)
`EN_MSFF(PreD_Data101,  NextD_Data102,   Clock, D_WrEn102)
// Forwording unit:

assign A_Data101 = SuperSsHit101 ? RegSrc1_101   :
                   SsHit101      ? Immediate101  : PreA_Data101;
assign D_Data101 = D_WrEn102     ? NextD_Data102 : PreD_Data101;

// Reading & Writing from Memory using A_Register as address.
ram #(.DATA_WIDTH          (16),
     .RAM_REGISTER_COUNT   (2**10))
        ram_inst0 (
    .address_a  (A_Data101[9:0]),//Read
    .address_b  (A_Data103[9:0]),//Write
    .clock_a    (Clock),
    .clock_b    (Clock),
    .data_a     ('0),
    .data_b     (AluData103),
    .wren_a     ('0),
    .wren_b     (M_WrEn103),
    .q_a        (PreM1_Data102),
    .q_b        ()//Second port is for writing only!
);
// read from memory with a second port (same write port so data is the same)
ram #(.DATA_WIDTH          (16),
     .RAM_REGISTER_COUNT   (2**10))
        ram_inst1 (
    .address_a  (RegSrc2_101[9:0]),//Read
    .address_b  (A_Data103[9:0]),//Write
    .clock_a    (Clock),
    .clock_b    (Clock),
    .data_a     ('0),
    .data_b     (AluData103),
    .wren_a     ('0),
    .wren_b     (M_WrEn103),
    .q_a        (PreM2_Data102),
    .q_b        ()//Second port is for writing only!
);
// Sample Ctrl Bits 101 -> 102
`MSFF(         SelImmAsAluOut102,   SelImmAsAluOut101,  Clock)
`MSFF(         RegSrc2_102,   RegSrc2_101,  Clock)
`MSFF(         SelAType102 ,        SelAType101  ,      Clock)
`MSFF(         SelMorA102,         SelMorA101  ,      Clock)
`MSFF(         CtrlAluOp102,        CtrlAluOp101 ,      Clock)
`RST_MSFF(     D_WrEn102   ,        D_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     A_WrEn102   ,        A_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     M_WrEn102   ,        M_WrEn101    ,      Clock , (Reset || RstCtrlJmp103) )
`RST_VAL_MSFF( JmpCond102  ,        JmpCond101   ,      Clock , (Reset || RstCtrlJmp103) , NO_JMP)
// Sample Data Path 101 -> 102 
`MSFF(         A_Data102   , A_Data101     , Clock)
`MSFF(         D_Data102   , D_Data101     , Clock)
`MSFF(         Immediate102, Immediate101  , Clock)


// ======================================
// === Execute & Write Back Cycle 102 ===
// ======================================
//Hazard detection
assign CtrlDataHzrdM1_102 = (A_Data103 == A_Data102) && M_WrEn103;
assign CtrlDataHzrdM1_103 = (A_Data104 == A_Data102) && M_WrEn104;
//Forwording unit 103->102
assign M1_Data102 = CtrlDataHzrdM1_102 ? FwrM_Data103  : 
                    CtrlDataHzrdM1_103 ? FwrM_Data104  :
                                       PreM1_Data102 ;
//Hazard detection
assign CtrlDataHzrdM2_102 = (A_Data103 == RegSrc2_102) && M_WrEn103;
assign CtrlDataHzrdM2_103 = (A_Data104 == RegSrc2_102) && M_WrEn104;
//Forwording unit 103->102
assign M2_Data102 = CtrlDataHzrdM2_102 ? FwrM_Data103  : 
                    CtrlDataHzrdM2_103 ? FwrM_Data104  :
                                         PreM2_Data102 ;
// input  D_Data102 , SelMorA102 , M1_Data102 , 
// input  A_Data102, Immediate102, SelImmAsAluOut102, JmpCond102, 
// output JmpCondMet102, AluData102

    //ALU module instantiation
assign   AluIn1_102      = LoadMDfromMminusM102 ? M2_Data102 : D_Data102;
assign   AluIn2_102      = SelMorA102           ? M1_Data102 : A_Data102;
    alu alu0(
            .x(AluIn1_102),
            .y(AluIn2_102),
            .out(PreAluData102),
            .fn(CtrlAluOp102),
            .zero(zero)
        );
assign  AluData102          = SelImmAsAluOut102 ? Immediate102 : PreAluData102;
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
assign RstCtrlJmp103 = JmpCondMet103 || JmpCondMet102;


// Sample Data Path 103 -> 104 (Used for Forwording unit & Hazard on the D_MEM read after Write
`MSFF(     A_Data104    , A_Data103     ,  Clock)
`MSFF(     FwrM_Data104 , FwrM_Data103  ,  Clock)
`RST_MSFF( M_WrEn104    , M_WrEn103     ,  Clock, Reset)

endmodule