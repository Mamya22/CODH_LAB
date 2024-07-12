`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/24 20:19:58
// Design Name: 
// Module Name: BRAM_T
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


module BRAM_T(
        input clk,we,en,
        input [31:0] data0,
        input [9:0] addr,
        output reg [31:0] res_b
    );
    BRAM bram(
        .addra(addr),
        .dina(data0),
        .douta(res),
        .clka(clk),
        .wea(we),
        .ena(en)
    );
endmodule
