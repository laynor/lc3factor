! Copyright (C) 2019 Alessandro Piras.
! See http://factorcode.org/license.txt for BSD license.

USING: arrays combinators.smart formatting io kernel locals math math.bitwise
namespaces sequences lc3.instrs combinators ;

IN: lc3

SYMBOLS: mem regs pc cnd instr-routines ;

: uint16-max ( -- y ) 0x10000 ;
: mem-size  ( -- y ) uint16-max ;



:: mask ( msb -- mask ) uint16-max 1 - msb 16 shift-mod ;

:: nth-bit ( value n -- b ) value n n bit-range ;

:: sign-extend ( value msb -- sextvalue )
    msb mask ! bitmask
    value msb nth-bit *
    value bitor ;


: u16mod ( x -- y ) uint16-max mod uint16-max + uint16-max mod ;
: u16+ ( x y -- x+y ) + u16mod ;
: u16* ( x y -- x*y ) * u16mod ;
: u16- ( x y -- x-y ) - u16mod ;
: u16/ ( x y -- x/y ) / u16mod ;

: reg-get ( reg -- value ) regs get-global nth ;
:: reg-set ( n val -- ) val n regs get-global set-nth ;

: mem-get ( addr -- val ) mem get-global nth ;
:: mem-set ( addr val -- ) val addr mem get-global set-nth ;

: reg<mem ( reg addr -- ) mem-get reg-set ;
: mem<reg ( addr reg -- ) reg-get mem-set ;

: set-cnd ( DR -- )
    reg-get {
        { [ dup 0 < ] [ drop 4 ] }
        { [ dup 0 = ] [ drop 2 ] }
        { [ dup 0 > ] [ drop 1 ] }
    } cond cnd set-global ;

:: cneg? ( -- x )  cnd get-global 4 = ;
:: cpos? ( -- x )  cnd get-global 1 = ;
:: czero? ( -- x ) cnd get-global 2 = ;

:: instr-br ( instr -- ) ;

:: instr-op-normal ( instr quot -- )
    instr 11 9 bit-range         ! DR
    instr 8 6  bit-range reg-get ! SR1
    instr 2 0  bit-range reg-get ! SR2
    quot call( x y -- z )        ! RES
    reg-set                      ! set
    ;

:: instr-op-immediate ( instr quot -- )
    instr 11 9 bit-range              ! DR
    instr 8 6  bit-range reg-get      ! SR value
    instr 4 0 bit-range 4 sign-extend ! immediate value
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
    instr 11 9 bit-range              ! DR
    dup
    instr 8 0 bit-range 8 sign-extend ! OFFSET9
    pc get-global u16+
    reg<mem
    set-cnd ;

:: instr-st ( instr -- )
    instr 8 0 bit-range 8 sign-extend ! OFFSET9
    pc get-global u16+
    instr 11 9 bit-range              ! SR
    mem<reg ;


:: instr-jsr ( instr -- ) ;

:: instr-ldr ( instr -- )
    instr 11 9 bit-range dup          ! DR DR (for set-cnd)
    instr 8 6 bit-range reg-get       ! DR BASER-value
    instr 5 0 bit-range 5 sign-extend ! DR BASER-value OFF6;
    u16+                              ! DR ADDR
    reg<mem                           ! --
    set-cnd
    ;

:: instr-str ( instr -- )
    instr 8 6 bit-range reg-get       ! BASER-value
    instr 5 0 bit-range 5 sign-extend ! BASER-value OFF6;
    u16+                              ! ADDR
    instr 11 9 bit-range              ! SR
    mem<reg                           ! --
    ;

:: instr-rti ( instr -- ) ;

:: instr-not ( instr -- )
    instr 11 9 bit-range               ! DR
    instr 8 6 bit-range reg-get bitnot ! not SR
    u16mod                             ! uint16
    reg-set ;

:: instr-ldi ( instr -- )
    instr 11 9 bit-range dup          ! DR DR (for set-cnd)

    instr 8 0 bit-range 8 sign-extend ! OFF9
    pc get-global u16+                ! PC+OFF9
    mem-get                           ! mem(PC+OFF9)

    reg<mem                           ! DR <- mem(mem(PC+OFF9))
    set-cnd
    ;

:: instr-sti ( instr -- )
    instr 8 0 bit-range 8 sign-extend ! OFF9
    pc get-global u16+                ! OFF9+PC
    mem-get                           ! mem(OFF9+PC)

    instr 11 9 bit-range              ! SRval
    mem<reg                           ! mem(mem(OFF9+PC)) <- SRval
    ;

:: instr-jmp ( instr -- ) ;
:: instr-res ( instr -- ) ;
:: instr-lea ( instr -- ) ;
:: instr-trap ( instr -- ) ;


: setup ( -- )
    mem-size 0 <array> mem set-global
    8 0 <array> regs set-global
    0 pc set-global
    0 cnd set-global
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
    ;

: fetch-instr ( -- instr ) pc get-global mem get-global nth ;

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
    fetch-instr
    exec-instr
    ;

: main ( -- )
    setup
    main-loop
    ;
