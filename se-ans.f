\ Sistemi Embedded 18/19
\ Daniele Peri - Universita' degli Studi di Palermo
\
\ Some definitions for ANS compliance
\
\ v. 20181215

: JF-HERE   HERE ;
: JF-CREATE   CREATE ;
: JF-FIND   FIND ;
: JF-WORD   WORD ;

: HERE   JF-HERE @ ;
: ALLOT   HERE + JF-HERE ! ;

: [']   ' LIT , ; IMMEDIATE
: '   JF-WORD JF-FIND >CFA ; 

: CELL+  4 + ;

: ALIGNED   3 + 3 INVERT AND ;
: ALIGN JF-HERE @ ALIGNED JF-HERE ! ;

: DOES>CUT   LATEST @ >CFA @ DUP JF-HERE @ > IF JF-HERE ! ; 

: CREATE   JF-WORD JF-CREATE DOCREATE , ;

