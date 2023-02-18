`timescale 1ns / 1ps
`include "pe_defs.vh"

module writeback(
//output
    hi_value,
    lo_value,
    rs_value,
    rt_value,
    //debug info
    reg_we,
    reg_waddr,
    reg_wdata,
    inst_branchjump,
    wb_pc,
//input
    clk,
    rst,
    rs,
    rt,
    inst_opreat,
    write_reg,
    write_hi,
    write_lo,
    write_hi_value,
    write_lo_value,
    write_reg_address,
    write_reg_value,
    //debug info
    am_pc);

input wire clk;
input wire rst;
input wire [4:0] rs;
input wire [4:0] rt;
input wire inst_opreat;
input wire write_reg;
input wire write_hi;
input wire write_lo;
input wire [31:0] write_hi_value;
input wire [31:0] write_lo_value;
input wire [4:0] write_reg_address;
input wire [31:0] write_reg_value;
input wire [31:0] am_pc;
output wire [31:0] hi_value;
output wire [31:0] lo_value;
output wire [31:0] rs_value;
output wire [31:0] rt_value;
output wire [3:0] reg_we;
output wire [4:0] reg_waddr;
output wire [31:0] reg_wdata;
output wire inst_branchjump;
output wire [31:0] wb_pc;

assign wb_pc = am_pc;
assign inst_branchjump = inst_opreat;

assign reg_we = {4{write_reg}};
assign reg_waddr = write_reg_address;
assign reg_wdata = write_reg_value;

registerfile rf(.clk(clk),
                .rst(rst),
                .we(write_reg),
                .waddr(write_reg_address),
                .wdata(write_reg_value),
                .raddr1(rs),
                .raddr2(rt),
                .rdata1(rs_value),
                .rdata2(rt_value));

hiloreg hilo(.clk(clk),
             .rst(rst),
             .we_hi(write_hi),
             .we_lo(write_lo),
             .wd_hi(write_hi_value),
             .wd_lo(write_lo_value),
             .hi(hi_value),
             .lo(lo_value));

endmodule

`include "pe_undefs.vh"

