module core_top(
    input wire          aclk,
    input wire          aresetn,
    // input wire   [ 7:0] ext_int,    // vivado trace
    input wire   [ 7:0] intrpt,     // chiplab
    //AXI interface 
    //read reqest
    output wire  [ 3:0] arid,
    output wire  [31:0] araddr,
    output wire  [ 7:0] arlen,
    output wire  [ 2:0] arsize,
    output wire  [ 1:0] arburst,
    output wire  [ 1:0] arlock,
    output wire  [ 3:0] arcache,
    output wire  [ 2:0] arprot,
    output wire         arvalid,
    input  wire         arready,
    //read back
    input  wire  [ 3:0] rid,
    input  wire  [31:0] rdata,
    input  wire  [ 1:0] rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output wire         rready,
    //write request
    output wire  [ 3:0] awid,
    output wire  [31:0] awaddr,
    output wire  [ 7:0] awlen,
    output wire  [ 2:0] awsize,
    output wire  [ 1:0] awburst,
    output wire  [ 1:0] awlock,
    output wire  [ 3:0] awcache,
    output wire  [ 2:0] awprot,
    output wire         awvalid,
    input  wire         awready,
    //write data
    output wire  [ 3:0] wid,
    output wire  [31:0] wdata,
    output wire  [ 3:0] wstrb,
    output wire         wlast,
    output wire         wvalid,
    input  wire         wready,
    //write back
    input wire   [ 3:0] bid,
    input wire   [ 1:0] bresp,
    input wire          bvalid,
    output wire         bready,

    //debug
    input           break_point,    //无需实现功能，仅提供接口即可，输入1’b0
    input           infor_flag,     //无需实现功能，仅提供接口即可，输入1’b0
    input  [ 4:0]   reg_num,        //无需实现功能，仅提供接口即可，输入5’b0
    output          ws_valid,       //无需实现功能，仅提供接口即可
    output [31:0]   rf_rdata,       //无需实现功能，仅提供接口即可

    //debug info
    // // vivado trace
    // output wire[31:0] debug_wb_pc,
    // output wire[ 3:0] debug_wb_rf_we,
    // output wire[ 4:0] debug_wb_rf_wnum,
    // output wire[31:0] debug_wb_rf_wdata

    // chiplab
    output wire[31:0] debug0_wb_pc,
    output wire[ 3:0] debug0_wb_rf_wen,
    output wire[ 4:0] debug0_wb_rf_wnum,
    output wire[31:0] debug0_wb_rf_wdata
    // `ifdef CPU_2CMT                      // 双发射
    // ,
    // output wire[31:0] debug1_wb_pc,
    // output wire[ 3:0] debug1_wb_rf_wen,
    // output wire[ 4:0] debug1_wb_rf_wnum,
    // output wire[31:0] debug1_wb_rf_wdata
    // `endif
);


// ICache Interface
wire        cpu2ic_flush ;
wire        cpu2ic_pause ;
wire        cpu2ic_rreq  ;
wire [31:0] cpu2ic_addr  ;
wire        ic2cpu_valid ;
wire [31:0] ic2cpu_inst  ;
wire        ic2cpu_stall;
wire        dev2ic_rrdy  ;
wire [ 3:0] ic2dev_ren   ;
wire [31:0] ic2dev_raddr ;
wire        dev2ic_rvalid;
wire [`CACHE_BLK_SIZE-1:0] dev2ic_rdata;

// DCache Interface
wire [ 3:0] cpu2dc_ren   ;
wire [31:0] cpu2dc_addr  ;
wire        dc2cpu_valid ;
wire [31:0] dc2cpu_rdata ;
wire [ 3:0] cpu2dc_wen   ;
wire [31:0] cpu2dc_wdata ;
wire        dc2cpu_wresp ;

wire        dev2dc_wrdy  ;
wire [ 3:0] dc2dev_wen   ;
wire [31:0] dc2dev_waddr ;
wire [31:0] dc2dev_wdata ;
wire        dev2dc_rrdy  ;
wire [ 3:0] dc2dev_ren   ;
wire [31:0] dc2dev_raddr ;
wire        dev2dc_rvalid;
wire [`CACHE_BLK_SIZE-1:0] dev2dc_rdata;

myCPU u_mycpu (
    .cpu_rstn   (aresetn),
    .cpu_clk    (aclk),
    .is_hwi     (intrpt),

    // Instruction Fetch Interface
    .ifetch_stall   (ic2cpu_stall),
    .ifetch_rreq    (cpu2ic_rreq ),
    .ifetch_addr    (cpu2ic_addr ),
    .ifetch_valid   (ic2cpu_valid),
    .ifetch_inst    (ic2cpu_inst ),
    .pause_icache   (cpu2ic_pause),
    .branch_flush    (cpu2ic_flush),
    // Data Access Interface
    .daccess_ren    (cpu2dc_ren  ),
    .daccess_addr   (cpu2dc_addr ),
    .daccess_valid  (dc2cpu_valid),
    .daccess_rdata  (dc2cpu_rdata),
    .daccess_wen    (cpu2dc_wen  ),
    .daccess_wdata  (cpu2dc_wdata),
    .daccess_wresp  (dc2cpu_wresp),

   // Debug Interface with chiplab
   .debug_wb_pc        (debug0_wb_pc),
   .debug_wb_ena       (debug0_wb_rf_wen),
   .debug_wb_reg       (debug0_wb_rf_wnum),
   .debug_wb_value     (debug0_wb_rf_wdata)
    
    // // Debug Interface with vivado trace
    // .debug_wb_pc        (debug_wb_pc),
    // .debug_wb_ena       (debug_wb_rf_we),
    // .debug_wb_reg       (debug_wb_rf_wnum),
    // .debug_wb_value     (debug_wb_rf_wdata)
);

inst_cache U_icache (
    .cpu_clk        (aclk),
    .cpu_rstn       (aresetn),
    // Interface to CPU
    .inst_rreq      (cpu2ic_rreq),
    .branch_flush   (cpu2ic_flush),
    .pause_icache   (cpu2ic_pause),
    .icache_stall   (ic2cpu_stall),
    .inst_addr      (cpu2ic_addr),
    .inst_valid     (ic2cpu_valid),
    .inst_out       (ic2cpu_inst),
    // Interface to Bus
    .dev_rrdy       (dev2ic_rrdy),
    .cpu_ren        (ic2dev_ren),
    .cpu_raddr      (ic2dev_raddr),
    .dev_rvalid     (dev2ic_rvalid),
    .dev_rdata      (dev2ic_rdata)
);

data_cache U_dcache (
    .cpu_clk        (aclk),
    .cpu_rstn       (aresetn),
    // Interface to CPU
    .data_ren       (cpu2dc_ren),
    .data_addr      (cpu2dc_addr),
    .data_valid     (dc2cpu_valid),
    .data_rdata     (dc2cpu_rdata),
    .data_wen       (cpu2dc_wen),
    .data_wdata     (cpu2dc_wdata),
    .data_wresp     (dc2cpu_wresp),
    // Interface to Bus
    .dev_wrdy       (dev2dc_wrdy),
    .cpu_wen        (dc2dev_wen),
    .cpu_waddr      (dc2dev_waddr),
    .cpu_wdata      (dc2dev_wdata),
    .dev_rrdy       (dev2dc_rrdy),
    .cpu_ren        (dc2dev_ren),
    .cpu_raddr      (dc2dev_raddr),
    .dev_rvalid     (dev2dc_rvalid),
    .dev_rdata      (dev2dc_rdata)
);

axi_master U_aximaster (
    .aclk           (aclk),
    .aresetn        (aresetn),

    // ICache Interface
    .ic_dev_rrdy    (dev2ic_rrdy),
    .ic_cpu_ren     (|ic2dev_ren),
    .ic_cpu_raddr   (ic2dev_raddr),
    .ic_dev_rvalid  (dev2ic_rvalid),
    .ic_dev_rdata   (dev2ic_rdata),
    // DCache Interface
    .dc_dev_wrdy    (dev2dc_wrdy),
    .dc_cpu_wen     (dc2dev_wen),
    .dc_cpu_waddr   (dc2dev_waddr),
    .dc_cpu_wdata   (dc2dev_wdata),
    .dc_dev_rrdy    (dev2dc_rrdy),
    .dc_cpu_ren     (|dc2dev_ren),
    .dc_cpu_raddr   (dc2dev_raddr),
    .dc_dev_rvalid  (dev2dc_rvalid),
    .dc_dev_rdata   (dev2dc_rdata),

    // AXI4-Lite Master Interface
    // write address channel
    .m_axi_awid     (awid),
    .m_axi_awaddr   (awaddr),
    .m_axi_awlen    (awlen),
    .m_axi_awsize   (awsize),
    .m_axi_awburst  (awburst),
    .m_axi_awlock   (awlock),
    .m_axi_awcache  (awcache),
    .m_axi_awprot   (awprot),
    .m_axi_awready  (awready),
    .m_axi_awvalid  (awvalid),
    // write data channel
    .m_axi_wid      (wid),
    .m_axi_wdata    (wdata),
    .m_axi_wready   (wready),
    .m_axi_wstrb    (wstrb),
    .m_axi_wlast    (wlast),
    .m_axi_wvalid   (wvalid),
    // write response channel
    .m_axi_bid      (bid),
    .m_axi_bready   (bready),
    .m_axi_bresp    (bresp),
    .m_axi_bvalid   (bvalid),
    // read address channel
    .m_axi_arid     (arid),
    .m_axi_araddr   (araddr),
    .m_axi_arlen    (arlen),
    .m_axi_arsize   (arsize),
    .m_axi_arburst  (arburst),
    .m_axi_arlock   (arlock),
    .m_axi_arcache  (arcache),
    .m_axi_arprot   (arprot),
    .m_axi_arready  (arready),
    .m_axi_arvalid  (arvalid),
    // read data channel
    .m_axi_rid      (rid),
    .m_axi_rdata    (rdata),
    .m_axi_rready   (rready),
    .m_axi_rresp    (rresp),
    .m_axi_rlast    (rlast),
    .m_axi_rvalid   (rvalid)
);

endmodule