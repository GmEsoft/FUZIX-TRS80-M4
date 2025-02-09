;** Fuzix Kernel Patch for Model 4p - (c) 2020 GmEsoft, All rights reserved. **
;
;	Thu Dec 17 2020		Initial


;=====	Patch activation flags
$PSRINT	EQU	0			;Disable serial interrupts (if defective UART)


;=====	original kernel binary
	ORG	0100H

	INCBIN	trs80-0.5.sys.bin	;original kernel binary

;=====	patches

;-----	disable serial int (defective UART)
	IF	$PSRINT
	ORG	0161H
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)

	ORG	01B5H
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)
	ENDIF


	END
