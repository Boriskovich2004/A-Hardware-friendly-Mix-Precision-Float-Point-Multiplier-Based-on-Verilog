`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 16:44:25
// Design Name: 
// Module Name: mult23
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


module mult24 (
    input clk,
    input rst_n,
    input valid,  // Start calculation flag
    input mode,  //0: fp16, 11-bit;  1: fp32, 24-bit
    input [23:0] in1,  // 23-bit input 1
    input [23:0] in2,  // 23-bit input 2
    output reg [22:0] product,  // 23-bit product
    output reg normalize,  // normalize flag
    output reg more_than_1,  // denorm normalize flag
    output reg ready  // Done flag
);

    // Internal signals
    reg [2:0] state;  // State machine
    reg [23:0] in1_reg; // Register for input 1
    reg [23:0] in2_reg; // Register for input 2 
    reg [47:0] temp_product;  // Accumulator for partial products
    reg [7:0] in1_segment, in2_segment;  // 8-bit segments
    reg [5:0] shift_amount;  // Shift amount for partial products
    reg [3:0] mult8_cnt;  // Counter for 8-bit multiplier
    reg [3:0] mult_end;  // End of partial products

    wire [15:0] mult8_result;  // Result from 8-bit multiplier

    // segmenting the 24-bit inputs
    wire [7:0] a1 = in1_reg[23:16];
    wire [7:0] b1 = in1_reg[15:8];
    wire [7:0] c1 = in1_reg[7:0];
    wire [7:0] a2 = in2_reg[23:16];
    wire [7:0] b2 = in2_reg[15:8];
    wire [7:0] c2 = in2_reg[7:0];

    // 8-bit multiplier instance
    mult8 mult8_inst (
        .in1(in1_segment),
        .in2(in2_segment),
        .product(mult8_result)
    );

    // State machine
    localparam IDLE = 3'b000;
    localparam CALC = 3'b001;
    localparam ACCU = 3'b010;
    localparam NORM = 3'b011;
    localparam DONE = 3'b100;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in1_reg <= 24'b0;
            in2_reg <= 24'b0;
        end
        else if(valid) begin
            in1_reg <= in1;
            in2_reg <= in2;
        end
        else begin
            in1_reg <= in1_reg;
            in2_reg <= in2_reg;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mult_end <= 4'h0;
        end
        else if(mode) begin // 24-bit mode, 9 partial products
            mult_end <= 4'h9;
        end
        else begin          // 16-bit mode, 4 partial products
            mult_end <= 4'h4;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            temp_product <= 46'b0;
            shift_amount <=6'h0;
            mult8_cnt <= 4'h0;
            in1_segment <= 8'b0;
            in2_segment <= 8'b0;
            product <= 23'b0;
            ready <= 1'b1;
            normalize <= 1'b0;
            more_than_1 <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    // Initialize registers
                    temp_product <= 46'b0;
                    shift_amount <= 6'h0;
                    mult8_cnt <= 4'h0;
                    normalize <= 1'b0;
                    more_than_1 <= 1'b0;
                    if(valid)begin
                        ready <= 1'b0; // busy
                        state <= CALC;
                    end
                    else begin
                        ready <= 1'b1;
                        state <= IDLE;
                    end
                end

                CALC: begin
                    if(mult8_cnt < mult_end) begin
                        // Calculate partial products
                        case (mult8_cnt)
                            4'h0: begin // c1 * c2, shift = 0
                                in1_segment <= c1;
                                in2_segment <= c2;
                                shift_amount <= 6'h0;
                            end
                            4'h1: begin // b1 * c2, shift = 8
                                in1_segment <= b1;
                                in2_segment <= c2;
                                shift_amount <= 6'h8;
                            end
                            4'h2: begin // c1 * b2, shift = 8
                                in1_segment <= c1;
                                in2_segment <= b2;
                                shift_amount <= 6'h8;
                            end
                            4'h3: begin // b1 * b2, shift = 16
                                in1_segment <= b1;
                                in2_segment <= b2;
                                shift_amount <= 6'h10;
                            end
                            4'h4: begin // a1 * c2, shift = 16
                                in1_segment <= a1;
                                in2_segment <= c2;
                                shift_amount <= 6'h10;
                            end 
                            4'h5: begin // c1 * a2, shift = 16
                                in1_segment <= c1;
                                in2_segment <= a2;
                                shift_amount <= 6'h10;
                            end
                            4'h6: begin // a1 * b2, shift = 24
                                in1_segment <= a1;
                                in2_segment <= b2;
                                shift_amount <= 6'h18;
                            end
                            4'h7: begin // b1 * a2, shift = 24
                                in1_segment <= b1;
                                in2_segment <= a2;
                                shift_amount <= 6'h18;
                            end
                            4'h8: begin // a1 * a2, shift = 32
                                in1_segment <= a1;
                                in2_segment <= a2;
                                shift_amount <= 6'h20;
                            end
                            default:begin
                                in1_segment <= 8'b0;
                                in2_segment <= 8'b0;
                                shift_amount <= 6'h0;
                            end
                        endcase
                        //turn to accumulate state
                        state <= ACCU;
                        mult8_cnt <= mult8_cnt + 1;
                    end else begin
                        state <= NORM;
                    end
                    
                end

                ACCU: begin
                    // Accumulate partial product with shift
                    temp_product <= temp_product + (mult8_result << shift_amount);
                    if(mult8_cnt > 4'h8) begin
                        state <= NORM;
                    end
                    else begin
                        state <= CALC;
                    end
                end

                NORM: begin
                    // Normalize the result
                    if (mode ? temp_product[47] : temp_product[21]) begin
                        temp_product <= temp_product >> 1;  // Right shift to normalize
                        normalize <= 1'b1;
                    end
                    else begin
                        temp_product <= temp_product;
                        normalize <= 1'b0;
                    end
                    // Check if the result is less than 1, needs turing to denorm number when the exponent is 1(-126)
                    if (mode ? temp_product[46] : temp_product[20]) begin
                        more_than_1 <= 1'b1;
                    end
                    else begin
                        more_than_1 <= 1'b0;
                    end
                    state <= DONE;  
                end

                DONE: begin
                    product <= mode ? temp_product[45:23] : {13'b0, temp_product[19:10]};  // Take high 23 bits as result
                    // Set done flag
                    ready <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule