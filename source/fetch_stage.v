`ifndef FETCH_V
`define FETCH_V

module instruction_fetch #(
    parameter IWIDTH = 32,
    parameter AWIDTH = 32,
    parameter PC_WIDTH = 32
)(
    f_clk, f_rst, f_i_instr, f_o_instr, f_o_addr_instr, f_change_pc, f_alu_pc_value, f_pc, f_o_syn, f_i_ack, f_i_stall, f_o_ce, f_o_stall
);
    input f_clk, f_rst;
    //Instruction
    output reg [AWIDTH - 1 : 0] f_o_addr_instr;
    input [IWIDTH - 1: 0] f_i_instr;
    output reg [IWIDTH - 1: 0] f_o_instr;
    output f_o_syn;
    input f_i_ack;
    //PC
    input f_change_pc;
    input [PC_WIDTH - 1 : 0] f_alu_pc_value;
    output reg [PC_WIDTH - 1: 0] f_pc;
    //Stall 
    input f_i_stall;
    output reg f_o_stall;
    output reg f_o_ce;

    reg [PC_WIDTH - 1 : 0] prev_pc;
    reg [AWIDTH - 1 : 0] i_addr_instr;
    reg ce, ce_d;
    assign f_o_syn = ce;
    wire stall = f_o_stall || f_i_stall || (f_o_syn && !f_i_ack) || !f_o_syn;

    always @(posedge f_clk or negedge f_rst) begin
        if (!f_rst) begin
            ce <= 0;
        end
        else if ((f_change_pc || f_i_ack) && !(f_i_stall || f_o_stall)) begin
            ce <= 0;
        end
        else begin
            ce <= 1;
        end
    end

    always @(posedge f_clk or negedge f_rst) begin
        if (!f_rst) begin
            f_o_instr <= {IWIDTH{1'b0}};
            f_pc <= {PC_WIDTH{1'b0}};
            i_addr_instr <= {AWIDTH{1'b0}};
            f_o_addr_instr <= {AWIDTH{1'b0}};
            prev_pc <= {PC_WIDTH{1'b0}};
            ce_d <= 1'b0;
        end
        else begin
            if ((ce && f_i_ack && !stall) || (stall && !f_o_ce && ce)) begin
                i_addr_instr <= prev_pc; 
                f_o_addr_instr <= i_addr_instr;
                f_o_instr <= f_i_instr;
            end
            if (stall) begin
                f_o_ce <= 0;
            end
            else begin
                f_o_ce <= ce_d;
            end
            if (f_i_ack) begin
                prev_pc <= f_pc;
                if (f_change_pc) begin
                    f_pc <= f_alu_pc_value; 
                end
                else begin
                    f_pc <= f_pc + 4;
                    ce_d <= ce;
                end
            end
        end
    end
endmodule
`endif 