`ifndef REGISTER_FILE
`define REGISTER_FILE

module register #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5,
    parameter DEPTH = (1 << AWIDTH)
)(
    r_clk, r_rst, r_addr_rs_1, r_addr_rs_2, r_addr_rd, r_data_rd, r_data_out_rs1, r_data_out_rs2, r_we, r_read_reg
);
    input r_clk, r_rst;
    input r_we, r_read_reg;
    input [AWIDTH - 1 : 0] r_addr_rs_1, r_addr_rs_2;
    input [AWIDTH - 1 : 0] r_addr_rd;
    input [DWIDTH - 1 : 0] r_data_rd;
    output reg [DWIDTH - 1 : 0] r_data_out_rs1, r_data_out_rs2;

    integer i;
    reg [DWIDTH - 1 : 0] data [DEPTH - 1 : 0];
    wire r_wb;

    assign r_wb = r_we && r_addr_rd != {AWIDTH{1'b0}};

    always @(posedge r_clk, negedge r_rst) begin
        if (!r_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
            r_data_out_rs1 <= {DWIDTH{1'b0}};
            r_data_out_rs2 <= {DWIDTH{1'b0}};
        end
        else begin
            if (r_wb) begin
                data[r_addr_rd] <= r_data_rd;
            end
            if (r_read_reg) begin
                r_data_out_rs1 <= data[r_addr_rs_1];
                r_data_out_rs2 <= data[r_addr_rs_2];
            end
        end
    end
endmodule
`endif 