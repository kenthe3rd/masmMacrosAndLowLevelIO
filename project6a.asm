TITLE Macros and Low-Level I/O Procedures     (project6a.asm)

; Author: Ken Hall
; Course / Project ID: CS 271 400                 Date: 3/18/2018
;
; Description:
;1) User’s numeric input is validated the hard way: Input is read as a string, and converted
;to numeric form. If the user enters non-digits or the number is too large for 32-bit registers, an
;error message should be displayed and the number should be discarded.
;2) Conversion routines use the lodsb and/or stosb operators.
;3) All procedure parameters are passed on the system stack.
;4) Addresses of prompts, identifying strings, and other memory locations are passed by address to
;the macros.
;5) Used registers are saved and restored by the called procedures and macros.
;6) The stack is “cleaned up” by the called procedure

INCLUDE Irvine32.inc



;;;MACROS;;;



getString MACRO string
	
	push					ecx
	push					edx
	mov						ecx, 100								;limits max size of input
	lea						edx, string
	call					ReadString
	pop						edx
	pop						ecx

ENDM


displayString MACRO string
	push					edx
	lea						edx, string
	call					WriteString
	call					CrLf
	pop						edx
ENDM


	BASE_TEN_MULTIPLIER = 10



.data



	buffer					BYTE	100		DUP(0)
	bufferQWORD				DWORD	20		DUP(0)
	sizeErrorMessage		BYTE	"Entry is too large to be processed." ,0
	badValErrorMessage		BYTE	"Your entry contained one or more invalid characters.",0
	intro					BYTE	"Macros and Low-Level I/O Procedures					By: Ken Hall",0
	rules1					BYTE	"Please provide 10 unsigned decimal integers that are small enough to fit inside a 32-bit register",0
	rules2					BYTE	"I will display a list of the integers you entered, as well as their sum and average.",0
	entryPrompt				BYTE	"Please enter an unsigned integer.",0
	results1				BYTE	"You entered the following numbers:",0
	results2				BYTE	"The sum of those numbers is:",0
	results3				BYTE	"The average of those numbers is:", 0

;;;MAIN PROC;;;



.code
main PROC
	pushad
	;;;Introduce the user to the program;;;
	displayString			intro
	displayString			rules1
	displayString			rules2

	;;;get input from the user;;;
	mov						ecx, 10
getAnotherVal:
	mov						eax, 10
	sub						eax, ecx
	mov						edx, TYPE bufferQWORD
	mul						edx
	mov						edi, OFFSET bufferQWORD
	add						edi, eax
	push					OFFSET buffer
	push					edi
	call					ReadVal
	loop					getAnotherVal

	;;;display the results;
	displayString			results1
	mov						ecx, 10
writeTheVal:
	mov						esi, OFFSET bufferQWORD
	mov						eax, 10
	sub						eax, ecx
	mov						ebx, TYPE bufferQWORD
	mul						ebx
	add						esi, eax
	push					OFFSET buffer
	push					esi
	call					WriteVal
	loop					writeTheVal

	;;;sum;;;
	displayString			results2
	push					10
	push					OFFSET bufferQWORD
	call					sumNums
	call					CrLf
	
	;;;average;;;
	displayString			results3
	push					10
	push					OFFSET bufferQWORD
	call					avgNums
	call					CrLf
	
	popad
	exit	
main ENDP


;;;ADD'L PROCEDURES;;;



ReadVal PROC
;-------
;DESCRIPTION: converts stored console input from string to numeric form and stores it in memory
;RECEIVES: the address from which to receive string, the address at which to store numeric value
;RETURNS: NONE
;PRECONDITIONS: NONE
;-------
	push					ebp
	mov						ebp, esp
	push					eax
	push					ebx
	push					ecx
	push					edx
	mov						ebx, 0
	mov						edx, 0
tryAgain:
	getString				[ebp + 12]
	add						ebp, 12
	mov						esi, ebp
	sub						ebp, 12
	mov						eax, 0
	mov						ebx, 0
nextByte:	
	lodsb
	cmp						eax, 0
	je						nullTermFound
	sub						eax, 48
	cmp						eax, 0
	jl						badIn
	cmp						eax, 9
	jg						badIn
	push					eax								;digit validated, push on to stack
	mov						eax, ebx						;move sum to eax
	mov						ebx, BASE_TEN_MULTIPLIER		;load 10x multiplier
	mul						ebx								;multiply
	pop						ebx								;move validated integer from stack to register
	add						eax, ebx						;add validated register to total
	mov						ebx, eax						;save sum in ebx
	mov						eax, 0
	cmp						edx, 0
	jg						sizeError
	jmp						nextByte						;get the next byte
		
sizeError:
	call					CrLf
	displayString			sizeErrorMessage
	call					CrLf
	mov						edx, 0							;reset values
	mov						ebx, 0							;reset values
	jmp						tryAgain
		
nullTermFound:
	mov						eax, [ebp + 8]
	mov						[eax], ebx
		
endProc:
	pop						edx
	pop						ecx
	pop						ebx
	pop						eax
	pop						ebp
	ret						8

badIn:
	displayString			badValErrorMessage
	jmp						tryAgain
ReadVal ENDP	



WriteVal PROC
;-------
;DESCRIPTION: converts an unsigned int to string and writes that string to console
;RECEIVES: the address of the integer and the address at which to store the string
;RETURNS: NONE
;PRECONDITIONS: NONE
;-------
	push					ebp
	mov						ebp, esp
	push					eax
	push					ebx
	push					ecx
	push					edx
	push					edi
	push					esi
	
	
	mov						ecx, 0
	mov						edi, [ebp + 12]
	mov						esi, [ebp + 8]
	std
	mov						eax, 0
	stosb
	mov						eax, [esi]
	add						edi, 50
	mov						ebx, BASE_TEN_MULTIPLIER
anotherDigit:	
	mov						edx, 0
	div						ebx
	cmp						eax, 0
	je						done
	add						edx, 48
	push					eax
	mov						eax, edx
	stosb	
	pop						eax
	jmp						anotherDigit
done:
	mov						eax, edx
	add						eax, 48
	stosb
	inc						edi
	displayString			[edi]
	pop						esi
	pop						edi
	pop						edx
	pop						ecx
	pop						ebx
	pop						eax
	pop						ebp
	ret						8
WriteVal ENDP	



sumNums PROC
;-------
;DESCRIPTION: calculates and displays the sum of an array of unsigned int
;RECEIVES: the address of the array, the number of items in the array (via the stack)
;RETURNS: NONE
;PRECONDITIONS: NONE
;-------
	push					ebp
	mov						ebp, esp
	push					eax
	push					ebx
	push					ecx
	push					esi
	mov						ecx, [ebp + 12]
	mov						esi, [ebp + 8]
	mov						ebx, 0
getNum:
	mov						eax, [esi]
	add						ebx, eax
	add						esi, 4
	loop					getNum
	mov						eax, ebx
	call					WriteDec
	pop						esi
	pop						ecx
	pop						ebx
	pop						eax
	pop						ebp
	ret						8
sumNums ENDP



avgNums PROC
;-------
;DESCRIPTION: calculates and displays the average of an array of unsigned int
;RECEIVES: the address of the array, the number of items in the array (via the stack)
;RETURNS: NONE
;PRECONDITIONS: NONE
;-------
	push					ebp
	mov						ebp, esp
	push					eax
	push					ebx
	push					ecx
	push					esi
		
	mov						ecx, [ebp + 12]
	push					ecx								;saved on top to be used as divisor
	mov						esi, [ebp + 8]
	mov						ebx, 0
getNum:	
	mov						eax, [esi]
	add						ebx, eax
	add						esi, 4
	loop					getNum
	mov						eax, ebx
	pop						ebx
	div						ebx
	call					WriteDec
	pop						esi
	pop						ecx
	pop						ebx
	pop						eax
	pop						ebp
	ret						8
avgNums ENDP

END main
