# Comunicação Serial e Código de Hamming em FPGA

Este projeto foi desenvolvido por **João Luis da Cruz de Souza**, **Verônica Nascimento** e **Matheus Molinari**, estudantes da disciplina ENGC40 - Eletrônica Digital.

O objetivo deste projeto é estabelecer comunicação serial de 8 bits entre dois módulos em um FPGA (DE2-115 Altera), utilizando um protocolo UART para transmissão de dados e o **Código de Hamming** para detectar e corrigir erros que possam ocorrer durante a comunicação.

##  Visão Geral
A comunicação serial é realizada através de uma **Máquina de Estados** (FSM), que controla o envio de um bit de início (START), seguido pelos 8 bits de dados e, ao final, um bit de parada (STOP). A implementação do **Código de Hamming** adiciona bits de paridade que permitem a detecção e correção de erros de um único bit, garantindo maior confiabilidade na comunicação entre os módulos.

##  O Projeto
A implementação foi idealizada em **C/C++** e, posteriormente, traduzida para **Verilog**. O sistema de comunicação entre transmissor (**TX**) e receptor (**RX**) é baseado nos módulos `uart_tx` e `uart_rx`, que foram projetados para enviar e receber dados de 8 bits, verificando e corrigindo erros com bits de paridade Hamming.

### Estrutura do Código
- **Módulo SerialCommunication**: Integra os módulos de transmissão (`uart_tx`) e recepção (`uart_rx`), criando a comunicação serial entre os componentes do FPGA.
  - **Transmissor (`uart_tx`)**: A FSM do transmissor possui três estados principais: START, DATA e STOP.
    - A mensagem de 8 bits é carregada e os bits de paridade Hamming são calculados e inseridos na sequência antes do envio.
  - **Receptor (`uart_rx`)**: A FSM do receptor reconhece o início, dados e final da transmissão.
    - Após a recepção completa, os bits de paridade são verificados para identificar e corrigir possíveis erros de um único bit na mensagem recebida.


##  Diagrama de Estados
1. **Estado IDLE**: O sistema espera pela habilitação do transmissor ou pelo recebimento do sinal de start.
2. **Start Bit**: Um bit de início é enviado para sincronizar a transmissão.
3. **Data Bits**: A sequência de 8 bits é transmitida junto com os bits de paridade Hamming.
4. **Stop Bit**: Finaliza a transmissão e aguarda a confirmação de recepção.
A mesma lógica é utilizada no receptor.

## Código de Hamming
O **Código de Hamming** é usado para detectar e corrigir erros de um bit na comunicação serial. Para a mensagem de 8 bits, são adicionados 4 bits de paridade:

- **Paridade P1**: cobre os bits 1, 3, 5, 7, 9 e 11.
- **Paridade P2**: cobre os bits 2, 3, 6, 7, 10 e 11.
- **Paridade P3**: cobre os bits 4, 5, 6, 7 e 12.
- **Paridade P4**: cobre os bits 8, 9, 10, 11 e 12.

Esses bits de paridade são verificados no receptor para identificar a posição do erro e corrigir o bit incorreto, caso necessário.
