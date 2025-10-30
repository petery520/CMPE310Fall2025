;compilation commands
;   nasm -f elf file.asm
;   ld -m elf_i386 file.o -o file

;section .data
      ;fileInput db 'test.txt'

section .bss
      fileInput resb 255 ; file
      fileDesc resb 1 ; file descriptor
      buffer resb 6006 ; buffer will contain data from the text file
      total resb 4 ; integer total, 4 bytes because it is an integer itself
      ans resb 8; output variable

section .text
      global _start

_start:

      ; take user input file
      mov eax, 3 ; sys_read
      mov ebx, 0 ; stdin
      mov ecx, fileInput ; file
      mov edx, 256
      int 0x80

      ; parse through fileInput and turn the newline character into null
      ; to prepare to read the file
      xor ecx,ecx
      dec ecx ; set ecx to -1 (loop begins by incrementing)
      RemoveNewline:
            inc ecx
            mov bl, [fileInput + ecx]
            cmp bl, 10 ; 10 is newline
            jne RemoveNewline
      mov bl, 0
      mov [fileInput + ecx], bl ; delete newline from the input

      ; open .txt file
      mov eax, 5 ; sys_open
      mov ebx, fileInput ; text file
      mov ecx, 0 ; read-only mode
      mov edx, 0777 ; read, write and execute by all
      int 0x80

      mov [fileDesc], eax

      ; read from file and put into buffer
      mov eax, 3 ; sys_read
      mov ebx, [fileDesc] ; file descriptor
      mov ecx, buffer ; input buffer
      mov edx, 6006 ; number of bytes to read
                    ; 6006 because the file will at most be 1001 lines with 1000\n or 5 bytes per line
                    ; using 6 bytes per line to be safe (accounting for invisible characters like carriage returns)
      int 0x80

      ; close .txt file
      mov eax, 6 ; sys_close
      mov ebx, [fileDesc] ; file descriptor
      int 0x80

      ; now operating on buffer which has the entire file in it
      ; read set of integers from file into a memory array

      ; first number in file is number of numbers in file
      ; originally I looped through the file based on this number but that was causing issues
      ;     so I am skipping this line instead and just looping until NULL at the end of the file
      xor ecx,ecx ; index
      xor ebx,ebx
      xor eax,eax
      FirstLine:
            mov bl, [buffer + ecx]
            cmp bl, 10 ; 10 is newline
            je FirstEscape
            cmp bl, 0x0 ; 0x0 is end of file
            je FirstEscape
            cmp bl, 13 ; 13 is a carriage return 
            je FirstEscape

            inc ecx
            jmp FirstLine
      FirstEscape:
      inc ecx

      ; add integers up
      ; loop over characters in buffer until newline is reached, convert to integer, add to running total
      xor eax,eax ; using eax to track the current integer to add
      xor ebx,ebx ; using ebx to hold the current character
      mov [total], eax ; setting total to zero

      AddLoop:
            mov bl, [buffer + ecx]
            cmp bl, 13 ; 13 is a carriage return (skipping these)
            je NotNewLine
            cmp bl, 10 ; 10 is newline
            je NewLine
            cmp bl, 0x0 ; 0x0 is end-of-file
            je NewLine
            
            imul eax, 10 ; to convert from ascii to integer we need to multiply ascii characters by 10
            sub bl, '0'
            add eax, ebx
            jmp NotNewLine

            NewLine:
                  add [total], eax
                  cmp bl, 0
                  je AddEscape
                  xor eax,eax ; clear eax

            NotNewLine:

            inc ecx
            ;mov edx, [total] ; for debugging's sake
            jmp AddLoop
      AddEscape:

      ;; create a readable message
      mov eax, [total] ; div operation uses eax
      mov ebx, 10 ; dividing by ten to pick out digits
      xor ecx,ecx ; clean ecx
      mov ecx, 8 ; loop 8x bc largest total is 8 digits to be safe (should never be that much)
      xor edx,edx ; div operation uses edx

      PrintLoop:
            dec ecx
            div ebx ; eax = eax / ebx, edx = eax % ebx

            cmp edx, 0x0 ; if there is no number left then escape	
            jne Number
            cmp eax, 0x0
            jne Number
            jmp EscapePrint

            Number:
            add edx, '0' ; convert to readable number character
            mov [ans + ecx], dl ; add current least significant digit to ans
            xor edx,edx ; clear least significant digit

            cmp ecx, 0
            jne PrintLoop
      EscapePrint:

      ; print out answer
      mov eax, 4 ;system call number (sys_write)
      mov ebx, 1 ;file descriptor (stdout)
      mov ecx, ans ;message to write
      mov edx, 8 ;message length
      int 0x80 ;call kernel

      mov eax, 1 ; sys_exit
      mov ebx,0
      int 0x80