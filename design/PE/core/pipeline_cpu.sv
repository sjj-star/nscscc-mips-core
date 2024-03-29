`timescale 1ns / 1ps
`include "pe_defs.vh"

module pipeline_cpu(
    clk,
    reset,
    hw_int,
    inst_addr_valid,
    inst_addr_ready,
    inst_addr,
    inst_line_valid,
    inst_line_ready,
    inst_line,
    data_valid,
    data_ready,
    data_wr,
    data_size,
    data_wstrb,
    data_addr,
    data_wdata,
    data_rdata,
    debug_wb_pc,
    debug_wb_rf_wen,
    debug_wb_rf_wnum,
    debug_wb_rf_wdata
);

input  wire        clk;
input  wire        reset;
input  wire [5:0]  hw_int;
output wire        inst_addr_valid;
input  wire        inst_addr_ready;
output wire [31:0] inst_addr;
input  wire        inst_line_valid;
output wire        inst_line_ready;
input  wire [31:0] inst_line;
output wire        data_valid;
input  wire        data_ready;
output wire        data_wr;
output wire [1:0]  data_size;
output wire [3:0]  data_wstrb;
output wire [31:0] data_addr;
output wire [31:0] data_wdata;
input  wire [31:0] data_rdata;
output wire [31:0] debug_wb_pc;
output wire [3:0]  debug_wb_rf_wen;
output wire [4:0]  debug_wb_rf_wnum;
output wire [31:0] debug_wb_rf_wdata;

/*顶层模块的连线命名规则：
*如果不是连接到流水线寄存器的线，而是直接连接两个模块的线，命名为xx_xx_xxx，第一部分是输入端口模块简称，第二部分是输出端口模块简称，第三部分是线的功能
*如果是输入到流水线寄存器的线，而不是直连两个模块之间的线，命名为xx_xxx，第一部分是输入到流水线寄存器的某一阶段流水线的简称，第二部分是线的功能
*如果是从流水线寄存器输出的线，命名为：xx_xxx_pipreg，第一部分是上一级流水线寄存器输入到某一阶段流水线的简称，第二部分是线的功能
*如果是寄存器的控制信号则统一指出控制信号来自哪一级以及用途，其格式不做具体要求
*/

localparam IFQ_ENTRY = 16;
localparam GLOBAL_WIDTH = 15;
localparam LOCAL_WIDTH = 4;
localparam BTB_SET_WIDTH = 8;
localparam BTB_WAY_NUM = 4;
localparam B_PATTEN_WIDTH = 2;
localparam G_PATTEN_WIDTH = 3;
localparam PHT_WIDTH = LOCAL_WIDTH+B_PATTEN_WIDTH*(2**LOCAL_WIDTH);

wire [31:0] if_ex_bjpc;
wire        if_ex_isbj;
wire [31:0] if_ex_fail_branch;
wire [BTB_WAY_NUM-1:0] if_ex_fail_way_vec;
wire [LOCAL_WIDTH-1:0] if_ex_fill_pht_history;
wire if_ex_fill_is_ret;
wire if_ex_fill_is_link;
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] if_ex_fill_pht_patten_tab;
wire [GLOBAL_WIDTH-1:0] if_ex_fail_ghr;
wire [G_PATTEN_WIDTH-1:0] if_ex_fill_ghr_patten;
wire [GLOBAL_WIDTH-1:0] if_ex_fill_ghr;
wire [31:0] if_pc;
wire [29:0] if_pc4;
wire [31:0] if_inst;
wire [4:0]  if_excepcode;
wire [BTB_WAY_NUM-1:0] if_btb_way_vec;
wire if_predict_is_branch;
wire [31:0] if_predict_pc;
wire [LOCAL_WIDTH-1:0] if_pht_history;
wire [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] if_pht_patten_tab;
wire [GLOBAL_WIDTH-1:0] if_ghr;
wire [G_PATTEN_WIDTH-1:0] if_ghr_patten;
reg  [31:0] id_instruction_pipreg;
wire        id_cft_en;
reg         id_vld_pipreg;
reg  [31:0] id_pc_pipreg;
reg  [29:0] id_pc4_pipreg;
reg [BTB_WAY_NUM-1:0] id_btb_way_vec_pipreg;
reg id_predict_is_branch_pipreg;
reg [31:0] id_predict_pc_pipreg;
reg [LOCAL_WIDTH-1:0] id_pht_history_pipreg;
reg [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] id_pht_patten_tab_pipreg;
reg [GLOBAL_WIDTH-1:0] id_ghr_pipreg;
reg [G_PATTEN_WIDTH-1:0] id_ghr_patten_pipreg;
reg  [4:0]  id_excepcode_pipreg;
wire [31:0] id_cft_rsvalue;
wire [31:0] id_cft_rtvalue;
wire [31:0] id_cft_hilovalue;
wire [44:0] id_instropreat;
wire [4:0]  id_regaddress;
wire [7:0]  id_copaddr;
wire [31:0] id_hilovalue;
wire        id_iswritereg;
wire        id_iswritehi;
wire        id_iswritelo;
wire [31:0] id_bjpc;
wire        id_btb_addr_fail;
wire [31:0] id_rtvalue;
wire [31:0] id_aluopA;
wire [31:0] id_aluopB;
wire [4:0]  id_excepcode;
wire        cft_id_users;
wire        cft_id_usert;
wire        cft_id_usehi;
wire        cft_id_uselo;
wire [4:0]  cft_id_rs;
wire [4:0]  cft_id_rt;
wire [31:0] id_pc;
reg         ex_vld_pipreg;
reg  [44:0] ex_instropreat_pipreg;
reg  [4:0]  ex_regaddress_pipreg;
reg  [7:0]  ex_copaddr_pipreg;
reg  [31:0] ex_hilovalue_pipreg;
reg  [31:0] ex_rtvalue_pipreg;
reg  [31:0] ex_aluopA_pipreg;
reg  [31:0] ex_aluopB_pipreg;
reg         ex_iswritereg_pipreg;
reg         ex_iswritehi_pipreg;
reg         ex_iswritelo_pipreg;
reg  [31:0] ex_bjpc_pipreg;
reg  [31:0] ex_pc_pipreg;
reg         ex_btb_addr_fail_pipreg;
reg [BTB_WAY_NUM-1:0] ex_btb_way_vec_pipreg;
reg ex_predict_is_branch_pipreg;
reg [LOCAL_WIDTH-1:0] ex_pht_history_pipreg;
reg [B_PATTEN_WIDTH*(2**LOCAL_WIDTH)-1:0] ex_pht_patten_tab_pipreg;
reg [GLOBAL_WIDTH-1:0] ex_ghr_pipreg;
reg [G_PATTEN_WIDTH-1:0] ex_ghr_patten_pipreg;
reg  [4:0]  ex_excepcode_pipreg;
wire [9:0]  ex_instropreat;
wire [4:0]  ex_regaddress;
wire [31:0] ex_regwdata;
wire [31:0] ex_hiwdata;
wire [31:0] ex_lowdata;
wire [31:0] ex_rtvalue;
wire [7:0]  ex_copaddr;
wire [31:0] ex_rwmemaddr;
wire        ex_opover;
wire [4:0]  ex_excepcode;
wire        cft_ex_wreg;
wire        cft_ex_clereg;
wire [4:0]  cft_ex_regaddr;
wire [31:0] cft_ex_regdata;
wire        cft_ex_whi;
wire        cft_ex_wlo;
wire [31:0] cft_ex_hidata;
wire [31:0] cft_ex_lodata;
wire [31:0] ex_pc;
reg         am_vld_pipreg;
reg  [9:0]  am_instropreat_pipreg;
reg  [4:0]  am_regaddress_pipreg;
reg  [31:0] am_regwdata_pipreg;
reg  [31:0] am_hiwdata_pipreg;
reg  [31:0] am_lowdata_pipreg;
reg         am_iswritereg_pipreg;
reg         am_iswritehi_pipreg;
reg         am_iswritelo_pipreg;
reg  [31:0] am_rtvalue_pipreg;
reg  [7:0]  am_copaddr_pipreg;
reg  [31:0] am_rwmemaddr_pipreg;
reg  [31:0] am_pc_pipreg;
reg  [4:0]  am_excepcode_pipreg;
wire        cop0_am_we;
wire [7:0]  cop0_am_addr;
wire [31:0] cop0_am_wdata;
wire [31:0] am_cop0_rdata;
wire        am_instropreat;
wire [4:0]  am_regaddress;
wire [31:0] am_regdata;
wire [31:0] am_hiwdata;
wire [31:0] am_lowdata;
wire        cft_am_wreg;
wire [4:0]  cft_am_regaddr;
wire [31:0] cft_am_regdata;
wire        cft_am_whi;
wire        cft_am_wlo;
wire [31:0] cft_am_hidata;
wire [31:0] cft_am_lodata;
wire [31:0] am_pc;
reg         wb_vld_pipreg;
reg         wb_instropreat_pipreg;
reg         wb_writereg_pipreg;
reg         wb_writehi_pipreg;
reg         wb_writelo_pipreg;
reg  [4:0]  wb_regaddress_pipreg;
reg  [31:0] wb_regdata_pipreg;
reg  [31:0] wb_hiwdata_pipreg;
reg  [31:0] wb_lowdata_pipreg;
reg  [31:0] wb_pc_pipreg;
wire [4:0]  wb_cft_rs;
wire [4:0]  wb_cft_rt;
wire [31:0] cft_wb_hidata;
wire [31:0] cft_wb_lodata;
wire [31:0] cft_wb_rsdata;
wire [31:0] cft_wb_rtdata;
wire        excep_isexception;
wire        excep_if_laddrerror;
wire        excep_cp0_isie;
wire        excep_cp0_isexl;
wire [7:0]  excep_cp0_intmask;
wire [1:0]  excep_cp0_softint;
wire        cp0_excep_bd;
wire        cp0_excep_webadaddr;
wire [31:0] cp0_excep_badaddr;
wire [31:0] cp0_excep_excpc;
wire        excep_idclr;
wire        excep_exclr;
wire        excep_amclr;
wire        excep_wbclr;
wire        excep_wb_isbj;
wire [31:0] if_cp0_returnpc;
wire        excep_id_isexcepreturn;
wire [4:0]  excep_am_excepcode;
wire [4:0]  cp0_excep_excepcode;
wire        excep_am_isinstload;

wire inst_retire;
wire if_id_pipreg_clr;
wire if_id_pipreg_en;
wire id_ex_pipreg_clr;
wire id_ex_pipreg_en;
wire ex_am_pipreg_clr;
wire ex_am_pipreg_en;
wire am_wb_pipreg_clr;
wire am_wb_pipreg_en;
wire inst_valid;
wire inst_ready;
wire dbus_over;
wire dbus_busy;

assign dbus_over = data_valid & data_ready;
assign dbus_busy = data_valid & (~data_ready);

assign inst_retire = excep_isexception|excep_id_isexcepreturn|(if_ex_isbj & id_vld_pipreg & (~dbus_busy));
assign inst_ready = (id_cft_en & ex_opover & (~dbus_busy))|inst_retire;

assign if_id_pipreg_clr = ((~if_id_pipreg_en) & id_ex_pipreg_en & id_cft_en)|excep_idclr|excep_id_isexcepreturn;
assign if_id_pipreg_en  = id_cft_en & ex_opover & (~dbus_busy) & inst_valid & (~inst_retire);

assign id_ex_pipreg_clr = ((~id_cft_en) & ex_am_pipreg_en)|excep_exclr;
assign id_ex_pipreg_en  = ex_opover & (~dbus_busy) & ((~ex_instropreat_pipreg[0])|id_vld_pipreg); // ex_instropreat_pipreg[0]: the instruction is branch/jump

assign ex_am_pipreg_clr = (((ex_instropreat_pipreg[0] & (~id_vld_pipreg))|(~ex_opover)) & (~dbus_busy))|excep_amclr;
assign ex_am_pipreg_en  = ex_opover & (~dbus_busy);

assign am_wb_pipreg_clr = ((~am_wb_pipreg_en) & wb_writereg_pipreg)|excep_wbclr;
assign am_wb_pipreg_en  = ~dbus_busy;

inst_fetch #(
	.IFQ_ENTRY(IFQ_ENTRY),
	.GLOBAL_WIDTH(GLOBAL_WIDTH),
	.LOCAL_WIDTH(LOCAL_WIDTH),
	.BTB_SET_WIDTH(BTB_SET_WIDTH),
	.BTB_WAY_NUM(BTB_WAY_NUM),
	.B_PATTEN_WIDTH(B_PATTEN_WIDTH),
	.G_PATTEN_WIDTH(G_PATTEN_WIDTH)
) if_unit(//input
          .clk                   (clk),
          .rst                   (reset),
          .jump_branch_address   (if_ex_bjpc),
          .is_jump_branch        (if_ex_isbj&id_vld_pipreg&(~dbus_busy)),
          //BPU
          .fail_branch           (if_ex_fail_branch        ),
          .fail_way_vec          (if_ex_fail_way_vec       ),
          .fill_is_ret           (if_ex_fill_is_ret        ),
          .fill_is_link          (if_ex_fill_is_link       ),
          .fill_pht_history      (if_ex_fill_pht_history   ),
          .fill_pht_patten_tab   (if_ex_fill_pht_patten_tab),
          .fail_ghr              (if_ex_fail_ghr           ),
          .fill_ghr_patten       (if_ex_fill_ghr_patten    ),
          .fill_ghr              (if_ex_fill_ghr           ),
          //execption
          .is_exception          (excep_isexception),
          .is_excep_return       (excep_id_isexcepreturn),
          .excep_return_pc       (if_cp0_returnpc),
          //output
          .pc                    (if_pc),
          .pc_4                  (if_pc4),
          //BPU
          .btb_way_vec           (if_btb_way_vec      ),
          .predict_is_branch     (if_predict_is_branch),
          .predict_pc            (if_predict_pc       ),
          .pht_history           (if_pht_history      ),
          .pht_patten_tab        (if_pht_patten_tab   ),
          .ghr                   (if_ghr              ),
          .ghr_patten            (if_ghr_patten       ),
          //exception
          .excep_code            (if_excepcode),
          //fetch instruction interface
          .inst_addr_valid       (inst_addr_valid),
          .inst_addr_ready       (inst_addr_ready),
          .inst_addr             (inst_addr      ),
          .inst_line_valid       (inst_line_valid),
          .inst_line_ready       (inst_line_ready),
          .inst_line             (inst_line      ),
          //pipe interface
          .inst_valid            (inst_valid),
          .inst_ready            (inst_ready),
          .inst                  (if_inst   ));

always @ (posedge clk)
begin
    if (reset|if_id_pipreg_clr)
        {id_vld_pipreg,
         id_pc_pipreg,
         id_pc4_pipreg,
         id_instruction_pipreg,
         id_btb_way_vec_pipreg,
         id_predict_is_branch_pipreg,
         id_predict_pc_pipreg,
         id_pht_history_pipreg,
         id_pht_patten_tab_pipreg,
         id_ghr_pipreg,
         id_ghr_patten_pipreg,
         id_excepcode_pipreg}
     <= {1'b0,32'b0,30'b0,`INST_INTI,{BTB_WAY_NUM+1+32+PHT_WIDTH+GLOBAL_WIDTH+G_PATTEN_WIDTH{1'b0}},`INVALID_EXCEP};
    else if (if_id_pipreg_en)
        {id_vld_pipreg,
         id_pc_pipreg,
         id_pc4_pipreg,
         id_instruction_pipreg,
         id_btb_way_vec_pipreg,
         id_predict_is_branch_pipreg,
         id_predict_pc_pipreg,
         id_pht_history_pipreg,
         id_pht_patten_tab_pipreg,
         id_ghr_pipreg,
         id_ghr_patten_pipreg,
         id_excepcode_pipreg}
     <= {if_id_pipreg_en,
         if_pc,
         if_pc4,
         if_inst,
         if_btb_way_vec,
         if_predict_is_branch,
         if_predict_pc,
         if_pht_history,
         if_pht_patten_tab,
         if_ghr,
         if_ghr_patten,
         if_excepcode};

end

decode id(//input
          .inst                     (id_instruction_pipreg),
          .pc_delayslot             (id_pc4_pipreg),
          .predict_pc               (id_predict_pc_pipreg),
          .reg_s_value_latest       (id_cft_rsvalue),
          .reg_t_value_latest       (id_cft_rtvalue),
          .hilo_value_latest        (id_cft_hilovalue),
          .if_pc                    (id_pc_pipreg),
          //exception
          .if_excep_code            (id_excepcode_pipreg),
          //output
          .inst_opreat              (id_instropreat),
          .reg_t_d_31               (id_regaddress),
          .reg_t_value              (id_rtvalue),
          .alu_opreatA              (id_aluopA),
          .alu_opreatB              (id_aluopB),
          .hi_lo_value              (id_hilovalue),
          .is_write_reg             (id_iswritereg),
          .is_write_hi              (id_iswritehi),
          .is_write_lo              (id_iswritelo),
          .jump_branch_address      (id_bjpc),
          .btb_addr_fail            (id_btb_addr_fail),
          .cop_address              (id_copaddr),
          //check confict
          .check_is_use_reg_s       (cft_id_users),
          .check_is_use_reg_t       (cft_id_usert),
          .check_is_use_hi          (cft_id_usehi),
          .check_is_use_lo          (cft_id_uselo),
          .check_reg_s              (cft_id_rs),
          .check_reg_t              (cft_id_rt),
          //exception
          .excep_code               (id_excepcode),
          .exception_is_return      (excep_id_isexcepreturn),
          .id_pc                    (id_pc));

always @ (posedge clk)
begin
    if (reset|id_ex_pipreg_clr)
        {ex_vld_pipreg,
         ex_instropreat_pipreg,
         ex_regaddress_pipreg,
         ex_copaddr_pipreg,
         ex_hilovalue_pipreg,
         ex_rtvalue_pipreg,
         ex_aluopA_pipreg,
         ex_aluopB_pipreg,
         ex_iswritereg_pipreg,
         ex_iswritehi_pipreg,
         ex_iswritelo_pipreg,
         ex_bjpc_pipreg,
         ex_pc_pipreg,
		 ex_btb_addr_fail_pipreg,
         ex_btb_way_vec_pipreg,
         ex_predict_is_branch_pipreg,
         ex_pht_history_pipreg,
         ex_pht_patten_tab_pipreg,
         ex_ghr_pipreg,
         ex_ghr_patten_pipreg,
         ex_excepcode_pipreg}
     <= {254'b0,{1+BTB_WAY_NUM+1+PHT_WIDTH+GLOBAL_WIDTH+G_PATTEN_WIDTH{1'b0}},`INVALID_EXCEP};
    else if (id_ex_pipreg_en)
        {ex_vld_pipreg,
         ex_instropreat_pipreg,
         ex_regaddress_pipreg,
         ex_copaddr_pipreg,
         ex_hilovalue_pipreg,
         ex_rtvalue_pipreg,
         ex_aluopA_pipreg,
         ex_aluopB_pipreg,
         ex_iswritereg_pipreg,
         ex_iswritehi_pipreg,
         ex_iswritelo_pipreg,
         ex_bjpc_pipreg,
         ex_pc_pipreg,
		 ex_btb_addr_fail_pipreg,
         ex_btb_way_vec_pipreg,
         ex_predict_is_branch_pipreg,
         ex_pht_history_pipreg,
         ex_pht_patten_tab_pipreg,
         ex_ghr_pipreg,
         ex_ghr_patten_pipreg,
         ex_excepcode_pipreg}
     <= {id_vld_pipreg,
         id_instropreat,
         id_regaddress,
         id_copaddr,
         id_hilovalue,
         id_rtvalue,
         id_aluopA,
         id_aluopB,
         id_iswritereg,
         id_iswritehi,
         id_iswritelo,
         id_bjpc,
         id_pc,
		 id_btb_addr_fail,
         id_btb_way_vec_pipreg,
         id_predict_is_branch_pipreg,
         id_pht_history_pipreg,
         id_pht_patten_tab_pipreg,
         id_ghr_pipreg,
         id_ghr_patten_pipreg,
         id_excepcode};
end

myexecute #(
	.GLOBAL_WIDTH(GLOBAL_WIDTH),
	.LOCAL_WIDTH(LOCAL_WIDTH),
	.BTB_SET_WIDTH(BTB_SET_WIDTH),
	.BTB_WAY_NUM(BTB_WAY_NUM),
	.B_PATTEN_WIDTH(B_PATTEN_WIDTH),
	.G_PATTEN_WIDTH(G_PATTEN_WIDTH)
) ex(//input
     .clk                       (clk),
     .reset                     (reset|id_ex_pipreg_clr),
     .inst_opreat               (ex_instropreat_pipreg),
     .reg_t_d_31                (ex_regaddress_pipreg),
     .cop_address               (ex_copaddr_pipreg),
     .hi_lo_value               (ex_hilovalue_pipreg),
     .reg_t_value               (ex_rtvalue_pipreg),
     .alu_opreat_A              (ex_aluopA_pipreg),
     .alu_opreat_B              (ex_aluopB_pipreg),
     .is_write_reg              (ex_iswritereg_pipreg),
     .is_write_hi               (ex_iswritehi_pipreg),
     .is_write_lo               (ex_iswritelo_pipreg),
     .jump_branch_address       (ex_bjpc_pipreg),
     .id_pc                     (ex_pc_pipreg),
     .id_excep_code             (ex_excepcode_pipreg),
     //BPU
	 .btb_addr_fail             (ex_btb_addr_fail_pipreg),
     .btb_way_vec               (ex_btb_way_vec_pipreg),
     .predict_is_branch         (ex_predict_is_branch_pipreg),
     .pht_history               (ex_pht_history_pipreg),
     .pht_patten_tab            (ex_pht_patten_tab_pipreg),
     .ghr                       (ex_ghr_pipreg),
     .ghr_patten                (ex_ghr_patten_pipreg),
     .is_busbusy                (dbus_busy),
      //output
     .inst_opreat_              (ex_instropreat),
     .write_reg_address         (ex_regaddress),
     .write_reg_data            (ex_regwdata),
     .write_hi_value            (ex_hiwdata),
     .write_lo_value            (ex_lowdata),
     .reg_t_value_              (ex_rtvalue),
     .cop_address_              (ex_copaddr),
     .rw_mem_address            (ex_rwmemaddr),
     .opreat_over               (ex_opover),
     .is_jump_branch            (if_ex_isbj),
     .jump_branch_address_      (if_ex_bjpc),
     //BPU
     .fail_branch               (if_ex_fail_branch        ),
     .fail_way_vec              (if_ex_fail_way_vec       ),
     .fill_is_ret               (if_ex_fill_is_ret        ),
     .fill_is_link              (if_ex_fill_is_link       ),
     .fill_pht_history          (if_ex_fill_pht_history   ),
     .fill_pht_patten_tab       (if_ex_fill_pht_patten_tab),
     .fail_ghr                  (if_ex_fail_ghr           ),
     .fill_ghr_patten           (if_ex_fill_ghr_patten    ),
     .fill_ghr                  (if_ex_fill_ghr           ),
     //check confict
     .check_is_write_reg        (cft_ex_wreg),
     .check_is_clean_reg        (cft_ex_clereg),
     .check_write_reg_address   (cft_ex_regaddr),
     .check_write_reg_data      (cft_ex_regdata),
     .check_is_write_hi         (cft_ex_whi),
     .check_is_write_lo         (cft_ex_wlo),
     .check_write_hi_value      (cft_ex_hidata),
     .check_write_lo_value      (cft_ex_lodata),
     //exception
     .excep_code                (ex_excepcode),
     .ex_pc                     (ex_pc));

always @ (posedge clk)
begin
    if (reset|ex_am_pipreg_clr)
        {am_vld_pipreg,
         am_instropreat_pipreg,
         am_regaddress_pipreg,
         am_regwdata_pipreg,
         am_hiwdata_pipreg,
         am_lowdata_pipreg,
         am_iswritereg_pipreg,
         am_iswritehi_pipreg,
         am_iswritelo_pipreg,
         am_rtvalue_pipreg,
         am_copaddr_pipreg,
         am_rwmemaddr_pipreg,
         am_pc_pipreg,
         am_excepcode_pipreg}
     <= {219'b0,`INVALID_EXCEP};
    else if (ex_am_pipreg_en)
        {am_vld_pipreg,
         am_instropreat_pipreg,
         am_regaddress_pipreg,
         am_regwdata_pipreg,
         am_hiwdata_pipreg,
         am_lowdata_pipreg,
         am_iswritereg_pipreg,
         am_iswritehi_pipreg,
         am_iswritelo_pipreg,
         am_rtvalue_pipreg,
         am_copaddr_pipreg,
         am_rwmemaddr_pipreg,
         am_pc_pipreg,
         am_excepcode_pipreg}
     <= {ex_vld_pipreg,
         ex_instropreat,
         ex_regaddress,
         ex_regwdata,
         ex_hiwdata,
         ex_lowdata,
         cft_ex_wreg,
         cft_ex_whi,
         cft_ex_wlo,
         ex_rtvalue,
         ex_copaddr,
         ex_rwmemaddr,
         ex_pc,
         ex_excepcode};
end

cop0 syscrtl(//input
             .clk               (clk),
             .rst               (reset),
             .we                (cop0_am_we),
             .cop_address       (cop0_am_addr),
             .data_i            (cop0_am_wdata),
             .hardware_int      (hw_int),
             .is_exception      (excep_isexception),
             .is_bd             (cp0_excep_bd),
             .we_badvaddr       (cp0_excep_webadaddr),
             .badvaddr          (cp0_excep_badaddr),
             .exc_code          (cp0_excep_excepcode),
             .exc_pc            (cp0_excep_excpc),
             .is_excep_return   (excep_id_isexcepreturn),
             //output
             .data_o            (am_cop0_rdata),
             .is_ie             (excep_cp0_isie),
             .is_exl            (excep_cp0_isexl),
             .int_mask          (excep_cp0_intmask),
             .soft_int          (excep_cp0_softint),
             .errorpc           (if_cp0_returnpc));

accessmem am(//input
             .inst_opreat               (am_instropreat_pipreg),
             .write_reg_address         (am_regaddress_pipreg),
             .write_reg_data_before     (am_regwdata_pipreg),
             .write_hi_value            (am_hiwdata_pipreg),
             .write_lo_value            (am_lowdata_pipreg),
             .is_write_reg              (am_iswritereg_pipreg),
             .is_write_hi               (am_iswritehi_pipreg),
             .is_write_lo               (am_iswritelo_pipreg),
             .reg_t_value               (am_rtvalue_pipreg),
             .cop_address               (am_copaddr_pipreg),
             .mem_address               (am_rwmemaddr_pipreg),
             .ex_excep_code             (am_excepcode_pipreg),
             .ex_pc                     (am_pc_pipreg),
             //output
             .inst_opreat_              (am_instropreat),
             .write_reg_address_        (am_regaddress),
             .write_reg_data            (am_regdata),
             .write_hi_value_           (am_hiwdata),
             .write_lo_value_           (am_lowdata),
             .check_is_write_reg        (cft_am_wreg),
             .check_write_reg_address   (cft_am_regaddr),
             .check_write_reg_data      (cft_am_regdata),
             .check_is_write_hi         (cft_am_whi),
             .check_is_write_lo         (cft_am_wlo),
             .check_write_hi_value      (cft_am_hidata),
             .check_write_lo_value      (cft_am_lodata),
             //exception
             .excep_code                (excep_am_excepcode),
             .is_instload               (excep_am_isinstload),
             .am_pc                     (am_pc),
             //read write COP0
             .cop_we                    (cop0_am_we),
             .cop_address_              (cop0_am_addr),
             .read_cop_data             (am_cop0_rdata),
             .write_cop_data            (cop0_am_wdata),
             //read write RAM
             .mem_req                   (data_valid),
             .mem_wr                    (data_wr),
             .mem_size                  (data_size),
             .mem_wstrb                 (data_wstrb),
             .mem_address_              (data_addr),
             .read_mem_data             (data_rdata),
             .write_mem_data            (data_wdata));

always @ (posedge clk)
begin
    if (reset|am_wb_pipreg_clr)
        {wb_vld_pipreg,
         wb_instropreat_pipreg,
         wb_writereg_pipreg,
         wb_writehi_pipreg,
         wb_writelo_pipreg,
         wb_regaddress_pipreg,
         wb_regdata_pipreg,
         wb_hiwdata_pipreg,
         wb_lowdata_pipreg,
         wb_pc_pipreg}
     <= 138'b0;
    else if (am_wb_pipreg_en)
        {wb_vld_pipreg,
         wb_instropreat_pipreg,
         wb_writereg_pipreg,
         wb_writehi_pipreg,
         wb_writelo_pipreg,
         wb_regaddress_pipreg,
         wb_regdata_pipreg,
         wb_hiwdata_pipreg,
         wb_lowdata_pipreg,
         wb_pc_pipreg}
     <= {am_vld_pipreg,
         am_instropreat,
         cft_am_wreg,
         cft_am_whi,
         cft_am_wlo,
         am_regaddress,
         am_regdata,
         am_hiwdata,
         am_lowdata,
         am_pc};
end

writeback wb(//input
             .clk                       (clk),
             .rst                       (reset),
             .rs                        (wb_cft_rs),
             .rt                        (wb_cft_rt),
             .inst_opreat               (wb_instropreat_pipreg),
             .write_reg                 (wb_writereg_pipreg),
             .write_hi                  (wb_writehi_pipreg),
             .write_lo                  (wb_writelo_pipreg),
             .write_hi_value            (wb_hiwdata_pipreg),
             .write_lo_value            (wb_lowdata_pipreg),
             .write_reg_address         (wb_regaddress_pipreg),
             .write_reg_value           (wb_regdata_pipreg),
             .am_pc                     (wb_pc_pipreg),
             //output
             .hi_value                  (cft_wb_hidata),
             .lo_value                  (cft_wb_lodata),
             .rs_value                  (cft_wb_rsdata),
             .rt_value                  (cft_wb_rtdata),
             .reg_we                    (debug_wb_rf_wen),
             .reg_waddr                 (debug_wb_rf_wnum),
             .reg_wdata                 (debug_wb_rf_wdata),
             .inst_branchjump           (excep_wb_isbj),
             .wb_pc                     (debug_wb_pc));

conflict_ctrl_unit ctf_unit(//input
                            .id_is_use_reg_s        (cft_id_users),
                            .id_is_use_reg_t        (cft_id_usert),
                            .id_is_use_hi           (cft_id_usehi),
                            .id_is_use_lo           (cft_id_uselo),
                            .id_reg_s               (cft_id_rs),
                            .id_reg_t               (cft_id_rt),
                            .ex_is_write_reg        (cft_ex_wreg),
                            .ex_is_clean_reg        (cft_ex_clereg),
                            .ex_write_reg_address   (cft_ex_regaddr),
                            .ex_write_reg_data      (cft_ex_regdata),
                            .ex_is_write_hi         (cft_ex_whi),
                            .ex_is_write_lo         (cft_ex_wlo),
                            .ex_write_hi_value      (cft_ex_hidata),
                            .ex_write_lo_value      (cft_ex_lodata),
                            .am_is_write_reg        (cft_am_wreg),
                            .am_write_reg_address   (cft_am_regaddr),
                            .am_write_reg_data      (cft_am_regdata),
                            .am_is_write_hi         (cft_am_whi),
                            .am_is_write_lo         (cft_am_wlo),
                            .am_write_hi_value      (cft_am_hidata),
                            .am_write_lo_value      (cft_am_lodata),
                            .wb_hi_value            (cft_wb_hidata),
                            .wb_lo_value            (cft_wb_lodata),
                            .wb_rs_value            (cft_wb_rsdata),
                            .wb_rt_value            (cft_wb_rtdata),
                            //output
                            .reg_s_id_read_address  (wb_cft_rs),
                            .reg_t_id_read_address  (wb_cft_rt),
                            .reg_s_value_latest     (id_cft_rsvalue),
                            .reg_t_value_latest     (id_cft_rtvalue),
                            .hilo_value_latest      (id_cft_hilovalue),
                            .id_unlock              (id_cft_en));

exception_ctrl excep_ctrl(//output
                          .is_exception  (excep_isexception),
                          .is_bd         (cp0_excep_bd),
                          .we_badvaddr   (cp0_excep_webadaddr),
                          .badvaddr      (cp0_excep_badaddr),
                          .excep_code    (cp0_excep_excepcode),
                          .excep_pc      (cp0_excep_excpc),
                          .id_clr        (excep_idclr),
                          .ex_clr        (excep_exclr),
                          .am_clr        (excep_amclr),
                          .wb_clr        (excep_wbclr),
                          //input
                          .excep_am_pc   (am_pc_pipreg),
                          .excep_wb_pc   (wb_pc_pipreg),
                          .wb_is_bj      (excep_wb_isbj),
                          .is_instload   (excep_am_isinstload),
                          .data_address  (data_addr),
                          .is_ie         (excep_cp0_isie),
                          .is_exl        (excep_cp0_isexl),
                          .int_mask      (excep_cp0_intmask),
                          .hardware_int  (hw_int),
                          .soft_int      (excep_cp0_softint),
                          .am_excep_code (excep_am_excepcode));

//synopsys translate_off
class ifq_perf;
	int fetch_num;
	int addr_commit_delay;
	int inst_fetch_delay;
	int issue_num;
	int inst_issue_interval;
	int retire_branch_num;

	int req_queue[$];
	event sync;

	function new();
		fetch_num = 0;
		addr_commit_delay = 0;
		inst_fetch_delay = 0;
		issue_num = 0;
		inst_issue_interval = 0;
		retire_branch_num = 0;
	endfunction
endclass

class bpu_perf;
	bit [31:0] addr;
	int excu_num;
	int trans_num;
	int hit_trans_num;
	int hit_notrans_num;
	int miss_trans_num;
	int miss_notrans_num;
	int victim_num;
	int alloc_num;
	int target_err_num;
	int bpu_err_num;
	int all_fail_num;
	bit [BTB_WAY_NUM-1:0] btb_way_vec;
	bit [BTB_SET_WIDTH-1+2:2] btb_set;
	real alloc_time;

	function new(bit [31:0] addr);
		this.addr = addr;
		excu_num = 0;
		trans_num = 0;
	    hit_trans_num = 0;
	    hit_notrans_num = 0;
	    miss_trans_num = 0;
	    miss_notrans_num = 0;
		victim_num = 0;
		alloc_num = 0;
		target_err_num = 0;
		bpu_err_num = 0;
		all_fail_num = 0;
	endfunction
endclass

class perf_group;
	ifq_perf ifq;
	bpu_perf bpu_mmap[bit [31:0]];
	int btb_usage;

	function new();
		btb_usage = 0;
		ifq = new();
	endfunction

	function void print_ifq(int test_num);
		$display("-----------IFQ Performance Statistics: TEST%0d----------", test_num);
		$display("IFU address commit avge delay:       %5.2f", 1.0*ifq.addr_commit_delay/ifq.fetch_num);
		$display("IFU data fetch avge delay:           %5.2f", 1.0*ifq.inst_fetch_delay/ifq.fetch_num);
		$display("IFU instruction issue avge interval: %5.2f", 1.0*ifq.inst_issue_interval/ifq.issue_num);
		$display("IFU retire branch number:            %0d", ifq.retire_branch_num);
	endfunction

	function void print_bpu(int test_num);
		$display("-----------BPU Performance Statistics: TEST%0d----------", test_num);
		$display("Branch instruction number:     %0d", bpu_mmap.size());
		$display("Branch execute count:          %0d", bpu_mmap.sum with(item.excu_num));
		$display("Branch transfer count:         %0d", bpu_mmap.sum() with(item.trans_num));
		$display("BTB hit & transfer count:      %0d", bpu_mmap.sum() with(item.hit_trans_num));
		$display("BTB hit & not transfer count:  %0d", bpu_mmap.sum() with(item.hit_notrans_num));
		$display("BTB miss & transfer count:     %0d", bpu_mmap.sum() with(item.miss_trans_num));
		$display("BTB miss & not transfer count: %0d", bpu_mmap.sum() with(item.miss_notrans_num));
		$display("BTB entry victim count:        %0d", bpu_mmap.sum() with(item.victim_num));
		$display("BTB entry allocate count:      %0d", bpu_mmap.sum() with(item.alloc_num));
		$display("BTB target error count:        %0d", bpu_mmap.sum() with(item.target_err_num));
		$display("BPU predict error count:       %0d", bpu_mmap.sum() with(item.bpu_err_num));
		$display("BPU failure count:             %0d", bpu_mmap.sum() with(item.all_fail_num));

		$display("Branch transfer rate:          %5.2f%%", 100.0*bpu_mmap.sum() with(item.trans_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB hit & transfer rate:       %5.2f%%", 100.0*bpu_mmap.sum() with(item.hit_trans_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB hit & not transfer rate:   %5.2f%%", 100.0*bpu_mmap.sum() with(item.hit_notrans_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB miss & transfer rate:      %5.2f%%", 100.0*bpu_mmap.sum() with(item.miss_trans_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB miss & not transfer rate:  %5.2f%%", 100.0*bpu_mmap.sum() with(item.miss_notrans_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB target error in hit rate:  %5.2f%%", 100.0*bpu_mmap.sum() with(item.target_err_num)/bpu_mmap.sum() with(item.hit_trans_num));
		$display("BPU predict error in hit rate: %5.2f%%", 100.0*bpu_mmap.sum() with(item.bpu_err_num)/bpu_mmap.sum() with(item.hit_trans_num));
		$display("BPU all failure rate:          %5.2f%%", 100.0*bpu_mmap.sum() with(item.all_fail_num)/bpu_mmap.sum() with(item.excu_num));
		$display("BTB usage rate:                %5.2f%%", 100.0*btb_usage/(BTB_WAY_NUM*(2**BTB_SET_WIDTH)));
	endfunction
endclass

perf_group perfs[$];

initial fork
	forever begin
		perf_group collect_now;
		@(posedge reset);
		if(perfs.size > 0) begin
			for(int i=0; i<2**BTB_SET_WIDTH; i++)
				for(int j=0; j<BTB_WAY_NUM; j++)
					perfs[$].btb_usage += if_unit.bpu.entry_vld[i][j];

			foreach(perfs[$].bpu_mmap[i])
				perfs[$].bpu_mmap[i].btb_way_vec = '0;
		end

		collect_now = new();
		perfs.push_back(collect_now);
	end
	forever begin
		@(posedge clk iff id_ex_pipreg_en && ex_vld_pipreg && ex.inst_opreat_[0]); // ex stage is branch inst
		if(!perfs[$].bpu_mmap.exists(ex.ex_pc))
			perfs[$].bpu_mmap[ex.ex_pc] = new(ex.ex_pc);
		perfs[$].bpu_mmap[ex.ex_pc].excu_num++;
		perfs[$].bpu_mmap[ex.ex_pc].trans_num += ex.real_is_jump_branch;
		perfs[$].bpu_mmap[ex.ex_pc].hit_trans_num += (|ex.btb_way_vec) & ex.real_is_jump_branch;
		perfs[$].bpu_mmap[ex.ex_pc].hit_notrans_num += (|ex.btb_way_vec) & (!ex.real_is_jump_branch);
		perfs[$].bpu_mmap[ex.ex_pc].miss_trans_num += (!(|ex.btb_way_vec)) & ex.real_is_jump_branch;
		perfs[$].bpu_mmap[ex.ex_pc].miss_notrans_num += (!(|ex.btb_way_vec)) & (!ex.real_is_jump_branch);
		perfs[$].bpu_mmap[ex.ex_pc].target_err_num += (|ex.btb_way_vec) & ex.real_is_jump_branch & ex.btb_addr_fail;
		perfs[$].bpu_mmap[ex.ex_pc].bpu_err_num += (|ex.btb_way_vec) & (ex.real_is_jump_branch ^ ex.predict_is_branch);
		perfs[$].bpu_mmap[ex.ex_pc].all_fail_num += ex.is_jump_branch;
	end
	forever begin
		@(posedge clk iff if_unit.bpu.fail && (~(|if_unit.bpu.fail_way_vec)));
		if(&if_unit.bpu.entry_vld[if_unit.bpu.fail_branch[BTB_SET_WIDTH-1+2:2]]) begin
			bpu_perf btb_victim_entry[$];
			btb_victim_entry = perfs[$].bpu_mmap.find() with((item.btb_way_vec == if_unit.bpu.fill_way_vec) &&
			                                            (item.btb_set == if_unit.bpu.fail_branch[BTB_SET_WIDTH-1+2:2]));
			if(btb_victim_entry.size != 1) begin
				$error("BTB replace find error: size = %d",btb_victim_entry.size);
				foreach(btb_victim_entry[i])
					$display("the entry[%d] allocate time: %t", i, btb_victim_entry[i].alloc_time);
				$stop;
			end
			btb_victim_entry[0].victim_num++;
			btb_victim_entry[0].btb_way_vec = '0;
		end
		perfs[$].bpu_mmap[if_unit.bpu.fail_branch].alloc_num++;
		perfs[$].bpu_mmap[if_unit.bpu.fail_branch].btb_way_vec = if_unit.bpu.fill_way_vec;
		perfs[$].bpu_mmap[if_unit.bpu.fail_branch].btb_set = if_unit.bpu.fail_branch[BTB_SET_WIDTH-1+2:2];
		perfs[$].bpu_mmap[if_unit.bpu.fail_branch].alloc_time = $realtime;
	end
	forever begin
		@(posedge clk iff inst_addr_valid & inst_addr_ready);
		perfs[$].ifq.fetch_num++;
	end
	forever begin
		@(posedge clk iff inst_addr_valid);
		perfs[$].ifq.addr_commit_delay++;
	end
	forever begin
		@(posedge clk iff ~reset);
		foreach(perfs[$].ifq.req_queue[i])
			perfs[$].ifq.req_queue[i]++;
		-> perfs[$].ifq.sync;
	end
	forever begin
		@(posedge clk iff inst_addr_valid & inst_addr_ready);
		wait(perfs[$].ifq.sync.triggered);
		perfs[$].ifq.req_queue.push_back(0);
	end
	forever begin
		int delay;
		@(posedge clk iff inst_line_valid & inst_line_ready);
		wait(perfs[$].ifq.sync.triggered);
		delay = perfs[$].ifq.req_queue.pop_front();
		perfs[$].ifq.inst_fetch_delay += delay;
	end
	forever begin
		@(posedge clk iff inst_valid & inst_ready);
		perfs[$].ifq.issue_num++;
	end
	forever begin
		@(posedge clk iff (~reset) && (~inst_valid));
		perfs[$].ifq.inst_issue_interval++;
	end
	forever begin
		@(posedge clk iff (~if_unit.inst_empty) && (~if_unit.pc_valid) && (|if_unit.btb_way_vec));
		perfs[$].ifq.retire_branch_num++;
	end
join

final begin
	foreach(perfs[i]) begin
		perfs[i].print_ifq(i+1);
		perfs[i].print_bpu(i+1);
	end
end
//synopsys translate_on

endmodule

`include "pe_undefs.vh"

