USING: arrays combinators.smart formatting io kernel locals math math.bitwise
namespaces sequences ;
IN: lc3.instrs

:: >add ( DR SR1 SR2 -- instr )
    1 12 shift                  ! opcode
    DR 9 shift bitor
    SR1 6 shift bitor
    SR2 bitor ;


:: >addi ( DR SR IMM5 -- instr )
    1 12 shift                  ! opcode
    DR 9 shift bitor
    SR 6 shift bitor
    1 5 shift bitor             ! immediate flag
    IMM5 bitor ;


:: >and ( DR SR1 SR2 -- instr )
    5 12 shift                  ! opcode
    DR 9 shift bitor
    SR1 6 shift bitor
    SR2 bitor ;


:: >andi ( DR SR IMM5 -- instr )
    5 12 shift                  ! opcode
    DR 9 shift bitor
    SR 6 shift bitor
    1 5 shift bitor             ! immediate flag
    IMM5 bitor ;

:: >ld ( DR OFF9 -- instr )
    2 12 shift                  ! opcode
    DR 9 shift bitor
    OFF9 bitor ;

:: >ldr ( DR BASER OFF6 -- instr )
    6 12 shift
    DR 9 shift bitor
    BASER 6 shift bitor
    OFF6 bitor ;

:: >st ( SR OFF9 -- instr )
    3 12 shift                  ! opcode
    SR 9 shift bitor
    OFF9 bitor ;

:: >str ( SR BASER OFF6 -- instr )
    7 12 shift
    SR 9 shift bitor
    BASER 6 shift bitor
    OFF6 bitor ;

:: >not ( DR SR -- instr )
    9 12 shift
    DR 9 shift bitor
    SR 6 shift bitor
    0x3F bitor ;

:: >ldi ( DR OFF9 -- instr )
    10 12 shift
    DR 9 shift bitor
    OFF9 bitor ;

:: >sti ( SR OFF9 -- instr )
    11 12 shift
    SR 9 shift bitor
    OFF9 bitor ;
