module sync_gen(
        input 				clk,
        output 				vga_h_sync,
        output 				vga_v_sync,
        output reg 		inDisplayArea,
        output reg [9:0] CounterX,
        output reg [9:0] CounterY
    );



    //=======================================//
    //				  Clock Divider				  //
    //=======================================//
    //VGA @ 640x480 resolution @ 60Hz requires a pixel clock of 25.175Mhz.
    //The Kiwi has an Onboard 50Mhz oscillator, we can divide it and get a 25Mhz clock.
    //It's not the exact frequency required for the VGA standard, but it works fine and it saves us the use of a PLL.

    reg clkdiv;
    reg [27:0] counter = 0;
    parameter DIVISOR = 28'd2;
    always @(posedge clk)
    begin
        counter <= counter + 28'd1;
        if(counter>=(DIVISOR-1))
            counter <= 28'd0;
        clkdiv <= (counter<DIVISOR/2)?1'b1:1'b0;
    end

    //=======================================//



    reg h_sync, v_sync;

    wire CounterXmaxed = (CounterX == 800); // 16 + 48 + 96 + 640
    wire CounterYmaxed = (CounterY == 525); // 10 + 2 + 33 + 480

    always @(posedge clkdiv)
        if (CounterXmaxed)
            CounterX <= 0;
        else
            CounterX <= CounterX + 1'b1;

    always @(posedge clkdiv)
    begin
        if (CounterXmaxed)
        begin
            if(CounterYmaxed)
                CounterY <= 0;
            else
                CounterY <= CounterY + 1'b1;
        end
    end

    always @(posedge clkdiv)
    begin
        h_sync <= (CounterX >= (640 + 16) && (CounterX < (640 + 16 + 96)));   // active for 96 clocks
        v_sync <= (CounterY >= (480 + 10) && (CounterY < (480 + 10 + 2)));   // active for 2 clocks
    end

    always @(posedge clkdiv)
    begin
        inDisplayArea <= (CounterX < 640) && (CounterY < 480);
    end

    assign vga_h_sync = ~h_sync;
    assign vga_v_sync = ~v_sync;

endmodule
