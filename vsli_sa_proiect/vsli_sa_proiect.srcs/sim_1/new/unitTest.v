`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2018 06:52:02 PM
// Design Name: 
// Module Name: unitTest
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


module unitTest;
    //parioada unui ciclu de ceas la 10Mhz
    parameter c_CLOCK_PERIOD_NS = 100;
    //numarul de periaode de ceas pe bit
    parameter c_CLKS_PER_BIT    = 87;
    //durata unui bit
    parameter c_BIT_PERIOD      = 8600;
    
    //reset
    reg reset;
    //ceasul
    reg r_Clock = 0;
    //RX
    reg r_Rx_Serial = 1;
    //TX
    wire w_Tx_Serial;
    
    //un task pentru scrierea la seriala a unui valori data ca input
    task UART_WRITE_BYTE;
        input [7:0] i_Data;
        integer     ii;
        begin
            // se transmite bitul de start
            r_Rx_Serial <= 1'b0;
            #(c_BIT_PERIOD);
            #1000;
            
            // se transmit biit de informatie
            for (ii=0; ii<8; ii=ii+1)
            begin
                r_Rx_Serial <= i_Data[ii];
                #(c_BIT_PERIOD);
            end
            
            // se transmite bitul de stop
            r_Rx_Serial <= 1'b1;
            #(c_BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE
    
    
    
    // initiarea modului de testat
    tempProces uut (
        .i_w_clk(r_Clock),
        .i_w_reset(reset),
        .i_w_Rx_Serial(r_Rx_Serial),
        .o_w_Tx_Serial(w_Tx_Serial)
    );
    //cofigurarea ceasului
    always
        #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

    
    initial
    begin
        
        //folosirea reset-ului pentru modul
        reset = 1;
        #10
        reset = 0;
        //asteptarea unor cicluri de ceas
        @(posedge r_Clock);
        @(posedge r_Clock);
        @(posedge r_Clock);
        
        //transmiterea pe seriala datelor a doi senzori
        // 1: 5 5 5
        // 2: 10 10 10
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h02);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h05);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h05);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h05);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h0A);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h0A);
        @(posedge r_Clock);
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h0A);
        @(posedge r_Clock);
        
    end
endmodule
