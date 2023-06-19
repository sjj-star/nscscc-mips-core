`timescale 1ns / 1ps
`include "pe_defs.vh"

module inst_fetch(
//output
	//pc
    pc,
    pc_4,
    //execption
    excep_code,
//input
    rst,
    clk,
    jump_branch_address,
    is_jump_branch,
    //execption
    is_exception,
    is_excep_return,
    excep_return_pc,
	//fetch instruction interface
	inst_addr_valid,
	inst_addr_ready,
	inst_addr,
	inst_line_valid,
	inst_line_ready,
	inst_line,
	//pipe interface
	inst_valid,
	inst_ready,
	inst
);

input wire rst;
input wire clk;
input wire [31:0] jump_branch_address;
input wire is_jump_branch;
input wire is_exception;
input wire is_excep_return;
input wire [31:0] excep_return_pc;
output wire [31:0] pc;
output wire [29:0] pc_4;
output wire [4:0] excep_code;

output wire inst_valid;
input wire inst_ready;
output wire [31:0] inst;

output wire inst_addr_valid;
input wire inst_addr_ready;
output reg [31:0] inst_addr;
input wire inst_line_valid;
output wire inst_line_ready;
input wire [31:0] inst_line;

wire is_exception_q;
wire is_excep_return_q;
wire [31:0] excep_return_pc_q;
wire is_jump_branch_q;
wire [31:0] jump_branch_address_q;
wire flush_req;
wire bq_empty;
reg [31:0] prefetch_addr;
wire pc_valid;

fifo #(
	.RETIRE_MEM_EN(1),
    .WIDTH(1+1+32+1+32),
    .DEEP_SIZE(1)
) branch_req_queue(
    .clk(clk),
    .reset(rst),
    .retire_mem({2**1{rst}}),
    .read((~bq_empty)&(inst_addr_valid&inst_addr_ready)),
    .write(is_exception|is_excep_return|is_jump_branch),
    .indata({is_exception,is_excep_return,excep_return_pc,is_jump_branch,jump_branch_address}),
    .outdata({is_exception_q,is_excep_return_q,excep_return_pc_q,is_jump_branch_q,jump_branch_address_q}),
    .empty(bq_empty),
    .full()
);

assign flush_req = is_exception_q|is_excep_return_q|is_jump_branch_q;

always @ (*)
begin
    case({is_exception_q,is_excep_return_q,is_jump_branch_q})
        3'b100: prefetch_addr = `PC_EBASE;
        3'b101: prefetch_addr = `PC_EBASE;
        3'b110: prefetch_addr = `PC_EBASE;
        3'b111: prefetch_addr = `PC_EBASE;
        3'b010: prefetch_addr = excep_return_pc_q;
        3'b011: prefetch_addr = excep_return_pc_q;
        3'b001: prefetch_addr = jump_branch_address_q;
        3'b000: prefetch_addr = {(inst_addr[31:2] + 30'd1),inst_addr[1:0]};
        default: prefetch_addr = {(inst_addr[31:2] + 30'd1),inst_addr[1:0]};
    endcase
end

always @(posedge clk)
begin
	if(rst) begin
        inst_addr <= `PC_INITIAL;
	end else begin
		if(inst_addr_valid&inst_addr_ready) begin
			inst_addr <= prefetch_addr;
		end
	end
end

fifo #(
	.RETIRE_MEM_EN(1),
	.BYPASS(1),
    .WIDTH(1+32),
    .DEEP_SIZE(4)
) inst_addr_queue(
    .clk(clk),
    .reset(rst),
    .retire_mem({2**4{rst|flush_req}}),
    .read((~inst_empty)&(inst_ready|(~pc_valid))),
    .write(inst_addr_valid&inst_addr_ready),
    .indata({1'b1,inst_addr}),
    .outdata({pc_valid,pc}),
    .empty(),
    .full(prefetch_full)
);

assign inst_addr_valid = ~prefetch_full;

fifo #(
	.BYPASS(1),
    .WIDTH(32),
    .DEEP_SIZE(4)
) inst_line_queue(
    .clk(clk),
    .reset(rst),
    .read((~inst_empty)&(inst_ready|(~pc_valid))),
    .write(inst_line_valid&inst_line_ready),
    .indata(inst_line),
    .outdata(inst),
    .empty(inst_empty),
    .full()
);

assign inst_line_ready = 1'b1;
assign inst_valid = (~inst_empty) & pc_valid & (~flush_req);

assign pc_4 = pc[31:2] + 30'd1;
assign excep_code = (|pc[1:0]) ? `ADEL : `INVALID_EXCEP;

endmodule

`include "pe_undefs.vh"

