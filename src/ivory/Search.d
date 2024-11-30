module ivory.Search;

import ivory.all;

final class Search {
public:
    this(MoveGenerator moveGenerator, Evaluator evaluator) {
        this.evaluator = evaluator;
        this.moveGenerator = moveGenerator;
        this.principalVariation.length = MAX_PLY;
    }

    Move asyncGetBestMove(Position pos, ulong timeMs) {
        return getBestMove(pos, timeMs);
    }

    Move getBestMove(Position pos, ulong timeMs) {
        this.pos = pos;
        this.timeMs = timeMs;
        this.nodesEvaluated = 0;
        this.quiescingNodesEvaluated = 0;
        this.maxDepth = 4;
        this.principalVariation[] = NO_MOVE;
        this.lineScores.clear();
        this.alphaMoves.clear();

        StopWatch watch = StopWatch(AutoStart.yes);
        Move bestMove = NO_MOVE;

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
                int score = -alphaBeta(depth, -beta, -alpha);
                pos.unmakeMove();
                writefln("[%s/%s] %s (%s)", i+1, numMoves, m, score);

                if(score > alpha) {
                    writefln("score > alpha (%s > %s)", score, alpha);
                    alpha = score;
                    bestMove = m;
                    alphaMoves.update(m, ()=>score, (ref int s) { if(score > s) s = score; });
                }

                // Update line scores 
                lineScores[m] ~= LineScore(score, depth);
            }

            // We should have used up or discarded all of the generated moves at this point
            throwIf(moveGenerator.getNumMoves() != 0);
        }
        watch.stop();
        ulong elapsedNs = watch.peek().total!"nsecs";
        double elapsedMs = elapsedNs / 1_000_000.0;
        double elapsedSec = elapsedMs / 1000.0;
        ulong nps = (nodesEvaluated / elapsedSec).as!ulong;

        writefln("# Move Scores:");
        foreach(v; lineScores.byKeyValue()) {
            writefln("%s -> %s", v.key, v.value);
        }
        writefln("# Principal Variation (max depth %s):", maxDepth);
        writefln("%s", principalVariation[0..maxDepth]);

        writefln("# Alpha moves:");
        foreach(e; alphaMoves.byKeyValue()) {
            writefln(" %s: score = %s", e.key, e.value);
        }

        writefln("Nodes evaluated ............. %s", nodesEvaluated);
        writefln("Quiescing nodes evaluated ... %s", quiescingNodesEvaluated);
        writefln("Elapsed time ................ %.2s ms (%s NPS)", elapsedMs, nps);

        return bestMove;
    }

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

            pos.unmakeMove();

            if(score >= beta) {
                // beta cutoff

                //writefln("beta cutoff %s", beta);
                moveGenerator.discardMoves(numMoves - 1 - i);
                return beta;
            }
            if(score > alpha) {
                //writefln("score > alpha (%s > %s)", score, alpha);
                alpha = score;
                alphaMoves.update(m, ()=>score, (ref int s) { if(score > s) s = score; });
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

private:
    MoveGenerator moveGenerator;
    Evaluator evaluator;
    Position pos;
    int maxDepth;
    ulong timeMs;
    ulong nodesEvaluated;
    ulong quiescingNodesEvaluated;

    int[Move] alphaMoves;

    Move[] principalVariation;
    LineScore[][Move] lineScores;

    static struct LineScore {
        int score;
        int depth;
    }
}
