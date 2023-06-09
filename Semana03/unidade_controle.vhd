LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY unidade_controle IS
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        iniciar : IN STD_LOGIC;
        igualChaveMemoria : IN STD_LOGIC;
        igualRodadaEndereco : IN STD_LOGIC;
        ultimaRodada : IN STD_LOGIC;
        jogada : IN STD_LOGIC; --joga_feita
        fim_timeout : IN STD_LOGIC;
        fim_mostra_jogada : IN STD_LOGIC;
        modo : IN STD_LOGIC_VECTOR(1 DOWNTO 0); --dois bits concatenados dos sinais de modo
        zeraCEndereco : OUT STD_LOGIC;
        zeraCRodada : OUT STD_LOGIC;
        contaCEndereco : OUT STD_LOGIC;
        contaCRodada : OUT STD_LOGIC;
        zeraR : OUT STD_LOGIC;
        registraR : OUT STD_LOGIC;
        acertou : OUT STD_LOGIC;
        errou : OUT STD_LOGIC;
        pronto : OUT STD_LOGIC;
        db_estado : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        conta_timeout : OUT STD_LOGIC;
        reset_timeout : OUT STD_LOGIC;
        enableMostraJogada : OUT STD_LOGIC;
        zeraMostraJogada : OUT STD_LOGIC;
        escreveM : OUT STD_LOGIC;
        enableControlaSelecionaTimeout : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE fsm OF unidade_controle IS
    TYPE t_estado IS (inicial, preparacao, mostra_primeira_jogada, inicia_rodada, esperando, time_out, registra, comparacao, proximo, errado, final_da_rodada, marca_endereco_seguinte, mostra_proxima_jogada, incrementa_rodada, adiciona_jogada, proxima_rodada, escreve_rodada, correto);
    SIGNAL Eatual, Eprox : t_estado;
BEGIN

    -- memoria de estado
    PROCESS (clock, reset)
    BEGIN
        IF reset = '1' THEN
            Eatual <= inicial;
        ELSIF clock'event AND clock = '1' THEN
            Eatual <= Eprox;
        END IF;
    END PROCESS;

    -- logica de proximo estado
    Eprox <=
        inicial WHEN Eatual = inicial AND iniciar = '0' AND modo = "00" ELSE --loop do inicial
        preparacao WHEN Eatual = inicial AND iniciar = '1' AND modo /= "00" ELSE --passa para preparacao
        mostra_primeira_jogada WHEN Eatual = preparacao ELSE
        mostra_primeira_jogada WHEN Eatual = mostra_primeira_jogada AND fim_mostra_jogada = '0' AND jogada = '0' ELSE
        inicia_rodada WHEN Eatual = mostra_primeira_jogada AND (fim_mostra_jogada = '1' OR jogada = '1') ELSE --passa para inicia_rodada

        esperando WHEN Eatual = inicia_rodada ELSE --passa para esperando
        esperando WHEN Eatual = esperando AND jogada = '0' AND fim_timeout = '0' ELSE --loop esperando
        time_out WHEN Eatual = esperando AND fim_timeout = '1' ELSE --passa para o time_out
        time_out WHEN Eatual = time_out AND iniciar = '0' ELSE --loop do time_out

        preparacao WHEN Eatual = time_out AND iniciar = '1' ELSE --passa para preparacao
        registra WHEN Eatual = esperando AND jogada = '1' AND fim_timeout = '0' ELSE --passa para o registra
        comparacao WHEN Eatual = registra ELSE --passa para comparacao
        proximo WHEN Eatual = comparacao AND igualChaveMemoria = '1' AND igualRodadaEndereco = '0' ELSE --passa para proximo

        esperando WHEN Eatual = proximo ELSE --passa para esperando
        final_da_rodada WHEN Eatual = comparacao AND igualChaveMemoria = '1' AND igualRodadaEndereco = '1' ELSE --passa para final_da_rodada
        marca_endereco_seguinte WHEN Eatual = final_da_rodada AND (modo = "10" or modo = "11") AND ultimaRodada = '0' ELSE --passa para marca_endereco_seguinte
        mostra_proxima_jogada WHEN Eatual = marca_endereco_seguinte ELSE --passa para mostra_proxima_jogada

        mostra_proxima_jogada WHEN Eatual = mostra_proxima_jogada AND fim_mostra_jogada = '0' ELSE --loop do mostra_proxima_jogada
        incrementa_rodada WHEN Eatual = mostra_proxima_jogada AND fim_mostra_jogada = '1' ELSE --passa para o incrementa_rodada
        inicia_rodada WHEN Eatual = incrementa_rodada ELSE
        adiciona_jogada WHEN Eatual = final_da_rodada AND modo = "01" AND ultimaRodada = '0' ELSE --passa para adiciona_jogada
        adiciona_jogada WHEN Eatual = adiciona_jogada AND modo = "01" AND jogada = '0' ELSE --loop do adiciona_jogada

        proxima_rodada WHEN Eatual = adiciona_jogada AND modo = "01" AND jogada = '1' ELSE --passa para proxima_rodada
        escreve_rodada WHEN Eatual = proxima_rodada AND modo = "01" ELSE --passa para proxima_rodada
        inicia_rodada WHEN Eatual = escreve_rodada ELSE --passa para inicia_rodada
        correto WHEN Eatual = final_da_rodada AND ultimaRodada = '1' ELSE --passa para correto
        correto WHEN Eatual = correto AND iniciar = '0' ELSE --loop do correto

        preparacao WHEN Eatual = correto AND iniciar = '1' ELSE --passa para preparacao
        errado WHEN Eatual = comparacao AND igualChaveMemoria = '0' ELSE --passa para errado
        errado WHEN Eatual = errado AND iniciar = '0' ELSE --loop do errado
        preparacao WHEN Eatual = errado AND iniciar = '1' ELSE --passa para preparacao

        inicial;
    -- logica de saída (maquina de Moore)
    WITH Eatual SELECT
        zeraCEndereco <= '1' WHEN inicial | preparacao | inicia_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        zeraCRodada <= '1' WHEN inicial | preparacao,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        zeraR <= '1' WHEN inicial | preparacao | proximo | inicia_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        registraR <= '1' WHEN registra | proxima_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        contaCEndereco <= '1' WHEN proximo | proxima_rodada | marca_endereco_seguinte,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        contaCRodada <= '1' WHEN proxima_rodada | incrementa_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        escreveM <= '1' WHEN escreve_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        pronto <= '1' WHEN correto | errado | time_out,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        acertou <= '1' WHEN correto,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        errou <= '1' WHEN errado | time_out,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        conta_timeout <= '1' WHEN esperando,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        reset_timeout <= '1' WHEN proximo | inicia_rodada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        enableMostraJogada <= '1' WHEN mostra_primeira_jogada | mostra_proxima_jogada,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        zeraMostraJogada <= '1' WHEN preparacao | incrementa_rodada | esperando,
        '0' WHEN OTHERS;

    WITH Eatual SELECT
        enableControlaSelecionaTimeout <= '1' WHEN marca_endereco_seguinte,
        '0' WHEN OTHERS;

    -- saida de depuracao (db_estado)
    WITH Eatual SELECT
        db_estado <=
        "0000" WHEN inicial, --0
        "0001" WHEN preparacao, --1
        "0010" WHEN mostra_primeira_jogada, --2
        "0011" WHEN inicia_rodada, --3
        "0100" WHEN esperando, --4
        "0101" WHEN registra, --5
        "0110" WHEN comparacao, --6
        "0111" WHEN proximo, --7
        "1000" WHEN final_da_rodada, --8
        "1001" WHEN adiciona_jogada, --9
        "1010" WHEN proxima_rodada, --A
        "1011" WHEN time_out, --B
        "1100" WHEN correto, --C
        "1110" WHEN errado, --E
        "1111" WHEN OTHERS; --F
END fsm;