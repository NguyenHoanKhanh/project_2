`ifndef MEMORY_V
`define MEMORY_V
module memory #(
    parameter AWIDTH = 5,
    parameter DWIDTH = 32,
    parameter DEPTH = 1 << AWIDTH
)(
    m_clk, m_rst, m_i_cyc, m_i_stb, m_i_we, m_i_rd, m_i_load_addr, m_i_store_addr, 
    m_i_data_store, m_o_read_data, m_o_ack, m_i_byte_enable, m_o_stall
);
    input m_clk, m_rst;
    input m_i_cyc;
    input m_i_stb;
    input m_i_we;
    input m_i_rd;
    input [3 : 0] m_i_byte_enable;
    input [AWIDTH - 1 : 0] m_i_load_addr;
    input [AWIDTH - 1 : 0] m_i_store_addr;
    input [DWIDTH - 1 : 0] m_i_data_store;
    output reg [DWIDTH - 1 : 0] m_o_read_data;
    output reg m_o_ack;
    output reg m_o_stall;

    reg req_active;
    reg [AWIDTH - 1 : 0] load_addr_reg;
    reg [AWIDTH - 1 : 0] store_addr_reg; 
    reg [DWIDTH - 1 : 0] data_reg;
    reg [DWIDTH - 1 : 0] mask_reg;
    reg we_reg, rd_reg;

    reg [DWIDTH - 1 : 0] data [DEPTH - 1 : 0];
    integer i;
    
    wire [DWIDTH - 1 : 0] mask = {
        {8{m_i_byte_enable[3]}},
        {8{m_i_byte_enable[2]}},
        {8{m_i_byte_enable[1]}},
        {8{m_i_byte_enable[0]}}
    };

    always @(posedge m_clk, negedge m_rst) begin
        if (!m_rst) begin
            m_o_ack <= 1'b0;
            m_o_stall <= 1'b0;
            req_active <= 1'b0;
            m_o_read_data <= {DWIDTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1) begin
                data[i] <= {DWIDTH{1'b0}};
            end
        end
        else begin
            m_o_ack <= 0;
            m_o_stall <= req_active;
// When there are storage requests, the full set of values will be prepared, such as the store
// value, store address when the value needs to be stored in memory, or the load address when 
// the value needs to be read from memory 
            if (!req_active) begin 
                if (m_i_cyc && m_i_stb) begin
                    load_addr_reg <= m_i_load_addr;
                    store_addr_reg <= m_i_store_addr;
                    data_reg <= m_i_data_store;
                    mask_reg <= mask;
                    we_reg <= m_i_we;
                    rd_reg <= m_i_rd;
                    req_active <= 1'b1;
                end
            end
// After preparation, the values will be retrieved from memory based on the read request or write 
// request signal
            else begin
                if (m_i_we) begin
                        data[store_addr_reg] <= (data[store_addr_reg] & ~mask) | (data_reg & mask);
                end
                if (m_i_rd) begin
                    m_o_read_data <= data[load_addr_reg];
                end
                m_o_ack <= 1'b1;
                req_active <= 1'b0;
            end
        end
    end
endmodule
`endif 