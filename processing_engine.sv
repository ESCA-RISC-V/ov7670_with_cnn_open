`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/21 17:29:32
// Design Name: 
// Module Name: processing_engine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: weight stationary
// 
//////////////////////////////////////////////////////////////////////////////////


module processing_engine #(
    parameter I_D_SIZE = 16,
    parameter F_D_SIZE = 16,
    parameter T_D_SIZE = 37,
    parameter F_WIDTH = 5
    )(
    input clk,    // Clock
    input clk_en, // Clock Enable
    input rst_n,  // Asynchronous reset active low
    
    input [I_D_SIZE-1:0] input_i,
    output logic [T_D_SIZE-1:0] input_o,

    input [F_D_SIZE-1:0] filter_i,
    input filter_we,
    //output logic [F_D_SIZE-1:0] filter_o,

    input [T_D_SIZE-1:0] sum_i,
    output logic [T_D_SIZE-1:0] sum_o
);
    logic [F_D_SIZE-1:0] filter_reg;

    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_reg
        if(~rst_n) begin
            filter_reg <= 0;
        end else if(clk_en) begin
            if (filter_we) begin
                filter_reg <= filter_i;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_input_o
        if(~rst_n) begin
            input_o <= 0;
        end else if(clk_en) begin
            input_o <= input_i;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_sum_o
        if(~rst_n) begin
            sum_o <= 0;
        end else if(clk_en) begin
            sum_o <= $signed(sum_i) + $signed(input_i) * $signed(filter_reg);
        end
    end

endmodule : processing_engine