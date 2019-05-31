USING: arrays combinators combinators.smart formatting io kernel locals math
math.bitwise namespaces sequences lc3.utils ;
IN: lc3.instrs

: >opcode ( opcode -- bitmask ) 12 shift ;

: >dr ( reg -- bitmask ) 9 shift ;
: >sr ( reg -- bitmask ) >dr ;
: <dr ( instr -- dr ) 11 9 bit-range ;
: <sr ( instr -- sr ) >dr ;

: >sr1 ( reg -- bitmask  ) 6 shift ;
: >baser ( reg -- bitmask  ) >sr1 ;
: <sr1 ( instr -- sr1 ) 8 6 bit-range ;
: <baser ( instr -- basr ) 8 6 bit-range ;

: <sr2 ( instr -- sr2 ) 2 0 bit-range ;

! TODO clip (negative) bitfields!
: >immediate ( n imm -- immn ) swap drop ;
: >pc-offset ( n off -- offn ) >immediate ;
:: <pc-offset ( instr n -- offset-n )
    n 1 - :> msb
    instr msb 0 bit-range msb sign-extend ;

: <immediate ( instr n -- immediate-n ) <pc-offset ;

: >nzp ( sign -- nzp )
    1 { { [ dup 0 > ] [ drop 9 ] }
        { [ dup 0 = ] [ drop 10 ] }
        { [ dup 0 < ] [ drop 11 ] }
    } cond shift ;

:: >add ( DR SR1 SR2 -- instr )
    1   >opcode
    DR  >dr bitor
    SR1 >sr1 bitor
    SR2 bitor ;

:: >addi ( DR SR1 IMM5 -- instr )
    1      >opcode
    DR     >dr bitor
    SR1    >sr1 bitor
           1 5 shift bitor      ! immediate flag
    5 IMM5 >immediate bitor ;

:: >and ( DR SR1 SR2 -- instr )
    5   >opcode
    DR  >dr bitor
    SR1 >sr1 bitor
    SR2 bitor ;

:: >andi ( DR SR1 IMM5 -- instr )
    5      >opcode                  ! opcode
    DR     >dr bitor
    SR1    >sr1 bitor
    1 5 shift bitor             ! immediate flag
    5 IMM5 >immediate bitor ;

:: >br ( SIGN OFF9 -- instr )
    0      >opcode
    SIGN   >nzp bitor
    9 OFF9 >pc-offset bitor ;

:: >jmp ( BASER -- instr )
    12    >opcode
    BASER >baser bitor ;

:: >jsr ( OFF11 -- instr )
    4        >opcode
    1 11 shift bitor
    11 OFF11 >pc-offset bitor ;

:: >jsrr ( BASER -- instr )
    4     >opcode
    BASER >baser bitor ;

:: >ld ( DR OFF9 -- instr )
    2      >opcode                  ! opcode
    DR     >dr bitor
    9 OFF9 >pc-offset bitor ;

:: >ldi ( DR OFF9 -- instr )
    10     >opcode
    DR     >dr bitor
    9 OFF9 >pc-offset bitor ;

:: >ldr ( DR BASER OFF6 -- instr )
    6      >opcode
    DR     >dr bitor
    BASER  >baser bitor
    6 OFF6 >pc-offset bitor ;

:: >lea ( DR OFF9 -- instr )
    14     >opcode
    DR     >dr bitor
    9 OFF9 >pc-offset bitor ;

:: >not ( DR SR1 -- instr )
    9   >opcode
    DR  >dr bitor
    SR1 >sr1 bitor
    0x3F bitor ;

: >ret ( -- instr ) 7 >jmp ;

: >rti ( -- instr ) 8 >opcode ;

:: >st ( SR OFF9 -- instr )
    3      >opcode
    SR     >sr bitor
    9 OFF9 >pc-offset bitor ;

:: >sti ( SR OFF9 -- instr )
    11     >opcode
    SR     >sr bitor
    9 OFF9 >pc-offset bitor ;

:: >str ( SR BASER OFF6 -- instr )
    7      >opcode
    SR     >sr bitor
    BASER  >baser bitor
    6 OFF6 >pc-offset bitor ;

:: >trap ( TRAPVECT8 -- instr )
    15 >opcode
    TRAPVECT8 bitor ;
