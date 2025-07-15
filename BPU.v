`timescale 1ns / 1ps

`define BHT_IDX_W 10                    // 表索引位宽
`define BHT_ENTRY (1 << `BHT_IDX_W)     // 表项个数
`define BHT_TAG_W 8                     // tag字段位宽
`define RAS_DEPTH 8                     // RAS栈深度
`define RAS_PTR_W 3                     // RAS指针位宽（log2(RAS_DEPTH)）

module BPU (
    input  wire         cpu_clk    ,
    input  wire         cpu_rstn   ,
    input  wire [31:0]  if_pc      ,    // IF阶段PC
    output wire [31:0]  pred_target,    // 预测目标地址
    output wire         pred_error ,    // 是否预测错误
    // 更新信号
    input  wire         ex_valid   ,    // EX阶段有效信号
    input  wire         ex_jump    ,
    input  wire         ex_branch  ,
    input  wire [31:0]  ex_pc      ,    // EX阶段PC
    input  wire         real_taken ,    // 真实跳转方向
    input  wire [31:0]  real_target,    // 真实目标地址

    input  wire         ex_is_call ,    // EX阶段是call指令
    input  wire         ex_is_ret  ,    // EX阶段是ret指令

    input  wire         suspend
);

wire [31:0] pc4 = if_pc + 32'h4;

wire ex_is_bj = ex_jump | ex_branch; // 判断是否是分支指令

// BHT/BTB表项
reg  [`BHT_TAG_W-1:0] tag     [`BHT_ENTRY-1:0];
reg  [`BHT_ENTRY-1:0] valid;
reg  [1:0]            history [`BHT_ENTRY-1:0];
reg  [31:0]           target  [`BHT_ENTRY-1:0];
reg  [`BHT_ENTRY-1:0] is_ret;  // 新增：标记ret指令

// RAS栈
reg [31:0]           ras_stack [0:`RAS_DEPTH-1];    // 返回地址栈
reg [`RAS_PTR_W-1:0] ras_ptr;                       // 栈指针

// 索引和标签生成
wire [`BHT_TAG_W-1:0] if_tag  = if_pc[31:32-`BHT_TAG_W];
wire [`BHT_TAG_W-1:0] ex_tag  = ex_pc[31:32-`BHT_TAG_W];
wire [          31:0] pc_hash = if_pc >> 2;            // 地址折叠todo
wire [`BHT_IDX_W-1:0] index   = pc_hash[`BHT_IDX_W-1:0]; 

// 预测逻辑
wire pred_taken = (valid[index] && (tag[index] == if_tag)) ? history[index][1] : 1'b0;
wire use_ras = valid[index] && (tag[index] == if_tag) && is_ret[index]; // 使用RAS预测
wire [31:0] ras_target = (ras_ptr != 0) ? ras_stack[ras_ptr - 1] : pc4; // RAS目标
assign pred_target = (pred_taken & use_ras) ? ras_target : (pred_taken ? target[index] : pc4);

// 流水线寄存器传递预测信息
reg  [`BHT_IDX_W-1:0] id_index,         ex_index;
reg                   id_pred_taken,    ex_pred_taken;
reg  [31:0]           id_pred_target,   ex_pred_target;
// reg                   id_use_ras,       ex_use_ras;      // 新增：传递RAS使用标志
// reg  [31:0]           id_ras_target,    ex_ras_target; // 新增：传递RAS目标

always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn) begin
        {id_index, ex_index} <= 0;
        {id_pred_taken, ex_pred_taken} <= 0;
        {id_pred_target, ex_pred_target} <= 0;
        // {id_use_ras, ex_use_ras} <= 0;
        // {id_ras_target, ex_ras_target} <= 0;
    end else begin
        if(suspend) begin
            id_index        <= id_index;
            id_pred_taken   <= id_pred_taken;
            id_pred_target  <= id_pred_target;

            ex_index        <= ex_index;
            ex_pred_taken   <= ex_pred_taken;
            ex_pred_target  <= ex_pred_target;
        end
        else begin
            id_index        <= index;
            id_pred_taken   <= pred_taken;
            id_pred_target  <= pred_target;
            // id_use_ras      <= use_ras;         // 传递RAS标志
            // id_ras_target   <= ras_target;      // 传递RAS目标地址
            ex_index        <= id_index;
            ex_pred_taken   <= id_pred_taken;
            ex_pred_target  <= id_pred_target;
            // ex_use_ras      <= id_use_ras;
            // ex_ras_target   <= id_ras_target;
        end
    end
end

// RAS管理逻辑
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn) begin
        ras_ptr <= 0;
        // for (integer i=0; i<`RAS_DEPTH; i=i+1) ras_stack[i] <= 0;
        ras_stack <= '{default: 32'h0};
    end else if (ex_valid) begin
        if (ex_is_call) begin  // 处理call：压入返回地址（LA32R: PC+4）
            if (ras_ptr < `RAS_DEPTH) begin
                ras_stack[ras_ptr] <= ex_pc + 32'h4;
                ras_ptr <= ras_ptr + 1;
            end
        end else if (ex_is_ret) begin  // 处理ret：弹出地址
            if (ras_ptr > 0) ras_ptr <= ras_ptr - 1;
        end
    end
end

// 错误检测
wire taken_error  = ( ex_valid & !ex_is_bj & ex_pred_taken )|(ex_valid & ex_is_bj & (ex_pred_taken != real_taken));        // 检测分支跳转方向是否预测错误todo
wire target_error = ex_valid & ex_is_bj & ex_pred_taken & real_taken & (ex_pred_target != real_target);                 // 检测目标地址是否预测错误todo
assign pred_error = (!cpu_rstn)?1'b0:ex_valid & (taken_error | target_error);

// BHT/BTB更新逻辑
wire add_entry     = ex_valid & ex_is_bj & real_taken & !valid[ex_index];     // 判断何种情形需要在BHT和BTB中新增表项todo
wire update_entry  = ex_valid & ex_is_bj & valid[ex_index] & (tag[ex_index] == ex_tag);     // 判断何种情形需要更新BHT和BTB的现有表项todo
wire replace_entry = ex_valid & ex_is_bj & real_taken & valid[ex_index] & (tag[ex_index] != ex_tag);     // 判断何种情形需要替换BHT和BTB的现有表项todo

integer i;
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn) begin
        valid  <= {`BHT_ENTRY{1'b0}};
        is_ret <= {`BHT_ENTRY{1'b0}};
        for (i=0; i<`BHT_ENTRY; i=i+1) begin
            history[i] <= 2'b10;
            // is_ret[i] <= 0;  // 初始化is_ret
        end
    end else begin
        if (add_entry) begin
            valid[ex_index] <= 1'b1;
            tag[ex_index]   <= ex_tag;
            target[ex_index]<= real_target;
            history[ex_index] <= 2'b10;
            is_ret[ex_index] <= ex_is_ret; // 标记ret指令
        end else if (update_entry) begin
            if (real_taken) target[ex_index] <= real_target;
            case (history[ex_index])
                2'b00: history[ex_index] <= real_taken ? 2'b01 : 2'b00;
                2'b01: history[ex_index] <= real_taken ? 2'b11 : 2'b00;
                2'b10: history[ex_index] <= real_taken ? 2'b11 : 2'b00;
                2'b11: history[ex_index] <= real_taken ? 2'b11 : 2'b10;
            endcase
            if (ex_is_ret) is_ret[ex_index] <= 1'b1; // 更新为ret
        end else if (replace_entry) begin
//            valid[ex_index] <= 1'b1;
            tag[ex_index]   <= ex_tag;
            target[ex_index]<= real_target;
            history[ex_index] <= 2'b10;
            is_ret[ex_index] <= ex_is_ret; // 标记ret指令
        end
    end
end

endmodule