`include "./source/forwarding.v"

module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 5;

    reg [DWIDTH - 1 : 0] h_data_reg_rs1, h_data_reg_rs2;
    reg [AWIDTH - 1 : 0] h_decoder_addr_rs1, h_decoder_addr_rs2;
    wire h_alu_force_stall_out;
    wire [DWIDTH - 1 : 0] h_data_out_rs1, h_data_out_rs2;
    reg h_i_valid_alu;
    reg h_i_we_reg_alu;
    reg [AWIDTH - 1 : 0] h_i_alu_addr_rd;
    reg [DWIDTH - 1 : 0] h_i_alu_data_rd;
    reg h_i_memoryaccess_ce;
    reg h_i_we_reg_mem;
    reg [AWIDTH - 1 : 0] h_i_addr_rd_mem;
    reg h_i_wb_ce;
    reg [DWIDTH - 1 : 0] h_i_data_rd_wb;

    forwarding #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) f (
        .h_data_reg_rs1(h_data_reg_rs1), 
        .h_data_reg_rs2(h_data_reg_rs2), 
        .h_decoder_addr_rs1(h_decoder_addr_rs1), 
        .h_decoder_addr_rs2(h_decoder_addr_rs2),
        .h_alu_force_stall_out(h_alu_force_stall_out), 
        .h_data_out_rs1(h_data_out_rs1), 
        .h_data_out_rs2(h_data_out_rs2), 
        .h_i_valid_alu(h_i_valid_alu), 
        .h_i_we_reg_alu(h_i_we_reg_alu),
        .h_i_alu_addr_rd(h_i_alu_addr_rd), 
        .h_i_alu_data_rd(h_i_alu_data_rd), 
        .h_i_memoryaccess_ce(h_i_memoryaccess_ce), 
        .h_i_we_reg_mem(h_i_we_reg_mem), 
        .h_i_addr_rd_mem(h_i_addr_rd_mem), 
        .h_i_wb_ce(h_i_wb_ce),
        .h_i_data_rd_wb(h_i_data_rd_wb)
    );

    initial begin
        $dumpfile("./waveform/forwarding.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        h_i_valid_alu = 1'b0;
        h_i_we_reg_alu = 1'b0;
        h_i_memoryaccess_ce = 1'b0;
        h_i_wb_ce = 1'b0;
        h_i_we_reg_mem = 1'b0;
        h_data_reg_rs1 = {DWIDTH{1'b0}};
        h_data_reg_rs2 = {DWIDTH{1'b0}};
        h_decoder_addr_rs1 = {AWIDTH{1'b0}};
        h_decoder_addr_rs2 = {AWIDTH{1'b0}};
        h_i_alu_addr_rd = {AWIDTH{1'b0}};
        h_i_alu_data_rd = {DWIDTH{1'b0}};
        h_i_addr_rd_mem = {AWIDTH{1'b0}};
        h_i_data_rd_wb = {DWIDTH{1'b0}};
        #10;
        //Check address decider fit with address alu 
        h_decoder_addr_rs1 = 5'd0;
        h_decoder_addr_rs2 = 5'd0;
        h_i_alu_addr_rd = 5'd0;
        h_i_alu_data_rd = 32'd109;
        h_i_valid_alu = 1'b0;
        h_i_we_reg_alu = 1'b1;
        h_i_memoryaccess_ce = 1'b1;
        #1; 
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
        #1;
        h_decoder_addr_rs1 = 5'd10;
        h_decoder_addr_rs2 = 5'd12;
        h_data_reg_rs1 = 32'd100;
        h_data_reg_rs2 = 32'd88;
        #1;
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
        #1;
        //Check address decider fit with address alu rs1
        h_decoder_addr_rs1 = 5'd10;
        h_i_alu_addr_rd = 5'd10;
        h_i_alu_data_rd = 32'd109;
        h_i_valid_alu = 1'b0;
        h_i_we_reg_alu = 1'b1;
        h_i_memoryaccess_ce = 1'b1;
        #1; 
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
        #1;
        h_decoder_addr_rs1 = 5'd10;
        h_i_alu_addr_rd = 5'd10;
        h_i_alu_data_rd = 32'd109;
        h_i_valid_alu = 1'b1;
        h_i_we_reg_alu = 1'b1;
        h_i_memoryaccess_ce = 1'b1;
        #1; 
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
        //Check address decider fit with address alu rs2
        h_decoder_addr_rs2 = 5'd12;
        h_i_alu_addr_rd = 5'd12;
        h_i_alu_data_rd = 32'd111;
        h_i_valid_alu = 1'b0;
        h_i_we_reg_alu = 1'b1;
        h_i_memoryaccess_ce = 1'b1;
        #1; 
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
        #1;
        h_decoder_addr_rs2 = 5'd12;
        h_i_alu_addr_rd = 5'd12;
        h_i_alu_data_rd = 32'd111;
        h_i_valid_alu = 1'b1;
        h_i_we_reg_alu = 1'b1;
        h_i_memoryaccess_ce = 1'b1;
        #1; 
        $display($time, " ", "address rs1 = %d, data rs1 = %d, address rs2 = %d, data rs2 = %d, h_alu_force_stall_out = %b", h_decoder_addr_rs1, h_data_out_rs1, h_decoder_addr_rs2, h_data_out_rs2, h_alu_force_stall_out);
    end
endmodule