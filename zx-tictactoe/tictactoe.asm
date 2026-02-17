; ============================================
; Tic Tac Toe for ZX Spectrum 48K
; Z80 Assembly - assembled with z80asm
; ============================================

; ZX Spectrum system constants
CHAN_OPEN: equ $1601
CLS_ROM:  equ $0DAF

; Game constants
EMPTY:    equ 0
PLAYER_X: equ 1
PLAYER_O: equ 2

        org $8000

start:
        call cls
        call init_game

game_loop:
        call draw_board
        call draw_status
        call wait_input
        cp 0
        jr z, game_loop

        call make_move
        cp 0
        jr z, game_loop

        call check_win
        cp 0
        jr nz, game_over_win

        call check_draw
        cp 0
        jr nz, game_over_draw

        ld a, (current_player)
        cp PLAYER_X
        jr z, switch_to_o
        ld a, PLAYER_X
        jr store_player
switch_to_o:
        ld a, PLAYER_O
store_player:
        ld (current_player), a
        jr game_loop

game_over_win:
        call draw_board
        call draw_win_message
        jr wait_restart

game_over_draw:
        call draw_board
        call draw_draw_message

wait_restart:
        call wait_any_key
        call init_game
        jr game_loop

; ============================================
; Initialize game state
; ============================================
init_game:
        ld hl, board
        ld b, 9
        xor a
init_loop:
        ld (hl), a
        inc hl
        djnz init_loop
        ld a, PLAYER_X
        ld (current_player), a
        xor a
        ld (move_count), a
        ret

; ============================================
; Clear screen
; ============================================
cls:
        ld a, 2
        call CHAN_OPEN
        call CLS_ROM
        ret

; ============================================
; Draw the board
; ============================================
draw_board:
        call cls

        ; Title
        ld a, 13
        rst $10
        ld hl, msg_title
        call print_string

        ; Row 1
        ld a, ' '
        rst $10
        ld a, (board+0)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+1)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+2)
        call print_cell
        ld a, 13
        rst $10

        ld hl, msg_sep
        call print_string

        ; Row 2
        ld a, ' '
        rst $10
        ld a, (board+3)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+4)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+5)
        call print_cell
        ld a, 13
        rst $10

        ld hl, msg_sep
        call print_string

        ; Row 3
        ld a, ' '
        rst $10
        ld a, (board+6)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+7)
        call print_cell
        ld a, '|'
        rst $10
        ld a, (board+8)
        call print_cell
        ld a, 13
        rst $10

        ld a, 13
        rst $10

        ; Key mapping
        ld hl, msg_keys
        call print_string

        ret

; ============================================
; Print a cell value (A = EMPTY/PLAYER_X/PLAYER_O)
; ============================================
print_cell:
        cp PLAYER_X
        jr z, .print_x
        cp PLAYER_O
        jr z, .print_o
        ld a, ' '
        rst $10
        ret
.print_x:
        ld a, 'X'
        rst $10
        ret
.print_o:
        ld a, 'O'
        rst $10
        ret

; ============================================
; Draw status line
; ============================================
draw_status:
        ld hl, msg_turn
        call print_string
        ld a, (current_player)
        call print_cell
        ld a, 13
        rst $10
        ret

; ============================================
; Wait for keyboard input (keys 1-9)
; Returns: A != 0 if valid, A == 0 (Z set) if invalid
; ============================================
wait_input:
        xor a
        ld ($5C08), a
.wait_loop:
        ld a, ($5C08)
        or a
        jr z, .wait_loop
        push af
        xor a
        ld ($5C08), a
        pop af

        cp '1'
        jr c, .invalid
        cp '9'+1
        jr nc, .invalid

        sub '1'
        ld (selected_pos), a
        ld a, 1
        or a
        ret

.invalid:
        xor a
        ret

; ============================================
; Make a move
; Returns: A = 1 success, 0 cell taken
; ============================================
make_move:
        ld a, (selected_pos)
        ld hl, board
        ld d, 0
        ld e, a
        add hl, de
        ld a, (hl)
        cp EMPTY
        jr nz, .taken
        ld a, (current_player)
        ld (hl), a
        ld a, (move_count)
        inc a
        ld (move_count), a
        ld a, 1
        or a
        ret
.taken:
        xor a
        ret

; ============================================
; Check for win by current_player
; Returns: A != 0 if win
; ============================================
check_win:
        ld a, (current_player)
        ld c, a

        ; Rows
        ld hl, board
        call check_row
        ret nz
        ld hl, board+3
        call check_row
        ret nz
        ld hl, board+6
        call check_row
        ret nz

        ; Columns
        ld de, 3
        ld hl, board+0
        call check_col
        ret nz
        ld hl, board+1
        call check_col
        ret nz
        ld hl, board+2
        call check_col
        ret nz

        ; Diagonal 0,4,8
        ld a, (board+0)
        cp c
        jr nz, .diag2
        ld a, (board+4)
        cp c
        jr nz, .diag2
        ld a, (board+8)
        cp c
        jr nz, .diag2
        ld a, 1
        or a
        ret

.diag2:
        ld a, (board+2)
        cp c
        jr nz, .nowin
        ld a, (board+4)
        cp c
        jr nz, .nowin
        ld a, (board+6)
        cp c
        jr nz, .nowin
        ld a, 1
        or a
        ret

.nowin:
        xor a
        ret

check_row:
        ld a, (hl)
        cp c
        jr nz, row_no
        inc hl
        ld a, (hl)
        cp c
        jr nz, row_no
        inc hl
        ld a, (hl)
        cp c
        jr nz, row_no
        ld a, 1
        or a
        ret
row_no:
        xor a
        ret

check_col:
        ld a, (hl)
        cp c
        jr nz, col_no
        add hl, de
        ld a, (hl)
        cp c
        jr nz, col_no
        add hl, de
        ld a, (hl)
        cp c
        jr nz, col_no
        ld a, 1
        or a
        ret
col_no:
        xor a
        ret

; ============================================
; Check for draw
; ============================================
check_draw:
        ld a, (move_count)
        cp 9
        jr z, .draw
        xor a
        ret
.draw:
        ld a, 1
        or a
        ret

; ============================================
; Messages
; ============================================
draw_win_message:
        ld hl, msg_player
        call print_string
        ld a, (current_player)
        call print_cell
        ld hl, msg_wins
        call print_string
        ld hl, msg_restart
        call print_string
        ret

draw_draw_message:
        ld hl, msg_draw
        call print_string
        ld hl, msg_restart
        call print_string
        ret

; ============================================
; Wait any key
; ============================================
wait_any_key:
        xor a
        ld ($5C08), a
.loop:
        ld a, ($5C08)
        or a
        jr z, .loop
        xor a
        ld ($5C08), a
        ret

; ============================================
; Print null-terminated string at HL
; ============================================
print_string:
        ld a, (hl)
        or a
        ret z
        rst $10
        inc hl
        jr print_string

; ============================================
; String data
; ============================================
msg_title:
        defb " TIC TAC TOE", 13, 13, 0

msg_sep:
        defb " -+-+-", 13, 0

msg_keys:
        defb " Keys: 1-9", 13
        defb " 1|2|3", 13
        defb " 4|5|6", 13
        defb " 7|8|9", 13, 13, 0

msg_turn:
        defb " Turn: ", 0

msg_player:
        defb 13
        defb " Player "
        defb 0

msg_wins:
        defb " wins!", 13, 0

msg_draw:
        defb 13
        defb " It is a draw!"
        defb 13, 0

msg_restart:
        defb " Press any key", 13, 0

; ============================================
; Variables
; ============================================
board:
        defs 9, 0

current_player:
        defb PLAYER_X

move_count:
        defb 0

selected_pos:
        defb 0
