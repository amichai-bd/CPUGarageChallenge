`include "definitions.sv"

package cpu_pkg;
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


endpackage
