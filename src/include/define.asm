;define()
        BOOT_LOAD       equ     (0x7C00)                ; ブートプログラムロード位置
        BOOT_SIZE       equ     (1024 * 8)              ; ブートコードサイズ
        SECT_SIZE       equ     (512)                   ; セクタサイズ 512B
        BOOT_SECT       equ     (BOOT_SIZE / SECT_SIZE) ; ブートプログラムのセクタ数

; (定義の概要)
; 0. それぞれdefineしています、ソースコードにうまく取り込もう