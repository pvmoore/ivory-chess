module ivory.all;

public:

import core.bitop             : popcnt, bsf;
import core.atomic            : cas;

import std.stdio              : writefln, writef;
import std.format             : format;
import std.algorithm          : any, find, map, filter, sort, sum;
import std.math               : abs, isClose;
import std.range              : array, iota;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.random             : Mt19937, uniform, unpredictableSeed;

import common                 : as, flushConsole, frontOrElse, Ansi, ansiWrap, throwIf, throwIfNot, todo;

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

__gshared {
    Mt19937 rng;

    static this() {
        rng = Mt19937(unpredictableSeed());
    }
}
