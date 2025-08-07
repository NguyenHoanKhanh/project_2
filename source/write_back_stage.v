`ifndef WRITE_BACK_STAGE_V
`define WRITE_BACK_STAGE_V
`include "./source/header.vh"
module writeback #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter PC_WIDTH = 32, 
    parameter FUNCT_WIDTH = 3
)(
    wb_clk, wb_rst, wb_i_opcode, wb_i_data_load, wb_i_we_rd, wb_o_we_rd, wb_i_rd_addr, 
    wb_o_rd_addr, wb_i_rd_data, wb_o_rd_data, wb_i_pc, wb_o_next_pc, wb_o_change_pc, 
    wb_i_ce, wb_o_stall, wb_o_flush, wb_i_csr, wb_i_funct, wb_i_flush, wb_i_stall, wb_o_ce
);
    input wb_clk, wb_rst;
    input [FUNCT_WIDTH - 1 : 0] wb_i_funct;
    input [`OPCODE_WIDTH - 1 : 0] wb_i_opcode;
    input [DWIDTH - 1 : 0] wb_i_data_load;
    input [DWIDTH - 1 : 0] wb_i_csr;
    input wb_i_we_rd;
    output reg wb_o_we_rd;
    input [AWIDTH - 1 : 0] wb_i_rd_addr;
    input [DWIDTH - 1 : 0] wb_i_rd_data;
    output reg [AWIDTH - 1 : 0] wb_o_rd_addr;
    output reg [DWIDTH - 1 : 0] wb_o_rd_data;

    input [PC_WIDTH - 1 : 0] wb_i_pc;
    output reg [PC_WIDTH - 1 : 0] wb_o_next_pc;
    output reg wb_o_change_pc;
    input wb_i_ce;
    output reg wb_o_ce;
    input wb_i_stall;
    output reg wb_o_stall;
    input wb_i_flush;
    output reg wb_o_flush;

    wire wb_opcode_load = (wb_i_opcode == `LOAD) ? 1 : 0;
    wire wb_opcode_system = (wb_i_opcode == `SYSTEM) ? 1 : 0;
    wire stall_bit = wb_i_stall || wb_o_stall;

    always @(posedge wb_clk or negedge wb_rst) begin
        if (!wb_rst) begin
            wb_o_we_rd <= 1'b0;
            wb_o_rd_addr <= {AWIDTH{1'b0}};
            wb_o_rd_data <= {DWIDTH{1'b0}};
            wb_o_next_pc <= {PC_WIDTH{1'b0}};
            wb_o_change_pc <= 1'b0;
            wb_o_stall <= 1'b0;
            wb_o_flush <= 1'b0;
            wb_o_ce <= 1'b0;
        end
        else begin
            if (!wb_i_flush) begin
                if (wb_i_ce) begin
                    wb_o_stall <= 1'b0;
                    wb_o_flush <= 1'b0;
                    wb_o_change_pc <= 1'b0;
                    wb_o_we_rd <= wb_i_we_rd;
                    wb_o_rd_addr <= wb_i_rd_addr;
                    if (wb_opcode_load) begin
                        wb_o_rd_data <= wb_i_data_load;
                    end
                    else if (wb_opcode_system && wb_i_funct != 3'd0) begin
                        wb_o_rd_data <= wb_i_csr;
                    end
                    else begin
                        wb_o_rd_data <= wb_i_rd_data;
                    end
                    wb_o_next_pc <= wb_i_pc + 32'd4;
                end
                else begin
                    wb_o_flush <= 1'b1;
                    wb_o_stall <= 1'b1;
                    wb_o_change_pc <= 1'b1;
                end
            end
        end
    end
endmodule
`endif 