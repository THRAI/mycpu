`timescale 1ns / 1ps

`include "defines.vh"

module myCPU (
    input  wire         cpu_rstn,
    input  wire         cpu_clk,
	input  wire	[ 7:0]  is_hwi,
    
    // Data Access Interface
    output wire [ 3:0]  daccess_ren,    // 读使能，发出读请求时置为4'hF
    output wire [31:0]  daccess_addr,   // 读/写地址
    input  wire         daccess_valid,  // 读数据有效信号
    input  wire [31:0]  daccess_rdata,  // 读数据
    output wire [ 3:0]  daccess_wen,    // 写使能
    output wire [31:0]  daccess_wdata,  // 写数据
    input  wire         daccess_wresp,  // 写响应

    // inc_dev
//    input  wire         ex_flag,        // 该信号有效表示需要执行指令，有效几个周期执行几条指令
//    input  wire [31:0]  ex_inst,        // 待执行指令
//    output wire         ex_finish,      // 执行结束后拉高此信号
//    input  wire         sync_pc_inc,    // PC同步信号（顺序执行）
//    input  wire         sync_pc_we,     // PC同步信号（分支跳转或异常）
//    input  wire [31:0]  sync_pc,        // PC同步值  （分支跳转或异常）
//    input  wire         sync_wb_we,     // WB阶段的写回同步：写使能
//    input  wire [31:0]  sync_wb_pc,     // WB阶段的写回同步：写回阶段的PC值
//    input  wire [ 4:0]  sync_wb_wreg,   // WB阶段的写回同步：被写的寄存器号
//    input  wire [31:0]  sync_wb_wdata,  // WB阶段的写回同步：待写数据
//`ifndef IMPL_TRAP
//    input  wire         excp_occur,     // 参考CPU执行指令发生异常
//`endif

    // Debug Interface
    //chiplab测试core_top没有valid信号
    //output wire         debug_wb_valid, // 写回阶段有效信号
    output wire [31:0]  debug_wb_pc,    // 写回阶段PC值
    output wire [ 3:0]  debug_wb_ena,   // 写回阶段的寄存器堆写使能
    output wire [ 4:0]  debug_wb_reg,   // 写回阶段被写寄存器的寄存器号
    output wire [31:0]  debug_wb_value,  // 写回阶段写入寄存器的数据值

    // Instruction Fetch Interface
    output wire         branch_flush,
    output wire         pause_icache, 
    input  wire         ifetch_stall,//icache暂停
    output wire         ifetch_rreq,    // CPU取指请求信号(取指时为1)
    output wire [31:0]  ifetch_addr,    // 取指地址
    input  wire         ifetch_valid,   // 返回指令机器码的有效信号
    input  wire [31:0]  ifetch_inst    // 返回的指令机器码
);

/****** inc_dev ******/
wire        jump_taken;
//assign      ex_finish = wb_valid;
//`ifndef IMPL_TRAP
//wire        wb_we_no_excp;
//assign      wb_we_no_excp = wb_rf_we /*& !excp_occur*/;     // 发生异常时屏蔽WB阶段的写使能，使异常指令不写回
//`endif

//suspend_restore ex_flag_r都仅和增量开发有关
/*reg suspend_restore;
reg ex_flag_r;
always @(posedge cpu_clk or negedge cpu_rstn) begin
    ex_flag_r <= ex_flag;
    suspend_restore <= !cpu_rstn ? 1'b0 : (ldst_suspend | suspend_restore) & ex_flag | pred_error & ex_flag_r;
end*/

//reg [31:0] ex_inst_r;
//always @(posedge cpu_clk or negedge cpu_rstn) begin
//    ex_inst_r <= !cpu_rstn ? 32'h0 : ex_inst; 
//end
//默认一直需要执行指令，取值请求一直有效
//assign      ifetch_rreq = 1'b1;          // 需要执行指令时myCPU发出取指请求
//assign      ifetch_addr = if_pc;            // 以当前PC值发出取指请求
//wire        inst_valid  = ifetch_valid;
//wire [31:0] inst        = ifetch_inst;
/****** inc_dev ******/

// IF stage signals
wire        if_valid;           // IF阶段有效信号（有效表示当前有指令正处于IF阶段）
reg         ldst_suspend;       // 执行访存指令时的流水线暂停信号
reg         ldst_unalign;       // 访存指令的访存地址是否满足对齐条件
wire        load_use;           // 该信号有效表示检测到ID和EX阶段存在Load-Use冒险

wire [31:0] if_pc;              // IF阶段的PC值
wire [31:0] if_npc;             // IF阶段的下一条指令PC值
wire [31:0] if_pc4;             // IF阶段PC值+4
wire [31:0] pred_target;
wire        pred_error;
assign branch_flush = pred_error;
// wire        mul_done = u_ALU.mul_done;  // PC里表示乘法算完了，IF阶段无需继续暂停流水线(ldst_suspend)了


// ID stage signals
wire        id_valid;           // ID阶段有效信号（有效表示当前有指令正处于ID阶段）
wire [31:0] id_pc;              // ID阶段的PC值
wire [31:0] id_pc4;             // ID阶段PC值+4
wire [31:0] id_inst;            // ID阶段的指令码

wire [ 1:0] id_npc_op;          // ID阶段的npc_op，用于控制下一条指令PC值的生成
wire [ 2:0] id_ext_op;          // ID阶段的立即数扩展op，用于控制立即数扩展方式
wire [ 2:0] id_ram_ext_op;      // ID阶段的读主存数据扩展op，用于控制主存读回数据的扩展方式（针对load指令）
wire [ 7:0] id_alu_op;          // ID阶段的alu_op，用于控制ALU运算方式
wire        id_rf_we;           // ID阶段的寄存器写使能（指令需要写回时rf_we为1）
wire [ 3:0] id_ram_we;          // ID阶段的主存写使能信号（针对store指令）
wire        id_r2_sel;          // ID阶段的源寄存器2选择信号（选择rk或rd）
wire        id_wr_sel;          // ID阶段的目的寄存器选择信号（选择rd或r1）
wire [ 1:0] id_wd_sel;          // ID阶段的写回数据选择（选择ALU执行结果写回，或选择访存数据写回，etc.）
wire        id_rR1_re;          // ID阶段的源寄存器1读标志信号（有效时表示指令需要从源寄存器1读取操作数）
wire        id_rR2_re;          // ID阶段的源寄存器2读标志信号（有效时表示指令需要从源寄存器2读取操作数）
wire        id_alua_sel;        // ID阶段的ALU操作数A选择信号（选择源寄存器1的值或PC）
wire        id_alub_sel;        // ID阶段的ALU操作数B选择信号（选择源寄存器2的值或扩展后的立即数）

wire [31:0] id_rD1;             // ID阶段的源寄存器1的值
wire [31:0] id_rD2;             // ID阶段的源寄存器2的值
wire [31:0] id_ext;             // ID阶段的扩展后的立即数
// wire [ 4:0] id_rR1 = id_inst[9:5];                                  
wire [ 4:0] id_rR1 = id_rR1_re ? id_inst[9:5] : 5'd0;               // 从指令码中解析出源寄存器1的编号
wire [ 4:0] id_rR2 = id_r2_sel ? id_inst[14:10] : id_inst[4:0];     // 选择源寄存器2
wire [ 4:0] id_wR  = id_wr_sel ? id_inst[ 4: 0] : 5'h1;             // 选择目的寄存器

wire [31:0] fd_rD1;             // 前递到ID阶段的源操作数1
wire [31:0] fd_rD2;             // 前递到ID阶段的源操作数2
wire        fd_rD1_sel;         // ID阶段的源操作数1选择信号（选择前递数据或源寄存器1的值）
wire        fd_rD2_sel;         // ID阶段的源操作数2选择信号（选择前递数据或源寄存器2的值）
wire [31:0] id_real_rD1 = fd_rD1_sel ? fd_rD1 : id_rD1;     // ID阶段的源寄存器1的实际数据
wire [31:0] id_real_rD2 = fd_rD2_sel ? fd_rD2 : id_rD2;     // ID阶段的源寄存器2的实际数据

wire        id_jump;
wire        id_branch;

wire        id_call;
wire        id_ret;
wire        id_mulordiv;
wire        id_ll;
wire        id_sc;


// EX stage signals
wire        ex_jump_flag;
wire        ex_valid;           // EX阶段有效信号（有效表示当前有指令正处于EX阶段）
wire [ 1:0] ex_npc_op;          // EX阶段的npc_op，用于控制下一条指令PC值的生成
wire [ 2:0] ex_ram_ext_op;      // EX阶段的读主存数据扩展op，用于控制主存读回数据的扩展方式（针对load指令）
wire [ 7:0] ex_alu_op;          // EX阶段的alu_op，用于控制ALU运算方式
wire        ex_rf_we;           // EX阶段的寄存器写使能（指令需要写回时rf_we为1）
wire [ 3:0] ex_ram_we;          // EX阶段的主存写使能信号（针对store指令）
wire [ 1:0] ex_wd_sel;          // EX阶段的写回数据选择（选择ALU执行结果写回，或选择访存数据写回，etc.）
wire        ex_alua_sel;        // EX阶段的ALU操作数A选择信号（选择源寄存器1的值或PC）
wire        ex_alub_sel;        // EX阶段的ALU操作数B选择信号（选择源寄存器2的值或扩展后的立即数）

wire [ 4:0] ex_wR;              // EX阶段的目的寄存器
wire [31:0] ex_rD1;             // EX阶段的源寄存器1的值
wire [31:0] ex_rD2;             // EX阶段的源寄存器2的值
wire [31:0] ex_pc;              // EX阶段的PC值
wire [31:0] ex_pc4;             // EX阶段的PC值+4
wire [31:0] ex_ext;             // EX阶段的立即数

wire        ex_jump;
wire        ex_branch;

wire        ex_call;
wire        ex_ret;

wire [31:0] ex_alu_A = ex_alua_sel ? ex_rD1 : ex_pc;    // EX阶段的ALU操作数A
wire [31:0] ex_alu_B = ex_alub_sel ? ex_rD2 : ex_ext;   // EX阶段的ALU操作数B
wire [31:0] ex_alu_C;                                   // EX阶段的ALU运算结果

reg  [31:0] ex_wd;                                      // EX阶段的待写回数据
wire        ex_sel_ram = (ex_wd_sel == `WD_RAM);        // EX阶段是否是访存指令 (特指Load指令)
wire        ex_mulordiv;
wire        ex_ll;
wire        ex_sc;


// MEM stage signals
wire        mem_valid;          // MEM阶段有效信号（有效表示当前有指令正处MEM阶段）
wire [ 4:0] mem_wR;             // MEM阶段的目的寄存器
wire [31:0] mem_alu_C;          // MEM阶段的ALU运算结果
wire [31:0] mem_rD2;            // MEM阶段的源寄存器2的值
wire [31:0] mem_pc4;            // MEM阶段的PC值+4
wire [31:0] mem_ext;            // MEM阶段的立即数

wire [ 2:0] mem_ram_ext_op;     // MEM阶段的读主存数据扩展op，用于控制主存读回数据的扩展方式（针对load指令）
wire [ 1:0] mem_wd_sel;         // MEM阶段的写回数据选择（选择ALU执行结果写回，或选择访存数据写回，etc.）
wire        mem_rf_we;          // MEM阶段的寄存器写使能（指令需要写回时rf_we为1）
wire [ 3:0] mem_ram_we;         // MEM阶段的主存写使能信号（针对store指令）
wire [31:0] mem_ram_ext;        // MEM阶段经过扩展的读主存数据
reg  [31:0] mem_wd;             // MEM阶段的待写回数据

wire        mem_ll;
wire        mem_sc;


// WB stage signals
wire        wb_valid;           // WB阶段有效信号（有效表示当前有指令正处于WB阶段）
wire [ 4:0] wb_wR;              // WB阶段的目的寄存器
wire [31:0] wb_pc4;             // WB阶段的PC值+4
wire [31:0] wb_alu_C;           // WB阶段的ALU运算结果
wire [31:0] wb_ram_ext;         // WB阶段的经过扩展的读主存数据
wire        wb_rf_we;           // WB阶段的寄存器写使能
wire [ 1:0] wb_wd_sel;          // WB阶段的写回数据选择（选择ALU执行结果写回，或选择访存数据写回，etc.）
reg  [31:0] wb_wd;              // WB阶段的写回数据

`ifndef IMPL_TRAP
wire        wb_we_no_excp;
assign      wb_we_no_excp = wb_rf_we /*& !excp_occur*/;     // 发生异常时屏蔽WB阶段的写使能，使异常指令不写回
`endif
//待验证
assign      ifetch_rreq = (!cpu_rstn) ? 1'b0 : ((load_use | ldst_suspend) ? 1'b0 : 1'b1);          // 需要执行指令时myCPU发出取指请求
assign      ifetch_addr = if_pc;            // 以当前PC值发出取指请求
wire        inst_valid  = ifetch_valid;
wire [31:0] inst        = ifetch_inst;

// IF
PC u_PC(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (load_use | ldst_suspend | ifetch_stall),      // 流水线暂停信号
    .din            ((pred_error /*| !if_valid*/) ? if_npc : pred_target),
    .pc             (if_pc),            // 当前PC值
    .valid          (if_valid),       // IF阶段有效信号
    .inst_valid     (inst_valid),
    // inc_dev
//    .ex_flag        (inst_valid),
//    .sync_inc       (sync_pc_inc),
//    .sync_we        (sync_pc_we),
//    .sync_pc        (sync_pc),
      .jump_taken     (jump_taken),
//    .suspend_restore(suspend_restore),
    .pred_error     (pred_error)
    //.mul_done       (mul_done)
);

wire  jump_actual = (ex_jump_flag & ex_branch & ex_valid) | ex_jump;    // 是直接跳转指令(跳转了) 或是真正发生跳转了的分支指令

BPU u_BPU (
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .if_pc          (if_pc),
    // predict branch direction and target
    .pred_target    (pred_target),
    .pred_error     (pred_error),
    // signals to correct BHT
    .ex_valid       (ex_valid),
    // .ex_is_bj       (ex_jump | ex_branch),
    .ex_jump        (ex_jump),
    .ex_branch      (ex_branch),
    .ex_is_call     (ex_call),
    .ex_is_ret      (ex_ret),
    .ex_pc          (ex_pc),
    .real_taken     (jump_actual),
    .real_target    (if_npc),
    
    .suspend        (load_use | ldst_suspend | ifetch_stall)
);


NPC u_NPC(
    .npc_op         (ex_valid ? ex_npc_op : `NPC_PC4),      // 若EX阶段无效，则IF阶段默认顺序执行
    .if_pc          (if_pc),
    .ex_pc          (ex_pc),
    .offset         (ex_ext),

    .ex_rj_pc       (ex_rD1),
    .branch         (ex_jump_flag & ex_branch & ex_valid),  // 分支指令是否真的发生跳转了的标志

    .pc4            (if_pc4),
    .npc            (if_npc),

    // inc_dev  
    .jump_taken     (jump_taken)
);

// IF/ID
IF_ID u_IF_ID(
    .cpu_clk    (cpu_clk),
    .cpu_rstn   (cpu_rstn),
    .suspend    (load_use | ldst_suspend /*| ifetch_stall*/),      // 执行访存指令时暂停流水线
    .valid_in   (if_valid & !pred_error /*& !ex_jump*/),//这里不需要管分支指令吗？？？？？？？？？

    .pc_in      (if_pc),
    .pc4_in     (if_pc + 32'h4),
    .inst_in    (inst),

//    .jump_ex_in (ex_jump),            // EX传过来的jump信号

    .valid_out  (id_valid),
    .pc_out     (id_pc),
    .pc4_out    (id_pc4),
    .inst_out   (id_inst)
);

wire [16:0] inst_ctr = id_inst[31:15];
// ID
CU u_CU(
    .din        (inst_ctr),
    .npc_op     (id_npc_op),
    .ext_op     (id_ext_op),
    .ram_ext_op (id_ram_ext_op),
    .alu_op     (id_alu_op),
    .rf_we      (id_rf_we),
    .ram_we     (id_ram_we),
    .r2_sel     (id_r2_sel),
    .wr_sel     (id_wr_sel),
    .wd_sel     (id_wd_sel),
    .rR1_re     (id_rR1_re),
    .rR2_re     (id_rR2_re),
    .alua_sel   (id_alua_sel),
    .alub_sel   (id_alub_sel),

    .is_jump    (id_jump),
    .is_branch  (id_branch),
    .is_call    (id_call),
    .is_ret     (id_ret),
    .is_mulordiv(id_mulordiv),
    .is_ll      (id_ll),
    .is_sc      (id_sc)
);


reg         LLbit;      // 原子锁标志
reg  [31:0] LLaddr;     // 原子地址



RF u_RF(
    .cpu_clk    (cpu_clk),
    .rR1        (id_rR1),
    .rR2        (id_rR2),
    .wR         (wb_wR),
`ifndef IMPL_TRAP
    .we         (wb_we_no_excp),        // 发生异常时屏蔽写回
`else
    .we         (wb_rf_we),
`endif
    .wD         (wb_wd),
    .rD1        (id_rD1),
    .rD2        (id_rD2)
    
    // inc_dev
//    .sync_we    (sync_wb_we),
//    .sync_dst   (sync_wb_wreg),
//    .sync_val   (sync_wb_wdata)
);

EXT u_EXT(
    .din    (id_inst[25:0]),            // 指令码中的立即数字段
    .ext_op (id_ext_op),                // 扩展方式
    .ext    (id_ext)                    // 扩展后的立即数
);

// ID/EX
ID_EX u_ID_EX(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend /*| ifetch_stall*/),
    .valid_in       (id_valid & !load_use & !pred_error),

    .wR_in          (id_wR),
    .pc_in          (id_pc),
    .pc4_in         (id_pc4),
    .rD1_in         (id_real_rD1),
    .rD2_in         (id_real_rD2),
    .ext_in         (id_ext),

    .jump_in        (id_jump & id_valid),
    .jump_ex_in     (jump_actual | ex_jump),            // CU传过来的实际发生了分支跳转的信号
    .branch_in      (id_branch & id_valid),
    .call_in        (id_call & id_valid),
    .ret_in         (id_ret & id_valid),
    .mulordiv_in    (id_mulordiv & id_valid),
    .ll_in          (id_ll & id_valid),
    .sc_in          (id_sc & id_valid),

    .npc_op_in      (id_npc_op),
    .rf_we_in       (id_rf_we & id_valid & !load_use & !pred_error),
    .wd_sel_in      (id_wd_sel),
    .alu_op_in      (id_alu_op),
    .alua_sel_in    (id_alua_sel),
    .alub_sel_in    (id_alub_sel),
    .ram_we_in      (id_ram_we),
    .ram_ext_op_in  (id_ram_ext_op),

    .valid_out      (ex_valid),
    .wR_out         (ex_wR),
    .pc_out         (ex_pc),
    .pc4_out        (ex_pc4),
    .rD1_out        (ex_rD1),
    .rD2_out        (ex_rD2),
    .ext_out        (ex_ext),

    .jump_out       (ex_jump),
    .branch_out     (ex_branch),
    .call_out       (ex_call),
    .ret_out        (ex_ret),
    .mulordiv_out   (ex_mulordiv),
    .ll_out         (ex_ll),
    .sc_out         (ex_sc),

    .npc_op_out     (ex_npc_op),
    .rf_we_out      (ex_rf_we),
    .wd_sel_out     (ex_wd_sel),
    .alu_op_out     (ex_alu_op),
    .alua_sel_out   (ex_alua_sel),
    .alub_sel_out   (ex_alub_sel),
    .ram_we_out     (ex_ram_we),
    .ram_ext_op_out (ex_ram_ext_op)
);

//乘除法时暂停流水线，乘除法指令执行完毕后复位暂停信号
//后续可将乘除法取或，用来整体实现顺序流水线遇到乘除法时的暂停
wire start_mul = u_ALU.start_mul;
// wire start_mulordiv = u_ALU.start_mul | u_ALU.start_div; //乘除法需要暂停的周期和具体控制的信号不同，不能放一起写; 乘法看start_mul信号升起来的时刻，下一个clk时suspend信号拉低; 除法看div_is_running信号升起来的时刻，下一个clk时suspend信号拉低
wire start_div = u_ALU.start_div;
wire div_is_running = u_ALU.div_is_running;
wire divisor_greater_than_dividend = u_ALU.u_div_alu.divisor_greater_than_dividend;
wire terminate = u_ALU.u_div_alu.terminate;

always @(posedge cpu_clk or negedge cpu_rstn) begin
    if(!cpu_rstn | start_mul | (div_is_running & terminate) | (start_div & divisor_greater_than_dividend))
        ldst_suspend <= 1'b0;
    else if(id_valid & id_mulordiv)
        ldst_suspend <= 1'b1;
end

// EX
ALU u_ALU(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .A              (ex_alu_A),
    .B              (ex_alu_B),
    .C              (ex_alu_C),
    .alu_op         (ex_alu_op),
    .jump_flag      (ex_jump_flag)  // ALU计算得到的分支指令是否真正进行跳转的标志
);

always @(*) begin
    // 根据选择信号，在EX阶段选择相应的数据用于前递
    case (ex_wd_sel)
        `WD_RAM: ex_wd = 32'h0;
        `WD_ALU: ex_wd = ex_alu_C;
        default: ex_wd = 32'h12345678;
    endcase

    // 判断访存地址是否对齐，地址不对齐时不访存
    case (ex_ram_we)
        `RAM_WE_W : ldst_unalign = (ex_alu_C[1:0] != 2'h0);                                     // st.w
        `RAM_WE_H : ldst_unalign = (ex_alu_C[1:0] != 2'h0) & (ex_alu_C[1:0] != 2'h2);           // st.h
        `RAM_WE_B : ldst_unalign = 1'b0;                                                        // st.b指令何时都访存
        default:    //RAM_WE_N 即ld型指令
            case (ex_ram_ext_op)
                `RAM_EXT_H : ldst_unalign = (ex_alu_C[1:0] != 2'h0) & (ex_alu_C[1:0] != 2'h2);  // ld.h
                `RAM_EXT_HU: ldst_unalign = (ex_alu_C[1:0] != 2'h0) & (ex_alu_C[1:0] != 2'h2);  // ld.hu
                `RAM_EXT_W : ldst_unalign = (ex_alu_C[1:0] != 2'h0);                            // ld.w
                // RAM_EXT_B, RAM_EXT_BU 即ld.b或ld.bu指令何时都访存，一定能对齐                // ld.b | ld.bu
                default    : ldst_unalign = 1'b0;
            endcase
    endcase
end
always @(posedge cpu_clk or negedge cpu_rstn) begin
    if (!cpu_rstn | daccess_valid | daccess_wresp)
        ldst_suspend <= 1'b0;       // 访存结束后复位流水线暂停信号
    else if (ex_valid & (ex_wd_sel == `WD_RAM) & !ldst_unalign)
        ldst_suspend <= 1'b1;       // 执行访存指令时，拉高流水线暂停信号
end
assign pause_icache = ldst_suspend;
// EX/MEM
EX_MEM u_EX_MEM(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend /*| ifetch_stall*/),
    .valid_in       (ex_valid),

    .wR_in          (ex_wR),
    .pc4_in         (ex_pc4),
    .alu_C_in       (ex_alu_C),
    .rD2_in         (ex_rD2),
    .ext_in         (ex_ext),

    .rf_we_in       (ex_rf_we & !ldst_unalign),     // 若地址不对齐，不写回
    .wd_sel_in      (ex_wd_sel),
    .ram_we_in      (ex_ram_we),
    .ram_ext_op_in  (ex_ram_ext_op),

    .ll_in          (ex_ll),
    .sc_in          (ex_sc),

    .valid_out      (mem_valid),
    .wR_out         (mem_wR),
    .pc4_out        (mem_pc4),
    .alu_C_out      (mem_alu_C),
    .rD2_out        (mem_rD2),
    .ext_out        (mem_ext),

    .rf_we_out      (mem_rf_we),
    .wd_sel_out     (mem_wd_sel),
    .ram_we_out     (mem_ram_we),
    .ram_ext_op_out (mem_ram_ext_op),
    .ll_out         (mem_ll),
    .sc_out         (mem_sc)
);

// MEM
RAM_EXT u_RAM_EXT(
    .din            (daccess_rdata),    // 从主存读回的数据
    .byte_offset    (mem_alu_C[1:0]),   // 访存地址低2位
    .ram_ext_op     (mem_ram_ext_op),   // 扩展方式
    .ext_out        (mem_ram_ext)       // 扩展后的数据
);
// 根据选择信号，在MEM阶段选择相应的数据用于前递
always @(*) begin
    case (mem_wd_sel)
        `WD_RAM: mem_wd = mem_ram_ext;
        `WD_ALU: mem_wd = mem_alu_C;
        default: mem_wd = 32'h87654321;
    endcase
end

// Generate load/store requests
MEM_REQ u_MEM_REQ (
    .clk            (cpu_clk       ),
    .rstn           (cpu_rstn      ),
    .ex_valid       (ex_valid      ),       // EX阶段有效信号
    .mem_wd_sel     (mem_wd_sel    ),       // 区分当前是否是访存指令
    .mem_ram_addr   (mem_alu_C     ),       // 由ALU计算得到的访存地址

    .mem_ram_ext_op (mem_ram_ext_op),       // 区分当前是哪一条load指令
    .da_ren         (daccess_ren   ),
    .da_addr        (daccess_addr  ),

    .mem_ram_we     (mem_ram_we    ),       // 区分当前是load指令还是store指令，以及是哪一条store指令
    .mem_ram_wdata  (mem_rD2       ),
    .da_wen         (daccess_wen   ),
    .da_wdata       (daccess_wdata )
);

// MEM/WB
MEM_WB u_MEM_WB(
    .cpu_clk        (cpu_clk),
    .cpu_rstn       (cpu_rstn),
    .suspend        (ldst_suspend /*| ifetch_stall*/),
    .valid_in       (mem_valid),

    .wR_in          (mem_wR),
    .pc4_in         (mem_pc4),
    .alu_C_in       (mem_alu_C),
    .ram_ext_in     (mem_ram_ext),
    .ext_in         (mem_ext),

    .rf_we_in       (mem_rf_we),
    .wd_sel_in      (mem_wd_sel),

    .valid_out      (wb_valid),
    .wR_out         (wb_wR),
    .pc4_out        (wb_pc4),
    .alu_C_out      (wb_alu_C),
    .ram_ext_out    (wb_ram_ext),

    .rf_we_out      (wb_rf_we),
    .wd_sel_out     (wb_wd_sel)
);

// WB
// 根据选择信号，在WB阶段选择相应的数据用于前递
always @(*) begin
    case (wb_wd_sel)
        `WD_RAM: wb_wd = wb_ram_ext;
        `WD_ALU: wb_wd = wb_alu_C;
        default: wb_wd = 32'haabbccdd;
    endcase
end

// Data Hazard Detection & Data Forward
data_forward u_DF(
    .id_rR1         (id_rR1),
    .id_rR2         (id_rR2),
    .id_rR1_re      (id_rR1_re),
    .id_rR2_re      (id_rR2_re),

    .ex_wd          (ex_wd),
    .ex_wr          (ex_wR),
    .ex_we          (ex_rf_we & ex_valid),

    .mem_wd         (mem_wd),
    .mem_wr         (mem_wR),
    .mem_we         (mem_rf_we),

    .wb_wd          (wb_wd),
    .wb_wr          (wb_wR),
    .wb_we          (wb_rf_we),

    .ex_sel_ram     (ex_sel_ram),
    .suspend_finish (!ldst_suspend),
    .load_use       (load_use),

    .fd_rD1         (fd_rD1),
    .fd_rD1_sel     (fd_rD1_sel),
    .fd_rD2         (fd_rD2),
    .fd_rD2_sel     (fd_rD2_sel)
);

reg debug_wb_we;//有且仅有效一个时钟周期版本
always@(posedge cpu_clk or negedge cpu_rstn)begin
    if(!cpu_rstn) debug_wb_we <= 1'd0;
    else if(mem_rf_we) debug_wb_we <= 1'd1;
    else debug_wb_we <= 1'd0;
end

// Debug Interface
//assign debug_wb_valid = wb_valid;
assign debug_wb_pc    = /*sync_wb_we ? sync_wb_pc      : */wb_pc4 - 4;
`ifndef IMPL_TRAP
//？奇怪，如果没有定义，wb_we_no_excp连的也是wb_rf_we
assign debug_wb_ena   = /*sync_wb_we ? {4{sync_wb_we}} : */{4{debug_wb_we}/*{wb_we_no_excp}*/};
`else
assign debug_wb_ena   = /*sync_wb_we ? {4{sync_wb_we}} : */{4{debug_wb_we}/*{wb_rf_we}*/};
`endif
assign debug_wb_reg   = /*sync_wb_we ? sync_wb_wreg    : */wb_wR;
assign debug_wb_value = /*sync_wb_we ? sync_wb_wdata   : */wb_wd;

endmodule
