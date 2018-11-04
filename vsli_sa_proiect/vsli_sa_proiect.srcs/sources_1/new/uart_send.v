`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2018 04:09:03 PM
// Design Name: 
// Module Name: uart_send
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


module uart_send
    #(
        parameter BAUD_RATE = 115200,
        parameter CLK_RATE  = 10000000 //10Mhz
    )
    (
        //ceasul
        input wire       i_w_clk,
        //reset
        input wire       i_w_reset,
        //daca se doreste transmiterea unui byte
        input wire       i_w_Tx_DV,
        //byte-ul de transmis
        input wire [7:0] i_w_Tx_Byte,
        //daca este folosit TX
        output wire      o_w_Tx_Active,
        //valoarea pentru TX
        output wire      o_w_Tx_Serial,
        //daca s-a transmis ultimul byte
        output wire      o_w_Tx_Done
    );

    //cate perioade de ceas are un bit
    parameter CLKS_PER_BIT = CLK_RATE/BAUD_RATE;
    //definirea starilor FSM-ului
    parameter s_IDLE         = 3'b000;
    parameter s_TX_START_BIT = 3'b001;
    parameter s_TX_DATA_BITS = 3'b010;
    parameter s_TX_STOP_BIT  = 3'b011;
    parameter s_CLEANUP      = 3'b100;
    
    //starea FSM-ului
    reg [2:0]    r_FSM_State;
    //contor pentru perioade de ceas
    reg [7:0]    r_Clock_Count;
    //indexul in byte
    reg [2:0]    r_Bit_Index;
    //registrul cu byte-ul de transmis
    reg [7:0]    r_Tx_Data;
    //daca byte-ul a fost transmis
    reg          r_Tx_Done;
    //daca linia TX este activa si se transmite pe ea
    reg          r_Tx_Active;
    //valoarea pe care o ia TX pentru transmitere
    reg          r_Tx_Serial;
    
    //asiganrea iesirilor la registri
    assign o_w_Tx_Active = r_Tx_Active;
    assign o_w_Tx_Done   = r_Tx_Done;
    assign o_w_Tx_Serial = r_Tx_Serial;
    
    //initializarea variabilelor
    //TX trebuie sa fie pe 1 in mod implicit
    always @(*)
    begin
        if(i_w_reset)
        begin
            r_FSM_State     = 0;
            r_Clock_Count   = 0;
            r_Bit_Index     = 0;
            r_Tx_Data       = 0;
            r_Tx_Done       = 0;
            r_Tx_Active     = 0;
            r_Tx_Serial     = 1'b1;
        end
    end
    
    //procesul de tracere prin starile FSM-ului pentru transmiterea unui byte
    always @(posedge i_w_clk)
    begin
      
        case (r_FSM_State)
        /*
        s_IDLE: starea in care se asteapta date pentr a fi transmise pe TX
        TX este pe 1
        nu s-a transmis nici un byte, contor de perioade de ceas si indexul de bit sunt
        setati pe zero.
        Daca se primeste semnal ca trebuie sa se transmita un byte se activea
        linea TX se retin datele ce trebuie transmise intr-un registru si se
        trece in starea urmatoare de transmitere a bitului de start, in caz contrar
        se ramane in stare IDLE
        */
        s_IDLE :
        begin
        r_Tx_Serial   <= 1'b1;
        r_Tx_Done     <= 1'b0;
        r_Clock_Count <= 0;
        r_Bit_Index   <= 0;
        
        if (i_w_Tx_DV == 1'b1)
        begin
            r_Tx_Active <= 1'b1;
            r_Tx_Data   <= i_w_Tx_Byte;
            r_FSM_State <= s_TX_START_BIT;
        end
        else
        begin
            r_FSM_State <= s_IDLE;
        end
        end // case: s_IDLE
        
        
        /*
        s_TX_START_BIT: starea in care se transmite bitul de start.
        TX va avea valoarea zero pe durata unui bit. dupa trecerea
        timpului se trece in starea de transmiterea a bitilor de date
        */
        s_TX_START_BIT :
        begin
            r_Tx_Serial <= 1'b0;

            if (r_Clock_Count < CLKS_PER_BIT-1)
            begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_FSM_State   <= s_TX_START_BIT;
            end
            else
            begin
                r_Clock_Count <= 0;
                r_FSM_State   <= s_TX_DATA_BITS;
            end
        end // case: s_TX_START_BIT
        
        
        /*
        s_TX_DATA_BITS: starea in care se transmit biti de date
        TX ia valoare bitului curent timp de o durata de bit.
        dupa care se trece la urmatorul bit. Dupa ce toti biti
        au fostr transmisi se trece in starea de transmitere
        a bitului de stop
        */     
        s_TX_DATA_BITS :
        begin
            r_Tx_Serial <= r_Tx_Data[r_Bit_Index];
            
            if (r_Clock_Count < CLKS_PER_BIT-1)
            begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_FSM_State     <= s_TX_DATA_BITS;
            end
            else
            begin
                r_Clock_Count <= 0;
                
                if (r_Bit_Index < 7)
                begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_FSM_State <= s_TX_DATA_BITS;
                end
                else
                begin
                    r_Bit_Index <= 0;
                    r_FSM_State <= s_TX_STOP_BIT;
                end
            end
        end // case: s_TX_DATA_BITS
        
        
        /*
        s_TX_STOP_BIT: starea in care se transmite bitul de stop
        si se anunta transmiterea byte-ului. Bitul de stop pune
        TX pe valoarea 1 si il tine o durata de bit. La terminarea
        duratei se anunta ca a fost transmis bitul prin r_Tx_Done
        si se anunta ca nu mai este folosit TX-ul. dupa se trece in starea
        de CELANUP
        */
        s_TX_STOP_BIT :
        begin
            r_Tx_Serial <= 1'b1;
            
            if (r_Clock_Count < CLKS_PER_BIT-1)
            begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_FSM_State   <= s_TX_STOP_BIT;
            end
            else
            begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_FSM_State   <= s_CLEANUP;
                r_Tx_Active   <= 1'b0;
            end
        end // case: s_Tx_STOP_BIT
        
        
        /*
        Se reseteaza valoare ca a fost transmis un byte, anuntandu-se
        astfel ca trebuie incarcat urmatorul byte pentru transmisie daca
        se doreste. dupa se trece in starea IDLE
        */
        s_CLEANUP :
        begin
            r_Tx_Done <= 1'b0;
            r_FSM_State <= s_IDLE;
        end
        
        
        default :
            r_FSM_State <= s_IDLE;
        
        endcase
    end
    
    
endmodule
