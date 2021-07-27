`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/23 13:55:43
// Design Name: 
// Module Name: rfdp
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


module rfdp #(
    parameter WIDTH = 16,
    parameter DEPTH = 1024
    )(					
	output 		[WIDTH-1:0]				QA,     
	input 		[$clog2(DEPTH)-1:0] 	AA,     
	input 								CLKA,   
	input 								CENA,   
	input 		[$clog2(DEPTH)-1:0] 	AB,     
	input 		[WIDTH-1:0] 			DB,     
	input 								CLKB,   
	input 								CENB    
	);                                          
	xilinx_1w1r_sram #(                         
		.WWORD		(WIDTH),                    
		.WADDR		($clog2(DEPTH)),            
		.DEPTH		(DEPTH)                     
		) u (                                   
		.clka		(CLKA),                     
		.aa			(AA),                       
		.cena		(CENA),                     
		.qa			(QA),                       
                                                
		.clkb		(CLKB),                     
		.ab			(AB),                       
		.cenb		(CENB),                     
		.db			(DB));                      
endmodule