`timescale 1ns / 1ps
`include "pe_defs.vh"

module inst_fetch(
//output
	//pc
    pc,
    pc_4,
	//BPU
	btb_way_vec,
	predict_is_branch,
	predict_pc,
	pht_history,
	pht_patten_tab,
	ghr,
	ghr_patten,
    //execption
    excep_code,
//input
    rst,
    clk,
    jump_branch_address,
    is_jump_branch,
	//BPU
	fail_branch,
	fail_way_vec,
	fill_is_ret,
	fill_is_link,
	fill_pht_history,
	fill_pht_patten_tab,
	fail_ghr,
	fill_ghr_patten,
	fill_ghr,
    //execption
    is_exception,
    is_excep_return,
    excep_return_pc,
	//fetch instruction interface
	inst_addr_valid,
	inst_addr_ready,
	inst_addr,
	inst_line_valid,
	inst_line_ready,
	inst_line,
	//pipe interface
	inst_valid,
	inst_ready,
	inst
);

parameter IFQ_ENTRY = 16;
parameter GLOBAL_WIDTH = 8;
parameter LOCAL_WIDTH = 4;
parameter BTB_SET_WIDTH = 6;
parameter BTB_WAY_NUM = 1;
parameter B_PATTEN_WIDTH = 2;
parameter G_PATTEN_WIDTH = 2;

localparam PHT_WIDTH = LOCAL_WIDTH+B_PATTEN_WIDTH*(2**LOCAL_WIDTH);

input wire rst;
input wire clk;
input wire [31:0] jump_branch_address;
input wire is_jump_branch;
input wire is_exception;
input wire is_excep_return;
input wire [31:0] excep_return_pc;
input wire [31:0] fail_branch;
input wire [BTB_WAY_NUM-1:0] fail_way_vec;
input wire fill_is_ret;
input wire fill_is_link;
input wire [LOCAL_WIDTH-1:0] fill_pht_history;
input wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] fill_pht_patten_tab;
input wire [GLOBAL_WIDTH-1:0] fail_ghr;
input wire [G_PATTEN_WIDTH-1:0] fill_ghr_patten;
input wire [GLOBAL_WIDTH-1:0] fill_ghr;
output wire [31:0] pc;
output wire [29:0] pc_4;
output wire [4:0] excep_code;
output wire [BTB_WAY_NUM-1:0] btb_way_vec;
output wire predict_is_branch;
output wire [31:0] predict_pc;
output wire [LOCAL_WIDTH-1:0] pht_history;
output wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] pht_patten_tab;
output wire [GLOBAL_WIDTH-1:0] ghr;
output wire [G_PATTEN_WIDTH-1:0] ghr_patten;

output wire inst_valid;
input wire inst_ready;
output wire [31:0] inst;

output wire inst_addr_valid;
input wire inst_addr_ready;
output wire [31:0] inst_addr;
input wire inst_line_valid;
output wire inst_line_ready;
input wire [31:0] inst_line;

wire is_exception_q;
wire is_excep_return_q;
wire [31:0] excep_return_pc_q;
wire is_jump_branch_q;
wire [31:0] jump_branch_address_q;
wire flush_req;
reg flushing;
wire bq_empty;
reg [31:0] prefetch_addr;
wire prefetch_full;
wire inst_empty;
wire pc_valid;
wire bpu_fail;
wire [31:0] bpu_fail_branch;
wire [BTB_WAY_NUM-1:0] bpu_fail_way_vec;
wire [31:0] bpu_fill_target;
wire [LOCAL_WIDTH-1:0] bpu_fill_pht_history;
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] bpu_fill_pht_patten_tab;
wire [GLOBAL_WIDTH-1:0] bpu_fail_ghr;
wire [G_PATTEN_WIDTH-1:0] bpu_fill_ghr_patten;
wire [GLOBAL_WIDTH-1:0] bpu_fill_ghr;
wire bpu_pc_vld;
reg [31:0] bpu_pc_in;
reg bpu_btb_vld;
wire [BTB_WAY_NUM-1:0] bpu_btb_way_vec;
wire bpu_predict_is_branch;
wire [31:0] bpu_predict_pc;
wire [LOCAL_WIDTH-1:0] bpu_pht_history;
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] bpu_pht_patten_tab;
wire [GLOBAL_WIDTH-1:0] bpu_ghr;
wire [G_PATTEN_WIDTH-1:0] bpu_ghr_patten;

fifo #(
	.RETIRE_MEM_EN(1),
    .WIDTH(1+1+32+1+32+32+BTB_WAY_NUM+2+PHT_WIDTH+GLOBAL_WIDTH+G_PATTEN_WIDTH+GLOBAL_WIDTH),
    .DEEP(2)
) branch_req_queue(
    .clk(clk),
    .reset(rst),
    .retire_mem({2{rst}}),
    .read((~bq_empty)&bpu_pc_vld),
    .write(is_exception|is_excep_return|is_jump_branch),
    .indata({is_exception,
	         is_excep_return,
			 excep_return_pc,
			 is_jump_branch,
			 jump_branch_address,
	         fail_branch,
	         fail_way_vec,
	         fill_is_ret,
	         fill_is_link,
	         fill_pht_history,
	         fill_pht_patten_tab,
	         fail_ghr,
	         fill_ghr_patten,
	         fill_ghr}),
    .outdata({is_exception_q,
	          is_excep_return_q,
	          excep_return_pc_q,
	          is_jump_branch_q,
	          jump_branch_address_q,
	          bpu_fail_branch,
	          bpu_fail_way_vec,
	          bpu_fill_is_ret,
	          bpu_fill_is_link,
	          bpu_fill_pht_history,
	          bpu_fill_pht_patten_tab,
	          bpu_fail_ghr,
	          bpu_fill_ghr_patten,
	          bpu_fill_ghr}),
    .empty(bq_empty),
    .full()
);

assign flush_req = is_exception_q|is_excep_return_q|is_jump_branch_q;
assign bpu_fail = is_jump_branch_q & bpu_pc_vld;
assign bpu_fill_target = jump_branch_address_q;
assign bpu_pc_vld = (~bpu_btb_vld) | (inst_addr_valid&inst_addr_ready);

always @ (*)
begin
	if(is_exception_q)
        prefetch_addr = `PC_EBASE;
	else if(is_excep_return_q)
        prefetch_addr = excep_return_pc_q;
	else if(is_jump_branch_q)
        prefetch_addr = jump_branch_address_q;
	else if(bpu_predict_is_branch)
		prefetch_addr = bpu_predict_pc;
	else
        prefetch_addr = {(bpu_pc_in[31:2] + 30'd1),bpu_pc_in[1:0]};
end

always @(posedge clk)
begin
	if(rst) begin
        bpu_pc_in <= `PC_INITIAL;
	end else begin
		if(bpu_pc_vld) begin
			bpu_pc_in <= prefetch_addr;
		end
	end
end

branch_predict_unit #(
	.GLOBAL_WIDTH(GLOBAL_WIDTH),
	.LOCAL_WIDTH(LOCAL_WIDTH),
	.BTB_SET_WIDTH(BTB_SET_WIDTH),
	.BTB_WAY_NUM(BTB_WAY_NUM),
	.B_PATTEN_WIDTH(B_PATTEN_WIDTH),
	.G_PATTEN_WIDTH(G_PATTEN_WIDTH)
) bpu(
//inputs
	.clk                 ( clk                        ),
	.reset               ( rst                        ),
	.pc_vld              ( bpu_pc_vld&(~flush_req)    ),
	.pc_in               ( bpu_pc_in                  ),
	.fail                ( bpu_fail                   ),
	.fail_branch         ( bpu_fail_branch            ),
	.fail_way_vec        ( bpu_fail_way_vec           ),
	.fill_target         ( bpu_fill_target            ),
	.fill_is_ret         ( bpu_fill_is_ret            ),
	.fill_is_link        ( bpu_fill_is_link           ),
	.fill_pht_history    ( bpu_fill_pht_history       ),
	.fill_pht_patten_tab ( bpu_fill_pht_patten_tab    ),
	.fail_ghr            ( bpu_fail_ghr               ),
	.fill_ghr_patten     ( bpu_fill_ghr_patten        ),
	.fill_ghr            ( bpu_fill_ghr               ),
	.btb_vld             ( bpu_btb_vld                ),
//outputs
	.pc_out              ( inst_addr                  ),
	.btb_way_vec         ( bpu_btb_way_vec            ),
	.predict_is_branch   ( bpu_predict_is_branch      ),
	.predict_pc          ( bpu_predict_pc             ),
	.predict_is_ret      ( bpu_predict_is_ret         ),
	.predict_is_link     ( bpu_predict_is_link        ),
	.pht_history         ( bpu_pht_history            ),
	.pht_patten_tab      ( bpu_pht_patten_tab         ),
	.ghr                 ( bpu_ghr                    ),
	.ghr_patten          ( bpu_ghr_patten             )
);

always @(posedge clk) begin
	if(rst)
		bpu_btb_vld <= 1'b0;
	else if(bpu_pc_vld)
		bpu_btb_vld <= bpu_pc_vld & (~flush_req);
end

fifo #(
	.RETIRE_MEM_EN(1),
	.RETIRE_HSB(0),
	.RETIRE_LSB(0),
	.BYPASS(1),
    .WIDTH(32+BTB_WAY_NUM+1+32+PHT_WIDTH+GLOBAL_WIDTH+G_PATTEN_WIDTH+1),
    .DEEP(IFQ_ENTRY)
) inst_addr_queue(
    .clk(clk),
    .reset(rst),
    .retire_mem({IFQ_ENTRY{rst|flush_req}}),
    .read((~inst_empty)&(inst_ready|(~pc_valid))),
    .write(inst_addr_valid&inst_addr_ready),
    .indata({inst_addr,
	         bpu_btb_way_vec,
	         bpu_predict_is_branch,
	         bpu_predict_pc,
	         bpu_pht_history,
	         bpu_pht_patten_tab,
	         bpu_ghr,
	         bpu_ghr_patten,
			 1'b1}),
    .outdata({pc,
	          btb_way_vec,
	          predict_is_branch,
	          predict_pc,
	          pht_history,
	          pht_patten_tab,
	          ghr,
	          ghr_patten,
			  pc_valid}),
    .empty(),
    .full(prefetch_full)
);

assign inst_addr_valid = (~prefetch_full) & bpu_btb_vld;

fifo #(
	.BYPASS(1),
    .WIDTH(32),
    .DEEP(IFQ_ENTRY)
) inst_line_queue(
    .clk(clk),
    .reset(rst),
    .read((~inst_empty)&(inst_ready|(~pc_valid))),
    .write(inst_line_valid&inst_line_ready),
    .indata(inst_line),
    .outdata(inst),
    .empty(inst_empty),
    .full()
);

assign inst_line_ready = 1'b1;
assign inst_valid = (~inst_empty) & pc_valid & (~flush_req);

assign pc_4 = pc[31:2] + 30'd1;
assign excep_code = (|pc[1:0]) ? `ADEL : `INVALID_EXCEP;

endmodule

`include "pe_undefs.vh"

