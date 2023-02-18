`timescale 1ns / 1ps
`include "pe_defs.vh"

module cop0(
//output
    data_o,
    is_ie,
    is_exl,
    int_mask,
    soft_int,
    errorpc,
//input
    clk,
    rst,
    we,
    cop_address,
    data_i,
    hardware_int,
    is_exception,
    is_bd,
    we_badvaddr,
    badvaddr,
    exc_code,
    exc_pc,
    is_excep_return
    );

`define CP0_BadVAddr {5'd8,3'd0}
`define CP0_Count {5'd9,3'd0}
`define CP0_Compare {5'd11,3'd0}
`define CP0_Status {5'd12,3'd0}
`define CP0_Cause {5'd13,3'd0}
`define CP0_EPC {5'd14,3'd0}
`define IM 15:8
`define EXL 1
`define IE 0
`define BD 31
`define TI 30
`define IP_H 15:10
`define IP_S 9:8
`define EXCCODE 6:2

input wire clk;
input wire rst;
input wire we;
input wire [7:0] cop_address;
input wire [31:0] data_i;
input wire [5:0] hardware_int;
input wire is_exception;
input wire is_bd;
input wire we_badvaddr;
input wire [31:0] badvaddr;
input wire [4:0] exc_code;
input wire [31:0] exc_pc;
input wire is_excep_return;
output reg [31:0] data_o;
output wire is_ie;
output wire is_exl;
output wire [7:0] int_mask;
output reg [1:0] soft_int;
output wire [31:0] errorpc;

reg [31:0] cp0_regs_BadVAddr;
reg [31:0] cp0_regs_Count;
reg [31:0] cp0_regs_Compare;
reg [31:0] cp0_regs_Status;
reg [31:0] cp0_regs_Cause;
reg [31:0] cp0_regs_EPC;
reg timercount;

assign int_mask = cp0_regs_Status[`IM];
assign is_exl = cp0_regs_Status[`EXL];
assign is_ie = cp0_regs_Status[`IE];
assign errorpc = cp0_regs_EPC;

always @ (*)
begin
    data_o = 32'b0;
    soft_int = 2'b0;
    case(cop_address)
        `CP0_BadVAddr:
        begin
            data_o = we ? data_i : cp0_regs_BadVAddr;
        end
        `CP0_Count:
        begin
            data_o = we ? data_i : cp0_regs_Count;
        end
        `CP0_Compare:
        begin
            data_o = we ? data_i : cp0_regs_Compare;
        end
        `CP0_Status:
        begin
            data_o = we ? {cp0_regs_Status[31:16],data_i[`IM],cp0_regs_Status[7:2],data_i[`EXL],data_i[`IE]} : cp0_regs_Status;
        end
        `CP0_Cause:
        begin
            data_o = we ? {cp0_regs_Cause[31:10],data_i[`IP_S],cp0_regs_Cause[7:0]} : cp0_regs_Cause;
            soft_int = we ? data_i[`IP_S] : cp0_regs_Cause[`IP_S];
        end
        `CP0_EPC:
        begin
            data_o = we ? data_i : cp0_regs_EPC;
        end
    endcase
end

always @ (posedge clk)
begin
    if (rst)
    begin
        cp0_regs_Count <= 32'b0;
        cp0_regs_Compare <= 32'b0;
        cp0_regs_Status <= 32'h0040_0000;
        cp0_regs_Cause <= 32'b0;
        cp0_regs_EPC <= 32'b0;
        timercount <= 1'b0;
    end
    else
    begin
        timercount <= ~timercount;
        if(timercount)
            cp0_regs_Count <= cp0_regs_Count + 32'd1;
        else
            cp0_regs_Count <= cp0_regs_Count;
        if(&(cp0_regs_Count~^cp0_regs_Compare))
            cp0_regs_Cause[`TI] <= 1'b1;
        if(we)
        begin
            case(cop_address)
            `CP0_Count:
            begin
                cp0_regs_Count <= data_i;
            end
            `CP0_Compare:
            begin
                cp0_regs_Compare <= data_i;
                cp0_regs_Cause[`TI] <= 1'b0;
            end
            `CP0_Status:
            begin
                cp0_regs_Status[`IM] <= data_i[`IM];
                cp0_regs_Status[`EXL] <= data_i[`EXL];
                cp0_regs_Status[`IE] <= data_i[`IE];
            end
            `CP0_Cause:
            begin
                cp0_regs_Cause[`IP_S] <= data_i[`IP_S];
            end
            `CP0_EPC:
            begin
                cp0_regs_EPC <= data_i;
            end
            endcase
        end
        cp0_regs_Cause[`IP_H] <= hardware_int;
        if(is_exception)
        begin
            if(we_badvaddr)
                cp0_regs_BadVAddr <= badvaddr;
            if(~cp0_regs_Status[`EXL])
            begin
                cp0_regs_EPC <= exc_pc;
                cp0_regs_Cause[`BD] <= is_bd;
            end
            cp0_regs_Status[`EXL] <= 1'b1;
            cp0_regs_Cause[`EXCCODE] <= exc_code;
        end
        if(is_excep_return)
            cp0_regs_Status[`EXL] <= 1'b0;
    end
end
endmodule

`include "pe_undefs.vh"

