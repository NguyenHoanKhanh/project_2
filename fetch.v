`ifndef FETCH_V
`define FETCH_V

module instruction_fetch #(
    parameter I_WIDTH = 32,
    parameter A_WIDTH = 32,
    parameter PC_WIDTH = 32
)(
    f_clk, f_rst_n, i_instr, o_instr, o_addr_instr, change_pc, alu_pc_value, pc, o_syn, i_ack, i_stall, o_ce
);
    input f_clk, f_rst_n;
    //Instruction
    output reg [A_WIDTH - 1 : 0] o_addr_instr;
    input [I_WIDTH - 1: 0] i_instr;
    output reg [I_WIDTH - 1: 0] o_instr;
    output o_syn;
    input i_ack;
    //PC
    input change_pc;
    input [PC_WIDTH - 1 : 0] alu_pc_value;
    output reg [PC_WIDTH - 1: 0] pc;
    //Stall 
    input i_stall;
    output reg o_ce;

    reg [PC_WIDTH - 1 : 0] prev_pc;
    reg [A_WIDTH - 1 : 0] i_addr_instr;
    reg ce, ce_d;
    reg stall_fetch;
    assign o_syn = ce;
    wire stall = stall_fetch || i_stall || (o_syn && !i_ack) || !o_syn;

    always @(posedge f_clk or negedge f_rst_n) begin
        if (!f_rst_n) begin
            ce <= 0;
        end
        else if ((change_pc || i_ack) && !(i_stall || stall_fetch)) begin
            ce <= 0;
        end
        else begin
            ce <= 1;
        end
    end

    always @(posedge f_clk or negedge f_rst_n) begin
        if (!f_rst_n) begin
            o_instr <= {I_WIDTH{1'b0}};
            pc <= {PC_WIDTH{1'b0}};
            i_addr_instr <= {A_WIDTH{1'b0}};
            o_addr_instr <= {A_WIDTH{1'b0}};
            prev_pc <= {PC_WIDTH{1'b0}};
            ce_d <= 1'b0;
        end
        else begin
            if ((ce && i_ack && !stall) || (stall && !o_ce && ce)) begin
                i_addr_instr <= prev_pc; 
                o_addr_instr <= i_addr_instr;
                o_instr <= i_instr;
            end
            if (stall) begin
                o_ce <= 0;
            end
            else begin
                o_ce <= ce_d;
            end
            if (i_ack) begin
                prev_pc <= pc;
                if (change_pc) begin
                    pc <= alu_pc_value; 
                end
                else begin
                    pc <= pc + 4;
                    ce_d <= ce;
                end
            end
        end
    end
endmodule
`endif 