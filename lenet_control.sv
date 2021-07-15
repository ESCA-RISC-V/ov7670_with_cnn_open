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
// Dependencies: 
// 
// Revision 1.00 - first well-activate version
// Additional Comments: get lenet_ready and data_ready signal and make one-clock lenet_go signal
//                                        
//                                      
//////////////////////////////////////////////////////////////////////////////////
module lenet_control (
	input clk,    // Clock
	input lenet_ready,
	input data_ready,
	input rst_n,
	output logic lenet_go
);

logic[1:0] data_ready_t;
logic[1:0] lenet_ready_t;

always_ff @(posedge clk or negedge rst_n) begin : proc_data_ready_t
   if(~rst_n) begin
      data_ready_t <= 2'b00;
   end else begin
      if (data_ready_t == 2'b00 && data_ready == 1'b1) begin
         data_ready_t <= 2'b01;
      end else if (data_ready_t == 2'b01 && lenet_ready_t == 2'b01) begin
         data_ready_t <= 2'b10;
      end else if (data_ready_t == 2'b10 && data_ready == 1'b0) begin
         data_ready_t <= 2'b00;
      end
   end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_lenet_ready_t
   if(~rst_n) begin
      lenet_ready_t <= 2'b01;
   end else begin
      if (lenet_ready_t == 2'b00 && lenet_ready == 1'b1) begin
         lenet_ready_t <= 2'b01;
      end else if (lenet_ready_t == 2'b01 && data_ready_t == 2'b01) begin
         lenet_ready_t <= 2'b10;
      end else if (lenet_ready_t == 2'b10 && lenet_ready == 1'b0) begin
         lenet_ready_t <= 2'b00;
      end
   end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_lenet_go
   if(~rst_n) begin
      lenet_go <= 1'b0;
   end else begin
      if (data_ready_t == 2'b01 && lenet_ready_t == 2'b01) begin
         lenet_go <= 1'b1;
      end else begin
         lenet_go <= 1'b0;
      end
   end
end

endmodule : lenet_control