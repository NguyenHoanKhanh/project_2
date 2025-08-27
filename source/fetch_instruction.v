`ifndef FETCH_INSTRUCTION_V
`define FETCH_INSTRUCTION_V

module instruction_fetch #(
    parameter IWIDTH = 32,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    f_clk, f_rst, f_i_instr, f_o_instr, f_o_addr_instr, f_change_pc, f_alu_pc_value, 
    f_pc, f_o_syn, f_i_ack, f_i_stall, f_o_ce, f_o_stall, f_i_flush, f_o_flush, f_i_ce
);
    input f_clk, f_rst;
    //Instruction
    output reg [AWIDTH_INSTR - 1 : 0] f_o_addr_instr;
    input [IWIDTH - 1: 0] f_i_instr;
    output reg [IWIDTH - 1: 0] f_o_instr;
    output reg f_o_syn;
    input f_i_ack;
    //PC
    input f_change_pc;
    input [PC_WIDTH - 1 : 0] f_alu_pc_value;
    output reg [PC_WIDTH - 1: 0] f_pc;
    //Stall 
    input f_i_stall;
    output reg f_o_stall;
    input f_i_ce;
    output reg f_o_ce;
    input f_i_flush;
    output reg f_o_flush;
    //Internal state regs
    reg [PC_WIDTH - 1 : 0] prev_pc;
    reg ce, ce_d;
    reg f_o_syn_r;
    wire stall = f_o_stall || f_i_stall || (f_o_syn_r && !f_i_ack);
    reg init_done;

    always @(posedge f_clk, negedge f_rst) begin
        if (!f_rst) begin
            f_o_stall <= 1'b0;
            ce <= 1'b0;
            ce_d <= 1'b0;
            f_o_ce <= 1'b0;
            f_o_flush <= 1'b0;
            f_o_stall <= 1'b0;
            f_o_instr <= {IWIDTH{1'b0}};
            f_pc <= {PC_WIDTH{1'b0}};
            prev_pc <= {PC_WIDTH{1'b0}};
            f_o_addr_instr <= {AWIDTH_INSTR{1'b0}};
            f_o_syn_r <= 1'b0;
            f_o_syn <= 1'b0;
            init_done <= 1'b0;
        end
        else begin
            if (!init_done) begin
                init_done <= 1'b1;
                ce <= 1'b1;
                f_o_syn <= 1'b1;
                f_o_syn_r <= 1'b1;
                f_pc <= f_pc + 4;
            end
            else begin
                // existing CE / request generation
                if (f_i_flush) begin
                    ce <= 1'b0;
                    f_o_stall <= 1'b1;
                    f_o_flush <= 1'b1;
                end
                else if ((f_change_pc || f_i_ack) && !(f_i_stall || f_o_stall)) begin
                    ce <= 1'b1;
                    f_o_stall <= 1'b0;
                    f_o_flush <= 1'b0;
                end
                else if (f_i_ce) begin
                    ce <= 1'b1;
                end
                // // SYN generation: set when request; pre-increment PC to reduce latency
                // if (!f_o_syn && ce && !f_i_ack && !f_i_stall && !f_o_stall) begin
                //     f_o_syn <= 1'b1;
                //     f_pc <= f_pc + 4;
                // end
                // else if (f_i_ack || f_i_flush) begin
                //     f_o_syn <= 1'b0;
                // end
                // output instruction when acked and allowed
                if((ce && f_i_ack && !stall) || (stall && !f_o_ce && ce)) begin
                    f_o_addr_instr <= prev_pc;
                    f_o_instr <= f_i_instr;
                    f_o_flush <= 1'b0;
                end
                // CE output control
                if (stall) begin
                    f_o_ce <= 1'b0;
                end
                else begin
                    f_o_ce <= ce_d;
                end
                // update PC/ce_d when ack arrives
                if (f_i_ack) begin
                    prev_pc <= f_pc;
                    f_o_syn <= 1'b0;
                    if (f_change_pc || f_i_flush) begin
                        f_pc <= f_alu_pc_value;
                    end
                    else begin
                        ce_d <= ce;
                    end
                end
                f_o_syn_r <= f_o_syn;
            end
        end
    end
endmodule
`endif 