`include "definitions.sv"

module top(
        input     CLK_50,
        input  [3:0]  SW,
        input  [1:0] BUTTON,

        output    [6:0]    HEX0,
        output    [6:0]    HEX1,
        output    [6:0]    HEX2,

        output [9:0] LED,

        output [3:0]  RED,
        output [3:0]  GREEN,
        output [3:0]  BLUE,

        output      h_sync,
        output    v_sync
    );
    // Widths and Counts
    // You may change the width of the instruction (e.g. make a 32-bit cpu).
    // You may change the width of the data (e.g. read and write 32 bit data into the ram).
    parameter DATA_WIDTH = 16, INSTR_WIDTH = 16; // ram and instruction widths in bits (default is 16 for both).
    parameter ROM_REGISTER_COUNT = 2**10, RAM_REGISTER_COUNT = 2**10;

    // VGA Settings
    parameter BITS_PER_MEMORY_PIXEL_X = 4; //4
    parameter BITS_PER_MEMORY_PIXEL_Y = 5; //5
    parameter HEX_START_X = 512;
    parameter HEX_DIGIT_WIDTH = 16;
    parameter HEX_DIGIT_HEIGHT = 32;
    parameter RAM_SCREEN_OFFSET = 0;

    parameter logic [15:0] FINAL_PC = 16'(ROM_REGISTER_COUNT-1);
    parameter NUMBER_OF_DIGITS_PERF = 8;
    // The number of bits shown will be (2**(9-BITS_PER_MEMORY_PIXEL_X))*(384/(2**(BITS_PER_MEMORY_PIXEL_Y)))

    localparam HEX_DIGITS_PER_LINE = BITS_PER_MEMORY_PIXEL_X <= 4 ? 8 : 4;
    localparam WORDS_PER_LINE = (2**9) >> ($clog2(DATA_WIDTH)+BITS_PER_MEMORY_PIXEL_X);
    localparam PIXELS_PER_WORD = 2**($clog2(DATA_WIDTH)+BITS_PER_MEMORY_PIXEL_X);
    localparam BITS_PER_HEX_DIGIT = 4;
    localparam WORDS_PER_HEX_LINE = BITS_PER_HEX_DIGIT * HEX_DIGITS_PER_LINE / DATA_WIDTH;
    localparam HEX_PIXELS_PER_WORD = DATA_WIDTH / BITS_PER_HEX_DIGIT * HEX_DIGIT_WIDTH;

    //PLL
    logic cpu_clk; // The real clock driving the CPU.
    logic cpu_clk_temp; // Same clock but before gating with `finished`.

`ifdef USE_PLL

    pll #(.MULTIPLY(`PLL_MULTIPLY), .DIVIDE(`PLL_DIVIDE))
        pll_inst(
            .inclk0 ( CLK_50 ),
            .c0 ( cpu_clk_temp )
        );
`else
    assign cpu_clk_temp = CLK_50;
`endif

    clkctrl clkctrl (
                .inclk  (cpu_clk_temp),
                .ena    (!finished),
                .outclk (cpu_clk)
            );


    //===
    logic [$clog2(RAM_REGISTER_COUNT)-1:0] ram_address;
    logic we;
    logic [DATA_WIDTH-1:0] rdata;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic [DATA_WIDTH-1:0] vga_word_value;

    logic [DATA_WIDTH-1:0] vga_word_address;

    logic resetN;
    assign resetN = BUTTON[0];

    logic finished;

    always_comb
    begin
        // Binary
        if (pixel_x < HEX_START_X)
            vga_word_address = DATA_WIDTH'((pixel_y >> BITS_PER_MEMORY_PIXEL_Y) * WORDS_PER_LINE
                                           + (pixel_x / PIXELS_PER_WORD));
        // HEX
        else
            vga_word_address = DATA_WIDTH'((pixel_y / HEX_DIGIT_HEIGHT) * WORDS_PER_HEX_LINE
                                           + ((pixel_x - HEX_START_X) / HEX_PIXELS_PER_WORD));
    end

    ram #(.DATA_WIDTH(DATA_WIDTH),
          .RAM_REGISTER_COUNT(RAM_REGISTER_COUNT))
        ram_inst (
            .address_a (ram_address),
            .address_b (RAM_SCREEN_OFFSET +  vga_word_address),
            .clock_a (cpu_clk),
            .clock_b (CLK_50),
            .data_a (cpu_out_m),
            .data_b (16'b0),
            .wren_a (we),
            .wren_b (~resetN),
            .q_a (rdata),
            .q_b (vga_word_value)
        );

    vga #(.DATA_WIDTH(16), .BITS_PER_MEMORY_PIXEL_X(BITS_PER_MEMORY_PIXEL_X), .BITS_PER_MEMORY_PIXEL_Y(BITS_PER_MEMORY_PIXEL_Y),
          .HEX_START_X(HEX_START_X), .HEX_DIGIT_WIDTH(HEX_DIGIT_WIDTH))
        vga_inst(.CLK_50(CLK_50),
                 .hex_drawing_request(hex_drawing_request),
                 .hex_rgb(hex_rgb),
                 .perf_drawing_request(perf_drawing_request),
                 .perf_rgb(perf_rgb),
                 .pixel_in(vga_word_value),

                 .RED(RED),
                 .GREEN(GREEN),
                 .BLUE(BLUE),
                 .h_sync(h_sync),
                 .v_sync(v_sync),
                 .pixel_x(pixel_x),
                 .pixel_y(pixel_y)
                );

    // HEX (NOT 7 Segment, but display on screen)
    logic hex_drawing_request;
    logic [7:0] hex_rgb;
    hex_display #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .HEX_DIGITS_PER_LINE(HEX_DIGITS_PER_LINE),
                    .HEX_DIGIT_WIDTH(HEX_DIGIT_WIDTH),
                    .HEX_START_X(HEX_START_X),
                    .HEX_PIXELS_PER_WORD(HEX_PIXELS_PER_WORD)
                )
                hex_display_inst(
                    .pixel_x(pixel_x),
                    .pixel_y(pixel_y),
                    .word_value(vga_word_value),

                    .hex_drawing_request(hex_drawing_request),
                    .hex_rgb(hex_rgb)
                );

    // performance counter
    logic perf_drawing_request;
    logic [7:0] perf_rgb;
    perf_counter #(
                     .NUMBER_OF_DIGITS(NUMBER_OF_DIGITS_PERF),
                     .HEX_DIGIT_WIDTH(HEX_DIGIT_WIDTH),
                     .HEX_DIGIT_HEIGHT(HEX_DIGIT_HEIGHT),
                     .FINAL_PC(FINAL_PC)
                 )
                 perf_counter_inst(
                     .CLK_50(CLK_50),
                     .resetN(resetN),
                     .pixel_x(pixel_x),
                     .pixel_y(pixel_y),
                     .pc(inst_address),
                     .SW(SW),

                     .perf_drawing_request(perf_drawing_request),
                     .perf_rgb(perf_rgb),

                     .HEX0(HEX0),
                     .HEX1(HEX1),
                     .HEX2(HEX2),

                     .LED(LED),
                     .finished(finished)
                 );


    //CPU AND ROM
    logic [INSTR_WIDTH-1:0] instruction0;
    logic [INSTR_WIDTH-1:0] instruction1;
    logic [INSTR_WIDTH-1:0] instruction2;
    logic [INSTR_WIDTH-1:0] instruction3;
    logic [DATA_WIDTH-1:0] cpu_out_m;
    logic [$clog2(ROM_REGISTER_COUNT)-1:0] inst_address;

    rom #(.INSTR_WIDTH(INSTR_WIDTH),
          .ROM_REGISTER_COUNT(ROM_REGISTER_COUNT))
        rom_inst0
        (
            .address(inst_address),
            .clock(cpu_clk),
            .q(instruction0)
        );
    rom #(.INSTR_WIDTH(INSTR_WIDTH),
          .ROM_REGISTER_COUNT(ROM_REGISTER_COUNT))
        rom_inst1
        (
            .address(inst_address + 1),
            .clock(cpu_clk),
            .q(instruction1)
        );
    rom #(.INSTR_WIDTH(INSTR_WIDTH),
          .ROM_REGISTER_COUNT(ROM_REGISTER_COUNT))
        rom_inst2
        (
            .address(inst_address + 2),
            .clock(cpu_clk),
            .q(instruction2)
        );
    rom #(.INSTR_WIDTH(INSTR_WIDTH),
          .ROM_REGISTER_COUNT(ROM_REGISTER_COUNT))
        rom_inst3
        (
            .address(inst_address + 3),
            .clock(cpu_clk),
            .q(instruction3)
        );
    cpu cpu_inst (
            .clk(cpu_clk),
            .SW(SW),
            .inst_0(instruction0),
				.inst_1(instruction1),
				.inst_2(instruction2),
				.inst_3(instruction3),
            .in_m(rdata),
            .resetN(resetN),

				.out_m(cpu_out_m),
            .write_m(we),
            .data_addr(ram_address),
            .inst_addr(inst_address)
        );
endmodule
