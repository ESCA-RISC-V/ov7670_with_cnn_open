//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun
//           1216kg@naver.com
// 
// Create Date: 2021/07/01 11:04:31
// Design Name: ov7670_controllers
// Module Name: ov7670_controllers
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: set registers of ov7670
//               
//
// Dependencies: i2c_senders.sv
//               ov7670_registers.sv
// 
// Revision 1.00 - first well-activate version
// Additional Comments: reference design: http://www.nazim.ru/2512
//                                        
//                                      
//////////////////////////////////////////////////////////////////////////////////
module ov7670_controller	(
							input	logic 		clk,
							input  logic      rst_n,
							output logic		config_finished,
							output logic		sioc,
							inout 	logic 		siod,
							output	logic 		reset,
							output logic 		pwdn,
							output logic 		xclk
							);
	logic 			sys_clk;
	logic [15:0]	command;
	logic 			finished;
	logic 			taken;
	logic 			send;
	logic [7:0]    camera_address = 8'h42; // constant


	always_comb begin : proc_config
		config_finished = finished;
		send = ~finished;
		reset = 1'b1;
		pwdn = 1'b0;
		xclk = sys_clk;
	end

	i2c_sender Inst_i2c_sender(
		.clk(clk),
		.taken(taken),
		.siod(siod),
		.sioc(sioc),
		.send(send),
		.id(camera_address),
		.regi(command[15:8]),
		.value(command[7:0]),
		.rst_n(rst_n)
		);

	ov7670_registers Inst_ov7670_registers(
		.clk(clk),
		.advance(taken),
		.command(command),
		.finished(finished),
		.rst_n(rst_n)
		);

	always_ff @(posedge clk or negedge rst_n) begin : proc_
	    if(~rst_n) begin
            sys_clk <= '0;
	    end else begin
		    sys_clk <= ~sys_clk;
		end
	end
endmodule