section .bss
  input1 resb 255 ; first user variable
  input2 resb 255 ; second user variable
  ans resb 4 ; output variable

section .text
	global _start

_start:

  mov eax, 3 ; sys_read
  mov ebx, 0 ; stdin
  mov ecx, input1 ; user input 1
  mov edx, 256
  int 0x80
  
  mov eax, 3 ; sys_read
  mov ebx, 0 ; stdin
  mov ecx, input2 ; user input 2
  mov edx, 256
  int 0x80
  
  ;; loop until newline and compute hamming distance
  ;; count number of ones in ans and store in output
  xor ecx,ecx ; index
  xor ebx,ebx ; using ebx to temporarily store the hamming distance
  
  HamLoop:
    cmp byte [input1 + ecx], 10 ; 10 is newline
    je EscapeHam
    cmp byte [input2 + ecx], 10
    je EscapeHam
  
    mov al, [input1 + ecx] ; character index of input1
    xor al, [input2 + ecx] ; compare to the same character index of input2
    xor ah,ah ; clean garbage
    popcnt ax,ax ; count hamming distance for the two characters
    add bx,ax ; add to bx
  
    inc ecx
    jmp HamLoop
  EscapeHam:
  
  ;; create a readable message
  mov eax, ebx ; div operation uses eax
  mov bl, 10 ; dividing by ten to pick out digits
  xor ecx,ecx ; clean ecx
  mov ecx, 4 ; loop 4x bc largest hamming distance is 255 bytes * 8 bits = 2040 which is 4 digits
  
  PrintLoop:
    dec ecx
    div bl ; al = ax / bl, ah = ax % bl

    cmp ax, 0x0 ; if there is no number left then escape	
    je EscapePrint

    add ah, '0' ; convert to readable number character
    mov [ans + ecx], ah ; add current least significant digit to ans
    xor ah,ah ; clear least significant digit

    cmp ecx, 0
    jne PrintLoop
  EscapePrint:
  
  mov eax, 4 ;system call number (sys_write)
  mov ebx, 1 ;file descriptor (stdout)
  mov ecx, ans ;message to write
  mov edx, 4 ;message length
  int 0x80 ;call kernel
  
  mov eax, 1 ;system call number (sys_exit)
  mov ebx,0
  int 0x80