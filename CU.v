`timescale 1ns / 1ps
`include "defines.vh"

//parameter EXCP_TYPE = 5;

module CU (
    input  wire [16:0]              din,            // 指令码inst的高17位
    output reg  [ 1:0]              npc_op,         // 控制下一条指令的PC值
    output reg  [ 2:0]              ext_op,         // 控制立即数扩展方式
    output reg  [ 2:0]              ram_ext_op,     // 控制读主存数据的扩展方式（针对load指令）
    output reg  [ 7:0]              alu_op,         // 控制运算类型
    output reg                      rf_we,          // 控制是否写回寄存器堆
    output reg  [ 3:0]              ram_we,         // 写主存的写使能信号（针对store指令）
    output reg                      r2_sel,         // 控制源寄存器2的选择
    output reg                      wr_sel,         // 控制目的寄存器的选择
    output reg  [ 1:0]              wd_sel,         // 控制写回数据来自ALU计算结果还是读主存结果
    output reg                      rR1_re,         // 指令是否读取rR1，用于检测数据冒险
    output reg                      rR2_re,         // 指令是否读取rR2，用于检测数据冒险
    output reg                      alua_sel,       // 选择ALU操作数A的来源
    output reg                      alub_sel,       // 选择ALU操作数B的来源
    output reg                      is_jump,        // 无条件跳转标志
    output reg                      is_branch,      // 分支信号
    output reg                      is_call,        // call(bl)指令标志
    output reg                      is_ret,         // ret(jirl)指令标志
    output reg                      is_mulordiv,    // mul或div或mod类指令标志
    output reg                      is_ll,          // ll.w指令标志
    output reg                      is_sc,          // sc.w指令标志
    output reg                      excp_occur,     // 例外发生标志
    output reg  [/*(EXCP_TYPE - 1)*/4:0] excp_type  // 例外类型 (00:无, 01:syscall, 10:break)
);

//------------------------------------------
//------------------------------------------
//------------------------------------------
// 指令识别与控制信号生成（使用casex)
//------------------------------------------
always @(*) begin
    casex (din)
        //------------------ 算术/逻辑指令 ------------------//
        // ADD.W (din[31:15]=17'h00020)
        17'b00000000000100000: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SUB.W (din[31:15]=17'h00022)
        17'b00000000000100010: begin
            alu_op      = `ALU_SUB;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SLT (din[31:15]=17'h00024)
        17'b00000000000100100: begin
            alu_op      = `ALU_SLT;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SLTU (din[31:15]=17'h00025)
        17'b00000000000100101: begin
            alu_op      = `ALU_SLTU;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // AND (din[31:15]=17'h00029)
        17'b00000000000101001: begin
            alu_op      = `ALU_AND;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // OR (din[31:15]=17'h0002A)
        17'b00000000000101010: begin
            alu_op      = `ALU_OR;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // XOR (din[31:15]=17'h0002B)
        17'b00000000000101011: begin
            alu_op      = `ALU_XOR;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // NOR (din[31:15]=17'h00028)
        17'b00000000000101000: begin
            alu_op      = `ALU_NOR;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SLL.W (din[31:15]=17'h0002E)
        17'b00000000000101110: begin
            alu_op      = `ALU_SLL;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SRL.W (din[31:15]=17'h0002F)
        17'b00000000000101111: begin
            alu_op      = `ALU_SRL;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // SRA.W (din[31:15]=17'h00030)
        17'b00000000000110000: begin
            alu_op      = `ALU_SRA;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // 乘除法指令
        // MUL.W (din[31:15]=17'b00000000000111000)
        17'b00000000000111000:begin
            alu_op      = `ALU_MULW;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // MULH.W (din[31:15]=17'b00000000000111001)
        17'b00000000000111001:begin
            alu_op      = `ALU_MULHW;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // MULH.WU (din[31:15]=17'b00000000000111010)
        17'b00000000000111010:begin
            alu_op      = `ALU_MULHWU;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // DIV.W (din[31:15]=17'b00000000001000000)
        17'b00000000001000000:begin
            alu_op      = `ALU_DIVW;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // DIV.WU (din[31:15]=17'b00000000001000010)
        17'b00000000001000010:begin
            alu_op      = `ALU_DIVWU;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // MOD.W (din[31:15]=17'b00000000001000001)
        17'b00000000001000001:begin
            alu_op      = `ALU_MODW;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // MOD.WU (din[31:15]=17'b00000000001000011)
        17'b00000000001000011:begin
            alu_op      = `ALU_MODWU;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b1;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end


        //------------------ 立即数指令------------------//
        // LU12I.W (din[31:25]=7'h0A --> din[16:10]=7'h0A)                                                                                                                       
        17'b0001010xxxxxxxxxx: begin
            ext_op      = `EXT_1RI20;       
            alu_op      = `ALU_ADD;
            rR1_re      = 1'b0;         //myCPU.v中会因为不选r1寄存器而把它的编号变成0号寄存器(x0天然为0)
            alub_sel    = `ALUB_EXT;    // ALU操作数B为立即数
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1  
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR2_re      = 1'b0;
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // ADDI.W (din[31:22]=10'h00A --> din[16:7]=10'h00A)
        17'b0000001010xxxxxxx: begin
            ext_op      = `EXT_2RI12;       // 符号扩展
            alu_op      = `ALU_ADD;
            alub_sel    = `ALUB_EXT;           
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // andi.w (din[31:15]=17'b0000001101xxxxxxx)
        17'b0000001101xxxxxxx: begin
            alu_op      = `ALU_AND;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // ori.w (din[31:15]=17'b0000001110xxxxxxx)
        17'b0000001110xxxxxxx: begin
            alu_op      = `ALU_OR;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1            
            ext_op      = `EXT_2RI12U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // xori.w (din[31:15]=17'b0000001111xxxxxxx)
        17'b0000001111xxxxxxx: begin
            alu_op      = `ALU_XOR;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // slti.w (din[31:15]=17'b0000001000xxxxxxx)
        17'b0000001000xxxxxxx: begin
            alu_op      = `ALU_SLT;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // sltui.w (din[31:15]=17'b0000001001xxxxxxx)
        17'b0000001001xxxxxxx: begin
            alu_op      = `ALU_SLTU;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1   
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // slli.w (din[31:15]=17'b00000000010000001)
        17'b00000000010000001: begin
            alu_op      = `ALU_SLL;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI5U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end
        
        // srli.w (din[31:15]=17'b00000000010000001)
        17'b00000000010001001: begin
            alu_op      = `ALU_SRL;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI5U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // srai.w (din[31:15]=17'b00000000010000001)
        17'b00000000010010001: begin
            alu_op      = `ALU_SRA;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI5U;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end
        
        // pcaddu12i (din[31:15]=17'b0001110xxxxxxxxxx)
        17'b0001110xxxxxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_PC;    // 默认选择rR1
            ext_op      = `EXT_1RI20;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b0;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end


        //        //------------------ 分支跳转指令 ------------------//

       // BL (din[31:26]=6'h15 --> din[16:11]=6'h15)
        17'b010101xxxxxxxxxxx: begin
            is_jump     = 1'b1;
            is_branch   = 1'b0;
            npc_op      = `NPC_BL;
            ext_op      = `EXT_I26;
            alu_op      = `ALU_JUMP;      // ALU计算目标地址：PC + offset
            rf_we       = 1'b1;
            wr_sel      = `WR_Rr1;       // 目的寄存选择r1
            alua_sel    = `ALUA_PC;
            r2_sel      = `R2_RK;      // 默认选择rk
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b0;
            rR2_re      = 1'b0;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b1;       // BL实际是call指令
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end  

        // jirl (din[31:26]=6'b010011)
        17'b010011xxxxxxxxxxx: begin
            is_jump     = 1'b1;
            is_branch   = 1'b0;
            npc_op      = `NPC_JIRL;    // 设置跳转类型为JIRL
            ext_op      = `EXT_2RI16;      
            alu_op      = `ALU_JUMP;      // ALU计算目标地址：rj + offset
            rf_we       = 1'b1;          // 写回rd寄存器
            wd_sel      = `WD_ALU;       // 写回数据为PC+4（需通过ALU）
            alua_sel    = `ALUA_PC;      // ALU操作数A为rj?? ??
            rR1_re      = 1'b1;          //  ??要读取rj寄存 ??
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            rR2_re      = 1'b0;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b1;       // JIRL实际是ret指令
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // BEQ (din[31:26]=6'h16 --> din[16:11]=6'h16)
        17'b010110xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BEQ;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // BLT(din[31:26]=6'b011000)
        17'b011000xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BLT;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end


        // BNE (din[31:26]=6'b010111)
        17'b010111xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BNE;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // BLTU (din[31:26]=6'b011010)
        17'b011010xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BLTU;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
       end

        // BGE (din[31:26]=6'b011001)
        17'b011001xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BGE;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // BGEU (din[31:26]=6'b011011)
        17'b011011xxxxxxxxxxx: begin
            is_jump     = 1'b0;
            is_branch   = 1'b1;
            npc_op      = `NPC_BX;
            rR1_re      = 1'b1;
            rR2_re      = 1'b1;     //读取r2
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_BGEU;
            rf_we       = 1'b0;     //rf_we = 0
            r2_sel      = `R2_RD;    //r2为rd寄存器
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // B (din[31:26]=6'b010100)
        17'b010100xxxxxxxxxxx: begin
            is_jump     = 1'b1;
            is_branch   = 1'b0;
            npc_op      = `NPC_BL;          // BL和B指令
            ext_op      = `EXT_2RI16;
            alu_op      = `ALU_JUMP;      // ALU计算目标地址：PC + offset
            rf_we       = 1'b0;
            wr_sel      = `WR_Rr1;       // 目的寄存选择r1
            alua_sel    = `ALUA_PC;
            r2_sel      = `R2_RK;      // 默认选择rk
            ram_ext_op  = `RAM_EXT_N;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b0;
            rR2_re      = 1'b0;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end


        //------------------ 访存指令 ------------------//
        // LD.W (din[31:22]=10'h0A2 --> din[16:7]=10'h0A2)
        17'b0010100010xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk, L型用不上rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_W;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // ST.W (din[31:22]=10'h0A6 --> din[16:7]=10'h0A6)
        17'b0010100110xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RD;      // 选择rd
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b0;
            ram_we      = `RAM_WE_W;  //内存写使能
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; 
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // LD.H 
        17'b0010100001xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_H;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // ST.H
        17'b0010100101xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RD;      // 选择rd
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b0;
            ram_we      = `RAM_WE_H;  //内存写使能
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; 
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end
        
        // LD.HU 
        17'b0010101001xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_HU;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // LD.B
        17'b0010100000xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_B;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT; // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // LD.BU
        17'b0010101000xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b0;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_BU;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT;    // ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end

        // ST.B 
        17'b0010100100xxxxxxx: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RD;      // 选择rd, 这是要往DCache里写回的数据，所以选择rd，不选rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_2RI12;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b0;
            ram_we      = `RAM_WE_B;  //
            wd_sel      = `WD_RAM;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_EXT;   //ALU操作数B选择立即数
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end


//         // 原子访存指令(ll.w, sc.w)
//         // ll.w (din[31:24] = 8'b00100000)
//         17'b00100000xxxxxxxxx: begin
//             alu_op      = `ALU_ADD;
//             rR2_re      = 1'b0;
//             npc_op      = `NPC_PC4;
//             r2_sel      = `R2_RK;
//             wr_sel      = `WR_RD;
//             alua_sel    = `ALUA_R1;
//             ext_op      = `EXT_2RI14;
//             ram_ext_op  = `RAM_EXT_LL;  // ll.w 原子访存指令
//             rf_we       = 1'b1;
//             ram_we      = `RAM_WE_N;
//             wd_sel      = `WD_RAM;
//             rR1_re      = 1'b1;
//             alub_sel    = `ALUB_EXT;
//             is_jump     = 1'b0;
//             is_branch   = 1'b0;
//             is_call     = 1'b0;
//             is_ret      = 1'b0;
//             is_mulordiv = 1'b0;
//             is_ll       = 1'b1;        // 标记为 ll.w
//             is_sc       = 1'b0;
//             excp_occur  = 1'b0;
//             excp_type   = `EXCP_NONE;
//         end

//         // sc.w (din[31:24] = 8'b00100001)
//         17'b00100001xxxxxxxxx: begin
//             alu_op      = `ALU_ADD;
//             rR2_re      = 1'b1;
//             npc_op      = `NPC_PC4;
//             r2_sel      = `R2_RD;      // 选择rd作为源寄存器2
//             wr_sel      = `WR_RD;
//             alua_sel    = `ALUA_R1;
//             ext_op      = `EXT_2RI14;
//             ram_ext_op  = `RAM_EXT_N;
//             rf_we       = 1'b0;
//             ram_we      = `RAM_WE_W;   // 内存写使能
// //            wd_sel      = `WD_SC;      // 特殊写回选择
//             rR1_re      = 1'b1;
//             alub_sel    = `ALUB_EXT;
//             is_jump     = 1'b0;
//             is_branch   = 1'b0;
//             is_call     = 1'b0;
//             is_ret      = 1'b0;
//             is_mulordiv = 1'b0;
//             is_ll       = 1'b0;
//             is_sc       = 1'b1;        // 标记为 sc.w
//             excp_occur  = 1'b0;
//             excp_type   = `EXCP_NONE;
//         end

      

//        //------------------ 例外指令 ------------------//
//        // SYSCALL (din[31:15]=17'h00056)
//        17'b00000000001010110: begin
//             alu_op      = `ALU_ADD;
//             rR2_re      = 1'b0;
//             npc_op      = `NPC_PC4;    // 默认顺序执行
//             r2_sel      = `R2_RK;      // 默认选择rk
//             wr_sel      = `WR_RD;      // 默认写rd
//             alua_sel    = `ALUA_R1;    // 默认选择rR1
//             ext_op      = `EXT_NONE;
//             ram_ext_op  = `RAM_EXT_N;
//             rf_we       = 1'b1;
//             ram_we      = `RAM_WE_N;
//             wd_sel      = `WD_ALU;
//             rR1_re      = 1'b0;
//             alub_sel    = `ALUB_R2; // 默认选择rR2
//             is_jump     = 1'b0;
//             is_branch   = 1'b0;
//             is_call     = 1'b0;
//             is_ret      = 1'b0;
//             is_mulordiv = 1'b0;
//             is_ll       = 1'b0;
//             is_sc       = 1'b0;
//             excp_occur  = 1'b1;
//             excp_type   = `EXCP_SYSCALL;
//        end

//        // BREAK (din[31:15]=17'h00054)
//        17'b00000000001010100: begin
//             alu_op      = `ALU_ADD;
//             rR2_re      = 1'b0;
//             npc_op      = `NPC_PC4;    // 默认顺序执行
//             r2_sel      = `R2_RK;      // 默认选择rk
//             wr_sel      = `WR_RD;      // 默认写rd
//             alua_sel    = `ALUA_R1;    // 默认选择rR1
//             ext_op      = `EXT_NONE;
//             ram_ext_op  = `RAM_EXT_N;
//             rf_we       = 1'b1;
//             ram_we      = `RAM_WE_N;
//             wd_sel      = `WD_ALU;
//             rR1_re      = 1'b0;
//             alub_sel    = `ALUB_R2; // 默认选择rR2
//             is_jump     = 1'b0;
//             is_branch   = 1'b0;
//             is_call     = 1'b0;
//             is_ret      = 1'b0;
//             is_mulordiv = 1'b0;
//             is_ll       = 1'b0;
//             is_sc       = 1'b0;
//             excp_occur  = 1'b1;
//             excp_type   = `EXCP_BREAK;
//        end

        // 默认处理非法指令
        default: begin
            alu_op      = `ALU_ADD;
            rR2_re      = 1'b1;
            npc_op      = `NPC_PC4;    // 默认顺序执行
            r2_sel      = `R2_RK;      // 默认选择rk
            wr_sel      = `WR_RD;      // 默认写rd
            alua_sel    = `ALUA_R1;    // 默认选择rR1
            ext_op      = `EXT_NONE;
            ram_ext_op  = `RAM_EXT_N;
            rf_we       = 1'b1;
            ram_we      = `RAM_WE_N;
            wd_sel      = `WD_ALU;
            rR1_re      = 1'b1;
            alub_sel    = `ALUB_R2; // 默认选择rR2
            is_jump     = 1'b0;
            is_branch   = 1'b0;
            is_call     = 1'b0;
            is_ret      = 1'b0;
            is_mulordiv = 1'b0;
            is_ll       = 1'b0;
            is_sc       = 1'b0;
            excp_occur  = 1'b0;
            excp_type   = `EXCP_NONE;
        end
    endcase
end

endmodule