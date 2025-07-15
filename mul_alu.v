`timescale 1ns / 1ps

module mul_alu (
    input  wire         cpu_clk,    // 时钟信号
    input  wire         cpu_rstn,   // 异步复位信号
    input  wire         start,      // 乘法启动信号
    input  wire [31:0]  reg1,       // 32位输入操作数1
    input  wire [31:0]  reg2,       // 32位输入操作数2
    input  wire         signed_op,  // 有符号操作标志
    output wire         done,       // 乘法完成标志
    output wire [63:0]  mul_result  // 64位乘法结果
);

// 内部寄存器声明
reg signed [63:0] result; // 带符号64位乘法结果寄存器
reg valid;                    // 有效标志寄存器

// 带符号33位扩展后的操作数
wire signed [32:0] reg1_ext;  // reg1的符号扩展结果
wire signed [32:0] reg2_ext;  // reg2的符号扩展结果

// 符号扩展逻辑
assign reg1_ext = $signed({reg1[31] & signed_op, reg1});  // 根据signed_op扩展符号位
assign reg2_ext = $signed({reg2[31] & signed_op, reg2});  // 同上

// 乘法计算时序逻辑
always @(posedge cpu_clk) begin
    if (start) begin
        result <= reg1_ext * reg2_ext;  // 执行带符号乘法并存储结果
    end
end

// 有效标志生成逻辑
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn)
        valid <= 1'b0;         // 复位时清零
    else
        valid <= start ? 1'b1 : 1'b0;        // start有效时置位，否则清零
end

// 输出连接
assign done = valid;           // 完成标志直接输出valid
assign mul_result = result;    // 输出乘法结果

endmodule