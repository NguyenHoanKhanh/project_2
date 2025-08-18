`ifndef STALL_V
`define STALL_V
module stall_pipeline (
    s_clk, s_rst, fetch_stall, decode_stall, ex_stall, mem_stall, wb_stall, out_stall,
    fetch_flush, decode_flush, ex_flush, mem_flush, wb_flush, out_flush
);
    input s_clk, s_rst;
    input fetch_stall, decode_stall, ex_stall, mem_stall, wb_stall;
    input fetch_flush, decode_flush, ex_flush, mem_flush, wb_flush;
    output reg out_stall;
    output reg out_flush;

    always @(posedge s_clk, negedge s_rst) begin
        if (!s_rst) begin
            out_stall <= 1'b0;
            out_flush <= 1'b0;
        end
        else begin
            if (fetch_stall || decode_stall || ex_stall || mem_stall || wb_stall) begin
                out_stall <= 1'b1;
                out_flush <= 1'b0;
            end
            else if (fetch_flush || decode_flush || ex_flush || mem_flush || wb_flush) begin
                out_stall <= 1'b0;
                out_flush <= 1'b1;
            end
            else begin
                out_stall <= 1'b0;
                out_flush <= 1'b0;
            end
        end
    end
endmodule
`endif 