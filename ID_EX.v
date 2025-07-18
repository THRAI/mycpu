`timescale 1ns / 1ps

`include "defines.vh"

module ID_EX (
    input  wire         cpu_clk,
    input  wire         cpu_rstn,
    input  wire         suspend,
    input  wire         valid_in,
    input  wire[31:0]   inst_in,
    input  wire[4:0]    wR_in,
    input  wire[31:0]   pc_in,
    input  wire[31:0]   pc4_in,
    input  wire[31:0]   rD1_in,
    input  wire[31:0]   rD2_in,
    input  wire[31:0]   ext_in,

    input  wire [1:0]   npc_op_in,
    input  wire         rf_we_in,
    input  wire[1:0]    wd_sel_in,
    input  wire[7:0]    alu_op_in,
    input  wire         alua_sel_in,
    input  wire         alub_sel_in,
    input  wire[3:0]    ram_we_in,
    input  wire[2:0]    ram_ext_op_in,

    input  wire         jump_in,   //CU产生的jump跳转信号
    input  wire         jump_ex_in, //EX传回来的实际发生了分支跳转的信号
    input  wire         branch_in,   //CU产生的branch分支信号
    input  wire         call_in,
    input  wire         ret_in,
    input  wire         mulordiv_in,

    input  wire         ll_in, 
    input  wire         sc_in,



    output reg          valid_out,
    output reg [31:0]   inst_out,
    output reg [4:0]    wR_out,
    output reg [31:0]   pc_out,
    output reg [31:0]   pc4_out,
    output reg [31:0]   rD1_out,
    output reg [31:0]   rD2_out,
    output reg [31:0]   ext_out,

    output reg [1:0]    npc_op_out,
    output reg          rf_we_out,
    output reg [1:0]    wd_sel_out,
    output reg [7:0]    alu_op_out,
    output reg          alua_sel_out,
    output reg          alub_sel_out,
    output reg [3:0]    ram_we_out,
    output reg [2:0]    ram_ext_op_out,
    output reg          jump_out,
    output reg          branch_out,
    output reg          call_out,
    output reg          ret_out,
    output reg          mulordiv_out,

    output reg          ll_out, 
    output reg          sc_out
);

always @(posedge cpu_clk) begin
    valid_out       <= !cpu_rstn ?  1'h0 : suspend ? valid_out      : valid_in;
    inst_out        <= !cpu_rstn ?  1'b0 : suspend ? inst_out       : inst_in; 
    wR_out          <= !cpu_rstn ?  5'h0 : suspend ? wR_out         : wR_in;
    pc_out          <= !cpu_rstn ? 32'h0 : suspend ? pc_out         : pc_in;
    pc4_out         <= !cpu_rstn ? 32'h0 : suspend ? pc4_out        : pc4_in;
    rD1_out         <= !cpu_rstn ? 32'h0 : suspend ? rD1_out        : rD1_in;
    rD2_out         <= !cpu_rstn ? 32'h0 : suspend ? rD2_out        : rD2_in;
    ext_out         <= !cpu_rstn ? 32'h0 : suspend ? ext_out        : ext_in;
    npc_op_out      <= !cpu_rstn ?  2'h0 : suspend ? npc_op_out     : npc_op_in;
    rf_we_out       <= !cpu_rstn ?  1'h0 : suspend ? rf_we_out      : (rf_we_in & !jump_ex_in);
    wd_sel_out      <= !cpu_rstn ?  2'h0 : suspend ? wd_sel_out     : wd_sel_in;
    alu_op_out      <= !cpu_rstn ?  4'h0 : suspend ? alu_op_out     : alu_op_in;
    alua_sel_out    <= !cpu_rstn ?  1'h0 : suspend ? alua_sel_out   : alua_sel_in;
    alub_sel_out    <= !cpu_rstn ?  1'h0 : suspend ? alub_sel_out   : alub_sel_in;
    ram_we_out      <= !cpu_rstn ?  4'h0 : suspend ? ram_we_out     : ram_we_in;
    ram_ext_op_out  <= !cpu_rstn ?  3'h0 : suspend ? ram_ext_op_out : ram_ext_op_in;
    jump_out        <= !cpu_rstn ?  1'h0 : suspend ? jump_out       : jump_in;
    branch_out      <= !cpu_rstn ?  1'h0 : suspend ? branch_out     : branch_in;
    call_out        <= !cpu_rstn ?  1'h0 : suspend ? call_out       : call_in;
    ret_out         <= !cpu_rstn ?  1'h0 : suspend ? ret_out        : ret_in;
    mulordiv_out    <= !cpu_rstn ?  1'h0 : suspend ? mulordiv_out   : mulordiv_in;
    ll_out          <= !cpu_rstn ?  1'h0 : suspend ? ll_out         : ll_in;
    sc_out          <= !cpu_rstn ?  1'h0 : suspend ? sc_out         : sc_in;
end

endmodule
