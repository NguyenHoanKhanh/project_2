`ifndef REGISTER_FILE
`define REGISTER_FILE

module register #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5
)(
    r_clk, r_rst, r_addr_rs_1, r_addr_rs_2, r_addr_rd, r_data_rd, r_data_out_rs1, r_data_out_rs2, r_we
);
    input r_clk, r_rst;
    input r_we;
    input [AWIDTH - 1 : 0] r_addr_rs_1;
    input [AWIDTH - 1 : 0] r_addr_rs_2;
    input [AWIDTH - 1 : 0] r_addr_rd;
    input [DWIDTH - 1 : 0] r_data_rd;
    output reg [DWIDTH - 1 : 0] r_data_out_rs1;
    output reg [DWIDTH - 1 : 0] r_data_out_rs2;

    integer i;
    reg [DWIDTH - 1 : 0] data [0 : (1 << AWIDTH) - 1];
    wire r_wb;

    assign r_wb = r_we && r_addr_rd != {AWIDTH{1'b0}};

    always @(posedge r_clk, negedge r_rst) begin
        if (!r_rst) begin
            for (i = 0; i < (1 << AWIDTH); i = i + 1) begin
                data[i] <= i;
            end
            r_data_out_rs1 <= {DWIDTH{1'b0}};
            r_data_out_rs2 <= {DWIDTH{1'b0}};
        end
        else begin
            if (r_wb) begin
                data[r_addr_rd] <= r_data_rd;
            end
           
            r_data_out_rs1 <= (r_wb && (r_addr_rd == r_addr_rs_1)) ? r_data_rd : data[r_addr_rs_1];
            r_data_out_rs2 <= (r_wb && (r_addr_rd == r_addr_rs_2)) ? r_data_rd : data[r_addr_rs_2];
        end
    end
endmodule
`endif 