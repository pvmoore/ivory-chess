module test.test_perft;

import std.stdio                : writefln;
import std.datetime.stopwatch   : StopWatch, AutoStart;
import std.typecons             : Tuple, tuple;

import ivory.all;

// Performance Test Move Path Enumeration
// https://www.chessprogramming.org/Perft
// https://www.chessprogramming.org/Perft_Results
// https://gist.github.com/peterellisjones/8c46c28141c162d1d8a0f0badbc9cff9

// Testing with stockfish:
//   stockfish.exe
//   position fen <fenstr>
//   go perft <depth>

void testPerft() {
    writefln("################################");
    writefln(" Testing perft");
    writefln("################################");

    PerftScenario[] scenarios = OVERRIDE_SCENARIOS;
    if(scenarios.length == 0) {
        scenarios = loadPerftScenarios();
    }

    testMailboxPerft(scenarios);
    writefln("Perft tests passed%s", VALIDATE ? " (with validation)" : "");
}

private:

enum VERBOSE  = false;
enum VALIDATE = true;

/**
 * 10,400 ms -->  
 * 8,800 ms --> 
 * 8,200 ms 
 * (728 scenarios)
 */
enum MAX_NODES = 10_000_000;     

/**
 * 546,490 ms --> 
 * 434,000 ms -->
 * 420,000 ms
 * (764 scenarios)
 */
//enum MAX_NODES = ulong.max;      

__gshared PerftScenario[] SCENARIOS;
__gshared PerftScenario[] OVERRIDE_SCENARIOS = [

    // Start position
    //PerftScenario(1, 20, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")),
    //PerftScenario(2, 400, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")),
    //PerftScenario(3, 8902, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")),
    //PerftScenario(4, 197_281, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")),
    //PerftScenario(5, 4_865609, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")), // 150 ms
    //PerftScenario(6, 119_060_324, new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")), // 3800 ms

    // Kiwipete ;D1 48 ;D2 2039 ;D3 97862 ;D4 4085603 ;D5 193690690 ;D6 8031647685
    //PerftScenario(5, 193690690, new FEN("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")), // 5400 ms
    //PerftScenario(6, 8031647685, new FEN("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")), // 238678 ms
]; 

struct PerftScenario {
    uint depth;
    ulong nodes;
    FEN fen;
    string toString() { return "%s, depth %s, nodes %s".format(fen, depth, nodes); }
}

PerftScenario[] loadPerftScenarios() {
    import std.stdio  : lines, File;
    import std.array  : split;
    import std.string : indexOf, strip, startsWith;
    import std.conv   : to;

    if(SCENARIOS.length > 0) return SCENARIOS;

    PerftScenario[] scenarios;
    File f = File("resources/perft.epd", "rb");
    foreach(string line; lines(f)) {

        auto d1 = line.indexOf(";D1");
        throwIf(d1 == -1);

        string fenStr = line[0..d1].strip();
        string[] tokens = line[d1..$].split();
        throwIf(tokens.length % 2);

        for(int i=0; i<tokens.length; i += 2) {
            uint depth = tokens[i][2..$].to!uint;
            ulong nodes = tokens[i+1].to!ulong;

            if(nodes < MAX_NODES) {
                scenarios ~= PerftScenario(depth, nodes, new FEN(fenStr));
            }
        }
    }
    SCENARIOS = scenarios;
    return scenarios;
}

void testMailboxPerft(PerftScenario[] scenarios) {
    writefln("Using Mailbox position:");
    auto moveGen = new MBMoveGenerator();
    auto eval = new MBEvaluator();
    auto watch = StopWatch(AutoStart.no);

    foreach(i, s; scenarios) {
        auto pos = createMailboxPosition(s.fen);
        writefln("  [%s/%s] %s", i+1, scenarios.length, s);
        //writefln("%s", pos);

        ulong nodesFound = runSinglePerftTest(moveGen, eval, pos, s.depth, watch);

        throwIf(moveGen.getMoves().length != 0);
        throwIf(nodesFound != s.nodes, "Expected %s nodes but found %s", s.nodes, nodesFound);
        writefln("  Leaf nodes %s ✓", nodesFound);
    }
    writefln("Elapsed %.2f ms", watch.peek().total!"nsecs" / 1_000_000.0);
}

ulong runSinglePerftTest(MBMoveGenerator moveGen, MBEvaluator eval, MBPosition pos, int depth, ref StopWatch watch) {
    ulong totalNodes = 0;

    watch.start();

    enum SELECT_MOVE = -1;
    
    // Generate outer moves
    uint numMoves = moveGen.generate(pos, false);

    foreach(i; 0..numMoves) {
        Move m = moveGen.popMove();

        if(SELECT_MOVE != -1 && i != SELECT_MOVE) continue;

        static if(VERBOSE) writefln("  %s", m);
        pos.makeMove(m);
        ulong nodes = perft(moveGen, eval, pos, depth - 1);
        totalNodes += nodes;
        pos.unmakeMove();
        static if(VERBOSE) writefln("[%s] %s %s nodes", i, m, nodes);

        static if(VALIDATE) validate(pos, m);
    }

    watch.stop();
    return totalNodes;
}

ulong perft(MBMoveGenerator moveGen, MBEvaluator eval, MBPosition pos, int depth) {

    if(depth == 0) return 1;

    ulong leafNodes = 0;

    static if(VERBOSE) writefln("  %s\n%s", pos.getFEN(), pos);

    uint numMoves = moveGen.generate(pos, false);

    foreach(i; 0..numMoves) {
        Move m = moveGen.popMove();
        static if(VERBOSE) writefln("  %s", m);
        if(depth == 1) {
            leafNodes++;

            static if(VALIDATE) validate(pos, m);

            //int e = eval.evaluate(pos);
        } else {
            pos.makeMove(m);
            static if(VALIDATE) validate(pos, m);

            leafNodes += perft(moveGen, eval, pos, depth - 1);
            pos.unmakeMove();

            static if(VALIDATE) validate(pos, m);
        }
    }

    return leafNodes;
}
