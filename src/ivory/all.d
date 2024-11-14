module ivory.all;

public:

import std.stdio        : writefln, writef;
import std.format       : format;
import std.algorithm    : any, find, map, filter, sort;
import std.math         : abs;
import std.range        : array, iota;

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

version(LDC) {
    import ldc.llvmasm;
    import ldc.attributes;
    // https://wiki.dlang.org/LDC_inline_assembly_expressions
    // https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html

    uint rol(uint a, uint b) nothrow @nogc {
        return __asm!uint(`
            roll %cl, $0
        `, 
        "={eax},{eax},{ecx}",a,b);
    }
    uint ror(uint a, uint b) nothrow @nogc {
        return __asm!uint(`
            rorl %cl, $0
        `, 
        "={eax},{eax},{ecx}",
        a, b);
    }
}
