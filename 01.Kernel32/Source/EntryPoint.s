[ORG 0x00]
[BITS 16]

SECTION .text

START:
	mov ax, 0x1000
	mov ds, ax
	mov es, ax

	mov ax, 0x2401	; activate A20 GATE
	int 0x15		; bios interrupt ( control A20 )
	jc .A20GATEERROR
	jmp .A20GATESUCCESS

.A20GATEERROR:
	in al, 0x92
	or al, 0x02
	and al, 0xFE
	out 0x92, al

.A20GATESUCCESS:

	cli

	lgdt [ GDTR ]
	mov eax, 0x4000003B
	mov cr0, eax

	jmp dword 0x18: (PROTECTEDMODE - $$ + 0x10000)


[BITS 32]

PROTECTEDMODE:
	mov ax, 0x20
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ss, ax
	mov esp, 0xFFFC
	mov ebp, 0xFFFC

	push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )
	push 2
	push 0
	call PRINTMESSAGE ; PRINTMESSAGE(int x, int y, char *msg);
	add esp, 12
	jmp dword 0x18: 0x10200

;
;	arg1 [ebp+0x8] : x
;	arg2 [ebp+0xc] : y
;	arg3 [ebp+0x10]: msg
;
;	while(msg[i]) 0xb8000+i = msg[i];
;
PRINTMESSAGE:	
	push ebp
	mov ebp, esp
	push edi
	push esi
	push ecx
	push edx
	push ebx

	mov edi, 0xb8000
	mov esi, dword [ebp+0x10]
	mov ecx, 0 					; count
	xor edx, edx

	mov eax, dword [ebp+0xc]	; eax = y
	mov ebx, 160
	mul ebx
	add edi, eax				; idx += (y*80*2) 80 : width, 2 : sizeof(char_display)

	mov eax, dword [ebp+0x8]	; eax = x
	mov ebx, 2
	mul ebx
	add edi, eax	 			; idx += (x*2) 2 : sizeof(char_display)

	xor eax, eax
	printloop:
		mov al, byte [ esi ]
		mov byte [ edi ], al
		test al, al
		je end
		add esi, 1
		add edi, 2
		jmp printloop
	end:
	mov eax, ecx

	pop ebx
	pop edx
	pop ecx
	pop esi
	pop edi
	leave
	ret



align 8, db 0

dw 0x0000
GDTR:
	dw GDTEND - GDT - 1
	dd ( GDT - $$ + 0x10000 )

GDT:
	NULLDescriptor:
		dd 0x00000000
		dd 0x00000000

	IA_32eCODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xAF
		db 0x00

	IDA_32eDATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xCF
		db 0x00

	CODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xCF
		db 0x00

	DATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xCF
		db 0x00

GDTEND:

SWITCHSUCCESSMESSAGE: db "Switched to Protected mode", 0

times 512 - ($ - $$) db 0x00

