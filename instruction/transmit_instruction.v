`ifndef TRANSMIT_INSTRUCTION_V
`define TRANSMIT_INSTRUCTION_V

module transmit #(
    parameter IWIDTH = 32,
    parameter DEPTH  = 36
)(
    input  t_clk,
    input  t_rst,
    input  t_i_syn,
    output reg [IWIDTH-1:0] t_o_instr,
    output reg t_o_ack
);

    integer counter;
    reg [IWIDTH-1:0] mem_instr [0:DEPTH-1];

    initial begin
        // nạp hex hoặc bin, kèm start-stop
        $readmemh("./instruction/instr.txt", mem_instr, 0, DEPTH-1);
        counter = 0;
    end

    always @(posedge t_clk or negedge t_rst) begin
        if (!t_rst) begin
            counter   <= 0;
            t_o_ack   <= 0;
            t_o_instr <= {IWIDTH{1'b0}};
        end
        else if (t_i_syn) begin
            t_o_instr <= mem_instr[counter];
            t_o_ack   <= 1;
            if (counter < DEPTH - 1)
                counter <= counter + 1;
            else
                counter <= 0;
        end
        else begin
            t_o_ack <= 0;
        end
    end
endmodule
`endif 