`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/20 20:16:35
// Design Name: 
// Module Name: TOP_Bubble
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


module TOP_Bubble(
    input up, start, prior, next, pre, nxt,
    input clk, rstn,
    output  done,                  //done表示结束
    output [9:0] index,
    output [7:0]        an,             //an7-0
    output [6:0]        seg             //ca-cg
    );
    wire [31:0]  count, data; 
    wire action, prior_f, next_f;
    debounce d_start(
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .ready(action)
    );
    debounce d_prior(
        .clk(clk),
        .rstn(rstn),
        .start(prior),
        .ready(prior_f)
    );
    debounce d_next(
        .clk(clk),
        .rstn(rstn),
        .start(next),
        .ready(next_f)
    );

    BubbleSort_ bubbleSort(
        .up(up),
        .start(action),
        .clk(clk),
        .rstn(rstn),
        .prior(prior_f),
        .next(next_f),
        .done(done),
        .data0(data),
        .count(count),
        .point(index)
    );
    wire [31:0]  tdout;
    reg [31:0] tdin;
    wire [11:0] alu_op;
    wire twe;
    wire rst, tclk;
    utu  utu_inst (
        .clk    (clk),
        .rstn   (rstn),
        .x      (x),
        .ent    (start),
        .del    (),
        .step   (),
        .pre    (pre),
        .nxt    (nxt),
        .taddr  (taddr),
        .tdin   (tdin),
        .tdout  (tdout),
        .twe    (twe),
        .flag   (),
        .an     (an),
        .seg    (seg),
        .rst    (rst),
        .tclk   (tclk)
    );
    wire [31:0] data_reg, count_reg;
    register# ( .WIDTH(32), .RST_VAL(0))
    register_inst_alu_out (
        .clk    (clk),
        .rst    (rst),
        .en     (taddr==16'h0&&1'b1),
        .d      (data),
        .q      (data_reg)
    );
    register# ( .WIDTH(32), .RST_VAL(0))
    register_inst_count_out (
        .clk    (clk),
        .rst    (rst),
        .en     (taddr==16'h1&&1'b1),
        .d      (count),
        .q      (count_reg)
    );
    always@(*) begin
        case(taddr)
        16'h0:   tdin = data;
        16'h1:   tdin = count;
        default: tdin = 0;
        endcase
    end

endmodule
