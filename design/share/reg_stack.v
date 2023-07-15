module reg_stack(
//inputs
	clk,
	reset,
	push,
	pop,
	data_in,
//outputs
	data_out,
	empty
);

parameter WIDTH = 32;
parameter DEEP = 8;

input wire clk;
input wire reset;
input wire push;
input wire pop;
input wire [WIDTH-1:0] data_in;
output wire [WIDTH-1:0] data_out;
output wire empty;

reg [WIDTH-1:0] mem[0:DEEP-1];
reg vld[0:DEEP-1];

genvar i;
generate
always @(posedge clk) begin
	if(reset)
		vld[0] <= 1'b0;
	else if(push) begin
		vld[0] <= 1'b1;
		mem[0] <= data_in;
	end else if(pop) begin
		vld[0] <= vld[1];
		mem[0] <= mem[1];
	end
end

always @(posedge clk) begin
	if(reset)
		vld[DEEP-1] <= 1'b0;
	else if(push && (!pop)) begin
		vld[DEEP-1] <= vld[DEEP-2];
		mem[DEEP-1] <= mem[DEEP-2];
	end else if((!push) && pop) begin
		vld[DEEP-1] <= 1'b0;
		mem[DEEP-1] <= {WIDTH{1'b0}};
	end
end

for(i=1; i<DEEP-1; i=i+1) begin: shift_reg
	always @(posedge clk) begin
		if(reset)
			vld[i] <= 1'b0;
		else if(push && (!pop)) begin
			vld[i] <= vld[i-1];
			mem[i] <= mem[i-1];
		end else if((!push) && pop) begin
			vld[i] <= vld[i+1];
			mem[i] <= mem[i+1];
		end
	end
end
endgenerate

assign data_out = mem[0];
assign empty = ~vld[0];

endmodule

