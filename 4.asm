section .data
  prompt:               db "Please enter your name: ", 0
  msg:                  db "User ", 0
  allowed:              db " is allowed to perform actions in the system", 10, 0
  filename:             db "file.txt", 0
  days_per_month:       dq 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ; количество дней в месяцах


section .bss
  termios_original: resb 24 ;
  termios_raw:      resb 24 ; 
  char_buffer:      resb 1  ; 
  buf:              resb 64 ; 

section .text
  global _start

_start:
  ; Вывод prompt "please enter your name"
  mov rax, 1            ; запись
  mov rdi, 1            ; stdout
  lea rsi, [prompt]     ; строка с текстом
  mov rdx, 24           ; количество символов которые нужно вывести
  syscall               ;

  ; Чтение ввода пользователя
  mov rax, 0            ; чтение
  mov rdi, 0            ; stdin
  lea rsi, [buf]        ; адресс буфера 
  mov rdx, 64           ; размер буфера
  syscall               ;
  mov r8, rax           ;r8 = количество байтов чтение
  dec r8                ;удаление последнего символа

  ; Вывод msg
  mov rax, 1            ;запись
  mov rdi, 1            ;stdout
  lea rsi, [msg]        ;адрес строки для вывода
  mov rdx, 5            ;количество символов которые нужно вывести
  syscall               ;

  ; Вывод
  mov rax, 1            ;запись
  mov rdi, 1            ;stdout
  lea rsi, [buf]        ;адрес буфера
  mov rdx, r8           ;количество символов которые нужно вывести из буфера 
  syscall               ;

  ; Вывод
  mov rax, 1            ;запись
  mov rdi, 1            ;stdout
  lea rsi, [allowed]    ;адрес строки
  mov rdx, 45           ;количество символов которые нужно вывести
  syscall               ;

  ; Получение настоящего времени
  mov rax, 201          ;системный вызов для sys_time
  lea rdi, [buf]        ;время в буфер
  syscall               ;

  ; Конвертация timestamp
  mov rdi, rax              ; rdi = timestamp
  call breakdown_timestamp  ; r10 = year, r11 = month, r12 = day, r13 = hour, r14 = minute, r15 = second

  push r11                  ; сохранение r11
  mov rax, 2                ; открытие файла
  lea rdi, [filename]       ; имя открываемого файла
  mov rsi, 0102             ; O_RDWR | O_CREAT
  mov rdx, 0666o            ; права файла, -rw-rw-rw-
  syscall
  pop r11                   ; restore r11

  mov rsi, rax              ; сохранение id открываемого файла
  mov rdi, r12              ; день
  call print_number         ; вывод дня
  mov rdi, '.'
  call putchar
  mov rdi, r11
  call print_number         ; вывод месяца
  mov rdi, '.'
  call putchar
  mov rdi, r10
  call print_number         ; вывод года

  mov rdi, ' '
  call putchar

  mov rdi, r13
  call print_number         ; вывод часа
  mov rdi, ':'
  call putchar
  mov rdi, r14
  call print_number         ; вывод минуты
  mov rdi, ':'
  call putchar
  mov rdi, r15
  call print_number         ; вывод second

  ; Close file
  push r11                  ; сохранение r11
  mov rax, 3                ; sys close
  mov rdi, rsi              ;id открываемого файла
  syscall
  pop r11                   ; restore r11

  ; print on stdout
  mov rax, 1
  mov rdi, r12              ; день
  call print_number         ; вывод дня
  mov rdi, '.'
  call putchar
  mov rdi, r11
  call print_number         ; вывод месяца
  mov rdi, '.'
  call putchar
  mov rdi, r10
  call print_number         ; вывод года

  mov rdi, ' '
  call putchar

  mov rdi, r13
  call print_number         ; вывод часа
  mov rdi, ':'
  call putchar
  mov rdi, r14
  call print_number         ; вывод минуты
  mov rdi, ':'
  call putchar
  mov rdi, r15
  call print_number         ; вывод second


; Отключение канонического режима (без буферизации)
  ; Сохранение настроек терминала
  mov rax, 16               ; sys_ioctl
  mov rdi, 0                ; stdin
  mov rsi, 0x5401           ; TCGETS
  lea rdx, [termios_original]
  syscall

  ; Копирование настроек в termios_raw и их изменение режима raw
  lea rsi, [termios_original]
  lea rdi, [termios_raw]
  mov rcx, 24
  cld                               ; Очистка флага направление
  rep movsb
  ; отключение ECHO, ICANON и других флагов
  and word [termios_raw+12], 0xFFA0 ; termios_raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG)
  ; Установка минимального количества байтов для чтения и тайм-аута на 0
  mov byte [termios_raw+6], 0       ; termios_raw.c_cc[VMIN] = 0
  mov byte [termios_raw+7], 0       ; termios_raw.c_cc[VTIME] = 0

  ; Установка терминала в raw режиме
  mov rax, 16               ; sys_ioctl
  mov rdi, 0                ; stdin
  mov rsi, 0x5402           ; TCSETS
  lea rdx, [termios_raw]
  syscall

; До тех пор пока клавижа ESC не будет нажата
wait_for_esc:
  ; ожидание нажатия клавиши
  mov rax, 0                ; чтение
  mov rdi, 0                ; stdin
  lea rsi, [buf]            ; запись в буфер
  mov rdx, 1                ; чтение 1 символа
  syscall

  cmp byte [buf], 0x1B      ; ожидание ESC
  jne wait_for_esc

  ; Восстановление настроек терминала
  mov rax, 16               ; sys_ioctl
  mov rdi, 0                ; stdin
  mov rsi, 0x5401           ; TCGETS
  lea rdx, [termios_original]
  syscall

  ; выход из программы
  mov rax, 60
  xor rdi, rdi
  syscall

breakdown_timestamp:
  ; Конвертация Unix timestamp из rdi to year, month, day, hour, minute, second
  ; Результат в r10 (year), r11 (month), r12 (day), r13 (hour), r14 (minute), r15 (second)

  ; Вычисление числа дней и секунд
  mov rax, rdi              ; rax = количество секунд с 1970
  mov rbx, 24*60*60         ; rbx = число секунд в одном дне
  xor rdx, rdx              ; reset rdx
  div rbx                   ; количество секунд с 1970 года/количество секунд в сутках (rax = daysTillNow, rdx = extraTime)
  mov r9, rax               ; количество дней
  mov r15, rdx              ; секунды
  mov r10, 1970             ; год

  ; Вычислите currYear, вычитая 365 или 366 дней из daysTillNow
  .year_loop:
    ; Проверка высокосного года
    ; (currYear % 400 == 0)
    mov rax, r10            ;от 1970 с увеличением на цикле
    mov r12, 400            ;400 -> r12
    xor rdx, rdx            ;reset rdx
    div r12                 ;разделение 1970 на 400 чтоб узнать высокосный ли год
    cmp rdx, 0              ;проверка равенству остатка 0
    je .leap_year           ;если год высокосный -> jump to leap_year func

    ; (currYear % 4 == 0)
    mov rax, r10            ; проверка года
    mov r12, 4              ;добавление значения 4
    xor rdx, rdx            ;reset rdx
    div r12                 ;деление года на 4
    cmp rdx, 0              ;проверка остатка равенству 0
    jne .not_leap_year      ;иначе -> jump to not_leap_year
    ;  && currYear % 100 != 0)
    mov rax, r10            ;проверка года
    mov r12, 100            ;значение 100
    xor rdx, rdx            ; reset rdx
    div r12                 ;деление года на 100
    cmp rdx, 0              ;проверка остатка равенству 0
    je .not_leap_year       ;иначе -> jump to not_leap_year
    ; Если год высокосный
    .leap_year:
      mov r13, 1            ;флаг говорит о том высокосный ли год
      cmp r9, 366           ; проверка до тех пор пока daysTillNow < 366
      jb .exit_loop
      sub r9, 366           ; вычисление 366 из daysTillNow
      jmp .increment_currYear

    ; иначе
    .not_leap_year:
      mov r13, 0            ;флаг сохраняет если год не высокосный
      cmp r9, 365           ;проверка до тех пор пока daysTillNow < 365
      jb .exit_loop
      sub r9, 365           ;вычисление 365 из daysTillNow

    .increment_currYear:
      add r10, 1            ;Increment currYear
      jmp .year_loop

  .exit_loop:
  ; currYear -> in r10

  mov r8, r9                ; extraDays = daysTillNow
  add r8, 1                 ; + 1

  ; Initialize month to 0
  xor r11, r11

  .month_loop:
    cmp r11, 1              ; проверка месяца != 1
    jne .not_feb
    cmp r13, 1              ; проверка flag == 1
    je .feb_leap

    .not_feb:
      ; проверка extraDays - days_per_month[index] < 0
      mov rax, [days_per_month + r11 * 8]
      cmp r8, rax
      jl .calculate_date

      add r11, 1            ; month += 1
      sub r8, rax           ; extraDays -= days_per_month[index]
      jmp .month_loop

    .feb_leap:
      cmp r8, 29            ; проверка extraDays - 29 < 0
      jl .calculate_date

      add r11, 1            ; month += 1
      sub r8, 29            ; extraDays -= 29
      jmp .month_loop

.calculate_date:
  cmp r8, 0                 ; проверка extraDays > 0
  jle .handle_zero_extraDays
  add r11, 1                ; month += 1
  mov r12, r8               ; date = extraDays
  jmp .end

;обработка последнего дня месяца
.handle_zero_extraDays:
  ; проверка если month == 2 и flag == 1
  cmp r11, 2
  jne .handle_not_feb
  cmp r13, 1
  jne .handle_not_feb

  mov r12, 29               ; в высокосном году 29 дней в феврале
  jmp .end
; копирование дней из days_per_month
.handle_not_feb:
  mov r12, [days_per_month + (r11 - 1) * 8] ; date = days_per_month[month - 1]

.end:
  ; Настоящий месяц и дата -> r11 r12

; вычисление часа, минуты, секунды
  mov rax, r15              ; rax = extraTime
  mov rbx, 3600             ; rbx = число секунд в часе
  xor rdx, rdx
  div rbx                   ; rax = hours, rdx = remaining seconds
  mov r13, rax              ; часы -> r13

  mov rax, rdx              ; оставшиеся секудны -> rax
  mov rbx, 60               ; rbx = число минут в часе
  xor rdx, rdx              ; reset rdx
  div rbx                   ; rax = minutes, rdx = оставшиеся секунды
  mov r14, rax              ; минуты -> r14
  mov r15, rdx              ; секунды -> r15

  ; выход
  ret

; функция для вывода number
print_number:
  ; сохранение регистров
  push rbp
  mov rbp, rsp
  push rbx
  push rcx
  push rdx
  push rsi
  push r11
  push rax

  ; конвертация числа в строку
  lea rsi, [buf + 19]       ; RSI указывает на конец буфера
  mov rax, rdi              ; RAX содержит номер для вывода
  mov rbx, 10               ; RBX содержит делитель (base 10)

.convert_loop:
  xor rdx, rdx              ; очистка RDX для деления
  div rbx                   ; RAX /= 10, RDX = RAX % 10
  add rdx, '0'              ; преобразование остатка в ASCII
  dec rsi                   ; перемещение указатель буфера назад на один байт
  mov [rsi], dl             ; запись ASCII символов буффера
  test rax, rax             ; проверка равенства нулю
  jnz .convert_loop         ; если не равно нулю, то продолжить конвертацию

  ; вывод строки
  pop rax                   ; восстановление файлового дескриптора
  mov rdi, rax              ; файловый дескриптор : rax
  push rax                  ; сохранение файлового дескриптора
  mov rax, 1                ; Syscall: sys_write
  mov rdx, 19               ; длина 20 байтов
  sub rdx, rsi              ; Регулировка длины, чтобы был вывод только соответствующих символов
  add rdx, buf
  syscall

  ; восстановление регистров
  pop rax
  pop r11
  pop rsi
  pop rdx
  pop rcx
  pop rbx
  mov rsp, rbp
  pop rbp
  ret

; запись одного символа без использования буфера
; void putchar(char c)
putchar:
  ; сохранение регистров для избежания неиожиданного поведения
  push rdi
  push rdx
  push rcx
  push rsi
  push r11

  mov [char_buffer], dil    ; сохранение символа в буфере

  ; вывод символа в stdout
  mov rdi, rax              ; дескриптор файла -> rax
  push rax
  mov rax, 1                ; системный вызов для записи
  mov rsi, char_buffer      ; указатель на символ, который нужно вывести
  mov rdx, 1                ; длина символа, который нужно вывести
  syscall                   ; вызов системного вызова

  ; восстановление регистров
  pop rax
  pop r11
  pop rsi
  pop rcx
  pop rdx
  pop rdi
  ret