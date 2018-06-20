// armips sound tester patch for sm64 j

//.n64
//.open "sm64.j.z64", "sm64.j.soundtest.z64", 0

// DPAD left, right -> select digit
// DPAD up, down    -> edit digit
// L                -> play sound

//////////////////

.definelabel SEG_MAIN_RAM, 0x80246000
.definelabel SEG_MAIN_ROM, 0x00001000
.definelabel SEG_MAIN_HEADERSIZE, (SEG_MAIN_RAM - SEG_MAIN_ROM)

.definelabel SEG_ENGINE_RAM, 0x80378800
.definelabel SEG_ENGINE_ROM, 0x000F4210
.definelabel SEG_ENGINE_HEADERSIZE, (SEG_ENGINE_RAM - SEG_ENGINE_ROM)

.definelabel SEG_GODDARD_RAM, 0x8016F000
.definelabel SEG_GODDARD_ROM, 0x0021D7D0
.definelabel SEG_GODDARD_HEADERSIZE, (SEG_GODDARD_RAM - SEG_GODDARD_ROM)

.definelabel SEG_MYCODE_RAM,  0x80370000
.definelabel SEG_MYCODE_ROM,  0x00761BE0
.definelabel SEG_MYCODE_HEADERSIZE, (SEG_MYCODE_RAM - SEG_MYCODE_ROM)
.definelabel SEG_MYCODE_SIZE, 0x00002000

//////////////////

.definelabel print_int, 0x802D57F8
.definelabel print_str, 0x802D5A74
.definelabel set_sound, 0x8031DC78
.definelabel print_8x8_tex, 0x802E1F48 // 02008150

.definelabel gButtonStates, 0x80339C68
.definelabel gGlobalTimer, 0x8032C694
.definelabel gDisplaylistHead, 0x80339CFC
.definelabel gSegmentTable, 0x8033A090

.definelabel seg02_c_up_tex, 0x02008150

MENU_BASE_X equ 20
MENU_BASE_Y equ 80

DPAD_RIGHT equ 0x0100
DPAD_LEFT  equ 0x0200
DPAD_DOWN  equ 0x0400
DPAD_UP    equ 0x0800
BTN_L      equ 0x0020
BTN_R      equ 0x0010

//////////////////

.headersize SEG_GODDARD_HEADERSIZE
.org 0x8016F4E0
    nop // no intro sound

.headersize SEG_MAIN_HEADERSIZE

.org 0x80247CEC
    jal sndtest_hook // replace jal 0x8024781C

.org 0x80248A40
    // shortened original code to fit
    lui   at, 0x8034
    sw    v0, 0x9CF4(at)
    or    a1, v0, r0
    jal   0x80277930
    addiu a0, r0, 0x18
    lui   t0, 0x8034
    addiu a0, t0, 0x9D20
    lui   a1, 0x0057
    addiu a1, a1, 0x7BC0
    jal   0x80278A78
    lw    a2, 0x9CF4 (t0)
    li    a0, 0x10
    li    a1, 0x001076A0
    addiu a2, a1, 0x30
    jal   0x802780DC
    li    a3, 0
    li    a1, 0x001076D0
    li    a2, 0x00112B50
    jal   0x80278228
    addiu a0, r0, 0x02
    // load my data
    li    a0, SEG_MYCODE_RAM
    li    a1, SEG_MYCODE_ROM
    jal   0x80277F54
    addiu a2, a1, SEG_MYCODE_SIZE
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x20

.org 0x802CA89C
    jal sndtest_main

.orga 0x26806E
    .dh 0xFFFF

.headersize SEG_MYCODE_HEADERSIZE
.org SEG_MYCODE_RAM

dlist_push_cmd:
    lw t0, gDisplayListHead
    sw a0, 0x00 (t0)
    sw a1, 0x04 (t0)
    addiu t0, t0, 8
    sw t0, gDisplayListHead
    jr ra
    nop

sndtest_hook:
    addiu sp, sp, -0x18
    sw ra, 0x14 (sp)
    jal 0x8024781C
    nop
    jal sndtest_main
    nop
    lw ra, 0x14 (sp)
    jr ra
    addiu sp, sp, 0x18

sndtest_main:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    jal   sndtest_keep_intro_screen_from_dismissing
    nop
    jal   sndtest_show_title
    nop
    jal   sndtest_show_word
    nop
    jal   sndtest_show_cursor
    nop
    jal   sndtest_process_input
    nop
    @@end:
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_keep_intro_screen_from_dismissing:
    // dumb hack
    li t0, 0xFFFF
    sh t0, 0x8007B3EE
    jr ra
    nop

sndtest_process_input:
    addiu sp, sp, -0x20
    sw    ra, 0x14 (sp)
    sw    s0, 0x18 (sp)
    lhu   s0, gButtonStates
    lhu   t1, prevButtonStates
    bnez  t1, @@end
    nop
    //lw    t1, gGlobalTimer
    //andi  t1, t1, 3
    //bnez  t1, @@end
    //nop
    andi  at, s0, DPAD_RIGHT
    beqz  at, @@L1
    nop
    lbu   t1, cursorPos
    addiu t1, t1, 1
    andi  t1, t1, 7
    sb    t1, cursorPos
    @@L1:
    andi  at, s0, DPAD_LEFT
    beqz  at, @@L2
    nop
    lbu   t1, cursorPos
    addiu t1, t1, -1
    andi  t1, t1, 7
    sb    t1, cursorPos
    @@L2:
    andi  at, s0, DPAD_UP
    beqz  at, @@L3
    nop
    li    a0, 1
    jal   sndtest_update_word
    nop
    @@L3:
    andi  at, s0, DPAD_DOWN
    beqz  at, @@L4
    nop
    li    a0, 0
    jal   sndtest_update_word
    nop
    @@L4:
    andi  at, s0, BTN_L
    beqz  at, @@L5
    nop
    lw    a0, soundWord
    la    a1, zeroVec3
    jal   set_sound
    @@L5:
    @@end:
    sh    s0, prevButtonStates
    lw    s0, 0x18 (sp)
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x20

sndtest_show_title:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y + 48
    la    a2, title
    jal   print_str
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_show_word:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y
    lhu   a3, soundWord
    la    a2, fmt_04x // (%08X not supported) 
    jal   print_int
    nop
    li    a0, MENU_BASE_X + (4 * 12)
    li    a1, MENU_BASE_Y
    lhu   a3, soundWord+2
    la    a2, fmt_04x
    jal   print_int
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_show_cursor:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li a0, 0x06000000
    li a1, 0x0200EC60
    jal dlist_push_cmd
    nop
    li    a0, MENU_BASE_X + 3
    li    a1, (224 - MENU_BASE_Y) + 16
    lbu   t0, cursorPos
    sll   t1, t0, 3
    sll   t2, t0, 2
    addu  t0, t1, t2 // cursorPos * 12
    la    a2, seg02_c_up_tex
    jal   print_8x8_tex
    addu  a0, a0, t0 // basex + cursorPos*12
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_update_word:
    lbu   t0, cursorPos
    li    t1, 7
    subu  t0, t1, t0
    sll   t0, t0, 2
    li    t1, 1
    sllv  t1, t1, t0 // t1 = 1 << (7-cursorPos)*4
    lw    t0, soundWord
    bnezl a0, @@L1
    addu  t0, t0, t1
    subu  t0, t0, t1
    @@L1:
    sw    t0, soundWord
    jr    ra
    nop

soundWord: .dw 0x34118081
cursorPos: .db 0
.align 4
zeroVec3: .dw 0, 0, 0
.align 4
prevButtonStates: .dh 0
fmt_04x: .asciiz "%04x"
cursor_str: .asciiz "/"
title: .asciiz "SETSOUND TESTER V1"

//.close