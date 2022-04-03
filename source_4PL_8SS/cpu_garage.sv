`include "definitions.sv"

module cpu_garage(
        input Clk,
        input Reset
    );
    parameter DATA_WIDTH = 16, INSTR_WIDTH = 16; // ram and instruction widths in bits (default is 16 for both).
    parameter ROM_REGISTER_COUNT = 2**10, RAM_REGISTER_COUNT = 2**10;

    //===
    logic [$clog2(RAM_REGISTER_COUNT)-1:0] ram_address;
    logic                                  we;
    logic [DATA_WIDTH-1:0]                 rdata;
    logic resetN;
    //CPU AND ROM
    logic [INSTR_WIDTH-1:0]                instruction_0;
    logic [INSTR_WIDTH-1:0]                instruction_1;
    logic [INSTR_WIDTH-1:0]                instruction_2;
    logic [INSTR_WIDTH-1:0]                instruction_3;
    logic [INSTR_WIDTH-1:0]                instruction_4;
    logic [INSTR_WIDTH-1:0]                instruction_5;
    logic [INSTR_WIDTH-1:0]                instruction_6;
    logic [INSTR_WIDTH-1:0]                instruction_7;
    logic [INSTR_WIDTH-1:0]                instruction_8;
    logic [INSTR_WIDTH-1:0]                instruction_9;
    logic [DATA_WIDTH-1:0]                 cpu_out_m;
    logic [$clog2(ROM_REGISTER_COUNT)-1:0] inst_address;
    assign resetN = ~Reset;
logic [4:0] nothing0;
logic [4:0] nothing1;
    cpu cpu_inst (
            .clk        (Clk),
            .SW         ('0),
            .inst_0     (instruction_0),
            .inst_1     (instruction_1),
            .inst_2     (instruction_2),
            .inst_3     (instruction_3),
            .inst_4     (instruction_4),
            .inst_5     (instruction_5),
            .inst_6     (instruction_6),
            .inst_7     (instruction_7),
            .inst_8     (instruction_8),
            .inst_9     (instruction_9),
            .in_m       (rdata),
            .resetN     (resetN),
            .out_m      (cpu_out_m),
            .write_m    (we),
            .data_addr  ({nothing0,ram_address}),
            .inst_addr  ({nothing1,inst_address})
        );

    ram #(.DATA_WIDTH           (DATA_WIDTH),
              .RAM_REGISTER_COUNT   (RAM_REGISTER_COUNT))
        ram_inst (
            .address_a  (ram_address),
            .address_b  ('0),
            .clock_a    (Clk),
            .clock_b    (Clk),
            .data_a     (cpu_out_m),
            .data_b     (16'b0),
            .wren_a     (we),
            .wren_b     (~resetN),
            .q_a        (rdata),
            .q_b        ()
        );


    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_0
        (
            .address    (inst_address),
            .clock      (Clk),
            .q          (instruction_0)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_1
        (
            .address    (inst_address + 10'd1),
            .clock      (Clk),
            .q          (instruction_1)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_2
        (
            .address    (inst_address + 10'd2),
            .clock      (Clk),
            .q          (instruction_2)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_3
        (
            .address    (inst_address +10'd3),
            .clock      (Clk),
            .q          (instruction_3)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_4
        (
            .address    (inst_address +10'd4),
            .clock      (Clk),
            .q          (instruction_4)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_5
        (
            .address    (inst_address +10'd5),
            .clock      (Clk),
            .q          (instruction_5)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_6
        (
            .address    (inst_address +10'd6),
            .clock      (Clk),
            .q          (instruction_6)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_7
        (
            .address    (inst_address +10'd7),
            .clock      (Clk),
            .q          (instruction_7)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_8
        (
            .address    (inst_address +10'd8),
            .clock      (Clk),
            .q          (instruction_8)
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_9
        (
            .address    (inst_address +10'd9),
            .clock      (Clk),
            .q          (instruction_9)
        );
endmodule

