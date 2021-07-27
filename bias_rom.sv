`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/26 13:58:13
// Design Name: 
// Module Name: bias_rom
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


module bias_rom(
	input							clk,
	input							rstn,
	input			[2:0]			aa,
	input                           cena,
	output reg		[24*1-1:0]	    qa
	);
	
	logic [0:6-1][0:1-1][23:0] weight	 = {
		-24'd33091,  -24'd345382,  -24'd986031,  -24'd314271,  24'd400309,  -24'd448129
	};
	
	always_ff @(posedge clk or negedge rstn) begin : proc_qa
		if(~rstn) begin
			qa <= 0;
		end else begin
			if (~cena) begin
			    qa <= weight[aa];
			end 
		end
	end

endmodule
