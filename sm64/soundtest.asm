// armips sound tester patch for sm64 j
// 
// Controls:
// 
//   DPAD left, right -> select digit
//   DPAD up, down    -> edit digit
//   L                -> play sound/song
//   R                -> switch menus
// 

.n64
.open "sm64.j.z64", "sm64.j.soundtest.z64", 0

//////////////////

.definelabel SEG_GODDARD_RAM, 0x8016F000
.definelabel SEG_GODDARD_ROM, 0x0021D7D0
.definelabel SEG_GODDARD_HEADERSIZE, (SEG_GODDARD_RAM - SEG_GODDARD_ROM)

.definelabel SEG_MAIN_RAM, 0x80246000
.definelabel SEG_MAIN_ROM, 0x00001000
.definelabel SEG_MAIN_HEADERSIZE, (SEG_MAIN_RAM - SEG_MAIN_ROM)

.definelabel SEG_ENGINE_RAM, 0x80378800
.definelabel SEG_ENGINE_ROM, 0x000F4210
.definelabel SEG_ENGINE_HEADERSIZE, (SEG_ENGINE_RAM - SEG_ENGINE_ROM)

.definelabel SEG_MYCODE_RAM,  0x80370000
.definelabel SEG_MYCODE_ROM,  0x00761BE0
.definelabel SEG_MYCODE_HEADERSIZE, (SEG_MYCODE_RAM - SEG_MYCODE_ROM)
.definelabel SEG_MYCODE_SIZE, 0x00002000

//////////////////

.definelabel print_int, 0x802D57F8
.definelabel print_str, 0x802D5A74
.definelabel set_sound, 0x8031DC78
.definelabel set_music, 0x8031F690
.definelabel print_8x8_tex, 0x802E1F48
.definelabel dma_copy, 0x80277F54

.definelabel gButtonStates, 0x80339C68
.definelabel gGlobalTimer, 0x8032C694
.definelabel gDisplaylistHead, 0x80339CFC
.definelabel gSegmentTable, 0x8033A090

.definelabel SEG02_C_UP_TEX, 0x02008150

STAY_ON_INTRO equ 1

MENU_BASE_X equ 20
MENU_BASE_Y equ 80

BTN_R          equ 0x0010
BTN_L          equ 0x0020
BTN_DPAD_RIGHT equ 0x0100
BTN_DPAD_LEFT  equ 0x0200
BTN_DPAD_DOWN  equ 0x0400
BTN_DPAD_UP    equ 0x0800
BTN_B          equ 0x4000
BTN_A          equ 0x8000

NUM_MENUS equ 2

SNDTEST_MENU_SETMUSIC equ 0
SNDTEST_MENU_SETSOUND equ 1


//////////////////

.headersize SEG_GODDARD_HEADERSIZE
.org 0x8016F4E0
    nop // no intro sound

.headersize SEG_MAIN_HEADERSIZE

.org 0x80247CEC
    jal sndtest_hook // replace jal 0x8024781C

.org 0x80248A40
    // shortened original code to fit
    sw    v0, 0x80339CF4
    move  a1, v0
    jal   0x80277930
    addiu a0, r0, 0x18
    
    la    a0, 0x80339D20
    li    a1, 0x00577BC0
    lui   a2, hi(0x80339CF4)
    jal   0x80278A78
    lw    a2, lo(0x80339CF4) (a2)

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
    jal   dma_copy
    addiu a2, a1, SEG_MYCODE_SIZE
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x20

.org 0x802CA89C
    jal sndtest_main

.if STAY_ON_INTRO
    .orga 0x26806E // keep intro from dismissing
        .dh 0xFFFF
.endif

.headersize SEG_MYCODE_HEADERSIZE
.org SEG_MYCODE_RAM

dlist_push_cmd:
    lw    t0, gDisplayListHead
    sw    a0, 0x00 (t0)
    sw    a1, 0x04 (t0)
    addiu t0, t0, 8
    sw    t0, gDisplayListHead
    jr    ra
    nop

///////////////////////////
// MAIN MENU

sndTestPrevButtonStates: .dh 0
sndTestMenuMode: .db 0 :: .align 4

sndTestMainTitle: .asciiz "SOUND TESTER V2"

sndTestFmt_04x: .asciiz "%04x"
sndTestFmt_02x: .asciiz "%02x"
.align 4

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
    .if STAY_ON_INTRO
    jal   sndtest_main_keep_intro_screen_from_dismissing
    nop
    .endif
    jal   sndtest_main_show_title
    nop
    jal   sndtest_main_process_input
    nop
    lbu   t0, sndTestMenuMode
    bne   t0, SNDTEST_MENU_SETSOUND, @@L1
    nop
    jal   sndtest_setsound_main
    nop
    b     @@end
    nop
    @@L1:
    bne   t0, SNDTEST_MENU_SETMUSIC, @@L2
    nop
    jal   sndtest_setmusic_main
    nop
    b     @@end
    nop
    @@L2:
    @@end:
    jal   sndtest_main_save_button_states
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

.if STAY_ON_INTRO
sndtest_main_keep_intro_screen_from_dismissing:
    // dumb hack
    li    t0, 0xFFFF
    sh    t0, 0x8007B3EE
    jr    ra
    nop
.endif

sndtest_main_save_button_states:
    lhu   t0, gButtonStates
    sh    t0, sndTestPrevButtonStates
    jr    ra
    nop

sndtest_main_process_input:
    lhu   t0, gButtonStates
    lhu   t1, sndTestPrevButtonStates
    bnez  t1, @@end
    nop
    andi  at, t0, BTN_R
    beqz  at, @@end
    nop
    lbu   t2, sndTestMenuMode
    addiu t2, t2, 1
    beql  t2, NUM_MENUS, @@L1
    add   t2, r0, r0 // wrap around to 0
    @@L1:
    sb    t2, sndTestMenuMode
    @@end:
    jr ra
    nop

sndtest_main_show_title:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y + 80
    la    a2, sndTestMainTitle
    jal   print_str
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_show_menu_title:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    move  a2, a0
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y + 48
    jal   print_str
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_show_cursor:
    addiu sp, sp, -0x20
    sw    ra, 0x14 (sp)
    sw    a0, 0x18 (sp)
    sw    a1, 0x1C (sp)
    lw    t0, gGlobalTimer
    andi  t0, t0, 0x10
    bnez  t0, @@end
    nop
    li a0, 0x06000000
    li a1, 0x0200EC60
    jal dlist_push_cmd
    nop
    lw    a0, 0x18 (sp)
    lw    a1, 0x1C (sp)
    la    a2, SEG02_C_UP_TEX
    li    t0, 224
    jal   print_8x8_tex
    subu  a1, t0, a1
    @@end:
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x20 

///////////////////////////
// SETSOUND MENU

sndTestSetSoundWord: .dw 0x24218081
sndTestSetSoundCursorPos: .db 0 :: .align 4
sndTestSetSoundZeroVec3: .dw 0, 0, 0
sndTestSetSoundCursorStr: .asciiz "/"
sndTestSetSoundTitle: .asciiz "SETSOUND"
.align 4

sndtest_setsound_main:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    la    a0, sndTestSetSoundTitle
    jal   sndtest_show_menu_title
    nop
    jal   sndtest_setsound_show_word
    nop
    jal   sndtest_setsound_show_cursor
    nop
    jal   sndtest_setsound_process_input
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setsound_process_input:
    addiu sp, sp, -0x20
    sw    ra, 0x14 (sp)
    sw    s0, 0x18 (sp)
    lhu   t1, sndTestPrevButtonStates
    bnez  t1, @@end
    nop
    lhu   s0, gButtonStates
    //lw    t1, gGlobalTimer
    //andi  t1, t1, 3
    //bnez  t1, @@end
    //nop
    andi  at, s0, BTN_DPAD_RIGHT
    beqz  at, @@L1
    nop
    lbu   t1, sndTestSetSoundCursorPos
    addiu t1, t1, 1
    andi  t1, t1, 7
    sb    t1, sndTestSetSoundCursorPos
    @@L1:
    andi  at, s0, BTN_DPAD_LEFT
    beqz  at, @@L2
    nop
    lbu   t1, sndTestSetSoundCursorPos
    addiu t1, t1, -1
    andi  t1, t1, 7
    sb    t1, sndTestSetSoundCursorPos
    @@L2:
    andi  at, s0, BTN_DPAD_UP
    beqz  at, @@L3
    nop
    li    a0, 1
    jal   sndtest_setsound_update_word
    nop
    @@L3:
    andi  at, s0, BTN_DPAD_DOWN
    beqz  at, @@L4
    nop
    li    a0, 0
    jal   sndtest_setsound_update_word
    nop
    @@L4:
    andi  at, s0, BTN_L
    beqz  at, @@L5
    nop
    lw    a0, sndTestSetSoundWord
    la    a1, sndTestSetSoundZeroVec3
    jal   set_sound
    @@L5:
    @@end:
    //sh    s0, sndTestPrevButtonStates
    lw    s0, 0x18 (sp)
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x20

sndtest_setsound_show_title:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y + 48
    la    a2, sndTestSetSoundTitle
    jal   print_str
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setsound_show_word:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y
    lhu   a3, sndTestSetSoundWord
    la    a2, sndTestFmt_04x // (%08X not supported) 
    jal   print_int
    nop
    li    a0, MENU_BASE_X + (4 * 12)
    li    a1, MENU_BASE_Y
    lhu   a3, sndTestSetSoundWord+2
    la    a2, sndTestFmt_04x
    jal   print_int
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setsound_show_cursor:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)

    li    a0, MENU_BASE_X + 3
    li    a1, MENU_BASE_Y - 16
    lbu   t0, sndTestSetSoundCursorPos
    sll   t1, t0, 3
    sll   t2, t0, 2
    addu  t0, t1, t2
    jal sndtest_show_cursor
    addu  a0, a0, t0

    @@end:
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setsound_update_word:
    lbu   t0, sndTestSetSoundCursorPos
    li    t1, 7
    subu  t0, t1, t0
    sll   t0, t0, 2
    li    t1, 1
    sllv  t1, t1, t0 // t1 = 1 << (7-sndTestSetSoundCursorPos)*4
    lw    t0, sndTestSetSoundWord
    bnezl a0, @@L1
    addu  t0, t0, t1
    subu  t0, t0, t1
    @@L1:
    sw    t0, sndTestSetSoundWord
    jr    ra
    nop

///////////////////////////
// SETMUSIC MENU

sndTestSetMusicCursorPos: .db 0x00
sndTestSetMusicSongID: .db 0x01 :: .align 4
sndTestSetMusicTitle: .asciiz "SETMUSIC"
.align 4

sndtest_setmusic_main:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    la    a0, sndTestSetMusicTitle
    jal   sndtest_show_menu_title
    nop
    jal   sndtest_setmusic_show_id
    nop
    jal   sndtest_setmusic_show_cursor
    nop
    jal   sndtest_setmusic_process_input
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setmusic_show_id:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)
    li    a0, MENU_BASE_X
    li    a1, MENU_BASE_Y
    la    a2, sndTestFmt_02x
    lbu   a3, sndTestSetMusicSongId
    jal   print_int
    nop
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setmusic_process_input:
    addiu sp, sp, -0x20
    sw    ra, 0x14 (sp)
    sw    s0, 0x18 (sp)
    lhu   t1, sndTestPrevButtonStates
    bnez  t1, @@end
    nop
    lhu   s0, gButtonStates

    andi  at, s0, BTN_DPAD_RIGHT
    beqz  at, @@L1
    nop
    lbu   t1, sndTestSetMusicCursorPos
    addiu t1, t1, 1
    andi  t1, t1, 1
    sb    t1, sndTestSetMusicCursorPos

    @@L1:
    andi  at, s0, BTN_DPAD_LEFT
    beqz  at, @@L2
    nop
    lbu   t1, sndTestSetMusicCursorPos
    addiu t1, t1, -1
    andi  t1, t1, 1
    sb    t1, sndTestSetMusicCursorPos

    @@L2:
    andi  at, s0, BTN_L
    beqz  at, @@L5
    nop
    li    a0, 1
    lbu   a1, sndTestSetMusicSongID
    jal   set_music // setmusic wrapper
    li    a2, 0

    @@L5:
    andi at, s0, BTN_DPAD_UP
    beqz at, @@L6
    nop
    li a0, 1
    jal sndtest_setmusic_update_id
    nop

    @@L6:
    andi at, s0, BTN_DPAD_DOWN
    beqz at, @@L7
    nop
    li a0, 0
    jal sndtest_setmusic_update_id
    nop

    @@L7:
    @@end:
    lw    ra, 0x14 (sp)
    lw    s0, 0x18 (sp)
    jr    ra
    addiu sp, sp, 0x20

sndtest_setmusic_show_cursor:
    addiu sp, sp, -0x18
    sw    ra, 0x14 (sp)

    li    a0, MENU_BASE_X + 3
    li    a1, MENU_BASE_Y - 16
    lbu   t0, sndTestSetMusicCursorPos
    sll   t1, t0, 3
    sll   t2, t0, 2
    addu  t0, t1, t2
    jal sndtest_show_cursor
    addu  a0, a0, t0
    
    @@end:
    lw    ra, 0x14 (sp)
    jr    ra
    addiu sp, sp, 0x18

sndtest_setmusic_update_id:
    lbu   t0, sndTestSetMusicCursorPos
    li    t1, 1
    subu  t0, t1, t0
    sll   t0, t0, 2
    li    t1, 1
    sllv  t1, t1, t0 // t1 = 1 << (1-sndTestSetSoundCursorPos)*4
    lbu   t0, sndTestSetMusicSongID
    bnezl a0, @@L1
    addu  t0, t0, t1
    subu  t0, t0, t1
    @@L1:
    sb    t0, sndTestSetMusicSongID
    jr    ra
    nop

///////////////////////////

.close