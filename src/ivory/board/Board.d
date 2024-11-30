module ivory.board.Board;

import ivory.all;

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
alias bitboard  = ulong;
alias square    = int;

enum NO_SQUARE  = -1;
enum PIECE_MASK = 0b0111;
enum SIDE_MASK  = 0b1000;

// square functions
//──────────────────────────────────────────────────────────────────────────────────────────────────
uint file(square sq) { return sq & 7; }
uint rank(square sq) { return sq >>> 3; }
uint swapRank(square sq) { return 7 - (sq >>> 3); }
square mirroredHorizontal(square sq) { return (56 - (sq & 0b111000)) + file(sq); }
square rotated180(square sq) { return 63 - sq; }

char rankChar(square sq) { return (rank(sq) + '1').as!char; }
char fileChar(square sq) { return (file(sq) + 'a').as!char; }
 
string algebraic(square sq) {
    return "%s%s".format(fileChar(sq), rankChar(sq));
}

// byteboard functions
//──────────────────────────────────────────────────────────────────────────────────────────────────
Piece pieceAt(ref byteboard bb, square sq) {
    return (bb[sq] & PIECE_MASK).as!Piece;
}
Side sideAt(ref byteboard bb, square sq) {
    return (bb[sq] >>> 3).as!Side;
}
uint get(ref byteboard bb, square sq) {
    return bb[sq];
}
void set(ref byteboard bb, square sq, Piece p, Side s) {
    bb[sq] = (p | (s<<3)).as!ubyte;
}
void setEmpty(ref byteboard bb, square sq) {
    bb[sq] = 0;
}
void move(ref byteboard bb, square fromSq, square toSq) {
    bb[toSq] = bb[fromSq];
    bb[fromSq] = 0;
}

// bitboard functions
//──────────────────────────────────────────────────────────────────────────────────────────────────
void set(ref bitboard bb, square sq) {
    bb |= (1L<<sq);
}
void unset(ref bitboard bb, square sq) {
    bb &= ~(1L<<sq);
}
void move(ref bitboard bb, square from, square to) {
    ulong bit = (bb >>> from) & 1L;
    bb &= ~(1L << to);
    bb |= (bit << to);
    bb &= ~(1L << from);
}
bool isSet(bitboard bb, square sq) {
    return (bb & (1L<<sq)) != 0L;
}
bool isUnset(bitboard bb, square sq) {
    return (bb & (1L<<sq)) == 0L;
}
/** Unsets the first set bit (from least significant to most significant) and returns the bit position */
uint pop(ref bitboard bb) {
    uint i = bsf(bb);
    bb.unset(i);
    return i;
}
