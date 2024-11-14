module ivory.Ivory;

import std.stdio 	: writefln, writef, readln;
import std.string 	: split, indexOf;
import core.memory  : GC;

import ivory.all;
import test_perft;

final class Ivory {
public:
    static NAME = "Ivory-Chess 0.1"; 

    this() {
        this.game = newGame();
    }
    void repl() {
        try{
            while(running) {
                string line = readln();
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
                writefln("id name %s", NAME);
                writefln("uciok");
                break;
            case "ucinewgame":
                game = newGame();
                break;
            case "debug":
                // debug [ on | off ]
                break;
            case "isready":
                writefln("readyok");
                break;
            case "position": {
                // position [fen <fenstring> | startpos ]  moves <move1> .... <movei>
                string sub = tokens.length > 1 ? tokens[1] : "";
                auto movesPos = line.indexOf("moves"); 
                FEN fen;
                if("fen" == sub) {
                    auto fenPos = line.indexOf("fen") + 4;
                    string fenStr = line[fenPos..maxOf(movesPos, line.length)];
                    fen = new FEN(fenStr);
                } else if("startpos" == sub) {
                    fen = FEN.START_POSITION;
                }
                game.setPosition(fen);

                if(movesPos != -1) {
                    // todo - apply moves 
                }
                break; 
            }
            case "setoption":
                // setoption name <id> [value <x>]
                break;
            case "go":
                break;
            case "stop":
                break;
            case "quit":
                running = false;
                break;

            // ###############################################################################
            // Internal commands		
            // ###############################################################################
            case "perft": 
                testPerft();
                break;
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
            default: 
                // Assume this is an algebraic move eg. a2a4
                Move move = Move.fromAlgebraic(command);
                auto gen = new MailboxMoveGenerator();
                gen.generate(game.pos);
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
    }

    Game newGame() {
        return new Game(FEN.START_POSITION);
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
}
