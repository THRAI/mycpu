`timescale 1ns / 1ps

`include "defines.vh"

module EXT (
    input  wire [25:0] din,//特别注意这个din是指令码的低26位 inst[25:0]
    input  wire [ 2:0] ext_op,
    output reg  [31:0] ext
);

//根据ext_op对应立即数扩展方式
always @(*) begin
    case (ext_op)
        `EXT_2RI5U: ext = {27'd0, din[14:10]};
        `EXT_2RI12: ext = {{20{din[21]}}, din[21:10]};//12位立即数有符号扩展
        `EXT_2RI12U:ext = {20'd0, din[21:10]};
        `EXT_1RI20: ext = {din[24:5], 12'h000};
        `EXT_2RI16: ext = {{14{din[25]}}, din[25:10], 2'b00};
        `EXT_I26:   ext = {{4{din[9]}}, din[9:0], din[25:10], 2'b00};
        `EXT_2RI14: ext = {{16{din[23]}}, din[23:10], 2'b00};
        default:    ext = {6'h0, din};
    endcase
end

endmodule
