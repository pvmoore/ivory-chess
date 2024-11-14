module ivory.all;

public:

import std.stdio        : writefln, writef;
import std.format       : format;
import std.algorithm    : find, any, sort;
import std.math         : abs;

import common           : as, frontOrElse, Ansi, ansiWrap, throwIf, throwIfNot;

import ivory.board;
import ivory.Castling;
import ivory.FEN;
import ivory.Game;
import ivory.Ivory;
import ivory.Move;
import ivory.MoveList;
import ivory.Piece;
import ivory.Side;

import ivory.mailbox;

enum MAX_MOVES = 1024;
enum MAX_PLY   = 32;

struct stack(T,uint CAP) {
public:
    void push(T v) { 
        assert(pos < CAP, "push() %s >= %s".format(pos, CAP));
        array[pos++] = v; 
    }
    T pop() { 
        assert(pos > 0, "pop() stack is empty");
        return array[--pos]; 
    }
    uint length() { return pos; }
private:
    T[CAP] array;
    uint pos;
}

T maxOf(T)(T a, T b) {
    return a > b ? a : b;
}
T minOf(T)(T a, T b) {
    return a < b ? a : b;
}
