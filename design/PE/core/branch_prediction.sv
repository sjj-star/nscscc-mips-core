`timescale 1ns / 1ps
/*
 * saturating counter
 */
module saturate(
//inputs
	d_i,
	incr,
//outputs
	d_o
);

parameter WIDTH = 2;

input wire [WIDTH-1:0] d_i;
input wire [WIDTH-1:0] incr;
output reg [WIDTH-1:0] d_o;

wire [WIDTH:0] sum;

assign sum = {1'b0,d_i}+{incr[WIDTH-1],incr};

always @(*) begin
	if(incr[WIDTH-1] && sum[WIDTH])
		d_o = {WIDTH{1'b0}};
	else if((~incr[WIDTH-1]) && sum[WIDTH])
		d_o = {WIDTH{1'b1}};
	else
		d_o = sum[WIDTH-1:0];
end

endmodule

module update_pht(
	history_i,
	patten_tab_i,
	is_branch,
	history_o,
	patten_tab_o
);

parameter LOCAL_WIDTH = 4;
parameter B_PATTEN_WIDTH = 2;

input wire [LOCAL_WIDTH-1:0] history_i;
input wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] patten_tab_i;
input wire is_branch;
output wire [LOCAL_WIDTH-1:0] history_o;
output wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] patten_tab_o;

genvar i;
int n;
wire [B_PATTEN_WIDTH-1:0] incr;
wire [B_PATTEN_WIDTH-1:0] patten;
wire [B_PATTEN_WIDTH-1:0] patten_tab[0:2**LOCAL_WIDTH-1];
wire [B_PATTEN_WIDTH-1:0] update_patten;
reg [B_PATTEN_WIDTH-1:0] update_patten_tab[0:2**LOCAL_WIDTH-1];

generate
for(i=0; i<2**LOCAL_WIDTH; i=i+1) begin: patten_remap
	assign patten_tab[i] = patten_tab_i[(i+1)*B_PATTEN_WIDTH-1:i*B_PATTEN_WIDTH];
	assign patten_tab_o[(i+1)*B_PATTEN_WIDTH-1:i*B_PATTEN_WIDTH] = update_patten_tab[i];
end
endgenerate

assign patten = patten_tab[history_i];
assign incr = is_branch ? 1 : {B_PATTEN_WIDTH{1'b1}};
saturate#(.WIDTH(B_PATTEN_WIDTH)) patten_compute(.d_i(patten), .incr(incr), .d_o(update_patten));

always @(*) begin
	for(n=0; n<2**LOCAL_WIDTH; n=n+1)
		if(n == history_i)
			update_patten_tab[n] = update_patten;
		else
			update_patten_tab[n] = patten_tab[n];
end

assign history_o = {history_i[LOCAL_WIDTH-2:0],is_branch};

endmodule

/*
 * Global Branch Pattern Table
 */
module branch_predict_unit(
//inputs
	clk,
	reset,
	pc_vld,
	pc_in,
	fail,
	fail_branch,
	fail_way_vec,
	fill_target,
	fill_pht_history,
	fill_pht_patten_tab,
	fail_ghr,
	fill_ghr_patten,
	fill_ghr,
	btb_vld,
//outputs
	pc_out,
	btb_way_vec,
	predict_is_branch,
	predict_pc,
	pht_history,
	pht_patten_tab,
	ghr,
	ghr_patten
);

parameter GLOBAL_WIDTH = 8;
parameter LOCAL_WIDTH = 0;
parameter BTB_SET_WIDTH = 6;
parameter BTB_WAY_NUM = 1;
parameter B_PATTEN_WIDTH = 2;
parameter G_PATTEN_WIDTH = 2;

localparam GPT_DEPTH = 2**(GLOBAL_WIDTH);
localparam BTB_DEPTH = 2**BTB_SET_WIDTH;
localparam BTB_WIDTH = ((32-2)-BTB_SET_WIDTH+(32-2));
localparam PHT_WIDTH = LOCAL_WIDTH+B_PATTEN_WIDTH*(2**LOCAL_WIDTH);
localparam BPU_GHP_EN = 0;

input wire clk;
input wire reset;
input wire pc_vld;
input wire [31:0] pc_in;
input wire fail;
input wire [31:0] fail_branch;
input wire [BTB_WAY_NUM-1:0] fail_way_vec;
input wire [31:0] fill_target;
input wire [LOCAL_WIDTH-1:0] fill_pht_history;
input wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] fill_pht_patten_tab;
input wire [GLOBAL_WIDTH-1:0] fail_ghr;
input wire [G_PATTEN_WIDTH-1:0] fill_ghr_patten;
input wire [GLOBAL_WIDTH-1:0] fill_ghr;
input wire btb_vld;
output reg [31:0] pc_out;
output wire [BTB_WAY_NUM-1:0] btb_way_vec;
output wire predict_is_branch;
output wire [31:0] predict_pc;
output wire [LOCAL_WIDTH-1:0] pht_history;
output wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] pht_patten_tab;
output reg [GLOBAL_WIDTH-1:0] ghr;
output wire [G_PATTEN_WIDTH-1:0] ghr_patten;

reg [BTB_WAY_NUM-1:0] lfsr;
reg [BTB_WAY_NUM-1:0] fill_way_vec;
reg [GLOBAL_WIDTH-1:0] GHR;
reg [BTB_WAY_NUM-1:0] entry_vld[0:BTB_DEPTH-1];
reg [BTB_WAY_NUM-1:0] way_vld;
wire [BTB_WIDTH-1:0] btb_din;
wire [BTB_WIDTH-1:0] btb_dout[0:BTB_WAY_NUM-1];
wire [PHT_WIDTH-1:0] pht_din;
wire [PHT_WIDTH-1:0] pht_dout[0:BTB_WAY_NUM-1];
wire [31:BTB_SET_WIDTH+2] btb_tag[0:BTB_WAY_NUM-1];
wire [31:2] target_pc[0:BTB_WAY_NUM-1];
wire [LOCAL_WIDTH-1:0] branch_history[0:BTB_WAY_NUM-1];
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] branch_patten_tab[0:BTB_WAY_NUM-1];
wire [B_PATTEN_WIDTH-1:0] branch_patten[0:BTB_WAY_NUM-1];
reg hit_btb;
reg [BTB_WAY_NUM-1:0] hit_btb_vec;
reg [31:BTB_SET_WIDTH+2] hit_btb_tag;
reg [31:2] hit_target_pc;
reg [B_PATTEN_WIDTH-1:0] hit_branch_patten;
reg [LOCAL_WIDTH-1:0] hit_branch_history;
reg [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] hit_branch_patten_tab;
wire [G_PATTEN_WIDTH-1:0] global_patten;
reg  [B_PATTEN_WIDTH-1:0] patten_offset;
wire [B_PATTEN_WIDTH-1:0] predict_patten;
reg update_en;
reg [31:0] update_pc;
reg [BTB_WAY_NUM-1:0] update_way_vec;
reg predict_is_branch_q;
reg [LOCAL_WIDTH-1:0] hit_branch_history_q;
reg [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] hit_branch_patten_tab_q;
reg [GLOBAL_WIDTH-1:0] ghr_q;
reg [G_PATTEN_WIDTH-1:0] global_patten_q;
wire [LOCAL_WIDTH-1:0] update_branch_history;
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] update_branch_patten_tab;
wire [G_PATTEN_WIDTH-1:0] g_patten_incr;
wire [G_PATTEN_WIDTH-1:0] update_global_patten;
wire [31:0] pht_fill_pc;
wire [BTB_WAY_NUM-1:0] pht_fill_way_vec;
wire [GLOBAL_WIDTH-1:0] gpt_fill_ghr;
wire [G_PATTEN_WIDTH-1:0] gpt_fill_patten;

int i,j;
genvar n,m;

always @(posedge clk) begin
	if(reset)
		lfsr <= 4'b0100;
	else if(fail && (~(|fail_way_vec)) && (&entry_vld[fail_branch[BTB_SET_WIDTH-1+2:2]]))
		case(1'b1)
			lfsr[3-1]: lfsr <= 4'b0001;
			lfsr[1-1]: lfsr <= 4'b1000;
			lfsr[4-1]: lfsr <= 4'b0010;
			lfsr[2-1]: lfsr <= 4'b0100;
			default  : lfsr <= 'x;
		endcase
end

always @(*) begin: alloc_update_way_vec
	fill_way_vec = '0;
	if(|fail_way_vec)
		fill_way_vec = fail_way_vec;
	else if(&entry_vld[fail_branch[BTB_SET_WIDTH-1+2:2]])
		fill_way_vec = lfsr;
	else
		for(i=0; i<BTB_WAY_NUM; i=i+1)
			if(~entry_vld[fail_branch[BTB_SET_WIDTH-1+2:2]][i]) begin
				fill_way_vec[i] = 1'b1;
				disable alloc_update_way_vec;
			end
end

// BTB entry valid regs
always @(posedge clk) begin
	if(reset)
		for(i=0; i<BTB_DEPTH; i=i+1)
			for(j=0; j<BTB_WAY_NUM; j=j+1)
				entry_vld[i][j] <= 1'b0;
	else
		for(j=0; j<BTB_WAY_NUM; j=j+1)
			if(fail && fill_way_vec[j])
				entry_vld[fail_branch[BTB_SET_WIDTH-1+2:2]][j] <= 1'b1;
end

always @(posedge clk) begin
	if(reset)
		way_vld <= '0;
	else if(pc_vld)
		way_vld <= entry_vld[pc_in[BTB_SET_WIDTH-1+2:2]];
end

assign btb_din = {fail_branch[31:BTB_SET_WIDTH+2], fill_target[31:2]};
assign pht_din = fail ? {fill_pht_history, fill_pht_patten_tab} : {update_branch_history, update_branch_patten_tab};
assign pht_fill_pc = fail ? fail_branch : update_pc;
assign pht_fill_way_vec = fail ? fill_way_vec : update_way_vec;

generate
for(n=0; n<BTB_WAY_NUM; n=n+1) begin: way_info
	xpm_memory_sdpram #(
		.ADDR_WIDTH_A(BTB_SET_WIDTH),
		.ADDR_WIDTH_B(BTB_SET_WIDTH),
		.AUTO_SLEEP_TIME(0),
		.BYTE_WRITE_WIDTH_A(BTB_WIDTH),
		.CLOCKING_MODE("common_clock"),
		.ECC_MODE("no_ecc"),
		.MEMORY_INIT_FILE("none"),
		.MEMORY_INIT_PARAM("0"),
		.MEMORY_OPTIMIZATION("true"),
		.MEMORY_PRIMITIVE("auto"),
		.MEMORY_SIZE(BTB_DEPTH*BTB_WIDTH),
		.MESSAGE_CONTROL(0),
		.READ_DATA_WIDTH_B(BTB_WIDTH),
		.READ_LATENCY_B(1),
		.READ_RESET_VALUE_B("0"),
		.RST_MODE_A("SYNC"),
		.RST_MODE_B("SYNC"),
		.USE_EMBEDDED_CONSTRAINT(0),
		.USE_MEM_INIT(1),
		.WAKEUP_TIME("disable_sleep"),
		.WRITE_DATA_WIDTH_A(BTB_WIDTH),
		.WRITE_MODE_B("read_first")
	) BTB(
		.clka           ( clk                              ),
		.clkb           ( clk                              ),
		.wea            ( fill_way_vec[n] & fill_ghr[0]    ),
		.ena            ( fail                             ),
		.enb            ( pc_vld                           ),
		.addra          ( fail_branch[BTB_SET_WIDTH-1+2:2] ),
		.addrb          ( pc_in[BTB_SET_WIDTH-1+2:2]       ),
		.dina           ( btb_din                          ),
		.rstb           ( reset                            ),
		.regceb         ( pc_vld                           ),
		.doutb          ( btb_dout[n]                      ),
		.injectdbiterra ( 1'b0                             ),
		.injectsbiterra ( 1'b0                             ),
		.dbiterrb       (                                  ),
		.sbiterrb       (                                  ),
		.sleep          ( 1'b0                             )
	);

	xpm_memory_sdpram #(
		.ADDR_WIDTH_A(BTB_SET_WIDTH),
		.ADDR_WIDTH_B(BTB_SET_WIDTH),
		.AUTO_SLEEP_TIME(0),
		.BYTE_WRITE_WIDTH_A(PHT_WIDTH),
		.CLOCKING_MODE("common_clock"),
		.ECC_MODE("no_ecc"),
		.MEMORY_INIT_FILE("none"),
		.MEMORY_INIT_PARAM("0"),
		.MEMORY_OPTIMIZATION("true"),
		.MEMORY_PRIMITIVE("auto"),
		.MEMORY_SIZE(BTB_DEPTH*PHT_WIDTH),
		.MESSAGE_CONTROL(0),
		.READ_DATA_WIDTH_B(PHT_WIDTH),
		.READ_LATENCY_B(1),
		.READ_RESET_VALUE_B("0"),
		.RST_MODE_A("SYNC"),
		.RST_MODE_B("SYNC"),
		.USE_EMBEDDED_CONSTRAINT(0),
		.USE_MEM_INIT(1),
		.WAKEUP_TIME("disable_sleep"),
		.WRITE_DATA_WIDTH_A(PHT_WIDTH),
		.WRITE_MODE_B("read_first")
	) PHT(
		.clka           ( clk                              ),
		.clkb           ( clk                              ),
		.wea            ( pht_fill_way_vec[n]              ),
		.ena            ( fail | update_en                 ),
		.enb            ( pc_vld                           ),
		.addra          ( pht_fill_pc[BTB_SET_WIDTH-1+2:2] ),
		.addrb          ( pc_in[BTB_SET_WIDTH-1+2:2]       ),
		.dina           ( pht_din                          ),
		.rstb           ( reset                            ),
		.regceb         ( pc_vld                           ),
		.doutb          ( pht_dout[n]                      ),
		.injectdbiterra ( 1'b0                             ),
		.injectsbiterra ( 1'b0                             ),
		.dbiterrb       (                                  ),
		.sbiterrb       (                                  ),
		.sleep          ( 1'b0                             )
	);

	assign {btb_tag[n],target_pc[n]} = btb_dout[n];
	assign {branch_history[n],branch_patten_tab[n]} = pht_dout[n];

	wire [B_PATTEN_WIDTH-1:0] patten_tab[0:2**LOCAL_WIDTH-1];
	for(m=0; m<2**LOCAL_WIDTH; m=m+1) begin: pht_sel
		assign patten_tab[m] = branch_patten_tab[n][(m+1)*B_PATTEN_WIDTH-1:m*B_PATTEN_WIDTH];
	end
	assign branch_patten[n] = patten_tab[branch_history[n]];
end
endgenerate

always @(*) begin
	hit_btb = 1'b0;
	hit_btb_vec = '0;
	hit_btb_tag = '0;
	hit_target_pc = '0;
	hit_branch_patten = '0;
	hit_branch_history = '0;
	hit_branch_patten_tab = '0;
	for(i=0; i<BTB_WAY_NUM; i=i+1) begin
		hit_btb_vec[i] = btb_vld & way_vld[i] & (btb_tag[i] == pc_out[31:BTB_SET_WIDTH+2]);
		hit_btb = hit_btb | hit_btb_vec[i];
		hit_btb_tag = hit_btb_tag | (btb_tag[i] & {32-BTB_SET_WIDTH-2{hit_btb_vec[i]}});
		hit_target_pc = hit_target_pc | (target_pc[i] & {32-2{hit_btb_vec[i]}});
		hit_branch_patten = hit_branch_patten | (branch_patten[i] & {B_PATTEN_WIDTH{hit_btb_vec[i]}});
		hit_branch_history = hit_branch_history | (branch_history[i] & {LOCAL_WIDTH{hit_btb_vec[i]}});
		hit_branch_patten_tab = hit_branch_patten_tab | (branch_patten_tab[i] & {B_PATTEN_WIDTH*(2**LOCAL_WIDTH){hit_btb_vec[i]}});
	end
end

generate
if(BPU_GHP_EN) begin
// Global History Register(a shift reg)
always @(posedge clk) begin
	if(reset)
		GHR <= {GLOBAL_WIDTH{1'b0}};
	else if(fail)
		GHR <= fill_ghr;
	else if(btb_vld && hit_btb)
		GHR <= {GHR[GLOBAL_WIDTH-2:0], predict_is_branch};
end

assign gpt_fill_ghr = fail ? fail_ghr : ghr_q;
assign gpt_fill_patten = fail ? fill_ghr_patten : update_global_patten;

// Global Pattern History Table
xpm_memory_sdpram #(
   .ADDR_WIDTH_A(GLOBAL_WIDTH),
   .ADDR_WIDTH_B(GLOBAL_WIDTH),
   .AUTO_SLEEP_TIME(0),
   .BYTE_WRITE_WIDTH_A(G_PATTEN_WIDTH),
   .CLOCKING_MODE("common_clock"),
   .ECC_MODE("no_ecc"),
   .MEMORY_INIT_FILE("none"),
   .MEMORY_INIT_PARAM("0"),
   .MEMORY_OPTIMIZATION("true"),
   .MEMORY_PRIMITIVE("auto"),
   .MEMORY_SIZE(GPT_DEPTH*G_PATTEN_WIDTH),
   .MESSAGE_CONTROL(0),
   .READ_DATA_WIDTH_B(G_PATTEN_WIDTH),
   .READ_LATENCY_B(1),
   .READ_RESET_VALUE_B("0"),
   .RST_MODE_A("SYNC"),
   .RST_MODE_B("SYNC"),
   .USE_EMBEDDED_CONSTRAINT(0),
   .USE_MEM_INIT(1),
   .WAKEUP_TIME("disable_sleep"),
   .WRITE_DATA_WIDTH_A(G_PATTEN_WIDTH),
   .WRITE_MODE_B("read_first")
) GPT(
   .clka           ( clk             ),
   .clkb           ( clk             ),
   .wea            ( fail | update_en),
   .ena            ( fail | update_en),
   .enb            ( pc_vld          ),
   .addra          ( gpt_fill_ghr    ),
   .addrb          ( GHR             ),
   .dina           ( gpt_fill_patten ),
   .rstb           ( reset           ),
   .regceb         ( pc_vld          ),
   .doutb          ( global_patten   ),
   .injectdbiterra ( 1'b0            ),
   .injectsbiterra ( 1'b0            ),
   .dbiterrb       (                 ),
   .sbiterrb       (                 ),
   .sleep          ( 1'b0            )
);

always @(*) begin
	case(global_patten[G_PATTEN_WIDTH-1:G_PATTEN_WIDTH-2])
		2'b00  : patten_offset = {{B_PATTEN_WIDTH-2{1'b1}}, 2'b11};
		//2'b00  : patten_offset = {{B_PATTEN_WIDTH-2{1'b1}}, 2'b10};
		//2'b01  : patten_offset = {{B_PATTEN_WIDTH-2{1'b1}}, 2'b11};
		//2'b10  : patten_offset = {{B_PATTEN_WIDTH-2{1'b0}}, 2'b01};
		//2'b11  : patten_offset = {{B_PATTEN_WIDTH-2{1'b0}}, 2'b10};
		2'b11  : patten_offset = {{B_PATTEN_WIDTH-2{1'b0}}, 2'b01};
		default: patten_offset = '0;
	endcase
end
saturate#(.WIDTH(B_PATTEN_WIDTH)) patten_merge(.d_i(hit_branch_patten), .incr(patten_offset), .d_o(predict_patten));
end else
assign predict_patten = hit_branch_patten;
endgenerate

always @(posedge clk) begin
	if(pc_vld)
		ghr <= GHR;
end

always @(posedge clk) begin
	if(pc_vld)
		pc_out <= pc_in;
end

assign btb_way_vec = hit_btb_vec;
assign predict_is_branch = predict_patten[B_PATTEN_WIDTH-1] & hit_btb;
assign predict_pc = {hit_target_pc, 2'b0};
assign pht_history = hit_branch_history;
assign pht_patten_tab = hit_branch_patten_tab;
assign ghr_patten = global_patten;

always @(posedge clk) begin
	if(reset | (~(pc_vld&btb_vld))) begin
		update_en <= 1'b0;
		update_way_vec <= '0;
	end else if(pc_vld && btb_vld) begin
		update_en <= hit_btb;
		update_way_vec <= hit_btb_vec;
		update_pc <= pc_out;
		hit_branch_history_q <= hit_branch_history;
		hit_branch_patten_tab_q <= hit_branch_patten_tab;
		predict_is_branch_q <= predict_is_branch;
		ghr_q <= GHR;
		global_patten_q <= global_patten;
	end
end

update_pht#(
	.LOCAL_WIDTH(LOCAL_WIDTH),
	.B_PATTEN_WIDTH(B_PATTEN_WIDTH)
) hit_pht_update(
	.history_i    ( hit_branch_history_q ),
	.patten_tab_i ( hit_branch_patten_tab_q ),
	.is_branch    ( predict_is_branch_q ),
	.history_o    ( update_branch_history ),
	.patten_tab_o ( update_branch_patten_tab )
);

assign g_patten_incr = predict_is_branch_q ? 1 : {G_PATTEN_WIDTH{1'b1}};
saturate#(.WIDTH(G_PATTEN_WIDTH)) hit_gpt_update(.d_i(global_patten_q), .incr(g_patten_incr), .d_o(update_global_patten));

endmodule

