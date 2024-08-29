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
       
        reg clk, reset_p;                   // �Է��� reg ����
        reg d;                                  
        wire q;                                // ����� wire ����     
        
        parameter data = 4'b1010;           // ���� �Է��� ���ϴ� ������ ��
        
       shift_register_SISO_Nbit_msb_n #(.N(4)) DUT( 
                .d(d), .clk(clk), .reset_p(reset_p), .q(q));
     
        initial begin           // ó�� �ִ� ��(���� Ȱ��ȭ)
            clk = 0;
            reset_p = 1;
            d = data[3];
        end
        
        always #5 clk = ~clk;       // sensitivity list�� ������ ���� �ݺ���(#���� ���ڸ�ŭ ������)
                                              // 10ns �ֱ��� clk�� ������ֱ� ���� ����(�ֱ��� �ݸ�ŭ ���)
        integer i;                                      
        initial begin          // �ùķ��̼� ���� (���� �ùķ��̼� �� �ִ����)
            #10;
            reset_p = 0;
            for(i=3;i>=0;i=i-1)begin
                 d = data[i];    #10;
            end
//            d = data[0];    #10;        // d�� �ְ� 10ns clk
//            d = data[1];    #10;        // d�� �ְ� 10ns clk
//            d = data[2];    #10;        // d�� �ְ� 10ns clk
//            d = data[3];    #10;        // d�� �ְ� 10ns clk
            #40;
            $finish;
        end

endmodule
