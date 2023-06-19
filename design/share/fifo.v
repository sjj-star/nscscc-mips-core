module fifo (
    clk,
    reset,
	retire_mem,
    read,
    write,
    indata,
    outdata,
    empty,
    full
);

parameter RETIRE_MEM_EN = 0;
parameter BYPASS = 0;
parameter WIDTH = 32;
parameter DEEP_SIZE = 4;
localparam DEEP = 2**DEEP_SIZE;

input wire clk;
input wire reset;
input wire [DEEP-1:0] retire_mem;
input wire read;
input wire write;
input wire [WIDTH-1:0] indata;
output wire [WIDTH-1:0] outdata;
output wire empty;
output wire full;

reg [WIDTH-1:0] mem[0:DEEP-1];
reg [DEEP_SIZE-1:0] r_pnt, w_pnt;
reg [DEEP_SIZE:0] count;

always @(posedge clk) begin
	if(reset) begin
		count <= {DEEP_SIZE+1{1'b0}};
	end else if(write & read) begin
		count <= count;
	end else if(write) begin
		count <= count+'b1;
	end else if(read) begin
		count <= count-'b1;
	end
end

always @(posedge clk) begin
    if(reset)
        r_pnt <= {DEEP_SIZE{1'b0}};
    else if(read)
        r_pnt <= r_pnt+'b1;
end

always @(posedge clk) begin
    if(reset)
        w_pnt <= {DEEP_SIZE{1'b0}};
    else if(write)
        w_pnt <= w_pnt+1'b1;
end

generate
	if(RETIRE_MEM_EN) begin: retire_ram

genvar i;
for(i=0; i<DEEP; i=i+1) begin
	always @(posedge clk) begin
		if(retire_mem[i] || (read && (r_pnt == i)))
			mem[i] <= {WIDTH{1'b0}};
	    else if(write && (w_pnt == i))
	        mem[i] <= indata;
	end
end

	end else begin: normal_ram

always @(posedge clk) begin
    if(write)
        mem[w_pnt] <= indata;
end
	end

assign full = count[DEEP_SIZE];
assign empty = ~(|count);

    if(BYPASS) begin: bypass_fifo

assign outdata = (empty & write) ? indata : mem[r_pnt];

    end
    else begin: normal_fifo

assign outdata = mem[r_pnt];

    end
endgenerate

endmodule
