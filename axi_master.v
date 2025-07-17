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
    input  wire         m_axi_rvalid
);
    assign m_axi_awid    = 4'h8;
    assign m_axi_awlock  = 2'h0;
    assign m_axi_awcache = 4'h2;
    assign m_axi_awprot  = 3'h0;
    assign m_axi_wid     = 4'h8;
    wire has_dc_wr_req = dc_dev_wrdy & (dc_cpu_wen != 4'h0);

 ///////////////////////////////////////////////////////
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
                m_axi_wdata  <= dc_cpu_wdata;
                m_axi_wstrb  <= dc_cpu_wen;
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
    reg client;
    localparam CLIENT_ICACHE = 1'b0;
    localparam CLIENT_DCACHE = 1'b1;
    always @ (posedge aclk or negedge aresetn) begin
        if (!ar_handshake_done && requested) begin
            if (ic_cpu_ren) begin
                client      <= CLIENT_ICACHE;
            end else begin
                client      <= CLIENT_DCACHE;
            end
        end
    end

    reg read_issued;
    wire requested = (ic_cpu_ren | dc_cpu_ren) & ~read_issued;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_issued <= 1'b0;
        end else if (!ar_handshake_done && requested) begin
            read_issued <= 1'b1;
            ic_dev_rrdy <= 1'b0;
            dc_dev_rrdy <= 1'b0;
        end else if (m_axi_rvalid && m_axi_rlast) begin
            read_issued <= 1'b0;
            ic_dev_rrdy <= 1'b1;
            dc_dev_rrdy <= 1'b1;
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
            m_axi_arlen     <=  8'h3;
            m_axi_arsize    <=  3'd2;       //4-byte = word
            m_axi_arburst   <=  2'b01;      //INCR
            if (ic_cpu_ren) m_axi_araddr <= ic_cpu_raddr;
            else m_axi_araddr <= dc_cpu_raddr;
        end else if (m_axi_arready && m_axi_arvalid) begin
                ar_handshake_done   <=  1'b1;
                m_axi_arvalid       <=  1'b0;
                m_axi_arlen         <=  8'h0;
                m_axi_arsize        <=  3'd0;
                m_axi_arburst       <=  2'b0;
        end
    end

    ///////////////////////////////////////////////////////
    // R channel
    assign m_axi_rready = 1'b1;
    reg [`CACHE_BLK_SIZE - 1 : 0] buffer;
    reg [2:0] r_cnt;
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            r_cnt   <=  0;
            buffer  <=  0;
        end else if (m_axi_rvalid) begin
            buffer[32*r_cnt +: 32] <= m_axi_rdata;
            r_cnt <= r_cnt + 1;
        end
    end

    ///////////////////////////////////////////////////////
    // rlast & rvalid
    reg last_pack;
    always @ (posedge aclk or negedge aresetn) begin
        if (saw_last) last_pack <= 1'b1;
        else last_pack <= 1'b0;
    end

    wire saw_last = m_axi_rlast && m_axi_rvalid;

    ///////////////////////////////////////////////////////
    // Fill data & send response
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ic_dev_rvalid   <= 0;
            ic_dev_rvalid   <= 0;
            ic_dev_rrdy     <= 1'b1;
            dc_dev_rrdy     <= 1'b1;
        end else if (last_pack) begin
            if (client == CLIENT_ICACHE) begin
                ic_dev_rvalid   <= 1'b1;
                ic_dev_rdata    <= buffer;
                ic_dev_rrdy     <= 1'b1;
            end else begin
                dc_dev_rvalid   <= 1'b1;
                dc_dev_rdata    <= buffer;
                dc_dev_rrdy     <= 1'b1;
            end
            ar_handshake_done   <= 1'b0;
            r_cnt               <= 0;
        end else begin
            ic_dev_rvalid   <= 0;
            dc_dev_rvalid   <= 0;
        end
    end

endmodule

