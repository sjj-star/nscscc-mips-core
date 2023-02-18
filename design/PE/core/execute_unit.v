`timescale 1ns / 1ps
`include "pe_defs.vh"

module myexecute(
//ouput
    inst_opreat_,
    write_reg_address,
    write_reg_data,
    write_hi_value,
    write_lo_value,
    reg_t_value_,
    cop_address_,
    rw_mem_address,
    opreat_over,
    is_jump_branch,
    jump_branch_address_,
    //check confict
    check_is_write_reg,
    check_is_clean_reg,
    check_write_reg_address,
    check_write_reg_data,
    check_is_write_hi,
    check_is_write_lo,
    check_write_hi_value,
    check_write_lo_value,
    //exception
    excep_code,
    //debug info
    ex_pc,
//input
    clk,
    reset,
    inst_opreat,
    reg_t_d_31,
    reg_t_value,
    alu_opreat_A,
    alu_opreat_B,
    hi_lo_value,
    is_write_reg,
    is_write_hi,
    is_write_lo,
    cop_address,
    jump_branch_address,
    is_busbusy,
    //exception
    id_excep_code,
    //debug info
    id_pc
);

input wire clk;
input wire reset;
input wire [43:0] inst_opreat;
input wire [4:0] reg_t_d_31;
input wire [31:0] reg_t_value;
input wire [31:0] alu_opreat_A;
input wire [31:0] alu_opreat_B;
input wire [31:0] hi_lo_value;
input wire is_write_reg;
input wire is_write_hi;
input wire is_write_lo;
input wire [7:0] cop_address;
input wire [31:0] jump_branch_address;
input wire [4:0] id_excep_code;
input wire [31:0] id_pc;
input wire is_busbusy;
output wire [9:0] inst_opreat_;
output wire [4:0] write_reg_address;
output reg [31:0] write_reg_data;
output reg [31:0] write_hi_value;
output reg [31:0] write_lo_value;
output wire [31:0] reg_t_value_;
output wire [7:0] cop_address_;
output wire [31:0] rw_mem_address;
output wire opreat_over;
output reg is_jump_branch;
output wire [31:0] jump_branch_address_;
output wire check_is_write_reg;
output wire check_is_clean_reg;
output wire [4:0] check_write_reg_address;
output wire [31:0] check_write_reg_data;
output wire check_is_write_hi;
output wire check_is_write_lo;
output wire [31:0] check_write_hi_value;
output wire [31:0] check_write_lo_value;
output reg [4:0] excep_code;
output wire [31:0] ex_pc;

wire inst_add;
wire inst_addu;
wire inst_sub;
wire inst_subu;
wire inst_slt;
wire inst_sltu;
wire inst_div;
wire inst_dviu;
wire inst_mult;
wire inst_multu;
wire inst_and;
wire inst_lui;
wire inst_nor;
wire inst_or;
wire inst_xor;
wire inst_sll;
wire inst_sra;
wire inst_srl;
wire inst_bjlink;
wire inst_mflohi;
wire inst_mtlo;
wire inst_mthi;
wire inst_lh;
wire inst_lw;
wire inst_sh;
wire inst_sw;
wire inst_beq;
wire inst_bne;
wire inst_bgtz;
wire inst_blez;
wire inst_bltz;
wire inst_bgez;
wire inst_j;
assign {inst_add,
        inst_addu,
        inst_sub,
        inst_subu,
        inst_slt,
        inst_sltu,
        inst_div,
        inst_dviu,
        inst_mult,
        inst_multu,
        inst_and,
        inst_lui,
        inst_nor,
        inst_or,
        inst_xor,
        inst_sll,
        inst_sra,
        inst_srl,
        inst_bjlink,
        inst_mflohi,
        inst_mtlo,
        inst_mthi,
        inst_lh,
        inst_lw,
        inst_sh,
        inst_sw,
        inst_beq,
        inst_bne,
        inst_bgtz,
        inst_blez,
        inst_bltz,
        inst_bgez,
        inst_j,
        check_is_clean_reg,
        inst_opreat_} = inst_opreat;

wire is_add_overflow;
wire is_sub_overflow;
wire [31:0] addu_result;
wire [31:0] subu_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] or_result;
wire [31:0] nor_result;
wire [31:0] xor_result;
wire [31:0] sll_result;
wire [31:0] srl_result;
wire [31:0] sra_result;
wire [63:0] mult_result;
wire [63:0] diver_result;
alu ex_alu(.clk             (clk),
           .rst             (reset),
           .is_busbusy      (is_busbusy),
           .alu_opreat_A    (alu_opreat_A),
           .alu_opreat_B    (alu_opreat_B),
           .opreat_over     (opreat_over),
           .is_add_overflow (is_add_overflow),
           .is_sub_overflow (is_sub_overflow),
           .addu_result     (addu_result),
           .subu_result     (subu_result),
           .slt_result      (slt_result),
           .sltu_result     (sltu_result),
           .and_result      (and_result),
           .or_result       (or_result),
           .nor_result      (nor_result),
           .xor_result      (xor_result),
           .sll_result      (sll_result),
           .srl_result      (srl_result),
           .sra_result      (sra_result),
           .mult_start      (inst_mult|inst_multu),
           .mult_sign       (inst_mult),
           .mult_result     (mult_result),
           .diver_start     (inst_div|inst_dviu),
           .div_sign        (inst_div),
           .diver_result    (diver_result));

assign ex_pc = id_pc;
assign reg_t_value_ = reg_t_value;
assign cop_address_ = cop_address;
assign rw_mem_address = addu_result;
assign write_reg_address = reg_t_d_31;
assign jump_branch_address_ = jump_branch_address;
assign check_is_write_reg = is_write_reg & (~(inst_lh&addu_result[0] | inst_lw&(|addu_result[1:0])));
assign check_is_write_hi = is_write_hi;
assign check_is_write_lo = is_write_lo;
assign check_write_reg_address = write_reg_address;
assign check_write_reg_data = write_reg_data;
assign check_write_hi_value = write_hi_value;
assign check_write_lo_value = write_lo_value;
wire [31:0] pc_link;
assign pc_link = {(ex_pc[31:3] + 29'd1),ex_pc[2],2'b0};

always @ (*)
begin
    case(1'b1)
        inst_beq:   is_jump_branch = alu_opreat_A==alu_opreat_B;
        inst_bne:   is_jump_branch = alu_opreat_A!=alu_opreat_B;
        inst_bgtz:  is_jump_branch = (~alu_opreat_A[31]) && (|alu_opreat_A);
        inst_blez:  is_jump_branch = alu_opreat_A[31] || (~(|alu_opreat_A));
        inst_bltz:  is_jump_branch = alu_opreat_A[31];
        inst_bgez:  is_jump_branch = ~alu_opreat_A[31];
        inst_j:     is_jump_branch = 1'b1;
        default:    is_jump_branch = 1'b0;
    endcase
end

always @ (*)
begin
    case(1'b1)
        inst_add&is_add_overflow,inst_sub&is_sub_overflow:
            excep_code = `OV;
        inst_lh&addu_result[0],inst_lw&(|addu_result[1:0]):
            excep_code = `ADEL;
        inst_sh&addu_result[0],inst_sw&(|addu_result[1:0]):
            excep_code = `ADES;
        default:
            excep_code = id_excep_code;
    endcase
end

always @ (*)
begin
    case(1'b1)
        inst_div,inst_dviu:
            write_hi_value = diver_result[63:32];
        inst_mult, inst_multu:
            write_hi_value = mult_result[63:32];
        inst_mthi:
            write_hi_value = alu_opreat_A;
        default:
            write_hi_value = 32'b0;
    endcase
end

always @ (*)
begin
    case(1'b1)
        inst_div,inst_dviu:
            write_lo_value = diver_result[31:0];
        inst_mult, inst_multu:
            write_lo_value = mult_result[31:0];
        inst_mtlo:
            write_lo_value = alu_opreat_A;
        default:
            write_lo_value = 32'b0;
    endcase
end

//assign write_reg_data = ({32{inst_add|inst_addu}}&addu_result)
//                      | ({32{inst_sub|inst_subu}}&subu_result)
//                      | ({32{inst_slt}}&slt_result)
//                      | ({32{inst_sltu}}&sltu_result)
//                      | ({32{inst_and}}&and_result)
//                      | ({32{inst_lui}}&alu_opreat_B)
//                      | ({32{inst_nor}}&nor_result)
//                      | ({32{inst_or}}&or_result)
//                      | ({32{inst_xor}}&xor_result)
//                      | ({32{inst_sll}}&sll_result)
//                      | ({32{inst_sra}}&sra_result)
//                      | ({32{inst_srl}}&srl_result)
//                      | ({32{inst_bjlink}}&pc_link)
//                      | ({32{inst_mflohi}}&hi_lo_value);

always @ (*)
begin
    case(1'b1)
        inst_add,inst_addu:
        begin
            write_reg_data = addu_result;
        end
        inst_sub,inst_subu:
        begin
            write_reg_data = subu_result;
        end
        inst_slt:
        begin
            write_reg_data = slt_result;
        end
        inst_sltu:
        begin
            write_reg_data = sltu_result;
        end
        inst_and:
        begin
            write_reg_data = and_result;
        end
        inst_lui:
        begin
            write_reg_data = alu_opreat_B;
        end
        inst_nor:
        begin
            write_reg_data = nor_result;
        end
        inst_or:
        begin
            write_reg_data = or_result;
        end
        inst_xor:
        begin
            write_reg_data = xor_result;
        end
        inst_sll:
        begin
            write_reg_data = sll_result;
        end
        inst_sra:
        begin
            write_reg_data = sra_result;
        end
        inst_srl:
        begin
            write_reg_data = srl_result;
        end
        inst_bjlink:
        begin
            write_reg_data = pc_link;
        end
        inst_mflohi:
        begin
            write_reg_data = hi_lo_value;
        end
        default:
        begin
            write_reg_data = 32'd0;
        end
    endcase
end

endmodule

`include "pe_undefs.vh"

