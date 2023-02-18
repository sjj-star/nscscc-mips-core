`timescale 1ns / 1ps
`include "defs.vh"

module pipeline_cpu(
    clk,
    reset,
    int,
    instruction_valid,
    instruction_ready,
    instruction_addr,
    instruction,
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
input  wire [5:0]  int;
output wire        instruction_valid;
input  wire        instruction_ready;
output wire [31:0] instruction_addr;
input  wire [31:0] instruction;
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

wire        if_cft_pcen;
wire [31:0] if_ex_bjpc;
wire        if_ex_isbj;
wire [31:0] if_pc;
wire [29:0] if_pc4;
wire [31:0] if_inst_q;
wire [4:0]  if_excepcode;
reg  [31:0] id_instruction_pipreg;
wire        if_cft_pipen;
reg  [31:0] id_pc_pipreg;
reg  [29:0] id_pc4_pipreg;
reg  [4:0]  id_excepcode_pipreg;
wire [31:0] id_cft_rsvalue;
wire [31:0] id_cft_rtvalue;
wire [31:0] id_cft_hilovalue;
wire [43:0] id_instropreat;
wire [4:0]  id_regaddress;
wire [7:0]  id_copaddr;
wire [31:0] id_hilovalue;
wire        id_iswritereg;
wire        id_iswritehi;
wire        id_iswritelo;
wire [31:0] id_bjpc;
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
wire        ex_cft_clr;
reg  [43:0] ex_instropreat_pipreg;
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
wire [31:0] data_rdata_q;
wire        cft_am_wreg;
wire [4:0]  cft_am_regaddr;
wire [31:0] cft_am_regdata;
wire        cft_am_whi;
wire        cft_am_wlo;
wire [31:0] cft_am_hidata;
wire [31:0] cft_am_lodata;
wire [31:0] am_pc;
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

wire pc_reg_en;
wire inst_fetch_en;
wire inst_fetch;
wire inst_q_empty;
wire if_id_pipreg_clr;
wire if_id_pipreg_en;
wire id_ex_pipreg_clr;
wire id_ex_pipreg_en;
wire ex_am_pipreg_clr;
wire ex_am_pipreg_en;
wire am_wb_pipreg_clr;
wire am_wb_pipreg_en;
wire data_req;
wire data_tr_retire;
wire data_q_empty;
wire wb_regfile_en;
wire ibus_over;
wire dbus_over;
wire ibus_busy;
wire dbus_busy;
wire bus_busy;

assign ibus_over = instruction_valid & instruction_ready;
assign dbus_over = data_valid & data_ready;
assign ibus_busy = instruction_valid & (~instruction_ready);
assign dbus_busy = data_valid & (~data_ready);
assign bus_busy  = ibus_busy | dbus_busy;

assign pc_reg_en        = (if_cft_pcen & ex_opover & (~bus_busy))|excep_isexception|excep_id_isexcepreturn;
assign inst_fetch_en    = if_cft_pipen & (~(excep_isexception|excep_id_isexcepreturn|excep_if_laddrerror|if_ex_isbj));
assign instruction_valid= inst_fetch_en & inst_q_empty;
assign inst_fetch       = inst_fetch_en & ex_opover & (~bus_busy);

assign if_id_pipreg_clr = ((~dbus_busy) & if_ex_isbj)|excep_idclr|(excep_id_isexcepreturn & ex_opover)|reset;
assign if_id_pipreg_en  = (if_cft_pipen & ex_opover & (~bus_busy))|excep_isexception;

assign id_ex_pipreg_clr = excep_exclr|(ex_cft_clr & (~dbus_busy))|reset;
assign id_ex_pipreg_en  = (ex_opover & (~bus_busy))|excep_isexception;

assign ex_am_pipreg_clr = excep_amclr|reset;
assign ex_am_pipreg_en  = (ex_opover & (~bus_busy))|excep_isexception;

assign am_wb_pipreg_clr = excep_wbclr|reset;
assign am_wb_pipreg_en  = (ex_opover & (~bus_busy))|excep_isexception;
assign data_valid       = data_req & data_q_empty;
assign data_tr_retire   = data_req & ex_opover & (~bus_busy);

assign wb_regfile_en = (ex_opover & (~bus_busy))|excep_isexception;

assign instruction_addr = if_pc;

pc pc_pipelinereg(//input
                  .clk                   (clk),
                  .rst                   (reset),
                  .pc_reg_enable         (pc_reg_en),
                  .jump_branch_address   (if_ex_bjpc),
                  .is_jump_branch        (if_ex_isbj),
                  //execption
                  .is_exception          (excep_isexception),
                  .is_excep_return       (excep_id_isexcepreturn),
                  .excep_return_pc       (if_cp0_returnpc),
                  //output
                  .pc_reg                (if_pc),
                  .pc_4                  (if_pc4),
                  //exception
                  .excep_code            (if_excepcode),
                  .execption_is_laddress (excep_if_laddrerror));

bypass_fifo #(
    .WIDTH(32),
    .DEEP_SIZE(0)
) inst_queue(
    .clk(clk),
    .reset(reset),
    .read(inst_fetch),
    .write(ibus_over),
    .indata(instruction),
    .outdata(if_inst_q),
    .empty(inst_q_empty),
    .full()
);

always @ (posedge clk)
begin
    if (if_id_pipreg_clr)
        {id_pc_pipreg,
         id_pc4_pipreg,
         id_instruction_pipreg,
         id_excepcode_pipreg}
     <= {32'b0,30'b0,`INST_INTI,`INVALID_EXCEP};
    else if (if_id_pipreg_en)
        {id_pc_pipreg,
         id_pc4_pipreg,
         id_instruction_pipreg,
         id_excepcode_pipreg}
     <= {if_pc,
         if_pc4,
         if_inst_q,
         if_excepcode};
end

decode id(//input
          .inst                     (id_instruction_pipreg),
          .pc_delayslot             (id_pc4_pipreg),
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
    if (id_ex_pipreg_clr)
        {ex_instropreat_pipreg,
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
         ex_excepcode_pipreg}
     <= {252'b0,`INVALID_EXCEP};
    else if (id_ex_pipreg_en)
        {ex_instropreat_pipreg,
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
         ex_excepcode_pipreg}
     <= {id_instropreat,
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
         id_excepcode};
end

myexecute ex(//input
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
             .is_busbusy                (bus_busy),
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
    if (ex_am_pipreg_clr)
        {am_instropreat_pipreg,
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
     <= {218'b0,`INVALID_EXCEP};
    else if (ex_am_pipreg_en)
        {am_instropreat_pipreg,
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
     <= {ex_instropreat,
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
             .hardware_int      (int),
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

bypass_fifo #(
    .WIDTH(32),
    .DEEP_SIZE(0)
) data_req_queue(
    .clk(clk),
    .reset(reset),
    .read(data_tr_retire),
    .write(dbus_over),
    .indata(data_rdata),
    .outdata(data_rdata_q),
    .empty(data_q_empty),
    .full()
);

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
             .mem_req                   (data_req),
             .mem_wr                    (data_wr),
             .mem_size                  (data_size),
             .mem_wstrb                 (data_wstrb),
             .mem_address_              (data_addr),
             .read_mem_data             (data_rdata_q),
             .write_mem_data            (data_wdata));

always @ (posedge clk)
begin
    if (am_wb_pipreg_clr)
        {wb_instropreat_pipreg,
         wb_writereg_pipreg,
         wb_writehi_pipreg,
         wb_writelo_pipreg,
         wb_regaddress_pipreg,
         wb_regdata_pipreg,
         wb_hiwdata_pipreg,
         wb_lowdata_pipreg,
         wb_pc_pipreg}
     <= 137'b0;
    else if (am_wb_pipreg_en)
        {wb_instropreat_pipreg,
         wb_writereg_pipreg,
         wb_writehi_pipreg,
         wb_writelo_pipreg,
         wb_regaddress_pipreg,
         wb_regdata_pipreg,
         wb_hiwdata_pipreg,
         wb_lowdata_pipreg,
         wb_pc_pipreg}
     <= {am_instropreat,
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
             .write_reg                 (wb_writereg_pipreg & wb_regfile_en),
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
                            .pc_reg_en              (if_cft_pcen),
                            .if_id_reg_en           (if_cft_pipen),
                            .id_ex_reg_clr          (ex_cft_clr));

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
                          .excep_ex_pc   (ex_pc_pipreg),
                          .excep_am_pc   (am_pc_pipreg),
                          .excep_wb_pc   (wb_pc_pipreg),
                          .wb_is_bj      (excep_wb_isbj),
                          .is_instload   (excep_am_isinstload),
                          .data_address  (data_addr),
                          .is_ie         (excep_cp0_isie),
                          .is_exl        (excep_cp0_isexl),
                          .int_mask      (excep_cp0_intmask),
                          .hardware_int  (int),
                          .soft_int      (excep_cp0_softint),
                          .am_excep_code (excep_am_excepcode));
endmodule
