             .title         "Glider Flasher"

;11/13/13
;Reverse engineered from glider.bin (was not open sourced. :( )
;RE'd by DG
;ORIGINAL SOURCE:
;03/05/06
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
read_byte:   .equ 020fh
wr_ppu:      .equ 020ch

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h
temp2:       .equ 00e2h
temp2_lo:    .equ 00e2h
temp2_hi:    .equ 00e3h
temp3:       .equ 00e4h
temp3_lo:    .equ 00e4h
temp3_hi:    .equ 00e5h
temp4:       .equ 00e6h
ferror:      .equ 00e7h
currbank:    .equ 00e8h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Glider Flasher"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #0f0h
             sta 08000h       ;reset flash ROM
             
             lda #0
             sta 04803h       ;input mode
             
             jsr read_byte
             sta temp3+1      ;receive number of sectors to erase
             
             lda #0
             sta ferror
             sta currbank
             
             lda #0ffh
             sta 04803h       ;output mode
             
er_loop:     ldx currbank
             jsr selbank
             jsr erasesector
             
             lda currbank
             jsr send_byte
             
             inc currbank
             lda currbank
             cmp temp3+1
             bne er_loop
             
             lda #0
             sta 04803h      ;input mode
             sta currbank
             
prog1:       ldx currbank
             jsr selbank      ;select desired bank
             lda #080h
             sta temp1+1
             lda #000h
             sta temp1+0      ;start of bank to program
             
prog2:       jsr read_byte
             sta temp2
             ldy #000h
             jsr dobyte
             inc temp1+0
             bne prog2
             inc temp1+1
             lda #0c0h
             cmp temp1+1
             bne prog2        ;program all 16K
             inc currbank
             dec temp3+1
             bne prog1
             
             lda #0ffh
             sta 4803h      ;set to output mode
             lda ferror
             jsr send_byte
             rts
             
             

;temp1 = address, acc =data
dobyte:      
             ldx #001h
             jsr selbank
             ldx #$AA 
             stx $9555      ;5555 = $AA


             ldx #000h
             jsr selbank
             ldx #$55 
             stx $AAAA      ;2AAA = $55
 
             ldx #001h
             jsr selbank
             ldx #$A0 
             stx $9555      ;5555 = $A0

             ldx currbank
             jsr selbank
             lda temp2
             sta (temp1),y    ;byte to program


;wtloop3:     lda 08000h
;             eor 08000h
;             bne wtloop3   ;check toggle
;             lda #000h
;             lda #0f0h
;             sta (temp1),y  ;reset to read mode
;             rts


             
wtloop2:     lda (temp1),y
             tax
             eor (temp1),y
             and #040h
             beq pgm_done     ;if bit clear, program is done (no toggle)
             txa
             and #020h
             beq wtloop2      ;if error bit clear, not done
             lda (temp1),y
             eor (temp1),y
             beq pgm_done
             lda #0f0h
             sta (temp1),y 
             sta ferror       ;we're fucked

pgm_done:    rts 


erasesector:       
             ldx #001h
             jsr selbank
             lda #0aah    ;erase sector command
             sta 09555h  ;write to 5555

             ldx #000h
             jsr selbank
             lda #055h
             sta 0Aaaah  ;write to 2AAA
             
              ldx #001h
             jsr selbank
            lda #080h
             sta 09555h  ;write to 5555

             ldx #001h
             jsr selbank
             lda #0aah
             sta 09555h   ;write to 5555

             ldx #000h
             jsr selbank
             lda #055h
             sta 0Aaaah   ;write to 2AAA

             ldx currbank
             jsr selbank
             lda #030h
             sta 08000h   ;write to 5555
             
wtloop:      lda 08000h
             eor 08000h
             bne wtloop
             lda #0f0h
             sta (temp1),y  ;reset to read mode
             rts


selbank:     lda 04800h
             ora #008h
             sta 04800h   ;enable the mapper, disable flash writing  exp0=1
             stx temp4
             asl temp4
             asl temp4
             ldx temp4
             stx 08000h
             and #0f7h
             sta 04800h   ;disable mapper, enable flash writing   exp0=0
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
