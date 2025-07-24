`include "./source/register_file.v"

module tb;
    parameter AWIDTH = 32, DWIDTH = 32;
    reg r_clk, r_rst;
    reg r_we;
    reg [AWIDTH - 1 : 0] r_addr;
    reg [DWIDTH - 1 : 0] r_data_in;
    wire [DWIDTH - 1 : 0] r_data_out;
    integer i;
    register #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) r (
        .r_clk(r_clk),
        .r_rst(r_rst),
        .r_we(r_we),
        .r_addr(r_addr),
        .r_data_in(r_data_in),
        .r_data_out(r_data_out)
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
                r_addr = i;
                r_data_in = i;
                @(posedge r_clk);
                r_we = 1'b0;
            end
        end
    endtask

    task display (input integer counter);
        begin
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge r_clk);
                r_addr = i;
                @(posedge r_clk);
                $display($time, " ", "addr = %d, data = %d", r_addr, r_data_out);
                @(posedge r_clk);
            end
        end
    endtask

    initial begin
        reset(2);
        load(10);
        display(10);
        #200; $finish;
    end
endmodule