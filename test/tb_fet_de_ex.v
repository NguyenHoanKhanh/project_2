`include "./source/fetch_decoder_execute.v"

module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter DWIDTH = 32;

    reg fe_clk, fe_rst; 
    reg fe_i_ce;
    reg fe_i_stall, fe_i_flush;
    wire [`ALU_WIDTH - 1 : 0] fe_o_alu;
    wire [`OPCODE_WIDTH - 1 : 0] fe_o_opcode;
    wire [AWIDTH - 1 : 0] fe_o_addr_rd;
    wire [DWIDTH - 1 : 0] fe_o_data_rd; 
    wire [FUNCT_WIDTH - 1 : 0] fe_o_funct3;
    wire [DWIDTH - 1 : 0] fe_o_imm; 
    wire [PC_WIDTH - 1 : 0] fe_next_pc;
    wire [PC_WIDTH - 1 : 0] fe_pc_n;
    wire [DWIDTH - 1 : 0] fe_alu_value;
    wire fe_o_stall_n, fe_o_flush_n, fe_o_ce_n, fe_stall_alu;
    wire fe_o_ce;
    wire fe_we_reg;
    wire [DWIDTH - 1 : 0] fe_o_data_rs1;
    wire [DWIDTH - 1 : 0] fe_o_data_rs2; 
    wire [AWIDTH - 1 : 0] fe_o_addr_rs1;
    wire [AWIDTH - 1 : 0] fe_o_addr_rs2;
    wire fe_o_valid;
    integer i;

    fetch_execute #(
        .IWIDTH(IWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) fe (
        .fe_clk(fe_clk), 
        .fe_rst(fe_rst), 
        .fe_i_ce(fe_i_ce), 
        .fe_i_stall(fe_i_stall), 
        .fe_i_flush(fe_i_flush), 
        .fe_o_alu(fe_o_alu), 
        .fe_o_opcode(fe_o_opcode), 
        .fe_o_addr_rd(fe_o_addr_rd), 
        .fe_o_data_rd(fe_o_data_rd), 
        .fe_o_funct3(fe_o_funct3), 
        .fe_o_imm(fe_o_imm), 
        .fe_next_pc(fe_next_pc), 
        .fe_pc_n(fe_pc_n), 
        .fe_alu_value(fe_alu_value), 
        .fe_o_stall_n(fe_o_stall_n), 
        .fe_o_flush_n(fe_o_flush_n), 
        .fe_o_ce_n(fe_o_ce_n), 
        .fe_stall_alu(fe_stall_alu),
        .fe_o_ce(fe_o_ce), 
        .fe_o_data_rs1(fe_o_data_rs1), 
        .fe_o_data_rs2(fe_o_data_rs2), 
        .fe_o_addr_rs1(fe_o_addr_rs1), 
        .fe_o_addr_rs2(fe_o_addr_rs2), 
        .fe_o_valid(fe_o_valid),
        .fe_we_reg(fe_we_reg)
    );

    initial begin
        fe_i_ce = 1'b0;
        fe_clk = 1'b0;
    end
    always #5 fe_clk = ~fe_clk;

    initial begin
        $dumpfile("./waveform/fe_de_ex.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            fe_rst = 1'b0;
            repeat(counter) @(posedge fe_clk);
            fe_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            fe_i_ce = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge fe_clk);
                #5;
                $display($time, " fe_o_ce = %b, fe_stall_alu = %b, fe_o_ce_n = %b, fe_o_flush_n = %b, fe_o_stall_n = %b, fe_pc_n = %0d, fe_next_pc = %0d, fe_o_funct3 = %b,  fe_o_opcode = %b", 
                fe_o_ce, fe_stall_alu, fe_o_ce_n, fe_o_flush_n, fe_o_stall_n, fe_pc_n, fe_next_pc, fe_o_funct3, fe_o_opcode);
                $display($time, " fe_alu_value = %h, fe_o_imm = %h, fe_o_alu = %b", fe_alu_value, fe_o_imm,  fe_o_alu);
                $display($time, " Instr = %h", fe.fe_i_instr_fetch);
                $display($time, " fe_o_addr_rs1 = %d, fe_o_addr_rs2 = %d", fe_o_addr_rs1, fe_o_addr_rs2);
                $display($time, " fe_o_data_rs1 = %0d, fe_o_data_rs2 = %0d", fe_o_data_rs1, fe_o_data_rs2);
                $display($time, " Write_enable = %b", fe_we_reg);
                $display($time, " fe_o_data_rd = %d, fe_o_addr_rd = %h, valid = %b\n", fe_o_data_rd, fe_o_addr_rd, fe_o_valid);
            end
        end
    endtask

    initial begin
        reset(2);
        @(posedge fe_clk);
        fe_i_stall = 1'b0;
        fe_i_flush = 1'b0;
        display(100);
        #20; $finish;
    end
endmodule