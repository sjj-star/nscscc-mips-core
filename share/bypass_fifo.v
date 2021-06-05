module bypass_fifo (
    clk,
    reset,
    read,
    write,
    indata,
    outdata,
    empty,
    full
);

parameter WIDTH = 32;
parameter DEEP_SIZE = 4;
localparam DEEP = 2**DEEP_SIZE;

input wire clk;
input wire reset;
input wire read;
input wire write;
input wire [WIDTH-1:0] indata;
output wire [WIDTH-1:0] outdata;
output wire empty;
output wire full;

generate
    if(DEEP_SIZE > 0) begin: fifo

reg [WIDTH-1:0] mem[0:DEEP-1];
reg [DEEP_SIZE-1:0] count, r_pnt, w_pnt;

always @(posedge clk) begin
    if(reset)
        count <= {DEEP_SIZE{1'b0}};
    else if(write & read)
        count <= count;
    else if(write)
        count <= count+'b1;
    else if(read)
        count <= count-'b1;
end

always @(posedge clk) begin
    if(reset)
        w_pnt <= {DEEP_SIZE{1'b0}};
    else if(write)
        w_pnt <= w_pnt+1'b1;
end

always @(posedge clk) begin
    if(write)
        mem[w_pnt] <= indata;
end

always @(posedge clk) begin
    if(reset)
        r_pnt <= {DEEP_SIZE{1'b0}};
    else if(read)
        r_pnt <= r_pnt+'b1;
end

assign outdata = (empty & read) ? indata : mem[r_pnt];
assign empty = count == {DEEP_SIZE{1'b0}};
assign full = count == {DEEP_SIZE{1'b1}};

    end
    else if(DEEP_SIZE == 0) begin: register

reg [WIDTH-1:0] mem;
reg [DEEP_SIZE-1:0] count;

always @(posedge clk) begin
    if(reset)
        count <= 1'b0;
    else if(write & read)
        count <= count;
    else if(write)
        count <= 1'b1;
    else if(read)
        count <= 1'b0;
end

always @(posedge clk) begin
    if(write)
        mem <= indata;
end

assign outdata = (empty & read) ? indata : mem;
assign empty = ~count;
assign full = count;

    end
endgenerate

endmodule
