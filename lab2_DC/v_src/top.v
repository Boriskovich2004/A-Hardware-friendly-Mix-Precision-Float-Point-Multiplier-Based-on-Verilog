`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/22 17:07:24
// Design Name: 
// Module Name: top
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


module top(
    input clk,
    input rst_n,
    input data_type, // 0: fp16, 1: fp32
    input enter,
    input ce, // delete all
    // input1
    input [3:0] in1_row, in1_col,
    // input2
    input [3:0] in2_row, in2_col,
    // input display
    output reg [6:0] disp1_seg,
    output reg [7:0] disp1_sel,
    output reg [6:0] disp2_seg,
    output reg [7:0] disp2_sel,
    // output
    output reg [6:0] out_seg,
    output reg [7:0] out_sel,
    // output reg [31:0] input1, input2, //debug
    // output reg [5:0] input1_cnt, input2_cnt, //debug
    output ready, 
    output overflow,
    output error
);
    reg [3:0] in1_row_reg;
    reg [3:0] in1_col_reg;
    reg [3:0] in2_row_reg;
    reg [3:0] in2_col_reg;
    reg [3:0] in1_row_q;
    reg [3:0] in1_col_q;
    reg [3:0] in2_row_q;
    reg [3:0] in2_col_q;
    reg [31:0] input1;
    reg [31:0] input2;
    reg [5:0] input1_cnt;
    reg [5:0] input2_cnt;
    reg [2:0] disp1_sel_cnt;
    reg [2:0] disp2_sel_cnt;
    reg [2:0] out_sel_cnt;
    reg [6:0] disp1_bit7, disp1_bit6, disp1_bit5, disp1_bit4, disp1_bit3, disp1_bit2, disp1_bit1, disp1_bit0;
    reg [6:0] disp2_bit7, disp2_bit6, disp2_bit5, disp2_bit4, disp2_bit3, disp2_bit2, disp2_bit1, disp2_bit0;
    reg [6:0] bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7;

    wire [31:0] in1_32;
    wire [31:0] in2_32;
    wire [15:0] in1_16;
    wire [15:0] in2_16;
    wire [31:0] out_32;
    wire [15:0] out_16;

    wire [31:0] in1_disp;
    wire [31:0] in2_disp;

    // input assign (reverse)
        assign in1_32[31:28] = input1[3:0];
        assign in1_32[27:24] = input1[7:4];
        assign in1_32[23:20] = input1[11:8];
        assign in1_32[19:16] = input1[15:12];
        assign in1_32[15:12] = input1[19:16];
        assign in1_32[11:8]  = input1[23:20];
        assign in1_32[7:4]   = input1[27:24];
        assign in1_32[3:0]   = input1[31:28];

        assign in2_32[31:28] = input2[3:0];
        assign in2_32[27:24] = input2[7:4];
        assign in2_32[23:20] = input2[11:8];
        assign in2_32[19:16] = input2[15:12];
        assign in2_32[15:12] = input2[19:16];
        assign in2_32[11:8]  = input2[23:20];
        assign in2_32[7:4]   = input2[27:24];
        assign in2_32[3:0]   = input2[31:28];

        assign in1_16[15:12] = input1[3:0];
        assign in1_16[11:8]  = input1[7:4];
        assign in1_16[7:4]   = input1[11:8];
        assign in1_16[3:0]   = input1[15:12];

        assign in2_16[15:12] = input2[3:0];
        assign in2_16[11:8]  = input2[7:4];
        assign in2_16[7:4]   = input2[11:8];
        assign in2_16[3:0]   = input2[15:12];

    always @(posedge clk or negedge rst_n) begin // input_q
        if(!rst_n) begin
            in1_row_q <= 4'b0;
            in1_col_q <= 4'b0;
            in2_row_q <= 4'b0;
            in2_col_q <= 4'b0;
        end
        else begin
            in1_row_q <= in1_row;
            in1_col_q <= in1_col;
            in2_row_q <= in2_row;
            in2_col_q <= in2_col;
        end
    end
    always @(posedge clk or negedge rst_n) begin // in1_row_reg button debounce
        if(!rst_n)
            in1_row_reg <= 4'h0;
        else if(in1_row != 4'b0 && in1_row_q == 4'b0)
            in1_row_reg <= in1_row;
        else
            in1_row_reg <= 4'b0;
    end
    always @(posedge clk or negedge rst_n) begin // in1_col_reg button debounce
        if(!rst_n)
            in1_col_reg <= 4'h0;
        else if(in1_col != 4'b0 && in1_col_q == 4'b0)
            in1_col_reg <= in1_col;
        else
            in1_col_reg <= 4'b0;
    end
    always @(posedge clk or negedge rst_n) begin // in2_row_reg button debounce
        if(!rst_n)
            in2_row_reg <= 4'h0;
        else if(in2_row != 4'b0 && in2_row_q == 4'b0)
            in2_row_reg <= in2_row;
        else
            in2_row_reg <= 4'b0;
    end
    always @(posedge clk or negedge rst_n) begin // in2_col_reg button debounce
        if(!rst_n)
            in2_col_reg <= 4'h0;
        else if(in2_col != 4'b0 && in2_col_q == 4'b0)
            in2_col_reg <= in2_col;
        else
            in2_col_reg <= 4'b0;
    end 

    // input1 cnt
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            input1_cnt <= 6'h0;
        else if(!enter) begin // if a button is pressed and calculation is not started
            if(in1_row_reg != 4'b0 && in1_col_reg != 4'b0)
                if(data_type ? input1_cnt < 6'h8 : input1_cnt < 6'h4) // cnt from 0-7(fp32) or 0-3(fp16)
                    input1_cnt <= input1_cnt + 1;
                else input1_cnt <= input1_cnt;
            else
                input1_cnt <= input1_cnt;
        end
        else // if calculation is started, reset cnt
            input1_cnt <= 6'h0;
    end
    // input2 cnt
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            input2_cnt <= 6'h0;
        else if(!enter) begin // if a button is pressed and calculation is not started
            if(in2_row_reg != 4'b0 && in2_col_reg != 4'b0)
                if(data_type ? input2_cnt < 6'h8 : input2_cnt < 6'h4) // cnt from 0-7(fp32) or 0-3(fp16)
                    input2_cnt <= input2_cnt + 1;
                else input2_cnt <= input2_cnt;
            else
                input2_cnt <= input2_cnt;
        end
        else // if calculation is started, reset cnt
            input2_cnt <= 6'h0;
    end

         // col3 col2 col1 col0
    // row3 1    2    3    4
    // row2 5    6    7    8
    // row1 9    0    A    B
    // row0 C    D    E    F
    
    // input1
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input1 <= 32'h0;
        end
        else if(in1_row_reg != 4'b0 && in1_col_reg != 4'b0 && (data_type ? input1_cnt < 32'h8 : input1_cnt < 32'h4)) begin
            case({in1_row_reg, in1_col_reg})
                8'b10001000: input1  <= input1 | 32'h0000_0001 << (input1_cnt << 2);
                8'b10000100: input1  <= input1 | 32'h0000_0002 << (input1_cnt << 2);
                8'b10000010: input1  <= input1 | 32'h0000_0003 << (input1_cnt << 2);
                8'b10000001: input1  <= input1 | 32'h0000_0004 << (input1_cnt << 2);
                8'b01001000: input1  <= input1 | 32'h0000_0005 << (input1_cnt << 2);
                8'b01000100: input1  <= input1 | 32'h0000_0006 << (input1_cnt << 2);
                8'b01000010: input1  <= input1 | 32'h0000_0007 << (input1_cnt << 2);
                8'b01000001: input1  <= input1 | 32'h0000_0008 << (input1_cnt << 2);
                8'b00101000: input1  <= input1 | 32'h0000_0009 << (input1_cnt << 2);
                8'b00100100: input1  <= input1 | 32'h0000_0000 << (input1_cnt << 2);
                8'b00100010: input1  <= input1 | 32'h0000_000A << (input1_cnt << 2);
                8'b00100001: input1  <= input1 | 32'h0000_000B << (input1_cnt << 2);
                8'b00011000: input1  <= input1 | 32'h0000_000C << (input1_cnt << 2);
                8'b00010100: input1  <= input1 | 32'h0000_000D << (input1_cnt << 2);
                8'b00010010: input1  <= input1 | 32'h0000_000E << (input1_cnt << 2);
                8'b00010001: input1  <= input1 | 32'h0000_000F << (input1_cnt << 2);
                default: input1 <= input1;
            endcase
        end
        else if(ce) begin // if start calculation, reset in1
            input1 <= 32'h0;
        end
        else begin
            input1 <= input1;
        end
    end
    // input2
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            input2 <= 32'h0;
        end
        else if(in2_row_reg != 4'b0 && in2_col_reg != 4'b0  && (data_type ? input2_cnt < 32'h8 : input2_cnt < 32'h4)) begin
            case({in2_row_reg, in2_col_reg})
                8'b10001000: input2  <= input2 | 32'h0000_0001 << (input2_cnt << 2);
                8'b10000100: input2  <= input2 | 32'h0000_0002 << (input2_cnt << 2);
                8'b10000010: input2  <= input2 | 32'h0000_0003 << (input2_cnt << 2);
                8'b10000001: input2  <= input2 | 32'h0000_0004 << (input2_cnt << 2);
                8'b01001000: input2  <= input2 | 32'h0000_0005 << (input2_cnt << 2);
                8'b01000100: input2  <= input2 | 32'h0000_0006 << (input2_cnt << 2);
                8'b01000010: input2  <= input2 | 32'h0000_0007 << (input2_cnt << 2);
                8'b01000001: input2  <= input2 | 32'h0000_0008 << (input2_cnt << 2);
                8'b00101000: input2  <= input2 | 32'h0000_0009 << (input2_cnt << 2);
                8'b00100100: input2  <= input2 | 32'h0000_0000 << (input2_cnt << 2);
                8'b00100010: input2  <= input2 | 32'h0000_000A << (input2_cnt << 2);
                8'b00100001: input2  <= input2 | 32'h0000_000B << (input2_cnt << 2);
                8'b00011000: input2  <= input2 | 32'h0000_000C << (input2_cnt << 2);
                8'b00010100: input2  <= input2 | 32'h0000_000D << (input2_cnt << 2);
                8'b00010010: input2  <= input2 | 32'h0000_000E << (input2_cnt << 2);
                8'b00010001: input2  <= input2 | 32'h0000_000F << (input2_cnt << 2);
                default: input2 <= input2;
            endcase
        end
        else if(ce) begin // if start calculation, reset in2
            input2 <= 32'h0;
        end
        else begin
            input2 <= input2;
        end
    end

    // float_mult instance
    float_mult uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_type(data_type),
        .valid(enter),
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

    // output assign
    // input1 display
    always @(posedge clk or negedge rst_n) begin // disp1_bit7
        if(!rst_n) begin
            disp1_bit7 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp1_bit7 <= 7'b0;
        else begin
            case (input1[3:0])
                4'h0: disp1_bit7 <= 7'b1111110; // 0
                4'h1: disp1_bit7 <= 7'b0110000; // 1
                4'h2: disp1_bit7 <= 7'b1101101; // 2
                4'h3: disp1_bit7 <= 7'b1111001; // 3
                4'h4: disp1_bit7 <= 7'b0110011; // 4
                4'h5: disp1_bit7 <= 7'b1011011; // 5
                4'h6: disp1_bit7 <= 7'b1011111; // 6
                4'h7: disp1_bit7 <= 7'b1110000; // 7
                4'h8: disp1_bit7 <= 7'b1111111; // 8
                4'h9: disp1_bit7 <= 7'b1111011; // 9
                4'hA: disp1_bit7 <= 7'b1110111; // A
                4'hB: disp1_bit7 <= 7'b0011111; // B
                4'hC: disp1_bit7 <= 7'b1001110; // C
                4'hD: disp1_bit7 <= 7'b0111101; // D
                4'hE: disp1_bit7 <= 7'b1001111; // E
                4'hF: disp1_bit7 <= 7'b1000111; // F
                default: disp1_bit7 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit6
        if(!rst_n) begin
            disp1_bit6 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp1_bit6 <= 7'b0;
        else begin
            case (input1[7:4])
                4'h0: disp1_bit6 <= 7'b1111110; // 0
                4'h1: disp1_bit6 <= 7'b0110000; // 1
                4'h2: disp1_bit6 <= 7'b1101101; // 2
                4'h3: disp1_bit6 <= 7'b1111001; // 3
                4'h4: disp1_bit6 <= 7'b0110011; // 4
                4'h5: disp1_bit6 <= 7'b1011011; // 5
                4'h6: disp1_bit6 <= 7'b1011111; // 6
                4'h7: disp1_bit6 <= 7'b1110000; // 7
                4'h8: disp1_bit6 <= 7'b1111111; // 8
                4'h9: disp1_bit6 <= 7'b1111011; // 9
                4'hA: disp1_bit6 <= 7'b1110111; // A
                4'hB: disp1_bit6 <= 7'b0011111; // B
                4'hC: disp1_bit6 <= 7'b1001110; // C
                4'hD: disp1_bit6 <= 7'b0111101; // D
                4'hE: disp1_bit6 <= 7'b1001111; // E
                4'hF: disp1_bit6 <= 7'b1000111; // F
                default: disp1_bit6 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit5
        if(!rst_n) begin
            disp1_bit5 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp1_bit5 <= 7'b0;
        else begin
            case (input1[11:8])
                4'h0: disp1_bit5 <= 7'b1111110; // 0
                4'h1: disp1_bit5 <= 7'b0110000; // 1
                4'h2: disp1_bit5 <= 7'b1101101; // 2
                4'h3: disp1_bit5 <= 7'b1111001; // 3
                4'h4: disp1_bit5 <= 7'b0110011; // 4
                4'h5: disp1_bit5 <= 7'b1011011; // 5
                4'h6: disp1_bit5 <= 7'b1011111; // 6
                4'h7: disp1_bit5 <= 7'b1110000; // 7
                4'h8: disp1_bit5 <= 7'b1111111; // 8
                4'h9: disp1_bit5 <= 7'b1111011; // 9
                4'hA: disp1_bit5 <= 7'b1110111; // A
                4'hB: disp1_bit5 <= 7'b0011111; // B
                4'hC: disp1_bit5 <= 7'b1001110; // C
                4'hD: disp1_bit5 <= 7'b0111101; // D
                4'hE: disp1_bit5 <= 7'b1001111; // E
                4'hF: disp1_bit5 <= 7'b1000111; // F
                default: disp1_bit5 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit4
        if(!rst_n) begin
            disp1_bit4 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp1_bit4 <= 7'b0;
        else begin
            case (input1[15:12])
                4'h0: disp1_bit4 <= 7'b1111110; // 0
                4'h1: disp1_bit4 <= 7'b0110000; // 1
                4'h2: disp1_bit4 <= 7'b1101101; // 2
                4'h3: disp1_bit4 <= 7'b1111001; // 3
                4'h4: disp1_bit4 <= 7'b0110011; // 4
                4'h5: disp1_bit4 <= 7'b1011011; // 5
                4'h6: disp1_bit4 <= 7'b1011111; // 6
                4'h7: disp1_bit4 <= 7'b1110000; // 7
                4'h8: disp1_bit4 <= 7'b1111111; // 8
                4'h9: disp1_bit4 <= 7'b1111011; // 9
                4'hA: disp1_bit4 <= 7'b1110111; // A
                4'hB: disp1_bit4 <= 7'b0011111; // B
                4'hC: disp1_bit4 <= 7'b1001110; // C
                4'hD: disp1_bit4 <= 7'b0111101; // D
                4'hE: disp1_bit4 <= 7'b1001111; // E
                4'hF: disp1_bit4 <= 7'b1000111; // F
                default: disp1_bit4 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit3
        if(!rst_n) begin
            disp1_bit3 <= 7'h0;
        end 
        else if(enter) 
            disp1_bit3 <= 7'b0;
        else if(data_type) begin // fp32
            case (input1[19:16])
                4'h0: disp1_bit3 <= 7'b1111110; // 0
                4'h1: disp1_bit3 <= 7'b0110000; // 1
                4'h2: disp1_bit3 <= 7'b1101101; // 2
                4'h3: disp1_bit3 <= 7'b1111001; // 3
                4'h4: disp1_bit3 <= 7'b0110011; // 4
                4'h5: disp1_bit3 <= 7'b1011011; // 5
                4'h6: disp1_bit3 <= 7'b1011111; // 6
                4'h7: disp1_bit3 <= 7'b1110000; // 7
                4'h8: disp1_bit3 <= 7'b1111111; // 8
                4'h9: disp1_bit3 <= 7'b1111011; // 9
                4'hA: disp1_bit3 <= 7'b1110111; // A
                4'hB: disp1_bit3 <= 7'b0011111; // B
                4'hC: disp1_bit3 <= 7'b1001110; // C
                4'hD: disp1_bit3 <= 7'b0111101; // D
                4'hE: disp1_bit3 <= 7'b1001111; // E
                4'hF: disp1_bit3 <= 7'b1000111; // F
                default: disp1_bit3 <= 7'b0000000;
            endcase
        end
        else begin // fp16
            case (input1[3:0])
                4'h0: disp1_bit3 <= 7'b1111110; // 0
                4'h1: disp1_bit3 <= 7'b0110000; // 1
                4'h2: disp1_bit3 <= 7'b1101101; // 2
                4'h3: disp1_bit3 <= 7'b1111001; // 3
                4'h4: disp1_bit3 <= 7'b0110011; // 4
                4'h5: disp1_bit3 <= 7'b1011011; // 5
                4'h6: disp1_bit3 <= 7'b1011111; // 6
                4'h7: disp1_bit3 <= 7'b1110000; // 7
                4'h8: disp1_bit3 <= 7'b1111111; // 8
                4'h9: disp1_bit3 <= 7'b1111011; // 9
                4'hA: disp1_bit3 <= 7'b1110111; // A
                4'hB: disp1_bit3 <= 7'b0011111; // B
                4'hC: disp1_bit3 <= 7'b1001110; // C
                4'hD: disp1_bit3 <= 7'b0111101; // D
                4'hE: disp1_bit3 <= 7'b1001111; // E
                4'hF: disp1_bit3 <= 7'b1000111; // F
                default: disp1_bit3 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit2
        if(!rst_n) begin
            disp1_bit2 <= 7'h0;
        end 
        else if(enter) 
            disp1_bit2 <= 7'b0;
        else if(data_type) begin // fp32
            case (input1[23:20])
                4'h0: disp1_bit2 <= 7'b1111110; // 0
                4'h1: disp1_bit2 <= 7'b0110000; // 1
                4'h2: disp1_bit2 <= 7'b1101101; // 2
                4'h3: disp1_bit2 <= 7'b1111001; // 3
                4'h4: disp1_bit2 <= 7'b0110011; // 4
                4'h5: disp1_bit2 <= 7'b1011011; // 5
                4'h6: disp1_bit2 <= 7'b1011111; // 6
                4'h7: disp1_bit2 <= 7'b1110000; // 7
                4'h8: disp1_bit2 <= 7'b1111111; // 8
                4'h9: disp1_bit2 <= 7'b1111011; // 9
                4'hA: disp1_bit2 <= 7'b1110111; // A
                4'hB: disp1_bit2 <= 7'b0011111; // B
                4'hC: disp1_bit2 <= 7'b1001110; // C
                4'hD: disp1_bit2 <= 7'b0111101; // D
                4'hE: disp1_bit2 <= 7'b1001111; // E
                4'hF: disp1_bit2 <= 7'b1000111; // F
                default: disp1_bit2 <= 7'b0000000;
            endcase
        end
        else begin // fp16
            case (input1[7:4])
                4'h0: disp1_bit2 <= 7'b1111110; // 0
                4'h1: disp1_bit2 <= 7'b0110000; // 1
                4'h2: disp1_bit2 <= 7'b1101101; // 2
                4'h3: disp1_bit2 <= 7'b1111001; // 3
                4'h4: disp1_bit2 <= 7'b0110011; // 4
                4'h5: disp1_bit2 <= 7'b1011011; // 5
                4'h6: disp1_bit2 <= 7'b1011111; // 6
                4'h7: disp1_bit2 <= 7'b1110000; // 7
                4'h8: disp1_bit2 <= 7'b1111111; // 8
                4'h9: disp1_bit2 <= 7'b1111011; // 9
                4'hA: disp1_bit2 <= 7'b1110111; // A
                4'hB: disp1_bit2 <= 7'b0011111; // B
                4'hC: disp1_bit2 <= 7'b1001110; // C
                4'hD: disp1_bit2 <= 7'b0111101; // D
                4'hE: disp1_bit2 <= 7'b1001111; // E
                4'hF: disp1_bit2 <= 7'b1000111; // F
                default: disp1_bit2 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit1
        if(!rst_n) begin
            disp1_bit1 <= 7'h0;
        end 
        else if(enter) 
            disp1_bit1 <= 7'b0;
        else if(data_type) begin // fp32
            case (input1[27:24])
                4'h0: disp1_bit1 <= 7'b1111110; // 0
                4'h1: disp1_bit1 <= 7'b0110000; // 1
                4'h2: disp1_bit1 <= 7'b1101101; // 2
                4'h3: disp1_bit1 <= 7'b1111001; // 3
                4'h4: disp1_bit1 <= 7'b0110011; // 4
                4'h5: disp1_bit1 <= 7'b1011011; // 5
                4'h6: disp1_bit1 <= 7'b1011111; // 6
                4'h7: disp1_bit1 <= 7'b1110000; // 7
                4'h8: disp1_bit1 <= 7'b1111111; // 8
                4'h9: disp1_bit1 <= 7'b1111011; // 9
                4'hA: disp1_bit1 <= 7'b1110111; // A
                4'hB: disp1_bit1 <= 7'b0011111; // B
                4'hC: disp1_bit1 <= 7'b1001110; // C
                4'hD: disp1_bit1 <= 7'b0111101; // D
                4'hE: disp1_bit1 <= 7'b1001111; // E
                4'hF: disp1_bit1 <= 7'b1000111; // F
                default: disp1_bit1 <= 7'b0000000;
            endcase
        end
        else begin // fp16
            case (input1[11:8])
                4'h0: disp1_bit1 <= 7'b1111110; // 0
                4'h1: disp1_bit1 <= 7'b0110000; // 1
                4'h2: disp1_bit1 <= 7'b1101101; // 2
                4'h3: disp1_bit1 <= 7'b1111001; // 3
                4'h4: disp1_bit1 <= 7'b0110011; // 4
                4'h5: disp1_bit1 <= 7'b1011011; // 5
                4'h6: disp1_bit1 <= 7'b1011111; // 6
                4'h7: disp1_bit1 <= 7'b1110000; // 7
                4'h8: disp1_bit1 <= 7'b1111111; // 8
                4'h9: disp1_bit1 <= 7'b1111011; // 9
                4'hA: disp1_bit1 <= 7'b1110111; // A
                4'hB: disp1_bit1 <= 7'b0011111; // B
                4'hC: disp1_bit1 <= 7'b1001110; // C
                4'hD: disp1_bit1 <= 7'b0111101; // D
                4'hE: disp1_bit1 <= 7'b1001111; // E
                4'hF: disp1_bit1 <= 7'b1000111; // F
                default: disp1_bit1 <= 7'b0000000;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp1_bit0
        if(!rst_n) begin
            disp1_bit0 <= 7'h0;
        end 
        else if(enter) 
            disp1_bit0 <= 7'b0;
        else if(data_type) begin // fp32
            case (input1[31:28])
                4'h0: disp1_bit0 <= 7'b1111110; // 0
                4'h1: disp1_bit0 <= 7'b0110000; // 1
                4'h2: disp1_bit0 <= 7'b1101101; // 2
                4'h3: disp1_bit0 <= 7'b1111001; // 3
                4'h4: disp1_bit0 <= 7'b0110011; // 4
                4'h5: disp1_bit0 <= 7'b1011011; // 5
                4'h6: disp1_bit0 <= 7'b1011111; // 6
                4'h7: disp1_bit0 <= 7'b1110000; // 7
                4'h8: disp1_bit0 <= 7'b1111111; // 8
                4'h9: disp1_bit0 <= 7'b1111011; // 9
                4'hA: disp1_bit0 <= 7'b1110111; // A
                4'hB: disp1_bit0 <= 7'b0011111; // B
                4'hC: disp1_bit0 <= 7'b1001110; // C
                4'hD: disp1_bit0 <= 7'b0111101; // D
                4'hE: disp1_bit0 <= 7'b1001111; // E
                4'hF: disp1_bit0 <= 7'b1000111; // F
                default: disp1_bit0 <= 7'b0000000;
            endcase
        end
        else begin // fp16
            case (input1[15:12])
                4'h0: disp1_bit0 <= 7'b1111110; // 0
                4'h1: disp1_bit0 <= 7'b0110000; // 1
                4'h2: disp1_bit0 <= 7'b1101101; // 2
                4'h3: disp1_bit0 <= 7'b1111001; // 3
                4'h4: disp1_bit0 <= 7'b0110011; // 4
                4'h5: disp1_bit0 <= 7'b1011011; // 5
                4'h6: disp1_bit0 <= 7'b1011111; // 6
                4'h7: disp1_bit0 <= 7'b1110000; // 7
                4'h8: disp1_bit0 <= 7'b1111111; // 8
                4'h9: disp1_bit0 <= 7'b1111011; // 9
                4'hA: disp1_bit0 <= 7'b1110111; // A
                4'hB: disp1_bit0 <= 7'b0011111; // B
                4'hC: disp1_bit0 <= 7'b1001110; // C
                4'hD: disp1_bit0 <= 7'b0111101; // D
                4'hE: disp1_bit0 <= 7'b1001111; // E
                4'hF: disp1_bit0 <= 7'b1000111; // F
                default: disp1_bit0 <= 7'b0000000;
            endcase
        end
    end

    // input2 display
    always @(posedge clk or negedge rst_n) begin // disp2_bit7
        if(!rst_n) begin
            disp2_bit7 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp2_bit7 <= 7'h0;
        else begin
            case (input2[3:0])
                4'h0: disp2_bit7 <= 7'b1111110; // 0
                4'h1: disp2_bit7 <= 7'b0110000; // 1
                4'h2: disp2_bit7 <= 7'b1101101; // 2
                4'h3: disp2_bit7 <= 7'b1111001; // 3
                4'h4: disp2_bit7 <= 7'b0110011; // 4
                4'h5: disp2_bit7 <= 7'b1011011; // 5
                4'h6: disp2_bit7 <= 7'b1011111; // 6
                4'h7: disp2_bit7 <= 7'b1110000; // 7
                4'h8: disp2_bit7 <= 7'b1111111; // 8
                4'h9: disp2_bit7 <= 7'b1111011; // 9
                4'hA: disp2_bit7 <= 7'b1110111; // A
                4'hB: disp2_bit7 <= 7'b0011111; // B
                4'hC: disp2_bit7 <= 7'b1001110; // C
                4'hD: disp2_bit7 <= 7'b0111101; // D
                4'hE: disp2_bit7 <= 7'b1001111; // E
                4'hF: disp2_bit7 <= 7'b1000111; // F
                default: disp2_bit7 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit6
        if(!rst_n) begin
            disp2_bit6 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp2_bit6 <= 7'h0; 
        else begin
            case (input2[7:4])
                4'h0: disp2_bit6 <= 7'b1111110; // 0
                4'h1: disp2_bit6 <= 7'b0110000; // 1
                4'h2: disp2_bit6 <= 7'b1101101; // 2
                4'h3: disp2_bit6 <= 7'b1111001; // 3
                4'h4: disp2_bit6 <= 7'b0110011; // 4
                4'h5: disp2_bit6 <= 7'b1011011; // 5
                4'h6: disp2_bit6 <= 7'b1011111; // 6
                4'h7: disp2_bit6 <= 7'b1110000; // 7
                4'h8: disp2_bit6 <= 7'b1111111; // 8
                4'h9: disp2_bit6 <= 7'b1111011; // 9
                4'hA: disp2_bit6 <= 7'b1110111; // A
                4'hB: disp2_bit6 <= 7'b0011111; // B
                4'hC: disp2_bit6 <= 7'b1001110; // C
                4'hD: disp2_bit6 <= 7'b0111101; // D
                4'hE: disp2_bit6 <= 7'b1001111; // E
                4'hF: disp2_bit6 <= 7'b1000111; // F
                default: disp2_bit6 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit5
        if(!rst_n) begin
            disp2_bit5 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp2_bit5 <= 7'h0;
        else begin
            case (input2[11:8])
                4'h0: disp2_bit5 <= 7'b1111110; // 0
                4'h1: disp2_bit5 <= 7'b0110000; // 1
                4'h2: disp2_bit5 <= 7'b1101101; // 2
                4'h3: disp2_bit5 <= 7'b1111001; // 3
                4'h4: disp2_bit5 <= 7'b0110011; // 4
                4'h5: disp2_bit5 <= 7'b1011011; // 5
                4'h6: disp2_bit5 <= 7'b1011111; // 6
                4'h7: disp2_bit5 <= 7'b1110000; // 7
                4'h8: disp2_bit5 <= 7'b1111111; // 8
                4'h9: disp2_bit5 <= 7'b1111011; // 9
                4'hA: disp2_bit5 <= 7'b1110111; // A
                4'hB: disp2_bit5 <= 7'b0011111; // B
                4'hC: disp2_bit5 <= 7'b1001110; // C
                4'hD: disp2_bit5 <= 7'b0111101; // D
                4'hE: disp2_bit5 <= 7'b1001111; // E
                4'hF: disp2_bit5 <= 7'b1000111; // F
                default: disp2_bit5 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit4
        if(!rst_n) begin
            disp2_bit4 <= 7'h0;
        end 
        else if(enter || !data_type) 
            disp2_bit4 <= 7'h0;
        else begin
            case (input2[15:12])
                4'h0: disp2_bit4 <= 7'b1111110; // 0
                4'h1: disp2_bit4 <= 7'b0110000; // 1
                4'h2: disp2_bit4 <= 7'b1101101; // 2
                4'h3: disp2_bit4 <= 7'b1111001; // 3
                4'h4: disp2_bit4 <= 7'b0110011; // 4
                4'h5: disp2_bit4 <= 7'b1011011; // 5
                4'h6: disp2_bit4 <= 7'b1011111; // 6
                4'h7: disp2_bit4 <= 7'b1110000; // 7
                4'h8: disp2_bit4 <= 7'b1111111; // 8
                4'h9: disp2_bit4 <= 7'b1111011; // 9
                4'hA: disp2_bit4 <= 7'b1110111; // A
                4'hB: disp2_bit4 <= 7'b0011111; // B
                4'hC: disp2_bit4 <= 7'b1001110; // C
                4'hD: disp2_bit4 <= 7'b0111101; // D
                4'hE: disp2_bit4 <= 7'b1001111; // E
                4'hF: disp2_bit4 <= 7'b1000111; // F
                default: disp2_bit4 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit3
        if(!rst_n) begin
            disp2_bit3 <= 7'h0;
        end 
        else if(enter) 
            disp2_bit3 <= 7'h0;
        else if(data_type) begin // fp32
            case (input2[19:16])
                4'h0: disp2_bit3 <= 7'b1111110; // 0
                4'h1: disp2_bit3 <= 7'b0110000; // 1
                4'h2: disp2_bit3 <= 7'b1101101; // 2
                4'h3: disp2_bit3 <= 7'b1111001; // 3
                4'h4: disp2_bit3 <= 7'b0110011; // 4
                4'h5: disp2_bit3 <= 7'b1011011; // 5
                4'h6: disp2_bit3 <= 7'b1011111; // 6
                4'h7: disp2_bit3 <= 7'b1110000; // 7
                4'h8: disp2_bit3 <= 7'b1111111; // 8
                4'h9: disp2_bit3 <= 7'b1111011; // 9
                4'hA: disp2_bit3 <= 7'b1110111; // A
                4'hB: disp2_bit3 <= 7'b0011111; // B
                4'hC: disp2_bit3 <= 7'b1001110; // C
                4'hD: disp2_bit3 <= 7'b0111101; // D
                4'hE: disp2_bit3 <= 7'b1001111; // E
                4'hF: disp2_bit3 <= 7'b1000111; // F
                default: disp2_bit3 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (input2[3:0])
                4'h0: disp2_bit3 <= 7'b1111110; // 0
                4'h1: disp2_bit3 <= 7'b0110000; // 1
                4'h2: disp2_bit3 <= 7'b1101101; // 2
                4'h3: disp2_bit3 <= 7'b1111001; // 3
                4'h4: disp2_bit3 <= 7'b0110011; // 4
                4'h5: disp2_bit3 <= 7'b1011011; // 5
                4'h6: disp2_bit3 <= 7'b1011111; // 6
                4'h7: disp2_bit3 <= 7'b1110000; // 7
                4'h8: disp2_bit3 <= 7'b1111111; // 8
                4'h9: disp2_bit3 <= 7'b1111011; // 9
                4'hA: disp2_bit3 <= 7'b1110111; // A
                4'hB: disp2_bit3 <= 7'b0011111; // B
                4'hC: disp2_bit3 <= 7'b1001110; // C
                4'hD: disp2_bit3 <= 7'b0111101; // D
                4'hE: disp2_bit3 <= 7'b1001111; // E
                4'hF: disp2_bit3 <= 7'b1000111; // F
                default: disp2_bit3 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit2
        if(!rst_n) begin
            disp2_bit2 <= 7'h0;
        end 
        else if(enter) 
            disp2_bit2 <= 7'h0; 
        else if(data_type) begin // fp32
            case (input2[23:20])
                4'h0: disp2_bit2 <= 7'b1111110; // 0
                4'h1: disp2_bit2 <= 7'b0110000; // 1
                4'h2: disp2_bit2 <= 7'b1101101; // 2
                4'h3: disp2_bit2 <= 7'b1111001; // 3
                4'h4: disp2_bit2 <= 7'b0110011; // 4
                4'h5: disp2_bit2 <= 7'b1011011; // 5
                4'h6: disp2_bit2 <= 7'b1011111; // 6
                4'h7: disp2_bit2 <= 7'b1110000; // 7
                4'h8: disp2_bit2 <= 7'b1111111; // 8
                4'h9: disp2_bit2 <= 7'b1111011; // 9
                4'hA: disp2_bit2 <= 7'b1110111; // A
                4'hB: disp2_bit2 <= 7'b0011111; // B
                4'hC: disp2_bit2 <= 7'b1001110; // C
                4'hD: disp2_bit2 <= 7'b0111101; // D
                4'hE: disp2_bit2 <= 7'b1001111; // E
                4'hF: disp2_bit2 <= 7'b1000111; // F
                default: disp2_bit2 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (input2[7:4])
                4'h0: disp2_bit2 <= 7'b1111110; // 0
                4'h1: disp2_bit2 <= 7'b0110000; // 1
                4'h2: disp2_bit2 <= 7'b1101101; // 2
                4'h3: disp2_bit2 <= 7'b1111001; // 3
                4'h4: disp2_bit2 <= 7'b0110011; // 4
                4'h5: disp2_bit2 <= 7'b1011011; // 5
                4'h6: disp2_bit2 <= 7'b1011111; // 6
                4'h7: disp2_bit2 <= 7'b1110000; // 7
                4'h8: disp2_bit2 <= 7'b1111111; // 8
                4'h9: disp2_bit2 <= 7'b1111011; // 9
                4'hA: disp2_bit2 <= 7'b1110111; // A
                4'hB: disp2_bit2 <= 7'b0011111; // B
                4'hC: disp2_bit2 <= 7'b1001110; // C
                4'hD: disp2_bit2 <= 7'b0111101; // D
                4'hE: disp2_bit2 <= 7'b1001111; // E
                4'hF: disp2_bit2 <= 7'b1000111; // F
                default: disp2_bit2 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit1
       if(!rst_n) begin
            disp2_bit1 <= 7'h0;
        end 
        else if(enter) 
            disp2_bit1 <= 7'h0; 
        else if(data_type) begin // fp32
            case (input2[27:24])
                4'h0: disp2_bit1 <= 7'b1111110; // 0
                4'h1: disp2_bit1 <= 7'b0110000; // 1
                4'h2: disp2_bit1 <= 7'b1101101; // 2
                4'h3: disp2_bit1 <= 7'b1111001; // 3
                4'h4: disp2_bit1 <= 7'b0110011; // 4
                4'h5: disp2_bit1 <= 7'b1011011; // 5
                4'h6: disp2_bit1 <= 7'b1011111; // 6
                4'h7: disp2_bit1 <= 7'b1110000; // 7
                4'h8: disp2_bit1 <= 7'b1111111; // 8
                4'h9: disp2_bit1 <= 7'b1111011; // 9
                4'hA: disp2_bit1 <= 7'b1110111; // A
                4'hB: disp2_bit1 <= 7'b0011111; // B
                4'hC: disp2_bit1 <= 7'b1001110; // C
                4'hD: disp2_bit1 <= 7'b0111101; // D
                4'hE: disp2_bit1 <= 7'b1001111; // E
                4'hF: disp2_bit1 <= 7'b1000111; // F
                default: disp2_bit1 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (input2[11:8])
                4'h0: disp2_bit1 <= 7'b1111110; // 0
                4'h1: disp2_bit1 <= 7'b0110000; // 1
                4'h2: disp2_bit1 <= 7'b1101101; // 2
                4'h3: disp2_bit1 <= 7'b1111001; // 3
                4'h4: disp2_bit1 <= 7'b0110011; // 4
                4'h5: disp2_bit1 <= 7'b1011011; // 5
                4'h6: disp2_bit1 <= 7'b1011111; // 6
                4'h7: disp2_bit1 <= 7'b1110000; // 7
                4'h8: disp2_bit1 <= 7'b1111111; // 8
                4'h9: disp2_bit1 <= 7'b1111011; // 9
                4'hA: disp2_bit1 <= 7'b1110111; // A
                4'hB: disp2_bit1 <= 7'b0011111; // B
                4'hC: disp2_bit1 <= 7'b1001110; // C
                4'hD: disp2_bit1 <= 7'b0111101; // D
                4'hE: disp2_bit1 <= 7'b1001111; // E
                4'hF: disp2_bit1 <= 7'b1000111; // F
                default: disp2_bit1 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // disp2_bit0
        if(!rst_n) begin
            disp2_bit0 <= 7'h0;
        end 
        else if(enter) 
            disp2_bit0 <= 7'h0; 
        else if(data_type) begin // fp32
            case (input2[31:28])
                4'h0: disp2_bit0 <= 7'b1111110; // 0
                4'h1: disp2_bit0 <= 7'b0110000; // 1
                4'h2: disp2_bit0 <= 7'b1101101; // 2
                4'h3: disp2_bit0 <= 7'b1111001; // 3
                4'h4: disp2_bit0 <= 7'b0110011; // 4
                4'h5: disp2_bit0 <= 7'b1011011; // 5
                4'h6: disp2_bit0 <= 7'b1011111; // 6
                4'h7: disp2_bit0 <= 7'b1110000; // 7
                4'h8: disp2_bit0 <= 7'b1111111; // 8
                4'h9: disp2_bit0 <= 7'b1111011; // 9
                4'hA: disp2_bit0 <= 7'b1110111; // A
                4'hB: disp2_bit0 <= 7'b0011111; // B
                4'hC: disp2_bit0 <= 7'b1001110; // C
                4'hD: disp2_bit0 <= 7'b0111101; // D
                4'hE: disp2_bit0 <= 7'b1001111; // E
                4'hF: disp2_bit0 <= 7'b1000111; // F
                default: disp2_bit0 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (input2[15:12])
                4'h0: disp2_bit0 <= 7'b1111110; // 0
                4'h1: disp2_bit0 <= 7'b0110000; // 1
                4'h2: disp2_bit0 <= 7'b1101101; // 2
                4'h3: disp2_bit0 <= 7'b1111001; // 3
                4'h4: disp2_bit0 <= 7'b0110011; // 4
                4'h5: disp2_bit0 <= 7'b1011011; // 5
                4'h6: disp2_bit0 <= 7'b1011111; // 6
                4'h7: disp2_bit0 <= 7'b1110000; // 7
                4'h8: disp2_bit0 <= 7'b1111111; // 8
                4'h9: disp2_bit0 <= 7'b1111011; // 9
                4'hA: disp2_bit0 <= 7'b1110111; // A
                4'hB: disp2_bit0 <= 7'b0011111; // B
                4'hC: disp2_bit0 <= 7'b1001110; // C
                4'hD: disp2_bit0 <= 7'b0111101; // D
                4'hE: disp2_bit0 <= 7'b1001111; // E
                4'hF: disp2_bit0 <= 7'b1000111; // F
                default: disp2_bit0 <= 7'b1111110;
            endcase
        end
    end

    // output display
    always @(posedge clk or negedge rst_n) begin // bit7
        if(!rst_n) begin
            bit7 <= 7'h0;
        end
        else if(!data_type) begin
            bit7 <= 7'h0;
        end
        else begin
            case(out_32[31:28])
                4'h0: bit7 <= 7'b1111110; // 0
                4'h1: bit7 <= 7'b0110000; // 1
                4'h2: bit7 <= 7'b1101101; // 2
                4'h3: bit7 <= 7'b1111001; // 3
                4'h4: bit7 <= 7'b0110011; // 4
                4'h5: bit7 <= 7'b1011011; // 5
                4'h6: bit7 <= 7'b1011111; // 6
                4'h7: bit7 <= 7'b1110000; // 7
                4'h8: bit7 <= 7'b1111111; // 8
                4'h9: bit7 <= 7'b1111011; // 9
                4'hA: bit7 <= 7'b1110111; // A
                4'hB: bit7 <= 7'b0011111; // B
                4'hC: bit7 <= 7'b1001110; // C
                4'hD: bit7 <= 7'b0111101; // D
                4'hE: bit7 <= 7'b1001111; // E
                4'hF: bit7 <= 7'b1000111; // F
                default: bit7 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit6
        if(!rst_n) begin
            bit6 <= 7'h0;
        end
        else if(!data_type) begin
            bit6 <= 7'h0;
        end
        else begin
            case(out_32[27:24])
                4'h0: bit6 <= 7'b1111110; // 0
                4'h1: bit6 <= 7'b0110000; // 1
                4'h2: bit6 <= 7'b1101101; // 2
                4'h3: bit6 <= 7'b1111001; // 3
                4'h4: bit6 <= 7'b0110011; // 4
                4'h5: bit6 <= 7'b1011011; // 5
                4'h6: bit6 <= 7'b1011111; // 6
                4'h7: bit6 <= 7'b1110000; // 7
                4'h8: bit6 <= 7'b1111111; // 8
                4'h9: bit6 <= 7'b1111011; // 9
                4'hA: bit6 <= 7'b1110111; // A
                4'hB: bit6 <= 7'b0011111; // B
                4'hC: bit6 <= 7'b1001110; // C
                4'hD: bit6 <= 7'b0111101; // D
                4'hE: bit6 <= 7'b1001111; // E
                4'hF: bit6 <= 7'b1000111; // F
                default: bit6 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit5
        if(!rst_n) begin
            bit5 <= 7'h0;
        end
        else if(!data_type) begin
            bit5 <= 7'h0;
        end
        else begin
            case(out_32[23:20])
                4'h0: bit5 <= 7'b1111110; // 0
                4'h1: bit5 <= 7'b0110000; // 1
                4'h2: bit5 <= 7'b1101101; // 2
                4'h3: bit5 <= 7'b1111001; // 3
                4'h4: bit5 <= 7'b0110011; // 4
                4'h5: bit5 <= 7'b1011011; // 5
                4'h6: bit5 <= 7'b1011111; // 6
                4'h7: bit5 <= 7'b1110000; // 7
                4'h8: bit5 <= 7'b1111111; // 8
                4'h9: bit5 <= 7'b1111011; // 9
                4'hA: bit5 <= 7'b1110111; // A
                4'hB: bit5 <= 7'b0011111; // B
                4'hC: bit5 <= 7'b1001110; // C
                4'hD: bit5 <= 7'b0111101; // D
                4'hE: bit5 <= 7'b1001111; // E
                4'hF: bit5 <= 7'b1000111; // F
                default: bit5 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit4
        if(!rst_n) begin
            bit4 <= 7'h0;
        end
        else if(!data_type) begin
            bit4 <= 7'h0;
        end
        else begin
            case(out_32[19:16])
                4'h0: bit4 <= 7'b1111110; // 0
                4'h1: bit4 <= 7'b0110000; // 1
                4'h2: bit4 <= 7'b1101101; // 2
                4'h3: bit4 <= 7'b1111001; // 3
                4'h4: bit4 <= 7'b0110011; // 4
                4'h5: bit4 <= 7'b1011011; // 5
                4'h6: bit4 <= 7'b1011111; // 6
                4'h7: bit4 <= 7'b1110000; // 7
                4'h8: bit4 <= 7'b1111111; // 8
                4'h9: bit4 <= 7'b1111011; // 9
                4'hA: bit4 <= 7'b1110111; // A
                4'hB: bit4 <= 7'b0011111; // B
                4'hC: bit4 <= 7'b1001110; // C
                4'hD: bit4 <= 7'b0111101; // D
                4'hE: bit4 <= 7'b1001111; // E
                4'hF: bit4 <= 7'b1000111; // F
                default: bit4 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit3
        if(!rst_n) begin
            bit3 <= 7'h0;
        end
        else if(data_type) begin // fp32
            case (out_32[15:12])
                4'h0: bit3 <= 7'b1111110; // 0
                4'h1: bit3 <= 7'b0110000; // 1
                4'h2: bit3 <= 7'b1101101; // 2
                4'h3: bit3 <= 7'b1111001; // 3
                4'h4: bit3 <= 7'b0110011; // 4
                4'h5: bit3 <= 7'b1011011; // 5
                4'h6: bit3 <= 7'b1011111; // 6
                4'h7: bit3 <= 7'b1110000; // 7
                4'h8: bit3 <= 7'b1111111; // 8
                4'h9: bit3 <= 7'b1111011; // 9
                4'hA: bit3 <= 7'b1110111; // A
                4'hB: bit3 <= 7'b0011111; // B
                4'hC: bit3 <= 7'b1001110; // C
                4'hD: bit3 <= 7'b0111101; // D
                4'hE: bit3 <= 7'b1001111; // E
                4'hF: bit3 <= 7'b1000111; // F
                default: bit3 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (out_16[15:12])
                4'h0: bit3 <= 7'b1111110; // 0
                4'h1: bit3 <= 7'b0110000; // 1
                4'h2: bit3 <= 7'b1101101; // 2
                4'h3: bit3 <= 7'b1111001; // 3
                4'h4: bit3 <= 7'b0110011; // 4
                4'h5: bit3 <= 7'b1011011; // 5
                4'h6: bit3 <= 7'b1011111; // 6
                4'h7: bit3 <= 7'b1110000; // 7
                4'h8: bit3 <= 7'b1111111; // 8
                4'h9: bit3 <= 7'b1111011; // 9
                4'hA: bit3 <= 7'b1110111; // A
                4'hB: bit3 <= 7'b0011111; // B
                4'hC: bit3 <= 7'b1001110; // C
                4'hD: bit3 <= 7'b0111101; // D
                4'hE: bit3 <= 7'b1001111; // E
                4'hF: bit3 <= 7'b1000111; // F
                default: bit3 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit2
        if(!rst_n) begin
            bit2 <= 7'h0;
        end 
        else if(data_type) begin // fp32
            case (out_32[11:8])
                4'h0: bit2 <= 7'b1111110; // 0
                4'h1: bit2 <= 7'b0110000; // 1
                4'h2: bit2 <= 7'b1101101; // 2
                4'h3: bit2 <= 7'b1111001; // 3
                4'h4: bit2 <= 7'b0110011; // 4
                4'h5: bit2 <= 7'b1011011; // 5
                4'h6: bit2 <= 7'b1011111; // 6
                4'h7: bit2 <= 7'b1110000; // 7
                4'h8: bit2 <= 7'b1111111; // 8
                4'h9: bit2 <= 7'b1111011; // 9
                4'hA: bit2 <= 7'b1110111; // A
                4'hB: bit2 <= 7'b0011111; // B
                4'hC: bit2 <= 7'b1001110; // C
                4'hD: bit2 <= 7'b0111101; // D
                4'hE: bit2 <= 7'b1001111; // E
                4'hF: bit2 <= 7'b1000111; // F
                default: bit2 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (out_16[11:8])
                4'h0: bit2 <= 7'b1111110; // 0
                4'h1: bit2 <= 7'b0110000; // 1
                4'h2: bit2 <= 7'b1101101; // 2
                4'h3: bit2 <= 7'b1111001; // 3
                4'h4: bit2 <= 7'b0110011; // 4
                4'h5: bit2 <= 7'b1011011; // 5
                4'h6: bit2 <= 7'b1011111; // 6
                4'h7: bit2 <= 7'b1110000; // 7
                4'h8: bit2 <= 7'b1111111; // 8
                4'h9: bit2 <= 7'b1111011; // 9
                4'hA: bit2 <= 7'b1110111; // A
                4'hB: bit2 <= 7'b0011111; // B
                4'hC: bit2 <= 7'b1001110; // C
                4'hD: bit2 <= 7'b0111101; // D
                4'hE: bit2 <= 7'b1001111; // E
                4'hF: bit2 <= 7'b1000111; // F
                default: bit2 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit1
        if(!rst_n) begin
            bit1 <= 7'h0;
        end 
        else if(data_type) begin // fp32
            case (out_32[7:4])
                4'h0: bit1 <= 7'b1111110; // 0
                4'h1: bit1 <= 7'b0110000; // 1
                4'h2: bit1 <= 7'b1101101; // 2
                4'h3: bit1 <= 7'b1111001; // 3
                4'h4: bit1 <= 7'b0110011; // 4
                4'h5: bit1 <= 7'b1011011; // 5
                4'h6: bit1 <= 7'b1011111; // 6
                4'h7: bit1 <= 7'b1110000; // 7
                4'h8: bit1 <= 7'b1111111; // 8
                4'h9: bit1 <= 7'b1111011; // 9
                4'hA: bit1 <= 7'b1110111; // A
                4'hB: bit1 <= 7'b0011111; // B
                4'hC: bit1 <= 7'b1001110; // C
                4'hD: bit1 <= 7'b0111101; // D
                4'hE: bit1 <= 7'b1001111; // E
                4'hF: bit1 <= 7'b1000111; // F
                default: bit1 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (out_16[7:4])
                4'h0: bit1 <= 7'b1111110; // 0
                4'h1: bit1 <= 7'b0110000; // 1
                4'h2: bit1 <= 7'b1101101; // 2
                4'h3: bit1 <= 7'b1111001; // 3
                4'h4: bit1 <= 7'b0110011; // 4
                4'h5: bit1 <= 7'b1011011; // 5
                4'h6: bit1 <= 7'b1011111; // 6
                4'h7: bit1 <= 7'b1110000; // 7
                4'h8: bit1 <= 7'b1111111; // 8
                4'h9: bit1 <= 7'b1111011; // 9
                4'hA: bit1 <= 7'b1110111; // A
                4'hB: bit1 <= 7'b0011111; // B
                4'hC: bit1 <= 7'b1001110; // C
                4'hD: bit1 <= 7'b0111101; // D
                4'hE: bit1 <= 7'b1001111; // E
                4'hF: bit1 <= 7'b1000111; // F
                default: bit1 <= 7'b1111110;
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin // bit0
        if(!rst_n) begin
            bit0 <= 7'h0;
        end 
        else if(data_type) begin // fp32
            case (out_32[3:0])
                4'h0: bit0 <= 7'b1111110; // 0
                4'h1: bit0 <= 7'b0110000; // 1
                4'h2: bit0 <= 7'b1101101; // 2
                4'h3: bit0 <= 7'b1111001; // 3
                4'h4: bit0 <= 7'b0110011; // 4
                4'h5: bit0 <= 7'b1011011; // 5
                4'h6: bit0 <= 7'b1011111; // 6
                4'h7: bit0 <= 7'b1110000; // 7
                4'h8: bit0 <= 7'b1111111; // 8
                4'h9: bit0 <= 7'b1111011; // 9
                4'hA: bit0 <= 7'b1110111; // A
                4'hB: bit0 <= 7'b0011111; // B
                4'hC: bit0 <= 7'b1001110; // C
                4'hD: bit0 <= 7'b0111101; // D
                4'hE: bit0 <= 7'b1001111; // E
                4'hF: bit0 <= 7'b1000111; // F
                default: bit0 <= 7'b1111110;
            endcase
        end
        else begin // fp16
            case (out_16[3:0])
                4'h0: bit0 <= 7'b1111110; // 0
                4'h1: bit0 <= 7'b0110000; // 1
                4'h2: bit0 <= 7'b1101101; // 2
                4'h3: bit0 <= 7'b1111001; // 3
                4'h4: bit0 <= 7'b0110011; // 4
                4'h5: bit0 <= 7'b1011011; // 5
                4'h6: bit0 <= 7'b1011111; // 6
                4'h7: bit0 <= 7'b1110000; // 7
                4'h8: bit0 <= 7'b1111111; // 8
                4'h9: bit0 <= 7'b1111011; // 9
                4'hA: bit0 <= 7'b1110111; // A
                4'hB: bit0 <= 7'b0011111; // B
                4'hC: bit0 <= 7'b1001110; // C
                4'hD: bit0 <= 7'b0111101; // D
                4'hE: bit0 <= 7'b1001111; // E
                4'hF: bit0 <= 7'b1000111; // F
                default: bit0 <= 7'b1111110;
            endcase
        end
    end

    //output segment display
    // disp 1
    always @(posedge clk or negedge rst_n) begin // disp1_sel_cnt
        if(!rst_n)
            disp1_sel_cnt <= 3'd0;
        else 
            disp1_sel_cnt <= disp1_sel_cnt + 1;
    end
    always @(*) begin
        case (disp1_sel_cnt)
            3'd0: disp1_sel <= 8'b0000_0001;
            3'd1: disp1_sel <= 8'b0000_0010;
            3'd2: disp1_sel <= 8'b0000_0100;
            3'd3: disp1_sel <= 8'b0000_1000;
            3'd4: disp1_sel <= 8'b0001_0000;
            3'd5: disp1_sel <= 8'b0010_0000;
            3'd6: disp1_sel <= 8'b0100_0000;
            3'd7: disp1_sel <= 8'b1000_0000;
        endcase
    end
    always @(*) begin // disp1_seg
        case(disp1_sel_cnt)
            3'd0: disp1_seg <= disp1_bit0;
            3'd1: disp1_seg <= disp1_bit1;
            3'd2: disp1_seg <= disp1_bit2;
            3'd3: disp1_seg <= disp1_bit3;
            3'd4: disp1_seg <= disp1_bit4;
            3'd5: disp1_seg <= disp1_bit5;
            3'd6: disp1_seg <= disp1_bit6;
            3'd7: disp1_seg <= disp1_bit7;
        endcase
    end

    // disp 2
    always @(posedge clk or negedge rst_n) begin // disp2_sel_cnt
        if(!rst_n)
            disp2_sel_cnt <= 3'd0;
        else 
            disp2_sel_cnt <= disp2_sel_cnt + 1;
    end
    always @(*) begin // disp2_sel
        case(disp2_sel_cnt)
            3'd0: disp2_sel <= 8'b0000_0001;
            3'd1: disp2_sel <= 8'b0000_0010;
            3'd2: disp2_sel <= 8'b0000_0100;
            3'd3: disp2_sel <= 8'b0000_1000;
            3'd4: disp2_sel <= 8'b0001_0000;
            3'd5: disp2_sel <= 8'b0010_0000;
            3'd6: disp2_sel <= 8'b0100_0000;
            3'd7: disp2_sel <= 8'b1000_0000;
        endcase
    end
    always @(*) begin // disp2_seg
        case(disp2_sel_cnt)
            3'd0: disp2_seg <= disp2_bit0;
            3'd1: disp2_seg <= disp2_bit1;
            3'd2: disp2_seg <= disp2_bit2;
            3'd3: disp2_seg <= disp2_bit3;
            3'd4: disp2_seg <= disp2_bit4;
            3'd5: disp2_seg <= disp2_bit5;
            3'd6: disp2_seg <= disp2_bit6;
            3'd7: disp2_seg <= disp2_bit7;
        endcase
    end

    // out
    always @(posedge clk or negedge rst_n) begin // out_sel_cnt
        if(!rst_n)
            out_sel_cnt <= 3'd0;
        else 
            out_sel_cnt <= disp2_sel_cnt + 1;
    end
    always @(*) begin // disp2_sel
        case(out_sel_cnt)
            3'd0: out_sel <= 8'b0000_0001;
            3'd1: out_sel <= 8'b0000_0010;
            3'd2: out_sel <= 8'b0000_0100;
            3'd3: out_sel <= 8'b0000_1000;
            3'd4: out_sel <= 8'b0001_0000;
            3'd5: out_sel <= 8'b0010_0000;
            3'd6: out_sel <= 8'b0100_0000;
            3'd7: out_sel <= 8'b1000_0000;
        endcase
    end
    always @(*) begin // disp2_seg
        case(out_sel_cnt)
            3'd0: out_seg <= bit0;
            3'd1: out_seg <= bit1;
            3'd2: out_seg <= bit2;
            3'd3: out_seg <= bit3;
            3'd4: out_seg <= bit4;
            3'd5: out_seg <= bit5;
            3'd6: out_seg <= bit6;
            3'd7: out_seg <= bit7;
        endcase
    end

endmodule
