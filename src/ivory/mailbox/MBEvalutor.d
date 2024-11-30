module ivory.mailbox.MBEvalutor;

import ivory.all;

final class MBEvaluator : Evaluator {
public:
    /** 
     * Evaluate the position from the side to move's point of view. 
     */
    override int evaluate(Position p) {
        MBPosition pos = p.as!MBPosition;

        uint score = evaluateMaterial(pos);
        score += evaluateControl(pos);

        // Invert the score if it is BLACK's move
        if(pos.state.sideToMove == Side.BLACK) {
            score = -score;
        }

        return score;
    }
private:
    /** Return material total from WHITE's point of view */
    int evaluateMaterial(MBPosition pos) {
        return pos.opt.material[0] - pos.opt.material[1];
    }
    /** Return scquare control from WHITE's point of view */
    int evaluateControl(MBPosition pos) {
        
        bitboard bb = pos.opt.pieces[0] | pos.opt.pieces[1];
        uint numPieces = popcnt(bb);
        bool mirror = pos.state.sideToMove == Side.BLACK;
        int score = 0;

        foreach(i; 0..numPieces) {
            square sq = bb.pop();
            Piece piece = pos.pieceAt(sq);
            if(mirror) {
                // swap table square ranks
                sq = mirroredHorizontal(sq);
            }
            final switch(piece) with(Piece) {
                case NONE: throwIf(true, "We should not get here"); break;
                case PAWN: score += getPawnControlValue(sq, pos.opt.endgame); break; 
                case BISHOP: score += getBishopControlValue(sq); break;
                case KNIGHT: score += getKnightControlValue(sq); break;
                case ROOK: score += getRookControlValue(sq); break; 
                case QUEEN: score += getQueenControlValue(sq); break; 
                case KING: score += getKingControlValue(sq, pos.opt.endgame); break; 
            }
        }
        return score;
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
