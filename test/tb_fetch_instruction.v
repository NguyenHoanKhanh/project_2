`include "./source/fetch_instruction.v"
module tb_instruction_fetch;
    // Parameters
    parameter IWIDTH        = 32;
    parameter AWIDTH_INSTR  = 32;
    parameter PC_WIDTH      = 32;

    // Clock and reset
    reg                    f_clk;
    reg                    f_rst;

    // Instruction interface
    reg  [IWIDTH-1:0]      f_i_instr;
    wire [IWIDTH-1:0]      f_o_instr;
    wire [AWIDTH_INSTR-1:0] f_o_addr_instr;
    wire                   f_o_syn;
    reg                    f_i_ack;

    // Program counter interface
    reg                    f_change_pc;
    reg  [PC_WIDTH-1:0]    f_alu_pc_value;
    wire [PC_WIDTH-1:0]    f_pc;

    // Stall interface
    reg                    f_i_stall;
    wire                   f_o_stall;
    reg                    f_i_ce;
    wire                   f_o_ce;

    // Flush interface
    reg                    f_i_flush;
    wire                   f_o_flush;

    // Instantiate DUT
    instruction_fetch #(
        .IWIDTH(IWIDTH),
        .AWIDTH_INSTR(AWIDTH_INSTR),
        .PC_WIDTH(PC_WIDTH)
    ) dut (
        .f_clk         (f_clk),
        .f_rst         (f_rst),
        .f_i_instr     (f_i_instr),
        .f_o_instr     (f_o_instr),
        .f_o_addr_instr(f_o_addr_instr),
        .f_change_pc   (f_change_pc),
        .f_alu_pc_value(f_alu_pc_value),
        .f_pc          (f_pc),
        .f_o_syn       (f_o_syn),
        .f_i_ack       (f_i_ack),
        .f_i_stall     (f_i_stall),
        .f_o_stall     (f_o_stall),
        .f_i_ce        (f_i_ce),
        .f_o_ce        (f_o_ce),
        .f_i_flush     (f_i_flush),
        .f_o_flush     (f_o_flush)
    );

    // Clock generation: 10 ns period
    initial begin
        f_clk = 0;
        forever #5 f_clk = ~f_clk;
    end

    // Waveform dump
    initial begin
        $dumpfile("./waveform/fetch_intruction.vcd");
        $dumpvars(0, tb_instruction_fetch);
    end

    // Reset task
    task do_reset(input integer cycles);
        begin
            f_rst = 0;
            repeat(cycles) @(posedge f_clk);
            f_rst = 1;
            @(posedge f_clk);
        end
    endtask

    // Send instruction
    task send_instruction(input [IWIDTH-1:0] instr);
        begin
            f_i_instr   = instr;
            f_i_ack     = 1;
            f_i_stall   = 0;
            f_i_ce      = 1;
            f_change_pc = 0;
            f_i_flush   = 0;
            @(posedge f_clk);
            f_i_ack     = 0;
            @(posedge f_clk);
        end
    endtask

    // Stall task
    task introduce_stall(input integer cycles);
        begin
            f_i_stall = 1;
            repeat(cycles) @(posedge f_clk);
            f_i_stall = 0;
            @(posedge f_clk);
        end
    endtask

    // Jump task
    task do_jump(input [PC_WIDTH-1:0] pc);
        begin
            f_alu_pc_value = pc;
            f_change_pc    = 1;
            f_i_ack        = 1;
            f_i_stall      = 0;
            f_i_flush      = 0;
            f_i_ce         = 0;
            @(posedge f_clk);
            f_change_pc    = 0;
            f_i_ack        = 0;
            @(posedge f_clk);
        end
    endtask

    // Flush task
    task do_flush(input integer cycles);
        begin
            f_i_flush = 1;
            f_i_ack   = 0;
            f_i_stall = 0;
            f_i_ce    = 0;
            @(posedge f_clk);
            repeat(cycles-1) @(posedge f_clk);
            f_i_flush = 0;
            @(posedge f_clk);
        end
    endtask

    // Monitor signals
    initial begin
        $display("Time | rst | addr_req | instr_in | ack | stall_i | stall_o | syn | ce | flush_i | flush_o | pc | fetched");
        $monitor("%4t |  %b  |    %h    |   %h   |  %b |    %b    |    %b    |  %b  | %b  |    %b    |    %b    | %h | %h", 
                 $time, f_rst, f_o_addr_instr, f_i_instr, f_i_ack, f_i_stall, f_o_stall, f_o_syn, f_o_ce, f_i_flush, f_o_flush, f_pc, f_o_instr);
    end

    // Test sequence
    initial begin
        // Initialize
        f_i_instr       = 0;
        f_i_ack         = 0;
        f_i_stall       = 0;
        f_change_pc     = 0;
        f_alu_pc_value  = 0;
        f_i_flush       = 0;
        f_i_ce          = 0; 

        // Reset
        do_reset(2);

        // Fetch three instructions
        send_instruction(32'hA0A0A0A0);
        send_instruction(32'hB1B1B1B1);
        send_instruction(32'hC2C2C2C2);

        // Stall for 3 cycles
        introduce_stall(3);

        // Resume fetch
        send_instruction(32'hD3D3D3D3);

        // Jump to 0x100
        do_jump(32'h00000100);

        // Flush pipeline for 2 cycles
        do_flush(2);

        // Fetch after flush
        send_instruction(32'hE4E4E4E4);
        send_instruction(32'hF5F5F5F5);

        #20;
        $display("Test completed.");
        $finish;
    end
endmodule
