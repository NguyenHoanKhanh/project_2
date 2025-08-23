`timescale 1ns/1ps
`include "./source/memory.v"

module tb_memory;
    parameter AWIDTH = 5;
    parameter DWIDTH = 32;

    // Clock and Reset
    reg m_clk, m_rst;

    // Stimulus signals
    reg                   m_i_cyc;
    reg                   m_i_stb;
    reg                   m_i_we;
    reg                   m_i_rd;
    reg [3:0]             m_i_byte_enable;
    reg [AWIDTH-1:0]      m_i_load_addr;
    reg [AWIDTH-1:0]      m_i_store_addr;
    reg [DWIDTH-1:0]      m_i_data_store;

    // Outputs
    wire [DWIDTH-1:0]     m_o_read_data;
    wire                  m_o_ack;

    // Instantiate memory
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) uut (
        .m_clk         (m_clk),
        .m_rst         (m_rst),
        .m_i_cyc       (m_i_cyc),
        .m_i_stb       (m_i_stb),
        .m_i_we        (m_i_we),
        .m_i_byte_enable (m_i_byte_enable),
        .m_i_load_addr (m_i_load_addr),
        .m_i_store_addr(m_i_store_addr),
        .m_i_data_store (m_i_data_store),
        .m_o_read_data (m_o_read_data),
        .m_o_ack       (m_o_ack),
        .m_i_rd(m_i_rd)
    );

    // Clock generator: 10 ns period
    initial begin
        m_clk = 0;
        forever #5 m_clk = ~m_clk;
    end

    initial begin
        $dumpfile("./waveform/memory.vcd");
        $dumpvars(0, tb_memory);
    end

    // Reset task
    task reset();
        begin
            m_rst         = 0;
            m_i_cyc       = 0;
            m_i_stb       = 0;
            m_i_we        = 0;
            m_i_rd        = 0;
            m_i_byte_enable = 4'b0;
            m_i_load_addr = 0;
            m_i_store_addr= 0;
            m_i_data_store      = 0;
            #20;
            m_rst = 1;
        end
    endtask

    initial begin
        // Initialize and reset
        reset();
        @(posedge m_clk);

        // Write transaction: write 0xDEADBEEF to address 5
        m_i_cyc        = 1;
        m_i_stb        = 1;
        m_i_we         = 1;
        m_i_byte_enable  = 4'b1111;        // full word byte-enable
        m_i_store_addr = 5;
        m_i_data_store       = 32'hDEADBEEF;
        @(posedge m_clk);
        // wait for ack
        wait (m_o_ack);
        $display("%0t WRITE ACK, addr=%0d data=0x%h", $time, m_i_store_addr, m_i_data_store);
        // deassert
        m_i_cyc = 0;
        m_i_stb = 0;
        m_i_we  = 0;
        @(posedge m_clk);

        // Read transaction: read from address 5
        m_i_cyc       = 1;
        m_i_stb       = 1;
        m_i_rd        = 1;
        m_i_load_addr = 5;
        @(posedge m_clk);
        wait (m_o_ack);
        $display("%0t READ  ACK, addr=%0d data=0x%h", $time, m_i_load_addr, m_o_read_data);
        // deassert
        m_i_cyc = 0;
        m_i_stb = 0;
        @(posedge m_clk);

        #20;
        $finish;
    end
endmodule
