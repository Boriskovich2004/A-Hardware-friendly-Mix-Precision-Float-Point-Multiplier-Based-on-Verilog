`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 15:20:58
// Design Name: 
// Module Name: float_mult
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


module float_mult(
    input clk,
    input rst_n,
    input data_type, // 0: fp16, 1: fp32
    input valid,
    input [31:0] in1_32, 
    input [31:0] in2_32,
    input [15:0] in1_16,
    input [15:0] in2_16,
    output reg [31:0] out_32,
    output reg [15:0] out_16,
    output reg ready, 
    output overflow,  // type1 underflow: less than the smallest number: fp32 0_00000000_00000000000000000000001, fp16 0_00000_00000001
                      //happens when exp1 + exp2 - exp_offset < 0
                      // type2 overflow: greater than the largest number: fp32 0_11111110_11111111111111111111111, fp16 0_11111110_1111111111
                      // happens when exp1 + exp2 - exp_offset > max exp
                      // both type1 and type2 show as exp_sum[highest] == 1
    output error,  // NaN input
    output [31:0] in1_disp,
    output [31:0] in2_disp
);
    reg start;
    reg valid_q;
    reg [15:0]in1_16_reg;
    reg [15:0]in2_16_reg;
    reg [31:0]in1_32_reg;
    reg [31:0]in2_32_reg;
    reg [8:0] exp_out;
    reg exp_complete;

    wire is_zero   = (data_type == 1'b1 && ((in1_32_reg[30:0] == 31'h0)        || (in2_32_reg[30:0] == 31'h0))) || 
                     (data_type == 1'b0 && ((in1_16_reg[14:0] == 15'h0)        || (in2_16_reg[14:0] == 15'h0)));
    wire is_inf    = (data_type == 1'b1 && ((in1_32_reg[30:0] == 31'h7f800000) || (in2_32_reg[30:0] == 31'h7f800000))) || 
                     (data_type == 1'b0 && ((in1_16_reg[14:0] == 15'h7c00)     || (in2_16_reg[14:0] == 15'h7c00)));

    wire is_nan    = (data_type == 1'b1 && ((in1_32_reg[30:23] == 8'hff && in1_32_reg[22:0] != 23'h0) || (in2_32_reg[30:23] == 8'hff && in2_32_reg[22:0] != 23'h0))) || 
                     (data_type == 1'b0 && ((in1_16_reg[14:10] == 5'h1f && in1_16_reg[9:0]  != 10'h0) || (in2_16_reg[14:10] == 5'h1f && in2_16_reg[9:0]  != 10'h0)));
    wire is_denorm_1 = (data_type == 1'b1 && (in1_32_reg[30:23] == 8'h00 && in1_32_reg[22:0] != 23'h0)) || 
                       (data_type == 1'b0 && (in1_16_reg[14:10] == 5'h00 && in1_16_reg[9:0]  != 10'h0));
    wire is_denorm_2 = (data_type == 1'b1 && (in2_32_reg[30:23] == 8'h00 && in2_32_reg[22:0] != 23'h0)) ||
                       (data_type == 1'b0 && (in2_16_reg[14:10] == 5'h00 && in2_16_reg[9:0]  != 10'h0));
    wire is_denorm = is_denorm_1 || is_denorm_2;

    wire sign1 = data_type ? in1_32_reg[31] : in1_16_reg[15];
    wire sign2 = data_type ? in2_32_reg[31] : in2_16_reg[15];
    wire [7:0] exp1 = data_type ? in1_32_reg[30:23] : {3'b0, in1_16_reg[14:10]};
    wire [7:0] exp2 = data_type ? in2_32_reg[30:23] : {3'b0, in2_16_reg[14:10]};
    wire [23:0] mant1 = data_type ?  // Add the implicit 1 if not denorm
                            (is_denorm_1 ? 
                                {1'b0, in1_32_reg[22:0]} : {1'b1, in1_32_reg[22:0]}) 
                          : (is_denorm_1 ? 
                                {14'b0000_0000_0000_00, in1_16_reg[9:0]} : {14'b0000_0000_0000_01, in1_16_reg[9:0]});

    wire [23:0] mant2 = data_type ?  // Add the implicit 1 if not denorm
                            (is_denorm_2 ? 
                                {1'b0, in2_32_reg[22:0]} : {1'b1, in2_32_reg[22:0]}) 
                          : (is_denorm_2 ? 
                                {14'b0000_0000_0000_00, in2_16_reg[9:0]} : {14'b0000_0000_0000_01, in2_16_reg[9:0]});
                         
    wire [8:0] exp_sum;
    wire [8:0] exp_offset;
    wire sign_out;
    wire [22:0] mant_out;
    wire normalize;
    wire more_than_1; // mantissa product more than 1
    wire denorm_dormalize; // when more_than_1 and exp_sum == 0(denorm -126) and norm*denorm
    wire mult_ready;

    assign in1_disp = in1_32;
    assign in2_disp = in2_32;
    assign sign_out = sign1 ^ sign2;
    assign exp_offset = data_type ? 8'h7f : 8'h0f; // fp32 exp offset is 127, fp16 exp offset is 15
    assign overflow = data_type ? exp_out[8] : exp_out[5];
    assign error = is_nan;
    assign denorm_dormalize = more_than_1 && (data_type ? exp_sum == 9'b001111111 : exp_sum == 9'b000001111) && (is_denorm_1 ^ is_denorm_2);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            valid_q <= 1'b0;
        else
            valid_q <= valid;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            exp_complete <= 1'b0;
        else if(normalize || denorm_dormalize)
            exp_complete <= 1'b1;
        else if(valid) //wait for the next input, then change exp_out
            exp_complete <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            ready <= 1'b1;
        else if(mult_ready || is_zero || is_inf || is_nan) // skip the multiplication
            ready <= 1'b1;
        else
            ready <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            start <= 1'b0;
        else if(valid_q && ready && !is_inf && !is_nan && !is_zero)
            start <= 1'b1;
        else                                               // skip the multiplication if not necessary
            start <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in1_16_reg <= 16'h0;
            in2_16_reg <= 16'h0;
            in1_32_reg <= 32'h0;
            in2_32_reg <= 32'h0;
        end
        else if(valid && ready) begin
            in1_16_reg <= in1_16;
            in2_16_reg <= in2_16;
            in1_32_reg <= in1_32;
            in2_32_reg <= in2_32;
        end
        else begin
            in1_16_reg <= in1_16_reg;
            in2_16_reg <= in2_16_reg;
            in1_32_reg <= in1_32_reg;
            in2_32_reg <= in2_32_reg;
        end
    end

    always @(*) begin  // 32-bit output
        if(!rst_n)
        begin
            out_32 <= 32'h0;
        end
        if(data_type)
        begin
            if(is_zero)
            begin
                out_32 <= 32'h0;
            end
            else if(is_inf)
            begin
                out_32 <= 32'h7f800000;
            end
            else if(is_nan)
            begin
                out_32 <= 32'h7fffffff;
            end
            else 
            begin
                out_32 <= {sign_out, exp_out[7:0], mant_out};
            end
        end
        else // 16-bit
        begin
            out_32 <= 32'h0;
        end
    end
 
    always @(*) begin  // 16-bit output
        if(!rst_n)
        begin
            out_16 <= 16'h0;
        end
        if(!data_type)
        begin
            if(is_zero)
            begin
                out_16 <= 16'h0;
            end
            else if(is_inf)
            begin
                out_16 <= 16'h7c00;
            end
            else if(is_nan)
            begin
                out_16 <= 16'h7fff;
            end
            else 
            begin
                out_16 <= {sign_out, exp_out[4:0], mant_out[9:0]};
            end
        end
        else // 32-bit
        begin
            out_16 <= 16'h0;
        end
    end

    // 1. Calculate the exponent
    add8 add8_exp(
        .in1(exp1),
        .in2(exp2),
        .sum(exp_sum)
    );

    // 2. Calculate the mantissa
    mult24 mult_mant(
        .clk(clk),
        .rst_n(rst_n),
        .valid(start),
        .mode(data_type),
        .in1(mant1), // Add the implicit 1
        .in2(mant2), // Add the implicit 1
        .product(mant_out),
        .normalize(normalize), // the result is normalized
        .more_than_1(more_than_1), // the result is denorm normalized
        .ready(mult_ready)
    );

    // 3. Normalization
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            exp_out <= 1'b0;
        else
        if(!exp_complete)
            if(normalize)
                exp_out <= exp_sum - exp_offset + 1'b1;
            else if(denorm_dormalize) // 
                exp_out <= 9'b1;
            else 
                exp_out <= exp_sum - exp_offset;
        else 
            exp_out <= exp_out;
    end

endmodule