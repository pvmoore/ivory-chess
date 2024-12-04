module ivory.Search;

import ivory.all;

/**
 * todo: Example of what we want to be sending periodically to the GUI:
 *  - info score cp -36  depth 5 seldepth 13 nodes 3530 time 0 pv h7h6  g5f4  e8g8  e2e4  d7d5  
 */

// rnbqkb1r/pppppppp/5n2/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 3

/*
    From start position:

    Max depth = 8:
        Nodes evaluated ............. 4,203,024
        PV moves .................... 21,271
    Max depth = 9:
        Nodes evaluated ............. 140,854,679
        PV moves .................... 696,821

 */

final class Search {
public:
    this(MoveGenerator moveGenerator, Evaluator evaluator) {
        this.evaluator = evaluator;
        this.moveGenerator = moveGenerator;
    }

    Move asyncGetBestMove(Position pos, ulong timeMs) {
        // todo - spawn a thread here
        return getBestMove(pos, timeMs);
    }

    Move getBestMove(Position pos, ulong timeMs) {
        this.pos = pos;
        this.timeMs = timeMs;
        this.nodesEvaluated = 0;
        this.quiescingNodesEvaluated = 0;
        this.lineScores.clear();
        this.pvMoves.clear();

        StopWatch watch = StopWatch(AutoStart.yes);
        Move bestMove = NO_MOVE;
        int maxDepth = 8;

        // Iterative deepening
        foreach(depth; 2..maxDepth) {

            writefln("# Evaluation depth = %s", depth);

            uint numMoves = moveGenerator.generate(pos, false);

            if(numMoves == 0) {
                // todo - checkmate/stalemate
            }
           
            int alpha = -int.max;
            int beta = int.max;

            // Run alpha beta search to find the best score
            foreach(i; 0..numMoves) {
                Move m = moveGenerator.popMove();
                pos.makeMove(m);

                ulong posKey = pos.key();

                int score = -alphaBeta(depth, -beta, -alpha);

                // if(score == 15) {
                //     writefln("!! 15 %s", m);
                // }

                pos.unmakeMove();
                writefln("[%s/%s] %s (%s)", i+1, numMoves, m, score);

                if(score > alpha) {
                    //writefln("score > alpha (%s > %s) %s", score, alpha, m);
                    alpha = score;
                    bestMove = m;
                    pvMoves[pos.key()] = m;
                }

                // Update line scores 
                lineScores[m] ~= LineScore(score, depth, posKey);
            }

            // We should have used up or discarded all of the generated moves at this point
            throwIf(moveGenerator.getNumMoves() != 0);
        }
        watch.stop();
        ulong elapsedNs = watch.peek().total!"nsecs";
        double elapsedMs = elapsedNs / 1_000_000.0;
        double elapsedSec = elapsedMs / 1000.0;
        ulong nps = (nodesEvaluated / elapsedSec).as!ulong;

        // writefln("# Move Scores:");
        // foreach(v; lineScores.byKeyValue()) {
        //     writefln("%s -> %s", v.key, v.value);
        // }

        Move[] pvLine = getPVLine(maxDepth);
        writefln("# PV line: %s", pvLine);

        writefln("Nodes evaluated ............. %s", nodesEvaluated);
        writefln("Quiescing nodes evaluated ... %s", quiescingNodesEvaluated);
        writefln("PV moves .................... %s", pvMoves.length);
        writefln("Elapsed time ................ %.2f ms (%s NPS)", elapsedMs, nps);
        
        // Send pv and best move to the UCI GUI
        uciWriteLine("info pv %s", pvLine.map!(it=>it.toString()).join(", "));
        uciWriteLine("bestmove %s", bestMove);

        return bestMove;
    }
private:
    int alphaBeta(int depth, int alpha, int beta) {
        //writefln("  alphaBeta depth %s %s, %s", depth, alpha, beta);
        enum doQuiescence = false;
        uint numMoves = moveGenerator.generate(pos, false);

        foreach(i; 0..numMoves) {
            Move m = moveGenerator.popMove();

            pos.makeMove(m);

            int score;

            // Handle leaf
            if(depth == 1) {
                nodesEvaluated++;
                score = evaluator.evaluate(pos);

                // Continue with quiescence search
                if(doQuiescence && m.isSpecial()) {
                    score = quiesce(depth, -beta, -alpha);
                } 
            } else {
                score = -alphaBeta(depth - 1, -beta, -alpha);
            }

            // if(score == 15) {
            //     writefln("!! 15 %s @ depth %s %s", m, depth, pos.key());
            // }

            pos.unmakeMove();

            if(score >= beta) {
                // beta cutoff
                //writefln("beta cutoff %s > %s", score, beta);
                moveGenerator.discardMoves(numMoves - 1 - i);
                return beta;
            }
            if(score > alpha) {
                //writefln("score > alpha (%s > %s)", score, alpha);
                alpha = score;
                pvMoves[pos.key()] = m;
            }
        }

        return alpha;
    }
    /**
     * Search only captures until a) we run out of moves, b) we reach max quiescence depth or c) one of them beats beta.
     */
    int quiesce(int depth, int alpha, int beta) {
        //writefln("  quiesce %s, %s", alpha, beta);

        int standPatScore = evaluator.evaluate(pos);
        if(standPatScore >= beta) {
            return beta;
        }
        if(standPatScore > alpha) {
            alpha = standPatScore;
        }
        if(depth >= MAX_QUIESCENCE_DEPTH) {
            return alpha;
        }

        uint numMoves = moveGenerator.generate(pos, true);
        foreach(i; 0..numMoves) {
            Move m = moveGenerator.popMove();

            pos.makeMove(m);
            int score = -quiesce(depth + 1, -beta, -alpha);
            pos.unmakeMove();

            if(score >= beta) {
                // beta cutoff

                //writefln("beta cutoff %s", beta);
                moveGenerator.discardMoves(numMoves - 1 - i);
                return beta;
            }
            if(score > alpha) {
                alpha = score;
            }
        }
        return alpha;
    }
    MoveGenerator moveGenerator;
    Evaluator evaluator;
    Position pos;
    ulong timeMs;
    ulong nodesEvaluated;
    ulong quiescingNodesEvaluated;

    // Alpha cutoff moves found keyed by position hash
    Move[PosKey] pvMoves;

    LineScore[][Move] lineScores;

    static struct LineScore {
        int score;
        int depth;
        PosKey posKey;
        string toString() { return "{%s D:%s %x}".format(score, depth, posKey); }
    }
    Move[] getPVLine(int depth) {

        Move[] moves;

        while(moves.length < depth) {
            Move m = pvMoves.get(pos.key(), NO_MOVE);
            if(m == NO_MOVE) break;

            moves ~= m;
            pos.makeMove(m);
        }

        foreach(i; 0..moves.length) {
            pos.unmakeMove();
        }
        return moves;
    }
}
