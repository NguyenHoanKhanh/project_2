`include "./source/memory_stage.v"
// Testbench for mem_stage
module tb_mem_stage;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;

    // Signals
    reg              me_clk;
    reg              me_rst;
    reg              me_i_ce;
    reg              me_i_stall;
    reg              me_i_flush;
    reg  [DWIDTH-1:0] me_i_rs2_data;
    reg  [DWIDTH-1:0] me_i_alu_value;
    reg  [`OPCODE_WIDTH-1:0] me_i_opcode;
    reg  [AWIDTH-1:0] me_i_rd_addr;
    reg  [DWIDTH-1:0] me_i_rd_data;

    wire             me_o_ce;
    wire             me_o_stall;
    wire             me_o_flush;
    wire [`OPCODE_WIDTH-1:0] me_o_opcode;
    wire             me_o_cyc;
    wire             me_o_stb;
    wire             me_o_we;
    wire [AWIDTH-1:0] me_o_store_addr;
    wire [DWIDTH-1:0] me_o_store_data;
    wire [AWIDTH-1:0] me_o_load_addr;
    wire [AWIDTH-1:0] me_o_rd_addr;
    wire [DWIDTH-1:0] me_o_rd_data;
    wire             me_o_rd_we;

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
        .me_o_store_addr(me_o_store_addr),
        .me_o_store_data(me_o_store_data),
        .me_o_load_addr(me_o_load_addr),
        .me_o_rd_addr(me_o_rd_addr),
        .me_o_rd_data(me_o_rd_data),
        .me_o_rd_we(me_o_rd_we)
    );

    // Clock generation
    initial begin
        me_clk = 0;
        forever #5 me_clk = ~me_clk;
    end
    
    initial begin
        $dumpfile("./waveform/memeory_stage.vcd");
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
    task do_store(input [AWIDTH-1:0] addr, input [DWIDTH-1:0] data);
    begin
        // Drive inputs
        me_i_opcode    = `STORE;
        me_i_alu_value = addr;
        me_i_rs2_data  = data;
        me_i_ce        = 1;
        @(posedge me_clk);
        // Deassert ce after one cycle
        me_i_ce = 0;
        // Wait for completion (stall deassert)
        wait (!me_o_stall);
        $display("STORE Complete at time %0t: addr=%0d data=%0d", $time, addr, data);
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
        $display("RTYPE Writeback at time %0t: rd_addr=%0d rd_data=%0d we=%b", $time, rd_addr, rd_data, me_o_rd_we);
    end
    endtask

    // Main test sequence
    initial begin
        // Initialize inputs
        me_i_stall    = 0;
        me_i_flush    = 0;
        me_i_rs2_data = 0;
        me_i_alu_value= 0;
        me_i_opcode   = 0;
        me_i_rd_addr  = 0;
        me_i_rd_data  = 0;

        // Reset
        do_reset();

        // Test store and load
        do_store(10, 14);

        // Test R-type writeback
        do_rtype(3, 12345);

        // Finish simulation
        #20;
        $finish;
    end
endmodule
