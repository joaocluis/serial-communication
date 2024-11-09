
// Autor: João Luis, Matheus Molinari e Verônica Nascimento

`timescale 1ns/1ns
module uart_rx_tb;
	
	//wire to show output
	wire [7:0] rx_msg;
	wire rx_complete;
	
	//registers to drive input
	reg clk;
	reg rx;
	
	//additional resgisters
  	reg [11:0] data;
	integer i;
	
	//instance of the design module
	uart_rx uut(
		.clk_50M(clk),
		.rx(rx),
		.rx_msg(rx_msg),
		.rx_complete(rx_complete)
    );
				
  	//clock generation
	always begin
		#10;
		clk = ~clk;
	end
  
	//run the test sequence
	initial begin
		clk=0;

      data=12'b000001111111;
      rx=0;
      #8680;
      for(i=0;i<12;i=i+1) begin
        rx=data[i];
        #8680;
      end
      rx=1;
      #10;
      
      // Aguarda até a recepção ser concluída
      wait (rx_complete);
      $display("Sucess Receiver.");

      // Verifica se a recepção foi concluída e exibe os dados transmitidos
      if (rx_complete) begin
        $display("Mensagem recebida: %b", rx_msg);
	  end else begin
        $display("Erro no Receiver.");
      end

      // Aguarda alguns ciclos de clock e termina a simulação
      #50;
      $finish;
	end 
endmodule