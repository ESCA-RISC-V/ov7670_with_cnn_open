`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/21 17:45:19
// Design Name: 
// Module Name: systolic_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module systolic_array #(
    parameter CHANNEL = 2,
    parameter FILTERS = 2,
    parameter I_D_SIZE = 4,
    parameter F_D_SIZE = 4,
    parameter F_WIDTH = 2,
    parameter O_D_SIZE = 4,
    parameter B_D_SIZE = 24,
    localparam T_D_SIZE = I_D_SIZE + F_D_SIZE,// + $clog2(F_WIDTH * F_WIDTH),
    localparam WIDTH = FILTERS,
    localparam HEIGHT = CHANNEL * F_WIDTH * F_WIDTH
    )(
    input clk,    // Clock
    input clk_en, // Clock Enable
    input rst_n,  // Asynchronous reset active low
    input [F_D_SIZE-1:0] filter_i,
    input [HEIGHT-1:0][WIDTH-1:0]filter_we,
    input [HEIGHT-1:0][I_D_SIZE-1:0] vectorized_input,
    input [B_D_SIZE-1:0] bias_i,
    input [FILTERS-1:0] bias_we,
    output logic [FILTERS-1:0][O_D_SIZE-1:0] vectorized_output
);
    wire[WIDTH:0][HEIGHT-1:0][I_D_SIZE-1:0] input_wire;
    wire[HEIGHT:0][WIDTH-1:0][T_D_SIZE-1:0] output_wire;
    logic [FILTERS-1:0][B_D_SIZE-1:0] bias_reg;

    genvar i, j;

    assign output_wire[0] = '0;
    generate
        for (i = 0; i < FILTERS; i++) begin
            always_ff @(posedge clk or negedge rst_n) begin : proc_bias_reg
                if(~rst_n) begin
                    bias_reg[i] <= 0;
                end else if(clk_en) begin
                    if (bias_we[i]) begin
                        bias_reg[i] <= bias_i;
                    end
                end
            end
        end
    endgenerate


    generate
        for (i = 0; i < FILTERS; i++) begin
            logic [i:0][T_D_SIZE-1:0] output_reg;
            always_ff @(posedge clk or negedge rst_n) begin : proc_output_reg
                if(~rst_n) begin
                    output_reg[0] <= 0;
                end else if(clk_en) begin
                    output_reg[0] <= $signed(output_wire[HEIGHT][WIDTH-i-1]) + $signed(bias_reg[WIDTH-i-1]); // fixed point is at between 14th bit and 13th bit (O_D_SIZE is 16 at reference design)
                end
            end
            if (i > 0) begin
                always_ff @(posedge clk or negedge rst_n) begin : proc_output_reg_i_1
                    if(~rst_n) begin
                        output_reg[i:1] <= 0;
                    end else if(clk_en) begin
                        output_reg[i:1] <= output_reg[i-1:0];
                    end
                end
            end
    
            assign vectorized_output[i] = output_reg[i][T_D_SIZE-1:T_D_SIZE-O_D_SIZE-1];
        end


    
        for (i = 0; i < HEIGHT; i++) begin
            logic [i:0][I_D_SIZE-1:0] input_reg;
        
            always_ff @(posedge clk or negedge rst_n) begin : proc_input_reg
                if(~rst_n) begin
                    input_reg[0] <= 0;
                end else if(clk_en) begin
                    input_reg[0] <= vectorized_input[i];
                end
            end

            if (i > 0) begin
                always_ff @(posedge clk or negedge rst_n) begin : proc_input_reg_i_1
                    if(~rst_n) begin
                        input_reg[i:1] <= 0;
                    end else if(clk_en) begin
                        input_reg[i:1] <= input_reg[i-1:0];
                    end
                end
            end
            assign input_wire[0][i] = input_reg[i];
        end


        for (i = 0; i < WIDTH; i++) begin
            for (j = 0; j < HEIGHT; j++) begin
                processing_engine #(
                    .I_D_SIZE(I_D_SIZE),
                    .F_D_SIZE(F_D_SIZE),
                    .T_D_SIZE(T_D_SIZE),
                    .F_WIDTH(F_WIDTH)
                    )i_pe(
                    .clk(clk),
                    .clk_en(clk_en),
                    .rst_n(rst_n),
                    .input_i(input_wire[i][j]),
                    .input_o(input_wire[i+1][j]),
                    .filter_i(filter_i),
                    .filter_we(filter_we[j][i]),
                    .sum_i(output_wire[j][i]),
                    .sum_o(output_wire[j+1][i])
                    );
            end
        end
    endgenerate

    

endmodule : systolic_array