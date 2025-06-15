`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/22 10:26:34
// Design Name: 
// Module Name: float_mult_tb
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

`timescale 1ns / 1ps

module tb_float_mult;

    // Inputs
    reg clk;
    reg rst_n;
    reg data_type;  // 0: fp16, 1: fp32
    reg valid;
    reg [31:0] in1_32;
    reg [31:0] in2_32;
    reg [15:0] in1_16;
    reg [15:0] in2_16;

    // Outputs
    wire [31:0] out_32;
    wire [15:0] out_16;
    wire ready;
    wire overflow;
    wire error;
    wire [31:0] in1_disp;
    wire [31:0] in2_disp;

    // Instantiate the Unit Under Test (UUT)
    float_mult uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_type(data_type),
        .valid(valid),
        .in1_32(in1_32),
        .in2_32(in2_32),
        .in1_16(in1_16),
        .in2_16(in2_16),
        .out_32(out_32),
        .out_16(out_16),
        .ready(ready),
        .overflow(overflow),
        .error(error),
        .in1_disp(in1_disp),
        .in2_disp(in2_disp)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test procedure
    initial begin
        // Initialize inputs
        rst_n = 0;
        valid = 0;
        data_type = 0;
        in1_32 = 0;
        in2_32 = 0;
        in1_16 = 0;
        in2_16 = 0;
        #20;  // Wait for reset

        // Release reset
        rst_n = 1;
        #100;

        // Test case 1: FP16 - Normal multiplication (negative)
        data_type = 0;  // FP16 mode
        in1_16 = 16'b1_01111_1000000000;  // -1.5
        in2_16 = 16'b1_10000_1100000000;  // -3.5
        valid = 1;
        #10;
        valid = 0;
        #200;  // Wait for calculation
        $display("Test case 1):\t in1 = %b, in2 = %b, out_16 = %b(ref: 0100010101000000), overflow = %b, error = %b (FP16 Normal multiplication (negative)",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 2: FP16 - Zero multiplication
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_00000_0000000000;  // 0.0
        in2_16 = 16'b0_10000_0000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 2:\t in1 = %b, in2 = %b, out_16 = %b(ref: 0000000000000000), overflow = %b, error = %b (FP16 Zero multiplication)",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 3: FP16 - Infinity multiplication
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_11111_0000000000;  // Infinity
        in2_16 = 16'b0_10000_0000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 3:\t in1 = %b, in2 = %b, out_16 = %b(ref: 0111110000000000), overflow = %b, error = %b (FP16 Infinity multiplication)",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 4: FP16 - NaN multiplication
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_11111_1000000000;  // NaN
        in2_16 = 16'b0_10000_0000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 4:\t in1 = %b, in2 = %b, out_16 = %b(ref: 0111111111111111), overflow = %b, error = %b (FP16 NaN multiplication)",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 5: FP16 - Random multiplication
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_01001_0001001100;  // 0.01678466796875
        in2_16 = 16'b0_11011_1011010011;  // 6982.03125
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 5:\t in1 = %b, in2 = %b, out_16 = %b(ref: 0101011101010100), overflow = %b, error = %b (FP16 Random multiplication)",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 6: FP16 - Random multiplication (denorm number underflow)
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_00000_0001001100;  // 4.5299530029296875 × 10⁻⁶
        in2_16 = 16'b0_00000_1011010011;  // 4.291534423828125 × 10⁻⁵
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 6:\t in1 = %b, in2 = %b, out_16 = %b(ref: ***underflow****), overflow = %b, error = %b (FP16 Random multiplication (denorm number underflow))",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 7: FP16 - Random multiplication (denorm number normalize)
        data_type = 0;  // FP16 mode
        in1_16 = 16'b0_01111_1001001100;  // 1.57421875
        in2_16 = 16'b0_00000_1011010011;  // 0.7060546875 × 2^-14 = 1.111484527587891 × 2^-14
        valid = 1;
        #10;
        valid = 0;
        #200;
        $display("Test case 7:\t in1 = %b, in2 = %b, out_16 = %b(ref: 0000010001110010), overflow = %b, error = %b (FP16 Random multiplication (denorm number normalize))",
                 in1_16, in2_16, out_16, overflow, error);

        // Test case 8: FP32 - Normal multiplication (negative)
        data_type = 1;  // FP32 mode
        in1_32 = 32'b1_01111111_10000000000000000000000;  // -1.5
        in2_32 = 32'b1_10000000_11000000000000000000000;  // -3.5
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 8:\t in1 = %b, in2 = %b, out_32 = %b(ref: 01000000001010000000000000000000), overflow = %b, error = %b (FP32 Normal multiplication (negative))",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 9: FP32 - Zero multiplication
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_00000000_00000000000000000000000;  // 0.0
        in2_32 = 32'b0_10000000_00000000000000000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 9:\t in1 = %b, in2 = %b, out_32 = %b(ref: 00000000000000000000000000000000), overflow = %b, error = %b (FP32 Zero multiplication)",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 10: FP32 - Infinity multiplication
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_11111111_00000000000000000000000;  // Infinity
        in2_32 = 32'b0_10000000_00000000000000000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 10:\t in1 = %b, in2 = %b, out_32 = %b(ref: 01111111100000000000000000000000), overflow = %b, error = %b (FP32 Infinity multiplication)",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 11: FP32 - NaN multiplication
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_11111111_10000000000000000000000;  // NaN
        in2_32 = 32'b0_10000000_00000000000000000000000;  // 2.0
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 11:\t in1 = %b, in2 = %b, out_32 = %b(ref: 01111111111111111111111111111111), overflow = %b, error = %b (FP32 NaN multiplication)",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 12: FP32 - Random multiplication
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_01111100_00000000000000000000000;  // 0.125
        in2_32 = 32'b0_10000101_00000000000000000000000;  // 128.0
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 12:\t in1 = %b, in2 = %b, out_32 = %b(ref: 01000001000000000000000000000000), overflow = %b, error = %b (FP32 Random multiplication)",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 13: FP32 - Random multiplication (denorm number underflow)
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_00000000_00000000000000000000001;  // 1.401298464324817 × 10⁻⁴⁵
        in2_32 = 32'b0_00000000_00000000000000000000010;  // 2.802596928649634 × 10⁻⁴⁵
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 13:\t in1 = %b, in2 = %b, out_32 = %b(ref: ***********underflow************), overflow = %b, error = %b (FP32 Random multiplication (denorm number underflow))",
                 in1_32, in2_32, out_32, overflow, error);

        // Test case 14: FP32 - Random multiplication (denorm number normalize)
        data_type = 1;  // FP32 mode
        in1_32 = 32'b0_01111111_10010011000000000000000;  // 1.57421875
        in2_32 = 32'b0_00000000_10110100110000000000000;  // 0.7060546875 × 2^-126 = 1.111484527587891 × 2^-126
        valid = 1;
        #10;
        valid = 0;
        #300;
        $display("Test case 14:\t in1 = %b, in2 = %b, out_32 = %b(ref: 00000000100011100100010100100000), overflow = %b, error = %b (FP32 Random multiplication (denorm number))",
                 in1_32, in2_32, out_32, overflow, error);

        // End simulation
        $stop;
    end

endmodule