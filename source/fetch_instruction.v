`ifndef FETCH_INSTRUCTION_V
`define FETCH_INSTRUCTION_V

module instruction_fetch #(
    parameter IWIDTH = 32,
    parameter AWIDTH_INSTR = 32,
    parameter PC_WIDTH = 32
)(
    f_clk, f_rst, f_i_instr, f_o_instr, f_o_addr_instr, f_change_pc, f_alu_pc_value, 
    f_pc, f_o_syn, f_i_ack, f_i_stall, f_o_ce, f_o_stall, f_i_flush, f_o_flush, f_i_ce,
    f_i_last
);
    input f_clk, f_rst;
    //Instruction
    output reg [AWIDTH_INSTR - 1 : 0] f_o_addr_instr;
    input [IWIDTH - 1: 0] f_i_instr;
    output reg [IWIDTH - 1: 0] f_o_instr;
    output reg f_o_syn;
    input f_i_ack;
    input f_i_last;
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
    reg temp_ack, temp_last;
    reg req; //value equal to syn
    reg [PC_WIDTH - 1 : 0] issued_pc;

    //The solution of using temporary variables and replacement variables with the same meaning is to avoid falling into race signals leading to a dealock
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
            temp_ack <= 1'b0;
            temp_last <= 1'b0;
            req <= 1'b0;
            issued_pc <= {PC_WIDTH{1'b0}};
        end
        else begin
            if (!init_done) begin
                init_done <= 1'b1;
                //Fix syn chạy trước i_ce được bật 
                if (f_i_ce) begin
                    req <= 1'b1;
                    f_o_syn <= 1'b1;
                    f_o_syn_r <= 1'b1;
                    f_pc <= f_pc + 4;
                    issued_pc <= f_pc;
                end
                else begin
                    req <= 1'b0;
                    f_o_syn <= 1'b0;
                    f_o_syn_r <= 1'b0;
                end
            end
            else begin
                // flush handling: stop requests
                if (f_i_flush) begin
                    req <= 1'b0;
                    f_o_syn <= 1'b0;
                    f_o_stall <= 1'b1;
                    f_o_flush <= 1'b1;
                end
                else begin
                    // if external CE, allow re-issue if no outstanding req and not stalled
                    if (!req && (ce || f_i_ce) && !f_i_stall && !f_o_stall) begin
                        req <= 1'b1;
                        f_o_syn <= 1'b1;
                        f_pc <= f_pc + 4;
                        issued_pc <= f_pc;
                    end
                    // change PC: handle on ack event below 
                    if ((f_change_pc || f_i_ack) && !(f_i_stall || f_o_stall)) begin
                        ce <= 1'b1;
                        f_o_stall <= 1'b0;
                        f_o_flush <= 1'b0;
                    end
                end

                if (stall) begin
                    f_o_ce <= 1'b0;
                end
                else begin
                    f_o_ce <= ce_d;
                end

                if (f_i_stall) begin
                    f_o_stall <= 1'b1; 
                end
                else if (!f_i_flush) begin
                    f_o_stall <= 1'b0;
                end
                f_o_syn_r <= f_o_syn;
            end
        end
    end

    always @(*) begin
        temp_ack = f_i_ack;
        temp_last = f_i_last;
        // When ack = 1, consume returned instruction
        if (temp_ack) begin
            f_o_addr_instr = issued_pc;
            f_o_instr = f_i_instr;
            f_o_flush = 1'b0;
            // // update prev_pc to the pre-increment for f_pc
            // prev_pc = f_pc;
            // if slave said last, stop request; otherwise continue streaming
            if (temp_last) begin
                req = 1'b0;
                f_o_syn = 1'b0;
            end
            else begin
                req = 1'b1;
                f_o_syn = 1'b1;
                f_pc = f_pc + 4;
                issued_pc = f_pc;
            end
            // handle change PC / flush on ack
            if (f_change_pc || f_i_flush) begin
                f_pc = f_alu_pc_value;
            end
            else begin
                ce_d = ce; 
            end
        end
    end
endmodule
`endif 