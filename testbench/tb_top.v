`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/24 15:09:41
// Design Name: 
// Module Name: tb_top
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

module top_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg data_type;
    reg enter;
    reg ce;
    reg [3:0] in1_row;
    reg [3:0] in1_col;
    reg [3:0] in2_row;
    reg [3:0] in2_col;
    

    // Outputs
    wire [6:0] disp1_seg;
    wire [7:0] disp1_sel;
    wire [6:0] disp2_seg;
    wire [7:0] disp2_sel;
    wire [6:0] out_seg;
    wire [7:0] out_sel;
    // wire [31:0] input1;
    // wire [31:0] input2;
    // wire [5:0] input1_cnt;
    // wire [5:0] input2_cnt;
    wire ready;
    wire overflow;
    wire error;

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_type(data_type),
        .enter(enter),
        .ce(ce),
        .in1_row(in1_row),
        .in1_col(in1_col),
        .in2_row(in2_row),
        .in2_col(in2_col),
        .disp1_seg(disp1_seg),
        .disp1_sel(disp1_sel),
        .disp2_seg(disp2_seg),
        .disp2_sel(disp2_sel),
        .out_seg(out_seg),
        .out_sel(out_sel),
        // .input1(input1),
        // .input2(input2),
        // .input1_cnt(input1_cnt),
        // .input2_cnt(input2_cnt),
        .ready(ready),
        .overflow(overflow),
        .error(error)
    );

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst_n = 0;
        data_type = 0;
        enter = 0;
        ce = 0;
        in1_row = 4'b0;
        in1_col = 4'b0;
        in2_row = 4'b0;
        in2_col = 4'b0;

        // Reset system
        #20;
        rst_n = 1;
        #200;

        // Test FP16 mode
        // test case: 16'b0_01111_1001001100 * 16'b0_00000_1011010011
        //           =3E4C * 02D3 = 0472
        // test case: 16'b0_11111_1000000000 * 16'b0_10000_0000000000
        //           = 7E00 * 4000 = 7FFF
        // test case: 16'b0_00000_0001001100 * 16'b0_00000_1011010011
        //           = 004C * 02D3 = underflow
        enter = 1;
        #60;
        enter = 0;  
        data_type = 0;
        
        // Input 1
        // bit3 = 3
        in1_row = 4'b1000;
        in1_col = 4'b0010;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit2 = E
        in1_row = 4'b0001;
        in1_col = 4'b0010;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit3 = 4
        in1_row = 4'b1000;
        in1_col = 4'b0001;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit4 = C
        in1_row = 4'b0001;
        in1_col = 4'b1000;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;

        // Input 2
        // bit3 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit2 = 2
        in2_row = 4'b1000;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit1 = D
        in2_row = 4'b0001;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit0 = 3
        in2_row = 4'b1000;
        in2_col = 4'b0010;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;

        // Start calculation
        enter = 1;
        #20;
        enter = 0;

        // Wait for result
        wait(ready);
        #1000;

        // ce
        ce = 1;
        #20
        ce = 0;

        // test case: 16'b0_01111_1001001100 * 16'b0_00000_1011010011
        //           =3E4C * 02D3 = 0472
        // test case: 16'b0_11111_1000000000 * 16'b0_10000_0000000000
        //           = 7E00 * 4000 = 7FFF
        // test case: 16'b0_00000_0001001100 * 16'b0_00000_1011010011
        //           = 004C * 02D3 = underflow
        // Test FP32 mode
        // test case: 32'b0011_1111_1100_1001_1000_0000_0000_0000 * 32'b0000_0000_0101_1010_0110_0000_0000_0000
        //           =    3FC98000 * 005A6000 = 008E4520
        // test case: 32'b0_11111111_10000000000000000000000 * 32'b0_10000000_00000000000000000000000
        //           =    7FC00000 * 40000000 = 7FFFFFFF
        // test case: 32'b0_00000000_00000000000000000000001 * 32'b0_00000000_00000000000000000000010
        //           =    00000001 * 00000002 = underflow
        data_type = 1;
        
        // Input 1
        // bit7 = 3
        in1_row = 4'b1000;
        in1_col = 4'b0010;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit6 = F
        in1_row = 4'b0001;
        in1_col = 4'b0001;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit5 = C
        in1_row = 4'b0001;
        in1_col = 4'b1000;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit4 = 9
        in1_row = 4'b0010;
        in1_col = 4'b1000;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit3 = 8
        in1_row = 4'b0100;
        in1_col = 4'b0001;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit2 = 0
        in1_row = 4'b0010;
        in1_col = 4'b0100;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit1 = 0
        in1_row = 4'b0010;
        in1_col = 4'b0100;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        // bit0 = 0
        in1_row = 4'b0010;
        in1_col = 4'b0100;
        #60;
        in1_row = 4'b0;
        in1_col = 4'b0;
        #100;
        
        // Input 2
        // bit7 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit6 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit5 = 5
        in2_row = 4'b0100;
        in2_col = 4'b1000;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit4 = A
        in2_row = 4'b0010;
        in2_col = 4'b0010;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit3 = 6
        in2_row = 4'b0100;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit2 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit1 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;
        // bit0 = 0
        in2_row = 4'b0010;
        in2_col = 4'b0100;
        #60;
        in2_row = 4'b0;
        in2_col = 4'b0;
        #100;

        // Start calculation
        enter = 1;
        #20;
        enter = 0;

        // Wait for result
        wait(ready);
        #200;

        // Add more test cases here...

        $finish;
    end

endmodule
