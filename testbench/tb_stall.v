`include "./source/stall.v"
module tb;
    reg s_clk, s_rst;
    reg fetch_stall, decode_stall, ex_stall, mem_stall, wb_stall;
    wire out_stall;

    stall_pipeline sp (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .fetch_stall(fetch_stall),
        .decode_stall(decode_stall),
        .ex_stall(ex_stall),
        .mem_stall(mem_stall),
        .wb_stall(wb_stall),
        .out_stall(out_stall)
    );

    initial begin
        s_clk = 1'b0;
        fetch_stall = 1'b0;
        decode_stall = 1'b0; 
        ex_stall = 1'b0; 
        mem_stall = 1'b0; 
        wb_stall = 1'b0;
    end
    always #5 s_clk = ~s_clk;

    task reset (input integer counter);
        begin
            s_rst = 1'b0;
            repeat(counter) @(posedge s_clk);
            s_rst = 1'b1;
        end
    endtask

    initial begin
        $dumpfile("./waveform/stall.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        reset(2);
        @(posedge s_clk);
        fetch_stall = 1'b1;
        @(posedge s_clk);
        reset(1);
        fetch_stall = 1'b1; decode_stall = 1'b1;
        @(posedge s_clk);
        reset(1);
        fetch_stall = 1'b1; decode_stall = 1'b1; ex_stall = 1'b1;
        @(posedge s_clk);
        reset(1);
        fetch_stall = 1'b1; decode_stall = 1'b1; ex_stall = 1'b1; mem_stall = 1'b1;
        @(posedge s_clk);
        reset(1);
        fetch_stall = 1'b1; decode_stall = 1'b1; ex_stall = 1'b1; mem_stall = 1'b1; wb_stall = 1'b1;
        @(posedge s_clk);
        reset(1);
        #200; $finish;
    end
endmodule