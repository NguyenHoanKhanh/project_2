`ifndef DATA_MEMORY_V
`define DATA_MEMORY_V

module data_mem #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5, 
    parameter DEPTH = 1 << AWIDTH
) (
    dm_clk, dm_rst, dm_we, dm_re, dm_addr, dm_data_in, dm_data_out
);
    input dm_clk, dm_rst;
    input dm_we, dm_re;
    input [AWIDTH - 1 : 0] dm_addr;
    input [DWIDTH - 1 : 0] dm_data_in;
    output reg [DWIDTH - 1 : 0] dm_data_out;

    reg [DWIDTH - 1 : 0] data [AWIDTH - 1 : 0];
    integer i;

    always @(posedge dm_clk, dm_rst) begin
        if (!dm_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
            dm_data_out <= {DWIDTH{1'b0}};
        end
        else begin
            if (dm_we) begin
                data[dm_addr] <= dm_data_in;
            end
            else if (dm_re) begin
                dm_data_out <= data[dm_addr];
            end
        end
    end
endmodule
`endif 