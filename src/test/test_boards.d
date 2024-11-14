module test.test_boards;

import std.stdio                : writefln;
import std.datetime.stopwatch   : StopWatch, AutoStart;
import std.random               : uniform, uniform01, Mt19937;

import ivory.all;

void testBoards() {
    Mt19937 rng;
    rng.seed(1);

    square[] squares;
    Piece[] pieces;
    Side[] sides;
    foreach(i; 0..1000) {
        squares ~= uniform(0, 64);
        pieces ~= (uniform(0,6) + 1).as!Piece;
        sides ~= uniform01 > 0.5 ? Side.WHITE : Side.BLACK;
    }
    // writefln("squares = %s", squares);
    // writefln("pieces  = %s", pieces);
    // writefln("sides   = %s", sides);

    testByteboard(squares, pieces, sides);
    testNibbleboard(squares, pieces, sides);
}

void testByteboard(square[] squares, Piece[] pieces, Side[] sides) {
    auto watch = StopWatch(AutoStart.no);

    byteboard bb;

    watch.start();
    foreach(i; 0..1000000) {
        foreach(j; 0..squares.length) {
            set(bb, squares[j], pieces[j], sides[j]);
        }
    }
    watch.stop();
    writefln("bb = %s", iota(0, 64).map!(i=>fenChar(pieceAt(bb, i), sideAt(bb, i))).array);
    writefln("Elapsed %.2f ms", watch.peek().total!"nsecs" / 1_000_000.0);
}

void testNibbleboard(square[] squares, Piece[] pieces, Side[] sides) {
    auto watch = StopWatch(AutoStart.no);

    nibbleboard bb;

    watch.start();
    foreach(i; 0..1000000) {
        foreach(j; 0..squares.length) {
            set(bb, squares[j], pieces[j], sides[j]);
        }
    }
    watch.stop();
    writefln("bb = %s", iota(0, 64).map!(i=>fenChar(pieceAt(bb, i), sideAt(bb, i))).array);
    writefln("Elapsed %.2f ms", watch.peek().total!"nsecs" / 1_000_000.0);
}
