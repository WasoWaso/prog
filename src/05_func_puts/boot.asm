;boot()

        ORG     0x7c00                                  ;

        %include "/home/m8ku/prog/src/include/macro.asm"; マクロ

Entry:
        jmp     IPL                                     ; IPLラベルへ移動
BPB:
        BOOT_LOAD       equ         0x7c00              ; BOOT_LOAD=0x7c00

        nop                                             ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; BPB( BIOS Parameter Block )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        times  90 - ( $ - $$ ) db 0x90                  ; BPB領域を確保
IPL:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; IPL( Initial Program Loader )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cli                                             ; 割り込み禁止

        mov     ax , 0x0000                             ; AX=0x0000
        mov     ds , ax                                 ; DS=0x0000
        mov     es , ax                                 ; ES=0x0000
        mov     ss , ax                                 ; SS=0x0000
        mov     sp , BOOT_LOAD                          ; SP=0x7c00

        sti                                             ; 割り込み許可

        mov     [BOOT.DRIVE] , dl                       ;

        cdecl   puts , .s0                              ;

        jmp     $                                       ; 処理の終了

.s0     db  "Booting..." , 0x0A , 0x0D , 0              ; データ


        align       2       , db 0                      ;
BOOT:
        .DRIVE:
            dw      0x0000                              ; ドライブ番号

    %include "/home/m8ku/prog/src/modules/real/puts.asm"; モジュール

        times 510 - ($ - $$) db 0x00                    ; IPL領域を浸す
        db      0x55 , 0xAA                             ; 0x55 0xAA


;(関数の概要(ブートプログラムです))
; 0. ソースファイル中の%includeで今回利用する'puts'関数と'macro'マクロをそれぞれ取り込みます
; 1. ORGディレクティブ命令でプログラムのロードアドレス指定を行います
; 2. BPBはOSが活用するデータの集合領域ですので早速IPL（初期化プログラム）へ移動します
; 3. 後にspに書き込む値(0x7c00)をBPB領域にequで定数として書き込んでおきました
; 4. かっこいいのでnop書いておきました
; 5. 今回はBPB領域を90バイトとし90バイト目までtimes疑似操作で0x90つまりnopで浸します(BPB
;    領域を実行してもシステムを暴走させないため)
; 6. 後にレジスタの設定や割り込み込みの設定も施すのでそのときに割り込みをされてしまうと困るので
;    cliでIFフラグを0にします
; 7. セグメントレジスタへの転送では即値を指定しないでレジスタを介して各セグメントレジスタに値を
;    書き込みます、AXに0を書き込んだらDS,ES,SSにAXレジスタの値を転送します、スタック領域は
;    ブートプログラムの真上に配置したいので先ほど設定したBOOT_LOAD (0x7x00)を付随します
; 8. 一通り設定を施したのでstiでIFフラグを1にします
; 9. BIOSがDLレジスタにドライブ番号を書き込んでくれるのでその値をメモリに保存しておきます
;10. macroファイル中のcdeclへputc関数と表示したい文字列をを渡して文字列を表示します
;11. jmp -2 を繰り返して繰り返しを施します
;12. 表示したい文字データを書き込みます、0x0AはLF(カーソルを一行下げて)0x0DはCR(カーソルを左
;    端へ戻します)
;13. 次に値を保存するための領域を作るので、アライメントを2バイトで合わせます
;14. 新たなグローバルラベルの中にローカルラベルで値を保存するための領域(さっきのDLレジスタの値
;    をほぞんするための領域)を2バイト空けておきます
;15. ブートプログラムは５１２バイトに収めることをしたいので一先ず５１０バイト目まで0で浸します
;16. 最後にブートフラグ、0x55と0xAAを書き込んでブートプログラムの完成です
