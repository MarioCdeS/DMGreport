include "gbhw.inc"

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

SECTION "Vblank", ROM0[$0040]
	reti

SECTION "LCDC", ROM0[$0048]
	reti

SECTION "Timer", ROM0[$0050]
	reti

SECTION "Serial", ROM0[$0058]
	reti

SECTION "Joypad", ROM0[$0060]
	reti
;----------- END INTERRUPT VECTORS -------------------

SECTION "ROM_entry_point", ROM0[$0100]	; ROM is given control from boot here
	nop
	jp	code_begins

;------------- BEGIN ROM HEADER ----------------
; The gameboy reads this info (before handing control over to ROM)
SECTION "rom header", ROM0[$0104]
	NINTENDO_LOGO
	ROM_HEADER	"  HELLO WORLD  "

; by convention, *.asm files add code to the ROM when included. *.inc files
; do not add code. They only define constants or macros. The macros add code
; to the ROM when called

include	"ibmpc1.inc"	; used to generate ascii characters in our ROM
include "memory.asm"	; used to copy Monochrome ascii characters to VRAM

code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM

	call	lcd_Stop

	; load ascii tiles (inserted below with chr_IBMPC1 macro) into VRAM
	ld	hl, ascii_tiles	; ROM address where we insert ascii tiles
	ld	de, _VRAM	; destination. Going to copy ascii to video ram
	; bc = byte-count. Aka how many bytes to copy
	ld	bc, ascii_tiles_end - ascii_tiles
	call	mem_CopyVRAM

	ld	a, [rLCDC]
	or	LCDCF_ON
	ld	[rLCDC], a	; turn LCD back on

	; need to set palette from [black & white] to [four shades of grey]
	ld	a, %11100100	; load pallette colors (to 4 shades)
	; each shade is 2 bits. So we set darkest to lightest using 11100100
	; 11 (black) 10 (dark) 01 (light) 00 (white)
	ld	[rBGP], a	; set background pallet
	ld	[rOBP0], a	; set sprite/obj pallete 0
	ld	[rOBP1], a	; set sprite/ obj pallete 1


.loop
	halt
	nop

	jp	.loop



; You can turn off LCD at any time, but it's bad for LCD if NOT done at vblank
lcd_Stop:
	ld	a, [rLCDC]	; LCD-Config
	and	LCDCF_ON	; compare config to lcd-on flag
	ret	z		; return if LCD is already off
.wait4vblank
	ldh	a, [rLY]   ; ldh is a faster version of ld if in [$FFxx] range
	cp	145  ; are we at line 145 yet?  (finished drawing screen then)
	jr	nz, .wait4vblank
.stopLCD
	ld	a, [rLCDC]
	xor	LCDCF_ON	; XOR lcd-on bit with lcd control bits. (toggles LCD off)
	ld	[rLCDC], a	; `a` holds result of XOR operation
	ret


; it's necessary to use a macro to generate characters. That way we can use
; custom characters to represent the 4 shades of grey
; (otherwise we'd have to use 0,1,2,3)
chr_custom: MACRO
	PUSHO	; push compiler options so that I can change the meaning of
	; 0,1,2,3 graphics to something better. Like  .-*@
	; change graphics characters. Start the line with ` (for graphics)
	; . = 00
	; - = 01
	; * = 10
	; @ = 11
	OPT	g.~*@

        DW      `...~~**@
        DW      `..~~**@@
        DW      `.~~**@@*
        DW      `~~**@@**
        DW      `~**@@**~
        DW      `**@@**~~
        DW      `*@@**~~.
        DW      `@@**~~..

	POPO	; restore compiler options

	DW	`00011223	; an example of using standard graphics


	ENDM


ascii_tiles:
	chr_custom
ascii_tiles_end:


; ================ QUESTIONS FOR STUDENT ===========================
; Why does "hello world!" Appear so far to the left of the screen?
;	Can you correct that?
; What happens if you shorten the "      hello world!          " to just
;	"hello world!"?    (Once done -- Where did the visual junk come from?)
; Can you blank the entire screen?
