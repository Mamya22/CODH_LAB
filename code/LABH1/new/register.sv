`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/20 22:07:29
// Design Name: 
// Module Name: register
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


module register #(parameter WIDTH=32,RST_VAL=0)
(   input clk,rst,en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
always @(posedge clk)
    if(rst) q<=RST_VAL;
    else if(en)
        q<=d;
endmodule
