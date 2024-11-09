// Autor: João Luis, Matheus Molinari e Verônica Nascimento


`timescale 1ns/1ps

module SerialCommunication (
	input clk_50M,			// Clock de 50 MHz do sistema principal
	input tx_en,			// Habilitar para iniciar a transmissão de dados
	input  [7:0] tx_data,	// Dados a serem transmitidos
	output [7:0] rx_msg,	// Dados recebidos
	output tx,				// Saída do transmissor
	output rx,				// Entrada do receptor
	output tx_done,			// Indicador de transmissão concluída
	output rx_complete		// Indicador que os dados foram recebidos
);

	// Instanciar o transmissor UART
	uart_tx tx_inst (
		.clk_50M(clk_50M),
		.tx_en(tx_en),
		.data(tx_data),
		.tx(tx),
		.tx_done(tx_done)
	);
    
	// Instanciar o receptor UART
	uart_rx rx_inst (
		.clk_50M(clk_50M),
		.rx(tx),		// Conecção entre o TX do transmissor e o RX do receptor
		.RxOut(rx),
		.rx_msg(rx_msg),
		.rx_complete(rx_complete)
	);
endmodule

module uart_tx(
	input clk_50M,
	input tx_en,
	input [7:0] data,
	output reg tx,
	output reg tx_done
);			
	
	// Parâmetros
  	parameter CYCLES_PER_BIT = 434; // Frequência do Clock [50M] / Baud Rate [115.000]
	parameter IDLE = 2'b00, START_BIT = 2'b01, DATA_BITS = 2'b10, STOP_BIT=2'b11;	// Estados da FSM
	
	// Registradores
	reg [1:0] state = IDLE;		// Estado Atual
	reg [10:0] cycle_count;		// Contagem de ciclos de clock para cada bit
	reg [3:0] index;				// Bit em transmissão
  	reg [11:0] mensagem; 		// Mensagem completa
   reg x1, x2, x3, x4; 			// Bits de paridade
	
	always@(posedge clk_50M) begin
		case(state)
		
			// Parado
			IDLE: begin	
				tx_done <= 1'b0;
				
				cycle_count <= 11'd0;
				if(tx_en == 1) begin		// Quando habilitada a transmissão muda o estado
					state <= START_BIT;
				end
				else state <= IDLE;
			end
			
			// Enviando start bit
			START_BIT: begin
				mensagem[11] <= data[0]; // D1
				mensagem[10] <= data[1]; // D2
				mensagem[9]  <= data[2]; // D3
				mensagem[8]  <= data[3]; // D4
				mensagem[6]  <= data[4]; // D5
				mensagem[5]  <= data[5]; // D6
				mensagem[4]  <= data[6]; // D7
            mensagem[2]  <= data[7]; // D8
              
				tx<=1'b0; // Bit start da comunicação
				
				// Espera 'CLKS_PER_BIT' ciclos de clock para enviar o bit start
				if(cycle_count == CYCLES_PER_BIT) begin
					index <= 4'b0000;
					state <= DATA_BITS;
					cycle_count <= 11'd0;
				end
				else begin
					cycle_count <= cycle_count + 1;
					state <= START_BIT;
				end
			end
			
			// Enviar os bits de dados e paridades
			DATA_BITS: begin
				// Bits de paridade
				x1 = mensagem[2] ^ mensagem[4] ^ mensagem[6] ^ mensagem[8] ^ mensagem[10];
				x2 = mensagem[2] ^ mensagem[5] ^ mensagem[6] ^ mensagem[9] ^ mensagem[10];
				x3 = mensagem[4] ^ mensagem[5] ^ mensagem[6] ^ mensagem[11];
				x4 = mensagem[8] ^ mensagem[9] ^ mensagem[10] ^ mensagem[11];

				// Insere os bits de paridade na mensagem
				mensagem[0] = x1;
				mensagem[1] = x2;
				mensagem[3] = x3;
				mensagem[7] = x4;
				
				// Envia para a saída do transmissor
				tx <= mensagem[index];
				
				// Espera 'CLKS_PER_BIT' ciclos de clock para enviar cada bit de dados
				if(cycle_count == CYCLES_PER_BIT) begin
					cycle_count <= 11'd0;
					if(index == 11) begin
						index <= 0;
						state <= STOP_BIT;
					end
					else begin
						index <= index + 1;
						state <= DATA_BITS;
					end
				end
				else begin
					cycle_count <= cycle_count + 1;
					state <= DATA_BITS;
				end
			end
			
			// Enviando stop bit
			STOP_BIT: begin
				tx <= 1'b1; // Bit stop da comunicação
				
				// Espera 'CLKS_PER_BIT' ciclos de clock para enviar o bit stop
				if(cycle_count == CYCLES_PER_BIT) begin
					cycle_count <= 11'd0;
					tx_done <= 1'b1;
					state <= IDLE;
				end
				else begin
					cycle_count <= cycle_count + 1;
					state <= STOP_BIT;
				end
			end
		endcase
	end
endmodule

module uart_rx(
    input clk_50M,
    input rx,
    output reg RxOut, // Debugger Rx
	 output reg [7:0] rx_msg,
    output reg rx_complete
);

	// Parâmetros
	parameter CYCLES_PER_BIT = 434;
	parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

	// Registradores
	reg [1:0] state = IDLE;
	reg [3:0] index;
	reg [10:0] cycle_count;
	reg ff_rx_1 = 1'b1, ff_rx_2 = 1'b1; // Flip flops

	// Variáveis ​​de paridade e correção de erros
	reg [3:0] P1, P2, P3, P4;				// Bits de paridade recebidos
	reg [3:0] position_loc;					// Posição do erro
	reg [11:0] receivedData = 12'b0;		// Armazenamento temporário dos dados de entrada

	//Sicronizador flip flop duplo para evitar metaestabilidade
	always @(posedge clk_50M) begin
		ff_rx_1 <= rx;
		ff_rx_2 <= ff_rx_1;
	end

	always @(posedge clk_50M) begin
		case(state)
		
			// Parado
			IDLE: begin
				cycle_count <= 0;
            rx_complete <= 0;
            index <= 0;
            receivedData <= 12'b0; // Limpa o registro antes de receber novos dados
            if (!ff_rx_2) state <= START;	// Se a linha de recepção estiver baixa (indicando o início da transmissão), muda para o estado START
        end

        // Recebendo o bit start
        START: begin
            if (cycle_count == (CYCLES_PER_BIT-1)/2) begin
                if (!ff_rx_2) begin
                    state <= DATA;
                    cycle_count <= 0;
                end else state <= IDLE;
            end else begin
                cycle_count <= cycle_count + 1;
                state <= START;
            end
        end

        // Recebendo os bits de dados
        DATA: begin
				if (cycle_count == CYCLES_PER_BIT-1) begin
					receivedData[index] <= ff_rx_2; // Armazena o bit recebido no receivedData
					RxOut <= ff_rx_2; // Saída para o Debugger do ModelSim
              
					cycle_count <= 0;
					if (index == 11) begin
						state <= STOP;
					end else begin
						index <= index + 1;
						state <= DATA;
					end
				end else begin
					cycle_count <= cycle_count + 1;
					state <= DATA;
				end
			end

        // Recebendo o bit stop
        STOP: begin
				if (cycle_count == CYCLES_PER_BIT-1) begin
					rx_complete <= 1;

					// Cálculo de paridade e correção de erro após recepção completa
					P1 = receivedData[0] + receivedData[2] + receivedData[4] + receivedData[6] + receivedData[8] + receivedData[10];
					P2 = receivedData[1] + receivedData[2] + receivedData[5] + receivedData[6] + receivedData[9] + receivedData[10];
					P3 = receivedData[3] + receivedData[4] + receivedData[5] + receivedData[6] + receivedData[11];
					P4 = receivedData[7] + receivedData[8] + receivedData[9] + receivedData[10] + receivedData[11];

					P1 = P1 % 2;
					P2 = P2 % 2;
					P3 = P3 % 2;
					P4 = P4 % 2;

					position_loc = (P1 + P2 * 2 + P3 * 4 + P4 * 8) - 1;
					
					// Corrige o erro se houver
					if (position_loc >= 0 && position_loc <= 11) begin
						receivedData[position_loc] = ~receivedData[position_loc];
					end

					// Mapeamento dos bits recebidos para o byte de saída (rx_msg)
					rx_msg[0] = receivedData[11];
					rx_msg[1] = receivedData[10];
					rx_msg[2] = receivedData[9];
					rx_msg[3] = receivedData[8];
					rx_msg[4] = receivedData[6];
					rx_msg[5] = receivedData[5];
					rx_msg[6] = receivedData[4];
					rx_msg[7] = receivedData[2];

					cycle_count <= 0;
					state <= IDLE;
				end else begin
					cycle_count <= cycle_count + 1;
					state <= STOP;
            end
			end
		endcase
	end
endmodule