        .include "header.s"
        .section .exceptions, "ax"

        ## allocate space on stack
        subi sp,sp,16
        stw ra,(sp)
        stw r2,4(sp)
        stw r3,8(sp)
        stw r4,12(sp)

CHECK_JP1:
        rdctl et,ipending
        andi r2,et,0b100000000000 # check for JP1 IRQ first
        beq r2,r0,CHECK_PS2

        movia r3,JP1            # load packet into et
        ldwio r0,12(r3)
        stwio r0,12(r3)
        ldwio r4,(r3)
        andi r2,r4,0xc000       # check magic
        movui r3,0x8000
        bne r2,r3,BADNESS
        andi r2,r4,0x3000       # check n
        srli r2,r2,12
        movia r3,n
        ldb r3,(r3)
        ## if signal comes back around to originating device, do not forward
        beq r2,r3,ACT_ON_PACKET
        movia r3,JP2
        ## send all 1s first and then signal, to cause negedge interrupt
        movui r2,0xffff
        stwio r2,(r3)
        stwio r4,(r3)           # pass along
ACT_ON_PACKET:
        call handle_packet      # execute packet actions and draw
        call drawscreen
        br EXIT_ISR
       
CHECK_PS2:
        andi r2,et,0b10000000
        beq r2,r0,CHECK_TIMER   # second, check for keyboard input

        movia r3,PS2
        movia r2,breakignore
        ldb et,(r2)             # check if ignoring due to break
        bne et,r0,SECOND_BREAK
        movui et,0xf0           # check for break
        ldbuio r4,(r3)
        beq et,r4,BREAK
        movui et,0x12           # check for shift (both left and right)
        beq et,r4,SHIFT
        movui et,0x59
        beq et,r4,SHIFT
MAKE:
        call decode             # decode PS2 scancode -> ASCII value/command character
        movia r4,n              # r2 now forms basis for the packet to be sent
        ori r2,r2,0x8000        # add magic
        ldb et,(r4)
        slli et,et,12
        or r2,r2,et             # add n
        movia r3,JP2
        movui et,0xffff
        stwio et,(r3)
        stwio r2,(r3)           # send it off
        br EXIT_ISR

BREAK:
        movi et,1               # write a flag to ignore the next scancode
        movia r2,breakignore
        stb et,(r2)
        br EXIT_ISR

SECOND_BREAK:
        movia r4,breakignore    # clear the flag
        stb r0,(r4)
        ldbuio et,(r3)
        movui r2,0x12
        beq r2,et,UNSHIFT       # if a shift break is found, unflag shift
        movui r2,0x59
        beq r2,et,UNSHIFT
        br EXIT_ISR

SHIFT:
        movia r3,shift          # enable shift flag
        movi et,1
        stb et,(r3)
        br EXIT_ISR

UNSHIFT:
        movia r3,shift          # disable shift flag
        stb r0,(r3)
        br EXIT_ISR

CHECK_TIMER:
        andi r2,et,0b1
        beq r2,r0,EXIT_ISR      # last priority is timer

        movia r3,blink          # toggle blink
        ldb r2,(r3)
        xori r2,r2,1
        stb r2,(r3)

        call drawscreen         # draw the screen and acknowledge timer IRQ
        movia r3,TIMER
        sthio r0,(r3)

        br EXIT_ISR
       
BADNESS:                        # invalid magic bits, should never happen
        movi r2,0xff
        movia et,GREENLEDS
        stwio r2,(et)
        br BADNESS
       
EXIT_ISR:
        ldw r4,12(sp)
        ldw r3,8(sp)
        ldw r2,4(sp)
        ldw ra,(sp)
        addi sp,sp,16
        ## deallocate space on stack

        subi ea,ea,4
        eret
