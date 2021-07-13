module lenet_control (
	input clk,    // Clock
	input lenet_ready,
	input data_ready,
	input rst_n,
	output logic lenet_go
);

logic[1:0] data_ready_t;
logic[1:0] lenet_ready_t;

always_ff @(posedge clk or negedge rst_n) begin 
    if (~rst_n) begin
        data_ready_t <= 2'b00;
        lenet_ready_t <= 2'b01;
        lenet_go <= 1'b0;
    end else begin
        if (data_ready == 1'b1 && data_ready_t == 2'b00) begin
           data_ready_t <= 2'b01;
        end else if(data_ready == 1'b0 && data_ready_t == 2'b10) begin
           data_ready_t <= 2'b00;
        end
        if (lenet_ready == 1'b1 && lenet_ready_t == 2'b00) begin
           lenet_ready_t <= 2'b01; 
        end else if(lenet_ready == 1'b0 && lenet_ready_t == 2'b10) begin
           lenet_ready_t <= 2'b00;
        end
        if(data_ready_t == 2'b01 && lenet_ready_t == 2'b01) begin
           data_ready_t <= 2'b10;
           lenet_ready_t <= 2'b10;
           lenet_go <= 1'b1;
        end else begin
           lenet_go <= 1'b0;
    	end
    end
end


endmodule : lenet_control