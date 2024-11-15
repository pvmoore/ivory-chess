module ivory.mailbox.MailboxMakeMove;

import ivory.all;

/**
 * Make move on the board. Ignore flags, history etc...
 * This is used by move generation which only requires the pieces to be moved for check evaluation.
 */
void makeMoveOnBoardOnly(ref byteboard board, Move m, Side side) {
    square from = m.from();
    square to = m.to();
    Piece movePiece = board.pieceAt(from); 

    board.move(from, to);

    if(m.isPromotion()) {
        board.set(to, m.promotionPiece(), side);
    }
    if(m.isEnPassantCapture()) {
        int offset = side == Side.WHITE ? -8 : 8; 
        board.setEmpty(to + offset);
    }
    if(movePiece == Piece.KING) {
        if(m.isCastle()) {
            bool queenSide = from > to;
            if(side == Side.WHITE) {
                if(queenSide) {
                    board.move(0, 3);
                } else {
                    board.move(7, 5);
                }
            } else {
                if(queenSide) {
                    board.move(56, 59);
                } else {
                    board.move(63, 61);
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
    Piece capture = m.isEnPassantCapture() ? Piece.PAWN : pos.pieceAt(to);

    // Store history
    MailboxPosition.History history = {
        halfMoveClock: pos.state.halfMoveClock,
        castingPermissions: pos.state.castlingPermissions,
        enPassantTargetSquare: pos.state.enPassantTargetSquare,
        capture: capture,
        move: m
    };
    pos.history.push(history);

    // Update castling permissions based on the to and from squares
    pos.state.castlingPermissions &= FROM_SQ_CASTLE_MASKS[from];
    pos.state.castlingPermissions &= FROM_SQ_CASTLE_MASKS[to];

    // Remove en passant target (may be added back later if this is a pawn move)
    pos.state.enPassantTargetSquare = NO_SQUARE;

    // Update the half move clock
    pos.state.halfMoveClock = (capture == Piece.NONE && movePiece != Piece.PAWN) ? pos.state.halfMoveClock + 1 : 0;

    // Move the piece
    pos.movePiece(from, to);

    if(movePiece == Piece.PAWN) {
        if(m.isPromotion()) {
            pos.set(to, m.promotionPiece(), side);
        }

        // Remove the captured pawn if this is an enpassant capture
        if(m.isEnPassantCapture()) {
            int offset = side == Side.WHITE ? -8 : 8; 
            pos.setEmpty(to + offset);
        }

        // Enpassant target available?
        if(abs(from-to) == 16) {
            pos.state.enPassantTargetSquare = (from + to) >>> 1;
        } 

    } else if(movePiece == Piece.KING) {
        // Castling - move the rook
        if(m.isCastle()) {
            bool queenSide = from > to;
            square rookFrom = queenSide ? from - 4 : from + 3;
            square rookTo   = queenSide ? from - 1 : from + 1;
            pos.movePiece(rookFrom, rookTo);
        }
        // Update king position cache
        pos.setKingSquare(to, side); 
    }

    pos.state.sideToMove = side.opposite();
    pos.state.fullMoveNumber += (side == Side.WHITE ? 1 : 0);
}
/*
// This appears to be slower than just copying the board and then throwing it away
void unmakeMoveBoardOnly(ref boardtype board, Move m, Side side, ubyte toSqValue) {
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
//     boardtype board;
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

    if(movePiece == Piece.PAWN) {
        if(m.isEnPassantCapture()) {
            square sq = (side == Side.WHITE) ? to - 8 : to + 8;
            pos.set(sq, Piece.PAWN, enemy);

        } else if(m.isPromotion()) {
            // Replace promotion piece with pawn
            pos.set(from, Piece.PAWN, side);
        } 
    } else if(movePiece == Piece.KING) {
        // Castling - move the rook
        if(m.isCastle()) {
            bool queenSide = from > to;
            square rookFrom = queenSide ? from - 1 : from + 1;
            square rookTo = queenSide ? from - 4 : from + 3;
            pos.movePiece(rookFrom, rookTo);
        } 

        // Update king position cache
        pos.setKingSquare(from, side); 
    }
}
