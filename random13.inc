; # CONSTANTES #
FUNC_GET_TIME EQU 2CH ; Retorna - CH: hora (0 a 23) / CL: min (0 a 59) / DH: seg (0 a 59) / DL: cent (0 a 99)

; #----------------------------#RANDOMIZA��O#---------------------------------#

emb_atual DB ?

incremento DB ?

limite_linha DB ?
limite_coluna DB ?

var_posicao_hidro DB ?
indice_valido DW ?

incremento_hidro DB ?
incremento_hidro_ult DB ?   ; Ultima pe�a do hidro_avi�o

pos_vet DB 0   ; Contador para acessar a posi��o do vetor embarca��es
	       ; Na verdade foi feito isso pq todos os registradores t�o sendo utilizados
	       ; e � necess�rio guardar esse contador em algum lugar

posicao_velha DB ? ; Guarda a primeira posi��o que j� foi sorteada, para incrementar ou decrementar em busca de uma posi��o que ainda n�o tenha sido sorteada

flag_decrement DB ? ; Flag para indicar que de tanto incrementar o valor sorteado j� chegou ao fim do vetor e est� na hora de tentar decrementando

vetor_pos_sort_play DB 64 DUP(100) ; 100 � um valor inv�lido para saber que a posi��o do vetor ainda n�o foi ocupada
vetor_pos_sort_pc DB 64 DUP(100) ; Esse aqui � para o CPU

var_sel_vet DB 0      ;Variavel que seleciona o vetor dos jogadores para ser colocado as informa��es

vetor_embarcacoes  DB 2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44

		   ; LEGENDA PARA O JOGADOR             ; LEGENDA PARA O CPU

		   ; PORTA_AVI�ES DB 2                  ; PORTA_AVI�ES DB 24
		   ; ENCOURA�ADO DB 4                   ; ENCOURA�ADO DB 26
		   ; HIDRO_AVI�O_1 DB 6                 ; HIDRO_AVI�O_1 DB 28
		   ; HIDRO_AVI�O_2 DB 8                 ; HIDRO_AVI�O_2 DB 30
		   ; CRUZADOR_1 DB 10                   ; CRUZADOR_1 DB 32
		   ; CRUZADOR_2 DB 12                   ; CRUZADOR_2 DB 34
		   ; SUBMARINO_1 DB 14                  ; SUBMARINO_1 DB 36
		   ; SUBMARINO_2 DB 16                  ; SUBMARINO_2 DB 38
		   ; SUBMARINO_3 DB 18                  ; SUBMARINO_3 DB 40
		   ; SUBMARINO_4 DB 20                  ; SUBMARINO_4 DB 42
		   ; SUBMARINO_5 DB 22                  ; SUBMARINO_5 DB 44

vetor_play DB 4,0,0,2,0,2,0,0,0,0,4,0,0,0,6,0,0,0,0,2,0,0,2,0,0,0,0,0,2,6,0,0,0,2,2,0,2,2,0,8,0,4,0,0,2,6,0,0,0,2,2,0,2,2,0,8,0,0,0,0,2,0,0,2;64 DUP(0) ; Foi colocado 0 nas posi��es do vetor pq ap�s o preenchimento das informa��es das pe�as
			; os espa�os que sobrarem automaticamente ser�o �gua com valor 0H

vetor_cpu DB 0,0,0,0,2,2,0,2,0,0,8,0,0,0,2,2,0,2,2,0,8,0,0,0,0,2,6,0,0,0,2,2,0,0,0,0,8,0,4,0,0,0,6,0,0,0,2,2,0,0,0,0,8,0,4,0,0,2,6,0,2,0,2,0;64 DUP(0)


vetor_contador_random DB 5,4,3,3,2,2,1,1,1,1,1,5,4,3,3,2,2,1,1,1,1,1

			; Na ordem esse vetor cont�m o n�mero de pe�as de cada embarca��o segundo a ordem do "vetor_embarcacao"
			; para um contador para o armazenamento das informa��es no vetor dos jogadores

pontosJ DB 0
pontosPC DB 0

vetor_contador_placar DB 5,4,3,3,2,2,1,1,1,1,1

		       ; Para a verifica��o da pontua��o no placar

;msg DB 13,10,"TESTE: $" ; Mensagem para teste.
;msg DB "DEBUG: $" ; Mensagem para teste.

val_debug DB ?	  ; usada para passar como argumento para a macro "TESTE val"

;  # MACROS #
macro TESTE val { ; macro pra exibir um valor qualquer
  ; Salva os valores dos registradores na pilha
  PUSH AX
  PUSH DX

  MOV AH,09H
  MOV DX,msg
  INT 21H

  MOV AH,02H
  MOV DL,val
  ADD DL,"0"
  INT 21H
  MOV DL,13
  INT 21H
  MOV DL,10
  INT 21H

  MOV AH,00H
  INT 16H

  POP DX
  POP AX
}
		 ; LEMBRAR DE TIRAR ISSO
macro TESTAR val { ; macro pra exibir a mensagem de teste
  MOV AH,09H

  PUSH DX
  MOV DX,msg
  INT 21H

  MOV AH,02H
  MOV DL,13
  INT 21H
  MOV DL,10
  INT 21H
}

macro LIMITE {
	     MOV CL,[pos_vet] ; Move o valor para CL para ter acesso � posi��o do vetor_cont_random
	     MOV CH,0H	; caso haja alguma informa��o desnecess�ria, zera o registrador
	     MOV SI,CX
	     MOV EBX,vetor_contador_random
	     MOV AH,[BX+SI]    ; AH contem o numero de pe�as da embarca��o a ser colocada no vetor do jogador
	     MOV DH,8  ;
	     SUB DH,AH
	     INC DH	;Esses pontos fazer a verifica��o do intervalo a ser sorteado mais tarde em fun��o do tamanho da embarca��o
			 ;Pra isso foi utilizada a f�rmula F= (8 - numero de pe�as)+1
	     }



macro SORTEIO limite_col,limite_lin {
  MOV AH,0
  MOV AL,[emb_atual]
  CMP AL,2
    JE SORTEIO_PA  ; Sorteio de porta-avi�o
  CMP AL,24
    JE SORTEIO_PA
  CMP AL,4
    JE SORTEIO_ENC ; Sorteio de encoura�ado
  CMP AL,26
    JE SORTEIO_ENC

  JMP INICIO_SORTEIO

  SORTEIO_PA:
  CMP limite_col,8
    JE PA_VERTICAL

  ; PA Horizontal
  MOV limite_lin,1
  MOV limite_col,2
  JMP INICIO_SORTEIO

  PA_VERTICAL:
  MOV limite_col,1
  MOV limite_lin,2
  JMP INICIO_SORTEIO

  SORTEIO_ENC:
  CMP limite_col,8
    JE ENC_VERTICAL

  ; Enc Horizontal
  MOV AH,FUNC_GET_TIME
  INT 21H
  MOV AH,00H
  MOV AL,DL
  MOV DL,limite_col
  DIV DL
  MOV DL,AH
  ADD DL,56 ; Posiciona na �ltima linha
  JMP POSICAO_SORTEADA

  ENC_VERTICAL:
  MOV DH,7
  JMP COLUNA_SORTEADA

  INICIO_SORTEIO:
  MOV AH,FUNC_GET_TIME
  INT 21H
  MOV AH,00H
  MOV AL,DL
  MOV DL,limite_col   ; Se vcs numerarem a tabela 8X8 ser� verificado q a primeira pe�a do porta-avi�es s� pode estar na posi��o do
	     ; intervalo de 4 n�meros para dar espa�o, [0,3] ou [8,11] ou[16,19] ...  [56,59] por isso divide por 4
	     ; e nesse caso s� obter� o intervalo [0,3]

  DIV DL
  MOV DH,AH  ; Guarda a posi��o do invervalo [0,limite_col - 1] em DH

  COLUNA_SORTEADA:
  PUSH DX ; Salva DX na pilha, pois ele � alterado pela fun��o GET TIME
  MOV AH,FUNC_GET_TIME
	     ; Dessa vez ser� usado o random para determinar em qual linha a embarca��o ficar� somando o valor sorteado ao intervalo [0,3]
  INT 21H
  MOV AH,00H
  MOV AL,DL
  MOV DL,limite_lin   ; Corresponde ao n�mero de linhas do tabuleiro, no caso [0,limite_lin - 1]
  DIV DL
  POP DX ; Pega o valor de volta da pilha
  MOV AL,AH
  SHL AL,3   ; Multiplica a linha sorteada com 8 para ter acesso a linha do tabuleiro
  ADD DH,AL  ; A soma indica a primeira posi��o
  MOV DL,DH  ; Move a posi��o da pe�a para o byte menos significativo
  MOV DH,0H  ; Zera o byte mais significativo
	     ; Foi feito isso pq mais tarde iria usar o DX pra num haver complica��o

  POSICAO_SORTEADA:
  MOV AH,0
  MOV AL,[pos_vet]
  MOV SI,AX
  MOV EBX,vetor_contador_random
  MOV AL,[BX+SI] ; AL vai ter a quantidade de posi��es que faltam verificar

  MOV CL,0

  CMP [var_sel_vet],1	   ; Verifica qual dos vetores dos jogadores est� sendo trabalhado
  JE VETOR_CPU
  MOV EBX,vetor_play
  JMP CONTINUA_POSICAO_SORTEADA

  VETOR_CPU:
  MOV EBX,vetor_cpu

  CONTINUA_POSICAO_SORTEADA:
  MOV SI,DX
  CMP [BX+SI],CL    ; Verifica a posi��o sorteada
  JNE INICIO_SORTEIO

  ; C�digo que verifica se a posi��o j� foi sorteada anteriormente
  MOV SI,0
  LOOP_VERIF_POSICAO: ; Verifica se a posi��o n�o foi sorteada anteriormente
    CMP [var_sel_vet],1
      JE SORTEIO_CPU
    MOV EBX,vetor_pos_sort_play
    JMP CONTINUA_VERIF_POSICAO

    SORTEIO_CPU:
    MOV EBX,vetor_pos_sort_pc

    CONTINUA_VERIF_POSICAO:
    MOV CH,[BX+SI]
    CMP CH,100
      JE POSICAO_NOVA
    CMP CH,DL
      JE POSICAO_VELHA
    INC SI
    JMP LOOP_VERIF_POSICAO

    POSICAO_VELHA:
      MOV [posicao_velha],DL
      CMP DL,63
	JE CHEGOU_NO_FIM
      CMP [flag_decrement],1
	JE DECREMENTAR_POSICOES

      INC DL
      JMP POSICAO_ALTERADA

      DECREMENTAR_POSICOES:
      DEC DL

      POSICAO_ALTERADA:
      MOV SI,0
      JMP LOOP_VERIF_POSICAO

      CHEGOU_NO_FIM:
	MOV DL,[posicao_velha]
	MOV [flag_decrement],1
	DEC DL
	MOV SI,0
	JMP LOOP_VERIF_POSICAO



  POSICAO_NOVA:
    ; TESTE
    ;MOV [val_debug],DL
    ;TESTE [val_debug]

    MOV [BX+SI],DL
    MOV [flag_decrement],0
  ; Fim desse c�digo

  CMP [var_sel_vet],1
    JE VETOR_CPU_
  MOV EBX,vetor_play
  JMP POSICAO_NOVA_CONT

  VETOR_CPU_:
  MOV EBX,vetor_cpu

  POSICAO_NOVA_CONT:
  MOV SI,DX
  MOV [indice_valido],DX   ;Coloca a posi��o que � valida onde nao h� aproxima��es de pe�as na variavel

  ; As linhas abaixo verificam se n�o h� nenhuma pe�a vizinha
  VERIF_VIZINHAS:
  CMP [BX+SI],CL    ; Verifica se a posi��o atual est� livre
  JNE INICIO_SORTEIO

  CMP [pos_vet],2      ; Verifica se a pe�a � um hidro-avi�o
  JE INCREMENTA_HIDRO
  CMP [pos_vet],3
  JE INCREMENTA_HIDRO
  CMP [pos_vet],13	; Verifica se a pe�a � um hidro-avi�o
  JE INCREMENTA_HIDRO
  CMP [pos_vet],14
  JE INCREMENTA_HIDRO

  MOV DL,[incremento]
  JMP VERIFICACAO

  INCREMENTA_HIDRO:
  CMP AL,3	     ;Verifica qual pe�a do hidro-avi�o sera colocado : a 2� ou a 3� pe�a
  JE INCREM_2_PECA
  CMP AL,2
  JE INCREM_3_PECA
		    ;Colocado 0 em DL por precau��o pois caso seja sorteado o numero 7 cai na condi��o na label VERIF_PROX
		    ;o que n�o � viavel no momento
  JMP VERIFICACAO

  INCREM_2_PECA:
  MOV DL,[incremento_hidro]  ; Coloca o incremento da 2� pe�a do hidro_avi�o dependendo da posi��o em DL
  JMP VERIFICACAO

  INCREM_3_PECA:
  MOV DL,7	       ; Coloca o incremento da 3� pe�a do hidro_avi�o dependendo da posi��o em DL

  VERIFICACAO:
  ; Verifica se est� na borda esquerda
  CMP SI,0
  JE BORDA_ESQUERDA_LINHA_1
  CMP SI,8
  JE BORDA_ESQUERDA
  CMP SI,16
  JE BORDA_ESQUERDA
  CMP SI,24
  JE BORDA_ESQUERDA
  CMP SI,32
  JE BORDA_ESQUERDA
  CMP SI,40
  JE BORDA_ESQUERDA
  CMP SI,48
  JE BORDA_ESQUERDA
  CMP SI,56
  JE BORDA_ESQUERDA_LINHA_8


  ; Verifica se est� na borda direita
  CMP SI,7
  JE BORDA_DIREITA_LINHA_1
  CMP SI,15
  JE BORDA_DIREITA
  CMP SI,23
  JE BORDA_DIREITA
  CMP SI,31
  JE BORDA_DIREITA
  CMP SI,39
  JE BORDA_DIREITA
  CMP SI,47
  JE BORDA_DIREITA
  CMP SI,55
  JE BORDA_DIREITA
  CMP SI,63
  JE BORDA_DIREITA_LINHA_8

  ; Verifica se est� na primeira ou na �ltima linha
  CMP SI,8
  JL NAO_BORDA_LINHA_1
  CMP SI,55
  JG NAO_BORDA_LINHA_8

  ; Passou em todas as verifica��es, ent�o n�o est� na borda e n�o est� nem na primeira, nem na �ltima linha
  JMP NAO_BORDA

  BORDA_ESQUERDA_LINHA_1:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  BORDA_ESQUERDA:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  BORDA_ESQUERDA_LINHA_8:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  BORDA_DIREITA_LINHA_1:
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  BORDA_DIREITA:
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  BORDA_DIREITA_LINHA_8:
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  NAO_BORDA_LINHA_1:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  NAO_BORDA:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI + 8],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO
    JMP VERIF_PROX

  NAO_BORDA_LINHA_8:
    CMP [BX + SI + 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 1],CL
    JNE INICIO_SORTEIO
    CMP [BX + SI - 8],CL
    JNE INICIO_SORTEIO


  VERIF_PROX:
    DEC AL
    CMP AL,0
    JE NUMERO_SORTEADO

    CMP DL,7
    JE VERIF_INC_HIDRO
    JMP ADICIONAR_POSICAO

    VERIF_INC_HIDRO:
    CMP [var_posicao_hidro],0
    JE ADICIONAR_POSICAO

    SUBTRAI_POSICAO:
    SUB SI,DX
    JMP VERIF_VIZINHAS

    ADICIONAR_POSICAO:
    ADD SI,DX
    JMP VERIF_VIZINHAS


}

macro POSICIONA_EMB incr {
  MOV CL,[pos_vet]    ; Essa instru��o foi colocada seperada da instru��o de baixo para n�o influenciar no valor dos registers
  MOV CH,0H
  MOV SI,CX
  MOV DX,[indice_valido]    ;Pega da variavel o indice verificado como v�lido da label SORTEIO

  LOOP_PECAS:
  MOV EBX,vetor_embarcacoes
  MOV AL,[BX+SI]  ; Guarda a informa��o da embarca��o em AL

  CMP [var_sel_vet],1	   ; Verifica qual dos vetores dos jogadores est� sendo trabalhado
  JE VETOR_CPU_1
  MOV EBX,vetor_play
  JMP CONTINUA_LOOP_PECAS

  VETOR_CPU_1:
  MOV EBX,vetor_cpu


  CONTINUA_LOOP_PECAS:

  MOV SI,DX	 ; SI recebe a posi��o para posicionar a pe�a (na primeira intera��o, trata-se do n�mero sorteado)
  MOV CL,AL	 ; Guarda a informa��o da embarca��o em CL para mais tarde verificar o n�mero de pe�as da embarca��o

  ;;;;; AQUI SER� COLOCADO  A FUN��O PARA VERIFICAR SE A POSI��O DO VETOR_PLAY JA FOI OCUPADA

  MOV [BX+SI],AL ; Guarda a informa��o da embarca��o no vetor do jogador
  SUB CX,2	   ; A subtra��o de CL � feita para ter acesso � posi��o do vetor q contem o n�mero pe�as da embarca��o (vetor_contador_random)
  MOV AL,[pos_vet]
  MOV AH,0
  SUB CX,AX

  MOV EBX,vetor_contador_random     ;;;;;;;;;;
  MOV SI,CX
  MOV AL,[BX+SI]

  ;  MOV CH,AL    ; CH cont�m aqui o n�mero de pe�as da embarca��o para iniciar o contador

  ;CMP AH,0H    ; Compara��o feita para verificar se o label executado ser� na vertical ou na horizontal
  PUSH CX
  MOV CL,incr
  ADD DX,CX ; Isso para acessar a posi��o subsequente do "vetor_play" e guardar a informa��o
  POP CX
  DEC AL ; Diminuir o contador do n�mero de pe�as at� chegar a zero
  CMP AL,0
  JE  INC_POS_VET_EMB
  MOV [BX+SI],AL
  JMP LOOP_PECAS

  INC_POS_VET_EMB:
  MOV CX,SI
  INC CX
  MOV [pos_vet],CL

  ;IMPRIMIR_TELA   ;
  ;MOV AH,00H      ; EXECUTAR VISUALIZANDO CADA INSERS�O
  ;INT 16H         ;

  JMP MAIN
}

macro POS_HIDRO inc1,inc2{

			  MOV CL,[pos_vet]
			  MOV CH,0H
			  MOV SI,CX
			  MOV DI,0H ; servira de contador para cada pe�a do hidro_avi�o
			  MOV DX,[indice_valido]    ;Pega da variavel o indice verificado como v�lido da label SORTEIO

			  MOV EBX,vetor_embarcacoes
			  MOV AL,[BX+SI]

			  CMP [var_sel_vet],1	   ; Verifica qual dos vetores dos jogadores est� sendo trabalhado
			  JE VETOR_CPU_2
			  MOV EBX,vetor_play
			  JMP LOOP_POS_HIDRO

			  VETOR_CPU_2:
			  MOV EBX,vetor_cpu


			  LOOP_POS_HIDRO:
			  CMP DI,0H
			  JE PECA_1
			  CMP DI,1H
			  JE PECA_2
			  CMP DI,2H
			  JE PECA_3

			  PECA_1:
			  MOV SI,DX	   ;Colocar a primeira pe�a
			  JMP ARMAZENAR

			  PECA_2:
			  PUSH CX
			  MOV CL,inc1
			  ADD SI,CX	 ;Coloca a 2� pe�a dependendo da posi��o
			  POP CX
			  JMP ARMAZENAR

			  PECA_3:
			  PUSH AX
			  ADD DX,SI	   ;Para colocar a 3� posi��o
			  MOV AX,DX	   ;tira a media dos valores das 2 primeiras posi��es
			  MOV DL,2	   ;fazendo isso ser� encontrado uma posi��o entre as duas pe�as
			  DIV DL	   ;e depois soma a posi��o dependendo da posi��o da pe�a
			  ADD AL,inc2
			  MOV AH,0
			  MOV SI,AX
			  POP AX


			  ARMAZENAR:
		       ;   MOV AH,[BX+SI]   ; Verifica se o vetor_play ja cont�m alguma embarca��o
		       ;   CMP AH,0


			  MOV [BX+SI],AL
			  INC DI
			  CMP DI,3
			  JE INC_POS_VET
			  JMP LOOP_POS_HIDRO

			  INC_POS_VET:
			  INC CL
			  MOV [pos_vet],CL

			  JMP MAIN

			  }



macro IMPRIMIR_TELA {
		     MOV SI,0
		     MOV EBX,vetor_play

		     LOOP_IMPRIMIR:
		     MOV DL,[BX+SI]
		     ADD DL,'0'
		     MOV AH,02H
		     INT 21H
		     INC SI
		     CMP SI,64
		     JNE LOOP_IMPRIMIR

		     MOV AH,02H
		     MOV DL,13
		     INT 21H
		     MOV DL,10
		     INT 21H

		     MOV SI,0
		     MOV EBX,vetor_cpu

		     LOOP_IMPRIMIR_CPU:
		     MOV DL,[BX+SI]
		     SUB DL,11
		     ADD DL,'0'
		     MOV AH,02H
		     INT 21H
		     INC SI
		     CMP SI,64
		     JNE LOOP_IMPRIMIR_CPU

		     MOV AH,02H
		     MOV DL,13
		     INT 21H
		     MOV DL,10
		     INT 21H



		    }

; #--------------------------------------------------#


proc Gerar_Posicoes
  MAIN:

  CMP [pos_vet],10
  JLE MAIN_1
  CMP [pos_vet],11
  JE MUDAR_VETOR
  CMP [pos_vet],22
  JE FIM_RANDOM 	 ;AP�S A RANDOMIZA��O SEGUE O PROGRAMA PRINCIPAL

  JMP MAIN_1


 MUDAR_VETOR:
 MOV AH,[var_sel_vet]	  ;Mudar a variavel para trabalhar na randomiza��o com o vetor do CPU
 INC AH
 MOV [var_sel_vet],AH


  MAIN_1:
  MOV AH,0			;
  MOV AL,[pos_vet]		;
  MOV EBX,vetor_embarcacoes	 ; Armazena o c�digo da embarca��o atual
  MOV SI,AX			;
  MOV AL,[BX+SI]		;
  MOV [emb_atual],AL		;

  MOV AH,FUNC_GET_TIME
  INT 21H
  MOV AH,00H
  MOV AL,DL   ; Cent�simos sorteado e guardado em AL
  MOV DL,2
  DIV DL      ; Faz a divis�o AX/DL e guarda o quociente em AL e o resto em AH
  MOV AL,AH

  CMP [pos_vet],2     ; Condi��o que verifica se a embarca��o a ser sorteada � um hidroavi�o
  JE VERIF_HIDRO_POS
  CMP [pos_vet],3
  JE VERIF_HIDRO_POS
  CMP [pos_vet],13     ; Condi��o que verifica se a embarca��o a ser sorteada � um hidroavi�o
  JE VERIF_HIDRO_POS
  CMP [pos_vet],14
  JE VERIF_HIDRO_POS
  JMP VER_POSICAO

  VERIF_HIDRO_POS:
  MOV [var_posicao_hidro],AL
  CMP AL,0
  JE CONT_HORIZONTAL_HIDRO


  CONT_VERTICAL_HIDRO:
  MOV [incremento_hidro],16  ; se for colocado o hidro na vertical a segunda posi��o estar� na mesma coluna ap�s duas linhas
			     ; por isso foi colocado 16 para incremento da segunda posi��o
  MOV [incremento_hidro_ult],1
  MOV [limite_linha],6
  MOV [limite_coluna],7
  JMP CONT



  CONT_HORIZONTAL_HIDRO:
  MOV [incremento_hidro],2   ;se for colocado o hidro na horizontal a segunda posi��o estar� duas casas ap�s a primeira pe�a
  MOV[incremento_hidro_ult],8
  MOV [limite_linha],7
  MOV [limite_coluna],6
  JMP CONT

  VER_POSICAO:
  LIMITE      ; chama a macro pra saber o limite do intervalo a ser sorteado q est� em DH
  CMP AL,1    ; Se o resto da divis�o for 1, sorteia a pe�a na vertical
  JE VERTICAL

  ; Horizontal
  MOV [limite_coluna],DH
  MOV [limite_linha],8 ; ex: Porta-avi�o: coluna [0,3] / linha [0,7]
  MOV [incremento],1 ; Na horizontal, cada pe�a fica apenas 1 posi��o na frente
  JMP CONT

  VERTICAL:
  MOV [limite_linha],DH
  MOV [limite_coluna],8
  MOV [incremento],8 ; Na vertical, cada pe�a fica 8 posi��es na frente

  CONT:
  SORTEIO [limite_coluna],[limite_linha] ; ex: Porta-avi�o: coluna [0,7] / linha [0,3]

  NUMERO_SORTEADO:
  CMP [pos_vet],2     ;Condi��o que verifica se a embarca��o a ser sorteada � um hidroavi�o
  JE LABEL_POS_HIDRO
  CMP [pos_vet],3
  JE LABEL_POS_HIDRO
  CMP [pos_vet],13     ;Condi��o que verifica se a embarca��o a ser sorteada � um hidroavi�o
  JE LABEL_POS_HIDRO
  CMP [pos_vet],14
  JE LABEL_POS_HIDRO

  POSICIONA_EMB [incremento] ; Chama a macro e passa CL como argumento

  LABEL_POS_HIDRO:
  POS_HIDRO [incremento_hidro],[incremento_hidro_ult]

  FIM_RANDOM:
  IMPRIMIR_TELA  ; Chama a macro para imprimir os valores armazenados no vetor_play na tela
  RET
  ; JMP GUAR_INF_EMB
endp