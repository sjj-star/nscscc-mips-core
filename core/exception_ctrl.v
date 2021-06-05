`timescale 1ns / 1ps
`include "defs.vh"

module exception_ctrl(
//output
    is_exception,
    is_bd,
    we_badvaddr,
    badvaddr,
    excep_code,
    excep_pc,
    id_clr,
    ex_clr,
    am_clr,
    wb_clr,
//input
    excep_ex_pc,
    excep_am_pc,
    excep_wb_pc,
    is_instload,
    wb_is_bj,
    data_address,
    is_ie,
    is_exl,
    int_mask,
    hardware_int,
    soft_int,
    am_excep_code);

input wire [31:0] excep_ex_pc;
input wire [31:0] excep_am_pc;
input wire [31:0] excep_wb_pc;
input wire is_instload;
input wire wb_is_bj;
input wire [31:0] data_address;
input wire is_ie;
input wire is_exl;
input wire [7:0] int_mask;
input wire [5:0] hardware_int;
input wire [1:0] soft_int;
input wire [4:0] am_excep_code;
output reg is_exception;
output wire is_bd;
output reg we_badvaddr;
output reg [31:0] badvaddr;
output reg [4:0] excep_code;
output reg [31:0] excep_pc;
output reg id_clr;
output reg ex_clr;
output reg am_clr;
output reg wb_clr;

assign is_bd = wb_is_bj;

always @ (*)
begin
    is_exception = 1'b0;
    we_badvaddr = 1'b0;
    badvaddr = 32'b0;
    excep_code = 5'b0;
    id_clr = 1'b0;
    ex_clr = 1'b0;
    am_clr = 1'b0;
    wb_clr = 1'b0;
    if((|({hardware_int,soft_int}&int_mask)) & is_ie & (~is_exl))
    begin
        excep_code = `INT;
        is_exception = 1'b1;
        id_clr = 1'b1;
        ex_clr = 1'b1;
        am_clr = 1'b1;
        wb_clr = 1'b1;
    end
    else if(am_excep_code==`ADEL)
    begin
        id_clr = 1'b1;
        ex_clr = 1'b1;
        am_clr = 1'b1;
        wb_clr = 1'b1;
        is_exception = 1'b1;
        we_badvaddr = 1'b1;
        excep_code = am_excep_code;
        if(is_instload)
            badvaddr = data_address;
        else
            badvaddr = excep_am_pc;
    end
    else if((am_excep_code==`RI)
          ||(am_excep_code==`BP)
          ||(am_excep_code==`SYS)
          ||(am_excep_code==`OV))
    begin
        id_clr = 1'b1;
        ex_clr = 1'b1;
        am_clr = 1'b1;
        wb_clr = 1'b1;
        is_exception = 1'b1;
        excep_code = am_excep_code;
    end
    else if(am_excep_code==`ADES)
    begin
        id_clr = 1'b1;
        ex_clr = 1'b1;
        am_clr = 1'b1;
        wb_clr = 1'b1;
        is_exception = 1'b1;
        excep_code = am_excep_code;
        we_badvaddr = 1'b1;
        badvaddr = data_address;
    end
    else
    begin
        is_exception = 1'b0;
        we_badvaddr = 1'b0;
        badvaddr = 32'b0;
        excep_code = 5'b0;
        id_clr = 1'b0;
        ex_clr = 1'b0;
        am_clr = 1'b0;
        wb_clr = 1'b0;
    end
end

always @ (*)
begin
    if(wb_is_bj)
        excep_pc = excep_wb_pc;
    else if(|({hardware_int,soft_int}&int_mask))
        excep_pc = excep_ex_pc;
    else
        excep_pc = excep_am_pc;
end

endmodule
