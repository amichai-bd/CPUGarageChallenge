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
    logic [20:0][INSTR_WIDTH-1:0]                instruction;
    logic [DATA_WIDTH-1:0]                 cpu_out_m;
    logic [$clog2(ROM_REGISTER_COUNT)-1:0] inst_address;
    assign resetN = ~Reset;
logic [4:0] nothing0;
logic [4:0] nothing1;
    cpu cpu_inst (
            .clk        (Clk),
            .SW         ('0),
            .inst       (instruction),
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
            .q          (instruction[0])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_1
        (
            .address    (inst_address + 10'd1),
            .clock      (Clk),
            .q          (instruction[1])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_2
        (
            .address    (inst_address + 10'd2),
            .clock      (Clk),
            .q          (instruction[2])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_3
        (
            .address    (inst_address +10'd3),
            .clock      (Clk),
            .q          (instruction[3])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_4
        (
            .address    (inst_address +10'd4),
            .clock      (Clk),
            .q          (instruction[4])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_5
        (
            .address    (inst_address +10'd5),
            .clock      (Clk),
            .q          (instruction[5])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_6
        (
            .address    (inst_address +10'd6),
            .clock      (Clk),
            .q          (instruction[6])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_7
        (
            .address    (inst_address +10'd7),
            .clock      (Clk),
            .q          (instruction[7])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_8
        (
            .address    (inst_address +10'd8),
            .clock      (Clk),
            .q          (instruction[8])
        );
    
   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_9
        (
            .address    (inst_address +10'd9),
            .clock      (Clk),
            .q          (instruction[9])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_10
        (
            .address    (inst_address + 10'd10),
            .clock      (Clk),
            .q          (instruction[10])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_11
        (
            .address    (inst_address + 10'd11),
            .clock      (Clk),
            .q          (instruction[11])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_12
        (
            .address    (inst_address + 10'd12),
            .clock      (Clk),
            .q          (instruction[12])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_13
        (
            .address    (inst_address +10'd13),
            .clock      (Clk),
            .q          (instruction[13])
        );
    rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_14
        (
            .address    (inst_address +10'd14),
            .clock      (Clk),
            .q          (instruction[14])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_15
        (
            .address    (inst_address +10'd15),
            .clock      (Clk),
            .q          (instruction[15])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_16
        (
            .address    (inst_address +10'd16),
            .clock      (Clk),
            .q          (instruction[16])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_17
        (
            .address    (inst_address +10'd17),
            .clock      (Clk),
            .q          (instruction[17])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_18
        (
            .address    (inst_address +10'd18),
            .clock      (Clk),
            .q          (instruction[18])
        );
    
   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_19
        (
            .address    (inst_address +10'd19),
            .clock      (Clk),
            .q          (instruction[19])
        );

   rom #(.INSTR_WIDTH          (INSTR_WIDTH),
              .ROM_REGISTER_COUNT   (ROM_REGISTER_COUNT))
        rom_inst_20
        (
            .address    (inst_address +10'd20),
            .clock      (Clk),
            .q          (instruction[20])
        );
endmodule

