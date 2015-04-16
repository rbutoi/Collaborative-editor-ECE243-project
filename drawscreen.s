        .include "header.s"

        .global drawscreen

        #drawscreen function that clears the screen everytime and redraws all the characters from the memory
drawscreen:
#save all callee save registers on the stack
        subi sp,sp,32
        stw r15,(sp)
        stw r16,4(sp)
        stw r17,8(sp)
        stw r18,12(sp)
        stw r19,16(sp)
        stw r20,20(sp)
        stw r21,24(sp)
        stw ra,28(sp)
#load the address for the pre, post & buffer pointer from memory
        movia r7,pre
        ldh r18,(r7)
        movia r7,post
        ldh r19,(r7)
        movia r4,buffer
#pre and post hold the index past buffer they are in, however making them the address itself by adding them to buffer
        add r5,r18,r4
        add r6,r19,r4

        movia r7,ADDR_CHAR
        movi r19,128
        movi r18,60
        movi r16,-1
#goes through all the char buffer and sets them all to space(clearing it)
cleartext:
#outerloop to go through while y<60 reset the x
outsideloop:
        beq r16,r18,text
        addi r16,r16,1
        movi r17,0

innerloop:
#increment x until its 80
        beq r17,r19,outsideloop
#memory address= x+128y+base
        muli r21,r16,128

        add r20,r17,r21
        add r20,r20,r7
#set them all to space
        movi r21,' '
        sthio r21,0(r20)
        addi r17,r17,1
        br innerloop
#begin writing from memory
text:
        movi r17,0
        movi r18,80
        movi r19,0
        movi r20,10
        movia r21,ADDR_CHAR
#loop while the index is less than pre(the beggining of the buffer)
loop:
        beq r4,r5,preskip
        bne r19,r18,here
        movi r19,0          #current position in the x
        addi r21,r21,48
here:
#load from the index
        ldb r16,(r4)
        addi r19,r19,1
#check if you have an enter
        bne r20,r16,next
#skip a full line of display by subtracting your current position from 128 to know what to add to get to the next line
        subi r19,r19,129        # -1 extra
        muli r19,r19,-1
        mov r15,r19
        add  r21,r21,r19
        movi r19,0

next:
#r17 holds which character number you are form the start of memory
#position is the location of each of the 4 cursors from the start of memory
#this section determines whether to draw a cursor or not
        movia r7,position
        ldh r22,(r7)
        beq r17,r22,cursor
        ldh r22,2(r7)
        beq r17,r22,cursor
        ## for cursors 3 and 4
        ## ldh r22,4(r7)
        ## beq r17,r22,cursor
        ## ldh r22,6(r7)
        ## beq r17,r22,cursor
#check if its an enter
        beq r16,r20,next11
#this is a normal character draw it onto the screen and increment the location in the char buffer
        stbio r16,0(r21)
        addi r21,r21,1

#increment buffer pointer
#increment the Nth character from memory
next11: addi r4,r4,1
        addi r17,r17,1
        br loop
#drawing a cursor based on blinking every half second
cursor:
        movia r7,blink
        ldb r7,(r7)
        beq r7,r0,dtdraw
        movi r28, 127
        beq r16,r20,specialcase
        stbio r28,0(r21)
        addi r21,r21,1
        br next11
specialcase:
        sub r21,r21,r15
        stbio r28,0(r21)
        ## addi r21,r21,1
        add r21,r21,r15
        br next11
#draw what should be drawn there not the cursor
dtdraw: beq r16,r20,next11
        stbio r16,0(r21)
        addi r21,r21,1
        br next11
#check if the cursor is at pre and draw it if need be
preskip:
        movia r7,blink
        ldb r7,(r7)
        beq r7,r0,skip
        movi r28, 127
        stbio r28,0(r21)
#same procedure as above however this time dealing with post buffer memory until you read a null/zero char
skip:
        ldb r16,(r6)
        addi r19,r19,1
        beq r0,r16,end
        bne r20,r16,next2
        subi r19,r19,129
        muli r19,r19,-1
        add  r21,r21,r19
        movi r19,0
        br next22
#check if the current position is where a cursor is
next2:  movia r7,position
        ldh r22,(r7)
        beq r17,r22,cursor2
        ldh r22,2(r7)
        beq r17,r22,cursor2
        stbio r16,0(r21)
        ## for cursors 3 and 4
        ## ldh r22,4(r7)
        ## beq r17,r22,cursor2
        ## ldh r22,6(r7)
        ## beq r17,r22,cursor2
        addi r21,r21,1

next22: addi r6,r6,1
        addi r17,r17,1
        movia r7,position
        ldh r22,(r7)
        beq r17,r22,endcursor
        ldh r22,2(r7)
        beq r17,r22,endcursor
        ## cursors 3 and 4
        ## ldh r22,4(r7)
        ## beq r17,r22,endcursor
        ## ldh r22,6(r7)
        ## beq r17,r22,endcursor
        br skip
#animation of cursor every 1 second
cursor2:
        movia r7,blink
        ldb r7,(r7)
        beq r7,r0,dtTdraw
        movi r28,127
        stbio r28,0(r21)
        addi r21,r21,1
        br next22
dtTdraw: stbio r16,0(r21)
        addi r21,r21,1
        br next22
endcursor:
        movia r7,blink
        ldb r7,(r7)
        beq r7,r0,skip
        movi r28,127
        stbio r28,0(r21)
        br skip
end:
        ldw r15,(sp)
        ldw r16,4(sp)
        ldw r17,8(sp)
        ldw r18,12(sp)
        ldw r19,16(sp)
        ldw r20,20(sp)
        ldw r21,24(sp)
        ldw ra,28(sp)
        addi sp,sp,32

        ret

        ## functiont to clear screen by pixels
        .global clearscreen
clearscreen:
        subi sp,sp,28
        stw r16,(sp)
        stw r17,4(sp)
        stw r18,8(sp)
        stw r19,12(sp)
        stw r20,16(sp)
        stw r21,20(sp)
        stw ra,24(sp)

        movia r7,ADDR_VGA
        movi r19,320
        movi r18,239
        movi r16,-1

#go through nested loop while y<320
outsideloop_s:
        beq r16,r18,done_clrscr
        addi r16,r16,1
        movi r17,0
#while x<240
innerloop_s:
        beq r17,r19,outsideloop_s
#memory address = 2x+1024y+base
        muli r20,r17,2
        muli r21,r16,1024

        add r20,r20,r21
        add r20,r20,r7
        sthio r0,0(r20)
        addi r17,r17,1
        br innerloop_s

done_clrscr:
        ldw r16,(sp)
        ldw r17,4(sp)
        ldw r18,8(sp)
        ldw r19,12(sp)
        ldw r20,16(sp)
        ldw r21,20(sp)
        ldw ra,24(sp)
        addi sp,sp,28
        ret

##         .include "header.s"

##         .global drawscreen
## drawscreen:
##         subi sp,sp,28
##         stw r16,(sp)
##         stw r17,4(sp)
##         stw r18,8(sp)
##         stw r19,12(sp)
##         stw r20,16(sp)
##         stw r21,20(sp)
##         stw ra,24(sp)

##         movia r7,pre
##         ldh r18,(r7)
##         movia r7,post
##         ldh r19,(r7)
##         movia r4,buffer
##         add r5,r18,r4
##         add r6,r19,r4

##         movia r7,ADDR_CHAR
##         movi r19,128
##         movi r18,60
##         movi r16,-1

## cleartext:
## outsideloop:
##         beq r16,r18,text
##         addi r16,r16,1
##         movi r17,0

## innerloop:
##         beq r17,r19,outsideloop

##         muli r21,r16,128

##         add r20,r17,r21
##         add r20,r20,r7

##         movi r21,' '
##         sthio r21,0(r20)
##         addi r17,r17,1
##         br innerloop
       
## text:
##         movi r17,0
##         movi r18,80
##         movi r19,0
##         movi r20,10
##         movia r21,ADDR_CHAR

## loop:
##         beq r4,r5,preskip
##         bne r19,r18,here
##         movi r19,0
##         addi r21,r21,48
## here:
##         ldb r16,(r4)
##         addi r19,r19,1
##         bne r20,r16,next
##         subi r19,r19,129        # -1 extra
##         muli r19,r19,-1
##         add  r21,r21,r19
##         movi r19,0
## ##        br next11
        
## next:         
##         movia r7,position
##         ldh r22,(r7)     
##         beq r17,r22,cursor
##         ldh r22,2(r7)    
##         beq r17,r22,cursor
##         beq r16,r20,next11
##         stbio r16,0(r21)
##         addi r21,r21,1


## next11: addi r4,r4,1
##         addi r17,r17,1                
##         br loop
## cursor:
##         movia r7,blink
##         ldb r7,(r7)
##         beq r7,r0,dtdraw
##         movi r28, 127
##         stbio r28,0(r21)
##         addi r21,r21,1
##         br next11

## dtdraw: beq r16,r20,next11
##         stbio r16,0(r21)
##         addi r21,r21,1
##         br next11
## preskip:
##         movia r7,blink
##         ldb r7,(r7)
##         beq r7,r0,skip
##         movi r28, 127
##         stbio r28,0(r21)
##         br skip
## skip:
##         ldb r16,(r6)
##         addi r19,r19,1        
##         beq r0,r16,end
##         bne r20,r16,next2
##         subi r19,r19,129
##         muli r19,r19,-1
##         add  r21,r21,r19
##         movi r19,0
##         br next22
        
## next2:  movia r7,position
##         ldh r22,(r7)
##         beq r17,r22,cursor2
##         ldh r22,2(r7)    
##         beq r17,r22,cursor2
##         stbio r16,0(r21)
##         addi r21,r21,1
       
## next22: addi r6,r6,1
##         addi r17,r17,1 
##         movia r7,position
##         ldh r22,(r7)
##         beq r17,r22,endcursor
##         ldh r22,2(r7)    
##         beq r17,r22,endcursor
##         br skip
## cursor2:
##         movia r7,blink
##         ldb r7,(r7)
##         beq r7,r0,dtTdraw
##         movi r28,127
##         stbio r28,0(r21)
##         addi r21,r21,1       
##         br next22
## dtTdraw: stbio r16,0(r21)
##         addi r21,r21,1
##         br next22
## endcursor:
##         movia r7,blink
##         ldb r7,(r7)
##         beq r7,r0,skip
##         movi r28,127
##         stbio r28,0(r21)
##         br skip
## end:
##         ldw r16,(sp)
##         ldw r17,4(sp)
##         ldw r18,8(sp)
##         ldw r19,12(sp)
##         ldw r20,16(sp)
##         ldw r21,20(sp)
##         ldw ra,24(sp)
##         addi sp,sp,28

##         ret

##         ## functiont to clear screen by pixels
##         .global clearscreen
## clearscreen:
##         subi sp,sp,28
##         stw r16,(sp)
##         stw r17,4(sp)
##         stw r18,8(sp)
##         stw r19,12(sp)
##         stw r20,16(sp)
##         stw r21,20(sp)
##         stw ra,24(sp)

##         movia r7,ADDR_VGA
##         movi r19,320
##         movi r18,239
##         movi r16,-1


## outsideloop_s:
##         beq r16,r18,done_clrscr
##         addi r16,r16,1
##         movi r17,0

## innerloop_s:
##         beq r17,r19,outsideloop_s

##         muli r20,r17,2
##         muli r21,r16,1024

##         add r20,r20,r21
##         add r20,r20,r7
##         sthio r0,0(r20)
##         addi r17,r17,1
##         br innerloop_s

## done_clrscr:
##         ldw r16,(sp)
##         ldw r17,4(sp)
##         ldw r18,8(sp)
##         ldw r19,12(sp)
##         ldw r20,16(sp)
##         ldw r21,20(sp)
##         ldw ra,24(sp)
##         addi sp,sp,28
##         ret
