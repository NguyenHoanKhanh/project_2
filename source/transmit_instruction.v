`ifndef TRANSMIT_INSTRUCTION_V
`define TRANSMIT_INSTRUCTION_V

module transmit #(
    parameter IWIDTH = 32,
    parameter DEPTH  = 36,
    parameter DWIDTH = 32
)(
    t_clk, t_rst, t_i_syn, t_o_instr, t_o_ack, t_o_last
);
    input  t_clk;
    input  t_rst;
    input  t_i_syn;
    output reg [IWIDTH - 1 : 0] t_o_instr;
    output reg t_o_ack;
    output reg t_o_last;

    integer counter;
    reg [IWIDTH-1:0] mem_instr [0 : DEPTH - 1];

    always @(posedge t_clk or negedge t_rst) begin
        if (!t_rst) begin
            counter   <= {DWIDTH{1'b0}};
            t_o_ack   <= 1'b0;
            t_o_instr <= {IWIDTH{1'b0}};
            t_o_last <= 1'b0;
            // nạp hex hoặc bin, kèm start-stop
            $readmemh("./source/instr.txt", mem_instr, 0, DEPTH - 1);
        end
        else begin
            if (t_i_syn) begin
                t_o_instr <= mem_instr[counter];
                t_o_ack   <= 1'b1;
                t_o_last <= (counter == DEPTH - 1) ? 1 : 0;
                counter <= (counter < DEPTH - 1) ? counter + 1 : 0;
            end
            else begin
                t_o_ack <= 1'b0;
                t_o_last <= 1'b0;
            end
        end
    end
endmodule
`endif 