module ov7670_capture 	(
						input  logic		pclk,
						input  logic 		vsync,
						input  logic		href,
						input  logic        sw,
						input  logic[7:0]	din,
						input  logic        rst_n,
						output logic[18:0]	addr,
						output logic[7:0]	dout,
						output logic 		we
						);
	logic[18:0] address;
	logic state;
    logic we_go;
    
//	initial begin
//		address = '0;
//		state = '0;
//	end

	assign addr = address;
	always_ff @(posedge pclk or negedge rst_n) begin : proc_1
	   if(~rst_n) begin
	       address <= '0;
	       dout <= '0;
	       we <= '0;
	       state <= '0;
	       we_go <= 1'b1;
	   end else begin
            if (vsync == 1'b1) begin
                address <= '0;
                we <= '0;
                state <= '0;
                we_go <= sw;
            end else begin
                if (state == 1'b1 && href == 1'b1) begin
                    address <= address + 1;
                    we <= '0;
                    state <= '0;
                end else begin
                    dout <= ~din;
                    we <= ~we_go;
                    state <= '1;
                end
            end
        end
	end

endmodule : ov7670_capture