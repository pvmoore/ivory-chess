module ivory.mailbox.MailboxPosition;

import ivory.all;

final class MailboxPosition {
public:
    struct State {
        byteboard board;
        uint halfMoveClock;
        uint fullMoveNumber;
        uint castlingPermissions;
        square enPassantTargetSquare;
        Side sideToMove;
        // Optimisation
        square whiteKingSquare;
        square blackKingSquare;
    }
    struct History {
        uint halfMoveClock;
        uint castingPermissions;
        square enPassantTargetSquare;
        Piece capture;
        Move move; 
    }

    State state;
    stack!(History,MAX_MOVES) history;

    void fromFEN(FEN fen) {
        this.state.sideToMove = fen.sideToMove;
        this.state.fullMoveNumber = fen.fullMoveNumber;
        this.state.halfMoveClock = fen.halfMoveClock;
        this.state.enPassantTargetSquare = fen.enPassantTargetSquare;
        this.state.castlingPermissions = fen.castlingPermissions;
        this.state.board = fen.board; 

        foreach(i; 0..64.as!square) {
            if(pieceAt(i) == Piece.KING) {
                if(sideAt(i) == Side.WHITE) {
                    this.state.whiteKingSquare = i;
                } else {
                    this.state.blackKingSquare = i;
                }
            }
        }
    }
    FEN getFEN() {
        return new FEN(state.board, state.sideToMove, state.castlingPermissions, state.enPassantTargetSquare, state.halfMoveClock, state.fullMoveNumber);
    }
    uint get(square sq) {
        return state.board.get(sq);
    }
    void set(square sq, Piece piece, Side side) {
        state.board.set(sq, piece, side);
    }
    void setEmpty(square sq) {
        state.board.setEmpty(sq);
    }
    void movePiece(square from, square to) {
        state.board.move(from, to);
    }
    bool isEmpty(square sq) {
        return state.board.get(sq) == 0;
    }
    bool isOccupied(square sq) {
        return state.board.get(sq) != 0;
    }
    bool isOccupiedBy(square sq, Piece p, Side s) {
        return state.board.get(sq) == (p | (s<<3));
    }
    Piece pieceAt(square sq) {
        return state.board.pieceAt(sq);
    }
    Side sideAt(square sq) {
        return state.board.sideAt(sq);
    }
    bool isSquareAttacked(square sq, Side bySide) {
        return .squareIsAttacked(state.board, sq, bySide);
    }
    square kingSquare(Side side) {
        return side == Side.WHITE ? state.whiteKingSquare : state.blackKingSquare;
    }
    void setKingSquare(square sq, Side side) {
        if(side == Side.WHITE) {
            state.whiteKingSquare = sq;
        } else {
            state.blackKingSquare = sq;
        }
    }
    bool canCastleKingSide() {
        return .canCastleKingSide(state.castlingPermissions, state.sideToMove);
    }
    bool canCastleQueenSide() {
        return .canCastleQueenSide(state.castlingPermissions, state.sideToMove);
    }
    override string toString() {
        string buf;
        for(int rank = 7; rank >= 0; rank--) {
            buf ~= "%s |".format(rank+1);
            for(int file = 0; file < 8; file++) {
                auto b = state.board.get(file + (rank<<3));
                if(b==0) {
                    buf ~= "· ";
                } else {
                    Piece p = (b & PIECE_MASK).as!Piece;
                    Side s = ((b & SIDE_MASK) >>> 3).as!Side;

                    auto colour = s == Side.WHITE ? Ansi.WHITE_BOLD : Ansi.CYAN_BOLD;
                    buf ~= ansiWrap("%s ".format(p.fenChar(s)), colour);
                }
            }
            buf ~= "  ";
            foreach(j; rank*8..rank*8+8) buf ~= "%02s ".format(j);
            buf ~= "\n";
        }
        buf ~= "  ------------------------------------------ ";

        string stm = state.sideToMove == Side.WHITE ? ansiWrap("WHITE", Ansi.WHITE_BOLD) 
                                                    : ansiWrap("BLACK", Ansi.CYAN_BOLD); 
        buf ~= "\n   a b c d e f g h   %s, ".format(stm);

        // Castling permissions
        string cp = "";
        if(state.castlingPermissions) {
            if(.canCastleKingSide(state.castlingPermissions, Side.WHITE)) cp ~= "K";
            if(.canCastleQueenSide(state.castlingPermissions, Side.WHITE)) cp ~= "Q";
            if(.canCastleKingSide(state.castlingPermissions, Side.BLACK)) cp ~= "k";
            if(.canCastleQueenSide(state.castlingPermissions, Side.BLACK)) cp ~= "q";
            buf ~= "Castling: [%s], ".format(cp);
        } else {
            buf ~= "Castling: None, ";
        }

        // En passant square
        if(state.enPassantTargetSquare != NO_SQUARE) {
            buf ~= "EP: %s, ".format(state.enPassantTargetSquare);
        } else {
            buf ~= "EP: None, ";
        }

        // Half move clock
        buf ~= "HMClock: %s, ".format(state.halfMoveClock);

        // Full move number
        buf ~= "Move: %s ".format(state.fullMoveNumber);

        // Material
        //buf ~= "Material: %s ".format(whiteMaterial-blackMaterial);

        // Num pieces
        //buf ~= "Pieces: %s ".format(whiteNumPieces-blackNumPieces);

        buf ~= "\n";

        return buf;
    }
}
