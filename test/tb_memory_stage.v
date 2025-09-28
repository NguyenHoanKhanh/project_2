`include "./source/memory_stage.v"
 // Testbench for mem_stage
module tb_mem_stage;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;

    reg me_rst, me_clk;
    wire [`OPCODE_WIDTH - 1 : 0] me_o_opcode;
    reg [`OPCODE_WIDTH - 1 : 0] me_i_opcode;
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
    reg me_we_reg_n;
    wire [DWIDTH - 1 : 0] me_o_load_data;
    integer i;

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
        i = 0;
    end
    always #5 me_clk = ~me_clk;
    
    initial begin
        $dumpfile("./waveform/mem_stage.vcd");
        $dumpvars(0, tb_mem_stage);
    end

    // ---------- NEW: stall helper task ----------
    // Introduce an input stall (me_i_stall) for a given number of clock cycles.
    task introduce_stall(input integer cycles);
        integer j;
        begin
            $display(">>> TB: introducing input stall for %0d cycles at time %0t", cycles, $time);
            me_i_stall = 1'b1;
            for (j = 0; j < cycles; j = j + 1) @(posedge me_clk);
            me_i_stall = 1'b0;
            @(posedge me_clk);
            $display(">>> TB: input stall cleared at time %0t", $time);
        end
    endtask

    // Reset task
    task do_reset();
        begin
            me_rst = 0;
            #(20);
            me_rst = 1;
            @(posedge me_clk);
        end
    endtask

    function [`OPCODE_WIDTH - 1 : 0] opc;
        input integer idx;
        begin
            opc = {`OPCODE_WIDTH{1'b0}};
            opc[idx] = 1'b1;
        end
    endfunction

    // Task to perform store
    task do_store(input [AWIDTH-1:0] addr, input [DWIDTH-1:0] data, input [FUNCT_WIDTH - 1 : 0] funct3);
        begin
            // Drive inputs
            me_i_opcode = opc(`STORE_WORD);
            me_i_funct3 = funct3;
            me_i_alu_value = addr;
            me_i_rs2_data = data;     
            me_i_ce = 1'b1;
            me_we_reg_n = 1'b1;
            repeat(2) @(posedge me_clk);
            // Deassert ce after one cycle
            me_i_ce = 0;
            $display("STORE Complete at time %0t: funct = %0d, addr = %0d, data = %h, byte_enable = %b, me_o_rd_we = %b, opcode = %b, me_o_stall = %b", $time, 
            funct3, addr, UUT.me_o_store_data, UUT.byte_enable, me_o_rd_we, me_o_opcode, me_o_stall);
            me_i_opcode = {`OPCODE_WIDTH{1'b0}};
        end
    endtask

    task do_load (input [AWIDTH - 1 : 0] addr, input [FUNCT_WIDTH - 1 : 0] funct3);
            begin
                me_i_opcode = opc(`LOAD_WORD);
                me_i_funct3 = funct3;
                me_i_alu_value = addr;
                me_i_ce = 1'b1;
                @(posedge me_clk);
                me_i_ce = 1'b0;
                // wait a couple cycles to let memory ack and stage commit
                repeat (2) @(posedge me_clk);
                $display("%0t LOAD Complete funct = %0d, addr = %0d, data = %h, me_o_stall = %b, UUT.me_o_cyc = %b, UUT.me_o_stb = %b",
                         $time, funct3, addr, me_o_load_data, me_o_stall, UUT.me_o_cyc, UUT.me_o_stb);
                me_i_opcode = {`OPCODE_WIDTH{1'b0}};
            end
    endtask

    // Task to perform R-type writeback
    task do_rtype(input [AWIDTH-1:0] rd_addr, input [DWIDTH-1:0] rd_data);
        begin
            me_i_opcode = opc(`RTYPE);
            me_i_rd_addr  = rd_addr;
            me_i_rd_data  = rd_data;
            me_i_ce       = 1;
            me_we_reg_n = 1'b1;
            @(posedge me_clk);
            me_i_ce = 0;
            @(posedge me_clk);
            $display("RTYPE Writeback at time %0t: rd_addr = %0d, rd_data = %0d, we = %b, o_rd_addr = %0d, o_rd_data = %0d",
                     $time, rd_addr, rd_data, me_o_rd_we, me_o_rd_addr, me_o_rd_data);
            me_i_opcode = {`OPCODE_WIDTH{1'b0}};
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
        me_we_reg_n = 1'b0;

        // Reset
        do_reset();

        // ---------- STORE tests (with stall scenarios) ----------
        // SB at offsets 0..3
        // Insert a stall before the first store to see how stage handles incoming stall
        $display("\n--- STORE tests with stall scenarios ---\n");
        introduce_stall(2);
        do_store(32'h00000000, 32'h00000011, `FUNCT_SB); // off 0

        // Introduce a stall immediately after issuing a store (simulate upstream backpressure)
        do_store(32'h00000001, 32'h00000022, `FUNCT_SB); // off 1
        introduce_stall(3); // stall while store may be pending

        do_store(32'h00000002, 32'h00000033, `FUNCT_SB); // off 2

        // SH at offsets 0..2 (avoid off 3)
        // Simulate stall during short store sequence
        introduce_stall(1);
        do_store(32'h00000004, 32'h00005566, `FUNCT_SH); // off 0
        do_store(32'h00000005, 32'h00007788, `FUNCT_SH); // off 1

        // SW aligned; also test stall while SW is in flight
        do_store(32'h00000008, 32'hCAFEBABE, `FUNCT_SW);
        introduce_stall(2);

        // ---------- LOAD tests (with stall scenarios) ----------
        $display("\n--- LOAD tests with stall scenarios ---\n");
        // Simple loads with occasional stalls injected between them
        do_load(32'h0000_0000, `FUNCT_LB );
        introduce_stall(2); // stall between loads

        do_load(32'h0000_0001, `FUNCT_LBU);
        do_load(32'h0000_0002, `FUNCT_LB );
        introduce_stall(1);

        do_load(32'h0000_0003, `FUNCT_LBU);

        do_load(32'h0000_0004, `FUNCT_LH );
        // Stall right after issuing a load to see pending behavior
        // We'll issue the load and immediately assert me_i_stall for a few cycles
        // For that, call do_load and then introduce_stall right away (do_load already waits 2 cycles)
        do_load(32'h0000_0004, `FUNCT_LHU);
        introduce_stall(3);

        do_load(32'h0000_0006, `FUNCT_LH );
        do_load(32'h0000_0006, `FUNCT_LHU);

        do_load(32'h0000_0008, `FUNCT_LW );

        // ---------- R-type WB ----------
        do_rtype(5, 32'h1234_5678);

        // Flush test
        $display("Triggering flush...");
        me_i_flush = 1; @(posedge me_clk);
        me_i_flush = 0;

        // Final stall test: assert stall while idle to ensure stage resumes correctly
        $display("\n--- Final stall while idle ---\n");
        introduce_stall(4);

        // Finish simulation
        #50;
        $finish;
    end
endmodule
