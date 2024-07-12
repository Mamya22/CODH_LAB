`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/19 16:08:05
// Design Name: 
// Module Name: ALU
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


module ALU(
    input [31:0] src0, src1,
    input [3:0] op,
    output reg [31:0] res
    );
    wire signed [31:0] su0, su1;
    assign su0 = src0;
    assign su1 = src1;
    always @(*) begin
        case (op)
            4'd0: res = src0 + src1; 
            4'd1: res = src0 - src1; 
            4'd2: res = su0 < su1;
            4'd3: res = src0 < src1; 
            4'd4: res = src0 & src1; 
            4'd5: res = src0 | src1; 
            4'd6: res = ~(src0 | src1); 
            4'd7: res = src0 ^ src1; 
            4'd8: res = src0 << src1[4:0]; 
            4'd9: res = src0 >> src1[4:0]; 
            4'd10: res = src0 >>> src1[4:0]; 
            4'd11: res = src1; 
            default: res = 0;
        endcase
    end
endmodule
