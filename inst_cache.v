`timescale 1ns / 1ps

`include "defines.vh"

module inst_cache(
    input  wire         cpu_clk,
    input  wire         cpu_rstn,       // low active
    // Interface to CPU
    input  wire         branch_flush, 
    input  wire         inst_rreq,      // 来自CPU的取指请求
    input  wire         pause_icache,
    output  wire        icache_stall,
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
    output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
    output reg  [31:0]  inst_out,       // 输出给CPU的指令
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
    output reg  [ 3:0]  cpu_ren,        // 输出给主存的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存的读地址
    input  wire         dev_rvalid,     // 来自主存的数据有效信号
    input  wire [`CACHE_BLK_SIZE-1:0] dev_rdata   // 来自主存的读数据
);
//容量8KB = 2^13B
//每一块的大小是128位 = 2^7
//一共有2^9块
//一共有2^8组
//块内偏移量：4位
//组号：8位
//主存地址标签位32-4-8=20位
//`define block_size 128
`define TAG_SIZE 20
`define GROUP_SIZE 256
`define LINE_SIZE 512
`define INDEX_SIZE 8
`define OFFSET_SIZE 4
`define TAG_LOC 31:12
`define INDEX_LOC 11:4
`define OFFSET_LOC 3:2
`define TAG_FROM_SET_LOC 147:128
`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/
    reg [31:0]pre_inst_addr;
    always@(posedge cpu_clk or negedge cpu_rstn)begin
        if(!cpu_rstn) pre_inst_addr <= 32'd0;
        else if(!icache_stall)pre_inst_addr <= inst_addr;
        else pre_inst_addr <= pre_inst_addr;
    end
    // 主存地址分解
    wire [ `TAG_SIZE-1:0] tag_from_cpu   = /* TODO */ inst_addr[`TAG_LOC];          // 主存地址的TAG
    wire [  `INDEX_SIZE-1:0] cache_index    = /* TODO */ inst_addr[`INDEX_LOC];            // 主存地址的Cache索引 / ICache存储体的地址
    wire [  1:0] offset         = /* TODO */ pre_inst_addr[`OFFSET_LOC];            // 32位字偏移量
    //从存储体中读出的line有三部分：valid+tag+data，一共是1+20+128=149位
    wire [`TAG_SIZE+`CACHE_BLK_SIZE:0] cache_line_r0;                                         // 从ICache存储体0读出的Cache块
    wire [`TAG_SIZE+`CACHE_BLK_SIZE:0] cache_line_r1;                                         // 从ICache存储体1读出的Cache块
    wire         valid_bit0     = /* TODO */ cache_line_r0[`TAG_SIZE+`CACHE_BLK_SIZE];        // Cache组内第0块的有效位
    wire         valid_bit1     = /* TODO */ cache_line_r1[`TAG_SIZE+`CACHE_BLK_SIZE];        // Cache组内第1块的有效位
    wire [ `TAG_SIZE-1:0] tag_from_set0  = /* TODO */ cache_line_r0[`TAG_FROM_SET_LOC];    // Cache组内第0块的TAG
    wire [ `TAG_SIZE-1:0] tag_from_set1  = /* TODO */ cache_line_r1[`TAG_FROM_SET_LOC];    // Cache组内第1块的TAG

    // TODO: 定义ICache状态机的状态变量
    reg [1:0] current_state, next_state;

    localparam IDLE         = 2'b00; 
    localparam TAG_CHECK    = 2'b01;  
    localparam REFILL       = 2'b10;


    // 需保证命中时，hit信号仅有效1个时钟周期
    wire hit0 = /* TODO */ (current_state == TAG_CHECK) & valid_bit0 & (tag_from_set0 == tag_from_cpu);     // Cache组内第0块的命中信号
    wire hit1 = /* TODO */ (current_state == TAG_CHECK) & valid_bit1 & (tag_from_set1 == tag_from_cpu);     // Cache组内第1块的命中信号
    wire hit  = hit0 | hit1;
    //在TAG_CHECK阶段有效
    wire [`CACHE_BLK_SIZE-1:0] hit_data_blk = {`CACHE_BLK_SIZE{hit0}} & cache_line_r0[`CACHE_BLK_SIZE-1:0] |
                                              {`CACHE_BLK_SIZE{hit1}} & cache_line_r1[`CACHE_BLK_SIZE-1:0];

    always @(*) begin
        //目前是REFILL之后也会回到TAG_CHECK阶段，所以将inst_valid赋值为hit
        inst_valid = hit;
        inst_out = (current_state == TAG_CHECK) ? hit_data_blk[offset * 32 +: 32] : 32'b0;    
    end
    
     // 记录第i个Cache组内的Cache块的被访问情况（比如块0被访问，则置use_bit[i]为01，块1被访问则置use_bit[i]为10），用于实现Cache块替换
    reg  [1:0] use_bit [`GROUP_SIZE-1:0];

    // 替换策略：优先替换无效块，否则根据LRU策略替换
    wire replace_way_sel = (~valid_bit0) ? 1'b0 :          // 块0无效则替换
                           (~valid_bit1) ? 1'b1 :          // 块1无效则替换
                           (use_bit[cache_index] == 2'b01) ? 1'b1 : // LRU替换块1
                           (use_bit[cache_index] == 2'b10) ? 1'b0 : // LRU替换块0
                           1'b0;                          // 默认替换块0

    wire  cache_we0  = (current_state == REFILL) & dev_rvalid & (replace_way_sel == 0); // 写使能0
    wire  cache_we1  = (current_state == REFILL) & dev_rvalid & (replace_way_sel == 1); // 写使能1
    wire [`TAG_SIZE+`CACHE_BLK_SIZE:0] cache_line_w = {1'b1, tag_from_cpu, dev_rdata}; // 拼接有效位、Tag和数据

    // ICache存储体：Block MEM IP核
    // blk_mem_gen_1 U_isram0 (        // ICache存储体0，存储所有Cache组的第0块
    //     .clka   (cpu_clk),
    //     .wea    (cache_we0),
    //     .addra  (cache_index),
    //     .dina   (cache_line_w),
    //     .douta  (cache_line_r0)
    // );

    // blk_mem_gen_1 U_isram1 (        // ICache存储体1，存储所有Cache组的第1块
    //     .clka   (cpu_clk),
    //     .wea    (cache_we1),
    //     .addra  (cache_index),
    //     .dina   (cache_line_w),
    //     .douta  (cache_line_r1)
    // );
    BRAM_try U_ram0 (//Icache存储体0，存储所有组中的第0块
        .clk    (cpu_clk),
        .ena    (1'b1),
        .wea    (cache_we0),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r0)
    );
    BRAM_try U_ram1 (//Icache存储体0，存储所有组中的第0块
        .clk    (cpu_clk),
        .ena    (1'b1),
        .wea    (cache_we1),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r1)
    );

    // TODO: 编写状态机现态的更新逻辑
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        current_state <= (!cpu_rstn | branch_flush) ? IDLE : next_state;
    end
    
    
      // TODO: 编写状态机的状态转移逻辑
    always @(*) begin
        if(pause_icache) next_state = current_state;
        else begin
            case (current_state)
                IDLE: begin
                    next_state = inst_rreq ? TAG_CHECK : IDLE; // 收到请求后进入 TAG_CHECK
                end
                TAG_CHECK: begin
                    if (hit) begin
                        next_state = IDLE;    // 命中则返回 IDLE
                    end else begin
                        next_state = dev_rrdy ? REFILL : TAG_CHECK; // 未命中则进入 REFILL
                    end
                end
                REFILL: begin
                    next_state = dev_rvalid ? TAG_CHECK : REFILL; // 等待数据填充完成
                end
                default: next_state = IDLE;
            endcase
        end
    end
    assign icache_stall = /*((!hit)&&(current_state == TAG_CHECK)) ||*/pause_icache ? 1'b0:
                           (current_state == REFILL);
    ///TODO: 生成状态机的输出信号
//    reg [3:0]pre_cpu_ren;
//    reg [31:0]pre_cpu_raddr;
//    always@(posedge cpu_clk or negedge cpu_rstn)begin
//        if(!cpu_rstn)begin
//            pre_cpu_ren <= 4'h0;
//            pre_cpu_raddr <= 32'd0;
//        end
//        else begin
//            pre_cpu_ren <= cpu_ren;
//            pre_cpu_raddr <= cpu_raddr;
//        end
//    end
    reg req_sent;
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            cpu_ren <= 4'h0;
            cpu_raddr <= 32'h0;
            req_sent <= 1'b0;
            // for (integer i=0; i<64; i=i+1)
            //     use_bit[i] <= 2'b00;
            use_bit <= '{default: 2'b00};    //verilog不支持这种语法
        end 
        else if(!pause_icache)begin
            case (current_state)
                IDLE: begin
                    cpu_ren <= 4'h0;
                    cpu_raddr <= 32'h0;
                end
                TAG_CHECK: begin
                    if (hit) begin
                        if (hit0)
                            use_bit[cache_index] <= 2'b01;
                        else if (hit1)
                            use_bit[cache_index] <= 2'b10;
                    end
                    else begin
                        cpu_ren <= 4'h0;
                        cpu_raddr <= 32'd0;
                    end
//                    else if(dev_rrdy & (next_state == REFILL)) begin
//                        cpu_raddr <= {pre_inst_addr[31:4], 4'b0};
//                        cpu_ren <= 4'hF;
//                    end
                end
                REFILL: begin
                    if(!req_sent)begin
                        cpu_ren <= 4'hF;
                        cpu_raddr <= {inst_addr[31:4],4'b0};
                        req_sent <= 1'b1;
                    end
                    else begin
                        cpu_raddr <= 32'h0;
                        cpu_ren <= 4'h0;
                    end
                    if (dev_rvalid) begin
                        req_sent <= 1'b0;
                        if (cache_we0)
                            use_bit[cache_index] <= 2'b01;
                        else if (cache_we1)
                            use_bit[cache_index] <= 2'b10;
                    end
                end//end REFILL
                default:begin
                    cpu_ren <= 4'h0;
                    cpu_raddr <= 32'd0;
                end
            endcase
        end else begin//暂停时不变
            cpu_ren <= cpu_ren;
            cpu_raddr <= cpu_raddr;
        end
    end



    /******** 不要修改以下代码 ********/
`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        state <= !cpu_rstn ? IDLE : nstat;
    end

    always @(*) begin
        case (state)
            IDLE:    nstat = inst_rreq ? (dev_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:   nstat = dev_rrdy ? STAT1 : STAT0;
            STAT1:   nstat = dev_rvalid ? IDLE : STAT1;
            default: nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            inst_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= (inst_rreq & dev_rrdy) ? 4'hF : 4'h0;
                    cpu_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0: begin
                    cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
                end
                STAT1: begin
                    cpu_ren    <= 4'h0;
                    inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= dev_rvalid ? dev_rdata[31:0] : 32'h0;
                end
                default: begin
                    inst_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule