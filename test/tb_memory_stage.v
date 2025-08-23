`include "./source/memory_stage.v"
// Testbench for mem_stage
module tb_mem_stage;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;

    reg me_rst, me_clk;
    wire [`OPCODE_WIDTH - 1 : 0] me_o_opcode;
    reg [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
    wire [AWIDTH - 1 : 0] me_o_load_addr;
    wire [DWIDTH - 1 : 0] me_o_store_data;
    wire [AWIDTH - 1 : 0] me_o_store_addr;
    wire me_o_we; 
    wire me_o_rd;
    wire me_o_stb, me_o_cyc;
    reg [DWIDTH - 1 : 0] me_i_rs2_data;
    reg [DWIDTH - 1 : 0] me_i_alu_value;
    wire me_o_flush;
    reg me_i_flush;
    wire me_o_stall;
    reg me_i_stall; 
    wire me_o_ce;
    reg me_i_ce;
    reg [DWIDTH - 1 : 0] me_i_rd_data;
    reg [AWIDTH - 1 : 0] me_i_rd_addr; 
    wire [FUNCT_WIDTH - 1 : 0] me_o_funct3;
    reg [FUNCT_WIDTH - 1 : 0] me_i_funct3;
    wire [AWIDTH - 1 : 0] me_o_rd_addr;
    wire [DWIDTH - 1 : 0] me_o_rd_data;
    wire me_o_rd_we;
    wire [DWIDTH - 1 : 0] me_o_load_data;

    // Instantiate memory stage
    mem_stage #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) UUT (
        .me_clk(me_clk),
        .me_rst(me_rst),
        .me_i_ce(me_i_ce),
        .me_i_stall(me_i_stall),
        .me_i_flush(me_i_flush),
        .me_i_rs2_data(me_i_rs2_data),
        .me_i_alu_value(me_i_alu_value),
        .me_i_opcode(me_i_opcode),
        .me_i_rd_addr(me_i_rd_addr),
        .me_i_rd_data(me_i_rd_data),
        .me_o_ce(me_o_ce),
        .me_o_stall(me_o_stall),
        .me_o_flush(me_o_flush),
        .me_o_opcode(me_o_opcode),
        .me_o_cyc(me_o_cyc),
        .me_o_stb(me_o_stb),
        .me_o_we(me_o_we),
        .me_o_rd(me_o_rd),
        .me_o_store_addr(me_o_store_addr),
        .me_o_store_data(me_o_store_data),
        .me_o_load_addr(me_o_load_addr),
        .me_o_load_data(me_o_load_data),
        .me_o_rd_addr(me_o_rd_addr),
        .me_o_rd_data(me_o_rd_data),
        .me_o_rd_we(me_o_rd_we),
        .me_o_funct3(me_o_funct3),
        .me_i_funct3(me_i_funct3)
    );

    // Clock generation
    initial begin
        me_clk = 0;
        me_i_funct3 = 0;
        me_i_rd_addr = 0;
        me_i_rd_data = 0;
        me_i_ce = 0;
        me_i_stall = 0;
        me_i_flush = 0;
        me_i_alu_value = 0;
        me_i_rs2_data = 0;
    end
    always #5 me_clk = ~me_clk;
    
    initial begin
        $dumpfile("./waveform/mem_stage.vcd");
        $dumpvars(0, tb_mem_stage);
    end
    // Reset task
    task do_reset();
    begin
        me_rst = 0;
        #(20);
        me_rst = 1;
    end
    endtask

    // Task to perform store
    task do_store(input [AWIDTH-1:0] addr, input [DWIDTH-1:0] data, input [FUNCT_WIDTH - 1 : 0] funct3);
    begin
        // Drive inputs
        me_i_opcode = `STORE_WORD;
        me_i_funct3 = funct3;
        me_i_alu_value = addr;
        me_i_rs2_data = data;     
        me_i_ce = 1'b1;
        @(posedge me_clk);
        // Deassert ce after one cycle
        me_i_ce = 0;
        // Wait for completion (stall deassert)
        wait (!me_o_stall);
        $display("STORE Complete at time %0t: funct = %0d, addr = %0d, data = %h, byte_enable = %b", $time, funct3, addr, me_o_store_data, UUT.byte_enable);
    end
    endtask

    task do_load (input [AWIDTH - 1 : 0] addr, input [FUNCT_WIDTH - 1 : 0] funct3);
        begin
            me_i_opcode = `LOAD_WORD;
            me_i_funct3 = funct3;
            me_i_alu_value = addr;
            me_i_ce = 1'b1;
            @(posedge me_clk);
            me_i_ce = 1'b0;
            wait(!me_o_stall);
            $display($time, " ", "LOAD funct = %0d, addr = %0d, data = %h", funct3, addr, me_o_load_data);
        end
    endtask

    // Task to perform R-type writeback
    task do_rtype(input [AWIDTH-1:0] rd_addr, input [DWIDTH-1:0] rd_data);
    begin
        me_i_opcode   = `RTYPE;
        me_i_rd_addr  = rd_addr;
        me_i_rd_data  = rd_data;
        me_i_ce       = 1;
        @(posedge me_clk);
        me_i_ce = 0;
        @(posedge me_clk);
        $display("RTYPE Writeback at time %0t: rd_addr = %0d, rd_data = %0d, we = %b, o_rd_addr = %0d, o_rd_data = %0d", $time, rd_addr, rd_data, me_o_rd_we, me_o_rd_addr, me_o_rd_data);
    end
    endtask

    // Main test sequence
    initial begin
        // Initialize inputs
        me_i_stall = 1'b0;
        me_i_flush = 1'b0;
        me_i_rs2_data = {DWIDTH{1'b0}};
        me_i_alu_value = {DWIDTH{1'b0}};
        me_i_opcode = {`OPCODE_WIDTH{1'b0}};
        me_i_rd_addr = {AWIDTH{1'b0}};
        me_i_rd_data = {DWIDTH{1'b0}};
        me_i_funct3 = {FUNCT_WIDTH{1'b0}};  

        // Reset
        do_reset();

        // Test store
        do_store(32'h04, 32'h11223344, `FUNCT_SB);
        do_store(32'h08, 32'hAABBCCDD, `FUNCT_SH);
        do_store(32'h08, 32'h55667788, `FUNCT_SH);
        do_store(32'h10, 32'hCAFECAFE, `FUNCT_SW);

        // Test load
        do_load(32'h04, `FUNCT_LB);
        do_load(32'h04, `FUNCT_LBU);
        do_load(32'h08, `FUNCT_LH);
        do_load(32'h08, `FUNCT_LHU);
        do_load(32'h10, `FUNCT_LW);

        // Test R-type writeback
        do_rtype(5, 32'h12345678);

        // Flush test
        $display("Triggering flush...");
        me_i_flush = 1; @(posedge me_clk);
        me_i_flush = 0;

        // Finish simulation
        #50;
        $finish;
    end
endmodule
