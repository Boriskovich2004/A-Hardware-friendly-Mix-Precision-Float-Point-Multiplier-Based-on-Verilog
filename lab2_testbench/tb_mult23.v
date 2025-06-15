`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 08:37:06
// Design Name: 
// Module Name: tb_mult23
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

module tb_mult23;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [22:0] in1;
    reg [22:0] in2;

    // Outputs
    wire [22:0] product;
    wire normalize;
    wire ready;

    mult24 uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid(start),
        .in1({1'b1, in1}),
        .in2({1'b1, in2}),
        .product(product),
        .normalize(normalize),
        .ready(ready)
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
        in1 = 0;
        in2 = 0;
        #20;  // Wait for reset

        // Release reset
        rst_n = 1;
        #10;

        
        // Test case 1: Normal multiplication (no normalize)
        start = 1; // Start calculation
        in1 = 23'b010_0000_0000_0000_0000_0000;  // 1 + 0.25
        in2 = 23'b100_0000_0000_0000_0000_0000;  // 1 + 0.5
        // result = 111 0000 0000 0000 0000 0000 = 1 + 0.875
        #10
        start = 0;
        #300;  // Wait for calculation
        $display("Test case 1: in1 = %b, in2 = %b, product = %b, normalize = %b, ready = %b",
                 in1, in2, product, normalize, ready);

        // Test case 2: Normal multiplication (result in [2, 4))
        start = 1; // Start calculation
        in1 = 23'b110_0000_0000_0000_0000_0000;  // 1 + 0.75
        in2 = 23'b110_0000_0000_0000_0000_0000;  // 1 + 0.75
        // result = 100 0100 0000 0000 0000 0000 = 2 * (1 + 0.53125)
        #10
        start = 0;
        #300;
        $display("Test case 2: in1 = %b, in2 = %b, product = %b, normalize = %b, ready = %b",
                 in1, in2, product, normalize, ready);

        // Test case 3: max case
        start = 1; // Start calculation
        in1 = 23'b111_1111_1111_1111_1111_1111;  // Maximum value 1 + 0.999 999 880 790 71
        in2 = 23'b111_1111_1111_1111_1111_1111;  // Maximum value 1 + 0.999 999 880 790 71
        // result = 111 1111 1111 1111 1111 1110 = 3.999 999 523 162 85 = 2 * (1 + 0.999 999 761 581 43)
        #10
        start = 0;
        #300;
        $display("Test case 3: in1 = %b, in2 = %b, product = %b, normalize = %b, ready = %b",
                 in1, in2, product, normalize, ready);

        // Test case 4: Zero case
        start = 1; // Start calculation
        in1 = 23'b000_0000_0000_0000_0000_0000;  // 1 + 0.0
        in2 = 23'b111_1111_1111_1111_1111_1111;  // Maximum value 1 + 0.999 999 880 790 71
        // result = 111 1111 1111 1111 1111 1111
        #10
        start = 0;
        #300;
        $display("Test case 4: in1 = %b, in2 = %b, product = %b, normalize = %b, ready = %b",
                 in1, in2, product, normalize, ready);

        // Test case 5: random case
        start = 1; // Start calculation
        in1 = 23'b001_1010_0100_0101_0101_0101;  // 1 + 0.20524084568024 9A4555
        in2 = 23'b101_0111_1101_0101_0110_1000;  // 1 + 0.68620014190674 D7D568
        // result = 000 0010 0001 0000 1101 0100 = 2 * (1 + 0.01613855361938)
        #10
        start = 0;
        #300;
        $display("Test case 5: in1 = %b, in2 = %b, product = %b, normalize = %b, ready = %b",
                 in1, in2, product, normalize, ready);

        // End simulation
        $stop;
    end

endmodule
