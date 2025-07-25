`include "./source/data_memory.v"

module tb;
    parameter DWIDTH = 32;
    parameter AWIDTH = 32;
    reg dm_clk, dm_rst;
    reg dm_re, dm_we;
    reg [AWIDTH - 1 : 0] dm_addr;
    reg [DWIDTH - 1 : 0] dm_data_in;
    wire [DWIDTH - 1 : 0] dm_data_out;
    integer i;
    data_mem #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) dm (
        .dm_clk(dm_clk), 
        .dm_rst(dm_rst), 
        .dm_we(dm_we), 
        .dm_re(dm_re), 
        .dm_addr(dm_addr), 
        .dm_data_in(dm_data_in), 
        .dm_data_out(dm_data_out)
    );

    initial begin
        i = 0;
        dm_we = 1'b0;
        dm_re = 1'b0;
        dm_clk = 1'b0;
    end
    always #5 dm_clk = ~dm_clk;

    initial begin
        $dumpfile("./waveform/data_memory.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin 
            dm_rst = 1'b0;
            repeat(counter) @(posedge dm_clk);
            dm_rst = 1'b1;
        end
    endtask

    task load (input integer counter);
        begin
            @(posedge dm_clk);
            for (i = 0; i < counter; i = i + 1) begin
                dm_we = 1'b1;
                @(posedge dm_clk);
                dm_addr = i;
                dm_data_in = i;
                @(posedge dm_clk);
                dm_we = 1'b0;
                @(posedge dm_clk);
            end
        end
    endtask

    task display (input integer counter);
        begin
            @(posedge dm_clk);
                for (i = 0; i < counter; i = i + 1) begin
                    @(posedge dm_clk);
                    dm_re = 1'b1;
                    @(posedge dm_clk);
                    dm_addr = i;
                    @(posedge dm_clk);
                    $display($time, " ", "addr = %d, data = %d", dm_addr, dm_data_out);
                    @(posedge dm_clk);
                    dm_re = 1'b0;
                end
            end
    endtask

    initial begin
        reset(2);
        load(10);
        display(10);
        #200;
        $finish;
    end
endmodule