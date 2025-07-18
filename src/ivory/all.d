module ivory.all;

public:

import core.bitop             : popcnt, bsf;
import core.atomic            : cas;

import std.stdio              : writefln, writef;
import std.format             : format;
import std.algorithm          : any, find, map, filter, sort, sum, reverse;
import std.math               : abs, isClose;
import std.range              : array, iota, join;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.random             : Mt19937, uniform, unpredictableSeed;

import common.utils : as, todo, frontOrElse, throwIf, throwIfNot;
import common.io    : Ansi, ansiWrap, flushConsole;

import ivory.FEN;
import ivory.Game;
import ivory.Ivory;
import ivory.Position;
import ivory.Search;
import ivory.utils;

import ivory.board.Board;
import ivory.board.Castling;
import ivory.board.Piece;
import ivory.board.Side;

import ivory.eval.Evaluator;

import ivory.move.Move;
import ivory.move.MoveGenerator;
import ivory.move.MoveList;

import ivory.mailbox;

enum MAX_MOVES            = 1024;
enum MAX_PLY              = 128;
enum MAX_QUIESCENCE_DEPTH = 64;

// Initialise global static data:
//  - Random number generator
__gshared {
    Mt19937 rng;
    enum FIXED_SEED = true;

    static this() {
        static if(true)
        uint seed = FIXED_SEED ? 71 : unpredictableSeed();
        rng = Mt19937(seed);
    }
}
