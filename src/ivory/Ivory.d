module ivory.Ivory;

import std.string 	: split, indexOf;
import core.memory  : GC;

import ivory.all;
import test;

final class Ivory {
public:
    static NAME = "Ivory-Chess 0.1"; 

    this() {
        this.game = newGame();
    }
    void repl() {
        try{
            while(running) {
                string line = uciReadLine();
                string[] tokens = split(line).as!(string[]);
                if(tokens.length == 0) continue;

                handleCommand(tokens[0], line, tokens);
            }
        }catch(Throwable t) {
            writefln("error: %s", t);
        }
    }
private:
    Game game;
    bool running = true;

    void handleCommand(string command, string line, string[] tokens) {
        switch(command) {
            // ###############################################################################
            // UCI commands from GUI
            // ###############################################################################
            case "uci":
                uciWriteLine("id name %s", NAME);
                uciWriteLine("uciok");
                break;
            case "ucinewgame":
                handleUcinewgame(tokens, line);
                break;
            case "debug":
                // debug [ on | off ]
                break;
            case "isready":
                uciWriteLine("readyok");
                break;
            case "position": 
                handlePosition(tokens, line);
                break; 
            case "setoption":
                handleSetoption(tokens, line);
                break;
            case "go":
                handleGo(tokens, line);
                break;
            case "stop":
                break;
            case "quit":
                running = false;
                break;

            // ###############################################################################
            // Internal testing commands		
            // ###############################################################################
            case "perft": 
                testPerft();
                break;
            case "boards":
                testBoards();
                break;
            case "test":
                game = new Game(new FEN("rnbqkb1r/pppppppp/5n2/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 3"));
                writefln("testing %s", game.pos.getFEN());
                break;

            // ###############################################################################
            // Other internal commands		
            // ###############################################################################                    
            case "q":
                displayGCStats();
                running = false;
                break;
            case "show":
                displayGameState(game);
                break;
            case "u":
                if(game.ply > 0) {
                    game.unmakeMove();
                    displayGameState(game);
                } else {
                    writefln("No moves to undo");
                }
                break;
            case "restart":
                game.restart();
                displayGameState(game);
                break;
            case "fen":
                writefln("%s", game.pos.getFEN());
                break;
            case "s":
                Move m = game.findBestMove();
                writefln("best move: %s", m);
                break;
            default: 
                // Assume this is an algebraic move eg. a2a4
                Move move = Move.fromAlgebraic(command);
                auto gen = new MBMoveGenerator();
                gen.generate(game.pos, false);
                move = gen.getMoves().find(move.from(), move.to());

                //move = Move(60, 62, Move.Flag.CASTLE, Move.Flag2.NONE);

                if(game.isLegalMove(move)) {
                    game.makeMove(move);
                    displayGameState(game);
                } else {
                    writefln("Illegal move: %s", move);
                }
                break;
        }
        uciLogger.close();
    }

    Game newGame() {
        return new Game(FEN.startPosition());
    }
    void displayGameState(Game game) {
        writefln(game.pos.toString());
    }
    void displayGCStats() {
        auto stats = GC.stats();
        auto profileStats = GC.profileStats();
        writefln("#==========================================#");
        writefln("| GC Statistics");
        writefln("#==========================================#");
        writefln("| Used .............. %s MB (%000,s bytes)", stats.usedSize/(1024*1024), stats.usedSize);
        writefln("| Free .............. %s MB (%000,s bytes)", stats.freeSize/(1024*1024), stats.freeSize);
        writefln("| Collections ....... %s", profileStats.numCollections);
        writefln("| Collection time ... %.2f ms", profileStats.totalCollectionTime.total!"nsecs"/1000000.0);
        writefln("| Pause time ........ %.2f ms", profileStats.totalPauseTime.total!"nsecs"/1000000.0);
        writefln("#==========================================#");
    }
    /**
     * setoption name <id> [value <x>]
     */
    void handleSetoption(string[] tokens, string line) {
        writefln("set option ignored: %s", line);
    }
    /**
     * position [fen <fenstring> | startpos ]  moves <move1> .... <movei>
     */
    void handlePosition(string[] tokens, string line) {
        string sub = tokens.length > 1 ? tokens[1] : "";
        auto movesPos = line.indexOf("moves"); 
        string[] moves = movesPos == -1 ? null : line[movesPos+5..$].split();
        FEN fen;
        if("fen" == sub) {
            auto fenPos = line.indexOf("fen") + 4;
            string fenStr = line[fenPos..maxOf!long(movesPos, line.length)];
            fen = new FEN(fenStr);
        } else if("startpos" == sub) {
            fen = FEN.startPosition();
        }

        MBPosition pos = createMailboxPosition(fen);

        foreach(s; moves) {
            Move move = Move.fromAlgebraic(s);
            if(move == NO_MOVE) {
                uciWriteDebugLine("invalid move: %s", s);
            } else {
                uciWriteDebugLine("applying move %s", move);
                pos.makeMove(move);
            }
        }
        uciWriteDebugLine("setting position to %s", pos.getFEN());
        game.setPosition(pos);
    }
    /**
     * ucinewgame
     */
    void handleUcinewgame(string[] tokens, string line) {
        this.game = new Game(FEN.startPosition());
        uciWriteDebugLine("starting new game");
    }
    /**
     * eg.
     *  go wtime 300000 btime 300000 movestogo 40
     *  go infinite
     */
    void handleGo(string[] tokens, string line) {
        assert(tokens[0] == "go");
        assert(tokens.length > 1);
        import std.conv : to;

        int i = 1;
        while(i < tokens.length) {
            string command = tokens[i++];

            switch(command) {
                case "infinite":
                    game.whiteTimeMs = ulong.max;
                    game.blackTimeMs = ulong.max;
                    uciWriteDebugLine("setting white time to %s ms", game.whiteTimeMs);
                    uciWriteDebugLine("setting black time to %s ms", game.blackTimeMs);
                    break;
                case "wtime":
                    game.whiteTimeMs = to!ulong(tokens[i++]);
                    uciWriteDebugLine("setting white time to %s ms", game.whiteTimeMs);
                    break;
                case "btime":
                    game.blackTimeMs = to!ulong(tokens[i++]);
                    uciWriteDebugLine("setting black time to %s ms", game.blackTimeMs);
                    break;
                case "movestogo":
                    uciWriteDebugLine("setting moves to go to %s", tokens[i++]);
                    break;    
                default: 
                    uciWriteDebugLine("todo handle go command '%s'", tokens[1]); 
                    return;
            }
        }

        uciWriteDebugLine("Searching...");
        // start searching and then return the best move
        game.asyncFindBestMove((move) {
            // todo - write info
            uciWriteLine("bestmove %s", move);
        });
    }
}
