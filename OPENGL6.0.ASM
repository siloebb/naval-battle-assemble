
; OpenGL programming example

format PE GUI 4.0
entry start


include 'win32a.inc'
include 'opengl.inc'
include 'random13.inc'


section '.data' data readable writeable

ID_LABEL_DATE	   = 101
ID_LABEL_TIME	   = 102
ID_LOCAL_TIME	   = 103

ID_EDIT_DATE	   = 104
ID_EDIT_TIME	   = 105
ID_EDIT_LOCAL	   = 106

  _title db 'BATALHA NAVAL',0
  _class db 'FASMOPENGL32',0
  theta GLfloat 0.6

  wc WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,NULL,NULL,_class

  hwnd dd ?
  hdc dd ?
  hrc dd ?

  msg MSG
  rc RECT
  pfd PIXELFORMATDESCRIPTOR

  lpSystemTime	   SYSTEMTIME
  _format_date	   db '%02u/%02u/%4u',0
  _buffer_date	   rb 11					; 11 bytes reserved (xx/xx/xxxx0)

  _format_time	   db '%02d:%02d:%02d:%02d'
  _buffer_time	   rb 9 					; 9 bytes reserved (xx:xx:xx0)
  _buffer_loc_time rb 9

  active dd ?
;VARIÁVEIS DE CONTROLE DO JOGO
  ;pontosPC DB 0
 ; pontosJ DB 0
  indc DB ?
  lin DB 8
  linha DW ?
  coluna DW ?
  col DB 8

  vez_pc DB 0
  fim_de_jogo DB 0
;  vetor_cpu DB 0,0,2,2,2,2,2,0,8,0,4,0,0,2,6,0,0,0,2,2,2,2,2,0,8,0,4,0,0,2,6,0,0,0,2,2,2,2,2,0,8,0,4,0,0,2,6,0,0,0,2,2,2,2,2,0,8,0,4,0,0,2,6,0;64 DUP(0)
;  vetor_play DB 64 DUP(1)

  tstvertX1 DD 0.0
  tstvertY1 DD -1.0
  tstvertX2 DD ?
  tstvertY2 DD ?
  tamanho_alvo DD 0.055
  dist_alvoX DD 0.075
  dist_alvoY DD -0.075
  inicio_alvoX DD -0.79
  inicio_alvoY DD 0.735
  tstcorR DD 0.0; cores do alvo
  tstcorG DD 0.0
  tstcorB DD 0.0

  winCor DD 0.0
  pc_winCor DD 0.0
  u_winCor DD 1.0

;OpenGL
  cores_celulasR DD 64 dup(-1.1)	;Cor R - Vermelho
  cores_celulasG DD 64 dup(0.2)        ;Cor G - Verde
  cores_celulasB DD 64 dup(-1.5)	;Cor B - Azul

  cores_celulasR_PC DD 64 dup(-1.1)	   ;Cor R - Vermelho
  cores_celulasG_PC DD 64 dup(0.2)	  ;Cor G - Verde
  cores_celulasB_PC DD 64 dup(-1.5)	   ;Cor B - Azul

  cor_R DD ?
  cor_G DD ?
  cor_B DD ?

  corDoFundo DD 0.0
  corDasCoordenadas DD 1.0

  ; Cor do numero que representa unidade do Jogador
  corAUnitJ DD 0.0
  corBUnitJ DD 0.0
  corCUnitJ DD 0.0
  corDUnitJ DD 0.0
  corEUnitJ DD 0.0
  corFUnitJ DD 0.0
  corGUnitJ DD 0.0

  ; Cor do numero que representa Dezena do Jogador
  corADezenJ DD 0.0
  corBDezenJ DD 0.0
  corCDezenJ DD 0.0
  corDDezenJ DD 0.0
  corEDezenJ DD 0.0
  corFDezenJ DD 0.0
  corGDezenJ DD 0.0

  ;Cor do Sinal do jogador
  corSinalJ DD 0.0

    ; Cor do numero que representa unidade do Computador
  corAUnitPC DD 0.0
  corBUnitPC DD 0.0
  corCUnitPC DD 0.0
  corDUnitPC DD 0.0
  corEUnitPC DD 0.0
  corFUnitPC DD 0.0
  corGUnitPC DD 0.0

  ; Cor do numero que representa unidade do Computador
  corADezenPC DD 0.0
  corBDezenPC DD 0.0
  corCDezenPC DD 0.0
  corDDezenPC DD 0.0
  corEDezenPC DD 0.0
  corFDezenPC DD 0.0
  corGDezenPC DD 0.0

  ;Cor do Sinal do computador
  corSinalPC DD 0.0




section '.code' code readable executable


  start:
       ; call Gerar_Posicoes
	invoke	GetModuleHandle,0
	mov	[wc.hInstance],eax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon],eax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],eax
	invoke	RegisterClass,wc
	invoke	CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW+WS_CLIPCHILDREN+WS_CLIPSIBLINGS,16,16,800,600,NULL,NULL,[wc.hInstance],NULL
	mov	[hwnd],eax

  msg_loop:
	invoke	InvalidateRect,[hwnd],NULL,FALSE
	invoke	GetMessage,msg,NULL,0,0
	or	eax,eax
	jz	end_loop
	invoke	TranslateMessage,msg
	invoke	DispatchMessage,msg
	jmp	msg_loop

  end_loop:
	invoke	ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
	push	ebx esi edi
	cmp	[wmsg],WM_CREATE
	je	.wmcreate
	cmp	[wmsg],WM_SIZE
	je	.wmsize
	cmp	[wmsg],WM_ACTIVATEAPP
	je	.wmactivateapp
	cmp	[wmsg],WM_PAINT
	je	.wmpaint
	cmp	[wmsg],WM_KEYDOWN
	je	.wmkeydown
	cmp	[wmsg],WM_DESTROY
	je	.wmdestroy
  .defwndproc:
	invoke	DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
       ; stdcall sys_time,[hwnd]
	jmp	.finish
  .wmcreate:
	invoke	GetDC,[hwnd]
	mov	[hdc],eax
	mov	edi,pfd
	mov	ecx,sizeof.PIXELFORMATDESCRIPTOR shr 2
	xor	eax,eax
	rep	stosd
	mov	[pfd.nSize],sizeof.PIXELFORMATDESCRIPTOR
	mov	[pfd.nVersion],1
	mov	[pfd.dwFlags],PFD_SUPPORT_OPENGL+PFD_DOUBLEBUFFER+PFD_DRAW_TO_WINDOW
	mov	[pfd.dwLayerMask],PFD_MAIN_PLANE
	mov	[pfd.iPixelType],PFD_TYPE_RGBA
	mov	[pfd.cColorBits],16
	mov	[pfd.cDepthBits],16
	mov	[pfd.cAccumBits],0
	mov	[pfd.cStencilBits],0
	invoke	ChoosePixelFormat,[hdc],pfd
	invoke	SetPixelFormat,[hdc],eax,pfd
	invoke	wglCreateContext,[hdc]
	mov	[hrc],eax
	invoke	wglMakeCurrent,[hdc],[hrc]
	invoke	GetClientRect,[hwnd],rc
	invoke	glViewport,0,0,[rc.right],[rc.bottom]
	xor	eax,eax
	jmp	.finish
  .wmsize:
	invoke	GetClientRect,[hwnd],rc
	invoke	glViewport,0,0,[rc.right],[rc.bottom]
	invoke	InvalidateRect,[hwnd],NULL,FALSE
	xor	eax,eax
	jmp	.placarJ;.finish
  .wmactivateapp:
	push	[wmsg]
	pop	[active]
	xor	eax,eax
	jmp	.finish
  .wmpaint:

	;invoke  MessageBox,HWND_DESKTOP,"Hi! I'm the example program!","Win32 Assembly",MB_ICONERROR

	invoke	glClear,GL_COLOR_BUFFER_BIT
	invoke	glBegin,GL_QUADS

	;Quadrado para dar a cor de fundo.
	invoke	glColor3f,[corDoFundo],[corDoFundo],[corDoFundo]
	invoke	glVertex2f,-1.0,-1.0
	invoke	glVertex2f,1.0,-1.0
	invoke	glVertex2f,1.0,1.0
	invoke	glVertex2f,-1.0,1.0
;====================================================
	; MENSAGEM DE VITORIA

	; YOU WIN

	invoke	glColor3f,[u_winCor],0.0,0.0

	;y

      ;  invoke  glVertex2f,-0.70,-0.75
      ;  invoke  glVertex2f,-0.65,-0.75
      ;  invoke  glVertex2f,-0.60,-0.85
      ;  invoke  glVertex2f,-0.65,-0.85

      ;  invoke  glVertex2f,-0.6,-0.75
      ;  invoke  glVertex2f,-0.55,-0.75
      ;  invoke  glVertex2f,-0.60,-0.85
      ;  invoke  glVertex2f,-0.65,-0.85

      ;  invoke  glVertex2f,-0.65,-0.85
      ;  invoke  glVertex2f,-0.60,-0.85
      ;  invoke  glVertex2f,-0.60,-0.95
      ;  invoke  glVertex2f,-0.65,-0.95

	;O

      ;  invoke  glVertex2f,-0.5,-0.75
      ;  invoke  glVertex2f,-0.45,-0.75
      ;  invoke  glVertex2f,-0.45,-0.95
      ;  invoke  glVertex2f,-0.5,-0.95
      ;
      ;  invoke  glVertex2f,-0.5,-0.75
      ;  invoke  glVertex2f,-0.35,-0.75
      ;  invoke  glVertex2f,-0.35,-0.80
      ;  invoke  glVertex2f,-0.5,-0.80

      ;  invoke  glVertex2f,-0.4,-0.75
      ;  invoke  glVertex2f,-0.35,-0.75
      ;  invoke  glVertex2f,-0.35,-0.95
      ;  invoke  glVertex2f,-0.4,-0.95
      ;
      ;  invoke  glVertex2f,-0.5,-0.9
      ;  invoke  glVertex2f,-0.35,-0.9
      ;  invoke  glVertex2f,-0.35,-0.95
      ;  invoke  glVertex2f,-0.5,-0.95

	; U

	invoke	glVertex2f,-0.3,-0.75
	invoke	glVertex2f,-0.25,-0.75
	invoke	glVertex2f,-0.25,-0.95
	invoke	glVertex2f,-0.3,-0.95

	invoke	glVertex2f,-0.2,-0.75
	invoke	glVertex2f,-0.15,-0.75
	invoke	glVertex2f,-0.15,-0.95
	invoke	glVertex2f,-0.2,-0.95

	invoke	glVertex2f,-0.3,-0.9
	invoke	glVertex2f,-0.15,-0.9
	invoke	glVertex2f,-0.15,-0.95
	invoke	glVertex2f,-0.3,-0.95

	; W
	invoke	glColor3f,[winCor],0.0,0.0
	invoke	glVertex2f,0.05,-0.75
	invoke	glVertex2f,0.1,-0.75
	invoke	glVertex2f,0.15,-0.95
	invoke	glVertex2f,0.1,-0.95

	invoke	glVertex2f,0.15,-0.80
	invoke	glVertex2f,0.2,-0.80
	invoke	glVertex2f,0.15,-0.95
	invoke	glVertex2f,0.1,-0.95

	invoke	glVertex2f,0.15,-0.8
	invoke	glVertex2f,0.2,-0.8
	invoke	glVertex2f,0.25,-0.95
	invoke	glVertex2f,0.2,-0.95

	invoke	glVertex2f,0.25,-0.75
	invoke	glVertex2f,0.30,-0.75
	invoke	glVertex2f,0.25,-0.95
	invoke	glVertex2f,0.2,-0.95

       ; I

	invoke	glVertex2f,0.35,-0.75
	invoke	glVertex2f,0.40,-0.75
	invoke	glVertex2f,0.40,-0.95
	invoke	glVertex2f,0.35,-0.95

	; N

	invoke	glVertex2f,0.45,-0.75
	invoke	glVertex2f,0.5,-0.75
	invoke	glVertex2f,0.5,-0.95
	invoke	glVertex2f,0.45,-0.95

	invoke	glVertex2f,0.45,-0.75
	invoke	glVertex2f,0.5,-0.75
	invoke	glVertex2f,0.6,-0.95
	invoke	glVertex2f,0.55,-0.95

	invoke	glVertex2f,0.55,-0.75
	invoke	glVertex2f,0.6,-0.75
	invoke	glVertex2f,0.6,-0.95
	invoke	glVertex2f,0.55,-0.95

       ; !

	invoke	glVertex2f,0.69,-0.75
	invoke	glVertex2f,0.76,-0.75
	invoke	glVertex2f,0.75,-0.885
	invoke	glVertex2f,0.7,-0.885

	invoke	glVertex2f,0.7,-0.9
	invoke	glVertex2f,0.75,-0.9
	invoke	glVertex2f,0.75,-0.95
	invoke	glVertex2f,0.7,-0.95

      ; PC WIN

	invoke	glColor3f,[pc_winCor],0.0,0.0

       ; P

	invoke	glVertex2f,-0.7,-0.75
	invoke	glVertex2f,-0.65,-0.75
	invoke	glVertex2f,-0.65,-0.95
	invoke	glVertex2f,-0.7,-0.95

	invoke	glVertex2f,-0.7,-0.75
	invoke	glVertex2f,-0.55,-0.75
	invoke	glVertex2f,-0.55,-0.80
	invoke	glVertex2f,-0.7,-0.80

	invoke	glVertex2f,-0.6,-0.75
	invoke	glVertex2f,-0.55,-0.75
	invoke	glVertex2f,-0.55,-0.90
	invoke	glVertex2f,-0.6,-0.90

	invoke	glVertex2f,-0.7,-0.85
	invoke	glVertex2f,-0.55,-0.85
	invoke	glVertex2f,-0.55,-0.90
	invoke	glVertex2f,-0.7,-0.90

	; C

	invoke	glVertex2f,-0.5,-0.75
	invoke	glVertex2f,-0.35,-0.75
	invoke	glVertex2f,-0.35,-0.80
	invoke	glVertex2f,-0.5,-0.80

	invoke	glVertex2f,-0.5,-0.75
	invoke	glVertex2f,-0.45,-0.75
	invoke	glVertex2f,-0.45,-0.95
	invoke	glVertex2f,-0.5,-0.95

	invoke	glVertex2f,-0.5,-0.90
	invoke	glVertex2f,-0.35,-0.90
	invoke	glVertex2f,-0.35,-0.95
	invoke	glVertex2f,-0.5,-0.95


 ;=====================================================


	;Quadrados do computador, em sequência a1,a2,a3,...,a8,b1,b2,...,h8

	;QUADRADO DOS COMPUTADOR
	;a1

	MOV DX,0
	MOV EBX,cores_celulasR
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX

	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX

	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f, [cor_R],[cor_G],[cor_B]   ;COR DA AGUA   RGB
	invoke	glVertex2f,-0.8,0.8
	invoke	glVertex2f,-0.725,0.8
	invoke	glVertex2f,-0.725,0.725
	invoke	glVertex2f,-0.8,0.725

	;a2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX

	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX

	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.8
	invoke	glVertex2f,-0.650,0.8
	invoke	glVertex2f,-0.650,0.725
	invoke	glVertex2f,-0.725,0.725

	;a3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.8
	invoke	glVertex2f,-0.575,0.8
	invoke	glVertex2f,-0.575,0.725
	invoke	glVertex2f,-0.650,0.725

	;a4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.8
	invoke	glVertex2f,-0.5,0.8
	invoke	glVertex2f,-0.5,0.725
	invoke	glVertex2f,-0.575,0.725

	;a5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.8
	invoke	glVertex2f,-0.425,0.8
	invoke	glVertex2f,-0.425,0.725
	invoke	glVertex2f,-0.5,0.725

	;a6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.8
	invoke	glVertex2f,-0.350,0.8
	invoke	glVertex2f,-0.350,0.725
	invoke	glVertex2f,-0.425,0.725

	;a7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.8
	invoke	glVertex2f,-0.275,0.8
	invoke	glVertex2f,-0.275,0.725
	invoke	glVertex2f,-0.350,0.725

	;a8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.8
	invoke	glVertex2f,-0.2,0.8
	invoke	glVertex2f,-0.2,0.725
	invoke	glVertex2f,-0.275,0.725

	;b1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.725
	invoke	glVertex2f,-0.725,0.725
	invoke	glVertex2f,-0.725,0.650
	invoke	glVertex2f,-0.8,0.650

	;b2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.725
	invoke	glVertex2f,-0.650,0.725
	invoke	glVertex2f,-0.650,0.650
	invoke	glVertex2f,-0.725,0.650

	;b3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.725
	invoke	glVertex2f,-0.575,0.725
	invoke	glVertex2f,-0.575,0.650
	invoke	glVertex2f,-0.650,0.650

	;b4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.725
	invoke	glVertex2f,-0.5,0.725
	invoke	glVertex2f,-0.5,0.650
	invoke	glVertex2f,-0.575,0.650

	;b5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.725
	invoke	glVertex2f,-0.425,0.725
	invoke	glVertex2f,-0.425,0.650
	invoke	glVertex2f,-0.5,0.650

	;b6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.725
	invoke	glVertex2f,-0.350,0.725
	invoke	glVertex2f,-0.350,0.650
	invoke	glVertex2f,-0.425,0.650

	;b7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.725
	invoke	glVertex2f,-0.275,0.725
	invoke	glVertex2f,-0.275,0.650
	invoke	glVertex2f,-0.350,0.650

	;b8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.725
	invoke	glVertex2f,-0.2,0.725
	invoke	glVertex2f,-0.2,0.650
	invoke	glVertex2f,-0.275,0.650

	;c1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.650
	invoke	glVertex2f,-0.725,0.650
	invoke	glVertex2f,-0.725,0.575
	invoke	glVertex2f,-0.8,0.575

	;c2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.650
	invoke	glVertex2f,-0.650,0.650
	invoke	glVertex2f,-0.650,0.575
	invoke	glVertex2f,-0.725,0.575

	;c3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.650
	invoke	glVertex2f,-0.575,0.650
	invoke	glVertex2f,-0.575,0.575
	invoke	glVertex2f,-0.650,0.575

	;c4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.650
	invoke	glVertex2f,-0.5,0.650
	invoke	glVertex2f,-0.5,0.575
	invoke	glVertex2f,-0.575,0.575

	;c5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.650
	invoke	glVertex2f,-0.425,0.650
	invoke	glVertex2f,-0.425,0.575
	invoke	glVertex2f,-0.5,0.575

	;c6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.650
	invoke	glVertex2f,-0.350,0.650
	invoke	glVertex2f,-0.350,0.575
	invoke	glVertex2f,-0.425,0.575

	;c7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.650
	invoke	glVertex2f,-0.275,0.650
	invoke	glVertex2f,-0.275,0.575
	invoke	glVertex2f,-0.350,0.575

	;c8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.650
	invoke	glVertex2f,-0.2,0.650
	invoke	glVertex2f,-0.2,0.575
	invoke	glVertex2f,-0.275,0.575

	;d1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.575
	invoke	glVertex2f,-0.725,0.575
	invoke	glVertex2f,-0.725,0.5
	invoke	glVertex2f,-0.8,0.5

	;d2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.575
	invoke	glVertex2f,-0.650,0.575
	invoke	glVertex2f,-0.650,0.5
	invoke	glVertex2f,-0.725,0.5

	;d3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.575
	invoke	glVertex2f,-0.575,0.575
	invoke	glVertex2f,-0.575,0.5
	invoke	glVertex2f,-0.650,0.5

	;d4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.575
	invoke	glVertex2f,-0.5,0.575
	invoke	glVertex2f,-0.5,0.5
	invoke	glVertex2f,-0.575,0.5

	;d5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.575
	invoke	glVertex2f,-0.425,0.575
	invoke	glVertex2f,-0.425,0.5
	invoke	glVertex2f,-0.5,0.5

	;d6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.575
	invoke	glVertex2f,-0.350,0.575
	invoke	glVertex2f,-0.350,0.5
	invoke	glVertex2f,-0.425,0.5

	;d7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.575
	invoke	glVertex2f,-0.275,0.575
	invoke	glVertex2f,-0.275,0.5
	invoke	glVertex2f,-0.350,0.5

	;d8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.575
	invoke	glVertex2f,-0.2,0.575
	invoke	glVertex2f,-0.2,0.5
	invoke	glVertex2f,-0.275,0.5

	;e1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.5
	invoke	glVertex2f,-0.725,0.5
	invoke	glVertex2f,-0.725,0.425
	invoke	glVertex2f,-0.8,0.425

	;e2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.5
	invoke	glVertex2f,-0.650,0.5
	invoke	glVertex2f,-0.650,0.425
	invoke	glVertex2f,-0.725,0.425

	;e3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.5
	invoke	glVertex2f,-0.575,0.5
	invoke	glVertex2f,-0.575,0.425
	invoke	glVertex2f,-0.650,0.425

	;e4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.5
	invoke	glVertex2f,-0.5,0.5
	invoke	glVertex2f,-0.5,0.425
	invoke	glVertex2f,-0.575,0.425

	;e5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.5
	invoke	glVertex2f,-0.425,0.5
	invoke	glVertex2f,-0.425,0.425
	invoke	glVertex2f,-0.5,0.425

	;e6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.5
	invoke	glVertex2f,-0.350,0.5
	invoke	glVertex2f,-0.350,0.425
	invoke	glVertex2f,-0.425,0.425

	;e7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.5
	invoke	glVertex2f,-0.275,0.5
	invoke	glVertex2f,-0.275,0.425
	invoke	glVertex2f,-0.350,0.425

	;e8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.5
	invoke	glVertex2f,-0.2,0.5
	invoke	glVertex2f,-0.2,0.425
	invoke	glVertex2f,-0.275,0.425

	;f1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.425
	invoke	glVertex2f,-0.725,0.425
	invoke	glVertex2f,-0.725,0.350
	invoke	glVertex2f,-0.8,0.350

	;f2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.425
	invoke	glVertex2f,-0.650,0.425
	invoke	glVertex2f,-0.650,0.350
	invoke	glVertex2f,-0.725,0.350

	;f3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.425
	invoke	glVertex2f,-0.575,0.425
	invoke	glVertex2f,-0.575,0.350
	invoke	glVertex2f,-0.650,0.350

	;f4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.425
	invoke	glVertex2f,-0.5,0.425
	invoke	glVertex2f,-0.5,0.350
	invoke	glVertex2f,-0.575,0.350

	;f5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.425
	invoke	glVertex2f,-0.425,0.425
	invoke	glVertex2f,-0.425,0.350
	invoke	glVertex2f,-0.5,0.350

	;f6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.425
	invoke	glVertex2f,-0.350,0.425
	invoke	glVertex2f,-0.350,0.350
	invoke	glVertex2f,-0.425,0.350

	;f7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.425
	invoke	glVertex2f,-0.275,0.425
	invoke	glVertex2f,-0.275,0.350
	invoke	glVertex2f,-0.350,0.350

	;f8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.425
	invoke	glVertex2f,-0.2,0.425
	invoke	glVertex2f,-0.2,0.350
	invoke	glVertex2f,-0.275,0.350

	;g1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.350
	invoke	glVertex2f,-0.725,0.350
	invoke	glVertex2f,-0.725,0.275
	invoke	glVertex2f,-0.8,0.275

	;g2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.350
	invoke	glVertex2f,-0.650,0.350
	invoke	glVertex2f,-0.650,0.275
	invoke	glVertex2f,-0.725,0.275

	;g3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.350
	invoke	glVertex2f,-0.575,0.350
	invoke	glVertex2f,-0.575,0.275
	invoke	glVertex2f,-0.650,0.275

	;g4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.350
	invoke	glVertex2f,-0.5,0.350
	invoke	glVertex2f,-0.5,0.275
	invoke	glVertex2f,-0.575,0.275

	;g5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.350
	invoke	glVertex2f,-0.425,0.350
	invoke	glVertex2f,-0.425,0.275
	invoke	glVertex2f,-0.5,0.275

	;g6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.350
	invoke	glVertex2f,-0.350,0.350
	invoke	glVertex2f,-0.350,0.275
	invoke	glVertex2f,-0.425,0.275

	;g7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.350
	invoke	glVertex2f,-0.275,0.350
	invoke	glVertex2f,-0.275,0.275
	invoke	glVertex2f,-0.350,0.275

	;g8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.350
	invoke	glVertex2f,-0.2,0.350
	invoke	glVertex2f,-0.2,0.275
	invoke	glVertex2f,-0.275,0.275

	;h1
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.8,0.275
	invoke	glVertex2f,-0.725,0.275
	invoke	glVertex2f,-0.725,0.2
	invoke	glVertex2f,-0.8,0.2

	;h2
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.725,0.275
	invoke	glVertex2f,-0.650,0.275
	invoke	glVertex2f,-0.650,0.2
	invoke	glVertex2f,-0.725,0.2

	;h3
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.650,0.275
	invoke	glVertex2f,-0.575,0.275
	invoke	glVertex2f,-0.575,0.2
	invoke	glVertex2f,-0.650,0.2

	;h4
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.575,0.275
	invoke	glVertex2f,-0.5,0.275
	invoke	glVertex2f,-0.5,0.2
	invoke	glVertex2f,-0.575,0.2

	;h5
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.5,0.275
	invoke	glVertex2f,-0.425,0.275
	invoke	glVertex2f,-0.425,0.2
	invoke	glVertex2f,-0.5,0.2

	;h6
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.425,0.275
	invoke	glVertex2f,-0.350,0.275
	invoke	glVertex2f,-0.350,0.2
	invoke	glVertex2f,-0.425,0.2

	;h7
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.350,0.275
	invoke	glVertex2f,-0.275,0.275
	invoke	glVertex2f,-0.275,0.2
	invoke	glVertex2f,-0.350,0.2

	;h8
	MOV EBX,cores_celulasR
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,-0.275,0.275
	invoke	glVertex2f,-0.2,0.275
	invoke	glVertex2f,-0.2,0.2
	invoke	glVertex2f,-0.275,0.2

;=====================================================================================

	;QUADRADOS DO JOGADOR
	;A1J
	MOV DX,0
	MOV EBX,cores_celulasR_PC
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX

	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX

	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.8
	invoke	glVertex2f,0.2,0.8
	invoke	glVertex2f,0.2,0.725
	invoke	glVertex2f,0.275,0.725

	;B1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.8
	invoke	glVertex2f,0.275,0.8
	invoke	glVertex2f,0.275,0.725
	invoke	glVertex2f,0.350,0.725

	;C1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.8
	invoke	glVertex2f,0.350,0.8
	invoke	glVertex2f,0.350,0.725
	invoke	glVertex2f,0.425,0.725

	;D1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.8
	invoke	glVertex2f,0.425,0.8
	invoke	glVertex2f,0.425,0.725
	invoke	glVertex2f,0.5,0.725

	;E1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.8
	invoke	glVertex2f,0.5,0.8
	invoke	glVertex2f,0.5,0.725
	invoke	glVertex2f,0.575,0.725

	;F1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.8
	invoke	glVertex2f,0.575,0.8
	invoke	glVertex2f,0.575,0.725
	invoke	glVertex2f,0.650,0.725



	;G1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.8
	invoke	glVertex2f,0.650,0.8
	invoke	glVertex2f,0.650,0.725
	invoke	glVertex2f,0.725,0.725

	;H1J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX

	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.8
	invoke	glVertex2f,0.725,0.8
	invoke	glVertex2f,0.725,0.725
	invoke	glVertex2f,0.8,0.725

	;A2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.725
	invoke	glVertex2f,0.2,0.725
	invoke	glVertex2f,0.2,0.650
	invoke	glVertex2f,0.275,0.650

	;B2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.725
	invoke	glVertex2f,0.275,0.725
	invoke	glVertex2f,0.275,0.650
	invoke	glVertex2f,0.350,0.650

	;C2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.725
	invoke	glVertex2f,0.350,0.725
	invoke	glVertex2f,0.350,0.650
	invoke	glVertex2f,0.425,0.650

	;D2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.725
	invoke	glVertex2f,0.425,0.725
	invoke	glVertex2f,0.425,0.650
	invoke	glVertex2f,0.5,0.650

	;E2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.725
	invoke	glVertex2f,0.5,0.725
	invoke	glVertex2f,0.5,0.650
	invoke	glVertex2f,0.575,0.650



	;F2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.725
	invoke	glVertex2f,0.575,0.725
	invoke	glVertex2f,0.575,0.650
	invoke	glVertex2f,0.650,0.650


	;G2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.725
	invoke	glVertex2f,0.650,0.725
	invoke	glVertex2f,0.650,0.650
	invoke	glVertex2f,0.725,0.650



	;H2J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.725
	invoke	glVertex2f,0.725,0.725
	invoke	glVertex2f,0.725,0.650
	invoke	glVertex2f,0.8,0.650

	;A3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.650
	invoke	glVertex2f,0.2,0.650
	invoke	glVertex2f,0.2,0.575
	invoke	glVertex2f,0.275,0.575

	;B3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.650
	invoke	glVertex2f,0.275,0.650
	invoke	glVertex2f,0.275,0.575
	invoke	glVertex2f,0.350,0.575

	;C3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.650
	invoke	glVertex2f,0.350,0.650
	invoke	glVertex2f,0.350,0.575
	invoke	glVertex2f,0.425,0.575

	;D3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.650
	invoke	glVertex2f,0.425,0.650
	invoke	glVertex2f,0.425,0.575
	invoke	glVertex2f,0.5,0.575

	;E3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.650
	invoke	glVertex2f,0.5,0.650
	invoke	glVertex2f,0.5,0.575
	invoke	glVertex2f,0.575,0.575



	;F3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.650
	invoke	glVertex2f,0.575,0.650
	invoke	glVertex2f,0.575,0.575
	invoke	glVertex2f,0.650,0.575


	;G3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.650
	invoke	glVertex2f,0.650,0.650
	invoke	glVertex2f,0.650,0.575
	invoke	glVertex2f,0.725,0.575



	;H3J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.650
	invoke	glVertex2f,0.725,0.650
	invoke	glVertex2f,0.725,0.575
	invoke	glVertex2f,0.8,0.575



	;A4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.575
	invoke	glVertex2f,0.2,0.575
	invoke	glVertex2f,0.2,0.5
	invoke	glVertex2f,0.275,0.5

	;B4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.575
	invoke	glVertex2f,0.275,0.575
	invoke	glVertex2f,0.275,0.5
	invoke	glVertex2f,0.350,0.5

	;C4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.575
	invoke	glVertex2f,0.350,0.575
	invoke	glVertex2f,0.350,0.5
	invoke	glVertex2f,0.425,0.5



	;D4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.575
	invoke	glVertex2f,0.425,0.575
	invoke	glVertex2f,0.425,0.5
	invoke	glVertex2f,0.5,0.5

	;E4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	 invoke  glVertex2f,0.575,0.575
	invoke	glVertex2f,0.5,0.575
	invoke	glVertex2f,0.5,0.5
	invoke	glVertex2f,0.575,0.5



	;F4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.575
	invoke	glVertex2f,0.575,0.575
	invoke	glVertex2f,0.575,0.5
	invoke	glVertex2f,0.650,0.5

	;G4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.575
	invoke	glVertex2f,0.650,0.575
	invoke	glVertex2f,0.650,0.5
	invoke	glVertex2f,0.725,0.5



	;H4J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.575
	invoke	glVertex2f,0.725,0.575
	invoke	glVertex2f,0.725,0.5
	invoke	glVertex2f,0.8,0.5



	;A5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.5
	invoke	glVertex2f,0.2,0.5
	invoke	glVertex2f,0.2,0.425
	invoke	glVertex2f,0.275,0.425

	;B5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.5
	invoke	glVertex2f,0.275,0.5
	invoke	glVertex2f,0.275,0.425
	invoke	glVertex2f,0.350,0.425

	;C5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.5
	invoke	glVertex2f,0.350,0.5
	invoke	glVertex2f,0.350,0.425
	invoke	glVertex2f,0.425,0.425

	;D5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.5
	invoke	glVertex2f,0.425,0.5
	invoke	glVertex2f,0.425,0.425
	invoke	glVertex2f,0.5,0.425

	;E5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.5
	invoke	glVertex2f,0.5,0.5
	invoke	glVertex2f,0.5,0.425
	invoke	glVertex2f,0.575,0.425

	;F5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.5
	invoke	glVertex2f,0.575,0.5
	invoke	glVertex2f,0.575,0.425
	invoke	glVertex2f,0.650,0.425

	;G5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.5
	invoke	glVertex2f,0.650,0.5
	invoke	glVertex2f,0.650,0.425
	invoke	glVertex2f,0.725,0.425

	;H5J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.5
	invoke	glVertex2f,0.725,0.5
	invoke	glVertex2f,0.725,0.425
	invoke	glVertex2f,0.8,0.425

	;A6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.425
	invoke	glVertex2f,0.2,0.425
	invoke	glVertex2f,0.2,0.350
	invoke	glVertex2f,0.275,0.350

	;B6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.425
	invoke	glVertex2f,0.275,0.425
	invoke	glVertex2f,0.275,0.350
	invoke	glVertex2f,0.350,0.350

	;C6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.425
	invoke	glVertex2f,0.350,0.425
	invoke	glVertex2f,0.350,0.350
	invoke	glVertex2f,0.425,0.350

	;D6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.425
	invoke	glVertex2f,0.425,0.425
	invoke	glVertex2f,0.425,0.350
	invoke	glVertex2f,0.5,0.350

	;E6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.425
	invoke	glVertex2f,0.5,0.425
	invoke	glVertex2f,0.5,0.350
	invoke	glVertex2f,0.575,0.350

	;F6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.425
	invoke	glVertex2f,0.575,0.425
	invoke	glVertex2f,0.575,0.350
	invoke	glVertex2f,0.650,0.350

	;G6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.425
	invoke	glVertex2f,0.650,0.425
	invoke	glVertex2f,0.650,0.350
	invoke	glVertex2f,0.725,0.350

	;H6J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.425
	invoke	glVertex2f,0.725,0.425
	invoke	glVertex2f,0.725,0.350
	invoke	glVertex2f,0.8,0.350

	;A7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.350
	invoke	glVertex2f,0.2,0.350
	invoke	glVertex2f,0.2,0.275
	invoke	glVertex2f,0.275,0.275

	;B7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.350
	invoke	glVertex2f,0.275,0.350
	invoke	glVertex2f,0.275,0.275
	invoke	glVertex2f,0.350,0.275

	;C7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.350
	invoke	glVertex2f,0.350,0.350
	invoke	glVertex2f,0.350,0.275
	invoke	glVertex2f,0.425,0.275

	;D7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.350
	invoke	glVertex2f,0.425,0.350
	invoke	glVertex2f,0.425,0.275
	invoke	glVertex2f,0.5,0.275

	;E7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.350
	invoke	glVertex2f,0.5,0.350
	invoke	glVertex2f,0.5,0.275
	invoke	glVertex2f,0.575,0.275

	;F7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.350
	invoke	glVertex2f,0.575,0.350
	invoke	glVertex2f,0.575,0.275
	invoke	glVertex2f,0.650,0.275

	;G7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.350
	invoke	glVertex2f,0.650,0.350
	invoke	glVertex2f,0.650,0.275
	invoke	glVertex2f,0.725,0.275

	;H7J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.350
	invoke	glVertex2f,0.725,0.350
	invoke	glVertex2f,0.725,0.275
	invoke	glVertex2f,0.8,0.275

	;A8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.275,0.275
	invoke	glVertex2f,0.2,0.275
	invoke	glVertex2f,0.2,0.2
	invoke	glVertex2f,0.275,0.2

	;B8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.350,0.275
	invoke	glVertex2f,0.275,0.275
	invoke	glVertex2f,0.275,0.2
	invoke	glVertex2f,0.350,0.2

	;C8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.425,0.275
	invoke	glVertex2f,0.350,0.275
	invoke	glVertex2f,0.350,0.2
	invoke	glVertex2f,0.425,0.2

	;D8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.5,0.275
	invoke	glVertex2f,0.425,0.275
	invoke	glVertex2f,0.425,0.2
	invoke	glVertex2f,0.5,0.2

	;E8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.575,0.275
	invoke	glVertex2f,0.5,0.275
	invoke	glVertex2f,0.5,0.2
	invoke	glVertex2f,0.575,0.2

	;F8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.650,0.275
	invoke	glVertex2f,0.575,0.275
	invoke	glVertex2f,0.575,0.2
	invoke	glVertex2f,0.650,0.2



	;G8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.725,0.275
	invoke	glVertex2f,0.650,0.275
	invoke	glVertex2f,0.650,0.2
	invoke	glVertex2f,0.725,0.2

	;H8J
	MOV EBX,cores_celulasR_PC
	ADD ESI,4
	MOV EAX,[EBX+ESI]
	MOV [cor_R],EAX
	MOV EBX,cores_celulasG_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_G],EAX
	MOV EBX,cores_celulasB_PC
	MOV EAX,[EBX+ESI]
	MOV [cor_B],EAX
	invoke	glColor3f,[cor_R],[cor_G],[cor_B] ;COR DA AGUA
	invoke	glVertex2f,0.8,0.275
	invoke	glVertex2f,0.725,0.275
	invoke	glVertex2f,0.725,0.2
	invoke	glVertex2f,0.8,0.2

	;========================Desenhando Alvo====================

	FLDZ
	FADD [tstvertX1]
	FADD [tamanho_alvo]
	FST [tstvertX2]
	FLDZ
	FADD [tstvertY1]
	FADD [tamanho_alvo]
	FST [tstvertY2]
	invoke	glColor3f,[tstcorR],[tstcorG],[tstcorB]
	invoke	glVertex2f,[tstvertX1],[tstvertY1]
	invoke	glVertex2f,[tstvertX2],[tstvertY1]
	invoke	glVertex2f,[tstvertX2],[tstvertY2]
	invoke	glVertex2f,[tstvertX1],[tstvertY2]

	;===========================================================

;==================================================================================

	;FAZENDO O PLACAR DO COMPUTADOR  ;   _a_
					 ; f|   |b
					 ;  |_g_|
					 ; e|   |c
					 ;  |_d_|
	;a Unidade

	invoke	glColor3f,0,[corAUnitJ],0
	invoke	glVertex2f,0.44,-0.2
	invoke	glVertex2f,0.55,-0.2
	invoke	glVertex2f,0.53,-0.225
	invoke	glVertex2f,0.46,-0.225


	;f Unidade
	invoke	glColor3f,0,[corFUnitJ],0
	invoke	glVertex2f,0.44,-0.21
	invoke	glVertex2f,0.44,-0.36
	invoke	glVertex2f,0.455,-0.34
	invoke	glVertex2f,0.455,-0.23

	;e Unidade
	invoke	glColor3f,0,[corEUnitJ],0
	invoke	glVertex2f,0.44,-0.37
	invoke	glVertex2f,0.44,-0.52
	invoke	glVertex2f,0.455,-0.5
	invoke	glVertex2f,0.455,-0.39

	;d Unidade
	invoke	glColor3f,0,[corDUnitJ],0
	invoke	glVertex2f,0.44,-0.53
	invoke	glVertex2f,0.55,-0.53
	invoke	glVertex2f,0.53,-0.505
	invoke	glVertex2f,0.46,-0.505

	;c Unidade
	invoke	glColor3f,0,[corCUnitJ],0
	invoke	glVertex2f,0.55,-0.37
	invoke	glVertex2f,0.55,-0.52
	invoke	glVertex2f,0.535,-0.5
	invoke	glVertex2f,0.535,-0.39

	;b Unidade
	invoke	glColor3f,0,[corBUnitJ],0
	invoke	glVertex2f,0.55,-0.21
	invoke	glVertex2f,0.55,-0.36
	invoke	glVertex2f,0.535,-0.34
	invoke	glVertex2f,0.535,-0.23

	;g Unidade
	invoke	glColor3f,0,[corGUnitJ],0
	invoke	glVertex2f,0.455,-0.351
	invoke	glVertex2f,0.535,-0.351
	invoke	glVertex2f,0.545,-0.365
	invoke	glVertex2f,0.445,-0.365

	invoke	glVertex2f,0.445,-0.365
	invoke	glVertex2f,0.545,-0.365
	invoke	glVertex2f,0.535,-0.379
	invoke	glVertex2f,0.455,-0.379

  ;DEZENAS
	;a Dezena

	invoke	glColor3f,0,[corADezenJ],0
	invoke	glVertex2f,0.31,-0.2
	invoke	glVertex2f,0.42,-0.2
	invoke	glVertex2f,0.40,-0.225
	invoke	glVertex2f,0.33,-0.225


	;b Dezena
	invoke	glColor3f,0,[corFDezenJ],0
	invoke	glVertex2f,0.31,-0.21
	invoke	glVertex2f,0.31,-0.36
	invoke	glVertex2f,0.325,-0.34
	invoke	glVertex2f,0.325,-0.23

	;c Dezena
	invoke	glColor3f,0,[corEDezenJ],0
	invoke	glVertex2f,0.31,-0.37
	invoke	glVertex2f,0.31,-0.52
	invoke	glVertex2f,0.325,-0.5
	invoke	glVertex2f,0.325,-0.39

	;d Dezena
	invoke	glColor3f,0,[corDDezenJ],0
	invoke	glVertex2f,0.31,-0.53
	invoke	glVertex2f,0.42,-0.53
	invoke	glVertex2f,0.40,-0.505
	invoke	glVertex2f,0.33,-0.505

	;e Dezena
	invoke	glColor3f,0,[corCDezenJ],0
	invoke	glVertex2f,0.42,-0.37
	invoke	glVertex2f,0.42,-0.52
	invoke	glVertex2f,0.405,-0.5
	invoke	glVertex2f,0.405,-0.39

	;f Dezena
	invoke	glColor3f,0,[corBDezenJ],0
	invoke	glVertex2f,0.42,-0.21
	invoke	glVertex2f,0.42,-0.36
	invoke	glVertex2f,0.405,-0.34
	invoke	glVertex2f,0.405,-0.23

	;g Dezena
	invoke	glColor3f,0,[corGDezenJ],0
	invoke	glVertex2f,0.325,-0.351
	invoke	glVertex2f,0.405,-0.351
	invoke	glVertex2f,0.415,-0.365
	invoke	glVertex2f,0.315,-0.365

	invoke	glVertex2f,0.415,-0.365
	invoke	glVertex2f,0.315,-0.365
	invoke	glVertex2f,0.325,-0.379
	invoke	glVertex2f,0.405,-0.379

  ;Sinal
	invoke	glColor3f,0,[corSinalJ],0
	invoke	glVertex2f,0.205,-0.351
	invoke	glVertex2f,0.285,-0.351
	invoke	glVertex2f,0.295,-0.365
	invoke	glVertex2f,0.195,-0.365

	invoke	glVertex2f,0.295,-0.365
	invoke	glVertex2f,0.195,-0.365
	invoke	glVertex2f,0.205,-0.379
	invoke	glVertex2f,0.285,-0.379



;=================================================================================
     ;FAZENDO O PLACAR DO JOGADOR  ;   _a_
				   ; f|   |b
				   ;  |_g_|
				   ; e|   |c
				   ;  |_d_|

  ;Unidade
	;a Unidade
	invoke	glColor3f,0,[corAUnitPC],0
	invoke	glVertex2f,-0.31,-0.2
	invoke	glVertex2f,-0.42,-0.2
	invoke	glVertex2f,-0.40,-0.225
	invoke	glVertex2f,-0.33,-0.225


	;b Unidade
	invoke	glColor3f,0,[corBUnitPC],0
	invoke	glVertex2f,-0.31,-0.21
	invoke	glVertex2f,-0.31,-0.36
	invoke	glVertex2f,-0.325,-0.34
	invoke	glVertex2f,-0.325,-0.23


	;c Unidade
	invoke	glColor3f,0,[corCUnitPC],0
	invoke	glVertex2f,-0.31,-0.37
	invoke	glVertex2f,-0.31,-0.52
	invoke	glVertex2f,-0.325,-0.5
	invoke	glVertex2f,-0.325,-0.39


	;d Unidade
	invoke	glColor3f,0,[corDUnitPC],0
	invoke	glVertex2f,-0.31,-0.53
	invoke	glVertex2f,-0.42,-0.53
	invoke	glVertex2f,-0.40,-0.505
	invoke	glVertex2f,-0.33,-0.505


	;e Unidade
	invoke	glColor3f,0,[corEUnitPC],0
	invoke	glVertex2f,-0.42,-0.37
	invoke	glVertex2f,-0.42,-0.52
	invoke	glVertex2f,-0.405,-0.5
	invoke	glVertex2f,-0.405,-0.39


	;f Unidade
	invoke	glColor3f,0,[corFUnitPC],0
	invoke	glVertex2f,-0.42,-0.21
	invoke	glVertex2f,-0.42,-0.36
	invoke	glVertex2f,-0.405,-0.34
	invoke	glVertex2f,-0.405,-0.23


	;g Unidade
	invoke	glColor3f,0,[corGUnitPC],0
	invoke	glVertex2f,-0.325,-0.351
	invoke	glVertex2f,-0.405,-0.351
	invoke	glVertex2f,-0.415,-0.365
	invoke	glVertex2f,-0.315,-0.365

	invoke	glVertex2f,-0.415,-0.365
	invoke	glVertex2f,-0.315,-0.365
	invoke	glVertex2f,-0.325,-0.379
	invoke	glVertex2f,-0.405,-0.379



      ;DEZENAS
	;a Dezena
	invoke	glColor3f,0,[corADezenPC],0
	invoke	glVertex2f,-0.44,-0.2
	invoke	glVertex2f,-0.55,-0.2
	invoke	glVertex2f,-0.53,-0.225
	invoke	glVertex2f,-0.46,-0.225

	;b Dezena
	invoke	glColor3f,0,[corBDezenPC],0
	invoke	glVertex2f,-0.44,-0.21
	invoke	glVertex2f,-0.44,-0.36
	invoke	glVertex2f,-0.455,-0.34
	invoke	glVertex2f,-0.455,-0.23

	;c Dezena
	invoke	glColor3f,0,[corCDezenPC],0
	invoke	glVertex2f,-0.44,-0.37
	invoke	glVertex2f,-0.44,-0.52
	invoke	glVertex2f,-0.455,-0.5
	invoke	glVertex2f,-0.455,-0.39

	;d Dezena
	invoke	glColor3f,0,[corDDezenPC],0
	invoke	glVertex2f,-0.44,-0.53
	invoke	glVertex2f,-0.55,-0.53
	invoke	glVertex2f,-0.53,-0.505
	invoke	glVertex2f,-0.46,-0.505

	;e Dezena
	invoke	glColor3f,0,[corEDezenPC],0
	invoke	glVertex2f,-0.55,-0.37
	invoke	glVertex2f,-0.55,-0.52
	invoke	glVertex2f,-0.535,-0.5
	invoke	glVertex2f,-0.535,-0.39

	;f Dezena
	invoke	glColor3f,0,[corFDezenPC],0
	invoke	glVertex2f,-0.55,-0.21
	invoke	glVertex2f,-0.55,-0.36
	invoke	glVertex2f,-0.535,-0.34
	invoke	glVertex2f,-0.535,-0.23

	;g Dezena
	invoke	glColor3f,0,[corGDezenPC],0
	invoke	glVertex2f,-0.455,-0.351
	invoke	glVertex2f,-0.535,-0.351
	invoke	glVertex2f,-0.545,-0.365
	invoke	glVertex2f,-0.445,-0.365

	invoke	glVertex2f,-0.445,-0.365
	invoke	glVertex2f,-0.545,-0.365
	invoke	glVertex2f,-0.535,-0.379
	invoke	glVertex2f,-0.455,-0.379

	;Sinal
	invoke	glColor3f,0,[corSinalPC],0
	invoke	glVertex2f,-0.575,-0.351
	invoke	glVertex2f,-0.655,-0.351
	invoke	glVertex2f,-0.665,-0.365
	invoke	glVertex2f,-0.565,-0.365

	invoke	glVertex2f,-0.565,-0.365
	invoke	glVertex2f,-0.665,-0.365
	invoke	glVertex2f,-0.655,-0.379
	invoke	glVertex2f,-0.575,-0.379

	invoke glEnd
;================================================================================

 ; LINHAS VERTICAIS DO TABULEIRO 1

	invoke glBegin,GL_LINES
	invoke glColor3f,0.0,0.0,0.0
	invoke glVertex2f,-0.8,0.8
	invoke glVertex2f,-0.8,0.2


	invoke glVertex2f,-0.725,0.8
	invoke glVertex2f,-0.725,0.2


	invoke glVertex2f,-0.650,0.8
	invoke glVertex2f,-0.650,0.2


	invoke glVertex2f,-0.575,0.8
	invoke glVertex2f,-0.575,0.2


	invoke glVertex2f,-0.5,0.8
	invoke glVertex2f,-0.5,0.2


	invoke glVertex2f,-0.425,0.8
	invoke glVertex2f,-0.425,0.2


	invoke glVertex2f,-0.350,0.8
	invoke glVertex2f,-0.350,0.2


	invoke glVertex2f,-0.275,0.8
	invoke glVertex2f,-0.275,0.2


	invoke glVertex2f,-0.2,0.8
	invoke glVertex2f,-0.2,0.2
;===================================================================================
    ; LINHAS HORIZONTAIS DO TABULEIRO 1

	invoke glVertex2f,-0.8,0.8
	invoke glVertex2f,-0.2,0.8


	invoke glVertex2f,-0.8,0.725
	invoke glVertex2f,-0.2,0.725


	invoke glVertex2f,-0.8,0.650
	invoke glVertex2f,-0.2,0.650

	invoke glVertex2f,-0.8,0.575
	invoke glVertex2f,-0.2,0.575

	invoke glVertex2f,-0.8,0.5
	invoke glVertex2f,-0.2,0.5

	invoke glVertex2f,-0.8,0.425
	invoke glVertex2f,-0.2,0.425

	invoke glVertex2f,-0.8,0.350
	invoke glVertex2f,-0.2,0.350

	invoke glVertex2f,-0.8,0.275
	invoke glVertex2f,-0.2,0.275

	invoke glVertex2f,-0.8,0.2
	invoke glVertex2f,-0.2,0.2

;===================================================================================


 ; LINHAS VERTICAIS DO TABULEIRO 2
	invoke glBegin,GL_LINES
	invoke glColor3f,0.0,0.0,0.0

	invoke glVertex2f, 0.8,0.8
	invoke glVertex2f, 0.8,0.2


	invoke glVertex2f, 0.725,0.8
	invoke glVertex2f, 0.725,0.2


	invoke glVertex2f, 0.650,0.8
	invoke glVertex2f, 0.650,0.2


	invoke glVertex2f, 0.575,0.8
	invoke glVertex2f, 0.575,0.2


	invoke glVertex2f, 0.5,0.8
	invoke glVertex2f, 0.5,0.2


	invoke glVertex2f, 0.425,0.8
	invoke glVertex2f, 0.425,0.2


	invoke glVertex2f, 0.350,0.8
	invoke glVertex2f, 0.350,0.2


	invoke glVertex2f, 0.275,0.8
	invoke glVertex2f, 0.275,0.2


	invoke glVertex2f, 0.2,0.8
	invoke glVertex2f, 0.2,0.2
;===================================================================================
    ; LINHAS HORIZONTAIS DO TABULEIRO 2

	invoke glVertex2f, 0.8,0.8
	invoke glVertex2f, 0.2,0.8


	invoke glVertex2f, 0.8,0.725
	invoke glVertex2f, 0.2,0.725


	invoke glVertex2f, 0.8,0.650
	invoke glVertex2f, 0.2,0.650

	invoke glVertex2f, 0.8,0.575
	invoke glVertex2f, 0.2,0.575

	invoke glVertex2f, 0.8,0.5
	invoke glVertex2f, 0.2,0.5

	invoke glVertex2f, 0.8,0.425
	invoke glVertex2f, 0.2,0.425

	invoke glVertex2f, 0.8,0.350
	invoke glVertex2f, 0.2,0.350

	invoke glVertex2f, 0.8,0.275
	invoke glVertex2f, 0.2,0.275

	invoke glVertex2f, 0.8,0.2
	invoke glVertex2f, 0.2,0.2

;===================================================================================

	;Numeros da Coordenadas do PC
	invoke glBegin,GL_LINES
	invoke glColor3f,[corDasCoordenadas],[corDasCoordenadas],[corDasCoordenadas]

	;Numero 1
	invoke glVertex2f,-0.835,0.79
	invoke glVertex2f,-0.835,0.739

	invoke glVertex2f,-0.835,0.79
	invoke glVertex2f,-0.845,0.77

	;Numero 2
	invoke glVertex2f,-0.85,0.71
	invoke glVertex2f,-0.825,0.71

	invoke glVertex2f,-0.825,0.71
	invoke glVertex2f,-0.825,0.69

	invoke glVertex2f,-0.825,0.69
	invoke glVertex2f,-0.85,0.66

	invoke glVertex2f,-0.85,0.66
	invoke glVertex2f,-0.825,0.66

	;Numero 3
	invoke glVertex2f,-0.825,0.64
	invoke glVertex2f,-0.825,0.58

	invoke glVertex2f,-0.85,0.64
	invoke glVertex2f,-0.825,0.64

	invoke glVertex2f,-0.85,0.605
	invoke glVertex2f,-0.825,0.605

	invoke glVertex2f,-0.85,0.58
	invoke glVertex2f,-0.825,0.58

	;Numero 4
	invoke glVertex2f,-0.825,0.56
	invoke glVertex2f,-0.825,0.51

	invoke glVertex2f,-0.85,0.56
	invoke glVertex2f,-0.85,0.537

	invoke glVertex2f,-0.85,0.537
	invoke glVertex2f,-0.825,0.537

	;Numero 5
	invoke glVertex2f,-0.85,0.49
	invoke glVertex2f,-0.825,0.49

	invoke glVertex2f,-0.85,0.49
	invoke glVertex2f,-0.85,0.46

	invoke glVertex2f,-0.85,0.46
	invoke glVertex2f,-0.825,0.46

	invoke glVertex2f,-0.825,0.46
	invoke glVertex2f,-0.825,0.43

	invoke glVertex2f,-0.825,0.43
	invoke glVertex2f,-0.85,0.43

	;Numero 6
	invoke glVertex2f,-0.85,0.41
	invoke glVertex2f,-0.825,0.41

	invoke glVertex2f,-0.85,0.41
	invoke glVertex2f,-0.85,0.36

	invoke glVertex2f,-0.85,0.39
	invoke glVertex2f,-0.825,0.39

	invoke glVertex2f,-0.825,0.39
	invoke glVertex2f,-0.825,0.36

	invoke glVertex2f,-0.825,0.36
	invoke glVertex2f,-0.85,0.36

	;Numero 7
	invoke glVertex2f,-0.825,0.34
	invoke glVertex2f,-0.852,0.34

	invoke glVertex2f,-0.825,0.34
	invoke glVertex2f,-0.835,0.29

	;Numero 8
	invoke glVertex2f,-0.85,0.26
	invoke glVertex2f,-0.825,0.26

	invoke glVertex2f,-0.85,0.26
	invoke glVertex2f,-0.85,0.21

	invoke glVertex2f,-0.825,0.26
	invoke glVertex2f,-0.825,0.21

	invoke glVertex2f,-0.85,0.24
	invoke glVertex2f,-0.825,0.24

	invoke glVertex2f,-0.825,0.21
	invoke glVertex2f,-0.85,0.21

;Colunas
	;Coluna A
	invoke glVertex2f,-0.78,0.84
	invoke glVertex2f,-0.765,0.9

	invoke glVertex2f,-0.75,0.84
	invoke glVertex2f,-0.765,0.9

	invoke glVertex2f,-0.76,0.87
	invoke glVertex2f,-0.77,0.87

	;Coluna B
	invoke glVertex2f,-0.715,0.84
	invoke glVertex2f,-0.67,0.84

	invoke glVertex2f,-0.715,0.87
	invoke glVertex2f,-0.67,0.87

	invoke glVertex2f,-0.715,0.9
	invoke glVertex2f,-0.68,0.9

	invoke glVertex2f,-0.715,0.9
	invoke glVertex2f,-0.715,0.84

	invoke glVertex2f,-0.67,0.84
	invoke glVertex2f,-0.67,0.87

	invoke glVertex2f,-0.68,0.9
	invoke glVertex2f,-0.68,0.87

	;Coluna C
	invoke glVertex2f,-0.6,0.9
	invoke glVertex2f,-0.64,0.9

	invoke glVertex2f,-0.6,0.84
	invoke glVertex2f,-0.64,0.84

	invoke glVertex2f,-0.64,0.84
	invoke glVertex2f,-0.64,0.9

	;Coluna D
	invoke glVertex2f,-0.52,0.88
	invoke glVertex2f,-0.565,0.9

	invoke glVertex2f,-0.565,0.9
	invoke glVertex2f,-0.565,0.84

	invoke glVertex2f,-0.52,0.85
	invoke glVertex2f,-0.565,0.84

	invoke glVertex2f,-0.52,0.88
	invoke glVertex2f,-0.52,0.85

	;Coluna E

	invoke glVertex2f,-0.49,0.9
	invoke glVertex2f,-0.435,0.9

	invoke glVertex2f,-0.49,0.87
	invoke glVertex2f,-0.445,0.87

	invoke glVertex2f,-0.49,0.84
	invoke glVertex2f,-0.435,0.84

	invoke glVertex2f,-0.49,0.9
	invoke glVertex2f,-0.49,0.84

	;Coluna F
	invoke glVertex2f,-0.415,0.9
	invoke glVertex2f,-0.36,0.9

	invoke glVertex2f,-0.415,0.87
	invoke glVertex2f,-0.37,0.87

	invoke glVertex2f,-0.415,0.9
	invoke glVertex2f,-0.415,0.84

	;Coluna G
	invoke glVertex2f,-0.34,0.84
	invoke glVertex2f,-0.285,0.84

	invoke glVertex2f,-0.34,0.9
	invoke glVertex2f,-0.295,0.9

	invoke glVertex2f,-0.34,0.9
	invoke glVertex2f,-0.34,0.84

	invoke glVertex2f,-0.285,0.87
	invoke glVertex2f,-0.285,0.84

	invoke glVertex2f,-0.285,0.87
	invoke glVertex2f,-0.32,0.87

	;Coluna H
	invoke glVertex2f,-0.21,0.87
	invoke glVertex2f,-0.265,0.87

	invoke glVertex2f,-0.265,0.9
	invoke glVertex2f,-0.265,0.84

	invoke glVertex2f,-0.21,0.9
	invoke glVertex2f,-0.21,0.84


;===================================================================================


	;Numeros da Coordenadas do Jogador
	invoke glBegin,GL_LINES
	invoke glColor3f,[corDasCoordenadas],[corDasCoordenadas],[corDasCoordenadas]

	;Numero 1
	invoke glVertex2f,0.165,0.79
	invoke glVertex2f,0.165,0.739

	invoke glVertex2f,0.165,0.79
	invoke glVertex2f,0.155,0.77

	;Numero 2
	invoke glVertex2f,0.15,0.71
	invoke glVertex2f,0.18,0.71

	invoke glVertex2f,0.18,0.71
	invoke glVertex2f,0.18,0.69

	invoke glVertex2f,0.18,0.69
	invoke glVertex2f,0.15,0.66

	invoke glVertex2f,0.15,0.66
	invoke glVertex2f,0.18,0.66

	;Numero 3
	invoke glVertex2f,0.18,0.64
	invoke glVertex2f,0.18,0.58

	invoke glVertex2f,0.15,0.64
	invoke glVertex2f,0.18,0.64

	invoke glVertex2f,0.15,0.605
	invoke glVertex2f,0.18,0.605

	invoke glVertex2f,0.15,0.58
	invoke glVertex2f,0.18,0.58

	;Numero 4
	invoke glVertex2f,0.18,0.56
	invoke glVertex2f,0.18,0.51

	invoke glVertex2f,0.15,0.56
	invoke glVertex2f,0.15,0.537

	invoke glVertex2f,0.15,0.537
	invoke glVertex2f,0.18,0.537

	;Numero 5
	invoke glVertex2f,0.15,0.49
	invoke glVertex2f,0.18,0.49

	invoke glVertex2f,0.15,0.49
	invoke glVertex2f,0.15,0.46

	invoke glVertex2f,0.15,0.46
	invoke glVertex2f,0.18,0.46

	invoke glVertex2f,0.18,0.46
	invoke glVertex2f,0.18,0.43

	invoke glVertex2f,0.18,0.43
	invoke glVertex2f,0.15,0.43

	;Numero 6
	invoke glVertex2f,0.15,0.41
	invoke glVertex2f,0.18,0.41

	invoke glVertex2f,0.15,0.41
	invoke glVertex2f,0.15,0.36

	invoke glVertex2f,0.15,0.39
	invoke glVertex2f,0.18,0.39

	invoke glVertex2f,0.18,0.39
	invoke glVertex2f,0.18,0.36

	invoke glVertex2f,0.18,0.36
	invoke glVertex2f,0.15,0.36

	;Numero 7
	invoke glVertex2f,0.18,0.34
	invoke glVertex2f,0.152,0.34

	invoke glVertex2f,0.18,0.34
	invoke glVertex2f,0.152,0.29

	;Numero 8
	invoke glVertex2f,0.15,0.26
	invoke glVertex2f,0.18,0.26

	invoke glVertex2f,0.15,0.26
	invoke glVertex2f,0.15,0.21

	invoke glVertex2f,0.18,0.26
	invoke glVertex2f,0.18,0.21

	invoke glVertex2f,0.15,0.24
	invoke glVertex2f,0.18,0.24

	invoke glVertex2f,0.18,0.21
	invoke glVertex2f,0.15,0.21

;Colunas
	;Coluna A
	invoke glVertex2f,0.21,0.84
	invoke glVertex2f,0.23,0.9

	invoke glVertex2f,0.245,0.84
	invoke glVertex2f,0.23,0.9

	invoke glVertex2f,0.22,0.87
	invoke glVertex2f,0.24,0.87

	;Coluna B
	invoke glVertex2f,0.285,0.84
	invoke glVertex2f,0.34,0.84

	invoke glVertex2f,0.285,0.87
	invoke glVertex2f,0.34,0.87

	invoke glVertex2f,0.285,0.9
	invoke glVertex2f,0.33,0.9

	invoke glVertex2f,0.285,0.9
	invoke glVertex2f,0.285,0.84

	invoke glVertex2f,0.34,0.84
	invoke glVertex2f,0.34,0.87

	invoke glVertex2f,0.33,0.9
	invoke glVertex2f,0.33,0.87

	;Coluna C
	invoke glVertex2f,0.36,0.9
	invoke glVertex2f,0.415,0.9

	invoke glVertex2f,0.36,0.84
	invoke glVertex2f,0.415,0.84

	invoke glVertex2f,0.36,0.84
	invoke glVertex2f,0.36,0.9

	;Coluna D
	invoke glVertex2f,0.48,0.88
	invoke glVertex2f,0.435,0.9

	invoke glVertex2f,0.435,0.9
	invoke glVertex2f,0.435,0.84

	invoke glVertex2f,0.48,0.85
	invoke glVertex2f,0.435,0.84

	invoke glVertex2f,0.48,0.88
	invoke glVertex2f,0.48,0.85

	;Coluna E

	invoke glVertex2f,0.565,0.9
	invoke glVertex2f,0.51,0.9

	invoke glVertex2f,0.565,0.87
	invoke glVertex2f,0.51,0.87

	invoke glVertex2f,0.565,0.84
	invoke glVertex2f,0.51,0.84

	invoke glVertex2f,0.51,0.9
	invoke glVertex2f,0.51,0.84

	;Coluna F
	invoke glVertex2f,0.64,0.9
	invoke glVertex2f,0.585,0.9

	invoke glVertex2f,0.585,0.87
	invoke glVertex2f,0.63,0.87

	invoke glVertex2f,0.585,0.9
	invoke glVertex2f,0.585,0.84

	;Coluna G
	invoke glVertex2f,0.715,0.84
	invoke glVertex2f,0.660,0.84

	invoke glVertex2f,0.660,0.9
	invoke glVertex2f,0.715,0.9

	invoke glVertex2f,0.660,0.9
	invoke glVertex2f,0.660,0.84

	invoke glVertex2f,0.715,0.87
	invoke glVertex2f,0.715,0.84

	invoke glVertex2f,0.715,0.87
	invoke glVertex2f,0.68,0.87

	;Coluna H
	invoke glVertex2f,0.735,0.87
	invoke glVertex2f,0.79,0.87

	invoke glVertex2f,0.79,0.9
	invoke glVertex2f,0.79,0.84

	invoke glVertex2f,0.735,0.9
	invoke glVertex2f,0.735,0.84




;================================================================================

	invoke glEnd ;FIM dos desenhos


	invoke	SwapBuffers,[hdc]
	xor	eax,eax
	jmp	.finish


;=============== Efetuando Ataque ===========================
   .FIM_DE_JOGO:
     MOV AL,1
     MOV [fim_de_jogo],AL
     CMP[wparam],0Dh
     JE .defwndproc
     JNE .wmdestroy

   .PC_WINNER:
     FLDZ
     FSTP [u_winCor]
     FLD1
     FST [winCor]
     FSTP [pc_winCor]
     JMP .FIM_DE_JOGO

   .USER_WINNER:
     FLDZ
     FSTP [pc_winCor]
     FLD1
     FST [winCor]
     FSTP [u_winCor]
     JMP .FIM_DE_JOGO

   .CHECA_FINAL:
     CMP [pontosJ],-10
     JE .USER_WINNER
     CMP [pontosPC],10
     JE .USER_WINNER
     CMP [pontosPC],-10
     JE .PC_WINNER
     CMP [pontosJ],10

     JE .PC_WINNER
     JMP .defwndproc

   .DESENHA_AGUA_PC:
	;pinta a célula atacada de azul
	MOV EBX,cores_celulasR_PC
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,0
	MOV [EBX+ESI],EDX

	MOV EBX,cores_celulasB_PC
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,1.0
	MOV [EBX+ESI],EDX

	MOV EAX,0
	MOV AL,[pontosPC]
	INC AL
	MOV [pontosPC],AL

	jmp  .placarJ

   .DESENHA_AGUA:
	;pinta a célula atacada de azul
	MOV EBX,cores_celulasR
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,0
	MOV [EBX+ESI],EDX

	MOV EBX,cores_celulasB
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,1.0
	MOV [EBX+ESI],EDX

	MOV EAX,0
	MOV AL,[pontosJ]
	INC AL
	MOV [pontosJ],AL

	jmp  .placarJ

   .CONFIRMA_ATAQUE:
	;alterando a cor do alvo
	FLD1;move 1 pra o st0
	FST [tstcorR];move o valor armazenado no topo da pilha para tstcorR
	FLD1;armazena 0 no topo da pilha
	FST [tstcorG];move o valor armazenado no topo da pilha para tstcorG
	FLDZ;armazena 0 no topo da pilha
	FST [tstcorB];move o valor armazenado no topo da pilha para tstcorB

	;verificação de turno
	CMP [vez_pc],0
	JE .PLAY_ATAQUE
	MOV AL,[vez_pc]
	DEC AL
	MOV [vez_pc],AL
	FLDZ
	FSTP [pc_winCor]
	FLD1
	FSTP [u_winCor]

	MOV DL,[indc]
	MOV EBX,vetor_play
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	INC EAX
	MOV [EBX+ESI],EAX

	;verifica se é água que está armazenada na posição atacada
	CMP AL,1
	JE .DESENHA_AGUA_PC


	MOV EBX,cores_celulasR_PC
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,1.0
	MOV [EBX+ESI],EDX

	MOV EBX,cores_celulasB_PC
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,0
	MOV [EBX+ESI],EDX

	MOV EAX,0
	MOV AL,[pontosPC]
	DEC AL
	MOV [pontosPC],AL
	jmp   .placarJ


   .PLAY_ATAQUE:
	;faz leitura do valor armazenado na posição atacada
	MOV AL,[vez_pc]
	INC AL
	MOV [vez_pc],AL
	FLDZ
	FSTP [u_winCor]
	FLD1
	FSTP [pc_winCor]

	MOV DL,[indc]
	MOV EBX,vetor_cpu
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	INC EAX
	MOV [EBX+ESI],EAX

	;verifica se é água que está armazenada na posição atacada
	CMP AL,1
	JE .DESENHA_AGUA


	MOV EBX,cores_celulasR
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,1.0
	MOV [EBX+ESI],EDX

	MOV EBX,cores_celulasB
	MOV DL,[indc]
	SHL DL,2
	MOV SI,DX
	MOV EDX,0
	MOV [EBX+ESI],EDX

	;decremento de teste

	;call Gerar_Posicoes


	MOV EAX,0
	MOV AL,[pontosJ]
	DEC AL
	MOV [pontosJ],AL

	jmp   .placarJ


   .VER_SEL:
	;verifica se os valores de linha e coluna são válidos para gerar o índice
	CMP [lin],0
	JL  .defwndproc
	CMP [col],0
	JL  .defwndproc
	CMP [lin],7
	JG  .defwndproc
	CMP [col],7
	JG  .defwndproc
	CMP [wparam],0Dh
	JE .FORMULA

   .POSICIONA_ALVO:
	;alterando a cor do alvo
	FLDZ;move 1 pra o st0
	FST [tstcorR];move o valor armazenado no topo da pilha para tstcorR
	FLD1;armazena 0 no topo da pilha
	FST [tstcorG];move o valor armazenado no topo da pilha para tstcorG
	FLDZ;armazena 0 no topo da pilha
	FST [tstcorB];move o valor armazenado no topo da pilha para tstcorB

	;alterando a posição do alvo (inicio_alvoX,inicio_alvoY)
	FLDz;move 0 pra o st0
	FADD [inicio_alvoX];soma 0 com a posição de início do alvo deixando armazenada no st0
	FST [tstvertX1];passa esse valor para para tstvertX1
	FLDZ;move 0 pra o st0
	FADD [inicio_alvoY]
	FST [tstvertY1];passa o valor de st0 para tstvertY

	;passando o alvo para a posição desejada pelo user (inicio_alvoX+coluna*dist_alvoX,inicio_alvoY+linha*dist_alvoY)
	FLD [dist_alvoX];move dist_alvoX pra o st0
	MOV AL,[col];como pra fazer uma multiplicação por inteiro precisa de um dado do tipo WORD, passa a col(DB) para coluna(DW) usando AX
	MOV [coluna],AX
	FIMUL [coluna];multiplia a linha pelo valor armazenado em st0, dist_alvoX
	FADD [tstvertX1];soma st0 com tstvertX1
	FST [tstvertX1];passa o valor de st0 para tstvertX1

	FLD [dist_alvoY]
	MOV AL,[lin]
	MOV [linha],AX
	FIMUL [linha]
	FADD [tstvertY1]
	FST [tstvertY1];passa o valor de st0 para tstvertY1

	jmp	.defwndproc

    .FORMULA:
	MOV AL,[lin]
	SHL AL,3 ; Desloca 3 bits à esquerda (o mesmo que multiplicar por 8)
	MOV DH,00H ; Inicializa com 0, pois podia estar armazenado algum outro valor
	MOV DL,AL
	ADD DL,[col] ;DL Contém a posição informada pelo play
	MOV [indc],DL



    .VERIF_ATAQUE_VALIDO:

	CMP [vez_pc],1
	JE .VERIF_ATAQUE_VALIDO_PC

	MOV EBX,vetor_cpu
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	MOV AH,0
	MOV DL,2
	DIV DL
	CMP AH,0  ;Verifica se a informação é par ou impar
	JE  .CONFIRMA_ATAQUE
	JMP .defwndproc;loop do windows

     .VERIF_ATAQUE_VALIDO_PC:
	MOV EBX,vetor_play
	MOV ESI,0
	MOV SI,DX
	MOV EAX,[EBX+ESI]
	MOV AH,0
	MOV DL,2
	DIV DL
	CMP AH,0  ;Verifica se a informação é par ou impar
	JE  .CONFIRMA_ATAQUE
	JMP .defwndproc;loop do windows
;-------------------------------------------------------------------------
 ;Mensagem Para tecla invalida

.MSG_ERROR:

	;invoke  MessageBox,HWND_DESKTOP,"Hi! I'm the example program!","Win32 Assembly",MB_OK
	;invoke  ExitProcess,0


	jmp .defwndproc


 ;=========Funções para desenhar os números============
 ;Unidade do jogador
     .num1UnitJ:
	FLD1
	FST [corBUnitJ]
	FST [corCUnitJ]
	FLDZ
	FST [corAUnitJ]
	FST [corDUnitJ]
	FST [corEUnitJ]
	FST [corFUnitJ]
	FST [corGUnitJ]
	JMP .placarPC

     .num2UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corDUnitJ]
	FST [corEUnitJ]
	FST [corGUnitJ]
	FLDZ
	FST [corCUnitJ]
	FST [corFUnitJ]
	JMP .placarPC

     .num3UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corCUnitJ]
	FST [corDUnitJ]
	FST [corGUnitJ]
	FLDZ
	FST [corEUnitJ]
	FST [corFUnitJ]
	JMP .placarPC

     .num4UnitJ:
	FLD1
	FST [corBUnitJ]
	FST [corCUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FLDZ
	FST [corDUnitJ]
	FST [corEUnitJ]
	FST [corAUnitJ]
	JMP .placarPC

     .num5UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corCUnitJ]
	FST [corDUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FLDZ
	FST [corBUnitJ]
	FST [corEUnitJ]
	JMP .placarPC

     .num6UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corCUnitJ]
	FST [corDUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FST [corEUnitJ]
	FLDZ
	FST [corBUnitJ]
	JMP .placarPC

     .num7UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corCUnitJ]
	FLDZ
	FST [corDUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FST [corEUnitJ]
	JMP .placarPC

     .num8UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corCUnitJ]
	FST [corDUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FST [corEUnitJ]
	JMP .placarPC

     .num9UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corCUnitJ]
	FST [corGUnitJ]
	FST [corFUnitJ]
	FLDZ
	FST [corDUnitJ]
	FST [corEUnitJ]
	JMP .placarPC

     .num0UnitJ:
	FLD1
	FST [corAUnitJ]
	FST [corBUnitJ]
	FST [corCUnitJ]
	FST [corDUnitJ]
	FST [corFUnitJ]
	FST [corEUnitJ]
	FLDZ
	FST [corGUnitJ]
	JMP .placarPC

;...................................
 ;Unidade do Computador
     .num1UnitPC:
	FLD1
	FST [corBUnitPC]
	FST [corCUnitPC]
	FLDZ
	FST [corAUnitPC]
	FST [corDUnitPC]
	FST [corEUnitPC]
	FST [corFUnitPC]
	FST [corGUnitPC]
	JMP .CHECA_FINAL

     .num2UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corDUnitPC]
	FST [corEUnitPC]
	FST [corGUnitPC]
	FLDZ
	FST [corCUnitPC]
	FST [corFUnitPC]
	JMP .CHECA_FINAL

     .num3UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corCUnitPC]
	FST [corDUnitPC]
	FST [corGUnitPC]
	FLDZ
	FST [corEUnitPC]
	FST [corFUnitPC]
	JMP .CHECA_FINAL

     .num4UnitPC:
	FLD1
	FST [corBUnitPC]
	FST [corCUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FLDZ
	FST [corDUnitPC]
	FST [corEUnitPC]
	FST [corAUnitPC]
	JMP .CHECA_FINAL

     .num5UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corCUnitPC]
	FST [corDUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FLDZ
	FST [corBUnitPC]
	FST [corEUnitPC]
	JMP .CHECA_FINAL

     .num6UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corCUnitPC]
	FST [corDUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FST [corEUnitPC]
	FLDZ
	FST [corBUnitPC]
	JMP .CHECA_FINAL

     .num7UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corCUnitPC]
	FLDZ
	FST [corDUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FST [corEUnitPC]
	JMP .CHECA_FINAL

     .num8UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corCUnitPC]
	FST [corDUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FST [corEUnitPC]
	JMP .CHECA_FINAL

     .num9UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corCUnitPC]
	FST [corGUnitPC]
	FST [corFUnitPC]
	FLDZ
	FST [corDUnitPC]
	FST [corEUnitPC]
	JMP .CHECA_FINAL

     .num0UnitPC:
	FLD1
	FST [corAUnitPC]
	FST [corBUnitPC]
	FST [corCUnitPC]
	FST [corDUnitPC]
	FST [corFUnitPC]
	FST [corEUnitPC]
	FLDZ
	FST [corGUnitPC]
	JMP .CHECA_FINAL



 ;Verifica o número que irá aparecer no placar do jogador
   .placarJ:
       .num1DezenJ:
	 CMP [pontosPC],9
	 JG  .maiorDezJ
	 CMP [pontosPC],-9
	 JL  .maiorDezJ

	.menorDezJ:
	 FLDZ
	 FST [corBDezenJ]
	 FST [corCDezenJ]
	 FST [corADezenJ]
	 FST [corDDezenJ]
	 FST [corEDezenJ]
	 FST [corFDezenJ]
	 FSTP [corGDezenJ]
	 JMP .verSinalJ


	.maiorDezJ:
	 FLD1
	 FST [corBDezenJ]
	 FSTP [corCDezenJ]
	 FLDZ
	 FST [corADezenJ]
	 FST [corDDezenJ]
	 FST [corEDezenJ]
	 FST [corFDezenJ]
	 FSTP [corGDezenJ]
	 JMP .verSinalJ

	.verSinalJ:
	CMP [pontosPC],0 ;se menor q 0 desenha sinal negativo
	JL  .sinalMenosJ

	MOV EAX,0
	MOV AL,[pontosPC]
	FLDZ
	FSTP [corSinalJ];apaga o sinal em caso contrário
	jmp .DesenhaPontosJ;.DesenhapontosJ

	.sinalMenosJ:
	MOV AL,[pontosPC]
	NEG AL

	FLD1
	FSTP [corSinalJ]

     .DesenhaPontosJ:

	MOV DL,10
	DIV DL
	CMP AH,0
	JE  .num0UnitJ

	CMP AH,1
	JE  .num1UnitJ
	CMP AH,-1
	JE  .num1UnitJ

	CMP AH,2
	JE  .num2UnitJ
	CMP AH,-2
	JE  .num2UnitJ

	CMP AH,3
	JE  .num3UnitJ
	CMP AH,-3
	JE  .num3UnitJ

	CMP AH,4
	JE  .num4UnitJ
	CMP AH,-4
	JE  .num4UnitJ

	CMP AH,5
	JE  .num5UnitJ
	CMP AH,-5
	JE  .num5UnitJ

	CMP AH,6
	JE  .num6UnitJ
	CMP AH,-6
	JE  .num6UnitJ

	CMP AH,7
	JE  .num7UnitJ
	CMP AH,-7
	JE  .num7UnitJ

	CMP AH,8
	JE  .num8UnitJ
	CMP AH,-8
	JE  .num8UnitJ

	CMP AH,9
	JE  .num9UnitJ
	CMP AH,-9
	JE  .num9UnitJ

	JMP .defwndproc
;Verifica o número que irá aparecer no placar do pc
   .placarPC:
	MOV EAX,0
	.num1DezenPC:
	 CMP [pontosJ],9
	 JG  .maiorDezPC
	 CMP [pontosJ],-9
	 JL  .maiorDezPC

	.menorDezPC:
	 FLDZ
	 FST [corBDezenPC]
	 FST [corCDezenPC]
	 FST [corADezenPC]
	 FST [corDDezenPC]
	 FST [corEDezenPC]
	 FST [corFDezenPC]
	 FSTP [corGDezenPC]
	 JMP .verSinalPC


	.maiorDezPC:
	 FLD1
	 FST [corBDezenPC]
	 FSTP [corCDezenPC]
	 FLDZ
	 FST [corADezenPC]
	 FST [corDDezenPC]
	 FST [corEDezenPC]
	 FST [corFDezenPC]
	 FSTP [corGDezenPC]
	 JMP .verSinalPC

	.verSinalPC:
	CMP [pontosJ],0 ;se menor q 0 desenha sinal negativo
	JL  .sinalMenosPC

	MOV AL,[pontosJ]
	FLDZ
	FSTP [corSinalPC];apaga o sinal em caso contrário
	jmp .DesenhaPontosPC;.DesenhapontosJ

	.sinalMenosPC:
	MOV AL,[pontosJ]
	NEG AL

	FLD1
	FSTP [corSinalPC]

     .DesenhaPontosPC:

	MOV DL,10
	DIV DL

	CMP AH,0
	JE  .num0UnitPC

	CMP AH,1
	JE  .num1UnitPC
	CMP AH,-1
	JE  .num1UnitPC

	CMP AH,2
	JE  .num2UnitPC
	CMP AH,-2
	JE  .num2UnitPC

	CMP AH,3
	JE  .num3UnitPC
	CMP AH,-3
	JE  .num3UnitPC

	CMP AH,4
	JE  .num4UnitPC
	CMP AH,-4
	JE  .num4UnitPC

	CMP AH,5
	JE  .num5UnitPC
	CMP AH,-5
	JE  .num5UnitPC

	CMP AH,6
	JE  .num6UnitPC
	CMP AH,-6
	JE  .num6UnitPC

	CMP AH,7
	JE  .num7UnitPC
	CMP AH,-7
	JE  .num7UnitPC

	CMP AH,8
	JE  .num8UnitPC
	CMP AH,-8
	JE  .num8UnitPC

	CMP AH,9
	JE  .num9UnitPC
	CMP AH,-9
	JE  .num9UnitPC

	JMP .defwndproc
;===============Controlando entradas do usuario============================
  .wmkeydown:
	CMP [fim_de_jogo],1
	JE .FIM_DE_JOGO
	;caso a tecla esc seja pressionada o programa é fechado
	CMP [wparam],VK_ESCAPE
	JE .wmdestroy
	;Quando o Enter for pressionado verifica se linha e coluna foram selecionadas
	CMP [wparam],0Dh
	JE .VER_SEL

	;selecionando coluna
	MOV EAX,[wparam]
	CMP AL,41h  ;(AL<a?)->salto pra verificar se é linha
	JL  .SEL_LIN
	CMP AL,48h  ;(AL>h?)->salto pra verificar se é linha
	JG  .SEL_LIN
	SUB AL,41h
	MOV [col],AL ;armazena Al em col
	JMP .VER_SEL

  .SEL_LIN:
	CMP AL,"1" ;(AL<0?)
	JL  .MSG_ERROR ;o valor n eh coluna válida e nem linha, assim salta p incio do loop
	CMP AL,"8" ;(AL>7?)
	JG  .MSG_ERROR ;o valor n eh coluna válida e nem linha, assim salta p incio do loop
	SUB AL,"1"
	MOV [lin],AL;(se chegar aqui eh pq (1<=AL<=8), assim lin=AL
	JMP .VER_SEL


  .wmdestroy:
	invoke	wglMakeCurrent,0,0
	invoke	wglDeleteContext,[hrc]
	invoke	ReleaseDC,[hwnd],[hdc]
	invoke	PostQuitMessage,0
	xor	eax,eax
  .finish:
	pop	edi esi ebx
	ret
endp

;===================================================================================


section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
	  user,'USER32.DLL',\
	  gdi,'GDI32.DLL',\
	  opengl,'OPENGL32.DLL',\
	  glu,'GLU32.DLL'


  import kernel,\
	 GetModuleHandle,'GetModuleHandleA',\
	 GetLocalTime,'GetLocalTime',\
	 GetSystemTime,'GetSystemTime',\
	 ExitProcess,'ExitProcess'

  import user,\
	 RegisterClass,'RegisterClassA',\
	 CreateWindowEx,'CreateWindowExA',\
	 DefWindowProc,'DefWindowProcA',\
	 GetMessage,'GetMessageA',\
	 TranslateMessage,'TranslateMessage',\
	 DispatchMessage,'DispatchMessageA',\
	 LoadCursor,'LoadCursorA',\
	 LoadIcon,'LoadIconA',\
	 GetClientRect,'GetClientRect',\
	 InvalidateRect,'InvalidateRect',\
	 GetDC,'GetDC',\
	 ReleaseDC,'ReleaseDC',\
	 SetDlgItemText,'SetDlgItemTextA',\
	 wsprintf,'wsprintfA',\
	 PostQuitMessage,'PostQuitMessage'

  import gdi,\
	 ChoosePixelFormat,'ChoosePixelFormat',\
	 SetPixelFormat,'SetPixelFormat',\
	 SwapBuffers,'SwapBuffers'

  import opengl,\
	 glAccum,'glAccum',\
	 glAlphaFunc,'glAlphaFunc',\
	 glAreTexturesResident,'glAreTexturesResident',\
	 glArrayElement,'glArrayElement',\
	 glBegin,'glBegin',\
	 glBindTexture,'glBindTexture',\
	 glBitmap,'glBitmap',\
	 glBlendFunc,'glBlendFunc',\
	 glCallList,'glCallList',\
	 glCallLists,'glCallLists',\
	 glClear,'glClear',\
	 glClearAccum,'glClearAccum',\
	 glClearColor,'glClearColor',\
	 glClearDepth,'glClearDepth',\
	 glClearIndex,'glClearIndex',\
	 glClearStencil,'glClearStencil',\
	 glClipPlane,'glClipPlane',\
	 glColor3b,'glColor3b',\
	 glColor3bv,'glColor3bv',\
	 glColor3d,'glColor3d',\
	 glColor3dv,'glColor3dv',\
	 glColor3f,'glColor3f',\
	 glColor3fv,'glColor3fv',\
	 glColor3i,'glColor3i',\
	 glColor3iv,'glColor3iv',\
	 glColor3s,'glColor3s',\
	 glColor3sv,'glColor3sv',\
	 glColor3ub,'glColor3ub',\
	 glColor3ubv,'glColor3ubv',\
	 glColor3ui,'glColor3ui',\
	 glColor3uiv,'glColor3uiv',\
	 glColor3us,'glColor3us',\
	 glColor3usv,'glColor3usv',\
	 glColor4b,'glColor4b',\
	 glColor4bv,'glColor4bv',\
	 glColor4d,'glColor4d',\
	 glColor4dv,'glColor4dv',\
	 glColor4f,'glColor4f',\
	 glColor4fv,'glColor4fv',\
	 glColor4i,'glColor4i',\
	 glColor4iv,'glColor4iv',\
	 glColor4s,'glColor4s',\
	 glColor4sv,'glColor4sv',\
	 glColor4ub,'glColor4ub',\
	 glColor4ubv,'glColor4ubv',\
	 glColor4ui,'glColor4ui',\
	 glColor4uiv,'glColor4uiv',\
	 glColor4us,'glColor4us',\
	 glColor4usv,'glColor4usv',\
	 glColorMask,'glColorMask',\
	 glColorMaterial,'glColorMaterial',\
	 glColorPointer,'glColorPointer',\
	 glCopyPixels,'glCopyPixels',\
	 glCopyTexImage1D,'glCopyTexImage1D',\
	 glCopyTexImage2D,'glCopyTexImage2D',\
	 glCopyTexSubImage1D,'glCopyTexSubImage1D',\
	 glCopyTexSubImage2D,'glCopyTexSubImage2D',\
	 glCullFace,'glCullFace',\
	 glDeleteLists,'glDeleteLists',\
	 glDeleteTextures,'glDeleteTextures',\
	 glDepthFunc,'glDepthFunc',\
	 glDepthMask,'glDepthMask',\
	 glDepthRange,'glDepthRange',\
	 glDisable,'glDisable',\
	 glDisableClientState,'glDisableClientState',\
	 glDrawArrays,'glDrawArrays',\
	 glDrawBuffer,'glDrawBuffer',\
	 glDrawElements,'glDrawElements',\
	 glDrawPixels,'glDrawPixels',\
	 glEdgeFlag,'glEdgeFlag',\
	 glEdgeFlagPointer,'glEdgeFlagPointer',\
	 glEdgeFlagv,'glEdgeFlagv',\
	 glEnable,'glEnable',\
	 glEnableClientState,'glEnableClientState',\
	 glEnd,'glEnd',\
	 glEndList,'glEndList',\
	 glEvalCoord1d,'glEvalCoord1d',\
	 glEvalCoord1dv,'glEvalCoord1dv',\
	 glEvalCoord1f,'glEvalCoord1f',\
	 glEvalCoord1fv,'glEvalCoord1fv',\
	 glEvalCoord2d,'glEvalCoord2d',\
	 glEvalCoord2dv,'glEvalCoord2dv',\
	 glEvalCoord2f,'glEvalCoord2f',\
	 glEvalCoord2fv,'glEvalCoord2fv',\
	 glEvalMesh1,'glEvalMesh1',\
	 glEvalMesh2,'glEvalMesh2',\
	 glEvalPoint1,'glEvalPoint1',\
	 glEvalPoint2,'glEvalPoint2',\
	 glFeedbackBuffer,'glFeedbackBuffer',\
	 glFinish,'glFinish',\
	 glFlush,'glFlush',\
	 glFogf,'glFogf',\
	 glFogfv,'glFogfv',\
	 glFogi,'glFogi',\
	 glFogiv,'glFogiv',\
	 glFrontFace,'glFrontFace',\
	 glFrustum,'glFrustum',\
	 glGenLists,'glGenLists',\
	 glGenTextures,'glGenTextures',\
	 glGetBooleanv,'glGetBooleanv',\
	 glGetClipPlane,'glGetClipPlane',\
	 glGetDoublev,'glGetDoublev',\
	 glGetError,'glGetError',\
	 glGetFloatv,'glGetFloatv',\
	 glGetIntegerv,'glGetIntegerv',\
	 glGetLightfv,'glGetLightfv',\
	 glGetLightiv,'glGetLightiv',\
	 glGetMapdv,'glGetMapdv',\
	 glGetMapfv,'glGetMapfv',\
	 glGetMapiv,'glGetMapiv',\
	 glGetMaterialfv,'glGetMaterialfv',\
	 glGetMaterialiv,'glGetMaterialiv',\
	 glGetPixelMapfv,'glGetPixelMapfv',\
	 glGetPixelMapuiv,'glGetPixelMapuiv',\
	 glGetPixelMapusv,'glGetPixelMapusv',\
	 glGetPointerv,'glGetPointerv',\
	 glGetPolygonStipple,'glGetPolygonStipple',\
	 glGetString,'glGetString',\
	 glGetTexEnvfv,'glGetTexEnvfv',\
	 glGetTexEnviv,'glGetTexEnviv',\
	 glGetTexGendv,'glGetTexGendv',\
	 glGetTexGenfv,'glGetTexGenfv',\
	 glGetTexGeniv,'glGetTexGeniv',\
	 glGetTexImage,'glGetTexImage',\
	 glGetTexLevelParameterfv,'glGetTexLevelParameterfv',\
	 glGetTexLevelParameteriv,'glGetTexLevelParameteriv',\
	 glGetTexParameterfv,'glGetTexParameterfv',\
	 glGetTexParameteriv,'glGetTexParameteriv',\
	 glHint,'glHint',\
	 glIndexMask,'glIndexMask',\
	 glIndexPointer,'glIndexPointer',\
	 glIndexd,'glIndexd',\
	 glIndexdv,'glIndexdv',\
	 glIndexf,'glIndexf',\
	 glIndexfv,'glIndexfv',\
	 glIndexi,'glIndexi',\
	 glIndexiv,'glIndexiv',\
	 glIndexs,'glIndexs',\
	 glIndexsv,'glIndexsv',\
	 glIndexub,'glIndexub',\
	 glIndexubv,'glIndexubv',\
	 glInitNames,'glInitNames',\
	 glInterleavedArrays,'glInterleavedArrays',\
	 glIsEnabled,'glIsEnabled',\
	 glIsList,'glIsList',\
	 glIsTexture,'glIsTexture',\
	 glLightModelf,'glLightModelf',\
	 glLightModelfv,'glLightModelfv',\
	 glLightModeli,'glLightModeli',\
	 glLightModeliv,'glLightModeliv',\
	 glLightf,'glLightf',\
	 glLightfv,'glLightfv',\
	 glLighti,'glLighti',\
	 glLightiv,'glLightiv',\
	 glLineStipple,'glLineStipple',\
	 glLineWidth,'glLineWidth',\
	 glListBase,'glListBase',\
	 glLoadIdentity,'glLoadIdentity',\
	 glLoadMatrixd,'glLoadMatrixd',\
	 glLoadMatrixf,'glLoadMatrixf',\
	 glLoadName,'glLoadName',\
	 glLogicOp,'glLogicOp',\
	 glMap1d,'glMap1d',\
	 glMap1f,'glMap1f',\
	 glMap2d,'glMap2d',\
	 glMap2f,'glMap2f',\
	 glMapGrid1d,'glMapGrid1d',\
	 glMapGrid1f,'glMapGrid1f',\
	 glMapGrid2d,'glMapGrid2d',\
	 glMapGrid2f,'glMapGrid2f',\
	 glMaterialf,'glMaterialf',\
	 glMaterialfv,'glMaterialfv',\
	 glMateriali,'glMateriali',\
	 glMaterialiv,'glMaterialiv',\
	 glMatrixMode,'glMatrixMode',\
	 glMultMatrixd,'glMultMatrixd',\
	 glMultMatrixf,'glMultMatrixf',\
	 glNewList,'glNewList',\
	 glNormal3b,'glNormal3b',\
	 glNormal3bv,'glNormal3bv',\
	 glNormal3d,'glNormal3d',\
	 glNormal3dv,'glNormal3dv',\
	 glNormal3f,'glNormal3f',\
	 glNormal3fv,'glNormal3fv',\
	 glNormal3i,'glNormal3i',\
	 glNormal3iv,'glNormal3iv',\
	 glNormal3s,'glNormal3s',\
	 glNormal3sv,'glNormal3sv',\
	 glNormalPointer,'glNormalPointer',\
	 glOrtho,'glOrtho',\
	 glPassThrough,'glPassThrough',\
	 glPixelMapfv,'glPixelMapfv',\
	 glPixelMapuiv,'glPixelMapuiv',\
	 glPixelMapusv,'glPixelMapusv',\
	 glPixelStoref,'glPixelStoref',\
	 glPixelStorei,'glPixelStorei',\
	 glPixelTransferf,'glPixelTransferf',\
	 glPixelTransferi,'glPixelTransferi',\
	 glPixelZoom,'glPixelZoom',\
	 glPointSize,'glPointSize',\
	 glPolygonMode,'glPolygonMode',\
	 glPolygonOffset,'glPolygonOffset',\
	 glPolygonStipple,'glPolygonStipple',\
	 glPopAttrib,'glPopAttrib',\
	 glPopClientAttrib,'glPopClientAttrib',\
	 glPopMatrix,'glPopMatrix',\
	 glPopName,'glPopName',\
	 glPrioritizeTextures,'glPrioritizeTextures',\
	 glPushAttrib,'glPushAttrib',\
	 glPushClientAttrib,'glPushClientAttrib',\
	 glPushMatrix,'glPushMatrix',\
	 glPushName,'glPushName',\
	 glRasterPos2d,'glRasterPos2d',\
	 glRasterPos2dv,'glRasterPos2dv',\
	 glRasterPos2f,'glRasterPos2f',\
	 glRasterPos2fv,'glRasterPos2fv',\
	 glRasterPos2i,'glRasterPos2i',\
	 glRasterPos2iv,'glRasterPos2iv',\
	 glRasterPos2s,'glRasterPos2s',\
	 glRasterPos2sv,'glRasterPos2sv',\
	 glRasterPos3d,'glRasterPos3d',\
	 glRasterPos3dv,'glRasterPos3dv',\
	 glRasterPos3f,'glRasterPos3f',\
	 glRasterPos3fv,'glRasterPos3fv',\
	 glRasterPos3i,'glRasterPos3i',\
	 glRasterPos3iv,'glRasterPos3iv',\
	 glRasterPos3s,'glRasterPos3s',\
	 glRasterPos3sv,'glRasterPos3sv',\
	 glRasterPos4d,'glRasterPos4d',\
	 glRasterPos4dv,'glRasterPos4dv',\
	 glRasterPos4f,'glRasterPos4f',\
	 glRasterPos4fv,'glRasterPos4fv',\
	 glRasterPos4i,'glRasterPos4i',\
	 glRasterPos4iv,'glRasterPos4iv',\
	 glRasterPos4s,'glRasterPos4s',\
	 glRasterPos4sv,'glRasterPos4sv',\
	 glReadBuffer,'glReadBuffer',\
	 glReadPixels,'glReadPixels',\
	 glRectd,'glRectd',\
	 glRectdv,'glRectdv',\
	 glRectf,'glRectf',\
	 glRectfv,'glRectfv',\
	 glRecti,'glRecti',\
	 glRectiv,'glRectiv',\
	 glRects,'glRects',\
	 glRectsv,'glRectsv',\
	 glRenderMode,'glRenderMode',\
	 glRotated,'glRotated',\
	 glRotatef,'glRotatef',\
	 glScaled,'glScaled',\
	 glScalef,'glScalef',\
	 glScissor,'glScissor',\
	 glSelectBuffer,'glSelectBuffer',\
	 glShadeModel,'glShadeModel',\
	 glStencilFunc,'glStencilFunc',\
	 glStencilMask,'glStencilMask',\
	 glStencilOp,'glStencilOp',\
	 glTexCoord1d,'glTexCoord1d',\
	 glTexCoord1dv,'glTexCoord1dv',\
	 glTexCoord1f,'glTexCoord1f',\
	 glTexCoord1fv,'glTexCoord1fv',\
	 glTexCoord1i,'glTexCoord1i',\
	 glTexCoord1iv,'glTexCoord1iv',\
	 glTexCoord1s,'glTexCoord1s',\
	 glTexCoord1sv,'glTexCoord1sv',\
	 glTexCoord2d,'glTexCoord2d',\
	 glTexCoord2dv,'glTexCoord2dv',\
	 glTexCoord2f,'glTexCoord2f',\
	 glTexCoord2fv,'glTexCoord2fv',\
	 glTexCoord2i,'glTexCoord2i',\
	 glTexCoord2iv,'glTexCoord2iv',\
	 glTexCoord2s,'glTexCoord2s',\
	 glTexCoord2sv,'glTexCoord2sv',\
	 glTexCoord3d,'glTexCoord3d',\
	 glTexCoord3dv,'glTexCoord3dv',\
	 glTexCoord3f,'glTexCoord3f',\
	 glTexCoord3fv,'glTexCoord3fv',\
	 glTexCoord3i,'glTexCoord3i',\
	 glTexCoord3iv,'glTexCoord3iv',\
	 glTexCoord3s,'glTexCoord3s',\
	 glTexCoord3sv,'glTexCoord3sv',\
	 glTexCoord4d,'glTexCoord4d',\
	 glTexCoord4dv,'glTexCoord4dv',\
	 glTexCoord4f,'glTexCoord4f',\
	 glTexCoord4fv,'glTexCoord4fv',\
	 glTexCoord4i,'glTexCoord4i',\
	 glTexCoord4iv,'glTexCoord4iv',\
	 glTexCoord4s,'glTexCoord4s',\
	 glTexCoord4sv,'glTexCoord4sv',\
	 glTexCoordPointer,'glTexCoordPointer',\
	 glTexEnvf,'glTexEnvf',\
	 glTexEnvfv,'glTexEnvfv',\
	 glTexEnvi,'glTexEnvi',\
	 glTexEnviv,'glTexEnviv',\
	 glTexGend,'glTexGend',\
	 glTexGendv,'glTexGendv',\
	 glTexGenf,'glTexGenf',\
	 glTexGenfv,'glTexGenfv',\
	 glTexGeni,'glTexGeni',\
	 glTexGeniv,'glTexGeniv',\
	 glTexImage1D,'glTexImage1D',\
	 glTexImage2D,'glTexImage2D',\
	 glTexParameterf,'glTexParameterf',\
	 glTexParameterfv,'glTexParameterfv',\
	 glTexParameteri,'glTexParameteri',\
	 glTexParameteriv,'glTexParameteriv',\
	 glTexSubImage1D,'glTexSubImage1D',\
	 glTexSubImage2D,'glTexSubImage2D',\
	 glTranslated,'glTranslated',\
	 glTranslatef,'glTranslatef',\
	 glVertex2d,'glVertex2d',\
	 glVertex2dv,'glVertex2dv',\
	 glVertex2f,'glVertex2f',\
	 glVertex2fv,'glVertex2fv',\
	 glVertex2i,'glVertex2i',\
	 glVertex2iv,'glVertex2iv',\
	 glVertex2s,'glVertex2s',\
	 glVertex2sv,'glVertex2sv',\
	 glVertex3d,'glVertex3d',\
	 glVertex3dv,'glVertex3dv',\
	 glVertex3f,'glVertex3f',\
	 glVertex3fv,'glVertex3fv',\
	 glVertex3i,'glVertex3i',\
	 glVertex3iv,'glVertex3iv',\
	 glVertex3s,'glVertex3s',\
	 glVertex3sv,'glVertex3sv',\
	 glVertex4d,'glVertex4d',\
	 glVertex4dv,'glVertex4dv',\
	 glVertex4f,'glVertex4f',\
	 glVertex4fv,'glVertex4fv',\
	 glVertex4i,'glVertex4i',\
	 glVertex4iv,'glVertex4iv',\
	 glVertex4s,'glVertex4s',\
	 glVertex4sv,'glVertex4sv',\
	 glVertexPointer,'glVertexPointer',\
	 glViewport,'glViewport',\
	 wglGetProcAddress,'wglGetProcAddress',\
	 wglCopyContext,'wglCopyContext',\
	 wglCreateContext,'wglCreateContext',\
	 wglCreateLayerContext,'wglCreateLayerContext',\
	 wglDeleteContext,'wglDeleteContext',\
	 wglDescribeLayerPlane,'wglDescribeLayerPlane',\
	 wglGetCurrentContext,'wglGetCurrentContext',\
	 wglGetCurrentDC,'wglGetCurrentDC',\
	 wglGetLayerPaletteEntries,'wglGetLayerPaletteEntries',\
	 wglMakeCurrent,'wglMakeCurrent',\
	 wglRealizeLayerPalette,'wglRealizeLayerPalette',\
	 wglSetLayerPaletteEntries,'wglSetLayerPaletteEntries',\
	 wglShareLists,'wglShareLists',\
	 wglSwapLayerBuffers,'wglSwapLayerBuffers',\
	 wglSwapMultipleBuffers,'wglSwapMultipleBuffers',\
	 wglUseFontBitmapsA,'wglUseFontBitmapsA',\
	 wglUseFontOutlinesA,'wglUseFontOutlinesA',\
	 wglUseFontBitmapsW,'wglUseFontBitmapsW',\
	 wglUseFontOutlinesW,'wglUseFontOutlinesW',\
	 wglUseFontBitmaps,'wglUseFontBitmaps',\
	 wglUseFontOutlines,'wglUseFontOutlines',\
	 glDrawRangeElements,'glDrawRangeElements',\
	 glTexImage3D,'glTexImage3D',\
	 glBlendColor,'glBlendColor',\
	 glBlendEquation,'glBlendEquation',\
	 glColorSubTable,'glColorSubTable',\
	 glCopyColorSubTable,'glCopyColorSubTable',\
	 glColorTable,'glColorTable',\
	 glCopyColorTable,'glCopyColorTable',\
	 glColorTableParameteriv,'glColorTableParameteriv',\
	 glColorTableParameterfv,'glColorTableParameterfv',\
	 glGetColorTable,'glGetColorTable',\
	 glGetColorTableParameteriv,'glGetColorTableParameteriv',\
	 glGetColorTableParameterfv,'glGetColorTableParameterfv',\
	 glConvolutionFilter1D,'glConvolutionFilter1D',\
	 glConvolutionFilter2D,'glConvolutionFilter2D',\
	 glCopyConvolutionFilter1D,'glCopyConvolutionFilter1D',\
	 glCopyConvolutionFilter2D,'glCopyConvolutionFilter2D',\
	 glGetConvolutionFilter,'glGetConvolutionFilter',\
	 glSeparableFilter2D,'glSeparableFilter2D',\
	 glGetSeparableFilter,'glGetSeparableFilter',\
	 glConvolutionParameteri,'glConvolutionParameteri',\
	 glConvolutionParameteriv,'glConvolutionParameteriv',\
	 glConvolutionParameterf,'glConvolutionParameterf',\
	 glConvolutionParameterfv,'glConvolutionParameterfv',\
	 glGetConvolutionParameteriv,'glGetConvolutionParameteriv',\
	 glGetConvolutionParameterfv,'glGetConvolutionParameterfv',\
	 glHistogram,'glHistogram',\
	 glResetHistogram,'glResetHistogram',\
	 glGetHistogram,'glGetHistogram',\
	 glGetHistogramParameteriv,'glGetHistogramParameteriv',\
	 glGetHistogramParameterfv,'glGetHistogramParameterfv',\
	 glMinmax,'glMinmax',\
	 glResetMinmax,'glResetMinmax',\
	 glGetMinmax,'glGetMinmax',\
	 glGetMinmaxParameteriv,'glGetMinmaxParameteriv',\
	 glGetMinmaxParameterfv,'glGetMinmaxParameterfv'

  import glu,\
	 gluBeginCurve,'gluBeginCurve',\
	 gluBeginPolygon,'gluBeginPolygon',\
	 gluBeginSurface,'gluBeginSurface',\
	 gluBeginTrim,'gluBeginTrim',\
	 gluBuild1DMipmaps,'gluBuild1DMipmaps',\
	 gluBuild2DMipmaps,'gluBuild2DMipmaps',\
	 gluCylinder,'gluCylinder',\
	 gluDeleteNurbsRenderer,'gluDeleteNurbsRenderer',\
	 gluDeleteQuadric,'gluDeleteQuadric',\
	 gluDeleteTess,'gluDeleteTess',\
	 gluDisk,'gluDisk',\
	 gluEndCurve,'gluEndCurve',\
	 gluEndPolygon,'gluEndPolygon',\
	 gluEndSurface,'gluEndSurface',\
	 gluEndTrim,'gluEndTrim',\
	 gluErrorString,'gluErrorString',\
	 gluGetNurbsProperty,'gluGetNurbsProperty',\
	 gluGetString,'gluGetString',\
	 gluGetTessProperty,'gluGetTessProperty',\
	 gluLoadSamplingMatrices,'gluLoadSamplingMatrices',\
	 gluLookAt,'gluLookAt',\
	 gluNewNurbsRenderer,'gluNewNurbsRenderer',\
	 gluNewQuadric,'gluNewQuadric',\
	 gluNewTess,'gluNewTess',\
	 gluNextContour,'gluNextContour',\
	 gluNurbsCallback,'gluNurbsCallback',\
	 gluNurbsCurve,'gluNurbsCurve',\
	 gluNurbsProperty,'gluNurbsProperty',\
	 gluNurbsSurface,'gluNurbsSurface',\
	 gluOrtho2D,'gluOrtho2D',\
	 gluPartialDisk,'gluPartialDisk',\
	 gluPerspective,'gluPerspective',\
	 gluPickMatrix,'gluPickMatrix',\
	 gluProject,'gluProject',\
	 gluPwlCurve,'gluPwlCurve',\
	 gluQuadricCallback,'gluQuadricCallback',\
	 gluQuadricDrawStyle,'gluQuadricDrawStyle',\
	 gluQuadricNormals,'gluQuadricNormals',\
	 gluQuadricOrientation,'gluQuadricOrientation',\
	 gluQuadricTexture,'gluQuadricTexture',\
	 gluScaleImage,'gluScaleImage',\
	 gluSphere,'gluSphere',\
	 gluTessBeginContour,'gluTessBeginContour',\
	 gluTessBeginPolygon,'gluTessBeginPolygon',\
	 gluTessCallback,'gluTessCallback',\
	 gluTessEndContour,'gluTessEndContour',\
	 gluTessEndPolygon,'gluTessEndPolygon',\
	 gluTessNormal,'gluTessNormal',\
	 gluTessProperty,'gluTessProperty',\
	 gluTessVertex,'gluTessVertex',\
	 gluUnProject,'gluUnProject'   



