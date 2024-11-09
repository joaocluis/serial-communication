// Autor: João Luis, Matheus Molinari e Verônica Nascimento


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

	// Variáveis de paridade e correção de erros
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
				if (cycle_count == CYCLES_PER_BIT - 1) begin
					cycle_count <= 0;

					// Verifica se é o bit na posição 6 para adicionar um erro
					if (index == 6) begin
						receivedData[index] <= ~ff_rx_2;
						RxOut <= ~ff_rx_2;
					end else begin
						// Armazena o bit recebido e atualiza a saída para o debugger
						receivedData[index] <= ff_rx_2;
						RxOut <= ff_rx_2;
					end

					// Verifica se é o último bit de dados e muda o estado para STOP
					if (index == 11) begin
                      	$display("Dados recebidos com bits de paridade: %b", receivedData);
						state <= STOP;
					end else begin
                      	$display("Dados recebidos com bits de paridade bit a bit: %b", ff_rx_2);
						index <= index + 1;
						state <= DATA;
					end
				end else begin
					// Incrementa o contador de ciclos e mantém o estado DATA
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