`include "defines.vh"
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
    `ifdef CPU_2CMT                      // 双发射
    ,
    output wire[31:0] debug1_wb_pc,
    output wire[ 3:0] debug1_wb_rf_wen,
    output wire[ 4:0] debug1_wb_rf_wnum,
    output wire[31:0] debug1_wb_rf_wdata
    `endif
);
wire reset = ~aresetn;

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

`ifdef DIFFTEST_EN
//mydifftest_signal
wire debug0_wb_valid;
wire [31:0] debug0_wb_rf_inst;
wire [2:0] wb_ext_op;
wire [3:0] wb_we;
wire [31:0] da_addr;
//end of mydifftest_signal
// difftest
// from wb_stage
wire            ws_valid_diff       ;
wire            cnt_inst_diff       ;
wire    [63:0]  timer_64_diff       ;
wire    [ 7:0]  inst_ld_en_diff     ;
wire    [31:0]  ld_paddr_diff       ;
wire    [31:0]  ld_vaddr_diff       ;
wire    [ 7:0]  inst_st_en_diff     ;
wire    [31:0]  st_paddr_diff       ;
wire    [31:0]  st_vaddr_diff       ;
wire    [31:0]  st_data_diff        ;
wire            csr_rstat_en_diff   ;
wire    [31:0]  csr_data_diff       ;

wire inst_valid_diff = ws_valid_diff;
reg             cmt_valid           ;
reg             cmt_cnt_inst        ;
reg     [63:0]  cmt_timer_64        ;
reg     [ 7:0]  cmt_inst_ld_en      ;
reg     [31:0]  cmt_ld_paddr        ;
reg     [31:0]  cmt_ld_vaddr        ;
reg     [ 7:0]  cmt_inst_st_en      ;
reg     [31:0]  cmt_st_paddr        ;
reg     [31:0]  cmt_st_vaddr        ;
reg     [31:0]  cmt_st_data         ;
reg             cmt_csr_rstat_en    ;
reg     [31:0]  cmt_csr_data        ;

reg             cmt_wen             ;
reg     [ 7:0]  cmt_wdest           ;
reg     [31:0]  cmt_wdata           ;
reg     [31:0]  cmt_pc              ;
reg     [31:0]  cmt_inst            ;

reg             cmt_excp_flush      ;
reg             cmt_ertn            ;
reg     [5:0]   cmt_csr_ecode       ;
reg             cmt_tlbfill_en      ;
reg     [4:0]   cmt_rand_index      ;

// to difftest debug
reg             trap                ;
reg     [ 7:0]  trap_code           ;
reg     [63:0]  cycleCnt            ;
reg     [63:0]  instrCnt            ;

// from regfile
wire    [31:0]  regs[31:1]          ;

// from csr
wire    [31:0]  csr_crmd_diff_0     ;
wire    [31:0]  csr_prmd_diff_0     ;
wire    [31:0]  csr_ectl_diff_0     ;
wire    [31:0]  csr_estat_diff_0    ;
wire    [31:0]  csr_era_diff_0      ;
wire    [31:0]  csr_badv_diff_0     ;
wire	[31:0]  csr_eentry_diff_0   ;
wire 	[31:0]  csr_tlbidx_diff_0   ;
wire 	[31:0]  csr_tlbehi_diff_0   ;
wire 	[31:0]  csr_tlbelo0_diff_0  ;
wire 	[31:0]  csr_tlbelo1_diff_0  ;
wire 	[31:0]  csr_asid_diff_0     ;
wire 	[31:0]  csr_save0_diff_0    ;
wire 	[31:0]  csr_save1_diff_0    ;
wire 	[31:0]  csr_save2_diff_0    ;
wire 	[31:0]  csr_save3_diff_0    ;
wire 	[31:0]  csr_tid_diff_0      ;
wire 	[31:0]  csr_tcfg_diff_0     ;
wire 	[31:0]  csr_tval_diff_0     ;
wire 	[31:0]  csr_ticlr_diff_0    ;
wire 	[31:0]  csr_llbctl_diff_0   ;
wire 	[31:0]  csr_tlbrentry_diff_0;
wire 	[31:0]  csr_dmw0_diff_0     ;
wire 	[31:0]  csr_dmw1_diff_0     ;
wire 	[31:0]  csr_pgdl_diff_0     ;
wire 	[31:0]  csr_pgdh_diff_0     ;
`endif

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
   .debug_wb_valid     (debug0_wb_valid),
   .debug_wb_pc        (debug0_wb_pc),
   .debug_wb_ena       (debug0_wb_rf_wen),
   .debug_wb_reg       (debug0_wb_rf_wnum),
   .debug_wb_value     (debug0_wb_rf_wdata),
   .debug_wb_inst      (debug0_wb_rf_inst),

   //diff
    .wb_ext_op        (wb_ext_op),
    .wb_we            (wb_we),
    .da_addr    (da_addr),
    .rf_to_diff (regs)
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



assign inst_ld_en_diff = {2'b0, wb_ext_op == `RAM_EXT_LL, wb_ext_op == `RAM_EXT_W, wb_ext_op == `RAM_EXT_HU,
                            wb_ext_op == `RAM_EXT_H, wb_ext_op == `RAM_EXT_BU, wb_ext_op == `RAM_EXT_B};
assign inst_st_en_diff = {4'b0, /*(mem_i[i].is_llw_scw && (mem_i[i].aluop == `ALU_SCW))*/1'b0,wb_we == `RAM_WE_W, 
                            wb_we == `RAM_WE_H, wb_we == `RAM_WE_B};
assign ld_paddr_diff = 32'd0;//未实现dcache和地址转换的接口，先置为0
assign st_paddr_diff = 32'd0;
assign st_data_diff = 32'd0;
assign ld_vaddr_diff = da_addr;//时序可能有问题?
assign st_vaddr_diff = da_addr;

`ifdef DIFFTEST_EN
always @(posedge aclk) begin
    if (reset) begin
        {cmt_valid, cmt_cnt_inst, cmt_timer_64, cmt_inst_ld_en, cmt_ld_paddr, cmt_ld_vaddr, cmt_inst_st_en, cmt_st_paddr, cmt_st_vaddr, cmt_st_data, cmt_csr_rstat_en, cmt_csr_data} <= 0;
        {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst} <= 0;
        {trap, trap_code, cycleCnt, instrCnt} <= 0;
    end else begin
        cmt_valid       <= debug0_wb_valid  /*ok*/        ;
        cmt_cnt_inst    <= 0 /*cnt指令未实现，为0*/            ;
        cmt_timer_64    <= 64'd0      /*未实现，0*/       ;
        cmt_inst_ld_en  <= inst_ld_en_diff   /*ok*/       ;
        cmt_ld_paddr    <= ld_paddr_diff     /*暂定为0*/       ;
        cmt_ld_vaddr    <= ld_vaddr_diff   /*ok*/         ;
        cmt_inst_st_en  <= inst_st_en_diff   /*ok*/       ;
        cmt_st_paddr    <= st_paddr_diff     /*暂定为0*/       ;
        cmt_st_vaddr    <= st_vaddr_diff   /*ok*/         ;
        cmt_st_data     <= st_data_diff     /*暂定为0*/        ;
        cmt_csr_rstat_en<= 1'b0    /*指令未实现，为0*/    ;
        cmt_csr_data    <= 32'd0    /*指令未实现，为0*/         ;

        cmt_wen     <=  debug0_wb_rf_wen/*ok*/            ;
        cmt_wdest   <=  {3'd0, debug0_wb_rf_wnum} /*ok*/  ;
        cmt_wdata   <=  debug0_wb_rf_wdata /*ok*/         ;
        cmt_pc      <=  debug0_wb_pc      /*ok*/          ;
        cmt_inst    <=  debug0_wb_rf_inst  /*ok*/            ;

        cmt_excp_flush  <= 0  /*未实现，0*/             ;
        cmt_ertn        <= 0  /*未实现，0*/                ;
        cmt_csr_ecode   <= 6'd0;             ;
        cmt_tlbfill_en  <= 0    /*未实现，0*/            ;
        cmt_rand_index  <= 0    /*未实现，0*/           ;

        trap            <= 0    /*ok*/                    ;
        trap_code       <= regs[10][7:0]/*ok*/          ;
        cycleCnt        <= cycleCnt + 1 /*ok*/        ;
        instrCnt        <= instrCnt + inst_valid_diff    /*ok*/;
    end
end

DifftestInstrCommit DifftestInstrCommit(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_valid      ),
    .pc                 (cmt_pc         ),
    .instr              (cmt_inst       ),
    .skip               (0              ),
    .is_TLBFILL         (cmt_tlbfill_en ),
    .TLBFILL_index      (cmt_rand_index ),
    .is_CNTinst         (cmt_cnt_inst   ),
    .timer_64_value     (cmt_timer_64   ),
    .wen                (cmt_wen        ),
    .wdest              (cmt_wdest      ),
    .wdata              (cmt_wdata      ),
    .csr_rstat          (cmt_csr_rstat_en),
    .csr_data           (cmt_csr_data   )
);

DifftestExcpEvent DifftestExcpEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .excp_valid         (cmt_excp_flush ),
    .eret               (cmt_ertn       ),
    .intrNo             (csr_estat_diff_0[12:2]),
    .cause              (cmt_csr_ecode  ),
    .exceptionPC        (cmt_pc         ),
    .exceptionInst      (cmt_inst       )
);

DifftestTrapEvent DifftestTrapEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .valid              (trap           ),
    .code               (trap_code      ),
    .pc                 (cmt_pc         ),
    .cycleCnt           (cycleCnt       ),
    .instrCnt           (instrCnt       )
);

DifftestStoreEvent DifftestStoreEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_inst_st_en ),
    .storePAddr         (cmt_st_paddr   ),
    .storeVAddr         (cmt_st_vaddr   ),
    .storeData          (cmt_st_data    )
);

DifftestLoadEvent DifftestLoadEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_inst_ld_en ),
    .paddr              (cmt_ld_paddr   ),
    .vaddr              (cmt_ld_vaddr   )
);

DifftestCSRRegState DifftestCSRRegState(
    .clock              (aclk               ),
    .coreid             (0                  ),
    .crmd               (csr_crmd_diff_0    ),
    .prmd               (csr_prmd_diff_0    ),
    .euen               (0                  ),
    .ecfg               (csr_ectl_diff_0    ),
    .estat              (csr_estat_diff_0   ),
    .era                (csr_era_diff_0     ),
    .badv               (csr_badv_diff_0    ),
    .eentry             (csr_eentry_diff_0  ),
    .tlbidx             (csr_tlbidx_diff_0  ),
    .tlbehi             (csr_tlbehi_diff_0  ),
    .tlbelo0            (csr_tlbelo0_diff_0 ),
    .tlbelo1            (csr_tlbelo1_diff_0 ),
    .asid               (csr_asid_diff_0    ),
    .pgdl               (csr_pgdl_diff_0    ),
    .pgdh               (csr_pgdh_diff_0    ),
    .save0              (csr_save0_diff_0   ),
    .save1              (csr_save1_diff_0   ),
    .save2              (csr_save2_diff_0   ),
    .save3              (csr_save3_diff_0   ),
    .tid                (csr_tid_diff_0     ),
    .tcfg               (csr_tcfg_diff_0    ),
    .tval               (csr_tval_diff_0    ),
    .ticlr              (csr_ticlr_diff_0   ),
    .llbctl             (csr_llbctl_diff_0  ),
    .tlbrentry          (csr_tlbrentry_diff_0),
    .dmw0               (csr_dmw0_diff_0    ),
    .dmw1               (csr_dmw1_diff_0    )
);

DifftestGRegState DifftestGRegState(
    .clock              (aclk       ),
    .coreid             (0          ),
    .gpr_0              (0          ),
    .gpr_1              (regs[1]    ),
    .gpr_2              (regs[2]    ),
    .gpr_3              (regs[3]    ),
    .gpr_4              (regs[4]    ),
    .gpr_5              (regs[5]    ),
    .gpr_6              (regs[6]    ),
    .gpr_7              (regs[7]    ),
    .gpr_8              (regs[8]    ),
    .gpr_9              (regs[9]    ),
    .gpr_10             (regs[10]   ),
    .gpr_11             (regs[11]   ),
    .gpr_12             (regs[12]   ),
    .gpr_13             (regs[13]   ),
    .gpr_14             (regs[14]   ),
    .gpr_15             (regs[15]   ),
    .gpr_16             (regs[16]   ),
    .gpr_17             (regs[17]   ),
    .gpr_18             (regs[18]   ),
    .gpr_19             (regs[19]   ),
    .gpr_20             (regs[20]   ),
    .gpr_21             (regs[21]   ),
    .gpr_22             (regs[22]   ),
    .gpr_23             (regs[23]   ),
    .gpr_24             (regs[24]   ),
    .gpr_25             (regs[25]   ),
    .gpr_26             (regs[26]   ),
    .gpr_27             (regs[27]   ),
    .gpr_28             (regs[28]   ),
    .gpr_29             (regs[29]   ),
    .gpr_30             (regs[30]   ),
    .gpr_31             (regs[31]   )
);
`endif
endmodule