//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun
//           1216kg@naver.com
// 
// Create Date: 2021/07/01 11:04:31
// Design Name: ov7670_capture
// Module Name: ov7670_capture
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: get a image like data and process it before send it to vga
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: reference design: http://www.nazim.ru/2512
// 
//////////////////////////////////////////////////////////////////////////////////
module core 
            #
            (
            parameter width = 640,
            parameter height = 480,
			parameter widthlength = 8,
			parameter heightlength = 8,
			parameter lenet_size = 28,
			parameter ACC_D_SIZE = 9,
			parameter threshold = 'b1001110000,
            
            localparam THRESHOLD = threshold * widthlength * heightlength / (8 * 8) ,
			
            localparam c_frame = width * height,                                 // number of total pixels per image
            localparam left = width / 2 - widthlength * lenet_size / 2,          // resolution-changing rectangle's left, right, up, down
            localparam right = width / 2 + widthlength * lenet_size / 2,
            localparam upper = height / 2 - heightlength * lenet_size / 2,
            localparam downer = height / 2 + heightlength * lenet_size / 2
            )
            (
			input  logic                  clk25,
			input  logic[7:0]	          din,
			input  logic                  lenet_signal,
			input  logic                  rst_n,
			
			output logic[18:0]	          addr_mem0,
			output logic[18:0]	          addr_mem1,
			output logic[9:0]             addr_mem2,
			output logic[3:0]	          dout,
			output logic                  we,
			output logic[7:0]             lenet_dout,
			output logic                  lenet_we,
			output logic                  data_ready
			);
	
	
	logic[18:0]	counter;
	logic[18:0]	address_mem0;
    logic[lenet_size-1:0][ACC_D_SIZE:0] accu_temp;
    logic[lenet_size-1:0][ACC_D_SIZE:0] out_temp;
    logic[9:0]hcounter;
    logic[9:0]vcounter;
    logic lenet_doing;
    logic [ACC_D_SIZE:0]lenet_dataout;

    assign addr_mem0 = address_mem0;
    //assign lenet_dout = lenet_dataout[ACC_D_SIZE:ACC_D_SIZE-7];
    assign lenet_dout = $unsigned(lenet_dataout * 16 / (widthlength * heightlength));
	always_ff @(posedge clk25 or negedge rst_n) begin : proc_25
        if (~rst_n) begin
            counter <= '0;
            address_mem0 <= '0;
            accu_temp <= '0;
            out_temp <= '0;
            hcounter <= '0;
            vcounter <= '0;
            lenet_doing <= lenet_signal;
            lenet_dataout <= '0;
            
            addr_mem1 <= '0;
            addr_mem2 <= '0;
            dout <= '0;
            we <= '0;
            lenet_we <= '0;
            data_ready <= '0;
        end else begin
            if (counter >= c_frame + 1) begin                                                                                                        // originally >= c_frame, but because of sync, we need to calculate until address_mem1 is c_frame + 1, so I changed >= to >            
                counter <= '0;
                address_mem0 <= '0;
                hcounter <= '0;
                vcounter <= '0;
                lenet_doing <= lenet_signal;
                
                addr_mem1 <= '0;
                addr_mem2 <= '0;
                we <= '0;
                lenet_we <= '0;
                data_ready <= '0;     
            end else begin
                address_mem0 <= address_mem0 + 1;
                counter <= counter + 1;
                if(counter == 1) begin
                    we <= '1; 
                end
                if (hcounter == width - 1) begin
                    hcounter <= 0;
                    vcounter <= vcounter + 1;
                end else begin
                    hcounter <= hcounter + 1;
                end
                
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if ((hcounter - left) % widthlength == 0 && (vcounter - upper) % heightlength ==0) begin
                            accu_temp[(hcounter-left)/widthlength] <= din[7:4];                                                                         
                            lenet_we <= 1'b0;
                        end else if ((hcounter - left) % widthlength == (widthlength - 1) && (vcounter - upper) % heightlength == (heightlength - 1)) begin       
                            addr_mem2 <= 2 + 64 + ((hcounter - left) / widthlength) + 32 * ((vcounter - upper) / heightlength);
                            if ((accu_temp[(hcounter-left)/widthlength] + din[7:4] + 2 ** (ACC_D_SIZE - 8)) > THRESHOLD) begin
                                lenet_dataout <= accu_temp[(hcounter-left)/widthlength] + din[7:4] + widthlength * heightlength / 32;                                       // add widthlength * heightlength / 32, because I want to do round, not round down
                                out_temp[(hcounter-left)/widthlength] <= accu_temp[(hcounter-left)/widthlength] + din[7:4] + widthlength * heightlength / 2;                // add widthlength * heightlength / 2, because I want to do round, not round down
                            end else begin
                                lenet_dataout <= '0;
                                out_temp[(hcounter-left)/widthlength] <= '0;
                            end
                            lenet_we <= 1'b1;
                        end else begin
                            accu_temp[(hcounter-left)/widthlength] <= accu_temp[(hcounter-left)/widthlength] + din[7:4];
                            lenet_we <= 1'b0;                                 					
                        end
                               
                        dout <= $unsigned(out_temp[(hcounter-left)/widthlength]) / (widthlength * heightlength);
                        
                        if (vcounter - upper < heightlength) begin
                            addr_mem1 <= vcounter * width + hcounter + width * (lenet_size - 1) * heightlength - 1;
                        end else begin
                            addr_mem1 <= vcounter * width + hcounter - width * heightlength - 1;
                        end
                    end else begin
                        dout <= din[7:4];
                        addr_mem1 <= vcounter * width + hcounter - 1;
                        lenet_we <= 1'b0;
                    end
        
                end else begin
                    dout <= din[7:4];
                    addr_mem1 <= vcounter * width + hcounter - 1;
                    lenet_we <= 1'b0;
                end
                
                if (lenet_doing == 1'b1 && hcounter == right-1 && vcounter == downer-1) begin
                    data_ready <= 1'b1;
                end else begin
                    data_ready <= 1'b0;
                end
            end
		end
	end
endmodule // core