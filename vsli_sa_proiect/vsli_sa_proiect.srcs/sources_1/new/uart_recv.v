`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2018 10:16:12 AM
// Design Name: 
// Module Name: uart_recv
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


module uart_recv
    #(
        parameter BAUD_RATE = 115200,
        parameter CLK_RATE  = 10000000 //10Mhz
    )
    (
        //ceasul
        input        wire i_w_clk,
        //reset
        input        wire i_w_reset,
        //daca este activat modul pentru receptionare
        input        wire i_w_enable,
        //RX
        input        wire i_w_Rx_Serial,
        //daca a fost recptionat un byte
        output       wire o_w_Rx_DV,
        //ultimul byte recptionat
        output       wire [7:0] o_w_Rx_Byte
    );

    //cate perioade de ceas are un bit
    parameter CLKS_PER_BIT = CLK_RATE/BAUD_RATE;
    //definirea starilor FSM-ului
    parameter s_IDLE         = 3'b000;
    parameter s_RX_START_BIT = 3'b001;
    parameter s_RX_DATA_BITS = 3'b010;
    parameter s_RX_STOP_BIT  = 3'b011;
    parameter s_CLEANUP      = 3'b100;
   
    //registre pentru datale venit pe RX
    reg           r_Rx_Data_R;
    reg           r_Rx_Data;;
    //contor pentru perioade de ceas
    reg [7:0]     r_Clock_Count;
    //indexul din byte
    reg [2:0]     r_Bit_Index;
    //registrul pentru byte-ul primit
    reg [7:0]     r_Rx_Byte;
    //registru care anunta cand s-a primit un byte intreg
    reg           r_Rx_DV;
    //registru cu starea FSM-ului
    reg [2:0]     r_FSM_State;
    
    //asignarea iesirilor la registrii
    assign o_w_Rx_DV   = r_Rx_DV;
    assign o_w_Rx_Byte = r_Rx_Byte;
    //initializarea valorilor cand se apasa pe butonul reset
    always @(*)
    begin
        if(i_w_reset)
        begin
            r_Rx_Data_R = 1'b1;
            r_Rx_Data   = 1'b1;
            r_Clock_Count = 0;
            r_Bit_Index   = 0;
            r_Rx_Byte     = 0;
            r_Rx_DV       = 0;
            r_FSM_State   = 0;
        end
    end
    // dublarea registrului pentru date de la intrare pentru stabilizarea
    // semnalului pe RX
    always @(posedge i_w_clk)
    begin
        r_Rx_Data_R <= i_w_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
    end
    
    //procesul de trecere prin starile FSM-ului si de receptioanre a byte-ului
    always @(posedge i_w_clk)
    begin
       
        case (r_FSM_State)
            /*
            S_IDLE: starea in care se astepta un bit de start
            contor pentru perioade si indexul pentru bit sunt la zero
            de asemenea nu s-a recptionat inca nici un byte
            
            Daca se receptioneaza o valoarea de 0 pe RX (deobicei seriala sta pe 1)
            si este activata recptionarea atunci trecem in starea de citire a bitului
            de start stfel ramanem in starea IDLE
            */
            s_IDLE :
            begin
                r_Rx_DV       <= 1'b0;
                r_Clock_Count <= 0;
                r_Bit_Index   <= 0;
                
                if ( (r_Rx_Data == 1'b0) && (i_w_enable==1'b1) )
                    r_FSM_State <= s_RX_START_BIT;
                else
                    r_FSM_State <= s_IDLE;
            end // case: s_IDLE
             
            /*
            s_RX_START_BIT: starea de citire a bitului de start
            Verificam daca si la jumatatea timoul de transmitere a
            unui bit este total valoare zero. Atunci avem un bit de start
            si trecem in starea de citire a bitilor de date, daca nu ne intoarcem
            in starea IDLE.
            */
            s_RX_START_BIT :
            begin
                if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
                begin
                    if (r_Rx_Data == 1'b0)
                    begin
                        r_Clock_Count <= 0;
                        r_FSM_State   <= s_RX_DATA_BITS;
                    end
                    else
                    begin
                        r_FSM_State <= s_IDLE;
                    end
                end
                else
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_FSM_State   <= s_RX_START_BIT;
                end
            end // case: s_RX_START_BIT
             
             
            /*
            s_RX_DATA_BITS: starea de citire a bitilor de informatie
            Se astepat ca timp o perioada si se citeste valoarea de la RX
            aceasta valoare este valoarea bitului dupa care se trece la urmatorul
            bit. Daca s-au citit toti bitii se trece in starea in care se citeste bitul
            de stop.
            */
            s_RX_DATA_BITS :
            begin
                if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_FSM_State   <= s_RX_DATA_BITS;
                end
                else
                begin
                    r_Clock_Count          <= 0;
                    r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                    
                    if (r_Bit_Index < 7)
                    begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_FSM_State <= s_RX_DATA_BITS;
                    end
                    else
                    begin
                        r_Bit_Index <= 0;
                        r_FSM_State <= s_RX_STOP_BIT;
                    end
                end
            end // case: s_RX_DATA_BITS
            
            
            /*
            s_RX_STOP_BIT: starea in care se receptioneaza bitul de stop.
            e revenirea la transmiterea semnalului de 1 pe RX. Se asteapta
            o durata de timp cat un bit dupa care se trece in strea de
            CEALNUP. In aceasta stare se anunta ca a fost receptionat
            byte-ul si ca poate sa fie citit.
            */
            s_RX_STOP_BIT :
            begin
                if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_FSM_State   <= s_RX_STOP_BIT;
                end
                else
                begin
                    r_Rx_DV       <= 1'b1;
                    r_Clock_Count <= 0;
                    r_FSM_State   <= s_CLEANUP;
                end
            end // case: s_RX_STOP_BIT
            
             
            /*
            s_CLEANUP: starea de curatare a datelor si revenirea
            la starea IDLE. In aceasta stare se sta un periaoda de ceas
            pentr a butea lua datele primite pe RX de la outputul modulului
            */
            s_CLEANUP :
              begin
                r_FSM_State <= s_IDLE;
                r_Rx_DV   <= 1'b0;
              end
             
             
            default :
              r_FSM_State <= s_IDLE;
         
        endcase
    end   
    
endmodule