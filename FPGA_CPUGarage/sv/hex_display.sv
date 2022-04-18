module hex_display(
        input logic [9:0] pixel_x,
        input logic [9:0] pixel_y,
        input logic [DATA_WIDTH-1:0] word_value,

        output logic hex_drawing_request,
        output logic [7:0] hex_rgb
    );

    parameter DATA_WIDTH;
    parameter HEX_DIGITS_PER_LINE, HEX_DIGIT_WIDTH, HEX_START_X, HEX_PIXELS_PER_WORD;

    logic [7:0] current_nibble;
    always_comb
    begin
        if ((pixel_x - HEX_START_X) % HEX_PIXELS_PER_WORD < HEX_DIGIT_WIDTH*1)
            current_nibble = word_value[15:12];
        else if ((pixel_x - HEX_START_X) % HEX_PIXELS_PER_WORD < HEX_DIGIT_WIDTH*2)
            current_nibble = word_value[11:8];
        else if ((pixel_x - HEX_START_X) % HEX_PIXELS_PER_WORD < HEX_DIGIT_WIDTH*3)
            current_nibble = word_value[7:4];
        else
            current_nibble = word_value[3:0];
    end

    number_display #(.OBJECT_WIDTH_X(HEX_DIGIT_WIDTH*HEX_DIGITS_PER_LINE), .OBJECT_HEIGHT_Y(384), .digit_color(8'b111_111_11))
                   seconds_counter_display(
                       .pixel_x(pixel_x),// current VGA pixel
                       .pixel_y(pixel_y),
                       .topLeftX(HEX_START_X), //position on the screen
                       .topLeftY(0),
                       .digit(current_nibble),

                       .drawingRequest(hex_drawing_request),
                       .RGBout(hex_rgb)
                   );

endmodule
