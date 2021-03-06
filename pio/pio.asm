; Intel Intellec Series II/III MDS IOC parallel I/O controller (PIO) 8041A

; The host interface is documented in chapter 5 of "Intellec(R) Series II
; Microcomputer Development System Hardware Interface Manual", Intel order
; number 9800555-03, July 1983

; Reverse engineered by Eric Smith <spacewar@gmail.com>

; assembles with asl (Macro Assembler AS)
;   http://john.ccac.rwth-aachen.de:8000/as/


 		ifndef	mod220
mod220		equ	0
		endif

		ifndef	mod230
mod230		equ	0
		endif

		ifndef	m104566_001
m104566_001	equ	0
		endif

	if	(mod220+mod230+m104566_001) <> 1
	fatal	"must select one version to assemble on command line"
	endif


; Port assignments

;   TEST1 - PPACK, J7-2 to UPP
;   PORT1 - P10-P17
;   PORT2 - P20-P23 to 74154 decoder
;           P24 to 74154 enable (active low)
;           P25 to PTRDR ENABLE (active low)
;           P26 to UPP IN ENABLE (active low)
;           P27 to parallel int J14-31
;
;   74145 outputs
;      UPP
;      0 - PPWC/D/  J7-25
;      1 - PPWC2/   J7-23
;      2 - PPWC1/   J7-24
;      3 - PPRC0/   J7-4
;      4 - PPRC1/   J7-3
;      5 - INIT/    J7-14
;
;      paper tape punch
;      6 - PUNCH COMMAND/    J4-11
;
;      7 - DR/               J5-16
;      8 - DL/               J5-17
;
;      printer
;      9 - LPT DATA STROBE/  J6-14
;     10 - LPT CTL 1/        J6-19
;     11 - LPT CTL 2/        J6-20
;
;     12 - STATUS ENABLE/



; RAM usage

; 028h - interrupt enables, set with sint command from host
;        bit 0 - 001h - paper tape punch interrupt enable
;        bit 1 - 002h - line printer interrupt enable
;        bit 2 - 004h - paper tape reader interrupt enable
;        bit 3 - 008h - undocumented

	cpu	8041

fillto	macro	dest,value
	while	$<dest
	db	value
	endm
	endm


	org	0
	jmp	reset

	fillto	0003h,000h
	jmp	ibfirq

	if	mod220
	db	012h,012h
	endif
	if	mod230
	db	003h,023h
	endif
	if	m104566_001
	db	007h,016h
	endif

	fillto	0007h,000h
	jmp	tmrirq


main:	orl	p1,#0ffh
	anl	p2,#0fch
	anl	p2,#0efh
	in	a,p1
	en	i
	orl	p2,#10h
	orl	p2,#3
	anl	a,#15h
	mov	r2,a
	swap	a
	inc	a
	anl	a,#0eh
	orl	a,r2
	anl	a,#0fh
	mov	r2,a
	dis	i

	mov	r1,#26h
	mov	a,@r1
	anl	a,r2
	jz	X002d
	mov	r1,#21h
	orl	a,@r1
	mov	@r1,a
	orl	p2,#80h		; set interrupt to master

X002d:	jmp	main


ibfirq:	clr	f0
	cpl	f0
	sel	rb1
	mov	r2,a
	orl	p2,#7fh

	in	a,dbb		; get byte from host, save in r7
	mov	r7,a

	jf1	X003b		; command
	jmp	X03de		; data

X003b:	clr	f1
	xch	a,r5
	jz	X0041
	jmp	X0100

X0041:	xch	a,r5
	mov	r0,#27h
	mov	@r0,a
	anl	a,#0e0h
	xch	a,r7
	anl	a,#1fh
	mov	r6,a
	add	a,#0f0h
	jnc	X0051
	jmp	cmd1x

X0051:	jmp	cmd0x


X0053:	anl	p2,#0efh	; pulse 74154 enable
X0055:	orl	p2,#10h
	orl	p2,#7fh
X0059:	clr	f0
	mov	a,r2
	retr

X005c:	mov	r5,#0
	clr	f0
	mov	a,r2
	retr

tmrirq:	mov	r4,a
	orl	p2,#7fh
	call	X03d2
	mov	r3,a
	inc	r7
	inc	r6
	inc	r5
	mov	a,r3
	jb4	X0077
	jb6	X0077
	mov	a,r7
	xrl	a,#0afh
	jnz	X007d
	mov	r7,a
	jmp	X0079

X0077:	mov	a,#2
X0079:	mov	r0,#24h
	call	X00b0
X007d:	mov	a,r3
	jb0	X0088
	mov	a,r6
	xrl	a,#0dh
	jnz	X008e
	mov	r6,a
	jmp	X008a

X0088:	mov	a,#2
X008a:	mov	r0,#23h
	call	X00b0
X008e:	mov	a,r3
	jb2	X0099
	mov	a,r5
	xrl	a,#0dh
	jnz	X009f
	mov	r5,a
	jmp	X009b

X0099:	mov	a,#2
X009b:	mov	r0,#22h
	call	X00b0
X009f:	call	X03c9
	clr	a
	jt1	X00a6
	mov	a,#2
X00a6:	mov	r0,#25h
	call	X00b0
	orl	p2,#10h
	orl	p2,#7fh
	mov	a,r4
	retr

X00b0:	xch	a,@r0
	anl	a,#0fdh
	orl	a,@r0
	mov	@r0,a
	ret

X00b6:
	if	mod220
	mov	r3,#2
	endif
	if	mod230 | m104566_001
	mov	r3,#96h
	endif

X00b8:	jt1	X00bc
	jmp	X00d5

	if	mod220
X00bc:	jtf	X00c0
X00be:	jmp	X00b8
	endif
	if	mod230 | m104566_001
X00bc:	jmp	X00be
X00be:	jmp	X00c0
	endif

X00c0:	djnz	r3,X00b8
	orl	p2,#10h
	orl	p2,#7fh
	mov	r1,#25h
	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	mov	a,#0ffh
	clr	f1
	cpl	f1
	out	dbb,a
	clr	a
	mov	@r1,a
	clr	c
	ret

X00d5:	clr	c
	cpl	c
	ret


X00d8:	call	X03d2
	anl	a,r4
	jz	X00e0
	clr	c
	cpl	c
	ret

X00e0:	jtf	X00e4
	jmp	X00e0

X00e4:	djnz	r3,X00d8
	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	clr	c
	ret


X00ec:	mov	r4,a
	mov	r0,#28h
	anl	a,@r0
	jnz	X00f8
	mov	r0,#27h
	mov	a,@r0
	jb7	X00f8
	ret

X00f8:	mov	r0,#26h
	mov	a,r4
	orl	a,@r0
	mov	@r0,a
	ret


; get contents of a ROM page 0 location, for checksum computation
getrp0:	movp	a,@a
	ret


X0100:	add	a,#X0103 & 0ffh
	jmpp	@a

X0103:	db	X0124 & 0ffh
	db	X010e & 0ffh
	db	X0118 & 0ffh
	db	X011c & 0ffh
	db	X011c & 0ffh
	db	X011c & 0ffh
	db	X011c & 0ffh
	db	X011c & 0ffh
	db	X0120 & 0ffh
	db	X0120 & 0ffh
	db	X0120 & 0ffh

X010e:	mov	r0,#23h
X0110:	mov	a,#20h
	orl	a,@r0
	mov	@r0,a
	mov	r5,#0
	jmp	X0041

X0118:	mov	r0,#24h
	jmp	X0110

X011c:	mov	r0,#25h
	jmp	X0110

X0120:	mov	r0,#20h
	jmp	X0110

X0124:	jmp	X005c


; handle commands 000h through 00fh
cmd0x:	mov	a,r6
	add	a,#ctbl0x & 0ffh
	jmpp	@a

ctbl0x:	db	pacify & 0ffh	; 00h pacify - reset PIO and devices
	db	ereset & 0ffh	; 01h ereset - reset device-generated error
	db	systat & 0ffh	; 02h systat - get subsystem status byte
	db	dstat & 0ffh	; 03h dstat  - get device status byte
	db	srqdak & 0ffh	; 04h srqdak - device interrupt acknowledge
	db	srqack & 0ffh	; 05h srqack - clear interrupt request
	db	srq & 0ffh	; 06h srq    - generate int req to master
	db	decho & 0ffh	; 07h decho  - echo byte from master
	db	xcsmem & 0ffh	; 08h csmem  - checksum ROM
	db	xtram & 0ffh	; 09h tram   - test RAM
	db	xsint & 0ffh	; 0ah sint   - enable specified interrupt

; remainder undefined
	db	badc0x & 0ffh	; 0bh
	db	badc0x & 0ffh	; 0ch
	db	badc0x & 0ffh	; 0dh
	db	badc0x & 0ffh	; 0eh
	db	badc0x & 0ffh	; 0fh

xcsmem:	jmp	csmem

xtram:	jmp	tram

xsint:	jmp	sint

badc0x:	jmp	badc1x


reset:		; power-on reset
pacify:		; pacify (00h) command - reset PIO and devices
	if	mod220 | mod230
	dis	i
	endif

	stop	tcnt
	dis	tcnti

	if	m104566_001
	dis	i
	jtf	$+2
	endif

	orl	p1,#0ffh
	mov	a,#7fh
	outl	p2,a
	anl	p2,#0f5h
	anl	p2,#0efh

	if	mod220 | mod230
	mov	a,#0ffh		; start timer and verify that it works
	endif

	if	m104566_001
	mov	a,#000h		; start timer and verify that it works
	endif
	
	mov	t,a
	strt	t
X0152:	jtf	X0156
	jmp	X0152

X0156:	orl	p2,#10h
	orl	p2,#0ah
	sel	rb0

	mov	r0,#3fh		; clear RAM
	clr	a
X015e:	mov	@r0,a
	djnz	r0,X015e

	mov	a,#0
	mov	psw,a
	clr	f0
	clr	f1
	call	X016b
	en	tcnti
	jmp	main


X016b:	retr


ereset:		; ereset (01h) command - reset device-generated error
	jmp	badc1x


systat:		; systat (02h) commnad - get subsystem status byte
	mov	r0,#22h		; merge MSB of device status bytes from r22 through r25
	mov	a,@r0
	mov	r0,#23h
	orl	a,@r0
	mov	r0,#24h
	orl	a,@r0
	mov	r0,#25h
	orl	a,@r0
	anl	a,#0f0h
	mov	r1,a
	jz	X0181		; any devices have error?
	mov	r1,#80h		; yes, set device error in system status byte
X0181:	clr	a
	mov	r0,#20h
	xch	a,@r0
	orl	a,r1
	out	dbb,a
	jmp	X005c

dstat:		; dstat (03h) commnad - get device status byte
	mov	r0,#22h		
	mov	a,@r0
	mov	r1,#0f0h
	anl	a,r1
	mov	r3,a
	jz	X0194
	mov	r3,#40h
X0194:	mov	r0,#23h
	mov	a,@r0
	anl	a,r1
	jz	X019e
	mov	a,#10h
	orl	a,r3
	mov	r3,a
X019e:	mov	r0,#24h
	mov	a,@r0
	anl	a,r1
	jz	X01a8
	mov	a,#20h
	orl	a,r3
	mov	r3,a
X01a8:	mov	r0,#25h
	mov	a,@r0
	anl	a,r1
	jz	X01b2
	mov	a,#80h
	orl	a,r3
	mov	r3,a
X01b2:	clr	a
	mov	r0,#21h
	xch	a,@r0
	orl	a,r3
	out	dbb,a
	jmp	X005c



srqdak:		; srqdak (04h) command - device interrupt acknowledge
	mov	r5,#8
	jmp	X0059

; data byte received for srqdak command
dsrqda:	mov	a,r7
	cpl	a
	anl	a,#0fh
	mov	r7,a
	mov	r0,#26h
	anl	a,@r0
	mov	@r0,a
	mov	a,r7
	swap	a
	orl	a,r7
	mov	r0,#21h
	anl	a,@r0
	mov	@r0,a
	mov	a,r7
	jnz	X01d9
	mov	r0,#20h
	mov	a,#10h
	orl	a,@r0
	mov	@r0,a
	jmp	X005c

X01d9:	anl	p2,#7fh
	jmp	X005c


; srqack (05h) command - reset all device interrupt bits, and interrupt signal to master
srqack:
	clr	a
	mov	r0,#26h
	mov	@r0,a
	mov	r0,#21h
	mov	a,#0f0h
	anl	a,@r0
	mov	@r0,a
	anl	p2,#7fh		; disable interrupt to master
	jmp	X005c


; srq (06h) command - generate hardware interrupt
srq:	orl	p2,#80h		; enable interrupt to master
	jmp	X005c


; decho (07h) command - echo byte from master
decho:	mov	r5,#9
	jmp	X0059

; received decho byte
ddecho:	mov	a,r7
	cpl	a
	out	dbb,a
	jmp	X005c


; get contents of a ROM page 1 location, for checksum computation
getrp1:	movp	a,@a
	ret

	fillto	0200h,000h

; csmem (08h) command - checksum ROM
csmem:	clr	c
	clr	a
	mov	r3,a
	mov	r4,a
X0204:	mov	a,r3
	call	getrp0
	addc	a,r4
	mov	r4,a
	djnz	r3,X0204

X020b:	mov	a,r3
	call	getrp1
	addc	a,r4
	mov	r4,a
	djnz	r3,X020b

X0212:	mov	a,r3
	movp	a,@a
	addc	a,r4
	mov	r4,a
	djnz	r3,X0212

X0218:	mov	a,r3
	call	getrp3
	addc	a,r4
	mov	r4,a
	djnz	r3,X0218

	mov	a,r4

	if	mod220
	add	a,#0f9h
	endif
	if	mod230
	add	a,#34h
	endif
	if	m104566_001
; do nothing
	endif
	
	jnz	X0227

	out	dbb,a		; ROM checksum good, return 000h
	jmp	X005c

X0227:	mov	a,#0ffh		; ROM checksum bad, return 0ffh
	cpl	f1
	out	dbb,a
	jmp	X0059


; tram (09h) command - test RAM
tram:	sel	rb0
	mov	r0,#3fh
	mov	a,#55h
X0232:	mov	@r0,a
	djnz	r0,X0232
	mov	r0,#3fh
X0237:	mov	a,#55h
	xrl	a,@r0
	jnz	X0252
	djnz	r0,X0237
	mov	r0,#3fh
	mov	a,#0aah
X0242:	mov	@r0,a
	djnz	r0,X0242
	mov	r0,#3fh
X0247:	mov	a,#0aah
	xrl	a,@r0
	jnz	X0252
	djnz	r0,X0247

	clr	a		; RAM OK, return 000h
	out	dbb,a
	jmp	reset


X0252:	mov	a,#0ffh		; RAM bad, return 0ffh
	cpl	f1
	out	dbb,a
	jmp	reset


; sint (0ah) command - enable specified interrupt
sint:	mov	r5,#0ah
	jmp	X0059

; data byte received for sint command
;    bits 7..4  reserved
;    bit 3:     documented as reserved, but not masked off below
;    bit 2:     interrupt enable for paper tape reader
;    bit 1:     interrupt enable for line printer
;    bit 0:     interrupt enable for paper tape punch
dsint:	mov	r0,#28h
	mov	a,r7
	anl	a,#0fh		; note low *four* bits preserved
	mov	@r0,a		;   function of bit 3 undocumented
	jmp	X005c


badc1x:	mov	r0,#20h
	mov	a,#40h		; illegal command bit
	orl	a,@r0
	mov	@r0,a
	jmp	X0059


; handle commands 010h through 01fh
; note that 010h has already been subtraced from command value in A
cmd1x:	add	a,#ctbl1x & 0ffh
	jmpp	@a

ctbl1x:
; paper tape reader
	db	rdrc & 0ffh	; 10h rdrc - read byte or move one frame fwd/rev
	db	rstc & 0ffh	; 11h rstc - read status byte

; paper tape punch
	db	punc & 0ffh	; 12h punc - punch one byte
	db	pstc & 0ffh	; 13h pstc - read status byte

; printer
	db	xlptc & 0ffh	; 14h lptc - print one byte
	db	xlstc & 0ffh	; 15h lstc - read status byte

; PROM programmer
	db	xwppc & 0ffh	; 16h wppc - send two addr/ctl, write one byte
	db	xrppc & 0ffh	; 17h rppc - send two addr/ctl, read one byte
	db	xrpstc & 0ffh	; 18h rpstc - read two status bytes
	db	xrdpdc & 0ffh	; 19h rdpdc - read data byte

; remainder undefined
	db	badc1x & 0ffh	; 1ah
	db	badc1x & 0ffh	; 1bh
	db	badc1x & 0ffh	; 1ch
	db	badc1x & 0ffh	; 1dh
	db	badc1x & 0ffh	; 1eh
	db	badc1x & 0ffh	; 1fh


xlptc:	jmp	lptc

xlstc:	jmp	lstc

xwppc:	jmp	wppc

xrppc:	jmp	rppc

xrpstc:	jmp	rpstc

xrdpdc:	jmp	rdpdc


; rdrc (10h) command
; read data byte if bit 6 of command is zero
; move tape forward one frame if bit 6 is zero and bit 5 is zero
; move tape backward one frame if bit 6 is one and bit 5 is one
rdrc:	mov	r5,#0
	mov	r1,#22h
	mov	r4,#4
	mov	r3,#0eh
	call	X00d8
	jnc	X02b5
	sel	rb0
	mov	r5,#0
	sel	rb1
	mov	a,#4
	call	X00ec
	mov	a,r7
	jb6	X02ab
	anl	p2,#0dfh
	anl	p2,#0efh
	in	a,p1
	clr	f1
	out	dbb,a
	jmp	X0055

X02ab:	jb5	X02b1
	anl	p2,#0f7h
	jmp	X0053

X02b1:	anl	p2,#0f8h
	jmp	X0053

X02b5:	mov	a,r7
	jb6	X02be
	clr	a
	xch	a,@r1
	cpl	f1
	out	dbb,a
	jmp	X0059

X02be:	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	jmp	X005c


; rstc (11h) command - get reader status byte
;    bit 7:     reader timeout
;    bit 6:     illegal status request (rstc command w/ request interrupt)
;    bits 5..2: reserved
;    bit 1:     systems ready
;    bit 0:     data ready
rstc:	mov	r0,#22h
	call	X03d2
	anl	a,#4
	jmp	X0337


; punc (12h) command - punch one byte
punc:	mov	r5,#1
	jmp	X0059

; data byte received for punc command
dpunc:	mov	r5,#0
	mov	r1,#23h
	mov	r4,#1
	mov	r3,#0eh
	call	X00d8
	jnc	X02ea
	sel	rb0
	mov	r6,#0
	sel	rb1
	mov	a,#1
	call	X00ec
	mov	a,r7
	outl	p1,a
	anl	p2,#0f6h
	jmp	X0053

X02ea:	jmp	X005c


; pstc (13h) command - get punch status byte
;    bit 7:     punch timeout
;    bit 6:     illegal status request (pstc command w/ request interrupt)
;    bit 5:     illegal command (punc command followed by a command byte)
;    bits 4..2: reserved
;    bit 1:     systems ready
;    bit 0:     punch ready
pstc:	mov	r0,#23h
	call	X03d2
	anl	a,#1
	jmp	X0339


	if	m104566_001
	db	03bh
	endif


	fillto	0300h,000h

X0300:	jmp	X005c

X0302:	jmp	X02be


; lptc (14h) command - print one byte
lptc:	mov	r5,#2
	jmp	X0059

; data byte received for lptc command
dlptc:	mov	r5,#0
	mov	r1,#24h
	mov	r4,#10h
	mov	r3,#0afh
	call	X00d8
	jnc	X0300
	sel	rb0
	mov	r7,#0
	sel	rb1
	mov	a,#2
	call	X00ec
	mov	a,r7
	cpl	a
	outl	p1,a
	anl	p2,#0f9h
	jmp	X0053


; lstc (15h) command - get printer status byte
;    bit 7:     printer timeout
;    bit 6:     illegal status request (lstc command w/ request interrupt)
;    bit 5:     illegal command (lptc command followed by a command byte)
;    bits 4..3: reserved
;    bit 2:     printer selected
;    bit 1:     printer present
;    bit 0:     printer ready
lstc:	mov	r0,#24h
	call	X03d2
	anl	a,#50h
	xrl	a,#40h
	mov	r1,a
	mov	a,@r0
	anl	a,#2
	rr	a
	rr	a
	rr	a
	orl	a,#10h
	anl	a,r1
	rr	a
	rr	a
X0337:	rr	a
	rr	a
X0339:	mov	r1,a
	mov	a,@r0
	anl	a,#2
	xch	a,@r0
	orl	a,r1
	mov	r1,a
	mov	a,r7
	anl	a,#80h
	rr	a
	orl	a,r1
	out	dbb,a
	jmp	X005c


; wppc (16h) command - send two addr/ctl, write one data byte
wppc:	mov	r5,#3
	jmp	X0059

; first byte (addr/ctl 1) received for wppc comand
d1wppc:	mov	r5,#4
	mov	a,r7
	outl	p1,a
	anl	p2,#0f1h
	jmp	X0053

; second byte (addr/ctl 2) received for wppc command
d2wppc:	mov	r5,#5
	mov	a,r7
	outl	p1,a
	anl	p2,#0f2h
	jmp	X0053

; third byte (data) received for wppc command
d3wppc:	mov	r5,#0
	mov	r1,#25h
	call	X03c9
	jt1	X0302
	orl	p2,#10h
	orl	p2,#7fh
	mov	a,#8
	call	X00ec
	mov	a,r7
	outl	p1,a
	anl	p2,#0f0h
	jmp	X0053


; rppc (017h) command - send two addr/ctl, read one data byte
rppc:	mov	r5,#6
	jmp	X0059

; first byte (addr/ctl) received for rppc command
d1rppc:	mov	r5,#7
	mov	a,r7
	outl	p1,a
	anl	p2,#0f1h
	jmp	X0053

; second byte (addr/ctl) received for rppc command
d2rppc:	mov	r5,#0
	mov	a,r7
	outl	p1,a
	anl	p2,#0f2h
	anl	p2,#0efh
	orl	p2,#10h
	orl	p2,#7fh
; fall into rdpdc command


; rdpdc (19h) command - read data byte
rdpdc:	mov	a,#8
	call	X00ec
	orl	p1,#0ffh
	mov	a,r7
	jb6	X039f
	anl	p2,#0bfh
	anl	p2,#0f3h
	anl	p2,#0efh
	call	X00b6
	jnc	X0300
	in	a,p1
	out	dbb,a
X039f:	jmp	X0055


; rpstc (18h) command - read two status bytes
rpstc:	mov	r0,#25h
	mov	r5,#0
	call	X03c9
	jt1	X03c0
	in	a,p1
	anl	a,#0ffh
X03ac:	out	dbb,a
	clr	f0
	orl	p2,#10h
	orl	p2,#7fh
X03b2:	jnibf	X03b6
	jmp	badc1x

X03b6:	jobf	X03b2
	mov	a,@r0
	anl	a,#2
	xch	a,@r0
	clr	f1
	out	dbb,a
	jmp	X005c

X03c0:	mov	a,#80h
	orl	a,@r0
	mov	@r0,a
	mov	a,#0ffh
	cpl	f1
	jmp	X03ac

X03c9:	orl	p1,#0ffh
	anl	p2,#0bfh
	anl	p2,#0f4h
	anl	p2,#0efh
	ret

X03d2:	orl	p1,#0ffh
	anl	p2,#0fch
	anl	p2,#0efh
	in	a,p1
	orl	p2,#10h
	orl	p2,#7fh
	ret


; received a data byte from master
; contents of r5 determine how to deal with it
X03de:	mov	a,r5
	add	a,#X03e2 & 0ffh
	jmpp	@a

X03e2:	db	drdrc & 0ffh	; rdrc
	db	xdpunc & 0ffh	; punc
	db	dlptc & 0ffh	; lptc
	db	d1wppc & 0ffh	; wppc byte 1
	db	d2wppc & 0ffh	; wppc byte 2
	db	d3wppc & 0ffh	; wppc byte 3
	db	d1rppc & 0ffh	; rppc byte 1
	db	d2rppc & 0ffh	; rppc byte 2
	db	xdsrqd & 0ffh	; srqdak
	db	xddech & 0ffh	; decho
	db	xdsint & 0ffh	; sint


xdpunc:	jmp	dpunc

xdsrqd:	jmp	dsrqda

xddech:	jmp	ddecho

xdsint:	jmp	dsint


; data byte received for rdrc command
drdrc:	mov	r0,#020h
	mov	a,#020h
	orl	a,@r0
	mov	@r0,a
	jmp	X005c


; get contents of a ROM page 3 location, for checksum computation
getrp3:	movp	a,@a
	ret

	fillto	0400h,000h

	end
