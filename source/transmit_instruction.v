`ifndef TRANSMIT_INSTRUCTION_V
`define TRANSMIT_INSTRUCTION_V

module transmit #(
    parameter IWIDTH = 32,
    parameter DEPTH  = 36
)(
    t_clk, t_rst, t_i_syn, t_o_instr, t_o_ack
);
    input  t_clk;
    input  t_rst;
    input  t_i_syn;
    output reg [IWIDTH - 1 : 0] t_o_instr;
    output reg t_o_ack;

    integer counter;
    reg accept;
    reg [IWIDTH-1:0] mem_instr [0 : DEPTH - 1];

    initial begin
        // nạp hex hoặc bin, kèm start-stop
        $readmemh("./source/instr.txt", mem_instr, 0, DEPTH - 1);
        counter = 0;
    end

    always @(posedge t_clk or negedge t_rst) begin
        if (!t_rst) begin
            counter   <= 0;
            t_o_ack   <= 0;
            accept <= 1'b0;
            t_o_instr <= {IWIDTH{1'b0}};
        end
        else begin
            if (t_i_syn && !accept) begin
                t_o_instr <= mem_instr[counter];
                t_o_ack   <= 1;
                accept <= 1'b1;
                if (counter < DEPTH - 1) begin
                    counter <= counter + 1;
                end
                else begin
                    counter <= 0;
                end
            end
            else if (!t_i_syn) begin
                accept <= 1'b0;
                t_o_ack <= 1'b0;
            end
            else begin
                t_o_ack <= 1'b0;
            end
        end
    end
endmodule
`endif 