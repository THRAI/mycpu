`timescale 1ns / 1ps

`include "defines.vh"

module MEM_REQ (
    input  wire         clk,
    input  wire         rstn,
    input  wire         ex_valid,
    input  wire [ 1:0]  mem_wd_sel,      // 访存写回位置
    input  wire [31:0]  mem_ram_addr,    // 访存的地址

    input  wire [ 2:0]  mem_ram_ext_op,  // 从内存读回数据的扩展操作
    output reg  [ 3:0]  da_ren,          // 读访存端读请求
    output reg  [31:0]  da_addr,

    input  wire [ 3:0]  mem_ram_we,      // 内存写使能
    input  wire [31:0]  mem_ram_wdata,
    output reg  [ 3:0]  da_wen,          // 写访存端写请求
    output reg  [31:0]  da_wdata
);

// send_ldst_req用于确保读写请求只有效一个clk
reg        send_ldst_req;       // only valid in the first clk of mem stage
wire [1:0] offset = mem_ram_addr[1:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        send_ldst_req <= 1'b0;
        da_ren        <= 4'h0;
        da_wen        <= 4'h0;
        da_addr       <= 32'h0;
        da_wdata      <= 32'h0;
    end else begin
        send_ldst_req <= ex_valid;
        if (da_ren != 4'h0) da_ren  <= 4'h0;
        if (da_wen != 4'h0) da_wen  <= 4'h0;

        // 通过mem_wd_sel的值判断当前是否是访存指令
        if (send_ldst_req & (mem_wd_sel == `WD_RAM)) begin
            
            da_addr <= {mem_ram_addr[31:2], 2'h0};          // 访存地址按字对齐
            
            // 通过mem_ram_we判断指令是store还是load，如果是store，具体是哪一条store
            case (mem_ram_we)
                `RAM_WE_W : begin                           // st.w
                    if (offset == 2'h0) begin
                        da_wen <= 4'hF;
                        da_wdata <= mem_ram_wdata;
                    end
                    else  da_wen <= 4'h0;
                end
                `RAM_WE_H : begin                           // st.h
                    if (offset == 2'h0 || offset == 2'h2) begin
                        da_wen <= (offset == 2'h0) ? 4'b0011 : 4'b1100;
                        da_wdata <= mem_ram_wdata[15:0] << (8 * offset); // 半字数据左移到对应位置
                    end
                    else  da_wen <= 4'h0;
                end
                `RAM_WE_B : begin                           // st.b
                    case(offset)
                        2'h0: begin
                            da_wen <= 4'b0001;
                            da_wdata <= mem_ram_wdata[7:0];
                        end
                        2'h1: begin
                            da_wen <= 4'b0010;
                            da_wdata <= mem_ram_wdata[7:0] << 8;
                        end
                        2'h2: begin
                            da_wen <= 4'b0100;
                            da_wdata <= mem_ram_wdata[7:0] << 16;
                        end
                        2'h3: begin
                            da_wen <= 4'b1000;
                            da_wdata <= mem_ram_wdata[7:0] << 24;
                        end
                    endcase
                end
                default: begin
                    // 通过mem_ram_ext_op判断load指令具体是哪一条load
                    case (mem_ram_ext_op)
                        `RAM_EXT_H :                        // ld.h
                            if (offset == 2'h0 || offset == 2'h2) 
                                da_ren <= 4'hF;
                        `RAM_EXT_HU:                        // ld.hu
                            if (offset == 2'h0 || offset == 2'h2) 
                                da_ren <= 4'hF;
                        `RAM_EXT_B :                        // ld.b
                            if (offset == 2'h0 || offset == 2'h2 || offset == 2'h1 || offset == 2'h3) 
                                da_ren <= 4'hF;
                        `RAM_EXT_BU:                        // ld.bu
                            if (offset == 2'h0 || offset == 2'h2 || offset == 2'h1 || offset == 2'h3) 
                                da_ren <= 4'hF;
                        `RAM_EXT_W :                        // ld.w
                            if (offset == 2'h0)
                                da_ren <= 4'hF;
                        default:                            // ld.w
                            if (offset == 2'h0)
                                da_ren <= 4'hF;
                    endcase
                end
            endcase
        end
    end
end

endmodule
