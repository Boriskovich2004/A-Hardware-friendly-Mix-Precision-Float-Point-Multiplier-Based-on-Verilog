`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 16:10:01
// Design Name: 
// Module Name: add8
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


module add8(
        input [7:0] in1,  // 8-bit input 1
        input [7:0] in2,  // 8-bit input 2
        output [8:0] sum  // 9-bit sum
    );
    assign sum = in1 + in2;
endmodule
