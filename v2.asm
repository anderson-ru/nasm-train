section .data
	msg1 db "Enter a number x:", 0
	len1 equ $-msg1
	msg2 db "y = ", 0
	len2 equ $-msg2
	newline db 0Ah, 0Dh

section .bss
	x resb 10
	y resb 10

section .text
	global _start

_start:
	; output a str "Enter a number x: "
	mov eax, 4
	mov ebx, 1
	mov ecx, msg1
	mov edx, len1
	int 0x80

	; reading a number
	mov eax, 3
	mov ebx, 0
	mov ecx, x
	mov edx, 10
	int 0x80

	; convert to int
	lea ebx, [x]
	call str_to_int
	mov [x], eax 

	
	mov eax, 12 ; eax = 12
	mov ebx, [x]; ebx = x
	mul ebx     ; eax = 12x
	
	
	mov ebx, 2  ; ebx = 2
	add ebx, [x]; ebx = 2 + x

	xor edx, edx 
	div ebx     ; 12x/(2+x)
	mov ecx, eax; ecx -> 12x/(2+x)

	
	; 13x + 4 / (3 - 1)
	mov eax, 13 ; eax = 13
	mov ebx, [x]; ebx = x
	mul ebx     ; eax = 13x
	add eax, 4  ; eax = 13x + 4
	
	mov ebx, 3  ; ebx = 3
	sub ebx, 1  ; ebx = 3 - 1
	
	div ebx     ; eac = 13x + 4 / ( 3 - 1)
	add ecx, eax; ecx = (13x+4)/(3-1) + 12x/(2+x)
	mov [y], ecx

	; Out "y = " and y itself
	mov eax, 4
	mov ebx, 1
	mov ecx, msg2
	mov edx, len2
	int 0x80

	; convert int to str and save it into y 
	mov eax, [y]
	mov [y], byte 0
	lea esi, [y]
	call int_to_str

	mov eax, 4
	mov ebx, 1
	mov ecx, y
	mov edx, 10
	int 0x80

	; output
	mov eax, 4
	mov ebx, 1
	mov ecx, newline
	mov edx, 2
	int 0x80 

	; end
	mov eax, 1
	mov ebx, 0
	int 0x80
	
str_to_int: 
	xor eax, eax 
	.next_char:
	movzx ecx, byte [ebx] 
	inc ebx 
	cmp ecx, '0' 
	jb .done
	cmp ecx, '9' 
	ja .done
	sub ecx, '0' 
	imul eax, 10  
	add eax, ecx 
	jmp .next_char 
.done:
	ret 
 
int_to_str:
	add esi, 9
	mov byte [esi], 0
	mov ebx, 10         
.next_digit:
	xor edx, edx         
	div ebx     
	add dl, '0'        
	dec esi      
	mov [esi], dl 
	test eax, eax        
	jnz .next_digit    
	mov eax, esi 
	ret
