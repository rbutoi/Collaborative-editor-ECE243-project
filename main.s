        .include "header.s"
        .section .text

        .global actualmain
actualmain:
        movia sp,0x0800000
       
        ## set up GPIOs
        movia r3,JP1
        stwio r0,4(r3)
        movia r3,JP2            # output
        movia r2,0x0000ffff     # input
        stwio r2,4(r3)
       
        movia r3,n
        movia r4,PUSHBUTTONS
        movia r5,JP1
        ## loop to establish "pecking order", or each devices's numeric ID, n
PECKINGLOOP:                    # now, wait until push button pressed to establish pecking order
        ldwio r2,(r4)           # check for button presses
        andi r2,r2,0b1110
        beq r2,r0,CHECKJP1
        ## button was pressed
        stb r0,(r3)             # I am 0
        movia r4,JP2
        movui r2,0xa001         # a is magic #, 1 is the next DE2's n
        stwio r2,(r4)
        br ESTABLISHED
       
CHECKJP1:
        ldhio r2,(r5)
        andi r6,r2,0xf000       # isolate magic number
        movui r7,0xa000
        bne r6,r7,PECKINGLOOP   # if magic num not found, restart loop
        andi r2,r2,0x0003
        stb r2,(r3)             # set own n to number received
        movia r4,JP2
        addi r2,r2,1            # build & send n+1 signal
        ori r2,r2,0xa000
        stwio r2,(r4)
       
ESTABLISHED:
        movia r4,GREENLEDS      # pecking order established, write n to green LEDs
        ldb r2,(r3)
        stwio r2,(r4)

        ## JP1
        movia r3,JP1            # set up interrupts for syncing
        ## only care about second-MSB, as that changes when signal goes from ffff -> magic _ rest
        movui r2,0x4000
        stwio r2,8(r3)          # IRQ mask
        stwio r0,12(r3)

        ## set up keyboard
        movia r3,PS2
        movi r2,1
        stwio r2,4(r3)

        ## set up timer
        movia r3,TIMER
        movia r2,25000000       # period = 0.5s
        sthio r2,8(r3)
        srli r2,r2,16
        sthio r2,12(r3)
        movi r2,0b111           # start, continue, enable IRQs
        sthio r2,4(r3)          # go

        movui r2,0b100010000001
        wrctl ienable,r2
        
        movi r2,1
        wrctl status,r2         # enable interrupts

        call clearscreen
CHILL:                          # it just chills
        br CHILL
