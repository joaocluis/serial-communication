
// Autor: João Luis, Matheus Molinari e Verônica Nascimento


`timescale 1ns/1ps

module Uart8Transmitter_tb;

    // Saídas
	wire tx;	
	wire tx_done;
	
	// Registradores
	reg clk;
	reg tx_en;
	reg [7:0] data;

    // Instancia o módulo Uart8Transmitter
    uart_tx uut (
        .clk_50M(clk),
      	.tx_en(tx_en),
      	.tx(tx),
      	.data(data),
      	.tx_done(tx_done)
    );

    // Gera o clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock de 10ns (100MHz)
    end

    initial begin
		// Inicializa os sinais
        tx_en = 0;
        data = 8'b0;
      
        // Aguarda alguns ciclos de clock
        #10;

        // Habilita o módulo e inicia a transmissão de dados
        tx_en = 1;
        data = 8'b11110000; // Dados a serem transmitidos
		
        // Aguarda um ciclo de clock para capturar o start
        #10;

        // Aguarda até a transmissão ser concluída
      	wait (tx_done);
      	$display("Sucess Transmitter.");

        // Verifica se a transmissão foi concluída e exibe os dados transmitidos
        if (tx_done) begin
          	$display("Mensagem transmitida: %b", data);
		end else begin
            $display("Erro no Transmitter.");
        end

        // Desabilita o módulo
        tx_en = 0;

        // Aguarda alguns ciclos de clock e termina a simulação
        #50;
        $finish;
    end
endmodule