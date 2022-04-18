// Represents a square object. Outputs the offsets from
// the top left corner to be used by a bitmap.

module square_object (
        input  logic [10:0] pixelX, //current VGA pixel
        input  logic [10:0] pixelY,
        input  logic signed [10:0] topLeftX, //position on the screen
        input  logic signed [10:0] topLeftY,

        output logic [10:0] offsetX, //offset inside bracket from top left position
        output logic [10:0] offsetY,
        output logic inside_rectangle //indicates the pixel is inside the bracket
    );

    parameter int signed OBJECT_WIDTH_X = 16;
    parameter int signed OBJECT_HEIGHT_Y = 32;

    int signed rightX, bottomY; //coordinates of the sides
    logic insideBracket, insideX, insideY;

    //==----------------------------------------------------------------------------------------------------------------=
    // Calculate object right  & bottom  boundaries
    assign rightX = (topLeftX + OBJECT_WIDTH_X);
    assign bottomY = (topLeftY + OBJECT_HEIGHT_Y);

    //==----------------------------------------------------------------------------------------------------------------=
    always_comb
    begin
        insideY = (pixelY >= topLeftY) && (pixelY < bottomY);
        insideX = (pixelX >= topLeftX) && (pixelX < rightX);
        if (insideX && insideY) // test if it is inside the rectangle
        begin
            inside_rectangle = 1'b1 ;
            // 16 and 32 are the width and height of the number bitmap, respectively.
            offsetX = (pixelX - topLeftX) % 11'd16; //calculate relative offsets from top left corner
            offsetY = (pixelY - topLeftY) % 11'd32;
        end
        else
        begin
            inside_rectangle = 1'b0 ;
            offsetX = 0; //no offset
            offsetY = 0; //no offset
        end
    end
endmodule
