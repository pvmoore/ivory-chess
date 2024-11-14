module ivory.board;

import ivory.all;

alias square = int;
enum NO_SQUARE = -1;

/** 
 *   7| 56 57 58 59 60 61 62 63
 *   6| 48 49 50 51 52 53 54 55
 * r 5| 40 41 42 43 44 45 46 47
 * a 4| 32 33 34 35 36 37 38 39
 * n 3| 24 25 26 27 28 29 30 31
 * k 2| 16 17 18 19 20 21 22 23
 *   1| 08 09 10 11 12 13 14 15
 *   0| 00 01 02 03 04 05 06 07
 *    -------------------------
 *       a  b  c  d  e  f  g  h
 *       0  1  2  3  4  5  6  7
 *               file
 */
alias byteboard = ubyte[64];

enum PIECE_MASK = 0b0111;
enum SIDE_MASK  = 0b1000;

uint file(square sq) { return sq & 7; }
uint rank(square sq) { return sq >>> 3; }

char rankChar(square sq) { return (rank(sq) + '1').as!char; }
char fileChar(square sq) { return (file(sq) + 'a').as!char; }
 
string algebraic(square sq) {
    return "%s%s".format(fileChar(sq), rankChar(sq));
}

/** 
 * Todo - describe bit positions -> file and rank
 */
alias bitboard = ulong;

/** 
 * Todo - is this better as ulong[4] or ubyte[32] ?
 */
alias nibbleboard = ulong[4];
