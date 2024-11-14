module ivory.mailbox.MailboxMakeMove;

import ivory.all;

/**
 * Make move on the board. Ignore flags, history etc...
 * This is used by move generation which only requires the pieces to be moved for check evaluation.
 */
void makeMoveOnBoardOnly(ref byteboard board, Move m, Side side) {
    square from = m.from();
    square to = m.to();
    Piece movePiece = (board[from] & PIECE_MASK).as!Piece;

    board[to] = board[from];
    board[from] = 0;

    if(m.isPromotion()) {
        board[to] = (m.promotionPiece() | (side<<3)).as!ubyte;
    }
    if(m.isEnPassantCapture()) {
        int offset = side == Side.WHITE ? -8 : 8; 
        board[to + offset] = 0;
    }
    if(movePiece == Piece.KING) {
        if(m.isCastle()) {
            bool queenSide = from > to;
            if(side == Side.WHITE) {
                if(queenSide) {
                    board[3] = board[0];
                    board[0] = 0;
                } else {
                    board[5] = board[7];
                    board[7] = 0;
                }
            } else {
                if(queenSide) {
                    board[59] = board[56];
                    board[56] = 0;
                } else {
                    board[61] = board[63];
                    board[63] = 0;
                }
            }
        }
    }
}

void makeMove(MailboxPosition pos, Move m) {
    square from = m.from();
    square to = m.to();
    Side side = pos.state.sideToMove;
    Piece movePiece = pos.pieceAt(from);
    assert(movePiece != Piece.NONE);

    // Calculate capture piece
    Piece capture = pos.pieceAt(to);
    if(m.isEnPassantCapture()) {
        assert(movePiece == Piece.PAWN);
        capture = Piece.PAWN;
    }

    // Store history
    MailboxPosition.History history = {
        halfMoveClock: pos.state.halfMoveClock,
        castingPermissions: pos.state.castlingPermissions,
        enPassantTargetSquare: pos.state.enPassantTargetSquare,
        capture: capture,
        move: m
    };
    pos.history.push(history);

    pos.state.halfMoveClock++;

    if(capture != Piece.NONE) {
        // Remove castling permissions if a rook was captured
        if(capture == Piece.ROOK) {
            if(to == 0) removePermission(pos.state.castlingPermissions, Castling.WHITE_OOO);
            if(to == 7) removePermission(pos.state.castlingPermissions, Castling.WHITE_OO);
            if(to == 56) removePermission(pos.state.castlingPermissions, Castling.BLACK_OOO);
            if(to == 63) removePermission(pos.state.castlingPermissions, Castling.BLACK_OO);
        }
        // Capture resets the half move clock
        pos.state.halfMoveClock = 0;
    }

    // Remove en passant target (may be added back later if this is a pawn move)
    pos.state.enPassantTargetSquare = NO_SQUARE;

    // Move the piece
    pos.movePiece(from, to);

    if(movePiece == Piece.PAWN) {
        if(m.isPromotion()) {
            pos.set(to, m.promotionPiece(), side);
        }

        //Remove the captured pawn if this is an enpassant capture
        if(m.isEnPassantCapture()) {
            int offset = side == Side.WHITE ? -8 : 8; 
            pos.setEmpty(to + offset);
        }

        // Enpassant target available?
        if(abs(from-to) == 16) {
            pos.state.enPassantTargetSquare = (from + to) >>> 1;
        } 

        // Pawn move resets the half move clock
        pos.state.halfMoveClock = 0;
    } else if(movePiece == Piece.ROOK) {
        // Remove castling permissions
        if(from == 0) removePermission(pos.state.castlingPermissions, Castling.WHITE_OOO);
        if(from == 7) removePermission(pos.state.castlingPermissions, Castling.WHITE_OO);
        if(from == 56) removePermission(pos.state.castlingPermissions, Castling.BLACK_OOO);
        if(from == 63) removePermission(pos.state.castlingPermissions, Castling.BLACK_OO);
    } else if(movePiece == Piece.KING) {
        // Castling - move the rook
        if(m.isCastle()) {
            bool queenSide = from > to;
            if(side == Side.WHITE) {
                if(queenSide) {
                    assert(pos.canCastleQueenSide());
                    assert(pos.isOccupiedBy(0, Piece.ROOK, Side.WHITE));
                    pos.movePiece(0, 3);
                } else {
                    assert(pos.canCastleKingSide());
                    assert(pos.isOccupiedBy(7, Piece.ROOK, Side.WHITE));
                    pos.movePiece(7, 5);
                }
            } else {
                if(queenSide) {
                    assert(pos.canCastleQueenSide());
                    assert(pos.isOccupiedBy(56, Piece.ROOK, Side.BLACK));
                    pos.movePiece(56, 59);
                } else {
                    assert(pos.canCastleKingSide());
                    assert(pos.isOccupiedBy(63, Piece.ROOK, Side.BLACK));
                    pos.movePiece(63, 61);
                }
            }
        }
        // Update king position cache
        // Remove castling permissions
        if(side == Side.WHITE) {
            pos.state.whiteKingSquare = to;
            removePermission(pos.state.castlingPermissions, Castling.WHITE_OO | Castling.WHITE_OOO);
        } else {
            pos.state.blackKingSquare = to;
            removePermission(pos.state.castlingPermissions, Castling.BLACK_OO | Castling.BLACK_OOO);
        }
    }

    pos.state.sideToMove = side.opposite();
    pos.state.fullMoveNumber += (side == Side.WHITE ? 1 : 0);
}
/*
// This appears to be slower than just copying the board and then throwing it away
void unmakeMoveBoardOnly(ref byteboard board, Move m, Side side, ubyte toSqValue) {
    square from = m.from();
    square to = m.to();
    Piece movePiece = m.isPromotion() ? Piece.PAWN : (board[to] & PIECE_MASK).as!Piece;

    // Apply move in reverse
    board[from] = board[to];
    board[to] = toSqValue;

    if(movePiece == Piece.PAWN) {
        if(m.isEnPassantCapture()) {
            Side enemy = side.opposite();
            square sq = (side == Side.WHITE) ? to - 8 : to + 8;
            board[sq] = (Piece.PAWN | (enemy<<3)).as!ubyte;

        } else if(m.isPromotion()) {
            // Replace promotion piece with pawn
            board[from] = (Piece.PAWN | (side<<3)).as!ubyte;
        } 
    } else if(movePiece == Piece.KING) {
        if(m.isCastle()) {
            // Move the rook
            bool queenSide = from > to;
            square rookFrom = queenSide ? from - 1 : from + 1;
            square rookTo = queenSide ? from - 4 : from + 3;

            board[rookTo] = board[rookFrom];
            board[rookFrom] = 0;
        } 
    }
}
*/

// struct State {
//     uint halfMoveClock;
//     uint fullMoveNumber;
//     uint castlingPermissions;
//     square enPassantTargetSquare;
//     Side sideToMove;
//     byteboard board;
//     // Optimisation
//     square whiteKingSquare;
//     square blackKingSquare;
// }
// MailboxPosition.History history = {
//         halfMoveClock: state.halfMoveClock,
//         castingPermissions: state.castlingPermissions,
//         enPassantTargetSquare: state.enPassantTargetSquare,
//         capture: capture,
//         move: m
// };
void unmakeMove(MailboxPosition pos) {
    auto history = pos.history.pop();

    pos.state.halfMoveClock = history.halfMoveClock;
    pos.state.fullMoveNumber -= (pos.state.sideToMove == Side.WHITE) ? 1 : 0;
    pos.state.castlingPermissions = history.castingPermissions;
    pos.state.enPassantTargetSquare = history.enPassantTargetSquare;
    pos.state.sideToMove = pos.state.sideToMove.opposite();
    
    Side side = pos.state.sideToMove;
    Side enemy = side.opposite();

    // Update board
    Move m = history.move;

    square from = m.from();
    square to = m.to();
    Piece movePiece = m.isPromotion() ? Piece.PAWN : pos.pieceAt(to);
    Piece capture = history.capture;

    // Apply move in reverse
    pos.movePiece(to, from);

    // Put captured piece back if not en-passant
    if(capture != Piece.NONE && !m.isEnPassantCapture()) {
        pos.set(to, capture, enemy);
    }

    switch(movePiece) {
        case Piece.PAWN:
            if(m.isEnPassantCapture()) {
                square sq = (side == Side.WHITE) ? to - 8 : to + 8;
                pos.set(sq, Piece.PAWN, enemy);

            } else if(m.isPromotion()) {
                // Replace promotion piece with pawn
                pos.set(from, Piece.PAWN, side);

            } 
            break;
        case Piece.KING:
            if(m.isCastle()) {
                // Move the rook
                bool queenSide = from > to;
                square rookFrom = queenSide ? from - 1 : from + 1;
                square rookTo = queenSide ? from - 4 : from + 3;

                pos.movePiece(rookFrom, rookTo);

                // Update whiteKingPos, blackKingPos 
                if(side == Side.WHITE) {
                    pos.state.whiteKingSquare = 4;
                } else {
                    pos.state.blackKingSquare = 60;
                }

            } else {
                // Normal king move

                // Update whiteKingPos, blackKingPos 
                if(side == Side.WHITE) {
                    pos.state.whiteKingSquare = from;
                } else {
                    pos.state.blackKingSquare = from;
                }
            }
            break;
        default:
            // Knight, bishop, rook or queen
            break;
    }
}
