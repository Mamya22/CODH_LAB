`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/20 21:01:34
// Design Name: 
// Module Name: debounce
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


module debounce(
    input clk, rstn, start,
    output reg ready
    );
    reg [19:0] count;
    reg we;
    always @(posedge clk) begin
        if(!rstn) begin 
            count <= 0;
            ready <= 0;
            we <= 0;
        end
        else if(start && !we) begin
            count <= count + 1;      
            if(count == 20'd1000000)begin
                ready <= 1;  
                we <= 1;              
            end
        end
        // else if(we && start)
        //     count <= 0;
        // else if (!start && we) begin
        //     count <= count + 1;    
        //     ready <= 1;
        //     we <= 0;  
        //     // if(count == 20'd1000000)begin
        //     //     ready <= 1;  
        //     //     we <= 0;              
        //     // end
        // end
        else if(!start) begin
            we <= 0;    
            count <= 0;        
        end

        else begin 
            ready <= 0;
            count <= 0;
        end
    end
endmodule
