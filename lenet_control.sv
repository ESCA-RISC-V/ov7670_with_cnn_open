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
	input          clk,    // Clock
	input          lenet_ready,
	input          data_ready,
	input          rst_n,
	output logic   lenet_go
);

typedef enum logic[1:0] {NOT_READY, READY, AFTER_READY} ready_state;

ready_state data_ready_t, logic_ready_t;


always_ff @(posedge clk or negedge rst_n) begin : proc_data_ready_t                 // preprocessed data is ready
   if(~rst_n) begin
      data_ready_t <= NOT_READY;
   end else begin
      case (data_ready_t)
         NOT_READY : begin
            if (data_ready) begin
               data_ready_t <= READY;
            end
         end // NOT_READY 
         READY : begin
            if (logic_ready_t == READY) begin
               data_ready_t <= AFTER_READY;
            end
         end // READY 
         AFTER_READY : begin
            if (!data_ready) begin
               data_ready_t <= NOT_READY;
            end
         end // AFTER_READY 
         default : begin
            data_ready_t <= NOT_READY;
         end // default 
      endcase
   end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_logic_ready_t                // lenet ready
   if(~rst_n) begin
      logic_ready_t <= READY;
   end else begin
      case (logic_ready_t)
         NOT_READY : begin
            if (lenet_ready) begin
               logic_ready_t <= READY;
            end
         end // NOT_READY 
         READY : begin
            if (data_ready_t == READY) begin
               logic_ready_t <= AFTER_READY;
            end
         end // READY 
         AFTER_READY : begin
            if (!lenet_ready) begin
               logic_ready_t <= NOT_READY;
            end
         end // AFTER_READY 
         default : begin
            logic_ready_t <= NOT_READY;
         end // default 
      endcase
   end
end

always_ff @(posedge clk or negedge rst_n) begin : proc_lenet_go                     // start lenet inference
   if(~rst_n) begin
      lenet_go <= 1'b0;
   end else begin
      if (data_ready_t == READY && logic_ready_t == READY) begin
         lenet_go <= 1'b1;
      end else begin
         lenet_go <= 1'b0;
      end
   end
end

endmodule : lenet_control