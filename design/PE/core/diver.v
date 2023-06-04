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
output reg opreat_over;

reg [4:0] count;
reg load;
always @ (posedge clk)
begin
    if(rst)
        count <= 5'd0;
    else if((count == 5'd17)&(~is_busbusy))
        count <= 5'd17;
    else if(start)
        if(count == 5'd17)
            count <= 5'd0;
        else
            count <= count + 5'd1;
    else
        count <= count;
end

always @ (*)
begin
    case(count)
        5'd0:
        begin
            load = start;
            opreat_over = ~start;
        end
        5'd17:
        begin
            load = is_busbusy;
            opreat_over = 1'b1;
        end
        default:
        begin
            load = 1'b0;
            opreat_over = 1'b0;
        end
    endcase
end

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
