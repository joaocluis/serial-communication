// Autor: João Luis, Matheus Molinari e Verônica Nascimento


module uart_top_tb;
    reg clk = 0;
    reg tx_en = 0;
    reg [7:0] tx_data = 0;
	 wire [7:0] rx_msg;
    wire tx;
	 wire rx;
    wire tx_done;
    wire rx_complete;

    // Instância do módulo SerialCommunication
    SerialCommunication uut (
        .clk_50M(clk),
        .tx_en(tx_en),
        .tx_data(tx_data),
        .tx(tx),
		  .rx(rx),
        .tx_done(tx_done),
        .rx_msg(rx_msg),
        .rx_complete(rx_complete)
    );

    // Geração do clock
    always begin
        #10 clk = ~clk;  // 50 MHz clock
    end

    // Sequência de teste
    initial begin
        // Inicialização
        @(posedge clk);
        tx_en <= 0;
        tx_data <= 8'h00;

        // Transmitir dados
        repeat(10) begin
            @(posedge clk);
            tx_en <= 1'b1;
            tx_data <= 8'b11110000; // Dados aleatórios entre 0 e 255
            @(posedge clk);
            tx_en <= 1'b0;
            @(posedge tx_done); // Espera a transmissão terminar

            // Verifica os dados recebidos
            @(posedge rx_complete);
            if (rx_msg == tx_data) 
                $display("Correct byte received: %h", rx_msg);
            else 
                $display("Incorrect byte received: %h (expected %h)", rx_msg, tx_data);
        end
        
        // Finaliza a simulação
        $display("Test completed.");
        $finish;
    end
endmodule