`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 16:05:54
// Design Name: 
// Module Name: mult8
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


module mult8 (
    input [7:0] in1,  // 8-bit multiplicand
    input [7:0] in2,  // 8-bit multiplier
    output reg [15:0] product  // 16-bit product
);

    integer i;
    always @(*) begin
        product = 16'b0;  // Initialize product to 0
        for (i = 0; i < 8; i = i + 1) begin
            if (in2[i]) begin
                product = product + (in1 << i);  // Shift and add
            end
        end
    end

endmodule
