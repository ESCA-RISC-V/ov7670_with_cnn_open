//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun
//           1216kg@naver.com
// 
// Create Date: 2021/07/01 11:04:31
// Design Name: ov7670_core
// Module Name: ov7670_core
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: get a image like data and process it before send it to vga and lenet
//              
// Dependencies: 
// 
// Revision 1.00 - first well-activate version
// Additional Comments: reference design: http://www.nazim.ru/2512
//                                        can change center image to lower resolution
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
			parameter threshold = 'b0110001111,
            
            localparam THRESHOLD = threshold * widthlength * heightlength / (8 * 8) ,
			
            localparam c_frame = width * height,                                 // number of total pixels per image
            localparam left = width / 2 - widthlength * lenet_size / 2,          // resolution-changing rectangle's left, right, up, down
            localparam right = width / 2 + widthlength * lenet_size / 2,
            localparam upper = height / 2 - heightlength * lenet_size / 2,
            localparam downer = height / 2 + heightlength * lenet_size / 2
            )
            (
			input                         clk25,
			input        [7:0]	          din,
			input                         lenet_signal,
			input                         rst_n,
			
			output       [18:0]	          addr_mem0,
			output       [18:0]	          addr_mem1,
			output       [9:0]            addr_mem2,
			output logic [3:0]	          dout,
			output logic                  we,
			output       [7:0]            lenet_dout,
			output logic                  lenet_we,
			output logic                  data_ready
			);
	
	
	logic[18:0]	counter;
	logic[18:0]	address_mem0;
	logic[18:0] address_mem1;
	logic[9:0] address_mem2;
    logic[lenet_size-1:0][ACC_D_SIZE:0] accu_temp;
    logic[lenet_size-1:0][ACC_D_SIZE:0] out_temp;
    logic[9:0]hcounter;
    logic[9:0]vcounter;
    logic lenet_doing;
    logic [ACC_D_SIZE:0]lenet_dataout;

    assign addr_mem0 = address_mem0;
    assign addr_mem1 = address_mem1;
    assign addr_mem2 = address_mem2;
    assign lenet_dout = $unsigned(lenet_dataout * 16 / (widthlength * heightlength));

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_counter                                        // counter - count per pixel - used for checking one frame processing ends.
        if(~rst_n) begin
            counter <= '0;
        end else begin
            if (counter >= c_frame) begin
                counter <= '0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_address_mem0                                   // address_mem0 - address of pixel of input data
        if(~rst_n) begin
            address_mem0 <= '0;
        end else begin
            if (counter >= c_frame) begin
                address_mem0 <= '0;
            end else begin
                address_mem0 <= address_mem0 + 1;
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_hcounter                                       // horizontal counter for pixel
        if(~rst_n) begin
            hcounter <= 0;
        end else begin
            if (counter >= c_frame) begin
                hcounter <= 0;
            end else begin
                if (hcounter == width - 1) begin
                    hcounter <= 0;
                end else begin
                    hcounter <= hcounter + 1;
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_vcounter                                       // vertical counter for pixel
        if(~rst_n) begin
            vcounter <= 0;
        end else begin
            if (counter >= c_frame) begin
                vcounter <= 0;
            end else begin
                if (hcounter == width - 1) begin
                    vcounter <= vcounter + 1;
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_lenet_doing                                    // do resolution change or not - check for each frame's begining
        if(~rst_n) begin
            lenet_doing <= lenet_signal;
        end else begin
            if (counter >= c_frame) begin
                lenet_doing <= lenet_signal;
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_address_mem1                                   // address for ouput image's pixel - this will be shown on the monitor
        if(~rst_n) begin
            address_mem1 <= 0;
        end else begin
            if (counter >= c_frame) begin
                address_mem1 <= '0;
            end else begin
                if (lenet_doing == 1'b1) begin
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if (vcounter - upper < heightlength) begin
                            address_mem1 <= vcounter * width + hcounter + width * (lenet_size - 1) * heightlength - 1;
                        end else begin
                            address_mem1 <= vcounter * width + hcounter - width * heightlength - 1;
                        end
                    end else begin
                        address_mem1 <= vcounter * width + hcounter - 1;
                    end
                end else begin
                    address_mem1 <= vcounter * width + hcounter - 1;
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_address_mem2                                   // lenet_inference input image's pixel address
        if(~rst_n) begin
            address_mem2 <= 0;
        end else begin
            if (counter >= c_frame) begin
                address_mem2 <= 0;
            end else begin
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if ((hcounter - left) % widthlength == (widthlength - 1) && (vcounter - upper) % heightlength == (heightlength - 1)) begin       
                            address_mem2 <= 2 + 64 + ((hcounter - left) / widthlength) + 32 * ((vcounter - upper) / heightlength);
                        end
                    end
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_accu_temp                                      // register who stores summary of the block section
        if(~rst_n) begin
            accu_temp <= '0;
        end else begin
            if (counter < c_frame) begin
                if (lenet_doing == 1'b1) begin
                    if ((hcounter - left) % widthlength == 0 && (vcounter - upper) % heightlength ==0) begin
                        accu_temp[(hcounter-left)/widthlength] <= din[7:4];                                                                         
                    end else begin
                        accu_temp[(hcounter-left)/widthlength] <= accu_temp[(hcounter-left)/widthlength] + din[7:4];
                    end
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_out_temp                                       // register who stores output image for block section
        if(~rst_n) begin
            out_temp <= '0;
        end else begin
            if (counter < c_frame) begin
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if ((hcounter - left) % widthlength == (widthlength - 1) && (vcounter - upper) % heightlength == (heightlength - 1)) begin       
                            if ((accu_temp[(hcounter-left)/widthlength] + din[7:4] + 2 ** (ACC_D_SIZE - 8)) < THRESHOLD) begin
                                out_temp[(hcounter-left)/widthlength] <= accu_temp[(hcounter-left)/widthlength] + din[7:4] + widthlength * heightlength / 2;                // add widthlength * heightlength / 2, because I want to do round, not round down
                            end else begin
                                out_temp[(hcounter-left)/widthlength] <= '1;
                            end
                        end
                    end
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_lenet_dataout                                  // lenet_inference input image's pixel data
        if(~rst_n) begin
            lenet_dataout <= 0;
        end else begin
            if (counter < c_frame) begin
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if ((hcounter - left) % widthlength == (widthlength - 1) && (vcounter - upper) % heightlength == (heightlength - 1)) begin       
                            if ((accu_temp[(hcounter-left)/widthlength] + din[7:4] + 2 ** (ACC_D_SIZE - 8)) < THRESHOLD) begin
                                lenet_dataout <= accu_temp[(hcounter-left)/widthlength] + din[7:4] + widthlength * heightlength / 32;                                       // add widthlength * heightlength / 32, because I want to do round, not round down
                            end else begin
                                lenet_dataout <= '1;
                            end
                        end
                    end
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_lenet_we                                       // lenet write enable - when accumulate block section is over
        if(~rst_n) begin
            lenet_we <= '0;
        end else begin
            if (counter >= c_frame) begin
                lenet_we <= '0;
            end else begin
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        if ((hcounter - left) % widthlength == (widthlength - 1) && (vcounter - upper) % heightlength == (heightlength - 1)) begin       
                            lenet_we <= 1'b1;
                        end else begin
                            lenet_we <= 1'b0;                                                   
                        end
                    end else begin
                        lenet_we <= 1'b0;
                    end
                end else begin
                    lenet_we <= 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_dout                                           // vga output pixel data 
        if(~rst_n) begin
            dout <= '0;
        end else begin
            if (counter >= c_frame) begin
                dout <= '0;
            end else begin
                if (lenet_doing == 1'b1) begin 
                    if (hcounter >= left && vcounter >= upper && hcounter < right && vcounter < downer) begin
                        dout <= $unsigned(out_temp[(hcounter-left)/widthlength]) / (widthlength * heightlength);
                    end else begin
                        dout <= din[7:4];
                    end
                end else begin
                    dout <= din[7:4];
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_we                                             // write enable of vga output pixel
        if(~rst_n) begin
            we <= 0;
        end else begin
            if (counter >= c_frame) begin
                we <= '0;
            end else begin
                if (counter == 1'b1) begin
                    we <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk25 or negedge rst_n) begin : proc_data_ready                                     // 1 when whole preprocessing of a frame as a lenet input image is over
        if(~rst_n) begin
            data_ready <= 0;
        end else begin
            if (counter >= c_frame) begin
                data_ready <= '0;
            end else begin
                if (lenet_doing == 1'b1 && hcounter == right - 1 && vcounter == downer - 1) begin
                    data_ready <= 1'b1;
                end else begin
                    data_ready <= 1'b0;
                end
            end
        end
    end
    
endmodule // core