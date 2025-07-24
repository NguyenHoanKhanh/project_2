`ifndef REGISTER_FILE
`define REGISTER_FILE

module register #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32
)(
    r_clk, r_rst, r_addr, r_data_in, r_data_out, r_we
);
    input r_clk, r_rst;
    input r_we;
    input [AWIDTH - 1 : 0] r_addr;
    input [DWIDTH - 1 : 0] r_data_in;
    output reg [DWIDTH - 1 : 0] r_data_out;

    integer i;
    reg [DWIDTH - 1 : 0] data [AWIDTH - 1 : 0];

    always @(posedge r_clk, negedge r_rst) begin
        if (!r_rst) begin
            for (i = 0; i < AWIDTH; i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
            r_data_out <= {DWIDTH{1'b0}};
        end
        else begin
            if (r_we) begin
                data[r_addr] <= r_data_in;
            end
            r_data_out <= data[r_addr];
        end
    end
endmodule
`endif 