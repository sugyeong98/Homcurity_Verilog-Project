`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/25 19:07:10
// Design Name: 
// Module Name: project1_module2
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

module ring_counter_mode(
        input clk, reset_p,
        input [3:0] btn,
        output reg [2:0] btn_mode_ring,
        output reg [2:0] led_mode);
        
        wire btn_mode_nedge;
        button_cntrl    btn_mode( .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode_pedge), .btn_nedge(btn_mode_nedge));
        
        // Mode ���� ��ư
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) btn_mode_ring = 3'b001;
                else if(btn_mode_nedge)begin
                    if(btn_mode_ring == 3'b100) btn_mode_ring = 3'b001; 
                    else btn_mode_ring = {btn_mode_ring[2:0], 1'b0};
                end
        end
        
        // Mode ���濡 ���� Mode Ȯ�ο� led Ȱ��ȭ 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) led_mode = 3'b001;
                else if(btn_mode_nedge)begin
                    if(led_mode == 3'b100) led_mode = 3'b001; 
                    else led_mode = {led_mode[2:0], 1'b0};
                end
        end
endmodule               
        
 //loadable Watch(Upgrade Version)
 //��尡 ����Ǿ ����ȭ�Ǿ �ð��� ���缭 �帥��
module loadable_watch_project(
        input clk, reset_p,        
        input [3:0] btn,
        output reg [15:0] value);         
    
        wire set_watch;          // 1�̸�(������) set , 0�̸� watch
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire watch_load_en, set_load_en;
      
         //��ư ��������� �ο� (ä�͸� ���� �ذ�)
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_mode_set_watch));                  
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min));
                
        // ��� ���� ��ư ��� ���� 
        T_flip_flop_p   t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode_set_watch), .q(set_watch));
        
        // �ð� ����ȭ(load)
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(set_watch), .n_edge(watch_load_en), .p_edge(set_load_en));
        
        // ��忡 ���� ���� �� ���� ���� 
        assign  inc_sec =  set_watch ? btn_sec : clk_sec;        // set ��忡���� �� ����, watch��忡���� �ð���
        assign  inc_min = set_watch ? btn_min : clk_min;        // set ��忡���� �� ����, watch��忡���� �ð���
        
        // �ֱ� ����
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));         // 1s   
        clock_div_60    min_clk( .clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));        // 1min 
       
        // loadable 60�� ī���� 
        loadable_counter_bcd_60 sec_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(watch_load_en),
            .load_bcd1(set_sec_1), .load_bcd10(set_sec_10),
            .bcd1(watch_sec_1), .bcd10(watch_sec_10));    
        loadable_counter_bcd_60 min_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(watch_load_en),
            .load_bcd1(set_min_1), .load_bcd10(set_min_10),
            .bcd1(watch_min_1), .bcd10(watch_min_10));
        loadable_counter_bcd_60 sec_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_sec), .load_enable(set_load_en),
            .load_bcd1(watch_sec_1), .load_bcd10(watch_sec_10),
            .bcd1(set_sec_1), .bcd10(set_sec_10));    
        loadable_counter_bcd_60 min_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_min), .load_enable(set_load_en),
            .load_bcd1(watch_min_1), .load_bcd10(watch_min_10),
            .bcd1(set_min_1), .bcd10(set_min_10));     
                
             wire [3:0] watch_sec_1,watch_sec_10, watch_min_1, watch_min_10;
             wire [3:0] set_sec_1,set_sec_10, set_min_1, set_min_10;
             wire [15:0] watch_value, set_value;  

            assign watch_value = {watch_min_10, watch_min_1, watch_sec_10, watch_sec_1};
            assign set_value = {set_min_10, set_min_1, set_sec_10, set_sec_1};
            
            always @(posedge clk or posedge reset_p)begin
                    if(reset_p) value = 0;
                    else begin
                         if(set_watch) value = set_value;
                         else value = watch_value;
                    end    
            end
            
endmodule


// STOP watch (start, stop, lap, clear)
module  stop_watch_project(
        input   clk, reset_p,
        input   [3:0] btn,
        output reg [15:0] value,
        output  led_start, led_lap);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec_1, sec_10, min_1, min_10;
        wire clk_start;
        wire start_stop; 
        reg lap;
        wire reset_start;
        
        // �ý��� ���� ��ư / Ŭ���� ��ư �з�
        assign reset_start = reset_p | btn_clear;
        // start / stop ��ư ���� �� ���� 
        assign clk_start = start_stop ? clk : 0;
        
        // �ֱ� ���� 
        clock_div_100   usec_clk( .clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        clock_div_60      min_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   // 1min 
        
        // ������ ��ư ��� �ο�(ä�͸� ���� �ذ�) 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start));   
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_lap));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_clear));
        
        // start, stop ��� ��� ���� + led on/off 
        T_flip_flop_p  t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
        assign  led_start = start_stop;
         
        // lap ��� ����(lap ���� / Ŭ���� ��ư ���� ����) 
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) lap = 0;
                else begin
                        if(btn_lap) lap = ~lap;     // lap ��� 
                        else if(btn_clear) lap = 0;
               end
        end   
        // lap ��� ����
        assign  led_lap = lap;
        
        // clear����� �ִ� 60�� ī����
        counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec_1), .bcd10(sec_10));     
        counter_bcd_60_clear counter_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .clear(btn_clear), .bcd1(min_1), .bcd10(min_10));
        
        reg [15:0] lap_time;
        wire [15:0] cur_time;
        assign  cur_time = {min_10, min_1, sec_10, sec_1};      // ���� �ð� 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) lap_time = 0;
                else if(btn_lap) lap_time = cur_time;                    // lap ��ư�� ������ ���� �ð� ����
                else if(btn_clear) lap_time = 0; 
        end  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) value = 0;
                else begin
                        if(lap) value = lap_time;
                        else value = cur_time;
                end
        end
endmodule

// cooktimer
module cook_timer_project(
        input clk, reset_p,
        input [4:0] btn,
        output reg [15:0] value,
        output led_alarm, led_start_timer, buzz);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] set_sec_1, set_sec_10, set_min_1, set_min_10;
        wire [3:0] cur_sec_1, cur_sec_10, cur_min_1, cur_min_10;
        wire dec_clk;
        reg start_set, alarm;
        wire [15:0] set_time, cur_time;
        
        // �ֱ� ���� 
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        
        // ��ư ��� �ο�
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start_timer)); 
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec_timer));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min_timer));
        button_cntrl  btn4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pedge(btn_alarm_off));
        
        // 60�� ��ī����(�ð� ���ÿ�)
        counter_bcd_60  counter_sec( .clk(clk), .reset_p(reset_p), .clk_time(btn_sec_timer), .bcd1(set_sec_1), .bcd10(set_sec_10));
        counter_bcd_60  counter_min( .clk(clk), .reset_p(reset_p), .clk_time(btn_min_timer), .bcd1(set_min_1), .bcd10(set_min_10));
        
        // 60�� �ٿ�ī����(Ÿ�̸� ��)
        loadable_downcounter_bcd_60 cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(btn_start_timer), 
                .load_bcd1(set_sec_1), .load_bcd10(set_sec_10), .bcd1(cur_sec_1), .bcd10(cur_sec_10), .dec_clk(dec_clk));   // �ʽð� ����ȭ
        loadable_downcounter_bcd_60 cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(btn_start_timer), 
                .load_bcd1(set_min_1), .load_bcd10(set_min_10), .bcd1(cur_min_1), .bcd10(cur_min_10));
        
        // start_set ���� 
        assign cur_time = { cur_min_10, cur_min_1, cur_sec_10, cur_sec_1 };
        assign set_time = { set_min_10, set_min_1, set_sec_10, set_sec_1 };

        always @(posedge clk or posedge reset_p)begin
               if(reset_p)begin
                       start_set = 0;
                       alarm = 0;
               end
               else begin
                       if(btn_start_timer)start_set = ~ start_set;
                       else if(cur_time == 0 && start_set)begin
                               start_set = 0;              // set ���� ���� 
                               alarm = 1;                   // �ð��� �ٵǸ� �˶��� ������ �ϹǷ�
                       end
                       else if(btn_alarm_off) alarm = 0;
               end
        end       
        
        // ��º� 
        assign buzz = alarm;
        assign led_alarm = alarm;
        assign led_start_timer = start_set;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) value = 0;
                else begin
                    if(start_set) value = cur_time;
                    else value = set_time;
                end    
        end
    endmodule
