`timescale 1ns / 1ps
`include "defs.vh"

module conflict_ctrl_unit(
//output
    reg_s_id_read_address,
    reg_t_id_read_address,
    reg_s_value_latest,
    reg_t_value_latest,
    hilo_value_latest,
    pc_reg_en,
    if_id_reg_en,
    id_ex_reg_clr,
//input
    id_is_use_reg_s,
    id_is_use_reg_t,
    id_is_use_hi,
    id_is_use_lo,
    id_reg_s,
    id_reg_t,
    ex_is_write_reg,
    ex_is_clean_reg,
    ex_write_reg_address,
    ex_write_reg_data,
    ex_is_write_hi,
    ex_is_write_lo,
    ex_write_hi_value,
    ex_write_lo_value,
    am_is_write_reg,
    am_write_reg_address,
    am_write_reg_data,
    am_is_write_hi,
    am_is_write_lo,
    am_write_hi_value,
    am_write_lo_value,
    wb_hi_value,
    wb_lo_value,
    wb_rs_value,
    wb_rt_value);

input wire id_is_use_reg_s;
input wire id_is_use_reg_t;
input wire id_is_use_hi;
input wire id_is_use_lo;
input wire [4:0]  id_reg_s;
input wire [4:0]  id_reg_t;
input wire        ex_is_write_reg;
input wire        ex_is_clean_reg;
input wire [4:0]  ex_write_reg_address;
input wire [31:0] ex_write_reg_data;
input wire        ex_is_write_hi;
input wire        ex_is_write_lo;
input wire [31:0] ex_write_hi_value;
input wire [31:0] ex_write_lo_value;
input wire        am_is_write_reg;
input wire [4:0]  am_write_reg_address;
input wire [31:0] am_write_reg_data;
input wire        am_is_write_hi;
input wire        am_is_write_lo;
input wire [31:0] am_write_hi_value;
input wire [31:0] am_write_lo_value;
input wire [31:0] wb_hi_value;
input wire [31:0] wb_lo_value;
input wire [31:0] wb_rs_value;
input wire [31:0] wb_rt_value;
output wire [4:0] reg_s_id_read_address;
output wire [4:0] reg_t_id_read_address;
output wire [31:0] reg_s_value_latest;
output wire [31:0] reg_t_value_latest;
output reg [31:0] hilo_value_latest;
output wire pc_reg_en;
output wire if_id_reg_en;
output wire id_ex_reg_clr;

assign reg_s_id_read_address = id_reg_s;
assign reg_t_id_read_address = id_reg_t;

wire id_ex_regs_clr;
wire id_ex_regt_clr;
wire pc_regs_en;
wire pc_regt_en;
wire if_id_regs_en;
wire if_id_regt_en;
wire is_id_rs_zero;
wire is_id_rt_zero;
wire is_ex_rs_addr_same;
wire is_ex_rt_addr_same;
wire is_am_rs_addr_same;
wire is_am_rt_addr_same;

assign id_ex_reg_clr = id_ex_regs_clr | id_ex_regt_clr;
assign pc_reg_en = pc_regs_en & pc_regt_en;
assign if_id_reg_en = if_id_regs_en & if_id_regt_en;
assign is_id_rs_zero = ~(|id_reg_s);
assign is_id_rt_zero = ~(|id_reg_t);
assign is_ex_rs_addr_same = &(id_reg_s~^ex_write_reg_address);
assign is_ex_rt_addr_same = &(id_reg_t~^ex_write_reg_address);
assign is_am_rs_addr_same = &(id_reg_s~^am_write_reg_address);
assign is_am_rt_addr_same = &(id_reg_t~^am_write_reg_address);

/*
 * 这里的assign语句与其下方的case语句功能相同，但是测试发现这里的assign语句性能更好。
 * case语句作为理解型代码不予删除。
 */
assign pc_regs_en = ~(id_is_use_reg_s & (~is_id_rs_zero) & ex_is_write_reg & is_ex_rs_addr_same & (~ex_is_clean_reg));
assign if_id_regs_en = ~(id_is_use_reg_s & (~is_id_rs_zero) & ex_is_write_reg & is_ex_rs_addr_same & (~ex_is_clean_reg));
assign id_ex_regs_clr = id_is_use_reg_s & (~is_id_rs_zero) & ex_is_write_reg & is_ex_rs_addr_same & (~ex_is_clean_reg);
assign reg_s_value_latest = ({32{ex_is_write_reg & is_ex_rs_addr_same}} & ex_write_reg_data)
                          | ({32{~(ex_is_write_reg & is_ex_rs_addr_same) & am_is_write_reg & is_am_rs_addr_same}} & am_write_reg_data)
                          | ({32{~(ex_is_write_reg & is_ex_rs_addr_same) & ~(am_is_write_reg & is_am_rs_addr_same)}} & wb_rs_value);
////冲突检测编码：源为0寄存器，要写寄存器，地址相同，数据干净，（后两位是访存阶段的信号）
//always @ (*)
//begin
//    casez({id_is_use_reg_s,
//           is_id_rs_zero,
//           ex_is_write_reg,is_ex_rs_addr_same,ex_is_clean_reg,
//           am_is_write_reg,is_am_rs_addr_same})
//        7'b1_0_111_??://第三级数据前推
//        begin
//            pc_regs_en = 1'b1;
//            if_id_regs_en = 1'b1;
//            id_ex_regs_clr = 1'b0;
//            reg_s_value_latest = ex_write_reg_data;
//        end
//        7'b1_0_0??_11://第四级数据前推
//        begin
//            pc_regs_en = 1'b1;
//            if_id_regs_en = 1'b1;
//            id_ex_regs_clr = 1'b0;
//            reg_s_value_latest = am_write_reg_data;
//        end
//        7'b1_0_10?_11://第四级数据前推
//        begin
//            pc_regs_en = 1'b1;
//            if_id_regs_en = 1'b1;
//            id_ex_regs_clr = 1'b0;
//            reg_s_value_latest = am_write_reg_data;
//        end
//        7'b1_0_110_??://第三级暂停流水线
//        begin
//            pc_regs_en = 1'b0;
//            if_id_regs_en = 1'b0;
//            id_ex_regs_clr = 1'b1;
//            reg_s_value_latest = 32'b0;
//        end
//        default:
//        begin
//            pc_regs_en = 1'b1;
//            if_id_regs_en = 1'b1;
//            id_ex_regs_clr = 1'b0;
//            reg_s_value_latest = wb_rs_value;
//        end
//    endcase
//end

/*
 * 这里的assign语句与其下方的case语句功能相同，但是测试发现这里的assign语句性能更好。
 * case语句作为理解型代码不予删除。
 */
assign pc_regt_en = ~(id_is_use_reg_t & (~is_id_rt_zero) & ex_is_write_reg & is_ex_rt_addr_same & (~ex_is_clean_reg));
assign if_id_regt_en = ~(id_is_use_reg_t & (~is_id_rt_zero) & ex_is_write_reg & is_ex_rt_addr_same & (~ex_is_clean_reg));
assign id_ex_regt_clr = id_is_use_reg_t & (~is_id_rt_zero) & ex_is_write_reg & is_ex_rt_addr_same & (~ex_is_clean_reg);
assign reg_t_value_latest = ({32{ex_is_write_reg & is_ex_rt_addr_same}} & ex_write_reg_data)
                          | ({32{~(ex_is_write_reg & is_ex_rt_addr_same) & am_is_write_reg & is_am_rt_addr_same}} & am_write_reg_data)
                          | ({32{~(ex_is_write_reg & is_ex_rt_addr_same) & ~(am_is_write_reg & is_am_rt_addr_same)}} & wb_rt_value);
//always @ (*)
//begin
//    casez({id_is_use_reg_t,
//           is_id_rt_zero,
//           ex_is_write_reg,is_ex_rt_addr_same,ex_is_clean_reg,
//           am_is_write_reg,is_am_rt_addr_same})
//        7'b1_0_111_??://第三级数据前推
//        begin
//            pc_regt_en = 1'b1;
//            if_id_regt_en = 1'b1;
//            id_ex_regt_clr = 1'b0;
//            reg_t_value_latest = ex_write_reg_data;
//        end
//        7'b1_0_0??_11://第四级数据前推
//        begin
//            pc_regt_en = 1'b1;
//            if_id_regt_en = 1'b1;
//            id_ex_regt_clr = 1'b0;
//            reg_t_value_latest = am_write_reg_data;
//        end
//        7'b1_0_10?_11://第四级数据前推
//        begin
//            pc_regt_en = 1'b1;
//            if_id_regt_en = 1'b1;
//            id_ex_regt_clr = 1'b0;
//            reg_t_value_latest = am_write_reg_data;
//        end
//        7'b1_0_110_??://第三级暂停流水线
//        begin
//            pc_regt_en = 1'b0;
//            if_id_regt_en = 1'b0;
//            id_ex_regt_clr = 1'b1;
//            reg_t_value_latest = 32'b0;
//        end
//        default:
//        begin
//            pc_regt_en = 1'b1;
//            if_id_regt_en = 1'b1;
//            id_ex_regt_clr = 1'b0;
//            reg_t_value_latest = wb_rt_value;
//        end
//    endcase
//end

always @ (*)
begin
    case({id_is_use_hi,id_is_use_lo})
        2'b01:
        begin
            if(ex_is_write_lo)
            begin
                hilo_value_latest = ex_write_lo_value;
            end
            else if(am_is_write_lo)
            begin
                hilo_value_latest = am_write_lo_value;
            end
            else
            begin
                hilo_value_latest = wb_lo_value;
            end
        end
        2'b10:
        begin
            if(ex_is_write_hi)
            begin
                hilo_value_latest = ex_write_hi_value;
            end
            else if(am_is_write_hi)
            begin
                hilo_value_latest = am_write_hi_value;
            end
            else
            begin
                hilo_value_latest = wb_hi_value;
            end
        end
        default:
        begin
            hilo_value_latest = 32'b0;
        end
    endcase
end

endmodule
