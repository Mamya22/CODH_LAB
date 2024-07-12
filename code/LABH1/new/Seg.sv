`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/20 21:37:16
// Design Name: 
// Module Name: Seg
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


module Seg(
    input [3:0] d,
    output reg [6:0] yn
  );
  always @(*)
  begin
    case(d)
      4'b0000: yn=7'b0000001;
      4'b0001: yn=7'b1001111;
      4'b0010: yn=7'b0010010;
      4'b0011: yn=7'b0000110;
      4'b0100: yn=7'b1001100;
      4'b0101: yn=7'b0100100;
      4'b0110: yn=7'b0100000;
      4'b0111: yn=7'b0001111;
      4'b1000: yn=7'b0000000;
      4'b1001: yn=7'b0000100;
      4'b1010: yn=7'b0001000;
      4'b1011: yn=7'b1100000;
      4'b1100: yn=7'b0110001;
      4'b1101: yn=7'b1000010;
      4'b1110: yn=7'b0110000;
      4'b1111: yn=7'b0111000;
      default: yn=7'b0000000;
    endcase
  end
endmodule
