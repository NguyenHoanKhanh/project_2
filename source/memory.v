`ifndef MEMORY_V
`define MEMORY_V
module memory #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter DEPTH = 1 << AWIDTH
)(
    m_clk, m_rst, m_i_cyc, m_i_stb, m_i_we, m_i_load_addr, m_i_store_addr, m_i_data, m_o_read_data, m_o_ack, m_i_be_enable
);
    input m_clk, m_rst;
    input m_i_cyc;
    input m_i_stb;
    input m_i_we;
    input [3 : 0] m_i_be_enable;
    input [AWIDTH - 1 : 0] m_i_load_addr;
    input [AWIDTH - 1 : 0] m_i_store_addr;
    input [DWIDTH - 1 : 0] m_i_data;
    output reg [DWIDTH - 1 : 0] m_o_read_data;
    output reg m_o_ack;

    reg [DWIDTH - 1 : 0] data [DEPTH - 1 : 0];
    integer i;

    wire [DWIDTH - 1 : 0] mask = {
        {8{m_i_be_enable[3]}},
        {8{m_i_be_enable[2]}},
        {8{m_i_be_enable[1]}},
        {8{m_i_be_enable[0]}}
    };

    always @(posedge m_clk, negedge m_rst) begin
        if (!m_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
            m_o_ack <= 0;
            m_o_read_data <= {DWIDTH{1'b0}};
        end
        else begin
            m_o_ack <= 0;
            if (m_i_cyc && m_i_stb) begin
                if (m_i_we) begin
                    data[m_i_store_addr] <= (data[m_i_store_addr] & ~mask) | (m_i_data & mask);
                end
                else begin
                    m_o_read_data <= data[m_i_load_addr];
                end
                m_o_ack <= 1'b1;
            end
        end
    end
endmodule
`endif 