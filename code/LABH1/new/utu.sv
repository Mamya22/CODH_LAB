`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/20 22:05:46
// Design Name: 
// Module Name: utu
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


module  utu(
    input clk,            //clk100mhz
    input rstn,           //cpu_resetn

    input [15:0] x,       //sw15-0
    input ent,            //btnc
    input del,            //btnl
    input step,           //btnr
    input pre,            //btnu
    input nxt,            //btnd

    //?????
    output [15:0] taddr,  //led15-0
    input [31:0] tdin,    //dut?????????????????
    output [31:0] tdout,  //?????dut??????
    output twe,	          //dutд???
    output [2:0] flag,    //led15-0??????????????????????
    output [7:0] an,      //an7-0
    output [6:0] seg,     //ca-cg

    output rst,
    output reg tclk       //dut's clk
  );


  reg x_p_flag;

  reg [15:0] rstn_r;

  wire clk_db;                //??????????????
  reg [19:0] cnt_clk_r;       //????????????????????
  reg [4:0] cnt_sw_db_r;
  reg [15:0] x_db_r, x_db_1r;
  reg xx_r, xx_1r;
  wire x_p;
  reg [3:0] x_hd_t;
  reg [31:0] tmp_r;           //?????????

  wire [4:0] btn;
  reg [4:0] cnt_btn_db_r;
  reg [4:0] btn_db_r, btn_db_1r;
  wire  pre_p,nxt_p, step_p,ent_p, del_p;

  reg [2:0] seg_sel_r;
  reg [31:0] disp_data_t;
  reg [7:0] an_t;
  reg [3:0] hd_t;
  reg [6:0] seg_t;

  reg [15:0] addr_r;               //?????????

  parameter SEG_COUNT_WIDTH = 4;   //?????????????λ??

  reg [SEG_COUNT_WIDTH-1:0] seg_count;
  wire is_open = (seg_count == 0);

  assign rst = rstn_r[15];         //??????????λ??????????Ч
  assign clk_db = cnt_clk_r[16];   //??????????????763Hz???????1.3ms??

  assign flag = seg_sel_r & {3{is_open}};
  assign an = an_t;
  assign seg = seg_t;


  assign tdout = tmp_r;      //?????????????????????
  assign taddr = addr_r;
  assign twe = ent_p;        //д????????????????



  assign btn ={pre, nxt, step, ent,del};

  assign x_p = xx_r ^ xx_1r;
  assign pre_p = btn_db_r[4] & ~ btn_db_1r[4];
  assign nxt_p = btn_db_r[3] & ~ btn_db_1r[3];
  assign step_p = btn_db_r[2] & ~ btn_db_1r[2];
  assign ent_p = btn_db_r[1] & ~ btn_db_1r[1];
  assign del_p = btn_db_r[0] & ~ btn_db_1r[0];


  ///////////////////////////////////////////////
  //??λ??????????λ?????????????
  ///////////////////////////////////////////////

  always @(posedge clk, negedge rstn)
  begin
    if (~rstn)
      rstn_r <= 16'hFFFF;
    else
      rstn_r <= {rstn_r[14:0], 1'b0};
  end


  ///////////////////////////////////////////////
  //?????
  ///////////////////////////////////////////////

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      cnt_clk_r <= 20'h0;
    else
      cnt_clk_r <= cnt_clk_r + 20'h1;
  end


  ///////////////////////////////////////////////
  //????sw?????
  ///////////////////////////////////////////////

  always @(posedge clk_db, posedge rst)
  begin
    if (rst)
      cnt_sw_db_r <= 5'h0;
    else if ((|(x ^ x_db_r)) & (~ cnt_sw_db_r[4]))
      cnt_sw_db_r <= cnt_sw_db_r + 5'h1;
    else
      cnt_sw_db_r <= 5'h0;
  end

  always@(posedge clk_db, posedge rst)
  begin
    if (rst)
    begin
      x_db_r <= x;
      x_db_1r <= x;
      xx_r <= 1'b0;
    end
    else if (cnt_sw_db_r[4])
    begin    //???????21ms?????
      x_db_r <= x;
      x_db_1r <= x_db_r;
      xx_r <= ~xx_r;		  //????x_p???
    end
  end

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      xx_1r <= 1'b0;
    else
      xx_1r <= xx_r;
  end


  ///////////////////////////////////////////////
  //?????????
  ///////////////////////////////////////////////

  always @*
  begin                //???????????
    case (x_db_r ^ x_db_1r )
      16'h0001:
        x_hd_t = 4'h0;
      16'h0002:
        x_hd_t = 4'h1;
      16'h0004:
        x_hd_t = 4'h2;
      16'h0008:
        x_hd_t = 4'h3;
      16'h0010:
        x_hd_t = 4'h4;
      16'h0020:
        x_hd_t = 4'h5;
      16'h0040:
        x_hd_t = 4'h6;
      16'h0080:
        x_hd_t = 4'h7;
      16'h0100:
        x_hd_t = 4'h8;
      16'h0200:
        x_hd_t = 4'h9;
      16'h0400:
        x_hd_t = 4'hA;
      16'h0800:
        x_hd_t = 4'hB;
      16'h1000:
        x_hd_t = 4'hC;
      16'h2000:
        x_hd_t = 4'hD;
      16'h4000:
        x_hd_t = 4'hE;
      16'h8000:
        x_hd_t = 4'hF;
      default:
        x_hd_t = 4'h0;
    endcase
  end

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      tmp_r <= 32'h0;
    else if (x_p)
      tmp_r <= {tmp_r[27:0], x_hd_t};      //x_hd_t + tmp_r << 4
    else if (del_p)
      tmp_r <= {{4{1'b0}}, tmp_r[31:4]};   //tmp_r >> 4
    else if (ent_p )                         //???????????????tmp_r
      tmp_r <= 32'h0;
    else if ((pre_p | nxt_p) & x_p_flag)
      tmp_r <= 32'h0;
  end


  ///////////////////////////////////////////////
  //???btn?????
  ///////////////////////////////////////////////

  always @(posedge clk_db, posedge rst)
  begin
    if (rst)
      cnt_btn_db_r <= 5'h0;
    else if ((|(btn ^ btn_db_r)) & (~ cnt_btn_db_r[4]))
      cnt_btn_db_r <= cnt_btn_db_r + 5'h1;
    else
      cnt_btn_db_r <= 5'h0;
  end

  always@(posedge clk_db, posedge rst)
  begin
    if (rst)
      btn_db_r <= btn;
    else if (cnt_btn_db_r[4])
      btn_db_r <= btn;
  end

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      btn_db_1r <= btn;
    else
      btn_db_1r <= btn_db_r;
  end


  ///////////////////////////////////////////////
  //addr???
  ///////////////////////////////////////////////

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      addr_r <= 16'h0000;
    else if (ent_p)
      addr_r <= 16'h0000;
    else if (pre_p)
      if (x_p_flag)
        addr_r <= tmp_r[15:0];
      else
        addr_r <= addr_r - 1;
    else if (nxt_p)
      if (x_p_flag)
        addr_r <= tmp_r[15:0];
      else
        addr_r <= addr_r + 1;
  end

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      x_p_flag <= 0;
    else if (x_p)
      x_p_flag <= 1;
    else if (pre_p| nxt_p)
      x_p_flag <= 0;
  end


  ///////////////////////////////////////////////
  //???????????????
  ///////////////////////////////////////////////



  always @(posedge clk, posedge rst)
  begin    //???????????????
    if (rst)
      seg_sel_r <= 3'b001;
    else if( pre_p| nxt_p| ent_p)
      seg_sel_r <= 3'b001;
    else if (x_p | del_p)
      seg_sel_r <= 3'b010;
  end

  always @(posedge clk)
  begin
    if(rst)
    begin
      seg_count <= 0;
    end
    else
    begin
      seg_count <= seg_count + 1;
    end
  end



  always @*
  begin
    case (seg_sel_r)
      3'b001:
        disp_data_t = tdin;             //???dut???????????
      3'b010:
        disp_data_t = tmp_r ;	        //????????????
      default:
        disp_data_t = tdin;
    endcase
  end


  ///////////////////////////////////////////////
  //???????????
  ///////////////////////////////////////////////

  always @(*)
  begin                  //????????
    an_t = 8'b1111_1111;
    hd_t = disp_data_t[3:0];
    if (&cnt_clk_r[16:15])         //????????
    case (cnt_clk_r[19:17])        //????????95Hz
      3'b000:
      begin
        an_t = 8'b1111_1110;
        hd_t = disp_data_t[3:0];
      end
      3'b001:
      begin
        an_t = 8'b1111_1101;
        hd_t = disp_data_t[7:4];
      end
      3'b010:
      begin
        an_t = 8'b1111_1011;
        hd_t = disp_data_t[11:8];
      end
      3'b011:
      begin
        an_t = 8'b1111_0111;
        hd_t = disp_data_t[15:12];
      end
      3'b100:
      begin
        an_t = 8'b1110_1111;
        hd_t = disp_data_t[19:16];
      end
      3'b101:
      begin
        an_t = 8'b1101_1111;
        hd_t = disp_data_t[23:20];
      end
      3'b110:
      begin
        an_t = 8'b1011_1111;
        hd_t = disp_data_t[27:24];
      end
      3'b111:
      begin
        an_t = 8'b0111_1111;
        hd_t = disp_data_t[31:28];
      end
      default:
      begin
        an_t = 8'b1111_1111;
        hd_t = 4'b0000;
      end
    endcase
  end

  always @ (*)
  begin    //7??????
    case(hd_t)
      4'b1111:
        seg_t = 7'b0111000;
      4'b1110:
        seg_t = 7'b0110000;
      4'b1101:
        seg_t = 7'b1000010;
      4'b1100:
        seg_t = 7'b0110001;
      4'b1011:
        seg_t = 7'b1100000;
      4'b1010:
        seg_t = 7'b0001000;
      4'b1001:
        seg_t = 7'b0001100;
      4'b1000:
        seg_t = 7'b0000000;
      4'b0111:
        seg_t = 7'b0001111;
      4'b0110:
        seg_t = 7'b0100000;
      4'b0101:
        seg_t = 7'b0100100;
      4'b0100:
        seg_t = 7'b1001100;
      4'b0011:
        seg_t = 7'b0000110;
      4'b0010:
        seg_t = 7'b0010010;
      4'b0001:
        seg_t = 7'b1001111;
      4'b0000:
        seg_t = 7'b0000001;
      default:
        seg_t = 7'b1111111;
    endcase
  end


  ///////////////////////////////////////////////
  //dut???????
  ///////////////////////////////////////////////

  always @(posedge clk, posedge rst)
  begin
    if (rst)
      tclk <= 1'b0;
    else if (step_p)
      tclk <= 1'b1;
    else
      tclk <= 1'b0;
  end

endmodule

