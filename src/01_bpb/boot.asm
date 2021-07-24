;boot()
Entry:
        jmp     IPL                                     ;
BPB:
        nop                                             ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; BPB( BIOS Parameter Block )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        times ( 90 - ($ - $$)) db 0x90                  ; BPB領域を確保
IPL:
        jmp     $                                       ; 繰り返す
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; IPL( Initial Program Loader )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        times (510 - ($ - $$)) db 0x00                  ; IPL領域を確保
        db      0x55 , 0xAA                             ; ブートフラグを書き込み

;(関数の概要(ブートプログラムです))
; 1. BPBはOSが活用するデータの集合領域ですので早速IPL（初期化プログラム）へ移動します
; 2. かっこいいのでnop書いておきました
; 3. 今回はBPB領域を90バイトとし90バイト目までtimes疑似操作で0x90つまりnopで浸します(BPB
;    領域を実行してもシステムを暴走させないため)
; 4. 何もしないブーロプログラムをつくりたいので９０バイト目のjmpをずっと繰り返します
; 5. ブートプログラムは５１２バイトに収めることをしたいので一先ず５１０バイト目まで0で浸します
; 6. 最後にブートフラグ、0x55と0xAAを書き込んでブートプログラムの完成です
