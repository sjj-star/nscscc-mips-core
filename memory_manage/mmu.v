`timescale 1ns / 1ps
`include "defs.vh"

module mmu(
    clk,
    reset,
    inst_cpu_valid,
    inst_cpu_ready,
    inst_cpu_addr,
    inst_cpu_rdata,
    
    data_cpu_valid,
    data_cpu_ready,
    data_cpu_wr,
    data_cpu_size,
    data_cpu_wstrb,
    data_cpu_addr,
    data_cpu_wdata,
    data_cpu_rdata,

    data_awid,
    data_awaddr,
    data_awlen,
    data_awsize,
    data_awburst,
    data_awvalid,
    data_awready,
    data_wid,
    data_wdata,
    data_wstrb,
    data_wlast,
    data_wvalid,
    data_wready,
    data_bid,
    data_bresp,
    data_bvalid,
    data_bready,
    data_arid,
    data_araddr,
    data_arlen,
    data_arsize,
    data_arburst,
    data_arvalid,
    data_arready,
    data_rid,
    data_rdata,
    data_rresp,
    data_rlast,
    data_rvalid,
    data_rready,
    inst_awid,
    inst_awaddr,
    inst_awlen,
    inst_awsize,
    inst_awburst,
    inst_awvalid,
    inst_awready,
    inst_wid,
    inst_wdata,
    inst_wstrb,
    inst_wlast,
    inst_wvalid,
    inst_wready,
    inst_bid,
    inst_bresp,
    inst_bvalid,
    inst_bready,
    inst_arid,
    inst_araddr,
    inst_arlen,
    inst_arsize,
    inst_arburst,
    inst_arvalid,
    inst_arready,
    inst_rid,
    inst_rdata,
    inst_rresp,
    inst_rlast,
    inst_rvalid,
    inst_rready 
);

input wire clk;
input wire reset;

input wire inst_cpu_valid;
output reg inst_cpu_ready;
input wire [31:0] inst_cpu_addr;
output reg [31:0] inst_cpu_rdata;

input wire data_cpu_valid;
output wire data_cpu_ready;
input wire data_cpu_wr;
input wire [1:0] data_cpu_size;
input wire [3:0] data_cpu_wstrb;
input wire [31:0] data_cpu_addr;
input wire [31:0] data_cpu_wdata;
output reg [31:0] data_cpu_rdata;

output wire [3 :0] data_awid   , inst_awid   ;
output wire [31:0] data_awaddr , inst_awaddr ;
output wire [3 :0] data_awlen  , inst_awlen  ;
output wire [2 :0] data_awsize , inst_awsize ;
output wire [1 :0] data_awburst, inst_awburst;
output reg         data_awvalid, inst_awvalid;
input  wire        data_awready, inst_awready;
output wire [3 :0] data_wid    , inst_wid    ;
output wire [31:0] data_wdata  , inst_wdata  ;
output wire [3 :0] data_wstrb  , inst_wstrb  ;
output reg         data_wlast  , inst_wlast  ;
output reg         data_wvalid , inst_wvalid ;
input  wire        data_wready , inst_wready ;
input  wire [3 :0] data_bid    , inst_bid    ;
input  wire [1 :0] data_bresp  , inst_bresp  ;
input  wire        data_bvalid , inst_bvalid ;
output wire        data_bready , inst_bready ;
output wire [3 :0] data_arid   , inst_arid   ;
output wire [31:0] data_araddr , inst_araddr ;
output wire [3 :0] data_arlen  , inst_arlen  ;
output wire [2 :0] data_arsize , inst_arsize ;
output wire [1 :0] data_arburst, inst_arburst;
output reg         data_arvalid, inst_arvalid;
input  wire        data_arready, inst_arready;
input  wire [3 :0] data_rid    , inst_rid    ;
input  wire [31:0] data_rdata  , inst_rdata  ;
input  wire [2 :0] data_rresp  , inst_rresp  ;
input  wire        data_rlast  , inst_rlast  ;
input  wire        data_rvalid , inst_rvalid ;
output wire        data_rready , inst_rready ;

reg [31:0] inst_mem_addr;
reg [31:0] data_mem_addr;

wire [31:0] kseg0_inst;
wire [31:0] kseg0_data;
assign kseg0_inst = {1'b0,inst_cpu_addr[30:0]};
assign kseg0_data = {1'b0,data_cpu_addr[30:0]};

wire [31:0] kseg1_inst;
wire [31:0] kseg1_data;
assign kseg1_inst = {3'b000,inst_cpu_addr[28:0]};
assign kseg1_data = {3'b000,data_cpu_addr[28:0]};

always @ (*)
begin
    case(inst_cpu_addr[31:29])
        `ADDR_SEG3:
            inst_mem_addr = inst_cpu_addr;
        `ADDR_SEG2:
            inst_mem_addr = inst_cpu_addr;
        `ADDR_SEG1:
            inst_mem_addr = kseg1_inst;
        `ADDR_SEG0:
            inst_mem_addr = kseg0_inst;
        default://kuseg
            inst_mem_addr = inst_cpu_addr;

    endcase
end

always @ (*)
begin
    case(data_cpu_addr[31:29])
        `ADDR_SEG3:
            data_mem_addr = data_cpu_addr;
        `ADDR_SEG2:
            data_mem_addr = data_cpu_addr;
        `ADDR_SEG1:
            data_mem_addr = kseg1_data;
        `ADDR_SEG0:
            data_mem_addr = kseg0_data;
        default://kuseg
            data_mem_addr = data_cpu_addr;
    endcase
end

/* 
 * States of AXI HandShak State Machine
 * IDLE: No transcation, can receive request of CPU
 * WAIT: The transcation is in-flighting on the channel, handshak don't over
 * HANDSHAK: The AXI Channel has handshak
 */
localparam IDLE = 2'd0;
localparam WAIT = 2'd1;
localparam HANDSHAK = 2'd2;

/* CPU Data Port, Start*/
reg data_cpu_wready, data_cpu_rready;
assign data_awid    = 4'b0;
assign data_awaddr  = data_mem_addr;
assign data_awlen   = 4'b0;
assign data_awsize  = {1'b0, data_cpu_size};
assign data_awburst = 2'b1;
assign data_wid     = 4'b0;
assign data_wdata   = data_cpu_wdata;
assign data_wstrb   = data_cpu_wstrb;
assign data_bready  = 1'b1;
assign data_arid    = 4'b0;
assign data_araddr  = data_mem_addr;
assign data_arlen   = 4'b0;
assign data_arsize  = {1'b0, data_cpu_size};
assign data_arburst = 2'b1;
assign data_rready  = 1'b1;

/* AXI Write transcation Handshak State Machine, Start */
reg [1:0] D_AW_S, D_W_S;
reg [1:0] D_AW_NS, D_W_NS;

always @(posedge clk) begin
    if(reset) begin
        D_AW_S <= IDLE;
        D_W_S  <= IDLE;
    end
    else begin
        D_AW_S <= D_AW_NS;
        D_W_S <= D_W_NS;
    end
end

always @* begin
    D_AW_NS = IDLE;
    data_awvalid = 1'b0;
    D_W_NS = IDLE;
    data_wvalid = 1'b0;
    data_wlast = 1'b0;
    data_cpu_wready = 1'b0;

    case({D_AW_S, D_W_S})
    {IDLE, IDLE}: begin
        data_awvalid = data_cpu_valid & data_cpu_wr;
        data_wvalid = data_cpu_valid & data_cpu_wr;
        data_wlast = data_cpu_valid & data_cpu_wr;

        if(data_awvalid & data_awready)
            D_AW_NS = HANDSHAK;
        else if(data_awvalid)
            D_AW_NS = WAIT;
        else
            D_AW_NS = IDLE;
        
        if(data_wvalid & data_wready)
            D_W_NS = HANDSHAK;
        else if(data_wvalid)
            D_W_NS = WAIT;
        else
            D_W_NS = IDLE;
    end
    {WAIT, WAIT}: begin
        data_awvalid = 1'b1;
        data_wvalid = 1'b1;
        data_wlast = 1'b1;
        if(data_awready)
            D_AW_NS = HANDSHAK;
        else
            D_AW_NS = WAIT;
        
        if(data_wready)
            D_W_NS = HANDSHAK;
        else
            D_W_NS = WAIT;
    end
    {HANDSHAK, WAIT}: begin
        data_awvalid = 1'b0;
        D_AW_NS = HANDSHAK;

        data_wvalid = 1'b1;
        data_wlast = 1'b1;
        if(data_wready)
            D_W_NS = HANDSHAK;
        else
            D_W_NS = WAIT;
    end
    {WAIT, HANDSHAK}: begin
        data_awvalid = 1'b1;
        if(data_awready)
            D_AW_NS = HANDSHAK;
        else
            D_AW_NS = WAIT;
        
        data_wvalid = 1'b0;
        data_wlast = 1'b0;
        D_W_NS = HANDSHAK;
    end
    {HANDSHAK, HANDSHAK}: begin
        if(data_bvalid) begin
            data_cpu_wready = 1'b1;
            D_AW_NS = IDLE;
            D_W_NS = IDLE;
        end
        else begin
            data_cpu_wready = 1'b0;
            D_AW_NS = HANDSHAK;
            D_W_NS = HANDSHAK;
        end
    end
    endcase
end
/* AXI Write transcation Handshak State Machine, End */

/* AXI Read transcation Handshak State Machine, Start */
reg [1:0] D_AR_S;
reg [1:0] D_AR_NS;

always @(posedge clk) begin
    if(reset) begin
        D_AR_S <= IDLE;
    end
    else begin
        D_AR_S <= D_AR_NS;
    end
end

always @* begin
    D_AR_NS = IDLE;
    data_arvalid = 1'b0;
    data_cpu_rdata = 32'b0;
    data_cpu_rready = 1'b0;

    case(D_AR_S)
    IDLE: begin
        data_arvalid = data_cpu_valid & (~data_cpu_wr);

        if(data_arvalid & data_arready)
            D_AR_NS = HANDSHAK;
        else if(data_arvalid)
            D_AR_NS = WAIT;
        else
            D_AR_NS = IDLE;
    end
    WAIT: begin
        data_arvalid = 1'b1;
        if(data_arready)
            D_AR_NS = HANDSHAK;
        else
            D_AR_NS = WAIT;
    end
    HANDSHAK: begin
        data_arvalid = 1'b0;

        if(data_rvalid & data_rlast) begin
            data_cpu_rdata = data_rdata;
            data_cpu_rready = 1'b1;
            D_AR_NS = IDLE;
        end
        else begin
            D_AR_NS = HANDSHAK;
        end
    end
    endcase
end

assign data_cpu_ready = data_cpu_wready | data_cpu_rready;
/* AXI Read transcation Handshak State Machine, End */
/* CPU Data Port, End*/

/* CPU Instruction Port, Start*/
assign inst_awid    = 4'b0;
assign inst_awaddr  = 32'b0;
assign inst_awlen   = 4'b0;
assign inst_awsize  = 3'b0;
assign inst_awburst = 2'b0;
assign inst_wid     = 4'b0;
assign inst_wdata   = 32'b0;
assign inst_wstrb   = 4'b0;
assign inst_bready  = 1'b0;
assign inst_arid    = 4'b0;
assign inst_araddr  = inst_mem_addr;
assign inst_arlen   = 4'b0;
assign inst_arsize  = 3'd2;
assign inst_arburst = 2'b1;
assign inst_rready  = 1'b1;

/* AXI Write transcation Handshak State Machine, Start */
always @(posedge clk) begin
    if(reset) begin
        inst_awvalid <= 1'b0;
        inst_wvalid <= 1'b0;
        inst_wlast <= 1'b0;
    end
end
/* AXI Write transcation Handshak State Machine, End */

/* AXI Read transcation Handshak State Machine, Start */
reg [1:0] I_AR_S;
reg [1:0] I_AR_NS;

always @(posedge clk) begin
    if(reset) begin
        I_AR_S <= IDLE;
    end
    else begin
        I_AR_S <= I_AR_NS;
    end
end

always @* begin
    I_AR_NS = IDLE;
    inst_arvalid = 1'b0;
    inst_cpu_rdata = 32'b0;
    inst_cpu_ready = 1'b0;

    case(I_AR_S)
    IDLE: begin
        inst_arvalid = inst_cpu_valid;

        if(inst_arvalid & inst_arready)
            I_AR_NS = HANDSHAK;
        else if(inst_arvalid)
            I_AR_NS = WAIT;
        else
            I_AR_NS = IDLE;
    end
    WAIT: begin
        inst_arvalid = 1'b1;
        if(inst_arready)
            I_AR_NS = HANDSHAK;
        else
            I_AR_NS = WAIT;
    end
    HANDSHAK: begin
        inst_arvalid = 1'b0;

        if(inst_rvalid & inst_rlast) begin
            inst_cpu_rdata = inst_rdata;
            inst_cpu_ready = 1'b1;
            I_AR_NS = IDLE;
        end
        else begin
            I_AR_NS = HANDSHAK;
        end
    end
    endcase
end
/* AXI Read transcation Handshak State Machine, End */
/* CPU Instruction Port, End*/

endmodule
