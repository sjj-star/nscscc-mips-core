`timescale 1ns / 1ps
`include "pe_defs.vh"

module accessmem(
//output
    inst_opreat_,
    write_reg_address_,
    write_reg_data,
    write_hi_value_,
    write_lo_value_,
    cop_address_,
    write_cop_data,
    cop_we,
    mem_req,
    mem_wr,
    mem_size,
    mem_wstrb,
    mem_address_,
    write_mem_data,
    //check confict
    check_is_write_reg,
    check_write_reg_address,
    check_write_reg_data,
    check_is_write_hi,
    check_is_write_lo,
    check_write_hi_value,
    check_write_lo_value,
    //execption
    excep_code,
    is_instload,
    //debug info
    am_pc,
//input
    inst_opreat,
    write_reg_address,
    write_reg_data_before,
    write_hi_value,
    write_lo_value,
    is_write_reg,
    is_write_hi,
    is_write_lo,
    reg_t_value,
    cop_address,
    read_cop_data,
    mem_address,
    read_mem_data,
    //exception
    ex_excep_code,
    //debug info
    ex_pc);

input wire [9:0] inst_opreat;
input wire [4:0] write_reg_address;
input wire [31:0] write_reg_data_before;
input wire [31:0] write_hi_value;
input wire [31:0] write_lo_value;
input wire is_write_reg;
input wire is_write_hi;
input wire is_write_lo;
input wire [31:0] reg_t_value;
input wire [7:0] cop_address;
input wire [31:0] read_cop_data;
input wire [31:0] mem_address;
input wire [31:0] read_mem_data;
input wire [4:0] ex_excep_code;
input wire [31:0] ex_pc;
output wire inst_opreat_;
output wire [4:0] write_reg_address_;
output reg [31:0] write_reg_data;
output wire [31:0] write_hi_value_;
output wire [31:0] write_lo_value_;
output wire [7:0] cop_address_;
output wire [31:0] write_cop_data;
output wire cop_we;
output wire [31:0] mem_address_;
output reg [31:0] write_mem_data;
output wire mem_req;
output wire mem_wr;
output wire [1:0] mem_size;
output reg [3:0] mem_wstrb;
output wire check_is_write_reg;
output wire [4:0] check_write_reg_address;
output wire [31:0] check_write_reg_data;
output wire check_is_write_hi;
output wire check_is_write_lo;
output wire [31:0] check_write_hi_value;
output wire [31:0] check_write_lo_value;
output wire [31:0] am_pc;
output wire [4:0] excep_code;
output wire is_instload;

wire inst_writereg_exdata;
wire mem_en;
wire data_signed;
wire inst_mfc0;
assign {inst_writereg_exdata,
        is_instload,
        mem_en,
        mem_wr,
        mem_size,
        data_signed,
        inst_mfc0,
        cop_we,
        inst_opreat_} = inst_opreat;

assign am_pc = ex_pc;
assign write_reg_address_ = write_reg_address;
assign check_write_reg_address = write_reg_address_;
assign check_write_reg_data = write_reg_data;
assign write_hi_value_ = write_hi_value;
assign write_lo_value_ = write_lo_value;
assign check_is_write_reg = is_write_reg;
assign check_is_write_hi = is_write_hi;
assign check_is_write_lo = is_write_lo;
assign check_write_hi_value = write_hi_value_;
assign check_write_lo_value = write_lo_value_;
assign cop_address_ = cop_address;
assign write_cop_data = reg_t_value;
assign mem_req = mem_en & (|(excep_code^`ADEL)) & (|(excep_code^`ADES));
assign mem_address_ = mem_address;
assign excep_code = ex_excep_code;

always @ (*)
begin
    case({mem_address[1:0],mem_size})
        4'b00_00:
        begin
            write_mem_data = {24'b0,reg_t_value[7:0]};
            mem_wstrb = 4'b0001;
        end
        4'b01_00:
        begin
            write_mem_data = {16'b0,reg_t_value[7:0],8'b0};
            mem_wstrb = 4'b0010;
        end
        4'b10_00:
        begin
            write_mem_data = {8'b0,reg_t_value[7:0],16'b0};
            mem_wstrb = 4'b0100;
        end
        4'b11_00:
        begin
            write_mem_data = {reg_t_value[7:0],24'b0};
            mem_wstrb = 4'b1000;
        end
        4'b00_01:
        begin
            write_mem_data = {16'b0,reg_t_value[15:0]};
            mem_wstrb = 4'b0011;    
        end
        4'b10_01:
        begin
            write_mem_data = {reg_t_value[15:0],16'b0};
            mem_wstrb = 4'b1100;
        end
        default:
        begin
            write_mem_data = reg_t_value;
            mem_wstrb = 4'b1111;
        end
    endcase
end

reg [31:0] load_mem_data;
always @ (*)
begin
    case({mem_address[1:0],mem_size})
        4'b00_00:
            load_mem_data = {{24{data_signed&read_mem_data[7]}},read_mem_data[7:0]};
        4'b01_00:
            load_mem_data = {{24{data_signed&read_mem_data[15]}},read_mem_data[15:8]};
        4'b10_00:
            load_mem_data = {{24{data_signed&read_mem_data[23]}},read_mem_data[23:16]};
        4'b11_00:
            load_mem_data = {{24{data_signed&read_mem_data[31]}},read_mem_data[31:24]};
        4'b00_01:
            load_mem_data = {{16{data_signed&read_mem_data[15]}},read_mem_data[15:0]};
        4'b10_01:
            load_mem_data = {{16{data_signed&read_mem_data[31]}},read_mem_data[31:16]};
        default:
            load_mem_data = read_mem_data;
    endcase
end

always @ (*)
begin
    case(1'b1)
        inst_writereg_exdata:
            write_reg_data = write_reg_data_before;
        mem_req&(~mem_wr):
            write_reg_data = load_mem_data;
        inst_mfc0:
            write_reg_data = read_cop_data;
        default:
        begin
            write_reg_data = 32'b0;
        end
    endcase
end
endmodule

`include "pe_undefs.vh"

