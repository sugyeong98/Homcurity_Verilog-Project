`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module i2c_lcd_send_byte(
        input clk, reset_p,
        input [6:0] addr,
        input [7:0] send_buffer,  //data
        input rs, send,
        output scl, sda,
        output reg busy,
        output [15:0] led );    // 5����Ʈ �����ϴ� ���� 1, ���� �𵨿���  busy�� 1�� ���� �ٸ� �����͸� �ٲ��� ���ϵ���

        parameter IDLE                                                         = 6'b00_0001;
        parameter SEND_HIGH_NIBBLE_DISABLE  = 6'b00_0010;
        parameter SEND_HIGH_NIBBLE_ENABLE    = 6'b00_0100;
        parameter SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
        parameter SEND_LOW_NIBBLE_ENABLE    = 6'b01_0000;
        parameter SEND_DISABLE                                 = 6'b10_0000;

        reg [7:0] data;
        reg comm_go;
        
        wire send_pedge;
        edge_detector_n        ed_go   (.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
        
        wire clk_usec;
        clock_div_100    usec_clock  (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec)); 
        
          reg [21:0] count_usec;  
          reg count_usec_e;           //enable 1�̸� ī��Ʈ, 0�̸� ����, 1�� �����ϰų�, clear �ǰų�(2���� ����)
            always @(negedge clk or posedge reset_p) begin
                        if(reset_p) count_usec = 0;
                        else if(clk_usec && count_usec_e)count_usec = count_usec+1;
                        else if(!count_usec_e) count_usec =0;
             end         
             
             reg [5:0] state, next_state;
             always @(negedge clk or posedge reset_p) begin
                    if(reset_p) state = IDLE;
                    else state = next_state;
             end
             
             always @(posedge clk or posedge reset_p)begin
                    if(reset_p) begin
                            next_state = IDLE;
                            busy =0;
                            comm_go =0;
                            data = 0;
                            count_usec_e =0;
                    end
                    else begin
                            case(state)
                                    IDLE :begin
                                            if(send_pedge) begin
                                                    next_state = SEND_HIGH_NIBBLE_DISABLE;
                                                    busy =1;
                                            end
                                    end
                                    
                                    SEND_HIGH_NIBBLE_DISABLE:begin
                                            if(count_usec <= 22'd200)begin // 8��Ʈ �����͸� ������ �ð����� ���
                                                    data = {send_buffer[7:4], 3'b100, rs};      // {[d7 d6 d5 d5], bt, e, rw, rs}
                                                    comm_go =1;    
                                                    count_usec_e =1;
                                            end
                                            else begin
                                                    comm_go =0;    
                                                    count_usec_e =0;
                                                    next_state = SEND_HIGH_NIBBLE_ENABLE;
                                            end
                                    end
                                    
                                    SEND_HIGH_NIBBLE_ENABLE:begin
                                              if(count_usec <= 22'd200)begin // 8��Ʈ �����͸� ������ �ð����� ���
                                                    data = {send_buffer[7:4], 3'b110, rs};      // {[d7 d6 d5 d5], bt, e, rw, rs}
                                                    comm_go =1;    
                                                    count_usec_e =1;
                                            end
                                            else begin
                                                    comm_go =0;    
                                                    count_usec_e =0;
                                                    next_state = SEND_LOW_NIBBLE_DISABLE;
                                            end
                                    end
                                    
                                    SEND_LOW_NIBBLE_DISABLE:begin
                                             if(count_usec <= 22'd200)begin // 8��Ʈ �����͸� ������ �ð����� ���
                                                    data = {send_buffer[3:0], 3'b100, rs};      // {[d7 d6 d5 d5], bt, e, rw, rs}
                                                    comm_go =1;    
                                                    count_usec_e =1;
                                            end
                                            else begin
                                                    comm_go =0;    
                                                    count_usec_e =0;
                                                    next_state = SEND_LOW_NIBBLE_ENABLE;
                                            end
                                    end
                                    
                                    SEND_LOW_NIBBLE_ENABLE:begin
                                            if(count_usec <= 22'd200)begin // 8��Ʈ �����͸� ������ �ð����� ���
                                                    data = {send_buffer[3:0], 3'b110, rs};      // {[d7 d6 d5 d5], bt, e, rw, rs}
                                                    comm_go =1;    
                                                    count_usec_e =1;
                                            end
                                            else begin
                                                    comm_go =0;    
                                                    count_usec_e =0;
                                                    next_state = SEND_DISABLE;
                                            end
                                    end
                                    
                                    SEND_DISABLE:begin
                                            if(count_usec <= 22'd200)begin // 8��Ʈ �����͸� ������ �ð����� ���
                                                    data = {send_buffer[3:0], 3'b100, rs};      // {[d7 d6 d5 d5], bt, e, rw, rs}
                                                    comm_go =1;    
                                                    count_usec_e =1;
                                            end
                                            else begin
                                                    comm_go =0;    
                                                    count_usec_e =0;
                                                    next_state = IDLE;
                                                    busy=0;
                                            end
                                    end
                                    
                            endcase
                    end
             end
         
               
        I2C_master(.clk(clk),.reset_p(reset_p), .addr(addr), .rd_wr(0), .data(data),.comm_go(comm_go), .sda(sda), .scl(scl) , .led(led));
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module I2C_master(
        input clk,reset_p,
        input [6:0] addr,
        input rd_wr,
        input [7:0] data,
        input comm_go,  // ��� ����
        output reg sda, scl,
        output reg [15:0] led );
        
        parameter IDLE = 7'b000_0001;
        parameter COMM_START = 7'b000_0010;
        parameter SEND_ADDR = 7'b000_0100;
        parameter RD_ACK = 7'b000_1000;
        parameter SEND_DATA = 7'b001_0000;
        parameter SCL_STOP = 7'b010_0000;
        parameter COMM_STOP = 7'b100_0000;
        
        wire  [7:0] addr_rw;
        assign addr_rw = {addr, rd_wr};
        
        wire clk_usec;
        clock_div_100    usec_clock         (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec)); 
        
        reg [2:0] count_usec5;
        reg scl_e;
        
        always @(posedge clk or posedge reset_p) begin
                    if(reset_p)begin
                                count_usec5 =0;
                                scl =1;
                    end
                    else if(scl_e)begin
                                if(clk_usec)begin
                                        if(count_usec5>= 4)begin
                                                count_usec5 = 0;
                                                scl = ~scl;
                                        end
                                        else count_usec5 = count_usec5 + 1;
                                end
                    end
                    else if(!scl_e)begin
                                scl = 1;
                                count_usec5 = 0;
                    end
        end
        
        wire scl_nedge, scl_pedge;
        edge_detector_n        ed   (.clk(clk), .reset_p(reset_p), .cp(scl),  .n_edge(scl_nedge), .p_edge(scl_pedge));
        
         wire comm_go_pedge;
        edge_detector_n        ed_go   (.clk(clk), .reset_p(reset_p), .cp(comm_go), .p_edge(comm_go_pedge));
        
        reg [6:0] state, next_state;
        always @(negedge clk or posedge reset_p) begin
                        if(reset_p) state = IDLE;
                        else state = next_state;                        
        end
        
        reg [2:0] cnt_bit;
        reg stop_flag;
        always @(posedge clk or posedge reset_p) begin
                        if(reset_p) begin
                                    next_state = IDLE;
                                    scl_e =0;
                                    sda =1;
                                    cnt_bit =7;
                                    stop_flag =0;
                        end
                        else begin
                                case(state)
                                            IDLE: begin
                                                    scl_e =0;
                                                    sda =1;
                                                    if(comm_go_pedge) next_state =  COMM_START;                                                     
                                            end
                                            
                                            COMM_START: begin
                                                     sda =0;
                                                     scl_e =1;
                                                     next_state = SEND_ADDR;                                                                                            
                                            end
                                            
                                            SEND_ADDR: begin
                                                     if(scl_nedge) sda = addr_rw[cnt_bit];
                                                     if(scl_pedge) begin
                                                                if(cnt_bit ==0) begin
                                                                            cnt_bit =7;
                                                                            next_state = RD_ACK;
                                                                end
                                                                else cnt_bit = cnt_bit -1;
                                                     end
                                            end
                                            
                                            RD_ACK: begin  //��ſ��� Ȯ�� �Ҷ�� sda�� input �����ؾ��� -> �츮�� ���� �Ⱦ�����
                                                    if(scl_nedge) sda ='bz;
                                                    else if(scl_pedge) begin
                                                                if(stop_flag)begin
                                                                        stop_flag =0;
                                                                        next_state = SCL_STOP;
                                                                end
                                                               else begin
                                                                        stop_flag =1;
                                                                        next_state = SEND_DATA;
                                                                end
                                                    end 
                                                    
                                            end
                                            
                                            SEND_DATA: begin
                                                    if(scl_nedge) sda = data[cnt_bit];
                                                             if(scl_pedge) begin
                                                                        if(cnt_bit ==0) begin
                                                                                    cnt_bit =7;
                                                                                    next_state = RD_ACK;
                                                                                    
                                                                        end
                                                                        else cnt_bit = cnt_bit -1;
                                                             end
                                                    end
                                            
                                            SCL_STOP: begin
                                                    if(scl_nedge) sda =0;
                                                    else if(scl_pedge) next_state =COMM_STOP;
                                            end
                                            
                                            COMM_STOP: begin
                                                    if(count_usec5 >=3)begin
                                                            scl_e =0; //Ŭ���� high�� ����
                                                            sda =1;
                                                            next_state = IDLE;
                                                    end
                                            end
                                            
                                endcase
                        end
        end
        
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module keypad_cntr_FSM(
         input clk, reset_p,
         input [3:0] row,   // �� 
         output reg [3:0] col,  //column �� 
         output reg [3:0] key_value,
         output reg key_valid);
         
         parameter SCAN0                        = 5'b00001;
         parameter SCAN1                         = 5'b00010;
         parameter SCAN2                        = 5'b00100;
         parameter SCAN3                        = 5'b01000;
         parameter KEY_PROCESS       = 5'b10000;
         
         
         reg [19:0] clk_div;
         always @(posedge clk) clk_div = clk_div+1;
        
        wire clk_8msec_n, clk_8msec_p;
        edge_detector_p        ed       (.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n),  .p_edge(clk_8msec_p));
        
        
       reg [4:0] state, next_state;
       
       always @(posedge clk or posedge reset_p)begin
                if(reset_p) state = SCAN0;
                else if(clk_8msec_n)state = next_state;
       end
       
       
       always @* begin   //���ϵ�ī�� ��� ��쿡 ���� (����ȸ���ε� �տ�else if(clk_8msec)state = next_state�� ���� ����ȸ��ó�� ���� )
                    case(state)
                            SCAN0 : begin
                                    if(row ==0) next_state = SCAN1;      // ��ư�� ������ 
                                    else next_state = KEY_PROCESS;                  // ��ư�� �ȴ�����
                            end 
                            
                            SCAN1 : begin
                                    if(row ==0) next_state = SCAN2;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            SCAN2 : begin
                                    if(row ==0) next_state = SCAN3;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            SCAN3 : begin
                                    if(row ==0) next_state = SCAN0;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            KEY_PROCESS : begin
                                    if(row ==0) next_state = SCAN0;
                                    else next_state = KEY_PROCESS;
                            end 
                            
                            default : next_state = SCAN0;
                    endcase
        end
        
  always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                        key_value = 0;
                        key_valid = 0;
                        col =0;
                end
                else if(clk_8msec_p)begin
                        case(state)
                                SCAN0 : begin col = 4'b0001; key_valid = 0; end
                                SCAN1 : begin col = 4'b0010; key_valid = 0; end
                                SCAN2 : begin col = 4'b0100; key_valid = 0; end
                                SCAN3 : begin col = 4'b1000; key_valid = 0; end
                                KEY_PROCESS : begin
                                            key_valid = 1;
                                                 case({col, row})
                                                 8'b0001_0001 : key_value = 4'h7;
                                                 8'b0001_0010 : key_value = 4'h4;
                                                 8'b0001_0100 : key_value = 4'h1;
                                                 8'b0001_1000 : key_value = 4'hc;
                                                 8'b0010_0001 : key_value = 4'h8;
                                                 8'b0010_0010 : key_value = 4'h5;
                                                 8'b0010_0100 : key_value = 4'h2;
                                                 8'b0010_1000 : key_value = 4'h0;
                                                 8'b0100_0001 : key_value = 4'h9;
                                                 8'b0100_0010 : key_value = 4'h6;
                                                 8'b0100_0100 : key_value = 4'h3;
                                                 8'b0100_1000 : key_value = 4'hf;
                                                 8'b1000_0001 : key_value = 4'ha;
                                                 8'b1000_0010 : key_value = 4'hb;
                                                 8'b1000_0100 : key_value = 4'he;
                                                 8'b1000_1000 : key_value = 4'hd;      
                                                 endcase  
                                end
                        endcase
               end
end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module edge_detector_p(
        input clk, reset_p,
        input cp, //�ԷµǴ� Ŭ���޽�(�׸��� btn) 
        output p_edge, n_edge); // ��¿������� �����Ŭ �޽��� ���
        
        reg ff_cur, ff_old; //
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        ff_cur <=0;
                        ff_old <=0;
                end
                else begin
                        //ff_old = ff_cur;
                        //ff_cur = cp;                    
                        //ff_cur = cp;
                        //ff_old = ff_cur;               
                        ff_cur <= cp;
                        ff_old <= ff_cur;
                        //if�� ���ǹ��� �ƴ� always������ ����ϸ� �񱳿����ڰ� �ƴ϶� ��������,,? �� ���
                        // ȭ��ǥ���� �ͺ��ŷ��(���� ����ǰ� �ؿ� �����),,,,, �������� ���ŷ�� (��������Ǹ� �ؿ� �������)
                 end
         end
         assign p_edge = ({ff_cur, ff_old} ==2'b10) ? 1 : 0;
         assign n_edge = ({ff_cur, ff_old} ==2'b01) ? 1 : 0;
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module fnd_cntr(
            input clk, reset_p,
            input [15:0] value,
            output [3:0] com,       //���뿡���
            output [7:0] seg_7);  //���׸�Ʈ
            
            ring_counter_fnd        rc( clk, reset_p,com);  //�ν��Ͻ����� ������ �˾Ƽ� �̸��ٿ���
            
            reg [3:0] hex_value;
            always @(posedge clk)begin
                    case(com)
                            4'b1110: hex_value = value[3:0];
                            4'b1101: hex_value = value[7:4];
                            4'b1011: hex_value = value[11:8];
                            4'b0111: hex_value = value[15:12];
                     endcase 
              end
                     
            decoder_7seg(.hex_value(hex_value),.seg_7(seg_7)); //4��Ʈ 2������ ��簪 ǥ��
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module ring_counter_fnd(    
        input clk, reset_p,
        output reg [3:0] com);
        
        reg [20:0] clk_div =0; //ȸ�λ����δ� ������ �ȵ����� �ùķ��̼� �Ҷ��� ���
        always @(posedge clk) clk_div = clk_div +1;
        
        wire clk_div_nedge;
        edge_detector_p ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));  //�� 1ms�� �����ϱ�
        //1ms ���� ����Ʈ�ȴ�, �츮 ������ �����̴°� �������� �ʴ´�.
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) com = 4'b1110;
                else if(clk_div_nedge)begin
                        if(com == 4'b0111)  com = 4'b1110;
                        else  com[3:0] = {com[2:0], 1'b1};
                end
        end
 endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module decoder_7seg(
           input [3:0] hex_value,
           output reg [7:0] seg_7);
           
           always @(hex_value)begin
                    case(hex_value)   //abcd_efgp
                           0 : seg_7 = 8'b0000_0011; //fnd�� 0 ǥ��
                           1 : seg_7 = 8'b1001_1111; //fnd�� 1 ǥ��
                           2 : seg_7 = 8'b0010_0101; //fnd�� 2 ǥ��
                           3 : seg_7 = 8'b0000_1101; //fnd�� 3 ǥ��
                           4 : seg_7 = 8'b1001_1001;
                           5 : seg_7 = 8'b0100_1001;
                           6 : seg_7 = 8'b0100_0001;
                           7 : seg_7 = 8'b0001_1011;
                           8 : seg_7 = 8'b0000_0001;
                           9 : seg_7 = 8'b0000_1001;
                           10 : seg_7 = 8'b0001_0001;  //A
                           11 : seg_7 = 8'b1100_0001;  //b
                           12 : seg_7 = 8'b0110_0011; //C
                           13 : seg_7 = 8'b1000_0101; //d
                           14 : seg_7 = 8'b0110_0001; //E
                           15 : seg_7 = 8'b0111_0001; //F
                   endcase  
           end
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module clock_div_100(
            input clk, reset_p,
            output clk_div_100,
            output clk_div_100_nedge);
            
            reg [6:0] cnt_sysclk;
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_sysclk = 0;
                    else begin
                            if(cnt_sysclk>=99)  cnt_sysclk = 0;
                            else cnt_sysclk = cnt_sysclk +1;  //1�� �����ϴ� ī����
                    end
             end
             
             assign clk_div_100 = (cnt_sysclk <50) ? 0:1;   // 1us ���� 1�ֱⰡ �߻��ϴ� clk_dic_100 ����
             // 50������ 0, 50������ 1, �� 100�� �ֱ�, 1ȸ�� 10ns 100�� �ݺ��ϸ� 1000ns = 1us
             // 1us ���� �����Ŭ�޽� �����(����������)
             
             edge_detector_n ed( //���������� �ν��Ͻ� ��������
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_100),
                   .n_edge(clk_div_100_nedge));   
                  
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module edge_detector_n(
        input clk, reset_p,
        input cp, //�ԷµǴ� Ŭ���޽�(�׸��� btn) 
        output p_edge, n_edge); // ��¿������� �����Ŭ �޽��� ���
        
        reg ff_cur, ff_old; //
        always @(negedge clk or posedge reset_p)begin
                if(reset_p)begin
                        ff_cur <=0;
                        ff_old <=0;
                end
                else begin             
                        ff_cur <= cp;
                        ff_old <= ff_cur;
                        //if�� ���ǹ��� �ƴ� always������ ����ϸ� �񱳿����ڰ� �ƴ϶� ��������,,? �� ���
                        // ȭ��ǥ���� �ͺ��ŷ��(���� ����ǰ� �ؿ� �����),,,,, �������� ���ŷ�� (��������Ǹ� �ؿ� �������)
                 end
         end
         assign p_edge = ({ff_cur, ff_old} ==2'b10) ? 1 : 0;
         assign n_edge = ({ff_cur, ff_old} ==2'b01) ? 1 : 0;         
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module button_cntr(
            input clk, reset_p,
            input btn,
            output btn_nedge, btn_pedge);
            
            reg [20:0] clk_div =0;
            always @(posedge clk) clk_div = clk_div +1;
            
            wire clk_div_nedge;
            edge_detector_p        ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge)); //���� 1ms �ȿ��� ü�ͤ����� ����
            
            reg debounced_btn;
            always @(posedge clk or posedge reset_p) begin
                    if(reset_p)debounced_btn =0;
                    else if(clk_div_nedge) debounced_btn =btn;
            end
            
            edge_detector_p        ed1(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge( btn_nedge), .p_edge( btn_pedge));
endmodule   

