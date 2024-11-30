module test.test_boards;

import std.stdio                : writefln;
import std.datetime.stopwatch   : StopWatch, AutoStart;
import std.random               : uniform, uniform01, Mt19937;

import ivory.all;

void testBoards() {
    Mt19937 rng;
    rng.seed(1);

    square[] squares;
    square[] squares2;
    square[] squares3;
    Piece[] pieces;
    Side[] sides;
    foreach(i; 0..1000) {
        squares ~= uniform(0, 64);
        squares2 ~= uniform(0, 64);
        squares3 ~= uniform(0, 64);
        pieces ~= (uniform(0,6) + 1).as!Piece;
        sides ~= uniform01 > 0.5 ? Side.WHITE : Side.BLACK;
    }

    testByteboard(squares, pieces, sides);
    testBitboard(squares, pieces, sides);

    testBitboardFunctions();

    
}

void testByteboard(square[] squares, Piece[] pieces, Side[] sides) {
    auto watch = StopWatch(AutoStart.no);

    byteboard bb;

    watch.start();
    foreach(i; 0..1000000) {
        foreach(j; 0..squares.length) {
            square sq = squares[j];
            Side s = sides[j];
            Piece p = pieces[j];
            set(bb, sq, p, s);
        }
    }
    watch.stop();
    writefln("bb = %s", iota(0, 64).map!(i=>fenChar(pieceAt(bb, i), sideAt(bb, i))).array);
    writefln("Elapsed %.2f ms", watch.peek().total!"nsecs" / 1_000_000.0);
}
void testBitboard(square[] squares, Piece[] pieces, Side[] sides) {
    auto watch = StopWatch(AutoStart.no);

    bitboard[2] sideBoards;
    // [0] white;
    // [1] black;

    bitboard[6] pieceBoards;
    // [0] pawns;
    // [1] bishops;
    // [2] knights;
    // [3] rooks;
    // [4] queens;
    // [5] kings;

    watch.start();
    foreach(i; 0..1000000) {
        foreach(j; 0..squares.length) {
            square sq = squares[j];
            uint s = sides[j].as!uint;
            uint p = pieces[j].as!uint - 1;

            set(sideBoards[s], sq);
            set(pieceBoards[p], sq);
        }
    }
    watch.stop();
    writefln("Elapsed %.2f ms", watch.peek().total!"nsecs" / 1_000_000.0);
}
void testBitboardFunctions() {
    bitboard bb;

    set(bb, 0);
    throwIf(bb != 1);

    set(bb, 1);
    throwIf(bb != 3);

    set(bb, 3);
    throwIf(bb != 0b1011);

    unset(bb, 1);
    throwIf(bb != 0b1001);

    move(bb, 3, 5);
    throwIf(bb != 0b100001);

    move(bb, 1, 2);
    throwIf(bb != 0b100001);

    move(bb, 1, 0);
    throwIf(bb != 0b100000);

    move(bb, 5, 4);
    throwIf(bb != 0b010000);

    throwIf(bb.pop() != 4);
    throwIf(bb != 0); 

    bb.set(33);
    bb.set(55);
    throwIf(bb != ((1L<<33) | (1L<<55)));

    throwIf(bb.pop() != 33);
    throwIf(bb != (1L<<55));

    throwIf(bb.pop() != 55);
    throwIf(bb != 0);

    writefln("ok"); 
}

