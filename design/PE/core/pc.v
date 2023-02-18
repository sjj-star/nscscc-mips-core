`timescale 1ns / 1ps
`include "pe_defs.vh"

module pc(
//output
    pc_reg,
    pc_4,
    //execption
    excep_code,
    execption_is_laddress,
//input
    rst,
    clk,
    pc_reg_enable,
    jump_branch_address,
    is_jump_branch,
    //execption
    is_exception,
    is_excep_return,
    excep_return_pc);

input wire rst;
input wire clk;
input wire pc_reg_enable;
input wire [31:0] jump_branch_address;
input wire is_jump_branch;
input wire is_exception;
input wire is_excep_return;
input wire [31:0] excep_return_pc;
output reg [31:0] pc_reg;
output wire [29:0] pc_4;
output wire [4:0] excep_code;
output wire execption_is_laddress;

assign execption_is_laddress = |pc_reg[1:0];
assign excep_code = (|pc_reg[1:0]) ? `ADEL : `INVALID_EXCEP;

assign pc_4 = pc_reg[31:2] + 30'd1;
reg [31:0] pc_src;
always @ (*)
begin
    case({is_exception,is_excep_return,is_jump_branch})
        3'b100: pc_src = `PC_EBASE;
        3'b101: pc_src = `PC_EBASE;
        3'b110: pc_src = `PC_EBASE;
        3'b111: pc_src = `PC_EBASE;
        3'b010: pc_src = excep_return_pc;
        3'b011: pc_src = excep_return_pc;
        3'b001: pc_src = jump_branch_address;
        3'b000: pc_src = {pc_4,pc_reg[1:0]};
        default: pc_src = {pc_4,pc_reg[1:0]};
    endcase
//    if(is_exception)
//        pc_src = `PC_EBASE;
//    else if(is_excep_return)
//        pc_src = excep_return_pc;
//    else if(is_jump_branch)
//        pc_src = jump_branch_address;
//    else
//        pc_src = pc_4;
end

always @ (posedge clk)
begin
    if (rst)
        pc_reg <= `PC_INITIAL;
    else if (pc_reg_enable)
        pc_reg <= pc_src;
    else
        pc_reg <= pc_reg;
end

endmodule

`include "pe_undefs.vh"

