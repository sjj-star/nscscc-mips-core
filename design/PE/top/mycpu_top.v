`timescale 1ns / 1ps
`include "pe_defs.vh"

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

wire        inst_addr_valid;
wire        inst_addr_ready;
wire [31:0] inst_addr;
wire        inst_line_valid;
wire        inst_line_ready;
wire [31:0] inst_line;

wire data_cpu_valid;
wire data_cpu_ready;
wire data_cpu_wr;
wire [1:0] data_cpu_size;
wire [3:0] data_cpu_wstrb;
wire [31:0] data_cpu_addr;
wire [31:0] data_cpu_wdata;
wire [31:0] data_cpu_rdata;

wire [0 :0] data_awid   , inst_awid   ;
wire [31:0] data_awaddr , inst_awaddr ;
wire [7 :0] data_awlen  , inst_awlen  ;
wire [2 :0] data_awsize , inst_awsize ;
wire [1 :0] data_awburst, inst_awburst;
wire [3 :0] data_awcache, inst_awcache;
wire        data_awvalid, inst_awvalid;
wire        data_awready, inst_awready;
wire [31:0] data_wdata  , inst_wdata  ;
wire [3 :0] data_wstrb  , inst_wstrb  ;
wire        data_wlast  , inst_wlast  ;
wire        data_wvalid , inst_wvalid ;
wire        data_wready , inst_wready ;
wire [0 :0] data_bid    , inst_bid    ;
wire [1 :0] data_bresp  , inst_bresp  ;
wire        data_bvalid , inst_bvalid ;
wire        data_bready , inst_bready ;
wire [0 :0] data_arid   , inst_arid   ;
wire [31:0] data_araddr , inst_araddr ;
wire [7 :0] data_arlen  , inst_arlen  ;
wire [2 :0] data_arsize , inst_arsize ;
wire [1 :0] data_arburst, inst_arburst;
wire [3 :0] data_arcache, inst_arcache;
wire        data_arvalid, inst_arvalid;
wire        data_arready, inst_arready;
wire [0 :0] data_rid    , inst_rid    ;
wire [31:0] data_rdata  , inst_rdata  ;
wire [1 :0] data_rresp  , inst_rresp  ;
wire        data_rlast  , inst_rlast  ;
wire        data_rvalid , inst_rvalid ;
wire        data_rready , inst_rready ;

wire [3 :0] mem_awid   ;
wire [31:0] mem_awaddr ;
wire [7 :0] mem_awlen  ;
wire [2 :0] mem_awsize ;
wire [1 :0] mem_awburst;
wire [0 :0] mem_awlock ;
wire [3 :0] mem_awcache;
wire [2 :0] mem_awprot ;
wire [3 :0] mem_awqos  ;
wire        mem_awvalid;
wire        mem_awready;
wire [31:0] mem_wdata  ;
wire [3 :0] mem_wstrb  ;
wire        mem_wlast  ;
wire        mem_wvalid ;
wire        mem_wready ;
wire [3 :0] mem_bid    ;
wire [1 :0] mem_bresp  ;
wire        mem_bvalid ;
wire        mem_bready ;
wire [3 :0] mem_arid   ;
wire [31:0] mem_araddr ;
wire [7 :0] mem_arlen  ;
wire [2 :0] mem_arsize ;
wire [1 :0] mem_arburst;
wire [0 :0] mem_arlock ;
wire [3 :0] mem_arcache;
wire [2 :0] mem_arprot ;
wire [3 :0] mem_arqos  ;
wire        mem_arvalid;
wire        mem_arready;
wire [3 :0] mem_rid    ;
wire [31:0] mem_rdata  ;
wire [1 :0] mem_rresp  ;
wire        mem_rlast  ;
wire        mem_rvalid ;
wire        mem_rready ;

pipeline_cpu cpu(
    .clk                   (aclk             ),
    .reset                 (reset            ),
    .hw_int                (int              ),
    .inst_addr_valid       (inst_addr_valid  ),
    .inst_addr_ready       (inst_addr_ready  ),
    .inst_addr             (inst_addr        ),
    .inst_line_valid       (inst_line_valid  ),
    .inst_line_ready       (inst_line_ready  ),
    .inst_line             (inst_line        ),
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
    .clk                 (aclk             ),
    .reset               (reset            ),
    .inst_cpu_addr_valid (inst_addr_valid  ),
    .inst_cpu_addr_ready (inst_addr_ready  ),
    .inst_cpu_addr       (inst_addr        ),
    .inst_cpu_data_valid (inst_line_valid  ),
    .inst_cpu_data_ready (inst_line_ready  ),
    .inst_cpu_data       (inst_line        ),
    .data_cpu_valid      (data_cpu_valid   ),
    .data_cpu_ready      (data_cpu_ready   ),
    .data_cpu_wr         (data_cpu_wr      ),
    .data_cpu_size       (data_cpu_size    ),
    .data_cpu_wstrb      (data_cpu_wstrb   ),
    .data_cpu_addr       (data_cpu_addr    ),
    .data_cpu_wdata      (data_cpu_wdata   ),
    .data_cpu_rdata      (data_cpu_rdata   ),
    .data_awid           (data_awid        ),
    .data_awaddr         (data_awaddr      ),
    .data_awlen          (data_awlen       ),
    .data_awsize         (data_awsize      ),
    .data_awburst        (data_awburst     ),
    .data_awcache        (data_awcache     ),
    .data_awvalid        (data_awvalid     ),
    .data_awready        (data_awready     ),
    .data_wdata          (data_wdata       ),
    .data_wstrb          (data_wstrb       ),
    .data_wlast          (data_wlast       ),
    .data_wvalid         (data_wvalid      ),
    .data_wready         (data_wready      ),
    .data_bid            (data_bid         ),
    .data_bresp          (data_bresp       ),
    .data_bvalid         (data_bvalid      ),
    .data_bready         (data_bready      ),
    .data_arid           (data_arid        ),
    .data_araddr         (data_araddr      ),
    .data_arlen          (data_arlen       ),
    .data_arsize         (data_arsize      ),
    .data_arburst        (data_arburst     ),
    .data_arcache        (data_arcache     ),
    .data_arvalid        (data_arvalid     ),
    .data_arready        (data_arready     ),
    .data_rid            (data_rid         ),
    .data_rdata          (data_rdata       ),
    .data_rresp          (data_rresp       ),
    .data_rlast          (data_rlast       ),
    .data_rvalid         (data_rvalid      ),
    .data_rready         (data_rready      ),
    .inst_awid           (inst_awid        ),
    .inst_awaddr         (inst_awaddr      ),
    .inst_awlen          (inst_awlen       ),
    .inst_awsize         (inst_awsize      ),
    .inst_awburst        (inst_awburst     ),
    .inst_awcache        (inst_awcache     ),
    .inst_awvalid        (inst_awvalid     ),
    .inst_awready        (inst_awready     ),
    .inst_wdata          (inst_wdata       ),
    .inst_wstrb          (inst_wstrb       ),
    .inst_wlast          (inst_wlast       ),
    .inst_wvalid         (inst_wvalid      ),
    .inst_wready         (inst_wready      ),
    .inst_bid            (inst_bid         ),
    .inst_bresp          (inst_bresp       ),
    .inst_bvalid         (inst_bvalid      ),
    .inst_bready         (inst_bready      ),
    .inst_arid           (inst_arid        ),
    .inst_araddr         (inst_araddr      ),
    .inst_arlen          (inst_arlen       ),
    .inst_arsize         (inst_arsize      ),
    .inst_arburst        (inst_arburst     ),
    .inst_arcache        (inst_arcache     ),
    .inst_arvalid        (inst_arvalid     ),
    .inst_arready        (inst_arready     ),
    .inst_rid            (inst_rid         ),
    .inst_rdata          (inst_rdata       ),
    .inst_rresp          (inst_rresp       ),
    .inst_rlast          (inst_rlast       ),
    .inst_rvalid         (inst_rvalid      ),
    .inst_rready         (inst_rready      )
);

core_cache_axi L2_cache (
  .ACLK           ( aclk         ),
  .ARESETN        ( aresetn      ),
  .S0_AXI_AWID    ( inst_awid    ),
  .S0_AXI_AWADDR  ( inst_awaddr  ),
  .S0_AXI_AWLEN   ( inst_awlen   ),
  .S0_AXI_AWSIZE  ( inst_awsize  ),
  .S0_AXI_AWBURST ( inst_awburst ),
  .S0_AXI_AWLOCK  ( 1'b0         ),
  .S0_AXI_AWCACHE ( inst_awcache ),
  .S0_AXI_AWPROT  ( 3'b0         ),
  .S0_AXI_AWQOS   ( 4'b0         ),
  .S0_AXI_AWVALID ( inst_awvalid ),
  .S0_AXI_AWREADY ( inst_awready ),
  .S0_AXI_WDATA   ( inst_wdata   ),
  .S0_AXI_WSTRB   ( inst_wstrb   ),
  .S0_AXI_WLAST   ( inst_wlast   ),
  .S0_AXI_WVALID  ( inst_wvalid  ),
  .S0_AXI_WREADY  ( inst_wready  ),
  .S0_AXI_BRESP   ( inst_bresp   ),
  .S0_AXI_BID     ( inst_bid     ),
  .S0_AXI_BVALID  ( inst_bvalid  ),
  .S0_AXI_BREADY  ( inst_bready  ),
  .S0_AXI_ARID    ( inst_arid    ),
  .S0_AXI_ARADDR  ( inst_araddr  ),
  .S0_AXI_ARLEN   ( inst_arlen   ),
  .S0_AXI_ARSIZE  ( inst_arsize  ),
  .S0_AXI_ARBURST ( inst_arburst ),
  .S0_AXI_ARLOCK  ( 1'b0         ),
  .S0_AXI_ARCACHE ( inst_arcache ),
  .S0_AXI_ARPROT  ( 3'b0         ),
  .S0_AXI_ARQOS   ( 4'b0         ),
  .S0_AXI_ARVALID ( inst_arvalid ),
  .S0_AXI_ARREADY ( inst_arready ),
  .S0_AXI_RID     ( inst_rid     ),
  .S0_AXI_RDATA   ( inst_rdata   ),
  .S0_AXI_RRESP   ( inst_rresp   ),
  .S0_AXI_RLAST   ( inst_rlast   ),
  .S0_AXI_RVALID  ( inst_rvalid  ),
  .S0_AXI_RREADY  ( inst_rready  ),
  .S1_AXI_AWID    ( data_awid    ),
  .S1_AXI_AWADDR  ( data_awaddr  ),
  .S1_AXI_AWLEN   ( data_awlen   ),
  .S1_AXI_AWSIZE  ( data_awsize  ),
  .S1_AXI_AWBURST ( data_awburst ),
  .S1_AXI_AWLOCK  ( 1'b0         ),
  .S1_AXI_AWCACHE ( data_awcache ),
  .S1_AXI_AWPROT  ( 3'b0         ),
  .S1_AXI_AWQOS   ( 4'b0         ),
  .S1_AXI_AWVALID ( data_awvalid ),
  .S1_AXI_AWREADY ( data_awready ),
  .S1_AXI_WDATA   ( data_wdata   ),
  .S1_AXI_WSTRB   ( data_wstrb   ),
  .S1_AXI_WLAST   ( data_wlast   ),
  .S1_AXI_WVALID  ( data_wvalid  ),
  .S1_AXI_WREADY  ( data_wready  ),
  .S1_AXI_BRESP   ( data_bresp   ),
  .S1_AXI_BID     ( data_bid     ),
  .S1_AXI_BVALID  ( data_bvalid  ),
  .S1_AXI_BREADY  ( data_bready  ),
  .S1_AXI_ARID    ( data_arid    ),
  .S1_AXI_ARADDR  ( data_araddr  ),
  .S1_AXI_ARLEN   ( data_arlen   ),
  .S1_AXI_ARSIZE  ( data_arsize  ),
  .S1_AXI_ARBURST ( data_arburst ),
  .S1_AXI_ARLOCK  ( 1'b0         ),
  .S1_AXI_ARCACHE ( data_arcache ),
  .S1_AXI_ARPROT  ( 3'b0         ),
  .S1_AXI_ARQOS   ( 4'b0         ),
  .S1_AXI_ARVALID ( data_arvalid ),
  .S1_AXI_ARREADY ( data_arready ),
  .S1_AXI_RID     ( data_rid     ),
  .S1_AXI_RDATA   ( data_rdata   ),
  .S1_AXI_RRESP   ( data_rresp   ),
  .S1_AXI_RLAST   ( data_rlast   ),
  .S1_AXI_RVALID  ( data_rvalid  ),
  .S1_AXI_RREADY  ( data_rready  ),
  .M0_AXI_AWID    ( mem_awid    ),
  .M0_AXI_AWADDR  ( mem_awaddr  ),
  .M0_AXI_AWLEN   ( mem_awlen   ),
  .M0_AXI_AWSIZE  ( mem_awsize  ),
  .M0_AXI_AWBURST ( mem_awburst ),
  .M0_AXI_AWLOCK  ( mem_awlock  ),
  .M0_AXI_AWCACHE ( mem_awcache ),
  .M0_AXI_AWPROT  ( mem_awprot  ),
  .M0_AXI_AWQOS   ( mem_awqos   ),
  .M0_AXI_AWVALID ( mem_awvalid ),
  .M0_AXI_AWREADY ( mem_awready ),
  .M0_AXI_WDATA   ( mem_wdata   ),
  .M0_AXI_WSTRB   ( mem_wstrb   ),
  .M0_AXI_WLAST   ( mem_wlast   ),
  .M0_AXI_WVALID  ( mem_wvalid  ),
  .M0_AXI_WREADY  ( mem_wready  ),
  .M0_AXI_BRESP   ( mem_bresp   ),
  .M0_AXI_BID     ( mem_bid     ),
  .M0_AXI_BVALID  ( mem_bvalid  ),
  .M0_AXI_BREADY  ( mem_bready  ),
  .M0_AXI_ARID    ( mem_arid    ),
  .M0_AXI_ARADDR  ( mem_araddr  ),
  .M0_AXI_ARLEN   ( mem_arlen   ),
  .M0_AXI_ARSIZE  ( mem_arsize  ),
  .M0_AXI_ARBURST ( mem_arburst ),
  .M0_AXI_ARLOCK  ( mem_arlock  ),
  .M0_AXI_ARCACHE ( mem_arcache ),
  .M0_AXI_ARPROT  ( mem_arprot  ),
  .M0_AXI_ARQOS   ( mem_arqos   ),
  .M0_AXI_ARVALID ( mem_arvalid ),
  .M0_AXI_ARREADY ( mem_arready ),
  .M0_AXI_RID     ( mem_rid     ),
  .M0_AXI_RDATA   ( mem_rdata   ),
  .M0_AXI_RRESP   ( mem_rresp   ),
  .M0_AXI_RLAST   ( mem_rlast   ),
  .M0_AXI_RVALID  ( mem_rvalid  ),
  .M0_AXI_RREADY  ( mem_rready  )
);

axi4to3_converter core_axi_port (
  .aclk           ( aclk        ),
  .aresetn        ( aresetn     ),
  .s_axi_awid     ( mem_awid    ),
  .s_axi_awaddr   ( mem_awaddr  ),
  .s_axi_awlen    ( mem_awlen   ),
  .s_axi_awsize   ( mem_awsize  ),
  .s_axi_awburst  ( mem_awburst ),
  .s_axi_awlock   ( mem_awlock  ),
  .s_axi_awcache  ( mem_awcache ),
  .s_axi_awprot   ( mem_awprot  ),
  .s_axi_awregion ( 4'b0        ),
  .s_axi_awqos    ( mem_awqos   ),
  .s_axi_awvalid  ( mem_awvalid ),
  .s_axi_awready  ( mem_awready ),
  .s_axi_wdata    ( mem_wdata   ),
  .s_axi_wstrb    ( mem_wstrb   ),
  .s_axi_wlast    ( mem_wlast   ),
  .s_axi_wvalid   ( mem_wvalid  ),
  .s_axi_wready   ( mem_wready  ),
  .s_axi_bid      ( mem_bid     ),
  .s_axi_bresp    ( mem_bresp   ),
  .s_axi_bvalid   ( mem_bvalid  ),
  .s_axi_bready   ( mem_bready  ),
  .s_axi_arid     ( mem_arid    ),
  .s_axi_araddr   ( mem_araddr  ),
  .s_axi_arlen    ( mem_arlen   ),
  .s_axi_arsize   ( mem_arsize  ),
  .s_axi_arburst  ( mem_arburst ),
  .s_axi_arlock   ( mem_arlock  ),
  .s_axi_arcache  ( mem_arcache ),
  .s_axi_arprot   ( mem_arprot  ),
  .s_axi_arregion ( 4'b0        ),
  .s_axi_arqos    ( mem_arqos   ),
  .s_axi_arvalid  ( mem_arvalid ),
  .s_axi_arready  ( mem_arready ),
  .s_axi_rid      ( mem_rid     ),
  .s_axi_rdata    ( mem_rdata   ),
  .s_axi_rresp    ( mem_rresp   ),
  .s_axi_rlast    ( mem_rlast   ),
  .s_axi_rvalid   ( mem_rvalid  ),
  .s_axi_rready   ( mem_rready  ),
  .m_axi_awid     ( awid        ),
  .m_axi_awaddr   ( awaddr      ),
  .m_axi_awlen    ( awlen       ),
  .m_axi_awsize   ( awsize      ),
  .m_axi_awburst  ( awburst     ),
  .m_axi_awlock   ( awlock      ),
  .m_axi_awcache  ( awcache     ),
  .m_axi_awprot   ( awprot      ),
  .m_axi_awqos    (             ),
  .m_axi_awvalid  ( awvalid     ),
  .m_axi_awready  ( awready     ),
  .m_axi_wid      ( wid         ),
  .m_axi_wdata    ( wdata       ),
  .m_axi_wstrb    ( wstrb       ),
  .m_axi_wlast    ( wlast       ),
  .m_axi_wvalid   ( wvalid      ),
  .m_axi_wready   ( wready      ),
  .m_axi_bid      ( bid         ),
  .m_axi_bresp    ( bresp       ),
  .m_axi_bvalid   ( bvalid      ),
  .m_axi_bready   ( bready      ),
  .m_axi_arid     ( arid        ),
  .m_axi_araddr   ( araddr      ),
  .m_axi_arlen    ( arlen       ),
  .m_axi_arsize   ( arsize      ),
  .m_axi_arburst  ( arburst     ),
  .m_axi_arlock   ( arlock      ),
  .m_axi_arcache  ( arcache     ),
  .m_axi_arprot   ( arprot      ),
  .m_axi_arqos    (             ),
  .m_axi_arvalid  ( arvalid     ),
  .m_axi_arready  ( arready     ),
  .m_axi_rid      ( rid         ),
  .m_axi_rdata    ( rdata       ),
  .m_axi_rresp    ( rresp       ),
  .m_axi_rlast    ( rlast       ),
  .m_axi_rvalid   ( rvalid      ),
  .m_axi_rready   ( rready      )
);

endmodule

`include "pe_undefs.vh"

