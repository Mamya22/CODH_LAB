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
    output reg done,                  //done��ʾ����
    output reg [31:0] data0, count,    //data��ʾ��������ݣ� count��ʾ��Լ���˶��ٸ�����
    output reg [9:0] point            //index��ʾ������ݵ��±�
  );
  //˼·�� �ȶԿ���ȥ����
  //s0��ʾ��ʼ��s1��ʾȡ��һ������s2��ʾȡ�ڶ�������s3��ʾ���һ������s4��ʾ��ڶ�������s
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
  //״̬�ı�
  always @(posedge clk)
  begin
    if(!rstn)
      current_state <= s0;
    else if(!done && ps)
      current_state <= next_state;
    else
      current_state <= current_state;
  end
  //next_state�仯��s1��ʾȡ��һ������s2��ʾȡ�ڶ��������Դ�С�����ж�
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
          next_state = s0;  //��ʾҪ������һ��ѭ��
        else
          next_state = s6;                  //�����������ȡ������һ�����֣���s2
      end
      s3:
        next_state = s4;                       //s3��ʾ���һ������������Ϊs4����ڶ�����
      s4:begin
        if(point == ps)
          next_state = s0;       //�жϱ���ѭ���Ƿ���������������s1
        else
          next_state = s5;                   //����
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
        src0 <= data0;   //src0��ʾ��һ����
      s2:
        src1 <= data0;   //src1��ʾ�ڶ�����
      s5:
        src0 <= src1;    //s6�ѵڶ�������ֵ����һ������ʾ������һ�αȽ�
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
          // point <= point + 1;    //point��һ����һ������ȡ��һ����
          // if(ps == 0) point <= 0;
        end
        s2:begin
          // if((!res[0] && up)||(res[0] && !up))begin    //�ó���С�ȽϵĽ��ۣ����ж��Ƿ���Ҫд��
          //   we <= 1;
          //   point <= point - 1;                       //��ʾҪд���һ������
          //   data3 <= src1;                            //data3��ʾĿ������
          // end
          // else begin
          //   if(point == ps)begin                       //����ѭ������
          //     ps <= ps - 1;                           // ps - 1
          //     point <= 0;                             // point��0��ʼ
          //   end
          //   else
          //     point <= point + 1;                    //���������һ������
          // end
        end
        s7:
        begin
          if((!res[0] && up)||(res[0] && !up))begin    //�ó���С�ȽϵĽ��ۣ����ж��Ƿ���Ҫд��
            we <= 1;
            point <= point - 1;                       //��ʾҪд���һ������
            data3 <= src1;                            //data3��ʾĿ������
          end
          else begin
            if(point == ps)begin                       //����ѭ������
              ps <= ps - 1;                           // ps - 1
              point <= 0;                             // point��0��ʼ
            end
            else
              point <= point + 1;                    //���������һ������
          end
        end
        s3:begin
          point <= point + 1;                             //����һ������
          data3 <= src0;
        end
        s4:begin
          we <= 0;                                        //s4֮����꣬we��Ϊ0
          if(point == ps)begin                           //�жϱ���ѭ���Ƿ����
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
