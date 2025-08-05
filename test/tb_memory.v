`include "./source/memory.v"
module tb;
    parameter AWIDTH = 5;
    parameter DWIDTH = 32;

    reg m_clk, m_rst;
    reg m_i_cyc, m_i_stb, m_i_we;
    reg [AWIDTH - 1 : 0] m_i_addr;
    reg [DWIDTH - 1 : 0] m_i_data;
    reg [3 : 0] m_i_sel;
    wire [DWIDTH - 1 : 0] m_o_read_data;
    wire m_o_ack, m_o_stall;

    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) m (
        .m_clk(m_clk), 
        .m_rst(m_rst), 
        .m_i_cyc(m_i_cyc), 
        .m_i_stb(m_i_stb), 
        .m_i_we(m_i_we), 
        .m_i_addr(m_i_addr), 
        .m_i_data(m_i_data), 
        .m_i_sel(m_i_sel), 
        .m_o_read_data(m_o_read_data), 
        .m_o_ack(m_o_ack), 
        .m_o_stall(m_o_stall)
    );

    initial begin
        m_clk = 0;
        m_i_stb = 0;
        m_i_cyc = 0;
        m_i_we = 0;
        m_i_addr = {AWIDTH{1'b0}};
        m_i_data = {DWIDTH{1'b0}};
        m_i_sel = 4'b0;
    end
    always #5 m_clk = ~m_clk;

    initial begin
        $dumpfile("./waveform/memory.vcd");
        $dumpvars(0, tb);
    end

    task reset();
        begin
            m_rst = 0;
            m_i_stb = 0;
            m_i_cyc = 0;
            m_i_we = 0;
            m_i_addr = {AWIDTH{1'b0}};
            m_i_data = {DWIDTH{1'b0}};
            m_i_sel = 4'b0;
            #10;
            m_rst = 1;
            #10;
        end
    endtask

    initial begin
        reset();
        @(posedge m_clk);
        m_i_stb = 1'b1;
        m_i_cyc = 1'b1;
        @(posedge m_clk);
        m_i_we = 1'b1;
        @(posedge m_clk);
        m_i_addr = 5;
        m_i_data = 10;
        @(posedge m_clk);
        m_i_we = 1'b0;
        @(posedge m_clk);
        $display($time, " ", "data = %h, ack = %b", m_o_read_data, m_o_ack);
        #100; $finish;
    end
endmodule