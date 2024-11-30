module ivory.mailbox.MBPosition;

import ivory.all;

final class MBPosition : Position {
public:
    struct State {
        byteboard board;
        uint halfMoveClock;
        uint fullMoveNumber;
        uint castlingPermissions;
        square enPassantTargetSquare;
        Side sideToMove;
    }
    struct Optimisation {
        square[2] kingSquare;
        uint[2] material;
        bitboard[2] pieces;
        float endgame;          // 0.0 start position -> 1.0 end game
        uint hash;
    }
    struct History {
        uint halfMoveClock;
        uint castlingPermissions;
        square enPassantTargetSquare;
        Piece capture;
        Move move; 
        uint hash;
    }

    State state;
    Optimisation opt;
    Stack!(History,MAX_PLY) history;

    override uint key() {
        return opt.hash;
    }
    override void makeMove(Move m) {
        return .makeMove(this, m);
    }
    override void unmakeMove() {
        .unmakeMove(this);
    }
    FEN getFEN() {
        return new FEN(state.board, state.sideToMove, state.castlingPermissions, state.enPassantTargetSquare, state.halfMoveClock, state.fullMoveNumber);
    }
    /** Check through move history */
    bool isRepeatMove(Move m) {
        bool isRepeat = false;
        history.iterateWhile((ref h) {
            if(h.move == m) {
                isRepeat = true;
                return false;
            }
            if(h.halfMoveClock == 0) {
                // if the half move clock was reset then this cannot be a repeat 
                return false;
            }
            return true;
        });
        return isRepeat;
    }

    // Board update functions
    //──────────────────────────────────────────────────────────────────────────────────────────────────
    void set(square sq, Piece piece, Side side, bool updateHash) {
        if(updateHash) {
            if(uint b = state.board[sq]) {
                opt.hash ^= HASH_BOARD[sq*16 + b];
            }
            opt.hash ^= HASH_BOARD[sq*16 + (piece | side<<3).as!uint];
        }
        state.board.set(sq, piece, side);
        opt.pieces[side.as!uint].set(sq);
    }
    void setEmpty(square sq, bool updateHash) {
        if(updateHash) {
            if(uint b = state.board[sq]) {
                opt.hash ^= HASH_BOARD[sq*16 + b];
            }
        }
        state.board.setEmpty(sq);
        opt.pieces[0].unset(sq);
        opt.pieces[1].unset(sq);
    }
    void movePiece(square from, square to, bool updateHash) {
        if(updateHash) {
            uint f = state.board[from];
            uint t = state.board[to];
            assert(f != 0);

            opt.hash ^= HASH_BOARD[from*16 + f];
            if(t != 0) {
                opt.hash ^= HASH_BOARD[to*16 + t];
            }
            opt.hash ^= HASH_BOARD[to*16 + f];
        }
        state.board.move(from, to);
        opt.pieces[0].move(from, to);
        opt.pieces[1].move(from, to);
    }

    // Board query functions
    //──────────────────────────────────────────────────────────────────────────────────────────────────
    uint get(square sq) {
        return state.board.get(sq);
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
        return opt.kingSquare[side.as!uint];
    }
    void setKingSquare(square sq, Side side) {
        opt.kingSquare[side.as!uint] = sq;
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
        buf ~= "Move: %s, ".format(state.fullMoveNumber);

        // Material
        buf ~= "Material: %s, ".format(opt.material);

        // Endgame
        buf ~= "Endgame: %.2f".format(opt.endgame);

        // buf ~= "\nWhite: %064b".format(opt.pieces[0]);
        // buf ~= "\nBlack: %064b".format(opt.pieces[1]);


        buf ~= "\n";

        return buf;
    }
}
