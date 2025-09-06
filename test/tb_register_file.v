`include "./source/register_file.v"

module tb;
    parameter AWIDTH = 5, DWIDTH = 32;
    reg r_clk, r_rst;
    reg [AWIDTH - 1 : 0] r_addr_rs1, r_addr_rs2, r_addr_rd;
    reg [DWIDTH - 1 : 0] r_data_rd; 
    wire [DWIDTH - 1 : 0] r_data_out_rs1, r_data_out_rs2;
    reg r_we;

    integer i;
    register #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) r (
        .r_clk(r_clk),
        .r_rst(r_rst),
        .r_we(r_we),
        .r_addr_rs1(r_addr_rs1),
        .r_addr_rs2(r_addr_rs2),
        .r_addr_rd(r_addr_rd),
        .r_data_rd(r_data_rd),
        .r_data_out_rs1(r_data_out_rs1),
        .r_data_out_rs2(r_data_out_rs2)
    );

    initial begin
        r_clk = 1'b0;
        i = 0;
        r_we = 1'b0;
    end 
    always #5 r_clk = ~r_clk;

    initial begin
        $dumpfile("./waveform/register_file.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            r_rst = 1'b0;
            repeat(counter) @(posedge r_clk);
            r_rst = 1'b1;
        end
    endtask

    task load (input integer counter);
        begin
            for (i = 0; i < counter; i = i + 1) begin
                r_we = 1'b1;
                @(posedge r_clk);
                r_addr_rd = i;
                r_data_rd = i;
                @(posedge r_clk);
                r_we = 1'b0;
            end
        end
    endtask

    task display (input integer counter);
        begin
            for (i = 0; i <= counter; i = i + 1) begin
                @(posedge r_clk);
                r_addr_rs1 = i;
                r_addr_rs2 = i;
                @(posedge r_clk);
                $display($time, " ", "addr 1 = %d, data 1 = %d", r_addr_rs1, r_data_out_rs1);
                $display($time, " ", "addr 2 = %d, data 2 = %d\n", r_addr_rs2, r_data_out_rs2);
                @(posedge r_clk);
            end
        end
    endtask

    initial begin
        reset(2);
        load(20);
        display(10);
        #20000; $finish;
    end
endmodule