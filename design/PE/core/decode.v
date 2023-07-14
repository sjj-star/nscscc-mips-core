`timescale 1ns / 1ps
`include "pe_defs.vh"

module decode(
//output
    inst_opreat,
    reg_t_d_31,
    reg_t_value,
    alu_opreatA,
    alu_opreatB,
    hi_lo_value,
    is_write_reg,
    is_write_hi,
    is_write_lo,
    jump_branch_address,
	btb_addr_fail,
    cop_address,
    //check confict
    check_is_use_reg_s,
    check_is_use_reg_t,
    check_is_use_hi,
    check_is_use_lo,
    check_reg_s,
    check_reg_t,
    //exception
    excep_code,
    exception_is_return,
    //debug info
    id_pc,
    //start
//input
    inst,
    pc_delayslot,
	predict_pc,
    reg_s_value_latest,
    reg_t_value_latest,
    hilo_value_latest,
    //exception
    if_excep_code,
    //debug info
    if_pc);

input  wire [31:0] inst;
input  wire [29:0] pc_delayslot;
input  wire [31:0] predict_pc;
input  wire [31:0] reg_s_value_latest;
input  wire [31:0] reg_t_value_latest;
input  wire [31:0] hilo_value_latest;
input  wire [4:0]  if_excep_code;
input  wire [31:0] if_pc;
output wire [44:0] inst_opreat;
output wire [4:0]  reg_t_d_31;
output wire [31:0] reg_t_value;
output wire [31:0] alu_opreatA;
output reg  [31:0] alu_opreatB;
output wire [31:0] hi_lo_value;
output wire        is_write_reg;
output wire        is_write_hi;
output wire        is_write_lo;
output wire [31:0] jump_branch_address;
output wire        btb_addr_fail;
output wire [7:0]  cop_address;
output wire        check_is_use_reg_s;
output wire        check_is_use_reg_t;
output wire        check_is_use_hi;
output wire        check_is_use_lo;
output wire [4:0]  check_reg_s;
output wire [4:0]  check_reg_t;
output reg  [4:0]  excep_code;
output wire        exception_is_return;
output wire [31:0] id_pc;

wire [5:0]  op;
wire [4:0]  rs;
wire [4:0]  rt;
wire [4:0]  rd;
wire [4:0]  sa;
wire [5:0]  funct;
wire [15:0] imm;
wire [15:0] offset;
wire [25:0] target;
wire [2:0]  cp0r_sel;

assign rs       = inst[25:21];  // 源操作数1
assign rt       = inst[20:16];  // 源操作数2
assign rd       = inst[15:11];  // 目标操作数
assign sa       = inst[10:6];   // 特殊域，可能存放偏移量
assign imm      = inst[15:0];   // 立即数
assign offset   = inst[15:0];   // 地址偏移量
assign target   = inst[25:0];   // 目标地址
assign cp0r_sel = inst[2:0];   // cp0寄存器的select域

assign id_pc = if_pc;
assign reg_t_value = reg_t_value_latest;
assign hi_lo_value = hilo_value_latest;
assign cop_address = {rd,cp0r_sel};
assign check_reg_s = rs;
assign check_reg_t = rt;

wire is_err_instaddr;
assign is_err_instaddr = |id_pc[1:0];

wire inst_add       = (!is_err_instaddr) & (&{inst[5]}) & (~(|{inst[31:26],inst[10:6],inst[4:0]}));
wire inst_addi      = (!is_err_instaddr) & (&{inst[29]}) & (~(|{inst[31:30],inst[28:26]}));
wire inst_addu      = (!is_err_instaddr) & (&{inst[5],inst[0]}) & (~(|{inst[31:26],inst[10:6],inst[4:1]}));
wire inst_addiu     = (!is_err_instaddr) & (&{inst[29],inst[26]}) & (~(|{inst[31:30],inst[28:27]}));
wire inst_sub       = (!is_err_instaddr) & (&{inst[5],inst[1]}) & (~(|{inst[31:26],inst[10:6],inst[4:2],inst[0]}));
wire inst_subu      = (!is_err_instaddr) & (&{inst[5],inst[1:0]}) & (~(|{inst[31:26],inst[10:6],inst[4:2]}));
wire inst_slt       = (!is_err_instaddr) & (&{inst[5],inst[3],inst[1]}) & (~(|{inst[31:26],inst[10:6],inst[4],inst[2],inst[0]}));
wire inst_slti      = (!is_err_instaddr) & (&{inst[29],inst[27]}) & (~(|{inst[31:30],inst[28],inst[26]}));
wire inst_sltu      = (!is_err_instaddr) & (&{inst[5],inst[3],inst[1:0]}) & (~(|{inst[31:26],inst[10:6],inst[4],inst[2]}));
wire inst_sltiu     = (!is_err_instaddr) & (&{inst[29],inst[27:26]}) & (~(|{inst[31:30],inst[28]}));
wire inst_div       = (!is_err_instaddr) & (&{inst[4:3],inst[1]}) & (~(|{inst[31:26],inst[15:5],inst[2],inst[0]}));
wire inst_dviu      = (!is_err_instaddr) & (&{inst[4:3],inst[1:0]}) & (~(|{inst[31:26],inst[15:5],inst[2]}));
wire inst_mult      = (!is_err_instaddr) & (&{inst[4:3]}) & (~(|{inst[31:26],inst[15:5],inst[2:0]}));
wire inst_multu     = (!is_err_instaddr) & (&{inst[4:3],inst[0]}) & (~(|{inst[31:26],inst[15:5],inst[2:1]}));
wire inst_and       = (!is_err_instaddr) & (&{inst[5],inst[2]}) & (~(|{inst[31:26],inst[10:6],inst[4:3],inst[1:0]}));
wire inst_andi      = (!is_err_instaddr) & (&{inst[29:28]}) & (~(|{inst[31:30],inst[27:26]}));
wire inst_lui       = (!is_err_instaddr) & (&{inst[29:26]}) & (~(|{inst[31:30],inst[25:21]}));
wire inst_nor       = (!is_err_instaddr) & (&{inst[5],inst[2:0]}) & (~(|{inst[31:26],inst[10:6],inst[4:3]}));
wire inst_or        = (!is_err_instaddr) & (&{inst[5],inst[2],inst[0]}) & (~(|{inst[31:26],inst[10:6],inst[4:3],inst[1]}));
wire inst_ori       = (!is_err_instaddr) & (&{inst[29:28],inst[26]}) & (~(|{inst[31:30],inst[27]}));
wire inst_xor       = (!is_err_instaddr) & (&{inst[5],inst[2:1]}) & (~(|{inst[31:26],inst[10:6],inst[4:3],inst[0]}));
wire inst_xori      = (!is_err_instaddr) & (&{inst[29:27]}) & (~(|{inst[31:30],inst[26]}));
wire inst_sllv      = (!is_err_instaddr) & (&inst[2]) & (~(|{inst[31:26],inst[10:3],inst[1:0]}));
wire inst_sll       = (!is_err_instaddr) & (~(|{inst[31:21],inst[5:0]}));
wire inst_srav      = (!is_err_instaddr) & (&inst[2:0]) & (~(|{inst[31:26],inst[10:3]}));
wire inst_sra       = (!is_err_instaddr) & (&{inst[1:0]}) & (~(|{inst[31:21],inst[5:2]}));
wire inst_srlv      = (!is_err_instaddr) & (&inst[2:1]) & (~(|{inst[31:26],inst[10:3],inst[0]}));
wire inst_srl       = (!is_err_instaddr) & (&{inst[1]}) & (~(|{inst[31:21],inst[5:2],inst[0]}));
wire inst_beq       = (!is_err_instaddr) & (&{inst[28]}) & (~(|{inst[31:29],inst[27:26]}));
wire inst_bne       = (!is_err_instaddr) & (&{inst[28],inst[26]}) & (~(|{inst[31:29],inst[27]}));
wire inst_bgez      = (!is_err_instaddr) & (&{inst[26],inst[16]}) & (~(|{inst[31:27],inst[20:17]}));
wire inst_bgtz      = (!is_err_instaddr) & (&{inst[28:26]}) & (~(|{inst[31:29],inst[20:16]}));
wire inst_blez      = (!is_err_instaddr) & (&{inst[28:27]}) & (~(|{inst[31:29],inst[26],inst[20:16]}));
wire inst_bltz      = (!is_err_instaddr) & (&{inst[26]}) & (~(|{inst[31:27],inst[20:16]}));
wire inst_bgezal    = (!is_err_instaddr) & (&{inst[26],inst[20],inst[16]}) & (~(|{inst[31:27],inst[19:17]}));
wire inst_bltzal    = (!is_err_instaddr) & (&{inst[26],inst[20]}) & (~(|{inst[31:27],inst[19:16]}));
wire inst_j         = (!is_err_instaddr) & (&{inst[27]}) & (~(|{inst[31:28],inst[26]}));
wire inst_jal       = (!is_err_instaddr) & (&{inst[27:26]}) & (~(|{inst[31:28]}));
wire inst_jr        = (!is_err_instaddr) & (&{inst[3]}) & (~(|{inst[31:26],inst[20:4],inst[2:0]}));
wire inst_jalr      = (!is_err_instaddr) & (&{inst[3],inst[0]}) & (~(|{inst[31:26],inst[20:16],inst[10:4],inst[2:1]}));
wire inst_mfhi      = (!is_err_instaddr) & (&{inst[4]}) & (~(|{inst[31:16],inst[10:5],inst[3:0]}));
wire inst_mflo      = (!is_err_instaddr) & (&{inst[4],inst[1]}) & (~(|{inst[31:16],inst[10:5],inst[3:2],inst[0]}));
wire inst_mthi      = (!is_err_instaddr) & (&{inst[4],inst[0]}) & (~(|{inst[31:26],inst[20:5],inst[3:1]}));
wire inst_mtlo      = (!is_err_instaddr) & (&{inst[4],inst[1:0]}) & (~(|{inst[31:26],inst[20:5],inst[3:2]}));
wire inst_break     = (!is_err_instaddr) & (&{inst[3:2],inst[0]}) & (~(|{inst[31:26],inst[5:4],inst[1]}));
wire inst_syscall   = (!is_err_instaddr) & (&{inst[3:2]}) & (~(|{inst[31:26],inst[5:4],inst[1:0]}));
wire inst_lb        = (!is_err_instaddr) & (&{inst[31]}) & (~(|{inst[30:26]}));
wire inst_lbu       = (!is_err_instaddr) & (&{inst[31],inst[28]}) & (~(|{inst[30:29],inst[27:26]}));
wire inst_lh        = (!is_err_instaddr) & (&{inst[31],inst[26]}) & (~(|{inst[30:27]}));
wire inst_lhu       = (!is_err_instaddr) & (&{inst[31],inst[28],inst[26]}) & (~(|{inst[30:29],inst[27]}));
wire inst_lw        = (!is_err_instaddr) & (&{inst[31],inst[27:26]}) & (~(|{inst[30:28]}));
wire inst_sb        = (!is_err_instaddr) & (&{inst[31],inst[29]}) & (~(|{inst[30],inst[28:26]}));
wire inst_sh        = (!is_err_instaddr) & (&{inst[31],inst[29],inst[26]}) & (~(|{inst[30],inst[28:27]}));
wire inst_sw        = (!is_err_instaddr) & (&{inst[31],inst[29],inst[27:26]}) & (~(|{inst[30],inst[28]}));
wire inst_eret      = (!is_err_instaddr) & (&{inst[30],inst[25],inst[4:3]}) & (~(|{inst[31],inst[29:26],inst[24:5],inst[2:0]}));
wire inst_mfc0      = (!is_err_instaddr) & (&{inst[30]}) & (~(|{inst[31],inst[29:21],inst[10:3]}));
wire inst_mtc0      = (!is_err_instaddr) & (&{inst[30],inst[23]}) & (~(|{inst[31],inst[29:24],inst[22:21],inst[10:3]}));

wire inst_invalid   = ~(inst_add|inst_addi|inst_addu|inst_addiu|inst_sub|inst_subu|inst_slt|inst_slti|
                       inst_sltu|inst_sltiu|inst_div|inst_dviu|inst_mult|inst_multu|inst_and|inst_andi|inst_lui|
                       inst_nor|inst_or|inst_ori|inst_xor|inst_xori|inst_sll|inst_sllv|inst_sra|inst_srav|
                       inst_srl|inst_srlv|inst_beq|inst_bne|inst_bgez|inst_bgtz|inst_blez|inst_bltz|
                       inst_bgezal|inst_bltzal|inst_j|inst_jal|inst_jr|inst_jalr|inst_mflo|inst_mfhi|
                       inst_mtlo|inst_mthi|inst_break|inst_syscall|inst_lb|inst_lbu|inst_lh|inst_lhu|
                       inst_lw|inst_sb|inst_sh|inst_sw|inst_mfc0|inst_mtc0|inst_eret) & (!is_err_instaddr);

/* ex */
wire check_is_clean_reg = inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_subu | inst_slt|
                          inst_slti | inst_sltu | inst_sltiu | inst_and | inst_andi | inst_lui | inst_nor|
                          inst_or | inst_ori | inst_xor | inst_xori | inst_sll | inst_sllv | inst_sra|
                          inst_srav | inst_srl | inst_srlv | inst_jal | inst_jalr | inst_bgezal | inst_bltzal|
                          inst_mflo | inst_mfhi;

wire is_ret = inst_jr & (&rs);

/* am */
wire inst_writereg_exdata = (inst_add|inst_addi|inst_addu|inst_addiu|inst_sub|inst_subu|inst_slt|inst_slti|
                             inst_sltu|inst_sltiu|inst_and|inst_andi|inst_lui|inst_nor|inst_or|inst_ori|
                             inst_xor|inst_xori|inst_sll|inst_sllv|inst_sra|inst_srav|inst_srl|inst_srlv|
                             inst_jal|inst_jalr|inst_bgezal|inst_bltzal|inst_mflo|inst_mfhi);
wire is_instload = inst_lw | inst_lh | inst_lb | inst_lhu | inst_lbu;
wire mem_req = (inst_lw | inst_lh | inst_lb | inst_lhu | inst_lbu | inst_sb | inst_sh | inst_sw);
wire mem_wr = inst_sb | inst_sh | inst_sw;
wire [1:0] mem_size = {(inst_lw|inst_sw),(inst_lh|inst_lhu|inst_sh)};
wire data_signed = inst_lh | inst_lb;

/* wb */
wire inst_branchjump = inst_beq|inst_bne|inst_bgez|inst_bgtz|
                       inst_blez|inst_bltz|inst_bgezal|inst_bltzal|
                       inst_jalr|inst_jr|inst_jal|inst_j;

assign inst_opreat = {/* ex */
                      inst_add|inst_addi,
                      inst_addu|inst_addiu,
                      inst_sub,
                      inst_subu,
                      inst_slt|inst_slti,
                      inst_sltu|inst_sltiu,
                      inst_div,
                      inst_dviu,
                      inst_mult,
                      inst_multu,
                      inst_and|inst_andi,
                      inst_lui,
                      inst_nor,
                      inst_or|inst_ori,
                      inst_xor|inst_xori,
                      inst_sll|inst_sllv,
                      inst_sra|inst_srav,
                      inst_srl|inst_srlv,
                      inst_jal|inst_jalr|inst_bgezal|inst_bltzal,
                      inst_mflo|inst_mfhi,
                      inst_mtlo,
                      inst_mthi,
                      inst_lh|inst_lhu,
                      inst_lw,
                      inst_sh,
                      inst_sw,
                      inst_beq,
                      inst_bne,
                      inst_bgtz,
                      inst_blez,
                      inst_bltz|inst_bltzal,
                      inst_bgez|inst_bgezal,
                      inst_jalr|inst_jr|inst_jal|inst_j,
					  is_ret,
                      check_is_clean_reg,
                      /* am */
                      inst_writereg_exdata,
                      is_instload,
                      mem_req,
                      mem_wr,
                      mem_size,
                      data_signed,
                      inst_mfc0,
                      inst_mtc0,
                      /* wb */
                      inst_branchjump};

always @ (*)
begin
    case(1'b1)
        inst_break: excep_code = `BP;
        inst_syscall: excep_code = `SYS;
        inst_invalid: excep_code = `RI;
        default: excep_code = if_excep_code;
    endcase
end

assign alu_opreatA = (inst_sll | inst_sllv | inst_sra | inst_srav | inst_srl | inst_srlv) ?
                     reg_t_value_latest : reg_s_value_latest;

always @ (*)
begin
    case(1'b1)
        inst_sw|inst_sh|inst_sb|inst_lw|inst_lhu|inst_lh|inst_lbu|inst_lb|inst_sltiu|inst_slti|inst_addi|inst_addiu:
            alu_opreatB = {{16{imm[15]}},imm};
        inst_xori|inst_ori|inst_andi:
            alu_opreatB = {16'b0, imm};
        inst_lui:
            alu_opreatB = {imm, 16'b0};
        inst_srl|inst_sra|inst_sll:
            alu_opreatB = {27'b0,sa};
        default:
            alu_opreatB = (inst_sll | inst_sllv | inst_sra | inst_srav | inst_srl | inst_srlv) ?
                           reg_s_value_latest : reg_t_value_latest;
    endcase
end

wire [31:0] branch_address;
assign branch_address = {(pc_delayslot + {{14{offset[15]}},offset}),2'b0};

assign jump_branch_address = ({32{inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bgezal | inst_bltzal}} & branch_address)
                           | ({32{inst_jr | inst_jalr}} & reg_s_value_latest)
                           | ({32{inst_j | inst_jal}} & {pc_delayslot[29:26],target,2'b00});

assign btb_addr_fail = |(jump_branch_address ^ predict_pc);

//always @ (*)
//begin
//    case(1'b1)
//        inst_beq:               is_jump_branch = reg_t_value_latest==reg_s_value_latest;
//        inst_bne:               is_jump_branch = reg_t_value_latest!=reg_s_value_latest;
//        inst_bgtz:              is_jump_branch = (~reg_s_value_latest[31]) && (|reg_s_value_latest);
//        inst_blez:              is_jump_branch = reg_s_value_latest[31] || (~(|reg_s_value_latest));
//        inst_bltz,inst_bltzal:  is_jump_branch = reg_s_value_latest[31];
//        inst_bgez,inst_bgezal:  is_jump_branch = ~reg_s_value_latest[31];
//        inst_jalr,inst_jr,inst_jal,inst_j:
//                                is_jump_branch = 1'b1;
//        default:                is_jump_branch = 1'b0;
//    endcase
//end

assign is_write_reg = inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_subu | inst_slt|
                      inst_slti | inst_sltu | inst_sltiu | inst_and | inst_andi | inst_lui | inst_nor|
                      inst_or | inst_ori | inst_xor | inst_xori | inst_sll | inst_sllv | inst_sra|
                      inst_srav | inst_srl | inst_srlv | inst_jal | inst_jalr | inst_bgezal | inst_bltzal|
                      inst_mflo | inst_mfhi| inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_mfc0;

assign is_write_hi = inst_div | inst_dviu | inst_mult | inst_multu | inst_mthi;

assign is_write_lo = inst_div | inst_dviu | inst_mult | inst_multu | inst_mtlo;

assign check_is_use_reg_s = inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_slt |
                            inst_subu | inst_slti | inst_sltu | inst_sltiu | inst_div | inst_dviu |
                            inst_mult | inst_multu | inst_and | inst_andi | inst_nor | inst_or |
                            inst_ori | inst_xor | inst_xori | inst_sllv | inst_srav | inst_srlv |
                            inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz |
                            inst_bgezal | inst_bltzal | inst_jr | inst_jalr | inst_mtlo | inst_mthi |
                            inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_sb | inst_sh | inst_sw;

assign check_is_use_reg_t = inst_add | inst_addu | inst_sub | inst_subu | inst_slt | inst_sltu |
                            inst_div | inst_dviu | inst_mult | inst_multu | inst_and | inst_nor|
                            inst_or | inst_xor | inst_sll | inst_sllv | inst_sra | inst_srav |
                            inst_srl | inst_srlv | inst_beq | inst_bne | inst_sb | inst_sh |
                            inst_sw | inst_mtc0;

assign check_is_use_hi = inst_mfhi;

assign check_is_use_lo = inst_mflo;

assign reg_t_d_31 = (inst_add | inst_addu | inst_sub | inst_subu | inst_slt | inst_sltu | inst_and |
                     inst_nor | inst_or | inst_xor | inst_sll | inst_sllv | inst_sra | inst_srav | 
                     inst_srl | inst_srlv | inst_mflo | inst_mfhi)
                     ? rd : (inst_bgezal | inst_bltzal | inst_jal | inst_jalr) ? 5'd31 : rt;

assign exception_is_return = inst_eret;

endmodule

`include "pe_undefs.vh"

