`timescale 1ns/1ps

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
    input  wire         m_axi_rvalid,

    //I-uncached Read channel
	input wire          iucache_ren,
	input wire[31:0]    iucache_addr,
	output reg          iucache_rvalid,
	output reg[31:0]    iucache_rdata, 

    //D-uncache: Read Channel
    input wire          ducache_ren,
    input wire [31:0]   ducache_araddr,
    output reg          ducache_rvalid,   
    output reg [31:0]   ducache_rdata,

    //D-uncache: Write Channel
	input wire [ 3:0]	ducache_wen, // 我们模版是4位，学长的只有一位，这里暂且改成4位
	input wire [31:0]	ducache_wdata,
    input wire [31:0]   ducache_awaddr,
    output reg 			ducache_bvalid,
);
    assign m_axi_awid    = 4'h8;
    assign m_axi_awlock  = 2'h0;
    assign m_axi_awcache = 4'h2;  //TODO: change this for uncached version
    assign m_axi_awprot  = 3'h0;
    assign m_axi_wid     = 4'h8;

    ///////////////////////////////////////////////////////
    // write address channel
    wire has_dc_wr_req = ducache_wen & dc_dev_wrdy & (dc_cpu_wen != 4'h0);

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_awaddr  <= 32'h0;
            m_axi_awvalid <= 1'b0;
        end else begin
            if (m_axi_awvalid & m_axi_awready) begin
                m_axi_awvalid   <=  1'b0;
                m_axi_awlen     <=  8'h0;
                m_axi_awsize    <=  3'h0;
                m_axi_awburst   <=  2'h0;
            end else if (has_dc_wr_req) begin
                m_axi_awaddr    <=  dc_dev_wrdy ?dc_cpu_waddr : ducache_awaddr;
                m_axi_awlen     <=  8'h1 - 1;      // 1 packages each transaction
                m_axi_awsize    <=  3'h2;          // 2^2 bytes per package
                m_axi_awburst   <=  2'h1;          // INCR addressing mode
                m_axi_awvalid   <=  1'b1;
            end 

        end
    end

    /////////////////////////////////////////////////////
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
                m_axi_wdata  <= dc_dev_wrdy ? dc_cpu_wdata : ducache_wdata;
                m_axi_wstrb  <= dc_dev_wrdy ? dc_cpu_wen : ducache_wen;
                m_axi_wvalid <= 1'b1;
            end
        end
    end

    assign m_axi_wlast = m_axi_wvalid;

    //////////////////////////////////////////////////////
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

    //////////////////////////////////////////////////////
    // ICACHE / DCACHE read interfaces
    wire requested = (iucache_ren | ducache_ren | ic_cpu_ren | dc_cpu_ren) & ~read_issued;

    reg [2:0]client;
    localparam CLIENT_ICACHE = 3'o0;
    localparam CLIENT_DCACHE = 3'o1;
    localparam CLIENT_IUNCACHE = 3'o2;
    localparam CLIENT_DUNCACHE = 3'o3; 
    localparam CLIENT_IDLE   =  3'b100;
    
    wire [2:0]next_client = iucache_ren ?   CLIENT_IUNCACHE :
                            ducache_ren ?   CLIENT_DUNCACHE :
                            ic_cpu_ren  ?   CLIENT_ICACHE   :
                            dc_cpu_ren  ?   CLIENT_DCACHE   :
                            CLIENT_IDLE;      

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            client  <= CLIENT_IDLE;
        end else if (!ar_handshake_done && requested) begin
            client  <= next_client;
        end
    end
    wire read_use_uncached = client[1];

    reg read_issued;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_issued <= 1'b0;
        end else if (!ar_handshake_done && requested) begin
            read_issued <= 1'b1;
            ic_dev_rrdy <= 1'b0;
            dc_dev_rrdy <= 1'b0;
        end     
    end

    //////////////////////////////////////////////////////
    // AR channel
    reg ar_handshake_done;
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_arvalid       <=  1'b0;
            ar_handshake_done   <=  1'b0;
        end else if (!ar_handshake_done && requested) begin
            m_axi_arvalid   <=  1'b1;
            m_axi_arburst   <=  2'b01;      //INCR
            if (ic_cpu_ren | dc_cpu_ren) begin 
                m_axi_arlen     <=  8'h3;
                m_axi_arsize    <=  3'd2;       //4-byte = word
                m_axi_araddr    <=  ic_cpu_ren? ic_cpu_raddr : dc_cpu_raddr;
                m_axi_arcache   <=  4'b1111;
            end else if (iucache_ren | ducache_ren )begin
                m_axi_arlen     <=  8'h0;
                m_axi_arsize    <=  3'd2;
                m_axi_araddr    <=  iucache_ren ? iucache_addr : ducache_araddr;
                m_axi_arcache   <=  4'b0010;
            end
        end else if (m_axi_arready && m_axi_arvalid) begin
                ar_handshake_done   <=  1'b1;
                m_axi_arvalid       <=  1'b0;
                m_axi_arlen         <=  8'h0;
                m_axi_arsize        <=  3'd0;
                m_axi_arburst       <=  2'b0;
                m_axi_arcache       <=  4'b0000;
        end
    end

    ///////////////////////////////////////////////////////
    // R channel
    assign m_axi_rready = 1'b1;
    reg [`CACHE_BLK_SIZE - 1 : 0] buffer;
    reg [2:0] r_cnt;
    reg [31:0] uncached_buffer;
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            r_cnt   <=  0;
            buffer  <=  0;
        end else if (~read_use_uncached && m_axi_rvalid) begin
            buffer[32*r_cnt +: 32] <= m_axi_rdata;
            r_cnt <= r_cnt + 1;
        end else if (read_use_uncached) begin
            uncached_buffer <= m_axi_rdata;
        end
    end

    ///////////////////////////////////////////////////////
    // rlast & rvalid
    reg last_pack_done; 
    always @ (posedge aclk or negedge aresetn) begin
        last_pack_done  <= saw_last;
    end

    wire saw_last = m_axi_rlast && m_axi_rvalid;

    ///////////////////////////////////////////////////////
    // Fill data & send response
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ic_dev_rvalid   <= 0;
            dc_dev_rvalid   <= 0;
            ic_dev_rrdy     <= 1'b1;
            dc_dev_rrdy     <= 1'b1;
        end else if (last_pack_done) begin
            case (client)
                CLIENT_ICACHE: begin
                    ic_dev_rvalid   <= 1'b1;
                    ic_dev_rdata    <= buffer;
                end
                CLIENT_DCACHE: begin
                    dc_dev_rvalid   <= 1'b1;
                    dc_dev_rdata    <= buffer;
                end
                CLIENT_IUNCACHE: begin
                    iucache_rvalid  <= 1'b1;
                    iucache_rdata   <= uncached_buffer;
                end
                CLIENT_DUNCACHE: begin
                    ducache_rvalid  <= 1'b1;
                    ducache_rdata   <= uncached_buffer;
                end
            endcase
            ar_handshake_done   <= 0; //统一处理前面的
            r_cnt               <= 0;
            read_issued         <= 0;
            ic_dev_rrdy         <= 1'b1;
            dc_dev_rrdy         <= 1'b1;
        end else begin
            ic_dev_rvalid   <= 0;
            dc_dev_rvalid   <= 0;
        end
    end

endmodule

