`timescale 1ns / 1ps

module mult_controller(
//input
    clk,
    rst,
    A,
    B,
    start,
    sign,
    is_busbusy,
//output
    P,
    opreat_over);

input wire clk;
input wire rst;
input wire start;
input wire sign;
input wire is_busbusy;
output reg opreat_over;
input wire [31:0] A;
input wire [31:0] B;
output wire [63:0] P;

multer multer_1(.clk(clk), .reset(rst), .ce(start), .sign(sign), .A(A), .B(B), .P(P));

reg [1:0] count;
always @ (posedge clk)
begin
    if(rst)
        count <= 2'd0;
    else if((count == 2'd2)&(~is_busbusy))
        count <= count;
    else if(start)
        if(count == 2'd2)
            count <= 2'd0;
        else
            count <= count + 2'd1;
    else
        count <= count;
end

always @ (*)
begin
    case(count)
        2'd0:
            opreat_over = ~start;
        2'd2:
            opreat_over = 1'b1;
        default:
            opreat_over = 1'b0;
    endcase
end

endmodule
