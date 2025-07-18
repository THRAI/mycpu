`timescale 1ns / 1ps

`include "defines.vh"

module EX_MEM (
    input  wire         cpu_clk,
    input  wire         cpu_rstn,
    input  wire         suspend,
    input  wire         valid_in,
    input  wire[31:0]   inst_in,
    input  wire[4:0]    wR_in,
    input  wire[31:0]   pc4_in,
    input  wire[31:0]   alu_C_in,
    input  wire[31:0]   rD2_in,
    input  wire[31:0]   ext_in,
    //input  wire[7:0]    alu_op_in,
    input  wire         rf_we_in,
    input  wire[1:0]    wd_sel_in,
    input  wire[3:0]    ram_we_in,
    input  wire[2:0]    ram_ext_op_in,

    input  wire         ll_in, 
    input  wire         sc_in,


    output reg          valid_out,
    output reg [31:0]   inst_out,
    output reg [4:0]    wR_out,
    output reg [31:0]   pc4_out,
    output reg [31:0]   alu_C_out,
    output reg [31:0]   rD2_out,
    output reg [31:0]   ext_out,
    //output reg [7:0]    alu_op_out,
    output reg          rf_we_out,
    output reg [1:0]    wd_sel_out,
    output reg [3:0]    ram_we_out,
    output reg [2:0]    ram_ext_op_out,

    output reg          ll_out, 
    output reg          sc_out
);

always @(posedge cpu_clk) begin
    valid_out      <= !cpu_rstn ?  1'h0 : suspend ? valid_out      :  valid_in;
    inst_out        <= !cpu_rstn ?  1'h0 : suspend ? inst_out       :  inst_in;
    wR_out         <= !cpu_rstn ?  5'h0 : suspend ? wR_out         :  wR_in;
    pc4_out        <= !cpu_rstn ? 32'h0 : suspend ? pc4_out        :  pc4_in;
    alu_C_out      <= !cpu_rstn ? 32'h0 : suspend ? alu_C_out      :  alu_C_in;
    rD2_out        <= !cpu_rstn ? 32'h0 : suspend ? rD2_out        :  rD2_in;
    ext_out        <= !cpu_rstn ? 32'h0 : suspend ? ext_out        :  ext_in;
    //alu_op_out     <= !cpu_rstn ? 8'd0  : suspend ? alu_op_out     :  alu_op_in;
    rf_we_out      <= !cpu_rstn ?  1'h0 : suspend ? rf_we_out      :  rf_we_in;
    wd_sel_out     <= !cpu_rstn ?  2'h0 : suspend ? wd_sel_out     :  wd_sel_in;
    ram_we_out     <= !cpu_rstn ?  4'h0 : suspend ? ram_we_out     :  ram_we_in;
    ram_ext_op_out <= !cpu_rstn ?  3'h0 : suspend ? ram_ext_op_out :  ram_ext_op_in;
    ll_out         <= !cpu_rstn ?  1'h0 : suspend ? ll_out         : ll_in;
    sc_out         <= !cpu_rstn ?  1'h0 : suspend ? sc_out         : sc_in;
end

endmodule
