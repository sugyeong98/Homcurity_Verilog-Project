`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/17 10:12:04
// Design Name: 
// Module Name: controller
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
// fnd
module fnd_cntrl(
        input clk, reset_p,
        input [15:0] value,
        output  [3:0] com,
        output  [7:0] seg_7);
        
        ring_counter_fnd  rc(.clk(clk), .reset_p(reset_p), .com(com));
        
        reg [3:0] hex_value;
        always @(posedge clk)begin
                case(com)
                    4'b1110 : hex_value = value[3:0];
                    4'b1101 : hex_value = value[7:4];
                    4'b1011 : hex_value = value[11:8];
                    4'b0111 : hex_value = value[15:12];
                endcase    
        end
        
        decoder_7seg(.hex_value(hex_value), .seg_7(seg_7));
        
endmodule
// button(ä�͸� ���� �ذ�)
module button_cntrl(
        input   clk, reset_p,
        input   btn,
        output  btn_pedge, btn_nedge);
        
        reg [20:0]  clk_div = 0;   
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));     // 16�� ��Ʈ�� 1.33ms
        
        reg debounced_btn;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)debounced_btn = 0;
                else if(clk_div_nedge)debounced_btn = btn;
        end
        
       edge_detector_p ed_btn(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge(btn_nedge), .p_edge(btn_pedge));                 
                
endmodule

// keypad(
module key_pad_cntrl(
        input clk, reset_p,
        input [3:0] row,
        output reg [3:0] col,                       
        output reg [3:0] key_value,               
        output reg key_valid);              // Ű�Է��� �߻����� �˸��� ���
        
        // ä�͸� �ذ�� (8ms)
        reg [19:0] clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        wire clk_8msec_p, clk_8msec_n;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n), .p_edge(clk_8msec_p));                 
              
        // ��ī����          
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)col =4'b0001;
                else if(clk_8msec_p && !key_valid)begin
                    case(col)
                        4'b0001: col = 4'b0010;
                        4'b0010: col = 4'b0100;
                        4'b0100: col = 4'b1000;
                        4'b1000: col = 4'b0001;
                        default: col = 4'b0001; 
                    endcase
                end
        end
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        key_value = 0;
                        key_valid = 0;
                end
                else begin
                        if(clk_8msec_n)begin
                            if(row)begin
                                key_valid = 1;
                                case({col, row})
                                    8'b0001_0001: key_value = 4'h0;
                                    8'b0001_0010: key_value = 4'h1;
                                    8'b0001_0100: key_value = 4'h2;
                                    8'b0001_1000: key_value = 4'h3;
                                    8'b0010_0001: key_value = 4'h4;
                                    8'b0010_0010: key_value = 4'h5;
                                    8'b0010_0100: key_value = 4'h6;
                                    8'b0010_1000: key_value = 4'h7;
                                    8'b0100_0001: key_value = 4'h8;
                                    8'b0100_0010: key_value = 4'h9;
                                    8'b0100_0100: key_value = 4'ha;
                                    8'b0100_1000: key_value = 4'hb;
                                    8'b1000_0001: key_value = 4'hc;
                                    8'b1000_0010: key_value = 4'hd;
                                    8'b1000_0100: key_value = 4'he;
                                    8'b1000_1000: key_value = 4'hf;    
                                endcase
                            end
                            else begin
                                key_valid = 0;
                                //key_value = 0;  // Ű���� ���� ���� ����� ���� 0���� ����  
                            end    
                        end
                end
        end
endmodule

// FSM ver. keypad(���� �迭)
module keypad_cntrl_FSM(
        input clk, reset_p,
        input [3:0] row,
        output reg [3:0] col,                       
        output reg [3:0] key_value,               
        output reg key_valid);   
        
        parameter SCAN0 =               5'b00001;
        parameter SCAN1 =               5'b00010;
        parameter SCAN2 =               5'b00100;
        parameter SCAN3 =               5'b01000;
        parameter KEY_PROCESS = 5'b10000;

        reg [19:0] clk_div;
        always @(posedge clk) clk_div = clk_div + 1;
        wire clk_8msec_n, clk_8msec_p;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n),.p_edge(clk_8msec_p));    
        
        reg [4:0] state, next_state;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)state = SCAN0;
                else if(clk_8msec_p)state = next_state;
        end
        
        always @* begin                 // � ������ ���ϸ� ����  
                case(state)
                        SCAN0 : begin
                                if(row == 0)next_state = SCAN1;
                                else next_state = KEY_PROCESS;
                        end
                        SCAN1 : begin
                                if(row == 0)next_state = SCAN2;
                                else next_state = KEY_PROCESS;
                        end
                        SCAN2 : begin
                                if(row == 0)next_state = SCAN3;
                                else next_state = KEY_PROCESS;
                        end
                        SCAN3 : begin
                                if(row == 0)next_state = SCAN0;
                                else next_state = KEY_PROCESS;
                        end
                        KEY_PROCESS : begin
                                if(row == 0)next_state = SCAN0;
                                else next_state = KEY_PROCESS;
                        end                        
                        default : next_state = SCAN0;
                endcase
        end
       
       always @(posedge clk or posedge reset_p)begin
           if(reset_p)begin
                key_value = 0;
                key_valid = 0;
                col = 0;
           end
           else if(clk_8msec_n)begin
                case(state)
                        SCAN0 : begin   col = 4'b0001;  key_valid = 0;  end
                        SCAN1 : begin   col = 4'b0010;  key_valid = 0;  end
                        SCAN2 : begin   col = 4'b0100;  key_valid = 0;  end
                        SCAN3 : begin   col = 4'b1000;  key_valid = 0;  end
                        KEY_PROCESS: begin
                                key_valid = 1;
                                case({col, row})
                                    8'b0001_0001: key_value = 4'h7; // 7 
                                    8'b0001_0010: key_value = 4'h4; // 4
                                    8'b0001_0100: key_value = 4'h1; // 1
                                    8'b0001_1000: key_value = 4'hc; // C
                                    8'b0010_0001: key_value = 4'h8; // 8
                                    8'b0010_0010: key_value = 4'h5; // 5
                                    8'b0010_0100: key_value = 4'h2; // 2
                                    8'b0010_1000: key_value = 4'h0; // 0
                                    8'b0100_0001: key_value = 4'h9; // 9
                                    8'b0100_0010: key_value = 4'h6; // 6
                                    8'b0100_0100: key_value = 4'h3; // 3
                                    8'b0100_1000: key_value = 4'hf; // F
                                    8'b1000_0001: key_value = 4'ha; // a
                                    8'b1000_0010: key_value = 4'hb; // b
                                    8'b1000_0100: key_value = 4'he; // E
                                    8'b1000_1000: key_value = 4'hd; // d   
                                endcase
                        end        
                endcase                
           end   
       end             
endmodule

// �½��� ����(dht11)
module dht11_cntrl(
        input clk, reset_p,
        inout dht11_data,
        output [15:0] led_debug,        // ���� state Ȯ�ο�
        output reg [7:0] humidity, temperature);
        
        parameter S_IDLE = 6'b00_0001; 
        parameter S_LOW_18MS = 6'b00_0010;
        parameter S_HIGH_20US = 6'b00_0100;
        parameter S_LOW_80US = 6'b00_1000;
        parameter S_HIGH_80US = 6'b01_0000;
        parameter S_READ_DATA = 6'b10_0000;
        
        parameter S_WAIT_PEDGE = 2'b01;
        parameter S_WAIT_NEDGE = 2'b10;
        
        reg [5:0] state, next_state;
        reg [1:0] read_state;
        
        assign led_debug[5:0] = state;
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
        
        // ����ũ�μ����� ������ ī��Ʈ 
        // enable �� 1�̸� ī��Ʈ ���� , 1�� �ƴϸ� 0���� ī��Ʈ �ʱ�ȭ 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = S_IDLE;
                else state = next_state;
        end
        
        // data�� in-out ���� �����Ƿ� reg ������ �� �� ���� 
        reg dht11_buffer;
        assign dht11_data = dht11_buffer;
        
        // ���� ������ 
        wire dht_nedge, dht_pedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .n_edge(dht_nedge), .p_edge(dht_pedge));
        
        reg [39:0] temp_data;
        reg [5:0] data_count;
        
        // ���� õ�̵��� ���� case��  
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = S_IDLE;
                        read_state = S_WAIT_PEDGE;
                        temp_data = 0;
                        data_count = 0;
                end
                else begin
                        case(state)
                            S_IDLE : begin      // �⺻����
                                    if(count_usec < 22'd3_000_000)begin     // 3�ʵ��� ��ٸ�
                                            count_usec_en = 1;    // usec ī��Ʈ ���� ����   
                                            dht11_buffer = 'bz;     // ���Ǵ��� ����ϸ� Ǯ���� ���� 1�� �ȴ�(Ǯ�������� �޷�����) 
                                    end
                                    else begin
                                            count_usec_en = 0;      // ī��Ʈ�� ���߰� �ʱ�ȭ ��Ŵ 
                                            next_state = S_LOW_18MS;    // ���� state�� õ��
                                    end         
                            end
                            S_LOW_18MS : begin      //  MCU���� ���۽�ȣ �߼ۻ��� 
                                    if(count_usec < 22'd20_000)begin        // �ּҰ��� 18ms �̹Ƿ� �����ְ� 20ms ���� 
                                            dht11_buffer = 0;       // ����� data �ʱ�ȭ 
                                            count_usec_en = 1;   // usec ī��Ʈ ���� 
                                    end       
                                    else begin      // 20ms ������ ���� 
                                            count_usec_en = 0;      // ī��Ʈ �ʱ�ȭ
                                            next_state = S_HIGH_20US;   // ���� ���·� õ�� 
                                            dht11_buffer = 'bz;     // data ���Ǵ��� �ο� -> Ǯ���� ���� 1
                                    end         
                            end
                            S_HIGH_20US : begin     // dht11���κ����� �����Ʈ ��ٸ�(20us)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1�� ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ�� 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge) begin     // ������ ������(�ϰ����� �߻�)
                                            count_usec_en = 0;
                                            next_state = S_LOW_80US;        // ���� ���·� õ�� 
                                    end        
                            end
                            S_LOW_80US : begin      // dht11 �����Ʈ ����(��¿��� �߻����� )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1�� ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ�� 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_pedge)begin              // �����ͽ�Ʈ�� ����Ȯ�������� ��Ȯ�� �ð��� �ƴ� ������ ��ٸ� 
                                            next_state = S_HIGH_80US;
                                            count_usec_en = 0;
                                    end
                            end
                            S_HIGH_80US : begin     // dht11 �����Ʈ �߻� Ȯ��(�ϰ����� �߻����� )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1�� ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ�� 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge)begin      
                                            next_state = S_READ_DATA;  
                                             count_usec_en = 0;
                                    end
                            end
                            S_READ_DATA : begin     // dht11���� ������ ��ȣ �߻� ����(��¿��� �ϰ����� 40�� �ݺ�)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1�� ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ�� 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                            data_count = 0;
                                            read_state = S_WAIT_PEDGE;
                                    end        
                                    else begin        
                                        case(read_state)
                                                S_WAIT_PEDGE : begin        // ��¿��� ��ٸ� ���� 
                                                        if(dht_pedge) read_state = S_WAIT_NEDGE;
                                                end
                                                S_WAIT_NEDGE :  begin       // �ϰ����� ��ٸ� ����
                                                        if(dht_nedge)begin
                                                                if(count_usec < 95)begin
                                                                        temp_data = {temp_data[38:0] , 1'b0};       // shift ��������(�� ����Ʈ)
                                                                end
                                                                else begin
                                                                        temp_data = {temp_data[38:0] , 1'b1};
                                                                end
                                                                data_count = data_count + 1;
                                                                read_state = S_WAIT_PEDGE;
                                                                count_usec_en = 0; 
                                                        end
                                                        else begin
                                                                count_usec_en = 1;
                                                        end
                                                end
                                        endcase 
                                        if(data_count >= 40)begin   // ������ �߼� ��Ʈ�� 40���� �Ǹ� ���� -> �⺻���·� õ�� 
                                                data_count = 0;
                                                next_state = S_IDLE;
                                                count_usec_en = 0;
                                                read_state = S_WAIT_PEDGE;
                                                // check_sum Ȯ��(���� ���� Ȯ��)
                                                if(temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8] == temp_data[7:0])begin
                                                    humidity = temp_data[39:32];
                                                    temperature = temp_data[23:16];
                                                end    
                                        end 
                                    end          
                                end
                        endcase
                end        
        end
endmodule

// ���� �Ÿ� ������(HC-SR04)
module  SR04_cntrl(
        input clk, reset_p,
        input echo,
        output reg trig,
        output [15:0] led_debug,
        output reg [21:0] distance_cm);
        
        reg [21:0] distance_cm;
        parameter S_IDLE = 3'b001; 
        parameter S_TRIG = 3'b010;
        parameter S_ECHO = 3'b100;

        // state ���� 
        reg [2:0] state, next_state;
        assign led_debug[3:0] = state;      // state Ȯ�ο� led 
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
        
        // ������ ������� �ʰ� 58���ַ� cm ����ϱ�
        reg cnt_en; 
        wire [11:0] cm;     
        clock_div_58(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec), .cnt_en(cnt_en), .cm(cm));
        
        // 1us¥�� ī����
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) begin
                    count_usec = 0;
                end    
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        // ECHO ī����
        reg[16:0] count_echo;
        reg count_echo_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) begin
                    count_echo = 0;
                end    
                else if(clk_usec && count_echo_en) count_echo = count_echo + 1;
                else if(!count_echo_en) count_echo = 0;
        end
        
        // �ʱ� state ���� �� state �ѱ�� ����         
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = S_IDLE;
                else state = next_state;
        end
        
        // echo ���� ������ 
        wire echo_nedge, echo_pedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(echo), .n_edge(echo_nedge), .p_edge(echo_pedge));
        // FSM õ�̵��� ���� �� state�� �۵� ����        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = S_IDLE;
                        distance_cm = 0;
                        count_usec_en = 0;
                        count_echo_en = 0;
                        cnt_en = 0;
                        trig = 0;
                end
                else begin
                        case(state)
                            S_IDLE : begin      // �⺻����
                                    if(count_usec < 22'd3_000_000)begin     // (���� ��������) 3�ʵ��� ��ٸ�
                                            count_usec_en = 1;    // usec ī��Ʈ ���� ����   
                                    end
                                    else begin
                                            count_usec_en = 0;      // ī��Ʈ�� ���߰� �ʱ�ȭ ��Ŵ 
                                            next_state = S_TRIG;    // ���� state�� õ��
                                    end         
                            end
                            S_TRIG : begin      // trigger �ܰ�
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1�� ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ��(��ſ���)
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(count_usec < 22'd10)begin
                                            trig = 1;                       // trigger �߻� 
                                            count_usec_en = 1;   // usec ī��Ʈ ���� 
                                    end       
                                    else begin   // 10us ���
                                            count_usec_en = 0;      // ī��Ʈ ���� �� �ʱ�ȭ
                                            trig = 0;                       // trigger ����(10us)
                                            next_state = S_ECHO;   // ���� ���·� õ�� 
                                    end         
                            end
                            S_ECHO : begin      // echo pulse �ܰ�
                                        count_usec_en = 1;
                                        if(count_usec > 22'd36_000)begin   // 36ms ���� ��ٷȴµ� ������ �ȿ��� �⺻���·� õ��(��ſ���)
                                                next_state = S_IDLE;
                                                count_usec_en = 0;
                                        end
                                        else begin
                                            if(echo_pedge)begin     // echo ��¿��� �߻��� 
                                                    cnt_en = 1;
                                                    //count_echo_en = 1;  // echo ī��Ʈ ���� 
                                            end
                                            else if(echo_nedge)begin    // echo �ϰ����� �߻���
                                                    distance_cm <= cm;  // distance�� ī��Ʈ�� �Է� 
                                                    //count_echo_en <= 0;      // echo ī��Ʈ ���� �� �ʱ�ȭ
                                                    cnt_en <= 0; 
                                                    next_state <= S_IDLE;   // ���� �⺻���·� õ��
                                                    count_usec_en <= 0;
                                            end
                                        end    
                                end    
                        endcase
                end        
        end
        
// negative slack������ ���� �����⸦ ������� �ʰ� lut�� ����ϴ� ���1          
//        always @(posedge clk or posedge reset_p)begin
//                if(reset_p) distance_cm =0;
//                else begin
//                        if(distance < 174) distance_cm = 2;
//                        else if(distance < 232) distance_cm = 3;
//                        else if(distance < 290) distance_cm = 4;
//                        else if(distance < 348) distance_cm = 5;
//                        else if(distance < 406) distance_cm = 6;
//                        else if(distance < 464) distance_cm = 7;
//                        else if(distance < 522) distance_cm = 8;
//                        else if(distance < 580) distance_cm = 9;
//                        else if(distance < 638) distance_cm = 10;
//                        else if(distance < 696) distance_cm = 11;
//                        else if(distance < 754) distance_cm = 12;
//                        else if(distance < 812) distance_cm = 13;
//                        else if(distance < 870) distance_cm = 14;
//                        else if(distance < 928) distance_cm = 15;
//                        else if(distance < 986) distance_cm = 16;
//                        else distance_cm = 17;
//                end
//        end
endmodule


module pwm_100step(
        input clk, reset_p,
        input [6:0] duty,
        output pwm);
        
        parameter   sys_clk_freq = 100_000_000;  // 100MHz
        parameter   pwm_freq = 10_000;
        parameter   duty_step = 100;
        parameter   temp = sys_clk_freq / duty_step / pwm_freq;
        parameter   temp_half = temp / 2;
        
        integer cnt_sysclk;     // �����Ǵ� ��Ʈ���� ������ �ٲ� �ʿ����
        reg [6:0] cnt_duty;
        wire pwm_freqX100, pwm_freqX100_nedge;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign pwm_freqX100 = (cnt_sysclk < temp_half) ? 0 : 1; 
        
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX100), .n_edge(pwm_freqX100_nedge)); 
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_duty = 0;
                else if(pwm_freqX100_nedge)begin
                        if(cnt_duty >= 99) cnt_duty = 0;
                        else cnt_duty = cnt_duty + 1;
                end
        end
//        always @(posedge clk or posedge reset_p)begin
//                if(reset_p)cnt = 0;
//                else if(clk_div_100_nedge)begin
//                    cnt = cnt + 1;
//                end
//        end

        assign pwm = (cnt_duty < duty) ? 1 : 0;      // duty rate
        
endmodule


module pwm_Nstep_freq
 #(
        parameter   sys_clk_freq = 100_000_000,  // 100MHz
        parameter   pwm_freq = 10_000,
        parameter   duty_step = 100,
        parameter   temp = sys_clk_freq / duty_step / pwm_freq,
        parameter   temp_half = temp / 2)
(
        input clk, reset_p,
        input [31:0] duty,
        output pwm);
        
        integer cnt_sysclk;     // �����Ǵ� ��Ʈ���� ������ �ٲ� �ʿ����
        integer cnt_duty;
        wire clk_freqXstep, clk_freqXstep_nedge;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_freqXstep = (cnt_sysclk < temp_half) ? 0 : 1; 
        
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_freqXstep), .n_edge(clk_freqXstep_nedge)); 
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_duty = 0;
                else if(clk_freqXstep_nedge)begin
                        if(cnt_duty >= (duty_step - 1)) cnt_duty = 0;
                        else cnt_duty = cnt_duty + 1;
                end
        end
        
        assign pwm = (cnt_duty < duty) ? 1 : 0;      // duty rate
        
endmodule

/////////////////////////////////////////////////////////////
// I2C �������� 
module I2C_master(
        input clk, reset_p,
        input [6:0] addr,   // �ּ�
        input rd_wr,        // �а� ����
        input [7:0] data,   // data
        input comm_go,  // ��ŸƮ ��ȣ
        output reg scl, sda,
        output reg [15:0] led);
        
        parameter IDLE                      = 7'b000_0001;
        parameter COMM_START    = 7'b000_0010;
        parameter SEND_ADDR       = 7'b000_0100;
        parameter RD_ACK               = 7'b000_1000;
        parameter SEND_DATA        = 7'b001_0000;
        parameter SCL_STOP           = 7'b010_0001;
        parameter COMM_STOP       = 7'b100_0001;
        
        wire [7:0] addr_rw;
        assign addr_rw = {addr, rd_wr};
        
        // 10usec LCD
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us         
        
        reg [2:0] count_usec5;
        reg scl_en;     // 1�� �Ǿ�� scl ����
        always  @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    count_usec5 = 0;
                    scl = 1;        // IDLE ���¿����� scl = 1
            end
            else if(scl_en)begin
                    if(clk_usec)begin
                            if(count_usec5 >= 4) begin
                            count_usec5 = 0;
                            scl = ~scl;
                            end
                            else count_usec5  = count_usec5 + 1;   
                    end 
            end
            else if(!scl_en)begin
                    scl = 1;
                    count_usec5 = 0;
            end
        end
        
        wire scl_nedge, scl_pedge, comm_go_pedge;
        edge_detector_n scl_edge(.clk(clk), .reset_p(reset_p), .cp(scl), .n_edge(scl_nedge), .p_edge(scl_pedge));
        edge_detector_n comm_edge(.clk(clk), .reset_p(reset_p), .cp(comm_go), .p_edge(comm_go_pedge));
        
        reg [6:0] state, next_state;
        always  @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        // FSM
        reg [2:0] cnt_bit;
        reg stop_flag;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        scl_en = 0;
                        sda = 1;        // IDLE ���׿��� sda, scl 1
                        cnt_bit = 7;        // MSB
                        stop_flag = 0;
                end
                else begin
                        case(state)
                            IDLE : begin
                                scl_en = 0;
                                sda = 1;
                                if(comm_go_pedge) next_state = COMM_START;
                            end
                            COMM_START : begin
                                sda = 0;
                                scl_en = 1;
                                next_state = SEND_ADDR;
                            end
                            SEND_ADDR : begin
                                if(scl_nedge) sda = addr_rw[cnt_bit];
                                if(scl_pedge)begin
                                    if(cnt_bit == 0)begin
                                        cnt_bit = 7;
                                        next_state = RD_ACK;
                                    end    
                                    else cnt_bit = cnt_bit - 1;
                                end    
                            end
                            RD_ACK : begin      // ACK ���� ����
                                if(scl_nedge) sda = 'bz;        // ���Ǵ��� ������� ����� ������
                                else if(scl_pedge)begin         // one-clock ����
                                    if(stop_flag)begin
                                        stop_flag = 0;
                                        next_state = SCL_STOP;
                                    end
                                    else begin
                                        stop_flag = 1;
                                        next_state = SEND_DATA;
                                    end
                                end    
                            end
                            SEND_DATA : begin
                                if(scl_nedge) sda = data[cnt_bit];
                                if(scl_pedge)begin
                                    if(cnt_bit == 0)begin
                                        cnt_bit = 7;
                                        next_state = RD_ACK;
                                    end    
                                    else cnt_bit = cnt_bit - 1;
                                end    
                            end
                            SCL_STOP : begin
                                if(scl_nedge) sda = 0;
                                else if(scl_pedge) next_state = COMM_STOP;
                            end
                            COMM_STOP : begin
                                if(count_usec5 >= 3)begin
                                        scl_en = 0;
                                        sda = 1;
                                        next_state = IDLE;
                                end
                            end
                        endcase     
                end
        end
endmodule


module i2c_lcd_send_byte(
        input clk, reset_p,
        input [6:0] addr,
        input [7:0] send_buffer,
        input rs, send,
        output scl, sda,
        output reg busy,
        output [15:0] led);
    
        parameter   IDLE                                                 = 6'b00_0001;      
        parameter   SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;      // 4bit = nibble
        parameter   SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
        parameter   SEND_LOW_NIBBLE_DISABLE = 6'b00_1000;
        parameter   SEND_LOW_NIBBLE_ENABLE  = 6'b01_0000;
        parameter   SEND_DISABLE                            = 6'b10_0000;
        
        reg [7:0] data;
        reg comm_go;
         I2C_master master( .clk(clk), .reset_p(reset_p),
                .addr(addr),
                .rd_wr(0),         
                .data(data),
                .comm_go(comm_go), 
                .scl(scl), .sda(sda),
                .led(led));
       
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us         
        
        wire send_pedge;
        edge_detector_n send_edge(.clk(clk), .reset_p(reset_p), .cp(send), .n_edge(send_nedge), .p_edge(send_pedge));
        
        // count
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        // FSM
        reg [5:0] state, next_state;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = IDLE;
                        busy = 0;
                        comm_go = 0;
                        count_usec_en = 0;
                        data = 0;
                end
                else begin
                        case(state)
                                IDLE : begin
                                       if(send_pedge)begin
                                            next_state = SEND_HIGH_NIBBLE_DISABLE;
                                            busy = 1;
                                       end
                                end
                                SEND_HIGH_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec ��ŭ ��ٸ�(������ ���۽ð�)
                                            data = {send_buffer[7:4], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_HIGH_NIBBLE_ENABLE;
                                        end
                                end
                                SEND_HIGH_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec ��ŭ ��ٸ�(������ ���۽ð�)
                                            data = {send_buffer[7:4], 3'b110, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_LOW_NIBBLE_DISABLE;
                                        end
                                end
                                SEND_LOW_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec ��ŭ ��ٸ�(������ ���۽ð�)
                                            data = {send_buffer[3:0], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_LOW_NIBBLE_ENABLE;
                                        end
                                end
                                SEND_LOW_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec ��ŭ ��ٸ�(������ ���۽ð�)
                                            data = {send_buffer[3:0], 3'b110, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = SEND_DISABLE;
                                        end
                                end
                                SEND_DISABLE : begin
                                        if(count_usec <= 22'd200)begin                  // 200usec ��ŭ ��ٸ�(������ ���۽ð�)
                                            data = {send_buffer[3:0], 3'b100, rs};       // [d7 d6 d5 d4], BT, EN, RW, RS
                                            comm_go = 1;
                                            count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            comm_go = 0;
                                            next_state = IDLE;
                                            busy = 0;
                                        end
                                end
                        endcase
                end
        end
endmodule

