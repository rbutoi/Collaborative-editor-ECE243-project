#include <stdint.h>

extern int8_t n, shift;

static const uint8_t charmap[] =
    "................"
    ".....q1...zsaw2."
    ".cxde43.. vftr5."
    ".nbhgy6...mju78."
    ".,kio09.../l;p-."
    "..'.[=.....].\\.." ;

static const uint8_t charmap_shift[] =
    "................"
    ".....Q!...ZSAW@."
    ".CXDE$#.. VFTR%."
    ".NBHGY^...MJU&*."
    ".<KIO)(..>?L:P_."
    "..\".{+.....}.|.." ;
/*
  handy guide

  a 10
  b 11
  c 12
  d 13
  e 14
  f 15
*/

uint8_t decode(uint8_t scancode)
{
    switch (scancode) {
    case 0x6b: return 0;
    case 0x74: return 1;
    case 0x75: return 2;
    case 0x72: return 3;
    case 0x66: return 4;
    case 0x71: return 5;
    case 0xe0: return 6;
    case 0x5a: return 10;
        /* debugging: */
    case 0x05: n = 0; return 6;
    case 0x06: n = 1; return 6;
    case 0x04: n = 2; return 6;
    case 0x0c: n = 3; return 6;
    default:
        return shift ? charmap_shift[scancode] : charmap[scancode];
    }
}
