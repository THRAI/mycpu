`timescale 1ns / 1ps

`include "defines.vh"

module NPC (
    input  wire [31:0]  if_pc,      // 当前指令的PC ???这玩意有啥用?????
    input  wire [ 1:0]  npc_op,     // NPC操作控制信号，用于选择下一个PC的值
    input  wire [31:0]  ex_pc,
    input  wire [31:0]  ex_rj_pc,   // JIRL信号用来计算pc的ID_EX里rj寄存器拉回来的pc
    input  wire [31:0]  offset,
    input  wire         branch,     // 分支指令是否真的发生了跳转的标志

    output wire [31:0]  pc4,        // 当前PC+4 的值（顺序执行的下一条指令地址）
    output reg  [31:0]  npc,        // 下一个PC的值

    // inc_dev
    output reg          jump_taken  // 跳转信号，表示是否发生了分支或跳转
);

assign pc4 = ex_pc + 32'h4;
always @(*) begin
    case (npc_op)
        `NPC_PC4:   npc = pc4;                      // 如果npc_op为NPC_PC4，选择顺序执行的下一条指令地址
        `NPC_JIRL:  npc = ex_rj_pc + offset;        // JIRL跳转：目标地址=ex_pc + offset
        `NPC_BL:    npc = ex_pc + offset;           // BL和B指令
        `NPC_BX:   begin                            // 分支跳转指令
            if(branch)  npc = ex_pc + offset;       // 分支指令真的发生了跳转
            else        npc = pc4;                  // 分支指令没发生跳转则选择顺序执行下一条指令地址(pc+4)
        end
        default :   npc = pc4;                      // 默认情况下，也选择顺序执行的下一条指令地址
            
    endcase
end

// inc_dev
// when branch or jump, set jump_taken to 1
//always @(*) begin
//    case (npc_op)
//        `NPC_JIRL: jump_taken = 1'b1;
//        `NPC_BL:   jump_taken = 1'b1;               // BL和B指令
//        `NPC_BX:   begin                            // 分支跳转指令
//            if(branch)  jump_taken = 1'b1;
//            else        jump_taken = 1'b0;
//        end
//        default  : jump_taken = 1'b0;
//    endcase
//end

endmodule
