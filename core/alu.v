`timescale 1ns / 1ps
`include "defs.vh"

module alu(
    clk,
    rst,
    is_busbusy,
    alu_opreat_A,
    alu_opreat_B,
    opreat_over,
    is_add_overflow,
    is_sub_overflow,
    addu_result,
    subu_result,
    slt_result,
    sltu_result,
    and_result,
    or_result,
    nor_result,
    xor_result,
    sll_result,
    srl_result,
    sra_result,
    mult_sign,
    mult_start,
    mult_result,
    diver_start,
    div_sign,
    diver_result);

input wire clk;
input wire rst;
input wire mult_sign;
input wire is_busbusy;
input wire [31:0] alu_opreat_A;
input wire [31:0] alu_opreat_B;
output wire opreat_over;
output wire is_add_overflow;
output wire is_sub_overflow;
output wire [31:0] addu_result;
output wire [31:0] subu_result;
output wire [31:0] slt_result;
output wire [31:0] sltu_result;
output wire [31:0] and_result;
output wire [31:0] or_result;
output wire [31:0] nor_result;
output wire [31:0] xor_result;
output wire [31:0] sll_result;
output wire [31:0] srl_result;
output wire [31:0] sra_result;
input wire mult_start;
wire mult_opreat_over;
output wire [63:0] mult_result;
input wire diver_start;
input wire div_sign;
wire diver_opreat_over;
output wire [63:0] diver_result;
wire [31:0] diver_A;
wire [31:0] diver_B;
wire [63:0] diver_result_temp;

assign opreat_over = mult_opreat_over&diver_opreat_over;

diver div_s_u(.clk(clk),
              .rst(rst),
              .A(diver_A),
              .B(diver_B),
              .start(diver_start),
              .is_busover(is_busbusy),
              .Q(diver_result_temp[31:0]),
              .R(diver_result_temp[63:32]),
              .opreat_over(diver_opreat_over));

assign diver_A = (alu_opreat_A[31] & div_sign) ? ((~alu_opreat_A)+32'b1) : alu_opreat_A;
assign diver_B = (alu_opreat_B[31] & div_sign) ? ((~alu_opreat_B)+32'b1) : alu_opreat_B;
assign diver_result[31:0] = (div_sign & (alu_opreat_A[31]^alu_opreat_B[31])) ? ((~diver_result_temp[31:0])+32'b1) : diver_result_temp[31:0];
assign diver_result[63:32] = (div_sign & alu_opreat_A[31]) ? ((~diver_result_temp[63:32])+32'b1) : diver_result_temp[63:32];

mult_controller alu_mult(.clk(clk),
                         .rst(rst),
                         .start(mult_start),
                         .sign(mult_sign),
                         .is_busbusy(is_busbusy),
                         .A(alu_opreat_A),
                         .B(alu_opreat_B),
                         .P(mult_result),
                         .opreat_over(mult_opreat_over));

assign addu_result = alu_opreat_A + alu_opreat_B;
assign subu_result = alu_opreat_A - alu_opreat_B;
assign is_add_overflow = (alu_opreat_A[31]~^alu_opreat_B[31])&(alu_opreat_A[31]^addu_result[31]);
assign is_sub_overflow = (alu_opreat_A[31]^alu_opreat_B[31])&(alu_opreat_A[31]^subu_result[31]);
assign slt_result = (alu_opreat_A[31]^alu_opreat_B[31]) ? (alu_opreat_A[31] ? 32'b1 : 32'b0) : (subu_result[31] ? 32'b1 : 32'b0);
assign sltu_result = (alu_opreat_A < alu_opreat_B) ? 32'b1 : 32'b0;
assign and_result = alu_opreat_A & alu_opreat_B;
assign nor_result = ~or_result;
assign or_result  = alu_opreat_A | alu_opreat_B;
assign xor_result = alu_opreat_A ^ alu_opreat_B;
assign sll_result = alu_opreat_A << alu_opreat_B[4:0];
assign srl_result = alu_opreat_A >> alu_opreat_B[4:0];
assign sra_result = $signed(alu_opreat_A) >>> alu_opreat_B[4:0];//srl_result | (alu_opreat_A[31] ? ~({32{1'b1}}>>alu_opreat_B[4:0]) : 32'h0);

endmodule