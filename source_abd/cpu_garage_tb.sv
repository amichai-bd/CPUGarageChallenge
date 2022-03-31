module cpu_garage_tb ();
    logic Clock;
    logic Rst;

// clock generation
initial begin: clock_gen
    forever begin
        #5 Clock = 1'b0;
        #5 Clock = 1'b1;
    end
end: clock_gen

initial begin: reset_gen
    Rst = 1'b1;
#40 Rst = 1'b0;
end: reset_gen

logic  [15:0] IMem [1023:0];
initial begin: test_seq
    $readmemb({"../hack/rom.sv"}, IMem);
    force cpu_garage_tb.cpu_garage.rom_inst.mem = IMem; //XMR - cross module reference
    #10000 $finish;
end: test_seq

//Instantiating
    cpu_garage cpu_garage (
        .Clk  (Clock),
        .Reset(Rst)
    );

//tracker on memory writes
integer trk_d_mem_access;
initial begin
    trk_d_mem_access      = $fopen({"trk_d_mem_access.log"},"w");
    $fwrite(trk_d_mem_access,"-----------------------------------------------------\n");
    $fwrite(trk_d_mem_access,"                Time\t| Address\t| Read/Write| data\t\t|\n");
    $fwrite(trk_d_mem_access,"-----------------------------------------------------\n");
end //initial
always @(posedge Clock) begin : memory_access_print
    if (cpu_garage_tb.cpu_garage.we) begin 
        $fwrite(trk_d_mem_access,"%t\t| %8h\t| WRITE\t\t| %8h\t| \n", 
        $realtime,
        cpu_garage_tb.cpu_garage.ram_address ,
        cpu_garage_tb.cpu_garage.cpu_out_m);
    end //if
end //shared_space

endmodule // test_tb
