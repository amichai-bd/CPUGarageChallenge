module vga(
        input logic CLK_50,
        input logic [DATA_WIDTH-1:0] pixel_in,
        input logic hex_drawing_request,
        input logic [7:0]  hex_rgb,
        input logic perf_drawing_request,
        input logic [7:0]  perf_rgb,

        output logic [3:0] RED,
        output logic [3:0] GREEN,
        output logic [3:0] BLUE,
        output logic h_sync,
        output logic v_sync,
        output logic [9:0] pixel_x,
        output logic [9:0] pixel_y
    );

    parameter DATA_WIDTH;
    parameter BITS_PER_MEMORY_PIXEL_X;
    parameter BITS_PER_MEMORY_PIXEL_Y;
    parameter HEX_START_X;
    parameter HEX_DIGIT_WIDTH;

    localparam PIXELS_PER_WORD = 2**($clog2(DATA_WIDTH)+BITS_PER_MEMORY_PIXEL_X);

    logic inDisplayArea;

    logic [7:0] output_rgb;
    assign RED[2:0]   = output_rgb[7:5];
    assign GREEN[2:0] = output_rgb[4:2];
    assign BLUE[1:0]  = output_rgb[1:0];

    // Naively expand 3-3-2 bits to 4-4-4
    assign RED[3] = RED[2];
    assign GREEN[3] = GREEN[2];
    assign BLUE[3] = BLUE[2];
    assign BLUE[2] = BLUE[1];

    sync_gen sync_inst(
                 .clk(CLK_50),
                 .vga_h_sync(h_sync),
                 .vga_v_sync(v_sync),
                 .CounterX(pixel_x),
                 .CounterY(pixel_y),
                 .inDisplayArea(inDisplayArea)
             );


    //==========================//


    always_ff @(posedge CLK_50)
    begin
        if (inDisplayArea)
        begin
            // off pixel
            output_rgb <= 8'b001_001_01;

            // on pixel
            if (pixel_in[(PIXELS_PER_WORD - (pixel_x % PIXELS_PER_WORD)) >> BITS_PER_MEMORY_PIXEL_X])
                output_rgb <= 8'b111_111_11;

            // pixel border
            if (((pixel_x % (2**BITS_PER_MEMORY_PIXEL_X)) == 0) || ((pixel_y % (2**BITS_PER_MEMORY_PIXEL_Y)) == 0))
                output_rgb <= 8'b111_000_00;

            // byte border
            if ((pixel_x % (2**(BITS_PER_MEMORY_PIXEL_X+3))) == 0)
                output_rgb <= 8'b000_000_01;

            // word border
            if ((pixel_x % (2**(BITS_PER_MEMORY_PIXEL_X+4))) == 0)
                output_rgb <= 8'b000_000_11;

            // out of boundary
            if ((pixel_x >= HEX_START_X) || (pixel_y >= 384))
            begin
                // background
                output_rgb <= 8'b000_001_00;

                // hex
                if (hex_drawing_request)
                    output_rgb <= hex_rgb;

                // seconds
                if (perf_drawing_request)
                    output_rgb <= perf_rgb;

                //decimal point for seconds
                if ((pixel_x == 32 || pixel_x == 31) && (pixel_y==448 || pixel_y==447))
                    output_rgb <= 8'b111_000_00;

                // byte border (2 hex digits)
                if ((pixel_x - HEX_START_X) % (2*HEX_DIGIT_WIDTH) == 0 && pixel_y < 384)
                    output_rgb <= 8'b000_000_01;

                // word border (4 hex digits)
                if ((pixel_x - HEX_START_X) % (4*HEX_DIGIT_WIDTH) == 0 && pixel_y < 384)
                    output_rgb <= 8'b000_000_11;
            end
        end
        else
            // blanking time
            output_rgb <= 8'b000_000_00;

    end
endmodule
