`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 14:07:15
// Design Name: 
// Module Name: tb_shift_register_SISO_NBits_msb_n
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

module tb_shift_register_SISO_NBits_msb_n();
       
        reg clk, reset_p;                   // 입력은 reg 선언
        reg d;                                  
        wire q;                                // 출력은 wire 선언     
        
        parameter data = 4'b1010;           // 내가 입력을 원하는 데이터 값
        
       shift_register_SISO_Nbit_msb_n #(.N(4)) DUT( 
                .d(d), .clk(clk), .reset_p(reset_p), .q(q));
     
        initial begin           // 처음 주는 값(리셋 활성화)
            clk = 0;
            reset_p = 1;
            d = data[3];
        end
        
        always #5 clk = ~clk;       // sensitivity list가 없으면 무한 반복문(#뒤의 숫자만큼 딜레이)
                                              // 10ns 주기의 clk을 만들어주기 위한 구문(주기의 반만큼 토글)
        integer i;                                      
        initial begin          // 시뮬레이션 진행 (원래 시뮬레이션 값 주던대로)
            #10;
            reset_p = 0;
            for(i=3;i>=0;i=i-1)begin
                 d = data[i];    #10;
            end
//            d = data[0];    #10;        // d값 주고 10ns clk
//            d = data[1];    #10;        // d값 주고 10ns clk
//            d = data[2];    #10;        // d값 주고 10ns clk
//            d = data[3];    #10;        // d값 주고 10ns clk
            #40;
            $finish;
        end

endmodule
