`include "./source/connect_fet_de.v"
module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    parameter AWIDTH_INSTR = 32;
    parameter PC_WIDTH = 32;
    parameter AWIDTH = 5;
    parameter FUNCT_WIDTH = 3;
    parameter DWIDTH = 32;

    reg c_clk, c_rst;
    reg fi_i_stall, fi_i_flush, fi_i_ce;
    wire [IWIDTH - 1 : 0] fi_o_instr_fetch;
    wire [DWIDTH - 1 : 0] ds_data_out_rs2, ds_data_out_rs1;
    reg [DWIDTH - 1 : 0] ds_data_in_rd;
    wire [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    wire [`ALU_WIDTH - 1 : 0] ds_o_alu;
    wire [DWIDTH - 1 : 0] ds_o_imm;
    wire [FUNCT_WIDTH - 1 : 0] ds_o_funct3;
    wire [AWIDTH - 1 : 0] ds_o_addr_rd_p, ds_o_addr_rs1_p, ds_o_addr_rs2_p;
    reg ds_read_reg, ds_we;
    integer i;

    connect # (
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH),
        .AWIDTH(AWIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH),
        .DWIDTH(DWIDTH)
    ) cn (
        .c_clk(c_clk), 
        .c_rst(c_rst), 
        .fi_i_stall(fi_i_stall), 
        .fi_i_flush(fi_i_flush), 
        .fi_i_ce(fi_i_ce), 
        .fi_o_instr_fetch(fi_o_instr_fetch), 
        .ds_data_out_rs2(ds_data_out_rs2), 
        .ds_data_out_rs1(ds_data_out_rs1),
        .ds_data_in_rd(ds_data_in_rd), 
        .ds_o_opcode(ds_o_opcode), 
        .ds_o_alu(ds_o_alu), 
        .ds_o_imm(ds_o_imm), 
        .ds_o_funct3(ds_o_funct3), 
        .ds_o_addr_rd_p(ds_o_addr_rd_p), 
        .ds_o_addr_rs1_p(ds_o_addr_rs1_p), 
        .ds_o_addr_rs2_p(ds_o_addr_rs2_p),
        .ds_we(ds_we),
        .ds_read_reg(ds_read_reg)
    );

    initial begin
        c_clk = 1'b0;
        fi_i_stall = 1'b0;
        fi_i_flush = 1'b0;
        fi_i_ce = 1'b0;
        ds_data_in_rd = {DWIDTH{1'b0}};
        ds_read_reg = 1'b0;
        ds_we = 1'b0;
        i = 0;
    end
    always #5 c_clk = ~c_clk;

    initial begin
        $dumpfile("./waveform/connect.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            c_rst = 1'b0;
            repeat(counter) @(posedge c_clk);
            c_rst = 1'b1;
        end
    endtask

    initial begin
        reset(2);
        @(posedge c_clk);
        fi_i_ce = 1'b1;

        for (i = 0; i < 5; i = i + 1) begin
            ds_we = 1'b1;
            ds_data_in_rd = i;
            @(posedge c_clk);
        end
        ds_we = 1'b0;

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge c_clk);
            ds_read_reg = 1'b1;
        end
        ds_read_reg = 1'b0;
        repeat(36) @(posedge c_clk);
        #200; 
        $finish;
    end

    initial begin
    $monitor("%0t fi_o_instr_fetch = %h, ds_data_out_rs1 = %0d, ds_data_out_rs2 = %0d, ds_o_opcode = %b, ds_o_alu = %b, ds_o_imm = %b, ds_o_funct3 = %b, ds_o_addr_rd_p = %0d, ds_o_addr_rs2_p = %0d, ds_o_addr_rs1_p = %0d",
           $time,
           fi_o_instr_fetch, ds_data_out_rs1, ds_data_out_rs2,
           ds_o_opcode, ds_o_alu, ds_o_imm, ds_o_funct3,
           ds_o_addr_rd_p, ds_o_addr_rs2_p, ds_o_addr_rs1_p);
end

endmodule