//-----------------------------------------------------------------------------
// Title            : cpu top.
// Project          : Intel CPU Garrage channge
//-----------------------------------------------------------------------------
// File             : cpu.sv
// Original Author  : Amichai Ben-David
// Created          : 3/2022
//-----------------------------------------------------------------------------
// Description :
// A 3 stage pipeline with the memory in the CPU.
// The memory is merrored to the outside the core for VGA & other to observe.


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

//==============================================
//      Module
//==============================================
module cpu (
    input   logic           Clock,
    input   logic           Reset,
    output  logic [11:0]    PC100,
    input   logic [15:0]    Inst101,
    output  logic           M_WrEn102,
    output  logic [15:0]    M_WrData102
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
logic           M_WrEn101   ,   M_WrEn102   , M_WrEn103;
logic           SelAType101 ,   SelAType102 ;
logic           JmpCondMet102, JmpCondMet103;
logic           RstCtrlJmp103;
logic           CtrlDataHzrdM102;
logic  [5:0]    CtrlAluOp101,   CtrlAluOp102    ;
logic           SelAluInM101,   SelAluInM102;
logic           SelM_Hzrd102;
t_inst_type     InstType101 ;
t_jmp_cond      JmpCond101  ,   JmpCond102  ; 

//  === Data Path ===
logic  [14:0]   NextD_Data102,  PreD_Data101,   D_Data101  ,   D_Data102   ;
logic  [14:0]   PreM_Data102,   M_Data102   ,   FwrM_Data103;
logic  [14:0]   NextA_Data102,  PreA_Data101,   A_Data101  ,   A_Data102   , A_Data103;
logic  [11:0]   NextPC100;
logic  [14:0]   AluIn1_102;
logic  [14:0]   AluIn2_102;
logic  [14:0]   AluData102;
logic  [14:0]   Immediate101,   Immediate102;

//==============================================
//      Module Content
//==============================================

// =======================
// === Fetch Cycle 100 ===
// =======================
assign NextPC100 = JmpCondMet102 ? A_Data102 : (PC100 + 1);
`MSFF(PC100 , NextPC100, Clock)

// ========================
// === Decode Cycle 101 ===
// ========================
// -- ctrl bits --
assign InstType101  = (Inst101[15] == 1'b0) ? A_TYPE : C_TYPE; // (Inst101[15:13] == 3'b111) -> C_TYPE
assign M_WrEn101    = (InstType101 == C_TYPE) && Inst101[3];
assign D_WrEn101    = (InstType101 == C_TYPE) && Inst101[4];
assign A_WrEn101    = (InstType101 == C_TYPE) && Inst101[5];
assign JmpCond101   = (InstType101 == C_TYPE) ? t_jmp_cond'(Inst101[2:0]) : NO_JMP;// Cast enum if C_TYPE.
assign SelAType101  = (InstType101 == A_TYPE);
assign CtrlAluOp101 = Inst101[11:6];  // See Spec for details. Inst101[11:6] = Operation.
assign SelAluInM101 = Inst101[12];    // See Spec for details. Inst101[12] = A_vs_M.

// -- Data Path -- 
assign NwxtA_Data102 = SelAType102 ? Immediate102 : AluData102;
assign NwxtD_Data102 = AluData102;
`EN_MSFF(PreA_Data101, NextA_Data102,   Clock, A_WrEn102)
`EN_MSFF(PreD_Data101, NextD_Data102,   Clock, D_WrEn102)
// Forwording unit:
assign A_Data101 = A_WrEn102 ? NextA_Data102 : PreA_Data101;
assign D_Data101 = D_WrEn102 ? NextD_Data102 : PreD_Data101;

// Reading & Writing from Memory using A_Register as address.
ram d_mem (
    .address_a  (A_Data101),//Read
    .address_b  (A_Data102),//Write
    .clock      (Clock),
    .data_a     ('0),
    .data_b     (AluData102),
    .wren_a     ('0),
    .wren_b     (M_WrEn102),
    .q_a        (PreM_Data102),
    .q_b        ()//Second port is for writing only!
);

// Sample Ctrl Bits 101 -> 102
`MSFF(         SelAType102 ,  SelAType101  , Clock)
`MSFF(         SelAluInM102,  SelAluInM101 , Clock)
`MSFF(         CtrlAluOp102,  CtrlAluOp101 , Clock)
`RST_MSFF(     D_WrEn102   ,  D_WrEn101    , Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     A_WrEn102   ,  A_WrEn101    , Clock , (Reset || RstCtrlJmp103) )
`RST_MSFF(     M_WrEn102   ,  M_WrEn101    , Clock , (Reset || RstCtrlJmp103) )
`RST_VAL_MSFF( JmpCond102  ,  JmpCond101   , Clock , (Reset || RstCtrlJmp103) , NO_JMP)
// Sample Data Path 101 -> 102 
`MSFF(         A_Data102   , A_Data101     , Clock)
`MSFF(         D_Data102   , D_Data101     , Clock)
`MSFF(         Immediate102, Immediate101  , Clock)


// ======================================
// === Execute & Write Back Cycle 102 ===
// ======================================
//Hazard detection
assign CtrlDataHzrdM102 = (A_Data103 == A_Data102) && M_WrEn103;
//Forwording unit 103->102
assign M_Data102 = CtrlDataHzrdM102 ? FwrM_Data103 : PreM_Data102;
always_comb begin : alu_logic
  AluIn1_102      = D_Data102;
  AluIn2_102      = SelAluInM102 ? M_Data102 : A_Data102;
  unique casez (CtrlAluOp102) 
    6'b101010: AluData102 = 0 ;                      // 0 
    6'b111111: AluData102 = 1 ;                      // 1
    6'b111010: AluData102 = -1;                      //-1
    6'b001100: AluData102 = AluIn1_102;              // D
    6'b110000: AluData102 = AluIn2_102;              // A    |  M
    6'b001101: AluData102 = ~AluIn1_102;             // ~D
    6'b110001: AluData102 = ~AluIn2_102;             // ~A   |  ~M
    6'b001111: AluData102 = -AluIn1_102;             // -D
    6'b110011: AluData102 = -AluIn2_102;             // -A   |  -M
    6'b011111: AluData102 = AluIn1_102 + 1;          // D+1
    6'b110111: AluData102 = AluIn2_102 + 1;          // A+1  |  M+1
    6'b001110: AluData102 = AluIn1_102 - 1;          // D-1
    6'b110010: AluData102 = AluIn2_102 - 1;          // A-1  |  M-1
    6'b000010: AluData102 = AluIn1_102 + AluIn2_102; // D+A  |  D+M
    6'b010011: AluData102 = AluIn1_102 - AluIn2_102; // D-A  |  D-M
    6'b000111: AluData102 = AluIn2_102 - AluIn1_102; // A-D  |  M-D
    6'b000000: AluData102 = AluIn1_102 & AluIn2_102; // A&D  |  M&D
    6'b010101: AluData102 = AluIn1_102 | AluIn2_102; // A|D  |  M|D
    default  : AluData102 = 0;
  endcase

  unique casez (JmpCond102) 
    NO_JMP  : JmpCondMet102 = 1'b0;
    JGT	    : JmpCondMet102 = (AluData102>0);
    JEG	    : JmpCondMet102 = (AluData102==0);
    JGE	    : JmpCondMet102 = (AluData102>=0);
    JLT	    : JmpCondMet102 = (AluData102<0);
    JNE	    : JmpCondMet102 = (AluData102!=0);
    JLE	    : JmpCondMet102 = (AluData102<=0);
    JMP	    : JmpCondMet102 = 1'b1;
    default : JmpCondMet102 = 0;
  endcase
end //always_comb alu_logic

// Sample Data Path 102 -> 103 (Used for Forwording unit & Hazard on the D_MEM read after Write
`MSFF(     A_Data103    , A_Data102     ,  Clock)
`MSFF(     FwrM_Data103 , AluData102    ,  Clock)
`RST_MSFF( M_WrEn103    , M_WrEn102     ,  Clock, Reset)
//RstCtrlJmp103 used to "flush" the pipe when jmp -> Rst the 102 CTRL for 2 cycles. (Sync Reset)
`RST_MSFF( JmpCondMet103, JmpCondMet102 ,  Clock, Reset)
assign RstCtrlJmp103 = JmpCondMet103 || JmpCondMet102;


endmodule
