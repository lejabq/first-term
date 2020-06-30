                section         .text

                global          _start
                %define         LENGTH_NUM 128
_start:

                sub             rsp, 6 * LENGTH_NUM * 8
                mov             rdi, rsp
                mov             rcx, LENGTH_NUM
                call            read_long

                lea             rdi, [rsp + LENGTH_NUM * 8]
                call            read_long

                mov             rsi, rsp                  ; first number
                mov             r9, rdi                   ; second number

                lea             r10, [rsp + 2 * LENGTH_NUM * 8]  ; reserved number
                lea             rdi, [rsp + 4 * LENGTH_NUM * 8]  ; result number

                call            mul_long_long

                lea             rcx, [rcx * 2]
                call            write_long

                mov             al, 0x0a
                call            write_char

                jmp             exit

; muls two long number
;    rsi -- address of multiplier #1 (long number)
;    r9 -- address of multiplier #2 (long number)
;    r10 -- reserved space for number
;    rcx -- length of long numbers in qwords
; result:
;    mul is written to rdi, length of result = 2 * rcx
mul_long_long:
                push            rsi
                push            r8
                push            r9
                push            r10
                push            rdi
                push            rcx
                push            rbx
                mov             r11, rcx        ; loop counter
                mov             r8, rdi         ; current block pointer in result
                mov             r12, rsi        ; current block pointer in source
                clc
.loop: 
                mov             rdi, r10
                inc             rcx
                call            set_zero
                dec             rcx

                call            copy_number     ; copy r9 -> r10
                mov             rdi, r10
                mov             rbx, [r12]

                inc             rcx
                call            mul_long_short  ; [rdi] *= rbx <=> [r10] *= [r12]
                mov             rsi, r10
                mov             rdi, r8
                call            add_long_long   ; [rdi] += [rsi] <=> [r8] += [r10]
                dec             rcx
                lea             r8, [r8 + 8]
                lea             r12, [r12 + 8]
                dec             r11
                jnz             .loop

                pop            rbx
                pop            rcx
                pop            rdi
                pop            r10
                pop            r9
                pop            r8
                pop            rsi
                ret

; copy one long number to other
;    r9 -- src address
;    r10 -- dst address
;    rcx -- length of long numbers in qwords
; result:
;    number with address r9 is written to r10, length of result = rcx
copy_number:
                push            r9
                push            r10
                push            rax
                push            rcx

                clc
.loop:
                mov             rax, [r9]
                mov             [r10], rax
                add             r10, 8
                add             r9, 8
                dec             rcx
                jnz             .loop

                pop             rcx
                pop            rax
                pop             r10
                pop             r9
                ret

; adds two long number
;    rdi -- address of summand #1 (long number)
;    rsi -- address of summand #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    sum is written to rdi
add_long_long:
                push            rdi
                push            rsi
                push            rcx

                clc
.loop:
                mov             rax, [rsi]
                lea             rsi, [rsi + 8]
                adc             [rdi], rax
                lea             rdi, [rdi + 8]
                dec             rcx
                jnz             .loop

                pop             rcx
                pop             rsi
                pop             rdi
                ret


; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short:
                push            rdi
                push            rcx
                push            rdx

                xor             rdx,rdx
.loop:
                add             [rdi], rax
                adc             rdx, 0
                mov             rax, rdx
                xor             rdx, rdx
                add             rdi, 8
                dec             rcx
                jnz             .loop

                pop             rdx
                pop             rcx
                pop             rdi
                ret


; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
mul_long_short:
                push            rax
                push            rdi
                push            rcx
                push            rsi
                xor             rsi, rsi
.loop:
                mov             rax, [rdi]
                mul             rbx
                add             rax, rsi
                adc             rdx, 0
                mov             [rdi], rax
                add             rdi, 8
                mov             rsi, rdx
                dec             rcx
                jnz             .loop

                pop             rsi
                pop             rcx
                pop             rdi
                pop             rax
                ret

; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short:
                push            rdi
                push            rax
                push            rcx

                lea             rdi, [rdi + 8 * rcx - 8]
                xor             rdx, rdx

.loop:
                mov             rax, [rdi]
                div             rbx
                mov             [rdi], rax
                sub             rdi, 8
                dec             rcx
                jnz             .loop

                pop             rcx
                pop             rax
                pop             rdi
                ret

; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero:
                push            rax
                push            rdi
                push            rcx

                xor             rax, rax
                rep stosq

                pop             rcx
                pop             rdi
                pop             rax
                ret

; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero:
                push            rax
                push            rdi
                push            rcx

                xor             rax, rax
                rep scasq

                pop             rcx
                pop             rdi
                pop             rax
                ret

; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long:
                push            rcx
                push            rdi

                call            set_zero
.loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              .done
                cmp             rax, '0'
                jb              .invalid_char
                cmp             rax, '9'
                ja              .invalid_char

                sub             rax, '0'
                mov             rbx, 10
                call            mul_long_short
                call            add_long_short
                jmp             .loop

.done:
                pop             rdi
                pop             rcx
                ret

.invalid_char:
                mov             rsi, invalid_char_msg
                mov             rdx, invalid_char_msg_size
                call            print_string
                call            write_char
                mov             al, 0x0a
                call            write_char

.skip_loop:
                call            read_char
                or              rax, rax
                js              exit
                cmp             rax, 0x0a
                je              exit
                jmp             .skip_loop

; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long:
                push            rax
                push            rcx

                mov             rax, 20
                mul             rcx
                mov             rbp, rsp
                sub             rsp, rax

                mov             rsi, rbp

.loop:
                mov             rbx, 10
                call            div_long_short
                add             rdx, '0'
                dec             rsi
                mov             [rsi], dl
                call            is_zero
                jnz             .loop

                mov             rdx, rbp
                sub             rdx, rsi
                call            print_string

                mov             rsp, rbp
                pop             rcx
                pop             rax
                ret

; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char:
                push            rcx
                push            rdi

                sub             rsp, 1
                xor             rax, rax
                xor             rdi, rdi
                mov             rsi, rsp
                mov             rdx, 1
                syscall

                cmp             rax, 1
                jne             .error
                xor             rax, rax
                mov             al, [rsp]
                add             rsp, 1

                pop             rdi
                pop             rcx
                ret
.error:
                mov             rax, -1
                add             rsp, 1
                pop             rdi
                pop             rcx
                ret

; write one char to stdout, errors are ignored
;    al -- char
write_char:
                sub             rsp, 1
                mov             [rsp], al

                mov             rax, 1
                mov             rdi, 1
                mov             rsi, rsp
                mov             rdx, 1
                syscall
                add             rsp, 1
                ret

exit:
                mov             rax, 60
                xor             rdi, rdi
                syscall

; print string to stdout
;    rsi -- string
;    rdx -- size
print_string:
                push            rax

                mov             rax, 1
                mov             rdi, 1
                syscall

                pop             rax
                ret


                section         .rodata
invalid_char_msg:
                db              "Invalid character: "
invalid_char_msg_size: equ             $ - invalid_char_msg