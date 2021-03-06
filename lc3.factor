! Copyright (C) 2019 Alessandro Piras.
! See http://factorcode.org/license.txt for BSD license.

USING: arrays combinators combinators.smart formatting io kernel lc3.instrs
lc3.utils locals math math.bitwise namespaces sequences strings curses.ffi
threads calendar  ;

IN: lc3

SYMBOLS: mem regs pc cnd instr-routines trap-routines is-running ;

: mem-size  ( -- y ) 2^16 ;
: kbdsr     ( -- kbdsr-addr ) 0xFE00 ;

: reg-get ( reg -- value ) regs get-global nth ;
:: reg-set ( n val -- ) val n regs get-global set-nth ;

:: mem-set ( addr val -- ) val addr mem get-global set-nth ;

: check-key ( -- )
    [let read-non-blocking :> ch
     ch -1 =
     [ kbdsr 0  mem-set ]
     [ kbdsr ch mem-set ] if ] ;


: mmio-update ( addr -- )
    {
        { [ dup kbdsr = ] [ drop check-key ] }
        [ drop ]
    } cond ;

: mem-get ( addr -- val )
    dup mmio-update
    mem get-global nth ;

: reg<mem ( reg addr -- ) mem-get reg-set ;
: mem<reg ( addr reg -- ) reg-get mem-set ;

: set-cnd ( DR -- ) reg-get {
        { [ dup 0 < ] [ drop 4 ] }
        { [ dup 0 = ] [ drop 2 ] }
        { [ dup 0 > ] [ drop 1 ] }
    } cond cnd set-global ;

: get-cnd ( -- cnd ) cnd get-global ;
: cneg? ( -- x )  get-cnd 4 = ;
: cpos? ( -- x )  get-cnd 1 = ;
: czero? ( -- x ) get-cnd 2 = ;

: get-pc ( -- pc ) pc get-global ;
: set-pc ( v -- ) pc set-global ;
: pc-incr ( step -- ) get-pc u16+ set-pc ;

:: instr-br ( instr -- )
    instr <nzp
    get-cnd
    bitand 0 = [
        instr 9 <pc-offset pc-incr
    ] unless ;

:: instr-op-normal ( instr quot -- )
    instr <dr                    ! DR
    instr <sr1 reg-get           ! SR1
    instr <sr2 reg-get           ! SR2
    quot call( x y -- z )        ! RES
    reg-set                      ! set
    ;

:: instr-op-immediate ( instr quot -- )
    instr <dr                         ! DR
    instr <sr1 reg-get                ! SR1 value
    instr 5 <immediate                ! immediate value
    quot call( x y -- z )             ! result
    reg-set                           ! set
    ;

:: instr-op ( instr quot -- )
    instr 5 nth-bit 0 =
        [ instr quot instr-op-normal ]
        [ instr quot instr-op-immediate ]
    if
    instr 11 9 bit-range set-cnd ;

:: instr-add ( instr -- ) instr [ u16+ ] instr-op ;
:: instr-and ( instr -- ) instr [ bitand ] instr-op ;

:: instr-ld ( instr -- )
    instr <dr                   ! DR
    dup
    instr 9 <pc-offset          ! OFFSET9
    get-pc u16+
    reg<mem
    set-cnd ;

:: instr-st ( instr -- )
    instr 9 <pc-offset          ! OFFSET9
    get-pc u16+                 ! PC + OFFSET9
    instr <sr                   ! SR
    mem<reg ;


:: instr-jsri ( instr -- ) instr 11 <pc-offset get-pc u16+ set-pc ;
:: instr-jsrr ( instr -- ) instr <baser reg-get set-pc ;

:: instr-jsr ( instr -- )
    7 get-pc reg-set
    instr 11 11 bit-range 1 =
      [ instr instr-jsri ]
      [ instr instr-jsrr ]
    if ;

: instr-ldr ( instr -- )
    {
        [ <dr dup ]             ! DR DR (for set-cnd)
        [ <baser reg-get ]      ! DR BASER-value
        [ 6 <pc-offset ]        ! DR BASER-value OFF6;
    } cleave
    u16+                        ! DR ADDR
    reg<mem                     ! --
    set-cnd
    ;

:: instr-str ( instr -- )
    instr 8 6 bit-range reg-get       ! BASER-value
    instr 5 0 bit-range 5 sign-extend ! BASER-value OFF6;
    u16+                              ! ADDR
    instr 11 9 bit-range              ! SR
    mem<reg                           ! --
    ;

:: instr-rti ( instr -- ) "RTI not implemented" throw ;

: instr-not ( instr -- )
    { [ <dr ]
      [ <sr1 reg-get bitnot u16mod ] } cleave
    reg-set ;

:: instr-ldi ( instr -- )
    instr <dr dup               ! DR DR (for set-cnd)

    instr 9 <pc-offset          ! OFF9
    get-pc u16+                 ! PC+OFF9
    mem-get                     ! mem(PC+OFF9)

    reg<mem                     ! DR <- mem(mem(PC+OFF9))
    set-cnd
    ;

:: instr-sti ( instr -- )
    instr 9 <pc-offset          ! OFF9
    get-pc u16+                 ! OFF9+PC
    mem-get                     ! mem(OFF9+PC)

    instr <sr                   ! SR
    mem<reg                     ! mem(mem(OFF9+PC)) <- SRval
    ;

: instr-jmp ( instr -- ) <baser reg-get set-pc ;

:: instr-res ( instr -- ) "RES not implemented" throw ;

: instr-lea ( instr -- )
    { [ <dr dup ] [ 9 <pc-offset ] } cleave
    get-pc
    u16+
    reg-set
    set-cnd ;

! get a string starting from memory address addr.
! characters are stored sequentially, one char per memory location
:: mem-gets ( addr -- string )
    0 ! from
    0 addr mem get-global index-from  ! index of next 0
    mem get-global
    <slice>
    >string
    ;

:: first-byte-zero? ( val -- res )
    val -8 shift 0 = ;

:: last-byte-zero? ( val -- res )
    val 0xFF bitand 0 = ;

:: end-of-string-sp? ( val -- res )
    val first-byte-zero?
    val last-byte-zero?
    or ;

:: concat-chars-sp ( str val -- res )
    [let val -8 shift :> char1 val 0xFF bitand :> char2
     {
         { [ char1 0 = ] [ str ] }
         { [ char2 0 = ] [ str char1 suffix ] }
         [ str char1 suffix char2 suffix ]
     } cond ] ;

:: find-eos-sp ( start -- index )
    start mem get-global [ end-of-string-sp? ] find-from drop 1 + ;

! get a string starting from memory address addr.
! characters are stored sequentially, two chars per memory location
! 0x6566 -> AB
:: mem-getsp ( addr -- string )
    addr addr find-eos-sp mem get-global <slice>  ! sequence
    ""
    [ concat-chars-sp ] reduce ;

:: write-char ( char -- )
    "" char suffix write ;

: trap-getc ( -- ) 0 read-blocking reg-set ;
: trap-out ( -- ) "" 0 reg-get 0xFF bitand suffix 0 printw drop ;
: trap-puts ( -- ) 0 reg-get mem-gets 0 printw drop ;

: trap-in ( -- ) "Enter a character" print trap-getc ;
: trap-putsp ( -- ) 0 reg-get mem-getsp 0 printw drop ;
: trap-halt ( -- ) f is-running set-global ;

:: instr-trap ( instr -- )
    instr <trapvect8 0x20 -
    instr-routines get-global nth
    call( -- )
    ;

: setup ( -- )
    mem-size 0 <array> mem set-global
    8 0 <array> regs set-global
    0 set-pc
    0 set-cnd
    {
        [ instr-br   ]          ! 0000
        [ instr-add  ]          ! 0001
        [ instr-ld   ]          ! 0010
        [ instr-st   ]          ! 0011
        [ instr-jsr  ]          ! 0100
        [ instr-and  ]          ! 0101
        [ instr-ldr  ]          ! 0110
        [ instr-str  ]          ! 0111
        [ instr-rti  ]          ! 1000
        [ instr-not  ]          ! 1001
        [ instr-ldi  ]          ! 1010
        [ instr-sti  ]          ! 1011
        [ instr-jmp  ]          ! 1100
        [ instr-res  ]          ! 1101
        [ instr-lea  ]          ! 1110
        [ instr-trap ]          ! 1111
    } instr-routines set-global
    {
        [ trap-getc ]
        [ trap-out ]
        [ trap-puts ]
        [ trap-in ]
        [ trap-putsp ]
        [ trap-halt ]
    } trap-routines set-global
    ;

: fetch-instr ( -- instr ) get-pc mem-get ;

: opcode ( instr -- opc ) -12 shift ;

: get-instr ( opcode -- quot )
    instr-routines get-global
    nth ;

:: interpret ( instr -- quot )
    instr opcode
    instr-routines get-global
    nth
    ;

: exec-instr ( instr -- ) interpret call( -- ) ; inline

: main-loop ( -- )
    is-running get-global
    [ fetch-instr
      1 pc-incr
      exec-instr
      main-loop ]
    [ "Halted." printw
      2 seconds sleep ] if ;

: main ( -- )
    initscr drop
    setup
    main-loop
    endwin drop
    ;
