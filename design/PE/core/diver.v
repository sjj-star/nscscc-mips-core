`timescale 1ns / 1ps

module diver(
//input
    clk,
    rst,
    A,
    B,
    start,
    is_busbusy,
//output
    Q,
    R,
    opreat_over);

input wire clk;
input wire rst;
input wire start;
input wire is_busbusy;
input wire [31:0] A;
input wire [31:0] B;
output wire [31:0] Q;
output wire [31:0] R;
output wire opreat_over;

reg [4:0] count;
wire load;
always @ (posedge clk)
begin
    if(rst)
        count <= 5'd0;
    else if((count == 5'd17)&is_busbusy)
        count <= 5'd17;
    else if(start)
        if(count == 5'd17)
            count <= 5'd0;
        else
            count <= count + 5'd1;
    else
        count <= count;
end

assign load = (count == 5'd0) ? start : 1'b0;
assign opreat_over = (count == 5'd17) ? 1'b1 : (~start);

reg [63:0] temp_result1;
wire [63:0] temp1;
wire [63:0] temp_result2;
wire [63:0] temp2;

assign temp1 = {(temp_result1[63:31] - {1'b0,B}), temp_result1[30:0]};
assign temp_result2 = temp1[63] ? {temp_result1[62:0],1'b0} : {temp1[62:0],1'b1};
assign temp2 = {(temp_result2[63:31] - {1'b0,B}), temp_result2[30:0]};

always @ (posedge clk)
begin
    if(rst|load)
        temp_result1 <= {32'b0,A};
    else if((~load)&opreat_over)
        temp_result1 <= temp_result1;
    else
    begin
        if(temp2[63])
            temp_result1 <= {temp_result2[62:0],1'b0};
        else
            temp_result1 <= {temp2[62:0],1'b1};
    end
end

assign Q = temp_result1[31:0];
assign R = temp_result1[63:32];

endmodule
