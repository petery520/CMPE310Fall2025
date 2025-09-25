section .data
      var1 db 'a',0x0A
      len1 equ $- var1
      var2 db 'b',0x0A
      len2 equ $- var2
section .text

      main:
            ans db
            mov al, var1
            mov dl, var2
            