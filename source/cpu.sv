module cpu (
        input logic         clk,
        input logic [3:0]   SW,
        input logic [15:0]  inst,
        input logic [15:0]  in_m,
        input logic         resetN,

        output logic [15:0] out_m,
        output logic        write_m,
        output logic [14:0] data_addr,
        output logic [14:0] inst_addr
    );

    //////////////////////////////////////////
    reg [14:0] pc;
    reg [15:0] a;
    reg [15:0] d;

    logic stall;



    wire zero; //zero flag from ALU
    wire load_a = !inst[15] || inst[5];
    wire load_d = inst[15] && inst[4];
    wire sel_a = inst[15];
    wire [15:0] alu_out;
    wire sel_am = inst[12]; //select if the ALU's Y input is from ram or from A register
    wire less_than_zero = alu_out[15];
    wire greater_than_zero = !(less_than_zero || zero);
    wire jump = (less_than_zero && inst[2]) || (zero && inst[1]) || (greater_than_zero && inst[0]);
    wire sel_pc = inst[15] && jump;
    wire [14:0] next_pc = sel_pc ? a[14:0] : pc + 15'b1;
    wire [15:0] next_a = !stall ? (sel_a ? alu_out : {1'b0, inst[14:0]}) : a;
    wire [15:0] next_d = !stall ? alu_out : d;
    wire [15:0] m = in_m;
    wire [15:0] am = sel_am ? m : a; // decide whether the alu will use the data in memory or in the A register
    wire [5:0] alu_fn = inst[11:6]; //function for the ALU
    assign data_addr = a[14:0];
    assign out_m = alu_out;
    assign write_m = inst[15] && inst[3] && !stall;
    assign inst_addr = pc;
    always_ff @(posedge clk or negedge resetN)
    begin
        if (!resetN)
            stall <= 1'b1;
        else
            stall <= !stall;
    end

    //ALU module instantiation
    alu alu0(
            .x(d),
            .y(am),
            .out(alu_out),
            .fn(alu_fn),
            .zero(zero)
        );
    always @(posedge clk)
        if (!resetN)
            pc <= 15'b0;
        else if (!stall)
            pc <= next_pc;

    always @(posedge clk)
        if (load_a)
            a <= next_a;

    always @(posedge clk)
        if (load_d)
            d <= next_d;

endmodule
