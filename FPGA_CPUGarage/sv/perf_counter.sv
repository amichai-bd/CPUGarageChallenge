`include "definitions.sv"

module perf_counter(
        input logic CLK_50,
        input logic resetN,
        input logic [9:0] pixel_x,
        input logic [9:0] pixel_y,
        input logic [15:0] pc,
        input logic [3:0] SW,

        output logic perf_drawing_request,
        output logic [7:0] perf_rgb,

        output logic [6:0]  HEX0,
        output logic [6:0]  HEX1,
        output logic [6:0]  HEX2,

        output logic [9:0] LED,

        output logic finished
    );

    parameter NUMBER_OF_DIGITS;
    parameter HEX_DIGIT_WIDTH, HEX_DIGIT_HEIGHT;
    parameter logic [15:0] FINAL_PC;

    int unsigned counter_50;
    logic unsigned [12:0] counter_hund_seconds;

    assign finished = (finished | (pc == FINAL_PC)) && resetN;

    // do the counting
    always_ff @(negedge resetN or posedge CLK_50)
        if (!resetN)
        begin
            counter_50 <= 0;
            counter_hund_seconds <= 7'b0;
        end
        else
        begin
            if (CLK_50)
                if ((counter_hund_seconds < 2**13 - 1) && !finished)
                begin
                    counter_50 <= counter_50 + 1;
                    if (counter_50 % 500_000 == (500_000 - 1))
                        counter_hund_seconds++;
                end
        end

    // hundredths of second counter

    logic [3:0] current_digit;
    // assign current_digit = (counter_hund_seconds >> (4*((HEX_DIGIT_WIDTH*3 - pixel_x) / HEX_DIGIT_WIDTH))) % 16;
    always_comb
    begin
        if (pixel_x < 16)
            current_digit = 4'((counter_hund_seconds / 1000) % 10);
        else if (pixel_x < 32)
            current_digit = 4'((counter_hund_seconds / 100) % 10);
        else if (pixel_x < 48)
            current_digit = 4'((counter_hund_seconds / 10) % 10);
        else
            current_digit = 4'((counter_hund_seconds / 1) % 10);
    end


    logic seconds_drawing_request, clocks_drawing_request;
    logic [7:0] seconds_rgb, clocks_rgb;
    assign perf_drawing_request = seconds_drawing_request | clocks_drawing_request;
    assign perf_rgb = seconds_drawing_request ? seconds_rgb : clocks_rgb;

    logic [3:0] digits_clks [7:0];
    always_ff @(posedge CLK_50)
    begin
        for (int i=0; i<8; i++)
        begin
            digits_clks[i] <= 4'(counter_50 >> (4*i));
        end
    end
    logic [3:0] current_digit_clks;
    // assign current_digit_clks = 4'((counter_50 >> (4*((HEX_DIGIT_WIDTH*NUMBER_OF_DIGITS - pixel_x) / HEX_DIGIT_WIDTH))) % 16);
    assign current_digit_clks = digits_clks[(HEX_DIGIT_WIDTH*NUMBER_OF_DIGITS - pixel_x) / HEX_DIGIT_WIDTH];

    number_display #(.OBJECT_WIDTH_X(HEX_DIGIT_WIDTH*4), .OBJECT_HEIGHT_Y(HEX_DIGIT_HEIGHT), .digit_color(8'b111_111_11))
                   seconds_counter_display(
                       .pixel_x(pixel_x),// current VGA pixel
                       .pixel_y(pixel_y),
                       .topLeftX(0), //position on the screen
                       .topLeftY(384+32),
                       .digit(current_digit),

                       .drawingRequest(seconds_drawing_request),
                       .RGBout(seconds_rgb)
                   );
    number_display #(.OBJECT_WIDTH_X(HEX_DIGIT_WIDTH*8), .OBJECT_HEIGHT_Y(HEX_DIGIT_HEIGHT), .digit_color(8'b111_111_11))
                   clock_counter_display(
                       .pixel_x(pixel_x),// current VGA pixel
                       .pixel_y(pixel_y),
                       .topLeftX(0), //position on the screen
                       .topLeftY(384),
                       .digit(current_digit_clks),

                       .drawingRequest(clocks_drawing_request),
                       .RGBout(clocks_rgb)
                   );

    // 7 segment
    logic [3:0] digits_clks_out [2:0];
    always_ff @(posedge CLK_50)
    begin
`ifdef DE10_LITE

        LED <= 10'h0;
`else
        LED <= 8'hFF;
`endif

`ifdef KIWI

        LED[0] <= !finished;

        if (SW[3])
        begin
            digits_clks_out[0] <= digits_clks[0];
            digits_clks_out[1] <= digits_clks[1];
            digits_clks_out[2] <= digits_clks[2];
            LED[7] <= 1'b0;
        end
        else if (SW[2])
        begin
            digits_clks_out[0] <= digits_clks[3];
            digits_clks_out[1] <= digits_clks[4];
            digits_clks_out[2] <= digits_clks[5];
            LED[6] <= 1'b0;
        end
        else if (SW[1])
        begin
            digits_clks_out[0] <= digits_clks[6];
            digits_clks_out[1] <= digits_clks[7];
            digits_clks_out[2] <= 4'b0;
            LED[5] <= 1'b0;
        end
        else
        begin
            digits_clks_out[0] <= 4'b0;
            digits_clks_out[1] <= 4'b0;
            digits_clks_out[2] <= 4'b0;
        end
`else
        LED[7] <= finished;

        if (SW[0])
        begin
            digits_clks_out[0] <= digits_clks[0];
            digits_clks_out[1] <= digits_clks[1];
            digits_clks_out[2] <= digits_clks[2];
            LED[0] <= 1'b1;
        end
        else if (SW[1])
        begin
            digits_clks_out[0] <= digits_clks[3];
            digits_clks_out[1] <= digits_clks[4];
            digits_clks_out[2] <= digits_clks[5];
            LED[1] <= 1'b1;
        end
        else if (SW[2])
        begin
            digits_clks_out[0] <= digits_clks[6];
            digits_clks_out[1] <= digits_clks[7];
            digits_clks_out[2] <= 4'b0;
            LED[2] <= 1'b1;
        end
        else
        begin
            digits_clks_out[0] <= 4'b0;
            digits_clks_out[1] <= 4'b0;
            digits_clks_out[2] <= 4'b0;
        end
`endif

    end

`ifdef KIWI
    seg7 seg7_0 (
             .input_dig(digits_clks_out[2]),
             .output_seg(HEX0)
         );
    seg7 seg7_1 (
             .input_dig(digits_clks_out[1]),
             .output_seg(HEX1)
         );
    seg7 seg7_2 (
             .input_dig(digits_clks_out[0]),
             .output_seg(HEX2)
         );
`else
    seg7 seg7_0 (
             .input_dig(digits_clks_out[2]),
             .output_seg(HEX2)
         );
    seg7 seg7_1 (
             .input_dig(digits_clks_out[1]),
             .output_seg(HEX1)
         );
    seg7 seg7_2 (
             .input_dig(digits_clks_out[0]),
             .output_seg(HEX0)
         );

`endif

endmodule
