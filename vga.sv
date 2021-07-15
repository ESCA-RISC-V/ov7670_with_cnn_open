//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun
//           1216kg@naver.com
// 
// Create Date: 2021/07/01 11:04:31
// Design Name: vga
// Module Name: vga
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: get a image like data send it by using vga port
//               
//
// Dependencies: 
// 
// Revision 1.00 - first well-activate version
// Additional Comments: reference design: http://www.nazim.ru/2512
//                                        can show lenet output at top left corner
//                                      
//////////////////////////////////////////////////////////////////////////////////
module vga	
			#(
            parameter widthlength = 8,
            parameter heightlength = 8,
            parameter lenet_size = 28,
            
			parameter hRez = 640,
			parameter hStartSync = 640 + 16,
			parameter hEndSync = 640 + 16 + 96,
			parameter hMaxCount = 800,

			parameter vRez = 480,
			parameter vStartSync = 480 + 10,
			parameter vEndSync = 480 + 10 + 2,
			parameter vMaxCount = 480 + 10 + 2 + 33,

			parameter hsync_active = 1'b0,
			parameter vsync_active = 1'b0,
			
            localparam left = hRez / 2 - widthlength * lenet_size / 2 - 1,
            localparam right = hRez / 2 + widthlength * lenet_size / 2,
            localparam upper = vRez / 2 - heightlength * lenet_size / 2 - 1,
            localparam downer = vRez / 2 + heightlength * lenet_size / 2
			)
			(
			input	logic		clk25,
			input 	logic[3:0]	frame_pixel,
			input  logic[3:0] lenet_digit,
			input  logic      lenet_ready,
			input  logic      sw,
			input  logic      sw2,
			input  logic      rst_n,
			output	logic[18:0]	frame_addr,
			output logic[3:0]	vga_red,
			output logic[3:0]	vga_green,
			output	logic[3:0]	vga_blue,
			output	logic 		vga_hsync,
			output logic		vga_vsync
			);



	logic [9:0]		hCounter;
	logic [9:0]		vCounter;
	logic [18:0]	address;
	logic 			blank;
	logic [3:0]    digit_t;
	logic [11:0]   temp_rgb;
	logic [6:0]    seven_seg;
	
	assign frame_addr = address;

    always_ff @(posedge lenet_ready or negedge rst_n) begin 
        if (~rst_n) begin
            digit_t <= 4'b1111;
        end else begin
            if (lenet_ready) begin
               digit_t <= lenet_digit;
           end
	    end
    end

	always_comb begin : proc_seven_seg
		case (digit_t)
			4'b0000: 	seven_seg = 7'b1111110;    // 0
			4'b0001: 	seven_seg = 7'b0110000;    // 1
			4'b0010: 	seven_seg = 7'b1101101;    // 2
			4'b0011: 	seven_seg = 7'b1111001;    // 3
			4'b0100: 	seven_seg = 7'b0110011;    // 4
			4'b0101: 	seven_seg = 7'b1011011;    // 5
			4'b0110: 	seven_seg = 7'b1011111;    // 6
			4'b0111: 	seven_seg = 7'b1110010;    // 7
			4'b1000: 	seven_seg = 7'b1111111;    // 8
			4'b1001: 	seven_seg = 7'b1111011;    // 9
			default : 	seven_seg = 7'b0000001;    // -
		endcase
	end

	always_comb begin : proc_temp_rgb
		case (digit_t)
			4'b0000: 	temp_rgb = 12'hF00;
			4'b0001: 	temp_rgb = 12'hF80;
			4'b0010: 	temp_rgb = 12'hFF0;
			4'b0011: 	temp_rgb = 12'h0F0;
			4'b0100: 	temp_rgb = 12'h08F;
			4'b0101: 	temp_rgb = 12'h00F;
			4'b0110: 	temp_rgb = 12'h808;
			4'b0111: 	temp_rgb = 12'hFFF;
			4'b1000: 	temp_rgb = 12'h888;
			4'b1001: 	temp_rgb = 12'h9B4;
            default : 	temp_rgb = 12'hF0F;
        endcase
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_hCounter
		if(~rst_n) begin
			hCounter <= '0;
		end else begin
			if (hCounter == hMaxCount - 1) begin
				hCounter <= 10'b0;
			end else begin
				hCounter <= hCounter + 1;
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_vCounter
		if(~rst_n) begin
			vCounter <= '0;
		end else begin
			if (hCounter == hMaxCount - 1) begin
				if (vCounter == vMaxCount - 1) begin
					vCounter <= 10'b0;
				end else begin
					vCounter <= vCounter + 1;
				end
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_address
		if(~rst_n) begin
			address <= 0;
		end else begin
			if (vCounter >= vRez) begin
				address <= 19'b0;
			end else begin
				if (hCounter < hRez) begin
					address <= address + 1;
				end
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_blank
		if(~rst_n) begin
			blank <= 1'b1;
		end else begin
			if (vCounter >= vRez) begin
				blank <= 1'b1;
			end else begin
				if (hCounter < hRez) begin
					blank <= 1'b0;
				end else begin
					blank <= 1'b1;
				end
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_vga_rgb
		if(~rst_n) begin
			{vga_red, vga_green, vga_blue} <= '0;
		end else begin
			if (blank == 1'b0) begin
				if (sw2 && (hCounter < 60 && vCounter < 100)) begin
					if (seven_seg[6] && hCounter >= 10 && hCounter < 50 && vCounter >= 10 && vCounter < 18) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[3] && hCounter >= 10 && hCounter < 50 && vCounter >= 82 && vCounter < 90) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[5] && hCounter >= 42 && hCounter < 50 && vCounter >= 10 && vCounter < 50) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[4] && hCounter >= 42 && hCounter < 50 && vCounter >= 50 && vCounter < 90) begin       
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[2] && hCounter >= 10 && hCounter < 18 && vCounter >= 50 && vCounter < 90) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[1] && hCounter >= 10 && hCounter < 18 && vCounter >= 10 && vCounter < 50) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else if(seven_seg[0] && hCounter >= 10 && hCounter < 50 && vCounter >= 46 && vCounter < 54) begin
                        {vga_red,vga_green,vga_blue} <= temp_rgb;
                    end else begin
                        {vga_red,vga_green,vga_blue} <= '0;
                    end
				end else begin
					if (sw) begin
                        if ((hCounter == left || hCounter == right)&&(vCounter >= upper && vCounter <= downer)) begin
                            vga_red <= 4'b0;
                            vga_green <= 4'b1111;
                            vga_blue <= 4'b0;	
                        end else if ((hCounter >= left && hCounter <= right)&&(vCounter == upper || vCounter == downer)) begin
                            vga_red <= 4'b0;
                            vga_green <= 4'b1111;
                            vga_blue <= 4'b0;	
                        end else begin
                            vga_red <= frame_pixel;
                            vga_green <= frame_pixel;
                            vga_blue <= frame_pixel;
                        end
                    end else begin
                        vga_red <= frame_pixel;
                        vga_green <= frame_pixel;
                        vga_blue <= frame_pixel;
                    end
				end
			end else begin
                vga_red <= 4'b0;
                vga_green <= 4'b0;
                vga_blue <= 4'b0;
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_vga_hsync
		if(~rst_n) begin
			vga_hsync <= ~hsync_active;
		end else begin
			if (hCounter > hStartSync && hCounter <= hEndSync) begin
				vga_hsync <= hsync_active;
			end else begin
				vga_hsync <= ~hsync_active;
			end
		end
	end

	always_ff @(posedge clk25 or negedge rst_n) begin : proc_vga_vsync
		if(~rst_n) begin
			vga_vsync <= ~vsync_active;
		end else begin
			if (vCounter >= vStartSync && vCounter < vEndSync) begin
				vga_vsync <= vsync_active;
			end else begin
				vga_vsync <= ~vsync_active;
			end
		end
	end

endmodule // vga