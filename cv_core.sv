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
module core #(
            parameter width = 640,
            parameter height = 480,
            
            parameter hMaxCount = 640 + 16 + 96 + 48,
			parameter vMaxCount = 480 + 10 + 2 + 33,

            localparam c_frame = hMaxCount * vMaxCount - 1,
            //localparam c_frame = width * height + 1,
            
            // for lenet parameter
            parameter REC_WIDTH = 8,
            parameter REC_HEIGHT = 8,
            parameter CNN_INPUT_WIDTH = 28,
            parameter CNN_INPUT_HEIGHT = 28,
            parameter CNN_INPUT_PAD = 2,
            parameter ACC_D_SIZE = 14,
            parameter THRESHOLD = 'b01100011110000,
            
            localparam CALC_THRESHOLD = THRESHOLD * REC_WIDTH * REC_HEIGHT / (8 * 8),
            localparam LEFT = width / 2 - REC_WIDTH * CNN_INPUT_WIDTH / 2,
            localparam RIGHT = width / 2 + REC_WIDTH * CNN_INPUT_WIDTH / 2,
            localparam UP = height / 2 - REC_HEIGHT * CNN_INPUT_HEIGHT / 2,
            localparam DOWN = height / 2 + REC_HEIGHT * CNN_INPUT_HEIGHT / 2,
            localparam CNN_REAL_WIDTH = 2 * CNN_INPUT_PAD + CNN_INPUT_WIDTH,
            localparam CNN_REAL_HEIGHT = 2 * CNN_INPUT_PAD + CNN_INPUT_HEIGHT
            // lenet parameter end
            )
            (
			input                         clk24,
			input        [7:0]	          din,
			input                         rst_n,
			
			output       [18:0]	          addr_mem0,
			output       [18:0]	          addr_mem1,
			output logic [3:0]	          dout,
			output logic                  we,
			
			// for lenet input output
			input                         lenet_doing_signal,
			input                         lenet_showing_signal,
			output logic [9:0]            addr_mem2,
			output logic [7:0]            lenet_dout,
			output logic                  lenet_we,
			output logic                  lenet_data_ready,
			// lenet input output end

            output logic                  core_end
			);
	
	logic[18:0]	counter;
	logic[18:0]	address_mem0;
	logic[18:0]	address_mem1;
    logic[9:0]  address_mem2;
    logic       we_t;
    
    assign addr_mem0 = address_mem0;
    assign addr_mem1 = address_mem1;
    assign addr_mem2 = address_mem2;
    
    logic [CNN_INPUT_WIDTH-1:0][ACC_D_SIZE-1:0] accum_temp;
    logic [CNN_INPUT_WIDTH-1:0][ACC_D_SIZE-1:0] out_temp;
    
    logic [9:0] hor, ver;
    logic lenet_doing, lenet_showing;
    logic [ACC_D_SIZE-1:0] lenet_dout_temp;
    
    generate
        if (1 << $clog2(REC_WIDTH * REC_HEIGHT) == REC_WIDTH * REC_HEIGHT) begin
            assign lenet_dout = lenet_dout_temp >> $clog2(REC_WIDTH * REC_HEIGHT);
        end 
        else begin
            assign lenet_dout = $unsigned(lenet_dout_temp / (REC_WIDTH * REC_HEIGHT)); 
        end  
    endgenerate
    
    assign core_end = hor == hMaxCount - 1 && ver == vMaxCount - 1;
    
// counter - count per pixel - used for checking one frame processing ends.
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_counter                                        
        if(~rst_n) begin
            counter <= '0;
        end 
        else begin
            if (counter == c_frame) begin
                counter <= '0;
            end 
            else begin
                counter <= counter + 1;
            end
        end
    end

// hor and ver
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_hor_ver
        if(~rst_n) begin
            hor <= 0;
            ver <= 0;
        end 
        else begin
            if (counter == c_frame) begin
                hor <= 0;
                ver <= 0;
            end 
            else begin
                if (hor == hMaxCount - 1) begin
                    hor <= 0;
                    ver <= ver + 1;
                end 
                else begin
                    hor <= hor + 1;
                    ver <= ver;
                end
            end
        end
    end
    
// address_mem0 - address of pixel of input data
    assign address_mem0 = hor + ver * width;
// lenet_doing
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_lenet_doing
        if(~rst_n) begin
            lenet_doing <= lenet_doing_signal;
        end 
        else begin
            if (counter == c_frame) begin
                lenet_doing <= lenet_doing_signal;
            end 
            else begin
            
            end
        end
    end

// lenet_doing
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_lenet_showing
        if(~rst_n) begin
            lenet_showing <= lenet_showing_signal;
        end 
        else begin
            if (counter == c_frame) begin
                lenet_showing <= lenet_showing_signal;
            end 
            else begin
            
            end
        end
    end
    
// address_mem1
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_address_mem1                               
        if(~rst_n) begin
            address_mem1 <= '0;
        end 
        else begin
            if (lenet_showing) begin
                if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                    if (ver - UP < REC_HEIGHT) begin
                        address_mem1 <= address_mem0 + width * (CNN_INPUT_HEIGHT - 1) * REC_HEIGHT;
                    end 
                    else begin
                        address_mem1 <= address_mem0 - width * REC_HEIGHT;
                    end
                end 
                else begin
                    address_mem1 <= address_mem0;
                end
            end 
            else begin
                address_mem1 <= address_mem0;
            end
        end
    end
    
// address_mem2
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_address_mem2
        if(~rst_n) begin
            address_mem2 <= '0;
        end 
        else begin
            if (counter == c_frame) begin
                address_mem2 <= '0;
            end 
            else begin
                if (lenet_doing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        if ((hor - LEFT) % REC_WIDTH == REC_WIDTH - 1 && (ver - UP) % REC_HEIGHT == REC_HEIGHT - 1) begin
                            address_mem2 <= CNN_INPUT_PAD + CNN_INPUT_PAD * CNN_REAL_WIDTH + ((hor - LEFT) / REC_WIDTH) + CNN_REAL_WIDTH * ((ver - UP) / REC_HEIGHT);
                        end 
                        else begin
                            
                        end
                    end 
                    else begin
                        
                    end
                end 
                else begin
                    address_mem2 <= 0; 
                end
            end
        end
    end
    
// accum_temp
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_accum_temp
        if(~rst_n) begin
            accum_temp <= '0;
        end 
        else begin
            if (counter == c_frame) begin
                //accum_temp <= '0; // no need to 
            end 
            else begin
                if (lenet_doing | lenet_showing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        if ((hor - LEFT) % REC_WIDTH == 0 && (ver - UP) % REC_HEIGHT == 0) begin
                            accum_temp[(hor - LEFT) / REC_WIDTH] <= din;
                        end 
                        else begin
                            accum_temp[(hor - LEFT) / REC_WIDTH] <= accum_temp[(hor - LEFT) / REC_WIDTH] + din; 
                        end
                    end 
                    else begin
                        //accum_temp <= '0;
                    end
                end 
                else begin
                    //accum_temp <= '0; 
                end
            end
        end
    end
    
// accum_temp
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_out_temp
        if(~rst_n) begin
            out_temp <= '0;
        end 
        else begin
            if (counter == c_frame) begin
            
            end 
            else begin
                if (lenet_showing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        if ((hor - LEFT) % REC_WIDTH == REC_WIDTH - 1 && (ver - UP) % REC_HEIGHT == REC_HEIGHT - 1) begin
                            if (accum_temp[(hor - LEFT) / REC_WIDTH] + din + REC_WIDTH * REC_HEIGHT / 2 < CALC_THRESHOLD) begin
                                out_temp[(hor - LEFT) / REC_WIDTH] <= accum_temp[(hor - LEFT) / REC_WIDTH] + din + REC_WIDTH * REC_HEIGHT / 2;
                            end 
                            else begin
                                out_temp[(hor - LEFT) / REC_WIDTH] <= $unsigned(8'b11111111 * REC_WIDTH * REC_HEIGHT);
                            end
                        end 
                        else begin
                           
                        end
                    end 
                    else begin
                       
                    end
                end 
                else begin
                  
                end
            end
        end
    end    
    
// accum_temp
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_lenet_dout_temp
        if(~rst_n) begin
            lenet_dout_temp <= '0;
        end 
        else begin
            if (counter == c_frame) begin
            
            end 
            else begin
                if (lenet_doing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        if ((hor - LEFT) % REC_WIDTH == REC_WIDTH - 1 && (ver - UP) % REC_HEIGHT == REC_HEIGHT - 1) begin
                            if (accum_temp[(hor - LEFT) / REC_WIDTH] + din + REC_WIDTH * REC_HEIGHT / 2 < CALC_THRESHOLD) begin
                                lenet_dout_temp <= accum_temp[(hor - LEFT) / REC_WIDTH] + din + REC_WIDTH * REC_HEIGHT / 32;
                            end 
                            else begin
                                lenet_dout_temp <= $unsigned(8'b11111111 * REC_WIDTH * REC_HEIGHT);
                            end
                        end 
                        else begin
                           
                        end
                    end 
                    else begin
                       
                    end
                end 
                else begin
                  
                end
            end
        end
    end    
    
// accum_temp
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_lenet_we
        if(~rst_n) begin
            lenet_we <= '0;
        end 
        else begin
            if (counter == c_frame) begin
                lenet_we <= '0;
            end 
            else begin
                if (lenet_doing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        if ((hor - LEFT) % REC_WIDTH == REC_WIDTH - 1 && (ver - UP) % REC_HEIGHT == REC_HEIGHT - 1) begin
                            lenet_we <= 1'b1;
                        end 
                        else begin
                            lenet_we <= 1'b0;
                        end
                    end 
                    else begin
                        lenet_we <= 1'b0;
                    end
                end 
                else begin
                    lenet_we <= 1'b0;
                end
            end
        end
    end    
    
// vga output pixel data
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_dout                                            
        if(~rst_n) begin
            dout <= '0;
        end 
        else begin
            if (counter == c_frame) begin
                dout <= '0;
            end 
            else begin
                if (lenet_showing) begin
                    if (hor >= LEFT && ver >= UP && hor < RIGHT && ver < DOWN) begin
                        dout <= $unsigned(out_temp[(hor - LEFT) / REC_WIDTH] / ((REC_WIDTH * REC_HEIGHT) * 16));
                    end 
                    else begin
                        dout <= din[7:4];
                    end
                end 
                else begin
                    dout <= din[7:4];
                end
            end
        end
    end

// write enable of vga output pixel
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_we                                             
        if(~rst_n) begin
            we <= 0;
            we_t <= 0;
        end 
        else begin
            we <= we_t;
            if (hor < width && ver < height) begin
                we_t <= 1'b1;
            end 
            else begin
                we_t <= 1'b0;
            end
        end
    end

// write enable of vga output pixel
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_lenet_data_ready                                             
        if(~rst_n) begin
            lenet_data_ready <= 1'b0;
        end 
        else begin
            if (counter == c_frame) begin
                lenet_data_ready <= 1'b0;
            end 
            else begin
                if (lenet_doing && hor == RIGHT - 1 && ver == DOWN - 1) begin
                    lenet_data_ready <= 1'b1;
                end 
                else begin
                    lenet_data_ready <= 1'b0;
                end
            end
        end
    end

    
endmodule // core