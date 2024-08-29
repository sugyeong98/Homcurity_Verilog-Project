`timescale 1ns / 1ps        // 1ns = #�� ��������� ����
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 11:24:11
// Design Name: 
// Module Name: tb_shift_register_SISO_Nbits_n
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

// �׽�Ʈ ��ġ �ڵ� 
module tb_shift_register_SISO_Nbits_n();
        
        reg clk, reset_p;                   // �Է��� reg ����
        reg d;                                  
        wire q;                                // ����� wire ����     
        
        parameter data = 4'b1010;           // ���� �Է��� ���ϴ� ������ ��
        
        shift_register_SISO_Nbit_n #(.N(4)) DUT( 
                .clk(clk), .reset_p(reset_p), 
                .d(d),
                .q(q));
                
        initial begin           // ó�� �ִ� ��(���� Ȱ��ȭ)
            clk = 0;
            reset_p = 1;
            d = data[0];
        end
        
        always #5 clk = ~clk;       // sensitivity list�� ������ ���� �ݺ���(#���� ���ڸ�ŭ ������)
                                              // 10ns �ֱ��� clk�� ������ֱ� ���� ����(�ֱ��� �ݸ�ŭ ���)
        integer i;                                      
        initial begin          // �ùķ��̼� ���� (���� �ùķ��̼� �� �ִ����)
            #10;
            reset_p = 0;
            for(i=0;i<4;i=i+1)begin
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
