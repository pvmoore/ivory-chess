module ivory.mailbox.MBEvalutor;

import ivory.all;

final class MBEvaluator : Evaluator {
public:
    bool chatty = false;

    /** 
     * Evaluate the position from the side to move's point of view. 
     */
    override int evaluate(Position p) {
        MBPosition pos = p.as!MBPosition;

        startChat(pos);

        int score = evaluateMaterial(pos);
        score += evaluateControl(pos);

        chat("Total %s", score);

        endChat();
        return score;
    }
private:
    void startChat(MBPosition pos) {
        //chatty = pos.history.contains(h=>h.hash == 10751324940445322172);
        if(!chatty) return;
        writefln("Eval (%s) { %s", pos.state.sideToMove, pos.history.map!(it=>it.move).array.reverse);
    }
    void endChat() {
        if(!chatty) return;
        writefln("}");
    }
    void chat(A...)(string fmt, A args) {
        if(!chatty) return;
        writefln("  %s", format(fmt, args));
    }
    int evaluateMaterial(MBPosition pos) {
        int score = pos.opt.material[0] - pos.opt.material[1];
        if(pos.state.sideToMove == Side.BLACK) {
            score = -score;
        } 
        chat("material %s", score);
        return score;
    }
    int evaluateControl(MBPosition pos) {
        
        bitboard bb = pos.opt.pieces[pos.state.sideToMove.as!uint];
        uint numPieces = popcnt(bb);
        bool mirror = pos.state.sideToMove == Side.BLACK;

        int pawnScore = 0;
        int knightScore = 0;
        int bishopScore = 0;
        int rookScore = 0;
        int queenScore = 0;
        int kingScore = 0;

        foreach(i; 0..numPieces) {
            square sq = bb.pop();
            Piece piece = pos.pieceAt(sq);
            if(mirror) {
                // swap table square ranks
                sq = mirroredHorizontal(sq);
            }
            final switch(piece) with(Piece) {
                case NONE: throwIf(true, "We should not get here"); break;
                case PAWN: pawnScore += getPawnControlValue(sq, pos.opt.endgame); break; 
                case BISHOP: bishopScore += getBishopControlValue(sq); break;
                case KNIGHT: knightScore += getKnightControlValue(sq); break;
                case ROOK: rookScore += getRookControlValue(sq); break; 
                case QUEEN: queenScore += getQueenControlValue(sq); break; 
                case KING: kingScore += getKingControlValue(sq, pos.opt.endgame); break; 
            }
        }
        if(chatty) {
            chat("Control: pawn: %s, bishop: %s, knight: %s, rook: %s, queen: %s, king: %s", 
                pawnScore, bishopScore, knightScore, rookScore, queenScore, kingScore);
        }
        return pawnScore + bishopScore + knightScore + rookScore + queenScore + kingScore;
    }

    int getPawnControlValue(square sq, float endGame) {
        float midgameScore = PAWN_CONTROL_MIDGAME[sq] * (1 - endGame);
        float endgameScore = PAWN_CONTROL_ENDGAME[sq] * endGame;
        return (midgameScore + endgameScore).as!int;
    }
    int getKingControlValue(square sq, float endGame) {
        float midgameScore = KING_POSITIONS_MIDGAME[sq] * (1 - endGame);
        float endgameScore = KING_POSITIONS_ENDGAME[sq] * endGame;
        return (midgameScore + endgameScore).as!int;
    }
    int getBishopControlValue(square sq) {
        return BISHOP_POSITIONS[sq];
    }
    int getKnightControlValue(square sq) {
        return KNIGHT_POSITIONS[sq];
    }
    int getRookControlValue(square sq) {
        return ROOK_POSITIONS[sq];
    }
    int getQueenControlValue(square sq) {
        return QUEEN_POSITIONS[sq];
    }

    immutable(int)[] PAWN_CONTROL_MIDGAME = [
        /* 8 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 7 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 6 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 5 */	 0,   0,   0,  30,  30,   0,   0,   0,
        /* 4 */	 0,   0,   0,  20,  20,   0,   0,   0,
        /* 3 */	 0,   0,   0,  10,  10,   0,   0,   0,
        /* 2 */	10,  20,  20, -20, -20,  20,  20,  20,
        /* 1 */	 0,   0,   0,   0,   0,   0,   0,   0
        /*       a     b   c    d    e    f    g    h */
    ];
    immutable(int)[] PAWN_CONTROL_ENDGAME = [
        /* 8 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 7 */	40,  40,  40,  40,  40,  40,  40,  40,  
        /* 6 */	30,  30,  30,  30,  30,  30,  30,  30,
        /* 5 */	20,  20,  20,  20,  20,  20,  20,  20,
        /* 4 */	10,  10,  10,  10,  10,  10,  10,  10,  
        /* 3 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 2 */	 0,   0,   0,   0,   0,   0,   0,   0,
        /* 1 */	 0,   0,   0,   0,   0,   0,   0,   0
        /*       a    b    c    d    e    f    g    h */
    ];
    immutable(int)[] KING_POSITIONS_MIDGAME = [
        /* 8 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 7 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 6 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 5 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 4 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 3 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 2 */	 0,   0,   0,   0,   0,   0,   0,  0, 
        /* 1 */	 0,   0,   0,   0,   0,   0,   0,  0 
        /*       a    b    c    d    e    f    g   h */
    ];
    immutable(int)[] KING_POSITIONS_ENDGAME = [
        /* 8 */	-50, -40, -30, -30, -30, -30, -40, -50,
        /* 7 */	-40, -20,   0,   0,   0,   0, -20, -40,
        /* 6 */	-30,   0,  10,  15,  15,  10,   0, -30,
        /* 5 */	-30,   0,  15,  20,  20,  15,   0, -30,
        /* 4 */	-30,   0,  15,  20,  20,  15,   0, -30,
        /* 3 */	-30,   0,  10,  15,  15,  10,   0, -30,
        /* 2 */	-40, -20,   0,  10,  10,   0, -20, -40,
        /* 1 */	-50, -40, -30, -30, -30, -30, -40, -50
        /*        a    b    c    d    e    f    g    h */
    ];

    immutable(int)[] KNIGHT_POSITIONS = [
        /* 8 */	-30, -20, -20, -20, -20, -20, -20, -30,
        /* 7 */	-20, -10,   0,   0,   0,   0, -10, -20,
        /* 6 */	-20,   0,  10,  15,  15,  10,   0, -20,
        /* 5 */	-20,   0,  15,  20,  20,  15,   0, -20,
        /* 4 */	-20,   0,  15,  20,  20,  15,   0, -20,
        /* 3 */	-20,   0,  10,  15,  15,  10,   0, -20,
        /* 2 */	-20, -10,   0,  10,  10,   0, -10, -20,
        /* 1 */	-30, -20, -20, -20, -20, -20, -20, -30
        /*        a    b    c    d    e    f    g    h */
    ];
    immutable(int)[] BISHOP_POSITIONS = [
        /* 8 */	-20, -10, -10, -10, -10, -10, -10, -20,
        /* 7 */	-10,   0,   0,   0,   0,   0,   0, -10,
        /* 6 */	-10,   0,  10,  10,  10,  10,   0, -10,
        /* 5 */	-10,   0,  10,  10,  10,  10,   0, -10,
        /* 4 */	-10,   0,  10,  10,  10,  10,   0, -10,
        /* 3 */	-10,   0,  10,  10,  10,  10,   0, -10,
        /* 2 */	-10,  10,  10,  10,  10,  10,  10, -10,
        /* 1 */	-20, -10, -10, -10, -10, -10, -10, -20
        /*        a    b    c    d    e    f    g    h */
    ];
    immutable(int)[] ROOK_POSITIONS = [
        /* 8 */	 0,   0,   0,   0,   0,   0,   0,  0,
        /* 7 */	 5,  10,  10,  10,  10,  10,  10,  5,
        /* 6 */	-5,   0,   0,   0,   0,   0,   0, -5,
        /* 5 */	-5,   0,   0,   0,   0,   0,   0, -5,
        /* 4 */	-5,   0,   0,   0,   0,   0,   0, -5,
        /* 3 */	-5,   0,   0,   0,   0,   0,   0, -5,
        /* 2 */	-5,   0,   0,   0,   0,   0,   0, -5,
        /* 1 */	 0,   0,   0,   5,   5,   0,   0,  0
        /*       a    b    c    d    e    f    g   h */
    ];
    immutable(int)[] QUEEN_POSITIONS = [
        /* 8 */	-20, -10, -10,  -5,  -5, -10, -10, -20,
        /* 7 */	-10,  0,   0,   0,   0,   0,   0,  -10,
        /* 6 */	-5,   0,   5,   5,   5,   5,   0,  -5,
        /* 5 */	-5,   0,   5,   5,   5,   5,   0,  -5,
        /* 4 */	-5,   0,   5,   5,   5,   5,   0,  -5,
        /* 3 */	-5,   0,   5,   5,   5,   5,   0,  -5,
        /* 2 */	-5,   0,   0,   0,   0,   0,   0,  -5,
        /* 1 */	-20, -10, -10,  -5,  -5, -10, -10, -20
        /*       a    b    c    d    e    f    g   h */
    ];
}
