`ifndef REGISTER
`define REGISTER
module register #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5
)(
    r_clk, r_rst, r_addr_rs1, r_addr_rs2, r_addr_rd, r_data_rd, r_data_out_rs1, r_data_out_rs2, r_we
);
    input r_clk, r_rst;
    input r_we;
    input [AWIDTH - 1 : 0] r_addr_rs1;
    input [AWIDTH - 1 : 0] r_addr_rs2;
    input [AWIDTH - 1 : 0] r_addr_rd;
    input [DWIDTH - 1 : 0] r_data_rd;
    output reg [DWIDTH - 1 : 0] r_data_out_rs1;
    output reg [DWIDTH - 1 : 0] r_data_out_rs2;

    
    localparam DEPTH = (1 << AWIDTH);
    reg [DWIDTH - 1 : 0] data [0 : DEPTH - 1];
    wire r_wb;

    //This signal is used to ensure that it obligatorily has enough two parts are we and address != 0 only then can the write occur
    assign r_wb = r_we && r_addr_rd != {AWIDTH{1'b0}};

    always @(posedge r_clk, negedge r_rst) begin
	 integer i;
        if (!r_rst) begin
            for (i = 0; i < (1 << AWIDTH); i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
            r_data_out_rs1 <= {DWIDTH{1'b0}};
            r_data_out_rs2 <= {DWIDTH{1'b0}};
        end
        else begin
            if (r_wb) begin
                data[r_addr_rd] <= r_data_rd;
                data[0] <= 32'b0;
            end
            r_data_out_rs1 <= (r_wb && (r_addr_rd == r_addr_rs1)) ? r_data_rd : data[r_addr_rs1];
            r_data_out_rs2 <= (r_wb && (r_addr_rd == r_addr_rs2)) ? r_data_rd : data[r_addr_rs2];
        end
    end
endmodule
`endif
