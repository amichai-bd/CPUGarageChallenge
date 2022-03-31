
module alu(
        x,    // D input
        y,    //A / M input (A register or RAM)
        out,  //Output Data
        fn,   //Function input (instruction)
        zero  //Zero Flag output
    );

    input[15:0] x, y;
    input[5:0] fn;
    output[15:0] out;
    output zero;

    wire zx = fn[5];  //zero X
    wire nx = fn[4];  //invert X
    wire zy = fn[3];  //zero Y
    wire ny = fn[2];  //invert Y
    wire add = fn[1]; //add
    wire no = fn[0];  //invert output

    wire[15:0] x0 = zx ? 16'b0 : x; //if zx is true set x to zero
    wire[15:0] y0 = zy ? 16'b0 : y; //if zy is true set y to zero
    wire[15:0] x1 = nx ? ~x0 : x0;  //if nx is true invert x0
    wire[15:0] y1 = ny ? ~y0 : y0;  //if ny is true invert y0
    wire[15:0] out0 = add ? x1 + y1 : x1 & y1; // if add is true sum x1 and y1

    assign out = no ? ~out0 : out0; //if invert bit is enabled, assign out to inverted data
    assign zero = ~|out; //NOR the output to check if the data is equal to zero



endmodule
