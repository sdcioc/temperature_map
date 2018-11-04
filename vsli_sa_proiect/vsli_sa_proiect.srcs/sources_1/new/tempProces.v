`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2018 06:54:35 PM
// Design Name: 
// Module Name: tempProces
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


module tempProces
    #(
        parameter      MAX_SENSOR_NUMBERS = 10,
        parameter      MAX_WIDTH = 20,
        parameter      MAX_HEIGHT = 20,
        parameter      PARALEL_ZONES = 5,
        parameter      DATA_WIDTH = 8,
        parameter      WDATA_WIDTH = 16,
        parameter      BAUD_RATE = 115200,
        parameter      CLK_RATE  = 10000000 //10Mhz
    )
    (
        //ceasul
        input wire i_w_clk,
        //reset
        input wire i_w_reset,
        //RX
        input wire i_w_Rx_Serial,
        //TX
        output wire o_w_Tx_Serial
    );
    
    //starile FSM-ului
    parameter s_IDLE = 3'b000;
    parameter s_UART_READ = 3'b001;
    parameter s_TEMP_PROCESSING = 3'b010;
    parameter s_UART_WRITE = 3'b011;
    parameter s_ERROR = 3'b111;
    
    //starea FSM-ului
    reg[2:0] r_FSM_State;
    //daca a fost receptionat numarul de senzori
    reg r_recived_sensors_number;
    //numarul de senzori
    reg[(DATA_WIDTH-1):0] r_sensors_number;
    //pozitia senzorilor pe axa ox
    reg[(DATA_WIDTH-1):0] ra_sensors_x_position[0:(MAX_SENSOR_NUMBERS-1)];
    //pozitia senzorilor pe axa oy
    reg[(DATA_WIDTH-1):0] ra_sensors_y_position[0:(MAX_SENSOR_NUMBERS-1)];
    //valaorea temperaturii senzorului
    reg[(DATA_WIDTH-1):0] ra_sensors_temp[0:(MAX_SENSOR_NUMBERS-1)];
    //harta temperaturii creata cu datele de la senzori
    reg[(DATA_WIDTH-1):0] raa_tempMap[0:(MAX_WIDTH-1)][0:(MAX_HEIGHT-1)];
    //produsul distanelor de la pozitia curenta la senzori
    reg[((MAX_SENSOR_NUMBERS + 1)* (WDATA_WIDTH-1)):0] ra_total_product[0:(PARALEL_ZONES-1)];
    //suma parametrilor
    reg[((MAX_SENSOR_NUMBERS + 1)* (WDATA_WIDTH-1)):0] ra_total_params[0:(PARALEL_ZONES-1)];
    //variabila temporara pentru retinerea temperaturii
    reg[((MAX_SENSOR_NUMBERS + 1)* (WDATA_WIDTH-1)):0] ra_tmp_temp[0:(PARALEL_ZONES-1)];
    //indecsi de parcurgere prin zonele de paralelism
    //se foloseste in calcularea temperaturii
    reg[(DATA_WIDTH-1):0] r_pz_i_index;
    //se foloseste in calcularea sumei distantelor
    reg[(DATA_WIDTH-1):0] r_pz_j_index;
    //indecsi de parcurgere pentru senzori
    //se folosesc cand se citesc valori pe seriala
    reg[(DATA_WIDTH-1):0] r_s_i_index;
    reg[(DATA_WIDTH-1):0] r_s_j_index;
    //se folosete la calcularea temperaturii
    reg[(DATA_WIDTH-1):0] r_s_k_index;
    //se foloseste la calcularea sumei distantei
    reg[(DATA_WIDTH-1):0] r_s_t_index;
    //indecsi de parcurgere pentru harta de temperatura
    //se folosesc la calcularea temperaturii
    reg[(DATA_WIDTH-1):0] r_tm_i_index;
    reg[(DATA_WIDTH-1):0] r_tm_j_index;
    //se folosesc la transmiterea informatiilor pe seriala
    reg[(DATA_WIDTH-1):0] r_tm_k_index;
    reg[(DATA_WIDTH-1):0] r_tm_t_index;
    //distantele de la pozitia curenta la fiecare senzor
    wire[(WDATA_WIDTH-1):0] waa_distances[0:(PARALEL_ZONES-1)][0:(MAX_SENSOR_NUMBERS-1)];
    //parametrii pentru fiecare senzor
    wire[((MAX_SENSOR_NUMBERS + 1)* (WDATA_WIDTH-1)):0] waa_params[0:(PARALEL_ZONES-1)][0:(MAX_SENSOR_NUMBERS-1)];
    //daca este activata citirea pe seriala
    wire w_uart_read_enable;
    //daca s-a citit un byte
    wire w_uart_read_Rx_DV;
    //byte-ul citit
    wire[7:0] w_uart_read_Rx_Byte;
    //daca se doreste transmiterea unui byte pe seriala
    wire w_uart_send_Tx_Dv;
    //byte-ul de transmis pe seriala
    wire[7:0] w_uart_send_Tx_Byte;
    //daca este folosit TX
    wire w_uart_send_Tx_Active;
    //daca s-a terminat transmiterea byte-ului
    wire w_uart_send_Tx_Done;
        
    //daca ne aflam in starea de citire la uart activam acest lucru
    assign w_uart_read_enable = (r_FSM_State == s_UART_READ);
    //daca ne aflam in starea de scriere la uart activam transmiterea unui byte
    assign w_uart_send_Tx_Dv = (r_FSM_State == s_UART_WRITE);
    //byte-ul de transmis pe seriala
    assign w_uart_send_Tx_Byte = raa_tempMap[r_tm_k_index][r_tm_t_index];
    
    
    //modulul de receptionare a datelor
    uart_recv 
    #(
    )
    uart_read
    (
    .i_w_clk(i_w_clk),
    .i_w_reset(i_w_reset),
    .i_w_enable(w_uart_read_enable),
    .i_w_Rx_Serial(i_w_Rx_Serial),
    .o_w_Rx_DV(w_uart_read_Rx_DV),
    .o_w_Rx_Byte(w_uart_read_Rx_Byte)
    );
    
    //modulul de transmitere a datelor
    uart_send 
    #(
    )
    uart_write
    (
    .i_w_clk(i_w_clk),
    .i_w_reset(i_w_reset),
    .i_w_Tx_DV(w_uart_send_Tx_Dv),
    .i_w_Tx_Byte(w_uart_send_Tx_Byte),
    .o_w_Tx_Active(w_uart_send_Tx_Active),
    .o_w_Tx_Serial(o_w_Tx_Serial),
    .o_w_Tx_Done(w_uart_send_Tx_Done)
    );
    
    /*
    TESTAREA modulului de transmitere prin folosirea unui modul
    de recptionare
    */
    /*
    wire w_uart_read_v_enable;
    wire w_uart_read_v_Rx_DV;
    wire[7:0] w_uart_read_v_Rx_Byte;
    assign w_uart_read_v_enable = 1'b1;
    uart_recv 
    #(
    )
    uart_verify
    (
    .i_w_clk(i_w_clk),
    .i_w_reset(i_w_reset),
    .i_w_enable(w_uart_read_v_enable),
    .i_w_Rx_Serial(o_w_Tx_Serial),
    .o_w_Rx_DV(w_uart_read_v_Rx_DV),
    .o_w_Rx_Byte(w_uart_read_v_Rx_Byte)
    );
    */
    
    
    /*
    Se genereaza legaturi pentru calcularea distantelor de la pozitia curenta
    la fiecare senzor (distanta este fara radical) si a parametrilor pentru
    interpolare
    */
    generate genvar index, kndex;
    for (kndex = 0; kndex < PARALEL_ZONES; kndex = kndex + 1)
    begin
        for (index = 0; index < MAX_SENSOR_NUMBERS; index = index + 1)
        begin
            assign waa_distances[kndex][index] =  (index < r_sensors_number) ? (
                                       ( (ra_sensors_x_position[index] > r_tm_i_index) ?
                                         ((ra_sensors_x_position[index]-r_tm_i_index) * (ra_sensors_x_position[index]-r_tm_i_index)) :
                                         ((r_tm_i_index-ra_sensors_x_position[index]) * (r_tm_i_index-ra_sensors_x_position[index]))
                                       )
                                       +
                                       ( (ra_sensors_y_position[index] > (r_tm_j_index+kndex)) ?
                                         ((ra_sensors_y_position[index]-(r_tm_j_index+kndex)) * (ra_sensors_y_position[index]-(r_tm_j_index+kndex))) :
                                         (((r_tm_j_index+kndex)-ra_sensors_y_position[index]) * ((r_tm_j_index+kndex)-ra_sensors_y_position[index]))
                                       )
                                       ) : 1; //unu ca sa nu afecteze produsul
            assign waa_params[kndex][index] =  (index < r_sensors_number) ? 
                                            (
                                            (waa_distances[kndex][index] == 0) ? 1 : (ra_total_product[kndex] / waa_distances[kndex][index])
                                            )
                                            :
                                            0;
        end
    end
    endgenerate
    
    
    /*
    se calculeaza produsul distantelor catre senzori de la pozitia curenta si
    suma parametrilor pentru interpolare
    si ce se intampa la reset
    */
    always @(*)
    begin
        for (r_pz_j_index = 0; r_pz_j_index < PARALEL_ZONES; r_pz_j_index = r_pz_j_index + 1)
        begin
            ra_total_product[r_pz_j_index] = 1;
            ra_total_params[r_pz_j_index] = 0;
            for (r_s_t_index = 0; r_s_t_index < MAX_SENSOR_NUMBERS; r_s_t_index = r_s_t_index + 1)
            begin
                ra_total_product[r_pz_j_index] = ra_total_product[r_pz_j_index] * waa_distances[r_pz_j_index][r_s_t_index];
                ra_total_params[r_pz_j_index] = ra_total_params[r_pz_j_index] + waa_params[r_pz_j_index][r_s_t_index];
            end
        end
        if(i_w_reset)
        begin
            r_FSM_State = s_IDLE;
            r_tm_i_index = 0;
            r_tm_j_index = 0;
            r_tm_k_index = 0;
            r_tm_t_index = 0;
        end
    end
    

    /*
    Se trace prin starile fsm-ului
    */
    always @(posedge i_w_clk)
    begin
        case (r_FSM_State)
        /*
        s_IDLE: starea in care se reseteaza numarulde senzori si daca s-a primit acest
        numar. Se trece dupa in starea de citire de la seriala
        */
        s_IDLE :
        begin
            r_FSM_State <= s_UART_READ;
            r_sensors_number = 0;
            r_recived_sensors_number = 0;
        end // case s_IDLE
        
        /*
        s_UART_READ: starea in care se citeste de la UART. Se asteapta
        citirea unui byte. O data citi un byte se verifica daca
        s-a citit numarul de senozori. Daca nu inseamna ca acest byte
        este si se actualizeazza valoarea cat si starea recptionarii
        acestui numar. Dupa se citesc pe ordine pentru fiecare senzori in ordine
        pozitia pe axa ox, pozitia pe axa oy si valaorea temperaturii.
        r_s_j_index reprezinta care dintre cele 3 sunt
        r_s_i_index reprezinta numarul senzorului
        dupa recptionarea tuturor senzoriilor se trece in starea de procesare
        */
        s_UART_READ :
        begin
            if(w_uart_read_Rx_DV)
            begin
                if(r_recived_sensors_number == 0)
                begin
                    r_recived_sensors_number = 1;
                    r_sensors_number = w_uart_read_Rx_Byte;
                    r_FSM_State <= s_UART_READ;
                    r_s_i_index = 0;
                    r_s_j_index = 0;
                end
                else
                begin
                    if(r_s_j_index == 0)
                    begin
                        ra_sensors_x_position[r_s_i_index] = w_uart_read_Rx_Byte;
                        r_FSM_State <= s_UART_READ;
                        r_s_j_index = 1;
                    end
                    else
                    begin
                        if(r_s_j_index == 1)
                        begin
                            ra_sensors_y_position[r_s_i_index] = w_uart_read_Rx_Byte;
                            r_FSM_State <= s_UART_READ;
                            r_s_j_index = 2;
                        end
                        else
                        begin
                            if(r_s_j_index == 2)
                            begin
                                ra_sensors_temp[r_s_i_index] = w_uart_read_Rx_Byte;
                                r_s_j_index = 0;
                                r_s_i_index = r_s_i_index + 1;
                                if(r_sensors_number == r_s_i_index)
                                begin
                                    r_FSM_State <= s_TEMP_PROCESSING;
                                    r_tm_i_index = 0;
                                    r_tm_j_index = 0;
                                end
                                else
                                begin
                                    r_FSM_State <= s_UART_READ;
                                end
                            end
                            else
                            begin
                                r_FSM_State <= s_ERROR;
                            end
                        end
                    end
                end
            end
            else
            begin
                r_FSM_State <= s_UART_READ;
            end
        end // case s_UART_READ
        
        /*
        s_TEMP_PROCESSING : starea in care se proceaseaza datele. Se ia cate o pozitie
        per ciclu de ceas si se calculeaza valoarea ei (mai multe in acelasi timp daca
        avem activate mai multe zone paralele). Se pune valoarea rezultata in harta de temperaturi
        r_tm_j_index - reprezinta pozitia pe axa oy
        r_tm_i_index - reprezinta poiztia pe axa ox
        Cand s-au caculat valoriile pentru toate poztiile se trece la starea de scriere pe seriala
        */
        s_TEMP_PROCESSING :
        begin
            for (r_pz_i_index = 0; r_pz_i_index < PARALEL_ZONES; r_pz_i_index = r_pz_i_index + 1)
            begin
                ra_tmp_temp[r_pz_i_index] = 0;
                for (r_s_k_index = 0; r_s_k_index < r_sensors_number; r_s_k_index = r_s_k_index + 1)
                begin
                    ra_tmp_temp[r_pz_i_index] = ra_tmp_temp[r_pz_i_index] + waa_params[r_pz_i_index][r_s_k_index]*ra_sensors_temp[r_s_k_index];
                end
                ra_tmp_temp[r_pz_i_index] = ra_tmp_temp[r_pz_i_index] / ra_total_params[r_pz_i_index];
                raa_tempMap[r_tm_i_index][r_tm_j_index+r_pz_i_index] = ra_tmp_temp[r_pz_i_index];
            end
            if( r_tm_j_index == (MAX_HEIGHT - PARALEL_ZONES) )
            begin
                if( r_tm_i_index == (MAX_WIDTH - 1) )
                begin
                    r_tm_k_index = 0;
                    r_tm_t_index = 0;
                    r_FSM_State <= s_UART_WRITE;
                end
                else
                begin
                    r_tm_i_index = r_tm_i_index+1;
                    r_tm_j_index = 0;
                    r_FSM_State <= s_TEMP_PROCESSING;
                end
            end
            else
            begin
                r_tm_j_index = r_tm_j_index + PARALEL_ZONES;
                r_FSM_State <= s_TEMP_PROCESSING;
            end
        end //case s_TEMP_PROCESSING
           
        /*
        s_UART_WRITE : starea de scriere la seriala a datelor hartii.
        Cand se primeste faptul ca a fost transmis valoarea de la o pozitie
        se trece la urmatoarea valoare de transmis (urmatoarea pozitie)
        r_tm_t_index - pozitia pe oy
        r_tm_k_index - pozitia pe ox
        La final transmisiunii si trece din nou in starea IDLE
        */ 
        s_UART_WRITE :
        begin
            if(w_uart_send_Tx_Done)
            begin
                if( r_tm_t_index == (MAX_HEIGHT-1) )
                begin
                    if( r_tm_k_index == (MAX_WIDTH-1) )
                    begin
                        r_FSM_State <= s_IDLE;
                    end
                    else
                    begin
                        r_tm_k_index = r_tm_k_index+1;
                        r_tm_t_index = 0;
                        r_FSM_State <= s_UART_WRITE;
                    end
                end
                else
                begin
                    r_tm_t_index = r_tm_t_index + 1;
                    r_FSM_State <= s_UART_WRITE;
                end
            end
            else
            begin
                r_FSM_State <= s_UART_WRITE;
            end
        end //case s_UART_WRITE
        
        s_ERROR :
        begin
            r_FSM_State <= s_ERROR;
        end //case s_ERROR
        
        default :
            r_FSM_State <= s_IDLE;
        
        endcase
        
    end
    
endmodule
