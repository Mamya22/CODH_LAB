`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/14 19:36:43
// Design Name: 
// Module Name: bram_sim
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


module bram_sim(

    );
    reg clk;
    // reg cpu_inst_en;
    // reg [3:0]cpu_inst_we;
    reg [16:0] addr ;
    initial
begin
    // $dumpfile("dump.vcd");
    // $dumpvars;
    clk = 1'b0;
    addr = 0;
    // resetn = 1'b0;
    // #2000;
    // resetn = 1'b1;
end
always #5 clk=~clk;
always @(posedge clk) begin
    addr <= addr + 1;
end
wire [31:0] mem_r_data ;
inst_ram inst_ram
(
    .clka  (clk            ),   
    .ena   (1'b1       ),
    .wea   ( 4'd0     ),   //3:0
    .addra (addr),   //17:0
    .dina  (   32'd0  ),   //31:0
    .douta (mem_r_data     )    //31:0
);
endmodule
