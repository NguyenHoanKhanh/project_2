`include "./source/transmit_instruction.v"
module tb;
    parameter IWIDTH = 32;
    parameter DEPTH = 36;
    reg t_clk, t_rst;
    wire [IWIDTH - 1 : 0] t_o_instr;
    reg t_i_syn;
    wire t_o_ack;
    wire t_o_last;
    integer i;

    transmit #(
        .IWIDTH(IWIDTH),
        .DEPTH(DEPTH)
    ) t (
        .t_clk(t_clk),
        .t_rst(t_rst),
        .t_o_instr(t_o_instr),
        .t_i_syn(t_i_syn),
        .t_o_ack(t_o_ack),
        .t_o_last(t_o_last)
    );

    initial begin
        t_clk = 0;
        t_i_syn = 0;
        i = 0;
    end
    always #5 t_clk = ~t_clk;

    initial begin
        $dumpfile("./waveform/transmit.vcd");
        $dumpvars(0, tb);
    end

    task reset (input integer counter);
        begin
            t_rst = 1'b0;
            repeat(counter) @(posedge t_clk);
            t_rst = 1'b1;
        end
    endtask

    task display (input integer counter);
        begin
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge t_clk);
                t_i_syn = 1'b1;
                @(posedge t_clk);
                $display($time, " ", "instr = %h, ack = %b, last = %b, %d", t_o_instr, t_o_ack, t_o_last, i);
                t_i_syn = 1'b0;
                @(posedge t_clk);
            end
        end
    endtask

    initial begin
        reset(2);
        @(posedge t_clk);
        display(36);
        #200; $finish;
    end
endmodule