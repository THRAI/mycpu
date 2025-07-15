`timescale 1ns / 1ps

`include "defines.vh"

module ALU (
    input  wire         cpu_clk,
    input  wire         cpu_rstn,
    input  wire [31:0]  A,
    input  wire [31:0]  B,
    input  wire [ 7:0]  alu_op,
    output reg  [31:0]  C,
    output reg          jump_flag

);


// PC alu
always @(*) begin
    case (alu_op)
        `ALU_JUMP:  jump_flag = 1;
        `ALU_BEQ :  begin
            if(!C)  jump_flag = 1;
            else    jump_flag = 0;
        end
        `ALU_BNE :  begin 
            if(C)   jump_flag = 1;
            else    jump_flag = 0;
        end
        `ALU_BLT :  begin 
            if($signed(A) < $signed(B))  jump_flag = 1;
            else    jump_flag = 0;
        end
        `ALU_BGE :  begin 
            if($signed(A) >= $signed(B)) jump_flag = 1;
            else    jump_flag = 0;
        end
        `ALU_BLTU:  begin 
            if($unsigned(A) < $unsigned(B))  jump_flag = 1;
            else    jump_flag = 0;
        end
        `ALU_BGEU:  begin 
            if($unsigned(A) >= $unsigned(B)) jump_flag = 1;
            else    jump_flag = 0;
        end
        default  :  jump_flag = 0;
    endcase
end



// mul alu
wire        is_mul;
wire        signed_mul;
reg         start_mul;
// wire        pause_ex_mul;
wire        mul_done;
// reg  [31:0] mul_data1_A;
// reg  [31:0] mul_data2_B;
wire  [63:0] mul_result;

// reg  [ 7:0] alu_op_latched; // 锁存alu_op，防止alu_op在mul_alu子模块计算期间改变

assign is_mul = (alu_op == `ALU_MULW || alu_op == `ALU_MULHW || alu_op == `ALU_MULHWU) && !mul_done;
// assign pause_ex_mul = is_mul && !mul_done;
assign signed_mul = (alu_op == `ALU_MULW || alu_op == `ALU_MULHW);

// 为mul_alu子模块赋值
always @(posedge cpu_clk or negedge cpu_rstn) begin
    // if(!cpu_rstn) begin
    //     alu_op_latched  <= 8'b0;
    //     mul_data1_A     <= 32'b0;
    //     mul_data2_B     <= 32'b0;
    // end
    // else begin
        
        if (start_mul) begin
            start_mul <= 1'b0;
        end
        else if (is_mul) begin
            start_mul <= 1'b1;
            // mul_data1_A <= A;
            // mul_data2_B <= B;
            // alu_op_latched <= alu_op;
        end
        // else if(mul_done) begin
        //     alu_op_latched <= 8'b0;
        // end
        else begin
            start_mul <= 1'b0;
        end
    // end
end

// 实例化mul_alu
mul_alu u_mul_alu (
    .cpu_clk    (cpu_clk),
    .cpu_rstn   (cpu_rstn),
    .start      (start_mul),
    .reg1       (A),
    .reg2       (B),
    .signed_op  (signed_mul),
    .done       (mul_done),
    .mul_result (mul_result)
);



// div alu
// reg [31:0] div_alu_res;
// wire pause_ex_div;
wire        is_div;
reg         start_div;
wire        signed_div;
wire        div_done;
wire        div_is_running;
wire [31:0] remainder;
wire [31:0] quotient;
reg  [31:0] div_data1;
reg  [31:0] div_data2;

// 组合逻辑赋值
assign is_div = (alu_op == `ALU_DIVW || alu_op == `ALU_MODW || alu_op == `ALU_DIVWU || alu_op == `ALU_MODWU) && !div_done;           
// assign pause_ex_div = is_div && !div_done;
assign signed_div = (alu_op == `ALU_DIVW || alu_op == `ALU_MODW);

// 时序逻辑 - 启动信号和数据处理
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn) begin
        start_div <= 1'b0;
    end else begin
        if (start_div) begin
            start_div <= 1'b0;
        end else if (is_div & !div_is_running) begin
            start_div <= 1'b1;
            div_data1 <= A;
            div_data2 <= B;
        end else begin
            start_div <= 1'b0;
        end 
    end
end

// 除法器实例化
div_alu u_div_alu (
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .signed_op      (signed_div),
    .dividend       (div_data1),
    .divisor        (div_data2),
    .start          (start_div),
    .div_is_running (div_is_running),
    .quotient_out   (quotient),
    .remainder_out  (remainder),
    .done           (div_done)
);




//接整体赋值的大块组合逻辑块
always @(*) begin
    // regular alu result
    case (alu_op)
        `ALU_ADD:   C = A + B;
        `ALU_SUB:   C = A - B;
        `ALU_AND:   C = A & B;
        `ALU_OR:    C = A | B;
        `ALU_XOR:   C = A ^ B;
        `ALU_NOR:   C = ~(A | B);
        `ALU_SLL:   C = A << B[4:0];
        `ALU_SRL:   C = A >> B[4:0];
        `ALU_SRA:   C = $signed(A) >>> B[4:0];
        `ALU_SLT:   C = $signed(A) < $signed(B);
        `ALU_SLTU:  C = $unsigned(A) < $unsigned(B);
        `ALU_JUMP:  C = A + 32'h4;
        `ALU_BEQ :  C = A - B;
        `ALU_BNE :  C = A - B;
        `ALU_BLT :  C = A - B;
        `ALU_BGE :  C = A - B;
        `ALU_BGEU:  C = A - B;
        default :   C = A + B;
    endcase

    // mul alu result
    if(mul_done) begin
        case (alu_op)
            `ALU_MULW:      C = mul_result[31: 0];
            `ALU_MULHW:     C = mul_result[63:32];
            `ALU_MULHWU:    C = mul_result[63:32];
        endcase
    end

    // div alu result
    if(div_done) begin
        case (alu_op)
            `ALU_DIVW, `ALU_DIVWU: C = quotient;
            `ALU_MODW, `ALU_MODWU: C = remainder;
        endcase
    end
end


endmodule
