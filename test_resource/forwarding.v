//Forwarding proceeds to get the standard data to return to the destination register,
// and if the data after calculation is finished (with with instructions that write to the destination 
// register), there will be stall, flush, invalid, so it will be retrieved one stage late to avoid that
`ifndef FORWARDING_V
`define FORWARDING_V
module forwarding #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 5
)(
    h_data_reg_rs1, h_data_reg_rs2, h_decoder_addr_rs1, h_decoder_addr_rs2,
    h_alu_force_stall_out, h_data_out_rs1, h_data_out_rs2, h_i_valid_alu, h_i_we_reg_alu,
    h_i_alu_addr_rd, h_i_alu_data_rd, h_i_memoryaccess_ce, h_i_we_reg_mem, h_i_addr_rd_mem, h_i_wb_ce,
    h_i_data_rd_wb
);
    input [DWIDTH - 1 : 0] h_data_reg_rs1, h_data_reg_rs2;   
    input [AWIDTH - 1 : 0] h_decoder_addr_rs1, h_decoder_addr_rs2;
    output reg h_alu_force_stall_out;
    output reg [DWIDTH - 1 : 0] h_data_out_rs1, h_data_out_rs2;
    //Memory Stage
    input h_i_valid_alu;
    input h_i_we_reg_alu;
    input [AWIDTH - 1 : 0] h_i_alu_addr_rd;
    input [DWIDTH - 1 : 0] h_i_alu_data_rd;
    input h_i_memoryaccess_ce;
    //Writeback Stage
    input [AWIDTH - 1 : 0] h_i_addr_rd_mem;
    input [DWIDTH - 1 : 0] h_i_data_rd_wb;
    input h_i_we_reg_mem;
    input h_i_wb_ce;

    always @(*) begin
        h_data_out_rs1 = h_data_reg_rs1;
        h_data_out_rs2 = h_data_reg_rs2;
        h_alu_force_stall_out = 0;
        
        //Check the current address of rs1 to match the address of the returned alu or the address of the memory load instruction to get value
        if ((h_decoder_addr_rs1 == h_i_alu_addr_rd) && h_i_we_reg_alu && h_i_memoryaccess_ce) begin
            if (!h_i_valid_alu) begin //If it is the value of alu returned then it must ben valid
                h_alu_force_stall_out = 1;
            end
            else begin
                h_data_out_rs1 = h_i_alu_data_rd;
            end
        end
        else if ((h_decoder_addr_rs1 == h_i_addr_rd_mem) && h_i_we_reg_mem && h_i_wb_ce) begin
            h_data_out_rs1 = h_i_data_rd_wb;
        end
        //Check the current address of rs2 to match the address of the returned alu or the address of the memory load instruction to get value
        if ((h_decoder_addr_rs2 == h_i_alu_addr_rd) && h_i_we_reg_alu && h_i_memoryaccess_ce) begin
            if (!h_i_valid_alu) begin //If it is the value of alu returned then it must ben valid
                h_alu_force_stall_out = 1;
            end
            else begin
                h_data_out_rs2 = h_i_alu_data_rd;
            end
        end
        else if ((h_decoder_addr_rs2 == h_i_addr_rd_mem) && h_i_we_reg_mem && h_i_wb_ce) begin
            h_data_out_rs2 = h_i_data_rd_wb;
        end

        if (h_decoder_addr_rs1 == {AWIDTH{1'b0}}) begin
            h_data_out_rs1 = {DWIDTH{1'b0}};
        end
        if (h_decoder_addr_rs2 == {AWIDTH{1'b0}}) begin
            h_data_out_rs2 = {DWIDTH{1'b0}};
        end
    end
endmodule
`endif 