`timescale 1ns / 1ps

`include "defines.vh"
//容量大小：16KB = 2^14字节
//一块的大小是16字节，即128位
//块内偏移4位（按字节编址）
//有2^10块
//cache组号9位
//主存地址标签位32-9-4=19位


module data_cache(
    input  wire         cpu_clk,
    input  wire         cpu_rstn,       // low active
    // Interface to CPU
    input  wire [ 3:0]  data_ren,       // CPU发送的数据读有效信号
    input  wire [31:0]  data_addr,      // CPU发送的数据读取地址
    output reg          data_valid,     // 读取数据有效信号
    output reg  [31:0]  data_rdata,     // 读取的数据
    input  wire [ 3:0]  data_wen,       // CPU发送的数据写有效信号
    input  wire [31:0]  data_wdata,     // 要写入的数据
    output reg          data_wresp,     // 写操作完成的相应信号，只有效一个时钟周期
    // Interface to Write Bus
    input  wire         dev_wrdy,       // 设备写就绪状态信号
    output reg  [ 3:0]  cpu_wen,        // 写使能信号
    output reg  [31:0]  cpu_waddr,      // 写地址
    output reg  [31:0]  cpu_wdata,      // 要写的数据
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 
    output reg  [ 3:0]  cpu_ren,        // 
    output reg  [31:0]  cpu_raddr,      // 
    input  wire         dev_rvalid,     // 主存数据有效信号
    input  wire [`CACHE_BLK_SIZE-1:0] dev_rdata       // 从主存中读取的数据
);
`ifdef ENABLE_DCACHE
    localparam cache_size = 15'd16384; //cache的容量，单位：字节B
    localparam block_size = 9'd128; //Cache每一块的大小，单位：比特bit
    localparam line_size = ((cache_size*8)/block_size);//Cache的行数 = cache_size*8 / block_size
    localparam group_size = line_size / 2;//Cache的组数 = line_size/2(2路组相联)
    
    localparam offset_bits = 3'd4;//以字节为单位的offset的位数
    localparam group_bits = 4'd9;//  
    localparam tag_bits = 32-offset_bits-group_bits;
    localparam offset_bits_32 = 2'd2;//一块里面有多少个32，这个数要用几位二进制数表示
    
    //主存地址分解
    wire [tag_bits-1:0] tag_from_cpu   = /* TODO */ data_addr[31:13];//注意，这里前后都要改位宽
    wire [group_bits-1:0] cache_index    = /* TODO */ data_addr[12:4];            // 
    wire [offset_bits_32-1:0] offset         = /* TODO */ data_addr[3:2];            

    wire [9:0]block_start_index;//注意，这里的位宽也要同步修改！
    assign block_start_index = 2 * cache_index;//由规律，每一组第0块的块号是cache_index*2
    
    //存储体定义
    reg valid [line_size-1:0];          // 有效信号
    reg [tag_bits-1:0] tag  [line_size-1:0];     // 主存地址标签
    reg [block_size-1:0] data [line_size-1:0];     // 存储数据
    reg dirty [line_size-1:0];//脏位
    // 
    //
    localparam R_IDLE  = 3'b000;//0
    localparam R_TAG_CHECK = 3'b001;//1
    localparam R_REFILL = 3'b010;//2
    localparam R_WB = 3'b011;//3
    ///////////////////////////////////////////////////////////
    // 
    localparam W_IDLE = 3'b100;//4
    localparam W_TAG_CHECK = 3'b101;//5
    
    localparam W_WB = 3'b110;//6
    localparam W_REFILL = 3'b111;//7

    
    reg [2:0]r_current_state;
    reg [2:0]r_next_state;
    reg [2:0]w_current_state;
    reg [2:0]w_next_state;
    
    
    reg [1:0]r_wb_counter;//?????°???0-3
    reg [1:0]w_wb_counter;
    reg [3:0]r_cpu_wen;//???é???????????????????????????????????
    reg [3:0]w_cpu_wen;//???é???????????????????????????????????
    reg [31:0]r_cpu_waddr;
    reg [31:0]w_cpu_waddr;
    reg [31:0]r_cpu_wdata;
    reg [31:0]w_cpu_wdata;
    reg [3:0]r_cpu_ren;
    reg [3:0]w_cpu_ren;
    reg [31:0]r_cpu_raddr;
    reg [31:0]w_cpu_raddr;
    //是否真的需要呢？写回cache不是接口信号，打一拍再存也不是不行，只要保证地址和数据正确即可
    reg [3:0]  latched_data_wen; 
    always@(posedge cpu_clk or negedge cpu_rstn)begin
        if(!cpu_rstn)begin
            latched_data_wen <= 4'd0;
        end else if(w_current_state == W_IDLE && w_next_state == W_TAG_CHECK)begin
            latched_data_wen <= data_wen;
        end else if(w_current_state != W_IDLE && w_next_state == W_IDLE)begin
            latched_data_wen <= 4'd0;//从其他状态变回IDLE
        end
    end
    
    //WB、REFILL阶段一开始，向总线发出的读写请求就有效
    always@(*)begin
        if(!cpu_rstn)begin
            cpu_wen = 4'd0;
            cpu_waddr = 32'd0;
            cpu_wdata = 32'd0;
            cpu_ren = 4'd0;
            cpu_raddr = 32'd0;
        end else begin
            cpu_wen = (w_current_state == W_WB) ? w_cpu_wen : (r_current_state == R_WB ? r_cpu_wen : 4'd0);
            cpu_waddr = (w_current_state == W_WB) ? w_cpu_waddr : (r_current_state == R_WB ? r_cpu_waddr : 32'd0);
            cpu_wdata = (w_current_state == W_WB) ? w_cpu_wdata : (r_current_state == R_WB ? r_cpu_wdata : 32'd0);
            
            cpu_ren = (w_current_state == W_REFILL) ? w_cpu_ren : (r_current_state == R_REFILL ? r_cpu_ren : 4'd0);
            cpu_raddr = (w_current_state == W_REFILL) ? w_cpu_raddr : (r_current_state == R_REFILL ? r_cpu_raddr : 32'd0);
        end
    end
    
    reg [block_size-1:0] write_back_data;     // 
    reg [31:0]  write_back_addr;     // 

    wire [block_size-1:0] cache_line_r0 = data[block_start_index];               // ???ICache?????¨???0?????????Cache???
    wire [block_size-1:0] cache_line_r1 = data[block_start_index+1];             // ???ICache?????¨???1?????????Cache???
    wire         valid_bit0     = /* TODO */ valid[block_start_index];  // Cache?????????0???????????????
    wire         valid_bit1     = /* TODO */ valid[block_start_index+1];// Cache?????????1???????????????
    wire [ tag_bits-1:0] tag_from_set0  = /* TODO */ tag[block_start_index];    // Cache?????????0??????TAG
    wire [ tag_bits-1:0] tag_from_set1  = /* TODO */ tag[block_start_index+1];    // Cache?????????1??????TAG

    //LRU逻辑
    reg [1:0] use_bit [group_size-1:0];
    wire replace_way_sel = (~valid_bit0) ? 1'b0 :          // 优先“替换”valid位为0的块，即尚未填充数据
                           (~valid_bit1) ? 1'b1 :          //
                           (use_bit[cache_index] == 2'b01) ? 1'b1 : // 最近使用块0，替换块1
                           (use_bit[cache_index] == 2'b10) ? 1'b0 : // 最近使用块1，替换块0
                           1'b0;                          // 默认替换块0

    wire replace_dirty;
    wire [9:0] replace_block_addr;//

    wire check_hit_r = ((tag_from_set0 == tag_from_cpu && valid_bit0 == 1)||
                 (tag_from_set1 == tag_from_cpu && valid_bit1 == 1)) &&
                 (r_current_state == R_TAG_CHECK);
    //wire refill_hit_r = (r_current_state == R_REFILL) &&
                 //(dev_rvalid);
    reg refill_hit_r;//比dev_rvalid晚一拍
    always@(posedge cpu_clk or negedge cpu_rstn)begin
        if(!cpu_rstn)begin
            refill_hit_r <= 1'b0;
        end
        else if(r_current_state == R_REFILL && dev_rvalid)begin
            refill_hit_r <= 1'b1;
        end
        else begin
            refill_hit_r <= 1'b0;
        end
    end
    wire hit_r = check_hit_r || refill_hit_r;
    wire check_hit_w = ((tag_from_set0 == tag_from_cpu && valid_bit0 == 1)||
                 (tag_from_set1 == tag_from_cpu && valid_bit1 == 1)) && 
                 (w_current_state == W_TAG_CHECK);
    wire refill_hit_w = (w_current_state == W_REFILL) && 
                 (dev_rvalid);//在将脏数据写回后，将需要的数据块再从主存中缓存到cache里，数据有效后必然是命中的

    wire hit_w = check_hit_w || refill_hit_w;
    
    assign replace_block_addr = block_start_index + replace_way_sel;
    assign replace_dirty = (!check_hit_r || !check_hit_w) && dirty[replace_block_addr];//和data_addr同时变化
    
    always@(posedge cpu_clk or negedge cpu_rstn)begin
        if(!cpu_rstn)begin
            write_back_data <= 128'd0;
            write_back_addr <= 32'd0;
        end else begin
            if(w_current_state == W_TAG_CHECK && !hit_w && replace_dirty)begin
                write_back_data <= data[replace_block_addr];
                write_back_addr <= {tag[replace_block_addr],cache_index,4'd0};
            end
        end
    end
    //读命中和写命中的输出逻辑放在一个过程块中?
//    always@(posedge cpu_clk or negedge cpu_rstn)begin
//        if(!cpu_rstn)begin
//            use_bit <= '{default: 2'b00};
//        end
//        else begin
//            data_valid <= hit_r;
//            if(hit_r)begin
//                data_rdata = (tag_from_set0 == tag_from_cpu) ? cache_line_r0[offset * 32 +:32] : cache_line_r1[offset * 32 +:32];
//                if(tag_from_cpu == tag_from_set0) begin
//                    use_bit[cache_index] = 2'b01;
//                end else begin
//                    use_bit[cache_index] = 2'b10;
//                end
//            end
//            if(hit_w)begin
//            end
//        end
//    end
    always @(*) begin//组合逻辑变为时序逻辑？
            data_valid = hit_r;
            if(hit_r) begin
                data_rdata = (tag_from_set0 == tag_from_cpu) ? cache_line_r0[offset * 32 +:32] : cache_line_r1[offset * 32 +:32];
                if(tag_from_cpu == tag_from_set0) begin
                    use_bit[cache_index] = 2'b01;
                end else begin
                    use_bit[cache_index] = 2'b10;
                end
            end
//            else begin
//                data_rdata = 32'd0;
//                use_bit[cache_index] = use_bit[cache_index];
//            /* TODO: ?????????????§????é?????Cache???????????????32??????????????°??? */; 
//            end
    end


                        
    // 
    always@(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn)begin
            r_current_state <= R_IDLE;
        end else begin
            r_current_state <= r_next_state;
        end
    end
    
    //状态更新
    always@(*)begin
        if(!cpu_rstn)begin
            r_next_state = R_IDLE;
        end else begin
            case(r_current_state)
                R_IDLE: r_next_state = (data_ren != 4'b0000) ? R_TAG_CHECK : R_IDLE;
                R_TAG_CHECK: r_next_state = hit_r ? R_IDLE : (replace_dirty ? R_WB:R_REFILL);
                R_WB:r_next_state = (r_wb_counter == 2'd3 && dev_wrdy) ? R_REFILL:R_WB;//dev_wrdyé????°???é???????????????????????
                R_REFILL: r_next_state = dev_rvalid ? R_IDLE : R_REFILL;
                default: r_next_state = R_IDLE;
            endcase
        end
    end


    //reg r_req_sent;
//    reg r_reg_delay;
    
//    always@(posedge cpu_clk or negedge cpu_rstn)begin
//        if(!cpu_rstn)begin
//            r_reg_delay <= 4'd0;
//        end else begin
//            r_reg_delay <= data_ren;
//        end
//    end
    always@(*)begin
        if(!cpu_rstn)begin
            valid = '{default:1'b0};
            tag = '{default:21'd0};
            data = '{default:128'd0};
        end
        else begin
            data[block_start_index] = (dev_rvalid && !replace_way_sel) ? dev_rdata : data[block_start_index];
            tag[block_start_index] = (dev_rvalid && !replace_way_sel) ? tag_from_cpu : tag[block_start_index];
            valid[block_start_index] = (dev_rvalid && !replace_way_sel) ? tag_from_cpu : valid[block_start_index];
            data[block_start_index+1] = (dev_rvalid && replace_way_sel) ? dev_rdata : data[block_start_index+1];
            tag[block_start_index+1] = (dev_rvalid && replace_way_sel) ? tag_from_cpu : tag[block_start_index+1];
            valid[block_start_index+1] = (dev_rvalid && replace_way_sel) ? tag_from_cpu : valid[block_start_index+1];
        end
    end
    


    // 读cache各阶段的输出信号
    always@(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn) begin
            r_wb_counter <= 2'd0;
            r_cpu_wen <= 4'd0;
            r_cpu_waddr <= 32'd0;
            r_cpu_ren <= 4'd0;
            r_cpu_raddr <= 32'd0;
            r_cpu_wdata <= 32'd0;
            //cpu_ren <= 4'd0;
            //cpu_raddr <= 32'd0;
            //r_req_sent <= 1'b0;
//            valid <= '{default:1'b0};
//            tag <= '{default:21'd0};
//            data <= '{default:128'd0};
            dirty <= '{default:1'b0};
            use_bit <= '{default: 2'b00};//??¨?????¤???systemverilog??????
        end else begin
            case(r_current_state)
                // R_IDLE: begin

                // end
                R_TAG_CHECK:begin
                    if(dev_rrdy & !hit_r & !replace_dirty)begin
                    //
                        r_cpu_ren <= 4'b1111;
                        r_cpu_raddr <= {data_addr[31:4],4'd0};//按块对齐的访问主存的地址也要改
                        //r_req_sent <= 1'b1;
                    end else begin
                        r_cpu_ren <= 4'd0;
                        r_cpu_raddr <= 32'd0;
                    end
//                    if(dev_rvalid) begin
//                        r_req_sent <= 1'b0;
//                    end
                end
                R_WB:begin
                    if(dev_wrdy)begin
                        r_cpu_wen <= 4'hf;//?????????????????????????????????????????????????????????1
                        r_cpu_waddr <= {write_back_addr[31:4],r_wb_counter,2'b00};
                        r_cpu_wdata <= write_back_data[r_wb_counter*32+:32];
                        if(r_wb_counter == 2'd3)begin
                            r_wb_counter <= 2'd0;
                            dirty[replace_block_addr] <= 1'b0;
                            //???????????????????°???????
                            r_cpu_ren <= 4'b1111;
                            r_cpu_raddr <= {data_addr[31:4],4'd0};//按块对齐的访问主存的地址也要改
                        end else begin
                            r_wb_counter <= r_wb_counter + 1'b1;
                        end
                    end
                end
                R_REFILL:begin
                    r_cpu_wen <= 4'd0;
                    r_cpu_waddr <= 32'd0;
                    r_cpu_wdata <= 32'd0;
                    r_cpu_ren <= 4'd0;
                    r_cpu_raddr <= 32'd0;
                    if(dev_rvalid)begin//?????????????¤????????????°?????°???
                        case(replace_way_sel)
                            1'b0: begin 
//                                data[block_start_index] <= dev_rdata;
//                                tag[block_start_index] <= tag_from_cpu;
//                                valid[block_start_index] <= 1'b1;
                                use_bit[cache_index] <= 2'b01;
                            end
                            1'b1: begin
//                                data[block_start_index+1] <= dev_rdata;
//                                tag[block_start_index+1] <= tag_from_cpu;
//                                valid[block_start_index+1] <= 1'b1;
                                use_bit[cache_index] <= 2'b10;
                            end
                            default: begin
//                                data[block_start_index] <= dev_rdata;
//                                tag[block_start_index] <= tag_from_cpu;
//                                valid[block_start_index] <= 1'b1;
                                use_bit[cache_index] <= 2'b01;
                            end
                        endcase
                    end
                end
                default:begin
                    //cpu_ren <= 4'd0;
                    //cpu_raddr <= 32'd0;
                    //r_req_sent <= 1'b0;
                end
            endcase
        end
    end

    // TODO: ???????????°Cache??????????????????????????°?????????é?????
    

//    ///////////////////////////////////////////////////////////
//    // TODO: ??????DCache????????????????????????é??
//    localparam W_IDLE = 3'b011;
//    localparam W_CACHE = 3'b100;//???????????°?????°???????????¨Cache??????????????????????????°???
//    localparam W_DEV = 3'b101;

    

    
    always@(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn) begin
            w_current_state <= W_IDLE;
        end else begin
            w_current_state <=  w_next_state;
        end
    end

    // TODO: ??????DCache?????????????????????????§?é?????
    always@(*) begin
        case(w_current_state)
            W_IDLE: w_next_state = (data_wen != 4'b0000) ? W_TAG_CHECK : W_IDLE;
            W_TAG_CHECK: w_next_state = hit_w ? W_IDLE : (replace_dirty ? W_WB : W_REFILL);//????????????????????????é?????????????????/?¤??????°???
            W_WB: w_next_state = (w_wb_counter == 2'd3 && dev_wrdy) ? W_REFILL : W_WB;
            W_REFILL: w_next_state = dev_rvalid ? W_IDLE : W_REFILL;
            default: w_next_state = W_IDLE;
        endcase
    end

    //各个阶段的关键信号输出
    always@(posedge cpu_clk or negedge cpu_rstn) begin
        if(!cpu_rstn) begin
            //w_req_sent <= 1'b0;
            w_wb_counter <= 2'd0;
            data_wresp <= 1'b0;
            //cpu_wen <= 4'b0000;
            //cpu_waddr <= 32'd0;
            //cpu_wdata <= 32'd0;
            w_cpu_wen <= 4'b0000;
            w_cpu_waddr <= 32'd0;
            w_cpu_wdata <= 32'd0;
            w_cpu_ren <= 4'b0000;
            w_cpu_raddr <= 32'd0;
        end else begin
            case(w_current_state)
                W_TAG_CHECK: begin
                    if(hit_w)begin
                        data_wresp <= 1'b1;
                    end

                    if(!hit_w && !replace_dirty && dev_rrdy)begin
                        w_cpu_ren <= 4'b1111;
                        w_cpu_raddr <= {data_addr[31:4],4'd0};
                    end
                end
                W_WB: begin
                    //w_req_sent <= 1'b0;
                    if(dev_wrdy)begin
                        w_cpu_wen <= 4'hf;//?????????????????????????????????????????????????????????1
                        w_cpu_waddr <= {write_back_addr[31:4],w_wb_counter,2'b00};
                        w_cpu_wdata <= write_back_data[w_wb_counter*32+:32];
                        if(w_wb_counter == 2'd3)begin
                            w_wb_counter <= 2'd0;
                            w_cpu_ren <= 4'b1111;
                            w_cpu_raddr <= {data_addr[31:4],4'd0};
                            dirty[replace_block_addr] <= 1'b0;
                        end else begin
                            w_wb_counter <= w_wb_counter + 1'b1;
                        end
                    end
                    
                end
                W_REFILL:begin
                //?????????é?????????¤???????data_wresp
                    w_cpu_wen <= 4'b0000;
                    w_cpu_waddr <= 32'd0;
                    w_cpu_wdata <= 32'd0;
                    w_cpu_ren <= 4'b0000;
                    w_cpu_raddr <= 32'd0;
                    if(hit_w)begin
                        data_wresp <= 1'b1;
                    end
                    if(dev_rvalid)begin
                        case(replace_way_sel)
                            1'b0:begin
//                                data[block_start_index] <= dev_rdata;
//                                tag[block_start_index] <= tag_from_cpu;
//                                valid[block_start_index] <= 1'b1;
                                use_bit[cache_index] <= 2'b01;
                            end
                            1'b1:begin
//                                data[block_start_index+1] <= dev_rdata;
//                                tag[block_start_index+1] <= tag_from_cpu;
//                                valid[block_start_index+1] <= 1'b1;
                                use_bit[cache_index] <= 2'b10;
                            end
                            default:begin
//                                data[block_start_index] <= dev_rdata;
//                                tag[block_start_index] <= tag_from_cpu;
//                                valid[block_start_index] <= 1'b1;
                                use_bit[cache_index] <= 2'b01;
                            end
                        endcase
//                        data[replace_block_addr] <= dev_rdata;
//                        tag[replace_block_addr] <= tag_from_cpu;
//                        valid[replace_block_addr] <= 1'b1;
                        
                    end
                    
                end
                default:begin
                    //w_req_sent <= 1'b0;
                    data_wresp <= 1'b0;
                    w_cpu_wen <= 4'b0000;
                    w_cpu_waddr <= 32'd0;
                    w_cpu_wdata <= 32'd0;
           
                end
            endcase
        end
    end
//    always@(*) begin
//        if(!cpu_rstn) begin
//            data_wresp = 1'b0;
//        end else begin
//            data_wresp = (w_current_state == W_DEV && dev_wrdy) ? 1'b1 : 1'b0;
//        end
//    end
    // TODO: ??????????????????é????????Cache?????????????????????????????ˇ??¨??¤?????°??????
    wire [31:0] bit_mask = {{8{latched_data_wen[3]}}
    , {8{latched_data_wen[2]}}
    , {8{latched_data_wen[1]}}
    , {8{latched_data_wen[0]}}};
    always@(posedge cpu_clk) begin
        if(hit_w) begin//hit_w???TAG_CHECK??????
            if(tag_from_set0 == tag_from_cpu) begin 
                //case(latched_data_wen)
//                data[block_start_index][offset*32+:32] = data[block_start_index][offset*32+:32] | (mask & data_wdata)
//                    4'b1111:data[block_start_index][offset*32+:32] = data_wdata;
//                    4'b1100:data[block_start_index][(16+offset*32)+:16] = data_wdata[31:16];
//                    4'b0011:data[block_start_index][offset*32+:16] = data_wdata[15:0];
//                    4'b0001:data[block_start_index][offset*32+:8] = data_wdata[7:0]
//                    4'b0010:data[block_start_index][offset*32+:32] = data_wdata
//                    4'b0100:data[block_start_index][offset*32+:
//                    4'b1000:data[block_start_index][offset*32+:
                data[block_start_index][offset*32+:32] = data_wdata| (~bit_mask & data[block_start_index][offset*32+:32]);
                    //default:data[block_start_index] = data[block_start_index];
                //endcase               
                //data[block_start_index][offset*32+:32] = data_wdata;
                dirty[block_start_index] = 1'b1;
                use_bit[cache_index] = 2'b01;
            end else begin
                data[block_start_index+1][offset*32+:32] = data_wdata | (~bit_mask & data[block_start_index+1][offset*32+:32]);
//                case(latched_data_wen)
//                    4'b1111:data[block_start_index+1][offset*32+:32] = data_wdata;
//                    4'b1100:data[block_start_index+1][(16+offset*32)+:16] = data_wdata[31:16];
//                    4'b0011:data[block_start_index+1][offset*32+:16] = data_wdata[15:0];
//                    default:data[block_start_index+1] = data[block_start_index+1];
//                endcase 
                //data[block_start_index+1][offset*32+:32] = data_wdata;
                use_bit[cache_index] <= 2'b10;
                dirty[block_start_index+1] = 1'b1;
            end
        end
    end
    
    /******** ???????????????????????? ********/
`else

    localparam R_IDLE  = 2'b00;
    localparam R_STAT0 = 2'b01;
    localparam R_STAT1 = 2'b11;
    reg [1:0] r_state, r_nstat;
    reg [3:0] ren_r;

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        r_state <= !cpu_rstn ? R_IDLE : r_nstat;
    end

    always @(*) begin
        case (r_state)
            R_IDLE:  r_nstat = (|data_ren) ? (dev_rrdy ? R_STAT1 : R_STAT0) : R_IDLE;
            R_STAT0: r_nstat = dev_rrdy ? R_STAT1 : R_STAT0;
            R_STAT1: r_nstat = dev_rvalid ? R_IDLE : R_STAT1;
            default: r_nstat = R_IDLE;
        endcase
    end

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            data_valid <= 1'b0;
            cpu_ren    <= 4'h0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    data_valid <= 1'b0;

                    if (|data_ren) begin
                        if (dev_rrdy)
                            cpu_ren <= data_ren;
                        else
                            ren_r   <= data_ren;

                        cpu_raddr <= data_addr;
                    end else
                        cpu_ren   <= 4'h0;
                end
                R_STAT0: begin
                    cpu_ren    <= dev_rrdy ? ren_r : 4'h0;
                end   
                R_STAT1: begin
                    cpu_ren    <= 4'h0;
                    data_valid <= dev_rvalid ? 1'b1 : 1'b0;
                    data_rdata <= dev_rvalid ? dev_rdata : 32'h0;
                end
                default: begin
                    data_valid <= 1'b0;
                    cpu_ren    <= 4'h0;
                end 
            endcase
        end
    end

    localparam W_IDLE  = 2'b00;
    localparam W_STAT0 = 2'b01;
    localparam W_STAT1 = 2'b11;
    reg  [1:0] w_state, w_nstat;
    reg  [3:0] wen_r;
    wire       wr_resp = dev_wrdy & (cpu_wen == 4'h0) ? 1'b1 : 1'b0;

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        w_state <= !cpu_rstn ? W_IDLE : w_nstat;
    end

    always @(*) begin
        case (w_state)
            W_IDLE:  w_nstat = (|data_wen) ? (dev_wrdy ? W_STAT1 : W_STAT0) : W_IDLE;
            W_STAT0: w_nstat = dev_wrdy ? W_STAT1 : W_STAT0;
            W_STAT1: w_nstat = wr_resp ? W_IDLE : W_STAT1;
            default: w_nstat = W_IDLE;
        endcase
    end

    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            data_wresp <= 1'b0;
            cpu_wen    <= 4'h0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    data_wresp <= 1'b0;

                    if (|data_wen) begin
                        if (dev_wrdy)
                            cpu_wen <= data_wen;
                        else
                            wen_r   <= data_wen;
                        
                        cpu_waddr  <= data_addr;
                        cpu_wdata  <= data_wdata;
                    end else
                        cpu_wen    <= 4'h0;
                end
                W_STAT0: begin
                    cpu_wen    <= dev_wrdy ? wen_r : 4'h0;
                end
                W_STAT1: begin
                    cpu_wen    <= 4'h0;
                    data_wresp <= wr_resp ? 1'b1 : 1'b0;
                end
                default: begin
                    data_wresp <= 1'b0;
                    cpu_wen    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule