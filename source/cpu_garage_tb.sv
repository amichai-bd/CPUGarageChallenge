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
#1
    $readmemb({"../hack/rom.sv"}, IMem);
    //$readmemh({"../hack/rom2.sv"}, IMem);
    force cpu_garage_tb.cpu_garage.rom_inst.mem = IMem; //XMR - cross module reference
    #100_000 $finish;
end: test_seq

//Instantiating
    cpu_garage cpu_garage (
        .Clk  (Clock),
        .Reset(Rst)
    );

//tracker on memory writes
integer trk_d_mem_access;
integer trk_reg_access;
integer trk_d_mem_access_no_time;
initial begin
    trk_d_mem_access      = $fopen({"trk_d_mem_access.log"},"w");
    trk_reg_access      = $fopen({"trk_reg_access.log"},"w");
    trk_d_mem_access_no_time      = $fopen({"trk_d_mem_access_no_time.log"},"w");
    $fwrite(trk_d_mem_access,"-----------------------------------------------------\n");
    $fwrite(trk_d_mem_access,"                Time\t| Address\t| Read/Write| data\t\t|\n");
    $fwrite(trk_d_mem_access,"-----------------------------------------------------\n");
    $fwrite(trk_d_mem_access_no_time,"-----------------------------------------------------\n");
    $fwrite(trk_d_mem_access_no_time," Address\t| Read/Write| data\t\t|\n");
    $fwrite(trk_d_mem_access_no_time,"-----------------------------------------------------\n");
end //initial
always @(posedge Clock) begin : memory_access_print
#1
    if (cpu_garage_tb.cpu_garage.we) begin 
        $fwrite(trk_d_mem_access,"%t\t| %8h\t| WRITE\t\t| %8h\t| \n", 
        $realtime,
        cpu_garage_tb.cpu_garage.ram_address ,
        cpu_garage_tb.cpu_garage.cpu_out_m);
        $fwrite(trk_d_mem_access_no_time," %8h\t| WRITE\t\t| %8h\t| \n", 
        cpu_garage_tb.cpu_garage.ram_address ,
        cpu_garage_tb.cpu_garage.cpu_out_m);
    end //if
    //if (cpu_garage_tb.cpu_garage.cpu_inst.A_WrEn101) begin 
    //    $fwrite(trk_reg_access,"%t\t|WRITE A\t| %8h\t| \n", 
    //    $realtime,
    //    cpu_garage_tb.cpu_garage.cpu_inst.A_Data101);
    //end //if
    //if (cpu_garage_tb.cpu_garage.cpu_inst.D_WrEn101) begin 
    //    $fwrite(trk_reg_access,"%t\t|WRITE A\t| %8h\t| \n", 
    //    $realtime,
    //    cpu_garage_tb.cpu_garage.cpu_inst.D_Data101);
    //end //if
end //shared_space

endmodule // test_tb
