QTree	START	0000

. main routine
FIRST	JSUB	RDARR	. get input to ARR

	LDA	#STACK
	STA	TOP	. set top pointer of stack

	LDA	ARRSIZE
	STA	tmpN
	LDA	#0
	STA	tmpX
	STA	tmpY	. parameter passing(tmpN, tmpX, tmpY)

	JSUB	SOLVE	. SOLVE(N, 0, 0)

DENTER	TD	#0
	JEQ	DENTER
	RD	#0	. 입력의 마지막에 들어온 enter를 버퍼에서 지움으로써 연속입력 가능

	J	ENDED

ENDED	J	ENDED	. end of program

BRAC1	WORD	40	. '(' = Ox28 : ASCII
BRAC2	WORD	41	. ')' = 0x29 : ASCII



. subroutine for getting input (TC입력이 아닌 ARR 입력임)
RDARR	LDS	#3	. WORD SIZE ( ONE SPACE SIZE OF ARRAY )
	LDX	#0
	LDA	#0
	
GETSIZE	TD	#0
	JEQ	GETSIZE
	RD	#0	. size N 입력받기
	SUB	ZEROC	. 아스키 값이 아닌 상수 값으로 저장하기 위함
	STA	ARRSIZE	. N : 1~8
	RMO	A,T
	MULR	T,A	. make two dimension array space(N X N)
	MUL	#3	. make real array size(메모리공간 크기 계산)
	RMO	A,T	. T = A

TESTIN	LDA	#0
	TD	#0
	JEQ	TESTIN
	RD	#0

	COMP	ENTER
	JEQ	TESTIN	. if new line character is entered

	SUB	ZEROC
	STA	ARR,X
	ADDR	S,X	. X = X + S
	COMPR	X,T	. end of array size
	JLT	TESTIN
	RSUB		. return RDARR

ZEROC	WORD	48	. '0' character (0x30)
ENTER	WORD	10	. NEW LINE character (0x0A)

ARRSIZE	RESW	1	. array size to be inputed (N)
ARR	RESW	64	. 3byte space x 64 (max size)



. recusive subroutine 'SOLVE', parameter passing through: tmpN, tmpX, tmpY
SOLVE	LDA	ARRSIZE	. calculate the address of ARR[?][?]
	MUL	#3
	MUL	tmpY
	RMO	A,S	. A -> S

	LDA	tmpX
	MUL	#3
	ADDR	S,A	. A = A + S

	LDS	#ARR	. S = address of ARR
	ADDR	S,A	. A = address of ARR[tmpY][tmpX]
	STA	taraddr	

	. 재귀 탈출 조건 검사
	LDA	tmpN
	COMP	#1
	JGT	DOMORE	. if (N > 1)

OUTVAL	TD	#1		. 숫자 출력
	JEQ	OUTVAL
	LDA	@taraddr	. *taraddr : the value in ARR[?][?] (ASCII)
	ADD	#48		. add ASCII '0'
	WD	#1
	J	EXIT		. escape recursive subroutine

DOMORE	LDA	tmpN
	DIV	#2
	STA	half	. half = A / 2

	. 기준값 설정
	LDA	@taraddr
	STA	pivot	. pivot = ARR[tmpY][tmpX]

	. calculate iMax (iMax = tmpY + tmpN)
	LDS	tmpY
	LDA	tmpN
	ADDR	A,S	. S = S + A
	STS	iMax

	. calculate jMax (jMax = tmpX + tmpN)
	LDS	tmpX
	LDA	tmpN
	ADDR	A,S
	STS	jMax

	LDS	tmpY
	STS	i	. i = tmpY 부터 반복문 시작

	LDX	tmpX	. (X) = tmpX 부터 반복문 시작
	J	LOOPCOL
	
	.LOOPROW visit every rows
LOOPROW	LDX	tmpX	. (X)값은 다시 tmpX부터 시작
	STX	j

	LDA	i
	ADD	#1
	STA	i

	COMP	iMax
	JLT	LOOPCOL	
	JEQ	OUTVAL	. if all number of this area are same

	. LOOPCOL visit every columns
LOOPCOL	STX	j

	. calculate the address of ARR[i][j]
	LDA	ARRSIZE
	MUL	#3
	MUL	i
	RMO	A,T	. A -> T

	LDA	j
	MUL	#3
	ADDR	T,A	. A = A + T

	LDT	#ARR	. T = address of ARR
	ADDR	T,A	. A = address of ARR[i][j]
	STA	taraddr

	. 구역의 X축 공간을 순회하다가 pivot과 다른값이 있는지 검사
	LDA	@taraddr
	COMP	pivot
	JEQ	NEXTCOL	. if (pivot == ARR[i][j]) continue;
	JGT	RECURS
	JLT	RECURS

NEXTCOL	TIX	jMax	. X++
	JLT	LOOPCOL	. if (j < tmpX + N)
	JEQ	LOOPROW	. this row's element values are all same

	. if (pivot != ARR[i][j]) -> need to call "recursive subroutines"
RECURS	TD	#1
	JEQ	RECURS
	LDA	BRAC1
	WD	#1	. '('

	STL	tmpL

. @@@ recursive call 1 : SOLVE(half, y, x)
	JSUB	PROLOG	. push current sobroutine's info before call a recursive subroutine

	. parameter passing: tmpN, tmpX, tmpY
	LDA	half
	STA	tmpN
	JSUB	SOLVE	

	JSUB	EPILOG	. restore information after recursive subroutine was returned

. @@@ recursive call 2 : SOLVE(half, y, x + half)
	JSUB	PROLOG

	. parameter passing: tmpN, tmpX, tmpY
	LDA	half
	STA	tmpN
	LDA	tmpX
	ADD	half
	STA	tmpX
	JSUB	SOLVE

	JSUB	EPILOG

. @@@ recursive call 3 : SOLVE(half, y + half, x)
	JSUB	PROLOG

	. parameter passing: tmpN, tmpX, tmpY
	LDA	half
	STA	tmpN
	LDA	tmpY
	ADD	half
	STA	tmpY
	JSUB	SOLVE

	JSUB	EPILOG

. @@@ recursive call 4 : SOLVE(half, y + half, x + half)
	JSUB	PROLOG

	. parameter passing: tmpN, tmpX, tmpY
	LDA	half
	STA	tmpN

	LDA	tmpY
	ADD	half
	STA	tmpY

	LDA	tmpX
	ADD	half
	STA	tmpX

	JSUB	SOLVE

	JSUB	EPILOG

	LDL	tmpL	. 현재 subroutine이 RSUB하기 전에 L레지스터에 복귀 주소를 로드해둔다.

OUTLP3	TD	#1
	JEQ	OUTLP3
	LDA	BRAC2
	WD	#1	. ')'

	RSUB		. return SOLVE
EXIT	RSUB		. return SOLVE

half	RESW	1	. current N / 2
pivot	RESW	1	. value to determine if a area has the same value
i	RESW	1	. i and j will be used nested repetitive sentence
j	RESW	1	. i means row index(y), j means column index(x)
iMax	RESW	1	. = tmpY + N
jMax	RESW	1	. = tmpX + N
tmpL	RESW	1	. used for stack
tmpN	RESW	1	. parameter of SOLVE
tmpX	RESW	1	. parameter of SOLVE
tmpY	RESW	1	. parameter of SOLVE
taraddr	RESW	1	. address of ARR[i][j]



PROLOG	STL	retaddr	. store backuo address

	LDA	tmpX	. stack에 push하는 이유: 현재 실행중인 함수가 자신을 위해 서브루틴 호출 전에 스택에 저장함
	JSUB	PUSH	. push current X
	LDA	tmpY
	JSUB	PUSH	. push current Y
	LDA	tmpN
	JSUB	PUSH	. push current N
	LDA	tmpL
	JSUB	PUSH	. push current L for return ("현재 실행중인 서브루틴"이 되돌아 가기 위해  현재 J 레지스터 값을 스택에 push함)
	LDA	half
	JSUB	PUSH	. push current half value to call next recursive subroutines

	LDL	retaddr	. restore backup address
	RSUB

EPILOG	STL	retaddr	. store backuo address

	JSUB	POP
	STA	half
	JSUB	POP
	STA	tmpL
	JSUB	POP
	STA	tmpN
	JSUB	POP
	STA	tmpY
	JSUB	POP
	STA	tmpX

	LDL	retaddr	. restore backup address
	RSUB

retaddr	RESW	1	. backup PROLOGUE'S return address



. subroutine for stack
PUSH	STA	@TOP
	LDA	TOP
	ADD	#3
	STA	TOP
	RSUB

POP	LDA	TOP
	SUB	#3
	STA	TOP
	LDA	@TOP
	RSUB

TOP	RESW	1
STACK	RESW	4096	. before calling the recursive subroutine, push the current sobroutine's info