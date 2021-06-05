`timescale 1ns / 1ps
`include "defs.vh"

module mycpu_top(
    int,//high
    
    aclk,
    aresetn,//lowa
    
    arid,
    araddr,
    arlen,
    arsize,
    arburst,
    arlock,
    arcache,
    arprot,
    arvalid,
    arready,
    
    rid,
    rdata,
    rresp,
    rlast,
    rvalid,
    rready,
    
    awid,
    awaddr,
    awlen,
    awsize,
    awburst,
    awlock,
    awcache,
    awprot,
    awvalid,
    awready,
    
    wid,
    wdata,
    wstrb,
    wlast,
    wvalid,
    wready,
    
    bid,
    bresp,
    bvalid,
    bready,
    
    //debuginterface
    debug_wb_pc,
    debug_wb_rf_wen,
    debug_wb_rf_wnum,
    debug_wb_rf_wdata);

input wire [5:0] int;
input wire aclk;
input wire aresetn;
//axi
//ar
output wire [3 :0] arid;
output wire [31:0] araddr;
output wire [3 :0] arlen;
output wire [2 :0] arsize;
output wire [1 :0] arburst;
output wire [1 :0] arlock;
output wire [3 :0] arcache;
output wire [2 :0] arprot;
output wire        arvalid;
input  wire        arready;
//r
input  wire [3 :0] rid;
input  wire [31:0] rdata;
input  wire [1 :0] rresp;
input  wire        rlast;
input  wire        rvalid;
output wire        rready;
//aw
output wire [3 :0] awid;
output wire [31:0] awaddr;
output wire [3 :0] awlen;
output wire [2 :0] awsize;
output wire [1 :0] awburst;
output wire [1 :0] awlock;
output wire [3 :0] awcache;
output wire [2 :0] awprot;
output wire        awvalid;
input  wire        awready;
//w
output wire [3 :0] wid;
output wire [31:0] wdata;
output wire [3 :0] wstrb;
output wire        wlast;
output wire        wvalid;
input  wire        wready;
//b
input  wire [3 :0] bid;
input  wire [1 :0] bresp;
input  wire        bvalid;
output wire        bready;

//debug interface
output wire [31:0]  debug_wb_pc;
output wire [3:0]   debug_wb_rf_wen;
output wire [4:0]   debug_wb_rf_wnum;
output wire [31:0]  debug_wb_rf_wdata;

wire reset = ~aresetn;

wire instruction_valid;
wire instruction_ready;
wire [31:0] instruction_addr;
wire [31:0] instruction;

wire data_cpu_valid;
wire data_cpu_ready;
wire data_cpu_wr;
wire [1:0] data_cpu_size;
wire [3:0] data_cpu_wstrb;
wire [31:0] data_cpu_addr;
wire [31:0] data_cpu_wdata;
wire [31:0] data_cpu_rdata;

wire [3 :0] data_awid   , inst_awid   ;
wire [31:0] data_awaddr , inst_awaddr ;
wire [3 :0] data_awlen  , inst_awlen  ;
wire [2 :0] data_awsize , inst_awsize ;
wire [1 :0] data_awburst, inst_awburst;
wire        data_awvalid, inst_awvalid;
wire        data_awready, inst_awready;
wire [3 :0] data_wid    , inst_wid    ;
wire [31:0] data_wdata  , inst_wdata  ;
wire [3 :0] data_wstrb  , inst_wstrb  ;
wire        data_wlast  , inst_wlast  ;
wire        data_wvalid , inst_wvalid ;
wire        data_wready , inst_wready ;
wire [3 :0] data_bid    , inst_bid    ;
wire [1 :0] data_bresp  , inst_bresp  ;
wire        data_bvalid , inst_bvalid ;
wire        data_bready , inst_bready ;
wire [3 :0] data_arid   , inst_arid   ;
wire [31:0] data_araddr , inst_araddr ;
wire [3 :0] data_arlen  , inst_arlen  ;
wire [2 :0] data_arsize , inst_arsize ;
wire [1 :0] data_arburst, inst_arburst;
wire        data_arvalid, inst_arvalid;
wire        data_arready, inst_arready;
wire [3 :0] data_rid    , inst_rid    ;
wire [31:0] data_rdata  , inst_rdata  ;
wire [2 :0] data_rresp  , inst_rresp  ;
wire        data_rlast  , inst_rlast  ;
wire        data_rvalid , inst_rvalid ;
wire        data_rready , inst_rready ;

pipeline_cpu cpu(
    .clk                   (aclk             ),
    .reset                 (reset            ),
    .int                   (int              ),
    .instruction_valid     (instruction_valid),
    .instruction_ready     (instruction_ready),
    .instruction_addr      (instruction_addr ),
    .instruction           (instruction      ),
    .data_valid            (data_cpu_valid   ),
    .data_ready            (data_cpu_ready   ),
    .data_wr               (data_cpu_wr      ),
    .data_size             (data_cpu_size    ),
    .data_wstrb            (data_cpu_wstrb   ),
    .data_addr             (data_cpu_addr    ),
    .data_wdata            (data_cpu_wdata   ),
    .data_rdata            (data_cpu_rdata   ),
    .debug_wb_pc           (debug_wb_pc      ),
    .debug_wb_rf_wen       (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum      (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata     (debug_wb_rf_wdata)
);

mmu memory_management_unit(
    .clk            (aclk             ),
    .reset          (reset            ),
    .inst_cpu_valid (instruction_valid),
    .inst_cpu_ready (instruction_ready),
    .inst_cpu_addr  (instruction_addr ),
    .inst_cpu_rdata (instruction      ),
    .data_cpu_valid (data_cpu_valid   ),
    .data_cpu_ready (data_cpu_ready   ),
    .data_cpu_wr    (data_cpu_wr      ),
    .data_cpu_size  (data_cpu_size    ),
    .data_cpu_wstrb (data_cpu_wstrb   ),
    .data_cpu_addr  (data_cpu_addr    ),
    .data_cpu_wdata (data_cpu_wdata   ),
    .data_cpu_rdata (data_cpu_rdata   ),
    .data_awid      (data_awid        ),
    .data_awaddr    (data_awaddr      ),
    .data_awlen     (data_awlen       ),
    .data_awsize    (data_awsize      ),
    .data_awburst   (data_awburst     ),
    .data_awvalid   (data_awvalid     ),
    .data_awready   (data_awready     ),
    .data_wid       (data_wid         ),
    .data_wdata     (data_wdata       ),
    .data_wstrb     (data_wstrb       ),
    .data_wlast     (data_wlast       ),
    .data_wvalid    (data_wvalid      ),
    .data_wready    (data_wready      ),
    .data_bid       (data_bid         ),
    .data_bresp     (data_bresp       ),
    .data_bvalid    (data_bvalid      ),
    .data_bready    (data_bready      ),
    .data_arid      (data_arid        ),
    .data_araddr    (data_araddr      ),
    .data_arlen     (data_arlen       ),
    .data_arsize    (data_arsize      ),
    .data_arburst   (data_arburst     ),
    .data_arvalid   (data_arvalid     ),
    .data_arready   (data_arready     ),
    .data_rid       (data_rid         ),
    .data_rdata     (data_rdata       ),
    .data_rresp     (data_rresp       ),
    .data_rlast     (data_rlast       ),
    .data_rvalid    (data_rvalid      ),
    .data_rready    (data_rready      ),
    .inst_awid      (inst_awid        ),
    .inst_awaddr    (inst_awaddr      ),
    .inst_awlen     (inst_awlen       ),
    .inst_awsize    (inst_awsize      ),
    .inst_awburst   (inst_awburst     ),
    .inst_awvalid   (inst_awvalid     ),
    .inst_awready   (inst_awready     ),
    .inst_wid       (inst_wid         ),
    .inst_wdata     (inst_wdata       ),
    .inst_wstrb     (inst_wstrb       ),
    .inst_wlast     (inst_wlast       ),
    .inst_wvalid    (inst_wvalid      ),
    .inst_wready    (inst_wready      ),
    .inst_bid       (inst_bid         ),
    .inst_bresp     (inst_bresp       ),
    .inst_bvalid    (inst_bvalid      ),
    .inst_bready    (inst_bready      ),
    .inst_arid      (inst_arid        ),
    .inst_araddr    (inst_araddr      ),
    .inst_arlen     (inst_arlen       ),
    .inst_arsize    (inst_arsize      ),
    .inst_arburst   (inst_arburst     ),
    .inst_arvalid   (inst_arvalid     ),
    .inst_arready   (inst_arready     ),
    .inst_rid       (inst_rid         ),
    .inst_rdata     (inst_rdata       ),
    .inst_rresp     (inst_rresp       ),
    .inst_rlast     (inst_rlast       ),
    .inst_rvalid    (inst_rvalid      ),
    .inst_rready    (inst_rready      )
);

axi_crossbar_core2mem cpu_axi_crossbar(
    .aclk          (aclk                        ),
    .aresetn       (aresetn                     ),
    .s_axi_awid    ({data_awid   , inst_awid   }),
    .s_axi_awaddr  ({data_awaddr , inst_awaddr }),
    .s_axi_awlen   ({data_awlen  , inst_awlen  }),
    .s_axi_awsize  ({data_awsize , inst_awsize }),
    .s_axi_awburst ({data_awburst, inst_awburst}),
    .s_axi_awlock  (4'b0                        ),
    .s_axi_awcache (8'b0                        ),
    .s_axi_awprot  (6'b0                        ),
    .s_axi_awqos   (8'b0                        ),
    .s_axi_awvalid ({data_awvalid, inst_awvalid}),
    .s_axi_awready ({data_awready, inst_awready}),
    .s_axi_wid     ({data_wid    , inst_wid    }),
    .s_axi_wdata   ({data_wdata  , inst_wdata  }),
    .s_axi_wstrb   ({data_wstrb  , inst_wstrb  }),
    .s_axi_wlast   ({data_wlast  , inst_wlast  }),
    .s_axi_wvalid  ({data_wvalid , inst_wvalid }),
    .s_axi_wready  ({data_wready , inst_wready }),
    .s_axi_bid     ({data_bid    , inst_bid    }),
    .s_axi_bresp   ({data_bresp  , inst_bresp  }),
    .s_axi_bvalid  ({data_bvalid , inst_bvalid }),
    .s_axi_bready  ({data_bready , inst_bready }),
    .s_axi_arid    ({data_arid   , inst_arid   }),
    .s_axi_araddr  ({data_araddr , inst_araddr }),
    .s_axi_arlen   ({data_arlen  , inst_arlen  }),
    .s_axi_arsize  ({data_arsize , inst_arsize }),
    .s_axi_arburst ({data_arburst, inst_arburst}),
    .s_axi_arlock  (4'b0                        ),
    .s_axi_arcache (8'b0                        ),
    .s_axi_arprot  (6'b0                        ),
    .s_axi_arqos   (8'b0                        ),
    .s_axi_arvalid ({data_arvalid, inst_arvalid}),
    .s_axi_arready ({data_arready, inst_arready}),
    .s_axi_rid     ({data_rid    , inst_rid    }),
    .s_axi_rdata   ({data_rdata  , inst_rdata  }),
    .s_axi_rresp   ({data_rresp  , inst_rresp  }),
    .s_axi_rlast   ({data_rlast  , inst_rlast  }),
    .s_axi_rvalid  ({data_rvalid , inst_rvalid }),
    .s_axi_rready  ({data_rready , inst_rready }),
    .m_axi_awid    (awid                        ),
    .m_axi_awaddr  (awaddr                      ),
    .m_axi_awlen   (awlen                       ),
    .m_axi_awsize  (awsize                      ),
    .m_axi_awburst (awburst                     ),
    .m_axi_awlock  (awlock                      ),
    .m_axi_awcache (awcache                     ),
    .m_axi_awprot  (awprot                      ),
    .m_axi_awqos   (                            ),
    .m_axi_awvalid (awvalid                     ),
    .m_axi_awready (awready                     ),
    .m_axi_wid     (wid                         ),
    .m_axi_wdata   (wdata                       ),
    .m_axi_wstrb   (wstrb                       ),
    .m_axi_wlast   (wlast                       ),
    .m_axi_wvalid  (wvalid                      ),
    .m_axi_wready  (wready                      ),
    .m_axi_bid     (bid                         ),
    .m_axi_bresp   (bresp                       ),
    .m_axi_bvalid  (bvalid                      ),
    .m_axi_bready  (bready                      ),
    .m_axi_arid    (arid                        ),
    .m_axi_araddr  (araddr                      ),
    .m_axi_arlen   (arlen                       ),
    .m_axi_arsize  (arsize                      ),
    .m_axi_arburst (arburst                     ),
    .m_axi_arlock  (arlock                      ),
    .m_axi_arcache (arcache                     ),
    .m_axi_arprot  (arprot                      ),
    .m_axi_arqos   (                            ),
    .m_axi_arvalid (arvalid                     ),
    .m_axi_arready (arready                     ),
    .m_axi_rid     (rid                         ),
    .m_axi_rdata   (rdata                       ),
    .m_axi_rresp   (rresp                       ),
    .m_axi_rlast   (rlast                       ),
    .m_axi_rvalid  (rvalid                      ),
    .m_axi_rready  (rready                      )
);
//assign awid = 4'b0;
//assign wid = 4'b0;
//assign arid = 4'b0;

endmodule
