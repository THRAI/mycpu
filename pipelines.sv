
    typedef struct packed {
        logic [31:0] debug_wb_pc;
        logic [31:0] debug_wb_inst;
        logic [3:0]  debug_wb_rf_wen;
        logic [4:0]  debug_wb_rf_wnum;
        logic [31:0] debug_wb_rf_wdata;

        logic inst_valid;
        logic cnt_inst;
        logic csr_rstat_en;
        logic [31:0] csr_data;

        logic excp_flush;
        logic ertn_flush;
        logic [5:0] ecode;

        logic [7:0] inst_st_en;
        bus32_t st_paddr;
        bus32_t st_vaddr;
        bus32_t st_data;

        logic [7:0] inst_ld_en;
        bus32_t ld_paddr;
        bus32_t ld_vaddr;

        logic tlbfill_en;
    } diff_t;