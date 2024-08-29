`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/24 16:34:25
// Design Name: 
// Module Name: exam02_sequential_logic
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

// D - flipflop �ϰ����� ����
module D_flip_flop_n(
        input d,
        input clk, reset_p, enable,
        output reg q);
                                                                                              // �ϰ����� ���� + ���±��
        always @(negedge clk or posedge reset_p)begin              // �ϰ�����(negative edge) , ��¿���(positive edge)
                if(reset_p) q = 0;
                else if(enable) q = d;
        end
        
endmodule

// D - flipflop ��¿��� ����
module D_flip_flop_p(
        input d,
        input clk, reset_p, enable,
        output reg q);
                                                                                               // ��¿��� ���� + ���±��
        always @(posedge clk or posedge reset_p)begin              // �ϰ�����(negative edge) , ��¿���(positive edge)
                if(reset_p) q = 0;                                                      // reset = 1 , ������ 0 ���
                else if(enable) q = d;                                                // enable = 1, flipflop ���� / = 0, �Һ�   
        end
endmodule

// T - flipflop �ϰ�����
module T_flip_flop_n(
        input clk, reset_p,
        input t,
        output reg q);
        
        always  @(negedge clk or posedge reset_p)begin
                if(reset_p) q = 0;
                else begin
                        if(t) q = ~q;                   // toggle 
                        else q = q;                    // latch             
               end
       end   

endmodule

// T-flipflop ��¿���
module T_flip_flop_p(
        input clk, reset_p,
        input t,
        output reg q);
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) q = 0;
                else begin
                        if(t) q = ~q;                   // toggle 
                        else q = q;                    // latch             
               end
       end   

endmodule

// �񵿱�� up ī����
module up_counter_asyc(
        input clk, reset_p,
        output [3:0] count);            // reg�� �ƴ� wire�̹Ƿ� 0���� �ʱ�ȭ�ϸ� �ȵ�
        // �ʱ�ȭ�ϴ� ������ �������� �����Ͽ� ����ϴ� ��� �𸣴� ���� ��µǱ� ����        
        // reset ����� �ִ� ����! �������� �ʱ�ȭ��Ű�� ���ؼ�!
        T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
        T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
        T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
        T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
        
endmodule

//�񵿱�� down ī����
module down_counter_asyc(
        input clk, reset_p,
        output [3:0] count);
        
        T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
        T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
        T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
        T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
        
endmodule
// �񵿱���� ������ : PDT ������ �߰��߰� ���ʿ��� ���� ���

//����� upī����
// T - flip flop �� ����ϸ� ��ȿ�������� ���ͼ� D ��� 
//��¿���
module upcounter_p(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop�� ���  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count +1;
        end        
endmodule
//�ϰ�����
module upcounter_n(
        input clk, reset_p, enable,
        output reg [3:0] count);
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count +1;
        end        
endmodule

//����� down ī����
//��¿���
module downcounter_p(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop�� ���  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count - 1;
        end        
endmodule

//�ϰ�����
module downcounter_n(
        input clk, reset_p, enable,
        output reg [3:0] count);                // D flip-flop�� ���  
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else if(enable) count = count - 1;
        end        
endmodule

//����� BCD ī���� 
//up-counter
module bcd_upcounter_p(
        input clk,reset_p,
        output reg [3:0] count);

        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;                      // �ʱⰪ ���� 
                else begin
                        if(count >= 9) count = 0;        // Ȥ�ö� 10�� �Ǵ� ������ ���� �� ����
                        else count = count + 1;         
                end
        end
endmodule        

//down-counter
module bcd_downcounter_p(
        input clk, reset_p,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 9;
                else begin
                        if(count >= 10 | count == 0) count = 9; // count >= 10 : ���� �ϳ� 10���� ū ���� ���ð�� ��� 
                        else count = count -1;
                end
        end
endmodule

//4��Ʈ up/down counter
module updowncounter_p(
        input clk, reset_p,
        input up_down,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) count = 0;
                else begin
                        if(up_down) begin                           // up_down = 1 �̸� ����
                            count = count + 1;                      
                        end
                        else begin                                      //  up_down = 0 �̸� ����
                            count = count - 1;                  
                        end
                end
        end
endmodule

// BCD up/down counter
module bcd_updowncounter_p(
        input clk, reset_p,
        input up_down,
        output reg[3:0] count);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    if(reset_p) count = 0;                                          // up_down = 1 �̸� 0���� �ʱ�ȭ
                    else count = 9;                                                   // up_down = 0 �̸� 9�� �ʱ�ȭ   
                end
                   
                else begin
                        if(up_down) begin                                            // up_down = 1 �̸� ����
                            if(count >= 9) count = 0;
                            else count = count + 1;                      
                        end
                        else begin
                            if(count == 0 | count >= 10) count = 9;           //  up_down = 0 �̸� ����
                            else count = count - 1;                  
                        end
                end
        end
endmodule

//Ring counter
module ring_counter(
        input clk, reset_p,
        output  reg [3:0]   q);
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) q = 4'b0001;
                else begin
                        if(q == 4'b1000) q = 4'b0001;
                        else q[3:0] = {q[2:0], 1'b0};
                end
       end
       // �⺻ Ʋ                    
//        always @(posedge clk or posedge reset_p)begin
//                if(reset_p)q =4'b0001;
//                else begin
//                    case(q)
//                        4'b0001: q = 4'b0010;
//                        4'b0010: q = 4'b0100;
//                        4'b0100: q = 4'b1000;
//                        4'b1000: q = 4'b0001;
//                        default: q = 4'b0001; 
//                    endcase
//                end
//        end
endmodule                

// Ring counter led
module ring_counter_led(
        input clk, reset_p,
        output reg [15:0] led);
        
        reg [24:0]  clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[24]), .n_edge(clk_div_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) led = 16'b0000_0000_0000_0001;
                else if(clk_div_nedge)begin
                    if(led == 16'b1000_0000_0000_0000) led = 16'b0000_0000_0000_0001; 
                    else led = {led[14:0], 1'b0};
                    //else led[15:0] = {led[14:0], 1b'0}; ���տ����� ����ؼ� shift ������ ��� ��� ����
                end
        end
endmodule



// T-flipflop Edge Detector (positive)
module edge_detector_p(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
                // ff_cur <= 0;
                // ff_old <= 0;
            end
            else begin      // else �� �ȿ����� ���Ľ� ������ �ƴ� �������� 
                ff_old = ff_cur;
                ff_cur = cp;            // blocking 
                // ff_cur <= cp;
                // ff_old <= ff_cur;    /non-blocking 
                // ���Կ����ڱ��� ������ ���� ���� ���� �� ���ʿ� �����Ѵ�. cp�� ff_cur ���� ���ϰ� �� ���� ���ʿ� ����
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 �϶��� 1�̰�, �������� 0�� LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 �϶� �ϰ����� �߻�
        
endmodule


// T-flipflop Edge Detector (negative)
module edge_detector_n(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(negedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
                // ff_cur <= 0;
                // ff_old <= 0;
            end
            else begin      // else �� �ȿ����� ���Ľ� ������ �ƴ� �������� 
                ff_old = ff_cur;
                ff_cur = cp;            // blocking 
                // ff_cur <= cp;
                // ff_old <= ff_cur;    /non-blocking 
                // ���Կ����ڱ��� ������ ���� ���� ���� �� ���ʿ� �����Ѵ�. cp�� ff_cur ���� ���ϰ� �� ���� ���ʿ� ����
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 �϶��� 1�̰�, �������� 0�� LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 �϶� �ϰ����� �߻�
        
endmodule

// memory
// 4bit register(�����Է� - �������) (Serial In - Serial Out)
module shift_register_SISO_n(
        input d,
        input clk, reset_p,
        output q);
        
        reg [3:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {d, siso_reg[3:1]};     // ���տ����ڸ� ����� shift
//                        siso_reg[3] <= d;
//                        siso_reg[2] <= siso_reg[3];
//                        siso_reg[1] <= siso_reg[2];
//                        siso_reg[0] <= siso_reg[1];         // non-blocking(���ʰ� �ѹ��� �����ϰ� �����ʰ��� ����/���Ľ�)
                end                     
        end
        assign q = siso_reg[0];
                        
endmodule

// nbit register(�����Է� - �������)
// 0����Ʈ ���� �Է� , 0����Ʈ ���� ��� 
//  data���� ��������Ʈ(LSB)���� ������
module shift_register_SISO_Nbit_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        output q);
        
        reg [N-1:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {d, siso_reg[N-1:1]};     // ���տ����ڸ� ����� shift
                end                     
        end
        assign q = siso_reg[0];       
endmodule

// data���� �ֻ�����Ʈ(MSB)���� ������
// �ֻ��� ��Ʈ ���� �Է�, ���� ��� 
module shift_register_SISO_Nbit_msb_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        output q);
        
        reg [N-1:0] siso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) siso_reg <= 0;
                else begin
                        siso_reg <= {siso_reg[N-2:0], d};     // ���տ����ڸ� ����� shift
                end                     
        end
        assign q = siso_reg[N-1];       
endmodule


// 4bits register ���Ժ���(Serial In - Parallel Out) 
module shift_register_SIPO_n( 
        input d,
        input clk, reset_p,
        input rd_en,
        output [3:0] q);
        
        reg [3:0] sipo_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) sipo_reg <= 0;
                else begin
                        sipo_reg <= {d, sipo_reg[3:1]};  
                end                     
        end
        
        assign q = rd_en ? 4'bz : sipo_reg;     // ����Ʈ ������Ƽ�� ��� ���ϰ� mux�� �̿��Ͽ� ����
                                                                // ������ Active Low
//        bufif0 (q[0]], sipo_reg[0], rd_en);     // �������� ����Ʈ ������Ƽ��(�Է�, ���, ���)
endmodule

// Nbits register ���Ժ���(Serial In - Parallel Out) 
module shift_register_SIPO_Nbit_n #(parameter N = 8)( 
        input d,
        input clk, reset_p,
        input rd_en,
        output [N-1:0] q);
        
        reg [N-1:0] sipo_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) sipo_reg <= 0;
                else begin
                        sipo_reg <= {d, sipo_reg[N-1:1]};  
                end                     
        end
        
        assign q = rd_en ? 'bz : sipo_reg;      // z = ���Ǵ���(�տ� ����θ� ��Ʈ���� ������� ���� z�� ä��)
endmodule


// 4bits register ��������(Parallel In - Serial Out)
module shift_register_PISO_n( 
        input [3:0] d,
        input clk, reset_p,
        input shift_load,               // shift = 1 , load = 0
        output q);
        
        reg [3:0] piso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) piso_reg <= 0;
                else begin
                       if(shift_load)begin
                            piso_reg <= {1'b0, piso_reg[3:1]};
                       end
                       else begin
                            piso_reg = d;
                       end  
                end                     
        end
        assign q = piso_reg[0];
endmodule

// Nbits register ��������(Parallel In - Serial Out)
module shift_register_PISO_Nbit_n #(parameter N = 8)( 
        input [N-1:0] d,
        input clk, reset_p,
        input shift_load,               // shift = 1 , load = 0
        output q);
        
        reg [N-1:0] piso_reg;
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) piso_reg <= 0;
                else begin
                       if(shift_load)begin
                            piso_reg <= {1'b0, piso_reg[N-1:1]};
                       end
                       else begin
                            piso_reg = d;
                       end  
                end                     
        end
        assign q = piso_reg[0];
endmodule

// 4bit register ���Ժ���(Parallel In - Parallel OUT)
module shift_register_PIPO_n(
         input [3:0] in_data,
        input clk, reset_p, wr_en, rd_en,
        output [3:0] out_data);
                     
        reg [3:0] register;                                                                                     
        always @(negedge clk or posedge reset_p)begin              
               if(reset_p) register = 0;
               else if(wr_en) register = in_data;      // wr_en 1�϶� register�� �Էµ����� ���� 
        end   
        
         assign out_data = rd_en ? register : 'bz;     
endmodule

// Nbit register ���Ժ���(Parallel In - Parallel OUT)
module shift_register_PIPO_Nbit_n #(parameter N = 8)(
        input [N-1:0] in_data,
        input clk, reset_p, wr_en, rd_en,
        output [N-1:0] out_data);
        
        reg [N-1:0] register;                                                                                     
        always @(negedge clk or posedge reset_p)begin              
                if(reset_p) register = 0;
                else if(wr_en) register = in_data;      // wr_en 1�϶� register�� �Էµ����� ���� 
        end
        
        assign out_data = rd_en ? register : 'bz;      // ���Ǵ��� : ���� ����         
endmodule

// 1024���� 8��Ʈ sram
module sram_8bit_1024(
        input clk,
        input wr_en, rd_en,
        input [9:0] address,  // 1024���� �ּҸ� ����� ���� 10���� ��Ʈ�� ��������
        inout [7:0] data);      // input, output �Ѵ� ��밡��(������ ����� ����Ҷ��� �ٸ� �ϳ��� ����� ���ƾ���) 
        
        reg [7:0] memory [0:1023];  // memory �迭 ����
        
        always @(posedge clk)begin
                if(wr_en) memory[address] = data;       // memory�� address ��° �ּҿ� data �� ���� 
        end
        
        assign data = rd_en ? memory[address] : 'bz;
        
endmodule