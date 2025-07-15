`define ENABLE_ICACHE
`define ENABLE_DCACHE
//`define CPU_2CMT
`define CACHE_BLK_LEN  4
`define CACHE_BLK_SIZE (`CACHE_BLK_LEN*32)

// PC复位初始值
`define PC_INIT_VAL     32'h1C000000

// NPC op
`define NPC_PC4     2'b00
`define NPC_BX      2'b01    // 分支指令
`define NPC_JIRL    2'b10    // 新增JIRL跳转
`define NPC_BL      2'b11    // 新增BL跳转

// 立即数扩展op
`define EXT_NONE    3'b000
`define EXT_1RI20   3'b001
`define EXT_2RI12   3'b010
`define EXT_2RI5U   3'b011
`define EXT_2RI12U  3'b100
`define EXT_2RI16   3'b101
`define EXT_I26     3'b110
`define EXT_2RI14   3'b111


// ALU op
`define ALU_ADD     8'b00000000     // 0
`define ALU_SUB     8'b00000001     // 1
`define ALU_AND     8'b00000010     // 2
`define ALU_OR      8'b00000011     // 3
`define ALU_XOR     8'b00000100     // 4
`define ALU_NOR     8'b00000101     // 5
`define ALU_SLL     8'b00000110     // 6
`define ALU_SRL     8'b00000111     // 7
`define ALU_SRA     8'b00001000     // 8
`define ALU_SLT     8'b00001001     // 9
`define ALU_SLTU    8'b00001010     // a
`define ALU_SLLI    8'b00001011     // b
`define ALU_SRLI    8'b00001100     // c
`define ALU_SRAI    8'b00001101     // d
`define ALU_JUMP    8'b00001110     // e 无条件跳转指令
`define ALU_BEQ     8'b00001111     // f 
`define ALU_BNE     8'b00010000     // 10
`define ALU_BLT     8'b00010001     // 11
`define ALU_BGE     8'b00010010     // 12   
`define ALU_BLTU    8'b00010011     // 13
`define ALU_BGEU    8'b00010100     // 14
`define ALU_MULW    8'b00010101     // 15
`define ALU_MULHW   8'b00010110     // 16
`define ALU_MULHWU  8'b00010111     // 17
`define ALU_DIVW    8'b00011000     // 18
`define ALU_DIVWU   8'b00011001     // 19
`define ALU_MODW    8'b00011010     // 1a
`define ALU_MODWU   8'b00011011     // 1b

`define ALU_CSRRD   8'b00011100     // 1c
`define ALU_CSRWR   8'b00011101     // 1d
`define ALU_CSRXCHG 8'b00011110     // 1e



// 源操作数2的选择：选择rk或rd
`define R2_RK  1'b1
`define R2_RD  1'b0

// 目的操作数寄存器的选择：选择rd或r1
`define WR_RD  1'b1
`define WR_Rr1  1'b0

// ALU操作数A的选择：选择源寄存器1或PC值
`define ALUA_R1  1'b1
`define ALUA_PC  1'b0

// ALU操作数B的选择：选择源寄存器2或立即数
`define ALUB_R2  1'b1
`define ALUB_EXT 1'b0

// Load指令读数据后的扩展op
`define RAM_EXT_N   3'b000  // 非L型访存指令
`define RAM_EXT_H   3'b001  // ld.h
`define RAM_EXT_W   3'b010  // ld.w
`define RAM_EXT_HU  3'b011  // ld.hu
`define RAM_EXT_B   3'b100  // ld.b
`define RAM_EXT_BU  3'b101  // ld.bu
`define RAM_EXT_LL  3'b110  // ll.w 原子访存指令

// Store指令写数据op
`define RAM_WE_N    4'b0000
`define RAM_WE_W    4'b0001
`define RAM_WE_H    4'b0010
`define RAM_WE_B    4'b0011

// 写数据选择：选择将ALU数据或将读主存的数据写回寄存器堆
`define WD_ALU  2'b00
`define WD_RAM  2'b01
`define WD_CSR  2'b10 


// 异常向量地址
`define EXCP_EENTRY_SYSCALL  32'h00000180
`define EXCP_EENTRY_BREAK    32'h000001C0

// 例外指令类型
`define EXCP_NONE       5'b00000
`define EXCP_SYSCALL    5'b00001
`define EXCP_BREAK      5'b00010

