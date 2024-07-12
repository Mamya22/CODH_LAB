`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/24 20:19:43
// Design Name: 
// Module Name: DRAM_T
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


module DRAM_T(
    input clk, we,
    input [31:0] data,
    input [9:0] addr,
    output reg [31:0] spo
    );
    DRAM_0 dram(
        .clk(clk),
        .d(data),
        .a(addr),
        .spo(spo),
        .we(we)
    );

endmodule
