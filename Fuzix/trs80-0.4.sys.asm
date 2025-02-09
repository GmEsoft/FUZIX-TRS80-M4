;** Fuzix Kernel Patch for Model 4p - (c) 2020 GmEsoft, All rights reserved. **
;
;	Fixes 1 bug:
;	- missing wait ready loop after OTIR in hard disk I/O routine
;
;	Thu Dec 17 2020		Initial


;=====	Patch activation flags
$PSRINT	EQU	1			;Disable serial interrupts (if defective UART)
$PWOTIR	EQU	1			;Fix missing wait ready loop after OTIR (MANDATORY on real machines)


;=====	original kernel binary
	ORG	0100H

	INCBIN	trs80-0.4.sys.bin	;original kernel binary

;=====	patches

;-----	disable serial int (defective UART)
	IF	$PSRINT
	ORG	0161H
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)

	ORG	01AAH
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)
	ENDIF

;-----	Add wait ready after OTIR
	IF	$PWOTIR			;

ZOFFSET	EQU	0E600H-0ACE5H		;(=391B) phased block offset 

	ORG	0E97DH-ZOFFSET		;(=B062)
	CALL	ENDOTIR+ZOFFSET		;intercept map_kernel call after OTIR

	IF	0
	
	ORG	0EBA6H-ZOFFSET		;(=B293) reorder PUSH statements in interrupt handler
	EXX				;common with previous routine
	PUSH	BC
	PUSH	DE
	PUSH	HL
	EXX
	PUSH	BC
	PUSH	IX
	PUSH	IY
	PUSH	AF			;specific to this routine
	PUSH	DE
	PUSH	HL
	EX	AF,AF'
	PUSH	AF	
	EX	AF,AF'

	ORG	0EBFBH-ZOFFSET		;(=B2E0) reorder POP statements and use dup code
	EX	AF,AF'
	POP	AF
	EX	AF,AF'
	POP	HL
	POP	DE
	POP	AF
	JP	0EB36H			;(=B21B) then jump to common POP code
	
	ELSE
	
	ORG	0EB8AH-ZOFFSET		;(=B26F)
	DB	'?',0			;replace '[illegal]',0DH,0AH,0

	ENDIF

ENDOTIR	EX	(SP),HL			;additional wait ready loop after OTIR
	EX	(SP),HL
	IN	A,(0CFH)		;read HDD controller status
	RLCA
	JR	C,ENDOTIR		;loop while busy
	JP	0EA0FH			;(=B0F4) reset memory map (map_kernel)

	ENDIF

	END
