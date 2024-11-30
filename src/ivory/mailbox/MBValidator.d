module ivory.mailbox.MBValidator;

import ivory.all;

void validate(MBPosition pos, Move afterMove) {
    validateKingPos(pos);
    validateMaterial(pos, afterMove);
    validatePieces(pos);
    validateEndgame(pos);
    validateHash(pos);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void validateKingPos(MBPosition pos) {
    int whiteKingPos = -1;
    int blackKingPos = -1;
    foreach(sq; 0..64) {
        if(pos.pieceAt(sq) == Piece.KING) {
            if(pos.sideAt(sq) == Side.WHITE) {
                throwIf(whiteKingPos != -1);
                whiteKingPos = sq;
            } else {
                throwIf(blackKingPos != -1);
                blackKingPos = sq;
            }
        }
    }
    throwIf(whiteKingPos != pos.opt.kingSquare[0]);
    throwIf(blackKingPos != pos.opt.kingSquare[1]);
}
void validateMaterial(MBPosition pos, Move afterMove) {
    uint blackMaterial = 0;
    uint whiteMaterial = 0;

    foreach(sq; 0..64) {
        if(!pos.isOccupied(sq)) continue;

        Piece p = pos.pieceAt(sq);
        Side s = pos.sideAt(sq);
        if(s == Side.WHITE) {
            whiteMaterial += material(p);
        } else {
            blackMaterial += material(p);
        }
    }

    throwIf(whiteMaterial != pos.opt.material[0], "Material is incorrect, expected %s but was %s (move %s)", whiteMaterial, pos.opt.material[0], afterMove);
    throwIf(blackMaterial != pos.opt.material[1], "Material is incorrect, expected %s but was %s (move %s)", blackMaterial, pos.opt.material[1], afterMove);
}
void validatePieces(MBPosition pos) {
    foreach(sq; 0..64) {
        if(pos.isOccupied(sq)) {
            Side side = pos.sideAt(sq);
            Side enemy = side.opposite();
            throwIf(pos.opt.pieces[side.as!uint].isUnset(sq), "pieces is incorrect");
            throwIf(pos.opt.pieces[enemy.as!uint].isSet(sq), "pieces is incorrect");
        } else {
            throwIf(pos.opt.pieces[0].isSet(sq), "pieces is incorrect");
            throwIf(pos.opt.pieces[1].isSet(sq), "pieces is incorrect");
        }
    }
}
void validateEndgame(MBPosition pos) {
    uint count = pos.state.board[].map!(it=>it == 0 ? 0 : 1).sum();
    uint numWhitePieces = popcnt(pos.opt.pieces[0]);
    uint numBlackPieces = popcnt(pos.opt.pieces[1]);
    throwIf(numWhitePieces + numBlackPieces != count, "endgame is incorrect");
    float e = getEndgamePercentage(count, 0);
    throwIf(!isClose(e, pos.opt.endgame));
}
void validateHash(MBPosition pos) {
    throwIf(generateHash(pos) != pos.opt.hash, "Hash is incorrect. Expected %x but is %x", generateHash(pos), pos.opt.hash);
}
