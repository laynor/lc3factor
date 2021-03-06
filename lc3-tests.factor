! Copyright (C) 2019 Your name.
! See http://factorcode.org/license.txt for BSD license.
USING: tools.test lc3 lc3.instrs namespaces ;
IN: lc3.tests

! test add
{ 10 } [
    setup
    1 7 reg-set
    2 3 reg-set
    0 1 2 >add instr-add
    0 reg-get
] unit-test

! test addi
{ 9 } [
    setup
    1 7 reg-set
    0 1 2 >addi instr-add
    0 reg-get
] unit-test


! test and
{ 3 } [
    setup
    1 7 reg-set
    2 3 reg-set
    0 1 2 >add instr-and
    0 reg-get
] unit-test

! test andi
{ 2 } [
    setup
    1 7 reg-set
    0 1 2 >addi instr-and
    0 reg-get
] unit-test


! test st
{ 3 } [
    setup
    1 3 reg-set
    1 10 >st instr-st
    10 mem-get
] unit-test


! test ld
{ 3 } [
    setup
    10 3 mem-set
    1 10 >ld instr-ld
    1 reg-get
] unit-test

! test ldr
{ 3 } [
    setup
    1 10 reg-set ! BASER = 10
    12 3 mem-set
    0 1 2 >ldr instr-ldr
    0 reg-get
] unit-test

! test str
{ 3 } [
    setup
    1 10 reg-set                ! BASER = 10
    0 3 reg-set                 ! R0 <- 3
    0 1 2 >str instr-str        ! STR R0 R1 #2
    12 mem-get
] unit-test

! test not
{ 0x0F0F } [
    setup
    0 0xF0F0 reg-set
    1 0 >not instr-not
    1 reg-get
] unit-test


! test ldi
{ 15 } [
    setup
    20 10 mem-set
    10 15 mem-set
    0 20 >ldi instr-ldi
    0 reg-get
] unit-test

{ 15 } [
    setup
    20 10 mem-set
    10 15 mem-set
    1 pc set-global
    0 19 >ldi instr-ldi
    0 reg-get
] unit-test

! test sti
{ 15 } [
    setup
    0 15 reg-set
    20 10 mem-set
    1 pc set-global
    0 19 >sti instr-sti
    10 mem-get
] unit-test

! test lea
{ 15 } [
    setup
    5 pc set-global
    0 10 >lea instr-lea
    0 reg-get
] unit-test

! test BRn
{ 20 } [                        ! BRn vs -
    setup
    14 pc set-global
    4 cnd set-global
    1 0 0 6 >br instr-br
    pc get-global
] unit-test

{ 14 } [
    setup
    14 pc set-global
    2 cnd set-global
    1 0 1 6 >br instr-br        ! BRnp vs 0
    pc get-global
] unit-test

{ 20 } [
    setup                       ! BRnp vs p
    14 pc set-global
    1 cnd set-global
    1 0 1 6 >br instr-br
    pc get-global
] unit-test

{ 20 } [
    setup                       ! BRzp vs 0
    14 pc set-global
    2 cnd set-global
    0 1 1 6 >br instr-br
    pc get-global
] unit-test

{ 20 } [
    setup                       ! BRzp vs p
    14 pc set-global
    1 cnd set-global
    0 1 1 6 >br instr-br
    pc get-global
] unit-test

! test JMP
{ 20 } [
    setup
    0 20 reg-set
    0 >jmp instr-jmp
    get-pc
] unit-test

{ 20 } [
    setup
    1 20 reg-set
    1 >jmp instr-jmp
    get-pc
] unit-test

! test JSR

{ 120 } [
    setup
    20 set-pc
    100 >jsr instr-jsr
    get-pc
] unit-test

{ 20 } [
    setup
    20 set-pc
    100 >jsr instr-jsr
    7 reg-get
] unit-test

{ 120 } [
    setup
    20 set-pc
    2 120 reg-set
    2 >jsrr instr-jsr
    get-pc
] unit-test

{ 20 } [
    setup
    20 set-pc
    2 120 reg-set
    2 >jsrr instr-jsr
    7 reg-get
] unit-test

{ "ABC" } [
    setup
    0x0 65 mem-set
    0x1 66 mem-set
    0x2 67 mem-set
    0x3 0 mem-set

    0x0 mem-gets
] unit-test

{ "ABCDE" } [
    0x0 0x4142 mem-set
    0x1 0x4344 mem-set
    0x2 0x4500 mem-set
    0x3 0x0    mem-set

    0x0 mem-getsp
] unit-test
