! Copyright (C) 2019 Alessandro Piras.
! See http://factorcode.org/license.txt for BSD license.
USING: lc3 locals math math.bitwise ;
IN: lc3.utils

: 2^16 ( -- y ) 0x10000 ;

:: nth-bit ( value n -- b ) value n n bit-range ;

:: mask ( msb -- mask ) 0xFFFF msb 16 shift-mod ;
:: sign-extend ( value msb -- sextvalue )
    msb mask ! bitmask
    value msb nth-bit *
    value bitor ;


: u16mod ( x -- y ) 2^16 mod 2^16 + 2^16 mod ;
: u16+ ( x y -- x+y ) + u16mod ;
: u16* ( x y -- x*y ) * u16mod ;
: u16- ( x y -- x-y ) - u16mod ;
: u16/ ( x y -- x/y ) / u16mod ;
