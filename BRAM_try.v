// simulate BRAM IP in simulation without Vivado
// data read latency is 1 cycle
`timescale 1ns / 1ps
module BRAM_try #(
    parameter DATA_SIZE = 149,//valid+tag+data = 1+20+128
    parameter ADDR_SIZE = 8
    //parameter TAG_SIZE 20
) (
    input logic clk,

    //感觉没必要多加使能信号，反正也是常置为1
    input logic ena,  // Chip enable A
    //input logic enb,  // Chip enable B

    input logic wea,  // A的写使能，因为每次只有读32位存储字的情况，所以不需要4位掩码
    //input logic[3:0] web,  // Write enable B

    input  logic [DATA_SIZE-1:0] dina,//每一个存储字32位，4字节单独放？
    input  logic [ADDR_SIZE-1:0] addra,//BRAM中的地址，即组号
    output logic [DATA_SIZE-1:0] douta

    // input  logic [DATA_SIZE-1:0] dinb,
    // input  logic [ADDR_SIZE-1:0] addrb,
    // output logic [DATA_SIZE-1:0] doutb
);

    (* ram_style = "block" *) logic [DATA_SIZE-1:0] data[2**ADDR_SIZE];//2^8

    // wire [31:0]write_mask_a;
    // assign write_mask_a={{8{wea[3]}},{8{wea[2]}},{8{wea[1]}},{8{wea[0]}}};

    // wire [31:0]write_mask_b;
    // assign write_mask_b={{8{web[3]}},{8{web[2]}},{8{web[1]}},{8{web[0]}}};

    // For Simulation
    initial begin
        for (integer i = 0; i < 2 ** ADDR_SIZE; i++) begin
            data[i] = 0;
        end
    end

    // Read logic
    always_ff @(posedge clk) begin
        if (wea) douta <= dina;//写操作时输出新数据
        else if (ena) douta <= data[addra];//读操作时输出存储数据
        else douta <= 0;//是否需要？好像并不会到这里

        // if (enb & (|web)) doutb <= dinb;
        // else if (enb) doutb <= data[addrb];
        // else doutb <= 0;
    end

    // Write logic
    always_ff @(posedge clk) begin
        if (wea) begin
            data[addra] <= dina/*(dina)|(data[addra]&~write_mask_a)*/;
        end
        else begin
            data[addra] <= data[addra];
        end
        // else if (enb & (|web)) begin
        //     data[addrb] <= (dinb&write_mask_b)|(data[addrb]&~write_mask_b);
        // end
    end



endmodule
