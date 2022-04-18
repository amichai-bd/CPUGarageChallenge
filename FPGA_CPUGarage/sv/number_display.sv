module number_display(
        input  logic [10:0] pixel_x,// current VGA pixel
        input  logic [10:0] pixel_y,
        input  logic signed [10:0] topLeftX, //position on the screen
        input  logic signed [10:0] topLeftY,
        input  logic [3:0] digit, // digit to display

        output logic drawingRequest, //output that the pixel should be dispalyed
        output logic [7:0]  RGBout
    );

    parameter OBJECT_WIDTH_X, OBJECT_HEIGHT_Y;
    parameter digit_color;

    logic inside_rectangle;
    logic [10:0] offsetX, offsetY;

    square_object #(.OBJECT_WIDTH_X(OBJECT_WIDTH_X), .OBJECT_HEIGHT_Y(OBJECT_HEIGHT_Y))
                  square_object_inst(
                      .pixelX(pixel_x),// current VGA pixel
                      .pixelY(pixel_y),
                      .topLeftX(topLeftX), //position on the screen
                      .topLeftY(topLeftY),

                      .offsetX(offsetX),// offset inside bracket from top left position
                      .offsetY(offsetY),
                      .inside_rectangle(inside_rectangle) // indicates pixel inside the bracket
                  );
    numbers_bitmap #(.digit_color(digit_color))
                   numbers_bitmap_inst(
                       .offsetX(offsetX),
                       .offsetY(offsetY),
                       .InsideRectangle(inside_rectangle),
                       .digit(digit),

                       .drawingRequest(drawingRequest),
                       .RGBout(RGBout)
                   );

endmodule
