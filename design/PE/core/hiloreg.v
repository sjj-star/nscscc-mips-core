`timescale 1ns / 1ps
`include "pe_defs.vh"

module hiloreg(
//output
    hi,
    lo,
//input
    clk,
    rst,
    we_hi,
    we_lo,
    wd_hi,
    wd_lo);

input wire clk;
input wire rst;
input wire we_hi;
input wire we_lo;
input wire[31:0] wd_hi;
input wire[31:0] wd_lo;
output wire [31:0] hi;
output wire [31:0] lo;

reg[31:0] hilo[0:1];

always @(posedge clk) begin
    if(rst) begin
        hilo[1] <= 32'b0;
    end
    else if(we_hi) begin
        hilo[1] <= wd_hi;
    end
end

always @(posedge clk) begin
    if(rst) begin
        hilo[0] <= 32'b0;
    end
    else if(we_lo) begin
        hilo[0] <= wd_lo;
    end
end

assign hi = we_hi ? wd_hi : hilo[1];
assign lo = we_lo ? wd_lo : hilo[0];

endmodule

`include "pe_undefs.vh"

