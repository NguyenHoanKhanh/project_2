`ifndef TREAT_LOAD_STORE_DATA_V
`define TREAT_LOAD_STORE_DATA_V
`include "./source/header.vh"

module load_store #(
    parameter DWIDTH = 32,
    parameter FUNCT_WIDTH = 3
)(
    clk, rst_n, final_load, store_data_aligned, byte_enable, me_i_funct3, me_i_load_data, byte_off_q, byte_offset_d, me_i_rs2_data
);
    // Store needs to align input data (from register → memory) and create byte_enable.
    // Load needs to shift the output data (from memory → register) and extend correctly.
    input clk, rst_n;
    input [FUNCT_WIDTH - 1 : 0] me_i_funct3;
    input [DWIDTH - 1 : 0] me_i_load_data;
    input [1 : 0] byte_off_q;
    input [1 : 0] byte_offset_d;
    input [DWIDTH - 1 : 0] me_i_rs2_data;
    output reg [DWIDTH - 1 : 0] final_load;
    output reg [DWIDTH - 1 : 0] store_data_aligned;
    output reg [3 : 0] byte_enable;
    reg [DWIDTH - 1 : 0] store_data_aligned_d;
    reg byte_enable_d;
    wire [DWIDTH - 1 : 0] raw = me_i_load_data >> (byte_off_q * 8);
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            final_load <= {DWIDTH{1'b0}};
        end
        else begin
            case(me_i_funct3) 
                `FUNCT_LB : begin
                    final_load <= {{24{raw[7]}}, raw[7 : 0]};
                end
                `FUNCT_LBU : begin
                    final_load <= {24'b0, raw[7 : 0]};
                end
                `FUNCT_LH : begin
                    final_load <= {{16{raw[15]}}, raw[15 : 0]};
                end
                `FUNCT_LHU : begin
                    final_load <= {16'b0, raw[15 : 0]};
                end
                `FUNCT_LW : begin
                    final_load <= raw;
                end
                default : begin
                    final_load <= {DWIDTH{1'b0}};
                end
            endcase
        end
    end
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            byte_enable <= 4'd0;
            byte_enable_d <= 4'd0;
            store_data_aligned <= {DWIDTH{1'b0}};
            store_data_aligned_d <= {DWIDTH{1'b0}};
        end
        else begin
            case (me_i_funct3)
                `FUNCT_SB : begin
                    store_data_aligned <= {4{me_i_rs2_data[7 : 0]}} << (byte_offset_d * 8);
                    byte_enable <= 4'b0001 << byte_offset_d;
                end
                `FUNCT_SH : begin
                    case (byte_offset_d)
                        2'b00 : begin
                            store_data_aligned <= {2{me_i_rs2_data[15 : 0]}} << (0 * 8);
                            byte_enable <= 4'b0011;
                        end
                        2'b01 : begin
                            store_data_aligned <= {2{me_i_rs2_data[15 : 0]}} << (1 * 8);
                            byte_enable <= 4'b0110;
                        end
                        2'b10 : begin
                            store_data_aligned <= {2{me_i_rs2_data[15 : 0]}} << (2 * 8);
                            byte_enable <= 4'b1100;
                        end
                        2'b11 : begin
                            store_data_aligned <= {4{me_i_rs2_data[15 : 8]}} << (2 * 8);
                            byte_enable <= 4'b1000;
                            store_data_aligned_d <= {4{me_i_rs2_data[7 : 0]}} << (0 * 8);
                            byte_enable_d <= 4'b0001;
                        end
                    endcase
                end
                `FUNCT_SW : begin
                    store_data_aligned <= me_i_rs2_data;
                    byte_enable <= 4'b1111;
                end
                default : begin
                    store_data_aligned <= {DWIDTH{1'b0}};
                    byte_enable <= 4'b0000;
                end 
            endcase
        end
    end
endmodule           
`endif