        .include "header.s"
        .section .data
d:
        .align 2
        .word 0xCAFEBABE        # hehe
pre:    .hword 0                # index to first empty space in gap
post:   .hword (BUFSIZE - 1)    # index to first valid char after gap
position:	 .hword 0,0,0,0 # positions, indexes into content, by n
lastn:  .byte -1                # last n to modify pre/post pointers
n:  	.byte -1                # which one am I?
breakignore:	 .byte 0        # flag to ignore break PS2 commands
blink:  .byte 0                 # cursor blink flag
buffer:	 .skip (BUFSIZE - 1)    # holds all text and empty space
        .byte 0                 # end with NULL char
shift:  .byte 0                 # whether shift is pressed

        .global d, pre, post, position, lastn, n, buffer, breakignore, blink, shift
