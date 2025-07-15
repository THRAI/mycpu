`timescale 1ns / 1ps

`include "defines.vh"

module axi_master(
    input  wire         aclk,
    input  wire         aresetn,    // low active

    // ICache Interface
    output reg          ic_dev_rrdy  ,
    input  wire         ic_cpu_ren   ,
    input  wire [31:0]  ic_cpu_raddr ,
    output reg          ic_dev_rvalid,
    output reg  [`CACHE_BLK_SIZE-1:0] ic_dev_rdata,
    // DCache Write Data Interface
    output reg          dc_dev_wrdy  ,
    input  wire [ 3:0]  dc_cpu_wen   ,
    input  wire [31:0]  dc_cpu_waddr ,
    input  wire [31:0]  dc_cpu_wdata ,
    // DCache Read Data Interface
    output reg          dc_dev_rrdy  ,
    input  wire         dc_cpu_ren   ,
    input  wire [31:0]  dc_cpu_raddr ,
    output reg          dc_dev_rvalid,
    output reg  [`CACHE_BLK_SIZE-1:0] dc_dev_rdata,

    // AXI4 Master Interface
    // write address channel
    output wire [ 3:0]  m_axi_awid   ,
    output reg  [31:0]  m_axi_awaddr ,
    output reg  [ 7:0]  m_axi_awlen  ,
    output reg  [ 2:0]  m_axi_awsize ,
    output reg  [ 1:0]  m_axi_awburst,
    output wire [ 1:0]  m_axi_awlock ,
    output wire [ 3:0]  m_axi_awcache,
    output wire [ 2:0]  m_axi_awprot ,
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    // write data channel
    output wire [ 3:0]  m_axi_wid    ,
    output reg  [31:0]  m_axi_wdata  ,
    output reg  [ 3:0]  m_axi_wstrb  ,
    output wire         m_axi_wlast  ,
    output reg          m_axi_wvalid ,
    input  wire         m_axi_wready ,
    // write response channel
    input  wire [ 3:0]  m_axi_bid    ,
    output wire         m_axi_bready ,
    input  wire [ 1:0]  m_axi_bresp  ,
    input  wire         m_axi_bvalid ,
    // read address channel
    output wire [ 3:0]  m_axi_arid   ,
    output reg  [31:0]  m_axi_araddr ,
    output reg  [ 7:0]  m_axi_arlen  ,
    output reg  [ 2:0]  m_axi_arsize ,
    output reg  [ 1:0]  m_axi_arburst,
    output wire [ 1:0]  m_axi_arlock ,
    output wire [ 3:0]  m_axi_arcache,
    output wire [ 2:0]  m_axi_arprot ,
    output reg          m_axi_arvalid,
    input  wire         m_axi_arready,
    // read data channel
    input  wire [ 3:0]  m_axi_rid   ,
    output wire         m_axi_rready,
    input  wire [31:0]  m_axi_rdata ,
    input  wire [ 1:0]  m_axi_rresp ,
    input  wire         m_axi_rlast ,
    input  wire         m_axi_rvalid
);

    assign m_axi_awid    = 4'h8;
    assign m_axi_awlock  = 2'h0;
    assign m_axi_awcache = 4'h2;
    assign m_axi_awprot  = 3'h0;
    assign m_axi_wid     = 4'h8;
    assign m_axi_arid    = 4'h8;
    assign m_axi_arlock  = 2'h0;
    assign m_axi_arcache = 4'h2;
    assign m_axi_arprot  = 3'h0;

    wire has_dc_wr_req = dc_dev_wrdy & (dc_cpu_wen != 4'h0);
    
    wire [1:0] cpu_ren;

    reg [255:0] buffer;
    reg [ 31:0] cpu_raddr;
    reg [  3:0] cur_state;
    reg [  3:0] next_state;
    reg client;     // remember who's my client
   
    // Handle cache signal
    assign cpu_ren = {dc_cpu_ren, ic_cpu_ren};
    assign requested = |cpu_ren;
    
    localparam         IDLE = 4'd0;  // states
    localparam WAIT_ARREADY = 4'd1;
    localparam  WAIT_RVALID = 4'd2;
    localparam       LOAD_1 = 4'd3;
    localparam       LOAD_2 = 4'd4;
    localparam       LOAD_3 = 4'd5;
    localparam       LOAD_4 = 4'd6;
    localparam       LOAD_5 = 4'd7;
    localparam       LOAD_6 = 4'd8;
    localparam       LOAD_7 = 4'd9;
    localparam         FILL = 4'd10;
    
    localparam       ICACHE = 1'b0; // client
    localparam       DCACHE = 1'b1;
    
    localparam         INCR = 2'b01; // burst mode
    
    // FSM for the whole read process
    always@(posedge aclk or negedge aresetn) begin
        if (!aresetn) cur_state <= IDLE;
        else cur_state <= next_state;
    end
    
    always@(*) begin
        case (cur_state)
            IDLE:         next_state = requested     ? WAIT_ARREADY  : IDLE;
            WAIT_ARREADY: next_state = m_axi_arready ? WAIT_RVALID   : WAIT_ARREADY;
            WAIT_RVALID:  next_state = m_axi_rvalid  ? LOAD_1        : WAIT_RVALID;
            LOAD_1:       next_state = LOAD_2;
            LOAD_2:       next_state = LOAD_3;
            LOAD_3:       next_state = LOAD_4;
            LOAD_4:       next_state = LOAD_5;
            LOAD_5:       next_state = LOAD_6;
            LOAD_6:       next_state = LOAD_7;
            LOAD_7:       next_state = FILL;
            FILL:         next_state = IDLE;
            default:      next_state = IDLE;
        endcase
    end
    
    always@(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            {ic_dev_rrdy,   dc_dev_rrdy}    <= 2'b0;
            {ic_dev_rvalid, dc_dev_rvalid}  <= 2'b0;
            {ic_dev_rdata,  dc_dev_rdata}   <= 256'b0;
            buffer        <= 256'b0;
            m_axi_arvalid <= 1'b0;
        end
        case (cur_state)
            IDLE: begin
                if (requested) begin
                    {dc_dev_rrdy, ic_dev_rrdy} <= 2'b0; 
                    if (dc_cpu_ren) begin
                        client <= DCACHE;
                        cpu_raddr <= dc_cpu_raddr;
                    end else begin
                        client <= ICACHE;
                        cpu_raddr <= ic_cpu_raddr;
                    end
                end else begin
                    {dc_dev_rrdy, ic_dev_rrdy}   <= 2'b11;
                    {dc_dev_rvalid, ic_dev_rvalid} <= 2'b0;
                end
             end
             
             WAIT_ARREADY: begin
                if (~m_axi_arready) begin
                    m_axi_araddr  <= cpu_raddr;
                    m_axi_arlen   <= 8'd7;
                    m_axi_arsize  <= 3'd2;
                    m_axi_arburst <= INCR;
                    m_axi_arvalid <= 1'b1;
                end else begin
                    m_axi_arvalid <= 1'b0;
                end
             end
             
             WAIT_RVALID: begin
                if (m_axi_rvalid) buffer[31:0] <= m_axi_rdata;
             end
             
             LOAD_1: buffer[63  : 32]  <= m_axi_rdata;
             LOAD_2: buffer[95  : 64]  <= m_axi_rdata;
             LOAD_3: buffer[127 : 96]  <= m_axi_rdata;
             LOAD_4: buffer[159 : 128] <= m_axi_rdata;
             LOAD_5: buffer[191 : 160] <= m_axi_rdata;
             LOAD_6: buffer[223 : 192] <= m_axi_rdata;
             LOAD_7: buffer[255 : 224] <= m_axi_rdata;
             
             FILL: begin
                {dc_dev_rrdy, ic_dev_rrdy} <= 2'b11;
                if (client == DCACHE) begin
                    dc_dev_rdata <= buffer;
                    dc_dev_rvalid <= 1'b1;
                end else begin
                    ic_dev_rdata <= buffer;
                    ic_dev_rvalid <= 1'b1;
                end
             end
              
             default: {ic_dev_rrdy, dc_dev_rrdy} <= 2'b00;
             
        endcase
    end
        

    assign m_axi_rready = !aresetn ? 1'b0 : 1'b1;



    /******** ��Ҫ�޸����´��� ********/
    ///////////////////////////////////////////////////////////////////////////
    // write address channel
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_awaddr  <= 32'h0;
            m_axi_awvalid <= 1'b0;
        end else begin
            if (m_axi_awvalid & m_axi_awready) begin
                m_axi_awvalid <= 1'b0;
                m_axi_awlen   <= 8'h0;
                m_axi_awsize  <= 3'h0;
                m_axi_awburst <= 2'h0;
            end else if (has_dc_wr_req) begin
                m_axi_awaddr  <= dc_cpu_waddr;
                m_axi_awlen   <= 8'h1 - 1;      // 1 packages each transaction
                m_axi_awsize  <= 3'h2;          // 2^2 bytes per package
                m_axi_awburst <= 2'h1;          // INCR addressing mode
                m_axi_awvalid <= 1'b1;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // write data channel
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_wdata  <= 32'h0;
            m_axi_wstrb  <= 4'h0;
            m_axi_wvalid <= 1'b0;
        end else begin
            if (m_axi_wvalid & m_axi_wready) begin
                m_axi_wvalid <= 1'b0;
            end else if (has_dc_wr_req) begin
                m_axi_wdata  <= dc_cpu_wdata;
                m_axi_wstrb  <= dc_cpu_wen;
                m_axi_wvalid <= 1'b1;
            end
        end
    end

    assign m_axi_wlast = m_axi_wvalid;

    ///////////////////////////////////////////////////////////////////////////
    // write response channel
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            dc_dev_wrdy     <= 1'b1;
        end else begin
            if (m_axi_bvalid) begin
                dc_dev_wrdy <= 1'b1;
            end else if (has_dc_wr_req) begin
                dc_dev_wrdy <= 1'b0;
            end
        end
    end

    assign m_axi_bready = !aresetn ? 1'b0 : 1'b1;

endmodule