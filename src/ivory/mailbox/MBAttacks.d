module ivory.mailbox.MBAttacks;

import ivory.all;

/**
 * Note that this can be improved by using precalculated attack bitboards
 * for each piece type and square.
 */
bool squareIsAttacked(ref byteboard bb, square sq, Side bySide) {
    int rank = rank(sq);
    int file = file(sq);

    return isSquareAttackedByPawn(bb, sq, rank, file, bySide) ||
           isSquareAttackedByKnight(bb, sq, rank, file, bySide) ||
           isSquareAttackedByKing(bb, sq, rank, file, bySide) ||
           isSquareAttackedOnDiagonal(bb, sq, rank, file, bySide) ||
           isSquareAttackedOnFileOrRank(bb, sq, rank, file, bySide);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

bool isSquareAttackedByPawn(ref byteboard bb, square sq, int rank, int file, Side bySide) {
    if(bySide == Side.WHITE) {
        enum whitePawn = Piece.PAWN | (Side.WHITE<<3);
        if(rank > 1) {
            // white
            if(file > 0 && bb.get(sq - 9) == whitePawn) return true;
            if(file < 7 && bb.get(sq - 7) == whitePawn) return true;
        }
    } else {
        enum blackPawn = Piece.PAWN | (Side.BLACK<<3);
        if(rank < 6) {
            // black
            if(file > 0 && bb.get(sq + 7) == blackPawn) return true;
            if(file < 7 && bb.get(sq + 9) == blackPawn) return true;
        }
    }
    return false;
}
bool isSquareAttackedByKnight(ref byteboard bb, square sq, int rank, int file, Side bySide) {
    uint knight = Piece.KNIGHT | (bySide<<3);

    // Note: The lookup method seems to be slightly slower
    enum LOOKUP = false;
    static if(LOOKUP) {
        foreach(target; knightMoves(sq)) {
            if(bb.get(target) == knight) return true;
        }
    } else {
        if(rank < 6) {
            if(file > 0 && bb.get(sq + 15) == knight) return true;
            if(file < 7 && bb.get(sq + 17) == knight) return true;
        }
        if(rank > 1) {
            if(file > 0 && bb.get(sq - 17) == knight) return true;
            if(file < 7 && bb.get(sq - 15) == knight) return true;
        }
        if(file < 6) {
            if(rank < 7 && bb.get(sq + 10) == knight) return true;
            if(rank > 0 && bb.get(sq - 6)  == knight) return true;
        }
        if(file > 1) {
            if(rank < 7 && bb.get(sq + 6)  == knight) return true;
            if(rank > 0 && bb.get(sq - 10) == knight) return true;
        }
    }
    return false;
}
bool isSquareAttackedByKing(ref byteboard bb, square sq, int rank, int file, Side bySide) {
    uint king  = Piece.KING | (bySide<<3);

    if(file > 0) {
        if(bb.get(sq - 1) == king) return true;	// left
        if(rank > 0) {
            if(bb.get(sq - 9) == king) return true;	// down left
        }
        if(rank < 7) {
            if(bb.get(sq + 7) == king) return true;	// up left
        }
    }
    if(file < 7) {
        if(bb.get(sq + 1) == king) return true;	// right
        if(rank > 0) {
            if(bb.get(sq - 7) == king) return true; // down right
        }
        if(rank < 7) {
            if(bb.get(sq + 9) == king) return true; // up right
        }
    }
    if(rank > 0) {
        if(bb.get(sq - 8) == king) return true;	// down
    }
    if(rank < 7) {
        if(bb.get(sq + 8) == king) return true;	// up
    }
    return false;
}
bool isSquareAttackedOnDiagonal(ref byteboard bb, square sq, uint rank, uint file, Side bySide) {
    const bishop = Piece.BISHOP | (bySide<<3);
    const queen = Piece.QUEEN | (bySide<<3);

    bool _checkDiagonal(uint fileDelta, uint rankDelta, int sqDelta) {
        uint f = file + fileDelta;
        uint r = rank + rankDelta;
        square s = sq + sqDelta;

        while(f < 8u && r < 8u) {
            auto val = bb.get(s);
            if(val != 0) {
                if(val == bishop || val == queen) return true;
                break;
            }
            f += fileDelta;
            r += rankDelta;
            s += sqDelta;
        }
        return false;
    }

    return _checkDiagonal(-1, 1,   7)  || // up left
           _checkDiagonal( 1, 1,   9)  || // up right
           _checkDiagonal(-1, -1, -9)  || // down left
           _checkDiagonal( 1, -1, -7);    // down right
}
bool isSquareAttackedOnFileOrRank(ref byteboard bb, square sq, int rank, int file, Side bySide) {
    const rook = Piece.ROOK | (bySide<<3);
    const queen = Piece.QUEEN | (bySide<<3);

    bool _checkFile(uint delta) {
        uint f = file + delta;
        square s = sq + delta;

        while(f < 8u) {
            auto val = bb.get(s);
            if(val != 0) {
                if(val == rook || val == queen) return true; 
                break;
            }
            f += delta;
            s += delta;
        }
        return false;

    }
    bool _checkRank(uint rankDelta, int sqDelta) {
        uint r = rank + rankDelta;
        square s = sq + sqDelta;

        while(r < 8u) {
            auto val = bb.get(s);
            if(val != 0) {
                if(val == rook || val == queen) return true; 
                break;
            }
            r += rankDelta;
            s += sqDelta;
        }
        return false;
    }

    return _checkFile(-1)   || // left 
           _checkFile(1)    || // right 
           _checkRank(1, 8) || // up
           _checkRank(-1, -8); // down
}
