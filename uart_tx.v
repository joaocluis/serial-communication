// Autor: João Luis, Matheus Molinari e Verônica Nascimento


module uart_tx(
	input clk_50M,
	input tx_en,
	input [7:0] data,
	output reg tx,
	output reg tx_done
);			
	
	// Parâmetros
	parameter CYCLES_PER_BIT = 434; // Frequência do Clock / Baud Rate
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
                        $display("Dados transmitidos com bits de paridade: %b", mensagem);
						index <= 0;
						state <= STOP_BIT;
					end
					else begin
                      	$display("Dados transmitidos com bits de paridade bit a bit: %b", tx);
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