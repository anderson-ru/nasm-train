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
  	; "Enter a number x: "
  	mov eax, 4
  	mov ebx, 1
  	mov ecx, msg1
  	mov edx, len1
  	int 0x80

  	; reading x 
  	mov eax, 3
  	mov ebx, 0
  	mov ecx, x
  	mov edx, 10
  	int 0x80

  	; convert str -> int
  	lea ebx, [x]
  	call str_to_int
  	mov [x], eax

    ;compare х and 5
    ;><=
  	cmp eax, 5
    jg .more
    jl .less
    je .eq

    ; if x > 5 then
    .more:
    mov eax, 3
    mov ebx, [x]
    add eax, ebx
    
    
    mov ecx, eax
  	mov [y], ecx
    jmp .exit
    
    ; x < 5
    .less:
    mov eax, 2
    mov ebx, [x]
    mul ebx
    mov ebx, 9
    sub ebx, eax
    mov eax, ebx
    
    mov ecx, eax
    mov [y], ecx
    jmp .exit

    ; x equals = 5  
    .eq:
    mov eax, [x]
    mov ebx, 3
    mul ebx

    mov ecx, eax
  	mov [y], ecx
  	jmp .exit

  	; output "y = " and y
  	.exit: 
  	mov eax, 4
  	mov ebx, 1
  	mov ecx, msg2
  	mov edx, len2
  	int 0x80

  	; convert int to str -> y
  	mov eax, [y]
  	mov [y], byte 0
  	lea esi, [y]
  	call int_to_str

  	mov eax, 4
  	mov ebx, 1
  	mov ecx, y
  	mov edx, 10
  	int 0x80

  	
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