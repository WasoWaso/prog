;boot()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; マクロ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        %include "/home/m8ku/prog/src/include/macro.asm"
        %include "/home/m8ku/prog/src/include/define.asm"

        ORG     BOOT_LOAD                               ; プログラムの開始位置を設定
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; エントリポイント
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
entry:

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; BPB( BIOS Parameter Block )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp     IPL                                     ; IPLラベルへ移動
        times  90 - ( $ - $$ ) db 0x90                  ; BPB領域を確保
IPL:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; IPL( Initial Program Loader )
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cli                                             ; //割り込み禁止

        mov     ax , 0x0000                             ; AX=0x0000
        mov     ds , ax                                 ; DS=0x0000
        mov     es , ax                                 ; ES=0x0000
        mov     ss , ax                                 ; SS=0x0000
        mov     sp , BOOT_LOAD                          ; SP=0x7c00

        sti                                             ; //割り込み許可

        mov     [BOOT + drive.no] , dl                  ; ドライブ番号
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 文字列を表示
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cdecl   puts , .s0                              ; puts(.s0);//Booting...

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 次の５１２バイトを読み込む
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov     bx , BOOT_SECT - 1                      ; BX = 残りのブートセクタ数
        mov     cx , BOOT_LOAD + SECT_SIZE              ; CX = 次のロードアドレス

        cdecl   read_chs, BOOT,  bx, cx                 ; セクタ読み出し関数の発行


        cmp     ax , bx                                 ; if(AX!=BX)
.10Q:   jz      .10E                                    ; {
.10T:   cdecl   puts, .e0                               ; puts(.e0); //メッセージ
        call    reboot                                  ; reboot();  //再起動
.10E:                                                   ; }

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 次のステージへ移行
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp     stage_2                                 ; ブート処理の第二ステージ

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; データ
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.s0     db  "Booting..." , 0x0A , 0x0D , 0              ;
.e0     db  "Error:sector read", 0                      ;

        align       2       , db 0                      ;
BOOT:
        istruc  drive
            at drive.no,    dw  0                       ; ドライブ番号
            at drive.cyln,  dw  0                       ; S:シリンダー
            at drive.head,  dw  0                       ; H:ヘッド
            at drive.sect,  dw  2                       ; S:セクタ
        iend

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; モジュール
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    %include "/home/m8ku/prog/src/modules/real/puts.asm"
    %include "/home/m8ku/prog/src/modules/real/reboot.asm"
    %include "/home/m8ku/prog/src/modules/real/read_chs.asm"

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ブートフラグの設定 (先頭512バイトの終了)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;p;;;;;;;;;;;;;;;;;;;;;;;;;;
        times 510 - ($ - $$) db 0x00                    ; IPL領域を浸す
        db      0x55 , 0xAA                             ; 0x55 0xAA

    ;****************************************************
    ; リアルモード時に取得した情報 絶対参照するため0x7E00へ配置
    ;****************************************************
FONT:
.seg:   dw  0                                           ; フォントadrの保存先を
.off:   dw  0
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; モジュール (先頭512バイト以降に配置)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    %include "/home/m8ku/prog/src/modules/real/itoa.asm"
    %include "/home/m8ku/prog/src/modules/real/get_drive_param.asm"
    %include "/home/m8ku/prog/src/modules/real/get_font_adr.asm"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ブートプログラムの第二ステージ ▽
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stage_2:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 文字列を表示
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cdecl puts, .s0                                 ; puts(.s0);

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; ドライブ情報を取得
        ;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cdecl   get_drive_param, BOOT                   ; get_drive_param(BOOT);
        cmp     ax , 0                                  ; if (0 == AX)
.10Q:   jnz     .10E                                    ; {
.10T:   cdecl   puts, .e0                               ;   puts(.e0);
        call    reboot                                  ;   reboot(); //再起動
.10E:                                                   ; }

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; ドライブ情報を表示
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov     ax , [BOOT + drive.no]                  ; AX = ブートドライブ
        cdecl   itoa, ax, .p1, 2, 16, 0b0100            ;

        mov     ax , [BOOT + drive.cyln]                ; AX = シリンダ(トラック)数
        cdecl   itoa, ax, .p2, 4, 16, 0b0100            ;

        mov     ax , [BOOT + drive.head]                ; AX = ヘッド数
        cdecl   itoa, ax, .p3, 2, 16, 0b0100            ;

        mov     ax , [BOOT + drive.sect]                ; AX=トラックあたりのセクタ数
        cdecl   itoa, ax, .p4, 2, 16, 0b0100            ;

        cdecl   puts, .s2                               ; puts(.s2); //情報を表示

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 次のステージへ移行
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp     stage_3rd                               ; 第三ステージへ移行

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; データ
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.s0     db  "2nd stage...", 0x0A, 0x0D, 0
.s2     db  " Drive:0x"
.p1     db  "--, C:0x"
.p2     db  "----, H:0x"
.p3     db  "--, S:0x"
.p4     db  "--", 0x0A, 0x0D, 0
.e0     db  "Error:Can't get parameter.", 0

    ;****************************************************
    ; ブートプログラムの第三ステージ ▽
    ;****************************************************
stage_3rd:
        ;************************************************
        ; 文字列を表示
        ;************************************************
        cdecl   puts, .s1                               ; puts(.s1);

        ;************************************************
        ; プロテクトモードで使用するフォントは、BIOSに内蔵された
        ; ものを流用する
        ;************************************************
        cdecl   get_font_adr, FONT                      ; //BIOSフォントアドレスを取得

        ;************************************************
        ; フォントアドレスの表示
        ;************************************************
        cdecl   itoa, word [FONT.seg], .p1, 4, 16, 0b0100
        cdecl   itoa, word [FONT.off], .p2, 4, 16, 0b0100
        cdecl   puts, .s2

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; 数値を表示
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        mov     ax , 3939                               ;
        cdecl itoa, ax, .s0, 8, 10, 0b0001              ;
        cdecl puts, .s0                                 ; puts(.s1);

        ;************************************************
        ; プログラムの終了
        ;************************************************
        jmp     $                                       ; while (1); //　∞

.s0     db  "--------", 0x0A, 0x0D, 0                   ;
.s1     db  "3rd stage...", 0x0A, 0x0D, 0               ;

.s2     db  " Font Address="
.p1     db  "ZZZZ:"
.p2     db  "ZZZZ", 0x0A, 0x0D, 0                       ;
        db  0x0A, 0x0D, 0                               ;

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; パディング (このファイルは8Kバイトとする)
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        times (BOOT_SIZE - ($ - $$)) db 0x00            ; 8KByte
