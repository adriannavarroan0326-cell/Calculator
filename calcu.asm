.model small
.stack 100h
.data
        ; --- Strings ---
        menu    db  0dh, 0ah, '=========CALCULATOR==========', 0dh, 0ah
                db  '1. Addition', 0dh, 0ah
                db  '2. Subtraction', 0dh, 0ah
                db  '3. Multiplication', 0dh, 0ah
                db  '4. Divison', 0dh, 0ah, '$'
        prompt  db  'Select operation (1-4): $'
        msg_n1  db  0dh, 0ah, 'Enter first number: $'
        msg_n2  db  0dh, 0ah, 'Enter second number: $'
        msg_res db  0dh, 0ah, 'Result: $'
        msg_rem db  ' Remainder $'
        wi_msg  db  0dh, 0ah, 'Invalid input!$'
        dz_msg  db  0dh, 0ah, 'Error: Divide by zero!$'
        msg_agn db  0dh, 0ah, 0dh, 0ah, 'Use again? (Y/N): $'
        
        ; --- Variables ---
        buff    db  20,0,20 dup(0)
        num1    dw  0    
        num2    dw  0
        err_flag db  0   ;

.code
main    proc
        mov ax,@data
        mov ds,ax
        mov es,ax

get_prompt:
        ; Show menu
        mov ah,9
        mov dx,offset menu
        int 21h

        ; Prompt user for menu choice
        mov ah,9
        mov dx,offset prompt
        int 21h

        ; Get menu choice (single char)
        mov ah,0ah
        mov dx,offset buff
        int 21h

        mov si,offset buff
        inc si
        lodsb
        
        cmp al,1
        je check_val
        jmp wrong_input

check_val:
        lodsb   
        cmp al,'1'
        jl do_wrong
        cmp al,'4'
        jg do_wrong
        jmp get_numbers

do_wrong:
        jmp wrong_input

get_numbers:
        mov bl, al 

get_num1:
        mov ah,9
        mov dx,offset msg_n1
        int 21h
        call READ_NUM      
        jc err_n1       
        mov num1, ax       
        jmp get_num2

err_n1:
        mov ah,9
        mov dx,offset wi_msg
        int 21h
        jmp get_num1

get_num2:
        mov ah,9
        mov dx,offset msg_n2
        int 21h
        call READ_NUM
        jc err_n2
        mov num2, ax
        jmp do_routing

err_n2:
        mov ah,9
        mov dx,offset wi_msg
        int 21h
        jmp get_num2

do_routing:
        cmp bl,'1'
        jne chk2
        jmp addi
chk2:
        cmp bl,'2'
        jne chk3
        jmp subt
chk3:
        cmp bl,'3'
        jne chk4
        jmp mult
chk4:
        cmp bl,'4'
        jne wrong_input
        jmp divi

wrong_input: 
        mov ah,9
        mov dx,offset wi_msg
        int 21h
        jmp get_prompt

; ==========================================
; MATH OPERATIONS
; ==========================================

addi:
        mov ax, num1
        add ax, num2
        
        mov cx, ax         
        mov ah, 9
        mov dx, offset msg_res
        int 21h
        mov ax, cx
        
        call PRINT_NUM     
        jmp ask_again

subt:
        mov ax, num1
        sub ax, num2
        
        mov cx, ax
        mov ah, 9
        mov dx, offset msg_res
        int 21h
        mov ax, cx
        
        call PRINT_NUM
        jmp ask_again

mult:
        mov ax, num1
        mul num2           
        
        mov cx, ax
        mov ah, 9
        mov dx, offset msg_res
        int 21h
        mov ax, cx
        
        call PRINT_NUM
        jmp ask_again

divi:
        cmp num2, 0        
        je div_zero

        xor dx, dx         
        mov ax, num1
        div num2           
        
        mov cx, ax         
        mov bx, dx         

        ; Print Quotient
        mov ah, 9
        mov dx, offset msg_res
        int 21h
        mov ax, cx
        call PRINT_NUM

        ; Print Remainder
        mov ah, 9
        mov dx, offset msg_rem
        int 21h
        mov ax, bx
        call PRINT_NUM
        jmp ask_again

div_zero:
        mov ah, 9
        mov dx, offset dz_msg
        int 21h
        jmp ask_again

; ==========================================
; RESTART PROMPT
; ==========================================
ask_again:
        mov ah, 9
        mov dx, offset msg_agn
        int 21h

        mov ah, 1
        int 21h

        cmp al, 'Y'
        je do_restart
        cmp al, 'y'
        je do_restart
        cmp al, 'N'
        je end_prog
        cmp al, 'n'
        je end_prog
        
        ; If they typed something invalid, ask again
        jmp ask_again

do_restart:
        jmp get_prompt

end_prog:
        mov ah,4ch
        int 21h
main    endp

; ==========================================
; HELPER SUBROUTINES
; ==========================================

READ_NUM PROC
        push bx
        push cx
        push dx
        xor bx, bx
        mov byte ptr [err_flag], 0

read_loop:
        mov ah, 1
        int 21h
        cmp al, 13
        je read_done

        cmp al, '0'
        jl check_letters
        cmp al, '9'
        jg check_letters

        sub al, 30h
        xor ah, ah
        mov cx, ax

        mov ax, bx
        mov dx, 10
        mul dx
        add ax, cx
        mov bx, ax
        jmp read_loop

check_letters:
        cmp al, 'A'
        jl read_loop
        cmp al, 'Z'
        jle set_error

        cmp al, 'a'
        jl read_loop
        cmp al, 'z'
        jle set_error

        jmp read_loop

set_error:
        mov byte ptr [err_flag], 1
        jmp read_loop

read_done:
        cmp byte ptr [err_flag], 1
        je num_error

        mov ax, bx
        pop dx
        pop cx
        pop bx
        clc
        ret

num_error:
        pop dx
        pop cx
        pop bx
        stc
        ret
READ_NUM ENDP


PRINT_NUM PROC
        push ax
        push bx
        push cx
        push dx
        
        or ax, ax
        jns positive
        push ax
        mov dl, '-'        
        mov ah, 2
        int 21h
        pop ax
        neg ax             

positive:
        xor cx, cx         
        mov bx, 10         

extract_loop:
        xor dx, dx
        div bx             
        push dx            
        inc cx             
        cmp ax, 0          
        jne extract_loop   

print_loop:
        pop dx             
        add dl, 30h        
        mov ah, 2
        int 21h
        loop print_loop    

        pop dx
        pop cx
        pop bx
        pop ax
        ret
PRINT_NUM ENDP

end main
