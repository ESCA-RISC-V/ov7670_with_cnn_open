//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun
//           1216kg@naver.com
// 
// Create Date: 2021/07/01 11:04:31
// Design Name: ov7670_top
// Module Name: ov7670_top
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: top module of ov7670 to VGA
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: reference design: http://www.nazim.ru/2512
//                      up button - reset ov7670
//                      switch 6 - pause image
//                      switch 7 - change resolution
//////////////////////////////////////////////////////////////////////////////////


module ov7670_top	#(
                    parameter screenwidth = 640,
                    parameter screenheight = 480,
                    parameter widthlength = 8,                                            // lenet_input data pixel accumulation size
                    parameter heightlength = 8,
                    parameter lenet_size = 28,
                    parameter threshold = 'b1001110000,
                    
                    localparam ACC_D_SIZE = $clog2(widthlength * heightlength) + 4 - 1           // each lenet pixel's data size
                    
                    )(
					input 	logic 		    clk100_zed,
					output  logic 			OV7670_SIOC,                           // similar with I2C's SCL
					inout 	logic 			OV7670_SIOD,                           // similar with I2C's SDA
					output  logic 			OV7670_RESET,                          // ov7670 reset
					output  logic 			OV7670_PWDN,                           // ov7670 power down
					input 	logic 			OV7670_VSYNC,                          // ov7670 vertical sync
					input 	logic 			OV7670_HREF,                           // ov7670 horizontal reference
					input 	logic 			OV7670_PCLK,                           // ov7670 pclock
					output  logic 			OV7670_XCLK,                           // ov7670 xclock
					input 	logic [7:0] 	OV7670_D,                              // ov7670 data
		
					output  logic [7:0]		LED,                                   // zedboard_LED
		
					output  logic [3:0]		vga_red,                               // vga red output
					output	logic [3:0]		vga_green,                             // vga green output
					output	logic [3:0]		vga_blue,                              // vga blue output
					output	logic 			vga_hsync,                             // vga horizontal sync
					output	logic 			vga_vsync,                             // vga vertical sync

					input 	logic			btn,                                    // zedboard BTNU (up button)
					input   logic           PAD_RESET,
					input 	logic [7:0]		SW                                    // zedboard SW (switch )

					);
        
	// clocks
	logic			clk100;
	logic			clk75;
	logic			clk50;
	logic 			clk25;
	logic           clk200;
	// capture to mem_blk_0
	logic [18:0]	capture_addr;
	logic [7:0] 	capture_data;
	logic [0:0]		capture_we;
	// mem_blk_0 -> core -> mem_blk_1
	logic [7:0]		data_to_core;
	logic [3:0]		data_from_core;
	logic [18:0]	addr_core_to_mem0;
	logic [18:0]	addr_core_to_mem1;
	logic [0:0]		we_core_to_mem1;
	// mem_blk_1 to vga
	logic [18:0]	frame_addr;
	logic [3:0]		frame_pixel;
	// controller to LED
	logic 			config_finished;
	// memory2 controller
	logic [9:0]		addr_core_to_mem2;
	logic [7:0]		data_core_to_mem2;
	logic 			lenet_we;
	// lenet memory access
	logic [9:0]    addr_lenet_to_mem2;
	logic [15:0]   data_lenet_from_mem2;
	logic          ren_lenet_to_mem2;
	// lenet control and output
	logic          lenet_rstn;
	logic          lenet_go;
	logic          lenet_ready;
	logic[3:0]     lenet_digit;
	logic          data_ready;
	
	logic [7:0] zerotemp;
    
    wire rst_n = ~PAD_RESET;


    assign LED = {SW[7:4], 3'b000 , config_finished};             // show LED some informations
    //assign zerotemp = 8'b00000000;
    
		clk_wiz_0 clkwiz(                                             // clock generator
			.clk_in_wiz(clk100_zed),
			.clk_100wiz(clk100),
			.clk_75wiz(clk75),
			.clk_50wiz(clk50),
			.clk_25wiz(clk25),
			.clk_200wiz(clk200),
			.resetn(rst_n)
			);                                                       

		ov7670_capture icapture(                                      // gets datas from ov7670 and stores them to fb1
			.pclk(OV7670_PCLK),
			.vsync(OV7670_VSYNC),
			.href(OV7670_HREF),
			.sw(SW[6]),
			.rst_n(rst_n),
			.din(OV7670_D),
			.addr(capture_addr),
			.dout(capture_data),
			.we(capture_we[0])
			);

    	blk_mem_gen_0 fb1(                                             // stores captured data
			.clka(OV7670_PCLK),
			.wea(capture_we),
			.addra(capture_addr),
			.dina(capture_data),

			.clkb(clk50),
			.addrb(addr_core_to_mem0),
			.doutb(data_to_core)
			);

		core #(
		    .width(screenwidth),
		    .height(screenheight),
		    .widthlength(widthlength),
		    .heightlength(heightlength),
		    .lenet_size(lenet_size),
		    .ACC_D_SIZE(ACC_D_SIZE),
		    .threshold(threshold)
		    )icore(                                                   // loads data from fb1 and processes it, stores processed data to fb2 and fb3, you can modify this module to change vga output or anything else
			.clk25(clk25),
			.din(data_to_core),
			.lenet_signal(SW[7]),
			.rst_n(rst_n),
			.addr_mem0(addr_core_to_mem0),
			.addr_mem1(addr_core_to_mem1),
			.dout(data_from_core),
			.we(we_core_to_mem1[0]),
			.addr_mem2(addr_core_to_mem2),
			.lenet_dout(data_core_to_mem2),
			.lenet_we(lenet_we),
			.data_ready(data_ready)
			);

		blk_mem_gen_1 fb2(                                            // stores processed data, connected with vga module
			.clka(clk25),
			.wea(we_core_to_mem1),
			.addra(addr_core_to_mem1),
			.dina(data_from_core),

			.clkb(clk50),
			.addrb(frame_addr),
			.doutb(frame_pixel)
			);

		vga #(
		     .widthlength(widthlength),
		     .heightlength(heightlength),
		     .lenet_size(lenet_size),
		     .hRez(640),
		     .hStartSync(640 + 16),
		     .hEndSync(640 + 16 + 96),
		     .hMaxCount(640 + 16 + 96 + 48),
		     .vRez(480),
		     .vStartSync(480 + 10),
		     .vEndSync(480 + 10 + 2),
		     .vMaxCount(480 + 10 + 2 + 33),
		     .hsync_active(1'b0),
		     .vsync_active(1'b0)
		     )ivga(                                                     // loads data from fb and sends it to vga output
			.clk25(clk25),
			.frame_pixel(~frame_pixel),
			.lenet_digit(lenet_digit),
			.lenet_ready(lenet_ready),
			.sw(SW[5]),
			.sw2(SW[4]),
			.rst_n(rst_n),
			.frame_addr(frame_addr),
			.vga_red(vga_red),
			.vga_green(vga_green),
			.vga_blue(vga_blue),
			.vga_hsync(vga_hsync),
			.vga_vsync(vga_vsync)
			);

		ov7670_controller controller(                                 // initialize ov7670 or reset ov7670, reset has some bug to be fixed in future
			.clk(clk50),
			.sioc(OV7670_SIOC),
			.rst_n(rst_n),
			.config_finished(config_finished),
			.siod(OV7670_SIOD),
			.pwdn(OV7670_PWDN),
			.reset(OV7670_RESET),
			.xclk(OV7670_XCLK)
			);
			
		blk_mem_gen_2 fb3(                                            // stores processed data, for now, stores datas for Lenet input
			.clka(clk25),
			.wea(lenet_we),
			.addra(addr_core_to_mem2),
			.dina({8'b0, data_core_to_mem2}),

			.clkb(clk100),
			.addrb(addr_lenet_to_mem2),
			.doutb(data_lenet_from_mem2),
			.enb(~ren_lenet_to_mem2)
			);
			
		lenet ilenet(
		    .clk(clk100),
		    .rstn(rst_n),
		    .go(lenet_go),
		    .cena_src(ren_lenet_to_mem2),
		    .aa_src(addr_lenet_to_mem2),
		    .qa_src(data_lenet_from_mem2),
		    .digit(lenet_digit),
		    .ready(lenet_ready)
		);
		
		lenet_control ilenet_control(
		    .clk(clk100),
		    .lenet_ready(lenet_ready),
		    .data_ready(data_ready),
		    .lenet_go(lenet_go),
		    .rst_n(rst_n)
		);

endmodule // ov7670_top