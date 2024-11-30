module ivory.mailbox.MBPositionBuilder;

import ivory.all;

MBPosition createMailboxPosition(FEN fen) {
    MBPosition pos = new MBPosition();
    pos.state.sideToMove = fen.sideToMove;
    pos.state.fullMoveNumber = fen.fullMoveNumber;
    pos.state.halfMoveClock = fen.halfMoveClock;
    pos.state.enPassantTargetSquare = fen.enPassantTargetSquare;
    pos.state.castlingPermissions = fen.castlingPermissions;
    pos.state.board = fen.board; 

    pos.opt.pieces[] = 0;
    pos.opt.material[] = 0;

    foreach(i; 0..64.as!square) {
        if(!pos.isOccupied(i)) continue;

        Side side = pos.sideAt(i);
        Piece p = pos.pieceAt(i);

        pos.opt.pieces[side.as!uint].set(i.as!uint);
        pos.opt.material[side.as!uint] += material(p); 

        if(p == Piece.KING) {
            pos.opt.kingSquare[side.as!uint] = i;
        }
    }

    pos.opt.endgame = getEndgamePercentage(popcnt(pos.opt.pieces[0]), popcnt(pos.opt.pieces[1]));
    pos.opt.hash = generateHash(pos);
    return pos;
}

__gshared {
    // todo - Check cache key collisions
    uint[] HASH_BOARD;
    uint[] HASH_EN_PASSANT_FILE;
    uint[] HASH_CASTLE_PERMS;
    uint[] HASH_SIDE_TO_MOVE;
    bool hashInitialised;
}
uint generateHash(MBPosition pos) {
    // Initial the global hash on first use
    if(cas(&hashInitialised, false, true)) {
        HASH_BOARD.length = 64 * 16;
        HASH_EN_PASSANT_FILE.length = 8;
        HASH_CASTLE_PERMS.length = 16;
        HASH_SIDE_TO_MOVE.length = 2;

        foreach(i; 0..HASH_BOARD.length) {
            HASH_BOARD[i] = uniform(0, uint.max);
        }
        foreach(i; 0..HASH_EN_PASSANT_FILE.length) {
            HASH_EN_PASSANT_FILE[i] = uniform(0, uint.max);
        }
        foreach(i; 0..HASH_CASTLE_PERMS.length) {
            HASH_CASTLE_PERMS[i] = uniform(0, uint.max);
        }
        foreach(i; 0..HASH_SIDE_TO_MOVE.length) {
            HASH_SIDE_TO_MOVE[i] = uniform(0, uint.max);
        }
    }

    uint h;

    // Hash the board
    foreach(i; 0..64) {
        uint b = pos.state.board[i];
        if(b != 0) {
            h ^= HASH_BOARD[i*16 + b];
        }
    }
    // Hash the castling permissions
    h ^= HASH_CASTLE_PERMS[pos.state.castlingPermissions]; 

    // Hash the enpassant file
    if(pos.state.enPassantTargetSquare != NO_SQUARE) {
        h ^= HASH_EN_PASSANT_FILE[file(pos.state.enPassantTargetSquare)];
    }

    // Hash the side to move
    h ^= HASH_SIDE_TO_MOVE[pos.state.sideToMove.as!uint];

    return h;
}
