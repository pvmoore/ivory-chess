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
   
/+
alias nibbleboard = uint[8];

Piece pieceAt(ref nibbleboard bb, square sq) {
    auto a = sq >>> 3;
    auto b = (sq & 7) << 2; 
    return ((bb[a] >>> b) & PIECE_MASK).as!Piece;
}
Side sideAt(ref nibbleboard bb, square sq) {
    auto a = sq >>> 3;
    auto b = ((sq & 7) << 2) + 3; 
    return ((bb[a] >>> b) & 1).as!Side;
}
uint get(ref nibbleboard bb, square sq) {
    auto a = sq >>> 3;
    auto b = (sq & 7) << 2; 
    return (bb[a] >>> b) & 15;
}
void set(ref nibbleboard bb, square sq, Piece p, Side s) {
    uint a = sq >>> 3;
    uint b = (sq & 7) << 2;
    bb[a] &= ~(15 << b);
    bb[a] |= ((p | (s<<3)) << b);
}
void setEmpty(ref nibbleboard bb, square sq) {
    uint a = sq >>> 3;
    uint b = (sq & 7) << 2;
    bb[a] &= ~(15 << b);
}
void move(ref nibbleboard bb, square fromSq, square toSq) {
    auto f1 = fromSq >>> 3;
    auto f2 = (fromSq & 7) << 2; 

    auto t1 = toSq >>> 3;
    auto t2 = (toSq & 7) << 2; 

    uint value = (bb[f1] >>> f2) & 15;

    bb[t1] &= ~(15 << t2);
    bb[t1] |= (value << t2);

    bb[f1] &= ~(15 << f2);
}
+/

