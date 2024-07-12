`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/19 16:32:25
// Design Name: 
// Module Name: RegFile
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


module RegFile(
    input clk,
    input [4:0] ra0, ra1, wa,
    input [31:0] wd,
    input we,
    output [31:0] rd0, rd1
    );
    reg [31:0] rf [0:31];
    assign rf[0] = 0;
    assign rd0 = (wa == ra0 && we) ? wd : rf[ra0];
    assign rd1 = (wa == ra1 && we) ? wd : rf[ra1];
    always @(posedge clk) begin
        if(we && wa != 0)
            rf[wa] <= wd;
    end                               
endmodule
