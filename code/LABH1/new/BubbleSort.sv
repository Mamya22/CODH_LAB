`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/03/19 16:49:58
// Design Name:
// Module Name: BubbleSort
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


module BubbleSort(
    input up, start, prior, next,
    input clk, rstn,
    output reg done,                  //done表示结束
    output reg [31:0] data0, count,    //data表示输出的数据， count表示大约用了多少个周期
    output reg [9:0] point            //index表示输出数据的下标
  );
  //思路： 先对开关去抖动
  //s0表示初始，s1表示取第一个数，s2表示取第二个数，s3表示存第一个数，s4表示存第二个数，s
  parameter  s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4,s5 = 3'd5, s6 = 3'd6, s7 = 3'd7;
  wire [31:0] res;
  reg [31:0] src0, src1;
  reg we;
  reg [9:0]  ps;
  // wire [31:0]  data0;
  reg [31:0] data3;
  DRAM_0 dram_0(
           .clk(clk),
           .we(we),
           .d(data3),
           .a(point),
           .spo(data0)
         );

  ALU alu(
        .src0(src0),
        .src1(src1),
        .op(4'd3),
        .res(res)
      );

  reg [2:0] current_state, next_state;
  //状态改变
  always @(posedge clk)
  begin
    if(!rstn)
      current_state <= s0;
    else if(!done && ps)
      current_state <= next_state;
    else
      current_state <= current_state;
  end
  //next_state变化，s1表示取第一个数，s2表示取第二个数，对大小进行判断
  always @(*)begin
    case (current_state)
      s0:
        next_state = s1;
      s1:
        next_state = s2;
      s2:begin
        if((!res[0] && up)||(res[0] && !up))
          next_state = s3;
        else if(point == ps)
          next_state = s0;  //表示要进行下一次循环
        else
          next_state = s6;                  //其余情况继续取接下来一个数字，即s2
      end
      s3:
        next_state = s4;                       //s3表示存第一个数，接下来为s4，存第二个数
      s4:begin
        if(point == ps)
          next_state = s0;       //判断本次循环是否结束，结束后进入s1
        else
          next_state = s5;                   //否则
      end
      s5:
        next_state = s2;
      s6:
        next_state = s2;
      default:
        next_state = s0;
    endcase
  end
  // assign src0 = (current_state == s1) ? data0 : ((current_state == s6) ? src1 :src0);
  // assign src1 = (current_state == s2) ? data0 : (current_state != s2 ? src1 : data0);
  always @(posedge clk)begin
    case (current_state)
      s1:
        src0 <= data0;   //src0表示第一个数
      s2:
        src1 <= data0;   //src1表示第二个数
      s5:
        src0 <= src1;    //s6把第二个数赋值给第一个，表示进行下一次比较
      default:
        ;
    endcase
  end
  always @(posedge clk)begin
    if(!rstn) begin
      point <= 0;
      ps <= 10'd1023;
      we <= 0;
      data3 <= 0;
    end
    if(!done) begin
      case (current_state)
        s0:begin
          point <= point + 1;
          if(ps == 0)
            point <= 0;
        end
        s1:begin
          // point <= point + 1;    //point加一，下一个周期取下一个数
          // if(ps == 0) point <= 0;
        end
        s2:begin
          // if((!res[0] && up)||(res[0] && !up))begin    //得出大小比较的结论，来判断是否需要写入
          //   we <= 1;
          //   point <= point - 1;                       //表示要写入第一个数据
          //   data3 <= src1;                            //data3表示目标数据
          // end
          // else begin
          //   if(point == ps)begin                       //本次循环结束
          //     ps <= ps - 1;                           // ps - 1
          //     point <= 0;                             // point从0开始
          //   end
          //   else
          //     point <= point + 1;                    //否则继续下一个数据
          // end
        end
        s7:
        begin
          if((!res[0] && up)||(res[0] && !up))begin    //得出大小比较的结论，来判断是否需要写入
            we <= 1;
            point <= point - 1;                       //表示要写入第一个数据
            data3 <= src1;                            //data3表示目标数据
          end
          else begin
            if(point == ps)begin                       //本次循环结束
              ps <= ps - 1;                           // ps - 1
              point <= 0;                             // point从0开始
            end
            else
              point <= point + 1;                    //否则继续下一个数据
          end
        end
        s3:begin
          point <= point + 1;                             //存下一个数据
          data3 <= src0;
        end
        s4:begin
          we <= 0;                                        //s4之后存完，we变为0
          if(point == ps)begin                           //判断本次循环是否结束
            ps <= ps - 1;
            point <= 0;
          end
          else
            point <= point + 1;
        end
        // s5: we <= 0;
        default:
          ;
      endcase
    end
    else if(done) begin
        // point <= 0;
        ps <= 10'd1023;
        we <= 0;
    end
    if(prior)
      point <= point - 1;
    else if(next)
      point <= point + 1;
    else if(start)
      point <= 0;
  end

  always @(posedge clk)
  begin
    if(!rstn)
      count <= 0;
    else if(!done)
      count <= count + 1;
    else if(start)
        count <= 0;
    else
      count <= count;
  end
  always @(posedge clk)
  begin
    if(!rstn)
      done <= 1;
    else if(start)
      done <= 0;
    else if(ps == 0 && we == 0)
      done <= 1;
  end
endmodule
