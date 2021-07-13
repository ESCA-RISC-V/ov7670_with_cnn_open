module i2c_sender (
                    input   logic       clk,
                    output  logic       siod,
                    output  logic       sioc,
                    output  logic       taken,
                    input   logic       send,
                    input   logic[7:0]  id,
                    input   logic[7:0]  regi,
                    input   logic[7:0]  value,
                    input   logic       rst_n
                   );

    logic[7:0]  divider;
    logic[31:0] busy_sr;
    logic[31:0] data_sr;
    logic       clklow;
    logic       cntmax ='d64;   // constant
    logic[5:0]  counter;
    

    always_comb begin : proc_as
        if (busy_sr[11:10] == 2'b10 || busy_sr[20:19] == 2'b10 || busy_sr[29:28] == 2'b10) begin
            siod = 1'b0;
        end else begin
            siod = data_sr[31];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : proc_clk
        if (~rst_n) begin
            clklow <= '0;
            counter <= '0;
        end else begin
            if (counter == cntmax - 1) begin
                clklow <= ~clklow;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always_ff @(posedge clklow or negedge rst_n) begin : proc_clklow
        if (~rst_n) begin
            divider <= 8'b1;
            busy_sr <= 0;
            data_sr <= 0;
            taken <= '0;
            sioc <= 1'b1;
        end else begin    
            if (busy_sr[31]==1'b0) begin
                sioc <= 1'b1;
                if (send == 1'b1) begin
                    if (divider == 8'b00000000) begin
                        data_sr <= {3'b100, id, 1'b0, regi, 1'b0, value, 1'b0, 2'b00};
                        busy_sr <= 32'hFFFF;
                        taken <= 1'b1;
                    end else begin
                        divider <= divider + 1;
                    end
                end
            end else begin
                case ({busy_sr[31:29], busy_sr[2:0]})
                    6'b111111:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b1;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b1;
                        endcase
                    6'b111110:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b1;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b1;
                        endcase
                    6'b111100:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b0;
                            2'b01   : sioc <= 1'b0;
                            2'b10   : sioc <= 1'b0;
                            default : sioc <= 1'b0;
                        endcase
                    6'b110000:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b0;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b1;
                        endcase
                    6'b100000:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b1;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b1;
                        endcase
                    6'b000000:
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b1;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b1;
                        endcase
                    default : 
                        case (divider[7:6])
                            2'b00   : sioc <= 1'b0;
                            2'b01   : sioc <= 1'b1;
                            2'b10   : sioc <= 1'b1;
                            default : sioc <= 1'b0;
                        endcase
                endcase
    
                if (divider == 8'hFF) begin
                    busy_sr <= {busy_sr[30:0], 1'b0};
                    data_sr <= {data_sr[30:0], 1'b1};
                    divider <= '0;
                end else begin
                    divider <= divider + 1;
                end
            end
        end
    end
endmodule