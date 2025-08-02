`include "./source/execute_stage.v"
module tb;
    parameter AWIDTH = 5;
    parameter DWIDTH = 32;
    parameter FUNCT_WIDTH = 3;
    parameter PC_WIDTH = 32;

    reg ex_clk, ex_rst;
    reg [`ALU_WIDTH - 1 : 0] ex_i_alu;
    reg [`OPCODE_WIDTH - 1 : 0] ex_i_opcode;
    wire [`ALU_WIDTH - 1 : 0] ex_o_alu;
    wire [`OPCODE_WIDTH - 1 : 0] ex_o_opcode;
    reg [AWIDTH - 1 : 0] ex_i_addr_rs1;
    reg [AWIDTH - 1 : 0] ex_i_addr_rs2;
    reg [AWIDTH - 1 : 0] ex_i_addr_rd;
    reg [DWIDTH - 1 : 0] ex_i_data_rs1;
    reg [DWIDTH - 1 : 0] ex_i_data_rs2;
    wire [DWIDTH - 1 : 0] ex_o_data_rd; 
    reg [FUNCT_WIDTH - 1 : 0] ex_i_funct3; 
    wire [FUNCT_WIDTH - 1 : 0] ex_o_funct3;
    reg [DWIDTH - 1 : 0] ex_i_imm; 
    wire [11 : 0] ex_o_imm;
    reg ex_i_ce;
    wire ex_o_ce;
    reg ex_i_stall;
    wire ex_o_stall; 
    reg ex_i_flush;
    wire ex_o_flush;
    reg [PC_WIDTH - 1 : 0] ex_i_pc;
    wire [PC_WIDTH - 1 : 0] ex_o_pc;
    wire [PC_WIDTH - 1 : 0] ex_next_pc;
    wire ex_o_change_pc;
    wire ex_o_we; 
    wire ex_o_valid;
    wire ex_stall_from_alu;

    execute #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .PC_WIDTH(PC_WIDTH),
        .FUNCT_WIDTH(FUNCT_WIDTH)
    ) e (
        .ex_clk(ex_clk), 
        .ex_rst(ex_rst), 
        .ex_i_alu(ex_i_alu), 
        .ex_i_opcode(ex_i_opcode), 
        .ex_o_alu(ex_o_alu), 
        .ex_o_opcode(ex_o_opcode),
        .ex_i_addr_rs1(ex_i_addr_rs1), 
        .ex_i_addr_rs2(ex_i_addr_rs2), 
        .ex_i_addr_rd(ex_i_addr_rd), 
        .ex_i_data_rs1(ex_i_data_rs1), 
        .ex_i_data_rs2(ex_i_data_rs2), 
        .ex_o_data_rd(ex_o_data_rd), 
        .ex_i_funct3(ex_i_funct3), 
        .ex_o_funct3(ex_o_funct3), 
        .ex_i_imm(ex_i_imm), 
        .ex_o_imm(ex_o_imm), 
        .ex_i_ce(ex_i_ce), 
        .ex_o_ce(ex_o_ce), 
        .ex_i_stall(ex_i_stall), 
        .ex_o_stall(ex_o_stall), 
        .ex_i_flush(ex_i_flush), 
        .ex_o_flush(ex_o_flush), 
        .ex_i_pc(ex_i_pc), 
        .ex_o_pc(ex_o_pc), 
        .ex_next_pc(ex_next_pc), 
        .ex_o_change_pc(ex_o_change_pc),
        .ex_o_we(ex_o_we), 
        .ex_o_valid(ex_o_valid), 
        .ex_stall_from_alu(ex_stall_from_alu)
    );

    initial begin
        $dumpfile("./waveform/execute_stage.vcd");
        $dumpvars(0, tb);
    end
    // Clock generation
    initial begin
        ex_clk = 0;
        forever #5 ex_clk = ~ex_clk;
    end

    task reset();
        begin
            ex_rst = 0;
            ex_i_ce = 0;
            ex_i_stall = 0;
            ex_i_flush = 0;
            #10;
            ex_rst = 1;
            #10;
        end
    endtask

    task test_instruction(
        input [`ALU_WIDTH-1:0] alu,
        input [`OPCODE_WIDTH-1:0] opcode,
        input [DWIDTH-1:0] rs1,
        input [DWIDTH-1:0] rs2,
        input [DWIDTH-1:0] imm,
        input [PC_WIDTH-1:0] pc
    );
        begin
            ex_i_alu = alu;
            ex_i_opcode = opcode;
            ex_i_data_rs1 = rs1;
            ex_i_data_rs2 = rs2;
            ex_i_imm = imm;
            ex_i_pc = pc;
            ex_i_ce = 1;
            ex_i_flush = 0;
            ex_i_stall = 0;
            #10;
            $display("Result: ex_o_data_rd = 0x%h", ex_o_data_rd);
            $display("NextPC: ex_next_pc = 0x%h", ex_next_pc);
            $display("ChangePC: %b, WE: %b, Valid: %b\n",
                     ex_o_change_pc, ex_o_we, ex_o_valid);
        end
    endtask

    initial begin
        reset();

        // ADD: 10 + 20
        test_instruction(`ADD, `RTYPE, 32'd10, 32'd20, 32'd0, 32'h1000);

        // SUB: 50 - 30
        test_instruction(`SUB, `RTYPE, 32'd50, 32'd30, 32'd0, 32'h1004);

        // SLL: 1 << 3 = 8
        test_instruction(`SLL, `RTYPE, 32'd1, 32'd3, 32'd0, 32'h1008);

        // SRA: signed(-16) >>> 2 = -4
        test_instruction(`SRA, `RTYPE, -32'd16, 32'd2, 32'd0, 32'h100C);

        // LUI: imm = 0xABCD000
        test_instruction(`ADD, `LUI, 32'd0, 32'd0, 32'hABCD1234, 32'h1010);

        // AUIPC: pc + imm
        test_instruction(`ADD, `AUIPC, 32'd0, 32'd0, 32'h100, 32'h2000);

        // JAL: pc + imm, rd = pc + 4
        test_instruction(`ADD, `JAL, 32'd0, 32'd0, 32'h10, 32'h3000);

        // BRANCH: (10 == 10) => jump
        test_instruction(`EQ, `BRANCH, 32'd10, 32'd10, 32'h4, 32'h4000);

        // Done
        #20;
        $finish;
    end

endmodule