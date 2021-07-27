`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/22 15:11:24
// Design Name: 
// Module Name: interleaved_ram
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

module interleaved_ram #(
    parameter I_WIDTH = 5,
    parameter T_WIDTH = 32,
    parameter D_SIZE = 16,
    localparam B_WIDTH = (T_WIDTH + I_WIDTH - 1) / I_WIDTH,
    localparam INTER_LOG = $clog2(B_WIDTH * B_WIDTH),
    localparam T_LOG = $clog2(T_WIDTH)
    )(
    input clka,    // Clock
    input clkb,
    input rst_n,  // Asynchronous reset active low
    input [T_LOG-1:0] addra_y,
    input [T_LOG-1:0] addra_x,
    input [D_SIZE-1:0] dina,
    input [T_LOG-1:0] addrb_y,
    input [T_LOG-1:0] addrb_x,
    output logic [I_WIDTH-1:0][I_WIDTH-1:0][D_SIZE-1:0] doutb,
    input we,
    input re
);
    genvar i, j;
    wire [I_WIDTH-1:0][I_WIDTH-1:0][D_SIZE-1:0] doutb_temp;
    logic [T_LOG-1:0] addrb_y_t;
    logic [T_LOG-1:0] addrb_x_t;

    always_ff @(posedge clkb or negedge rst_n) begin : proc_addrb_y_t
        if(~rst_n) begin
            addrb_x_t <= 0;
            addrb_y_t <= 0;
        end else begin
            addrb_x_t <= addrb_x;
            addrb_y_t <= addrb_y;
        end
    end

    generate
        for (i = 0; i < I_WIDTH; i++) begin
            for (j = 0; j < I_WIDTH; j++) begin
                wire[INTER_LOG-1:0] addra;
                assign addra = (($unsigned(addra_y)+I_WIDTH-1-j)/I_WIDTH)*B_WIDTH + (($unsigned(addra_x)+I_WIDTH-1-i)/I_WIDTH);
                wire[INTER_LOG-1:0] addrb;
                assign addrb = (($unsigned(addrb_y)+I_WIDTH-1-j)/I_WIDTH)*B_WIDTH + (($unsigned(addrb_x)+I_WIDTH-1-i)/I_WIDTH);
                wire wea;
                assign wea = (addra_x % I_WIDTH == i) && (addra_y % I_WIDTH == j) && we;

                rfdp #(
                    .WIDTH(D_SIZE),
                    .DEPTH(B_WIDTH*B_WIDTH)
                    )irfdp(
                    .QA(doutb_temp[i][j]),
                    .AA(addrb),
                    .CLKA(clkb),
                    .CENA(~re),
                    .AB(addra),
                    .DB(dina),
                    .CLKB(clka),
                    .CENB(~wea)
                    );
            end
        end
        
        for (i = 0; i < I_WIDTH; i++) begin
            for (j = 0; j < I_WIDTH; j++) begin
                always_ff @(posedge clkb or negedge rst_n) begin : proc_doutb
                    if(~rst_n) begin
                        doutb[j][i] <= 0;
                    end else begin
                        doutb[j][i] <= doutb_temp[($unsigned(addrb_x_t)+i)%I_WIDTH][($unsigned(addrb_y_t)+j)%I_WIDTH];
                    end
                end
            end
        end

    endgenerate



endmodule : interleaved_ram


