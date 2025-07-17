`timescale 1ns / 1ps

`include "defines.vh"
module clz (
    input wire [31:0] clz_input,
    output reg [4:0] clz_out
);
// // 查找表常量
// localparam [1:0] clz_low_table [0:7] = {
//     2'd3, 2'd2, 2'd1, 2'd1, 
//     2'd0, 2'd0, 2'd0, 2'd0
// };

reg [7:0] sub_clz;  // 索引0对应最高位组
reg [1:0] low_order_clz [0:7];  // 索引0对应最高位组
reg [1:0] upper_lower [0:3];

always @(*) begin
    // 4位组全零检测（高位在前）
    sub_clz[0] = (clz_input[31:28] == 4'b0);  // 最高位组
    sub_clz[1] = (clz_input[27:24] == 4'b0);
    sub_clz[2] = (clz_input[23:20] == 4'b0);
    sub_clz[3] = (clz_input[19:16] == 4'b0);
    sub_clz[4] = (clz_input[15:12] == 4'b0);
    sub_clz[5] = (clz_input[11:8] == 4'b0);
    sub_clz[6] = (clz_input[7:4] == 4'b0);
    sub_clz[7] = (clz_input[3:0] == 4'b0);  // 最低位组

    // // 动态计算low_order_clz（高位在前）
    // low_order_clz[0] = clz_low_table[clz_input[31:29]];  
    // low_order_clz[1] = clz_low_table[clz_input[27:25]];  
    // low_order_clz[2] = clz_low_table[clz_input[23:21]];  
    // low_order_clz[3] = clz_low_table[clz_input[19:17]];  
    // low_order_clz[4] = clz_low_table[clz_input[15:13]];  
    // low_order_clz[5] = clz_low_table[clz_input[11:9]];   
    // low_order_clz[6] = clz_low_table[clz_input[7:5]];    
    // low_order_clz[7] = clz_low_table[clz_input[3:1]]; 

    case(clz_input[31:29])
        3'd0: low_order_clz[0] = 2'd3;
        3'd1: low_order_clz[0] = 2'd2;
        3'd2: low_order_clz[0] = 2'd1;
        3'd3: low_order_clz[0] = 2'd1;
        3'd4: low_order_clz[0] = 2'd0;
        3'd5: low_order_clz[0] = 2'd0;
        3'd6: low_order_clz[0] = 2'd0;
        3'd7: low_order_clz[0] = 2'd0;
    endcase

    case(clz_input[27:25])
        3'd0: low_order_clz[1] = 2'd3;
        3'd1: low_order_clz[1] = 2'd2;
        3'd2: low_order_clz[1] = 2'd1;
        3'd3: low_order_clz[1] = 2'd1;
        3'd4: low_order_clz[1] = 2'd0;
        3'd5: low_order_clz[1] = 2'd0;
        3'd6: low_order_clz[1] = 2'd0;
        3'd7: low_order_clz[1] = 2'd0;
    endcase

    case(clz_input[23:21])
        3'd0: low_order_clz[2] = 2'd3;
        3'd1: low_order_clz[2] = 2'd2;
        3'd2: low_order_clz[2] = 2'd1;
        3'd3: low_order_clz[2] = 2'd1;
        3'd4: low_order_clz[2] = 2'd0;
        3'd5: low_order_clz[2] = 2'd0;
        3'd6: low_order_clz[2] = 2'd0;
        3'd7: low_order_clz[2] = 2'd0;
    endcase

    case(clz_input[19:17])
        3'd0: low_order_clz[3] = 2'd3;
        3'd1: low_order_clz[3] = 2'd2;
        3'd2: low_order_clz[3] = 2'd1;
        3'd3: low_order_clz[3] = 2'd1;
        3'd4: low_order_clz[3] = 2'd0;
        3'd5: low_order_clz[3] = 2'd0;
        3'd6: low_order_clz[3] = 2'd0;
        3'd7: low_order_clz[3] = 2'd0;
    endcase

    case(clz_input[15:13])
        3'd0: low_order_clz[4] = 2'd3;
        3'd1: low_order_clz[4] = 2'd2;
        3'd2: low_order_clz[4] = 2'd1;
        3'd3: low_order_clz[4] = 2'd1;
        3'd4: low_order_clz[4] = 2'd0;
        3'd5: low_order_clz[4] = 2'd0;
        3'd6: low_order_clz[4] = 2'd0;
        3'd7: low_order_clz[4] = 2'd0;
    endcase

    case(clz_input[11:9])
        3'd0: low_order_clz[5] = 2'd3;
        3'd1: low_order_clz[5] = 2'd2;
        3'd2: low_order_clz[5] = 2'd1;
        3'd3: low_order_clz[5] = 2'd1;
        3'd4: low_order_clz[5] = 2'd0;
        3'd5: low_order_clz[5] = 2'd0;
        3'd6: low_order_clz[5] = 2'd0;
        3'd7: low_order_clz[5] = 2'd0;
    endcase

    case(clz_input[7:5])
        3'd0: low_order_clz[6] = 2'd3;
        3'd1: low_order_clz[6] = 2'd2;
        3'd2: low_order_clz[6] = 2'd1;
        3'd3: low_order_clz[6] = 2'd1;
        3'd4: low_order_clz[6] = 2'd0;
        3'd5: low_order_clz[6] = 2'd0;
        3'd6: low_order_clz[6] = 2'd0;
        3'd7: low_order_clz[6] = 2'd0;
    endcase

    case(clz_input[3:1])
        3'd0: low_order_clz[7] = 2'd3;
        3'd1: low_order_clz[7] = 2'd2;
        3'd2: low_order_clz[7] = 2'd1;
        3'd3: low_order_clz[7] = 2'd1;
        3'd4: low_order_clz[7] = 2'd0;
        3'd5: low_order_clz[7] = 2'd0;
        3'd6: low_order_clz[7] = 2'd0;
        3'd7: low_order_clz[7] = 2'd0;
    endcase

    // 层级计算（保持原始索引）
    clz_out[4] = &sub_clz[3:0];  // 高16位全零
    clz_out[3] = clz_out[4] ? &sub_clz[5:4] : &sub_clz[1:0];  
    
    // 精确复制原始组合逻辑
    clz_out[2] = (sub_clz[0] & ~sub_clz[1]) |
                 (&sub_clz[2:0] & ~sub_clz[3]) |
                 (&sub_clz[4:0] & ~sub_clz[5]) |
                 (&sub_clz[6:0]);

    // upper_lower索引计算（保持原始索引顺序）
    upper_lower[0] = low_order_clz[{1'b0, sub_clz[0]}];  // 组0
    upper_lower[1] = low_order_clz[{1'b1, sub_clz[2]}];  // 组2
    upper_lower[2] = low_order_clz[{1'b0, sub_clz[4]}];  // 组4
    upper_lower[3] = low_order_clz[{1'b1, sub_clz[6]}];  // 组6

    // 最终位选择
    clz_out[1:0] = upper_lower[{clz_out[4], clz_out[3]}];
end
endmodule