module div_alu #(
    parameter DIV_WIDTH = 32
) (
    input  wire cpu_clk,
    input  wire cpu_rstn,
    input  wire signed_op,
    input  wire [DIV_WIDTH-1:0] dividend,             //被除数
    input  wire [DIV_WIDTH-1:0] divisor,              //除数
    input  wire start,
    output wire div_is_running,
    output reg  [DIV_WIDTH-1:0] remainder_out,   //余数
    output reg  [DIV_WIDTH-1:0] quotient_out,    //商
    output wire done
);

// ========== 参数与信号声明 ==========
localparam CLZ_W = 5;  // $clog2(DIV_WIDTH) for 32-bit
wire [CLZ_W-1:0] CLZ_delta;
wire divisor_greater_than_dividend;
reg  [DIV_WIDTH-1:0] shifted_divisor;
wire [1:0] new_quotient_bits;
wire [DIV_WIDTH-1:0] sub_1x;
wire [DIV_WIDTH-1:0] sub_2x;
wire sub_1x_overflow;
wire sub_2x_overflow;
wire sub2x_toss;  // 添加原始代码中缺失的声明

reg  [CLZ_W-2:0] cycles_remaining;
wire [CLZ_W-2:0] cycles_remaining_next;
reg  running;
wire terminate;
// wire signed_divop;
wire negate_dividend;
wire negate_divisor;
wire negate_quotient;
wire negate_remainder;
wire [31:0] unsigned_dividend;
wire [31:0] unsigned_divisor;
reg  [31:0] quotient;
reg  [31:0] remainder;
wire  [CLZ_W-1:0] dividend_CLZ;
wire  [CLZ_W-1:0] divisor_CLZ;

// ========== 符号处理逻辑 ==========

// assign signed_divop = signed_op;
assign negate_dividend  = signed_op & dividend[31];
assign negate_divisor   = signed_op & divisor[31];
assign negate_quotient  = signed_op & (dividend[31] ^ divisor[31]);
assign negate_remainder = signed_op & dividend[31];

// 补码转换
assign unsigned_dividend = negate_dividend ? (~dividend + 1) : dividend;
assign unsigned_divisor  = negate_divisor  ? (~divisor + 1)  : divisor;


// ========== CLZ模块实例化 ==========
clz dividend_clz_block (
    .clz_input(unsigned_dividend),
    .clz_out(dividend_CLZ)
);

clz divisor_clz_block (
    .clz_input(unsigned_divisor),
    .clz_out(divisor_CLZ)
);

// ========== 迭代控制逻辑 ==========
// always @(*) begin
//     // 修复原始代码中的比较逻辑
//     divisor_greater_than_dividend = (divisor_CLZ > dividend_CLZ);
//     CLZ_delta = divisor_CLZ - dividend_CLZ;
    // cycles_remaining_next = cycles_remaining - 1;
    // terminate = (cycles_remaining == 0);
// end
assign {divisor_greater_than_dividend, CLZ_delta} = divisor_CLZ - dividend_CLZ;

// 移位寄存器控制
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if(!cpu_rstn)   shifted_divisor <= 32'b0;
    else begin
        if (running) 
            shifted_divisor <= {2'b0, shifted_divisor[DIV_WIDTH-1:2]};
        else
            shifted_divisor <= unsigned_divisor << {CLZ_delta[CLZ_W-1:1], 1'b0};
    end
end

// ========== 核心运算逻辑 ==========

// wire [32:0] sub2x_result = {1'b0, remainder} - {shifted_divisor, 1'b0};
// wire [32:0] add_result = {sub2x_toss, sub_2x} + {1'b0, shifted_divisor};
// wire [32:0] sub_result = {sub2x_toss, sub_2x} - {1'b0, shifted_divisor};

// always @(*) begin
//     // 33位减法器 (1-bit carry + 32-bit result)
// //    wire [32:0] sub2x_result = {1'b0, remainder} - {shifted_divisor, 1'b0};
//     sub_2x_overflow = sub2x_result[32];
//     sub2x_toss = sub2x_result[31];  // 原始代码中的中间信号
//     sub_2x = sub2x_result[DIV_WIDTH-1:0];
    
//     // 1x减法器 - 与原始条件逻辑一致
//     if (sub_2x_overflow) begin
// //        wire [32:0] add_result = {sub2x_toss, sub_2x} + {1'b0, shifted_divisor};
//         sub_1x_overflow = add_result[32];
//         sub_1x = add_result[DIV_WIDTH-1:0];
//     end else begin
// //        wire [32:0] sub_result = {sub2x_toss, sub_2x} - {1'b0, shifted_divisor};
//         sub_1x_overflow = sub_result[32];
//         sub_1x = sub_result[DIV_WIDTH-1:0];
//     end
    
//     // 商位生成逻辑
//     new_quotient_bits[1] = ~sub_2x_overflow;
//     new_quotient_bits[0] = ~sub_1x_overflow;
// end

assign {sub_2x_overflow, sub2x_toss, sub_2x} = {1'b0, remainder} - {shifted_divisor, 1'b0};
assign {sub_1x_overflow, sub_1x} = sub_2x_overflow ? {sub2x_toss, sub_2x} + {1'b0, shifted_divisor} : {sub2x_toss, sub_2x} - {1'b0, shifted_divisor};

assign new_quotient_bits[1] = ~sub_2x_overflow;
assign new_quotient_bits[0] = ~sub_1x_overflow;

// 商寄存器
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if(!cpu_rstn)   quotient <= 32'b0;
    else begin
        if (start) 
            quotient <= 32'b0;
        else if (running) 
            quotient <= {quotient[DIV_WIDTH-3:0], new_quotient_bits};
    end
end

// 部分余数寄存器
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if(!cpu_rstn)   remainder <= 32'b0;
    else begin
        if (start | (running & |new_quotient_bits)) begin
            case ({~running, sub_1x_overflow})
                2'b00: remainder <= sub_1x;
                2'b01: remainder <= sub_2x;
                default: remainder <= unsigned_dividend;
            endcase
        end
    end
end

// ========== 状态控制逻辑 ==========
assign {terminate, cycles_remaining_next} = cycles_remaining - 1;

always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn) begin
        running <= 1'b0;
        cycles_remaining <= 4'b0;
    end else begin
        cycles_remaining <= running ? cycles_remaining_next : CLZ_delta[CLZ_W-1:1];
        // 修复启动条件逻辑
        running <= (running & ~terminate) | (start & ~divisor_greater_than_dividend);
    end
end

// always @(posedge cpu_clk or negedge cpu_rstn) begin
//     /* if(!cpu_rstn)   cycles_remaining <= 4'b0;
//     else  */          cycles_remaining <= running ? cycles_remaining_next : CLZ_delta[CLZ_W-1:1];
// end

// always @(posedge cpu_clk or negedge cpu_rstn) begin
//     if (!cpu_rstn)  running <= 1'b0;
//     else            running <= (running & ~terminate) | (start & ~divisor_greater_than_dividend);
// end

assign div_is_running = running;

// 输出结果处理
always @(*) begin
    if (dividend == 32'b0) begin
        quotient_out = 32'b0;
        remainder_out = 32'b0;
    end else begin
        quotient_out = negate_quotient ? (~quotient + 1'b1) : quotient;
        remainder_out = negate_remainder ? (~remainder + 1'b1) : remainder;
    end
end

// 完成信号生成
reg running_delay, terminate_delay, start_delay, divisor_greater_than_dividend_delay;
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if(!cpu_rstn) begin
        running_delay <= 1'b0;
        terminate_delay <= 1'b0;
        start_delay <= 1'b0;
        divisor_greater_than_dividend_delay <= 1'b0;
    end else begin
        running_delay <= running;
        terminate_delay <= terminate;
        start_delay <= start;
        divisor_greater_than_dividend_delay <= divisor_greater_than_dividend;
    end
end

assign done = (running_delay & terminate_delay) | (start_delay & divisor_greater_than_dividend_delay);

endmodule