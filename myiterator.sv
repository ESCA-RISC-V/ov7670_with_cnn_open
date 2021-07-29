`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/23 18:49:24
// Design Name: 
// Module Name: iterator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module myiterator #(
    parameter F_SIZE = 5,
    parameter STEP = 1,
    parameter I_SIZE = 32,
    parameter CHANNEL = 1,
    parameter FILTERS = 6,
    localparam D_F_SIZE = $clog2(F_SIZE*F_SIZE+1),
    localparam D_I_SIZE = $clog2(I_SIZE*I_SIZE+1),
    localparam D_IC_SIZE = $clog2(CHANNEL+1),
    localparam D_OC_SIZE = $clog2(FILTERS+1),
    localparam START_DELAY = 3 + F_SIZE * F_SIZE * CHANNEL + FILTERS + 1 - 1,
    localparam TOTAL_DELAY = 3 + ((I_SIZE-F_SIZE)/STEP + 1) ** 2 + F_SIZE * F_SIZE * CHANNEL + FILTERS + 1 - 1,
    localparam DC_SIZE = $clog2(TOTAL_DELAY+1),
    localparam FC_SIZE = $clog2(F_SIZE * F_SIZE * CHANNEL * FILTERS + 1)
    )(
    input clk,    // Clock
    input clk_en, // Clock Enable
    input rst_n,  // Asynchronous reset active low
    input going,
    output logic [D_OC_SIZE-1:0] aa_bias,                           // done
    output logic [$clog2(I_SIZE+1)-1:0] aa_data_x,
    output logic [$clog2(I_SIZE+1)-1:0] aa_data_y,
    output logic [D_F_SIZE-1:0] aa_filter_f,                        // done
    output logic [D_IC_SIZE-1:0] aa_filter_ic,                      // done
    output logic [D_OC_SIZE-1:0] aa_filter_oc,                      // done
    output logic [F_SIZE*F_SIZE*CHANNEL*FILTERS-1:0] filter_we,            // done
    output logic [FILTERS-1:0]bias_we,
    output logic cena,
    output logic cenb,
    output logic filter_ready,
    output logic bias_ready,
    output logic ready
);
    logic [FC_SIZE-1:0] filter_counter;
    logic [DC_SIZE-1:0] delay_counter;
    logic filter_ready_t;
    logic [F_SIZE*F_SIZE*CHANNEL*FILTERS-1:0]filter_we_t;
    logic activate, ending;
    logic bias_ready_t;
    logic go;
    //assign ready = filter_ready && input_ready && bias_ready;
    assign ending = delay_counter == TOTAL_DELAY;
    assign ready = ending;
    assign go = going && bias_ready && filter_ready;


    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_counter
        if(~rst_n) begin
            filter_counter <= 0;
        end else if(clk_en) begin
            if (filter_counter < F_SIZE * F_SIZE * CHANNEL * FILTERS) begin
                filter_counter <= filter_counter + 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_aa_filter_f
        if(~rst_n) begin
            aa_filter_f <= 0;
        end else if(clk_en) begin
            if (filter_counter < F_SIZE * F_SIZE * CHANNEL * FILTERS) begin
                aa_filter_f <= filter_counter / (CHANNEL * FILTERS);
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_aa_filter_ic
        if(~rst_n) begin
            aa_filter_ic <= 0;
        end else if(clk_en) begin
            if (filter_counter < F_SIZE * F_SIZE * CHANNEL * FILTERS) begin
                aa_filter_ic <= (filter_counter % (CHANNEL * FILTERS)) / FILTERS;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_aa_filter_oc
        if(~rst_n) begin
            aa_filter_oc <= 0;
        end else if(clk_en) begin
            if (filter_counter < F_SIZE * F_SIZE * CHANNEL * FILTERS) begin
                aa_filter_oc <= filter_counter % FILTERS;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_aa_bias
        if(~rst_n) begin
            aa_bias <= 0;
        end else if(clk_en) begin
            if (aa_bias < FILTERS - 1) begin
                aa_bias <= aa_bias + 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_bias_we
        if(~rst_n) begin
            bias_we <= 0;
        end else if(clk_en) begin
            if (aa_bias == 0) begin
                bias_we <= 1;
            end else begin
                bias_we <= {bias_we[FILTERS-2:0], 1'b0};
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin : proc_bias_ready
        if(~rst_n) begin
            bias_ready <= 0;
        end else if(clk_en) begin
            bias_ready <= bias_ready_t;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_bias_ready_t
        if(~rst_n) begin
            bias_ready_t <= 0;
        end else if(clk_en) begin
            if (aa_bias == FILTERS - 1) begin
                bias_ready_t <= 1;
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_we
        if(~rst_n) begin
            filter_we <= 0;
        end else if(clk_en) begin
            filter_we <= filter_we_t;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_we_t
        if(~rst_n) begin
            filter_we_t <= 0;
        end else if(clk_en) begin
            if (filter_counter == 0) begin
                filter_we_t <= 1;
            end else begin
                filter_we_t <= {filter_we_t[F_SIZE*F_SIZE*CHANNEL*FILTERS-2:0], 1'b0};
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_ready
        if(~rst_n) begin
            filter_ready <= 0;
        end else if(clk_en) begin
            filter_ready <= filter_ready_t;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_filter_ready_t
        if(~rst_n) begin
            filter_ready_t <= 0;
        end else if(clk_en) begin
            if (filter_counter == F_SIZE * F_SIZE * CHANNEL * FILTERS) begin
                filter_ready_t <= 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_activate
        if(~rst_n) begin
            activate <= 0;
        end else if(clk_en) begin
            if (go) begin
                activate <= 1;
            end else if (ending) begin
                activate <= 0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_delay_counter
        if(~rst_n) begin
            delay_counter <= 0;
        end else if(clk_en) begin
            if (ending) begin
                delay_counter <= 0;
            end else if (activate) begin
                delay_counter <= delay_counter + 1;            
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin : proc_cenb
        if(~rst_n) begin
            cenb <= 1;
        end else if(clk_en) begin
            if (delay_counter == START_DELAY) begin
                cenb <= 0;
            end else if (ending) begin
                cenb <= 1;
            end
        end
    end

    logic [$clog2(I_SIZE)-1:0] vcounter;
    logic [$clog2(I_SIZE)-1:0] hcounter;

    always_ff @(posedge clk or negedge rst_n) begin : proc_vhcounters
        if(~rst_n) begin
            vcounter <= 0;
            hcounter <= 0;
        end else if(clk_en) begin
            if (go) begin
                vcounter <= 0;
                hcounter <= 0;
            end else if (~cena && hcounter < I_SIZE - F_SIZE + 1 - STEP || vcounter < I_SIZE - F_SIZE + 1 - STEP) begin
                if (vcounter >= I_SIZE - F_SIZE + 1 - STEP) begin
                    vcounter <= 0;
                    hcounter <= hcounter + STEP;
                end else begin
                    vcounter <= vcounter + STEP;
                end
            end
        end
    end

    assign aa_data_x = vcounter;
    assign aa_data_y = hcounter;

    always_ff @(posedge clk or negedge rst_n) begin : proc_cena
        if(~rst_n) begin
            cena <= 1;
        end else if(clk_en) begin
            if (go) begin
                cena <= 0;
            end else if (hcounter >= I_SIZE - F_SIZE + 1 - STEP && vcounter >= I_SIZE - F_SIZE + 1 - STEP) begin
                cena <= 1;
            end
        end
    end


endmodule : myiterator