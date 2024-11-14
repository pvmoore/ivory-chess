module ivory.mailbox.MailboxMoveGenerator;

import ivory.all;

/**
 * A simple baseline move generator. Expected to be correct but not fast.
 *
 *  Squares:
 *
 *   7| 56 57 58 59 60 61 62 63
 *   6| 48 49 50 51 52 53 54 55
 * r 5| 40 41 42 43 44 45 46 47
 * a 4| 32 33 34 35 36 37 38 39
 * n 3| 24 25 26 27 28 29 30 31
 * k 2| 16 17 18 19 20 21 22 23
 *   1| 08 09 10 11 12 13 14 15
 *   0| 00 01 02 03 04 05 06 07
 *    ------------------------
 *       a  b  c  d  e  f  g  h
 *       0  1  2  3  4  5  6  7
 *               file
 */
final class MailboxMoveGenerator {
public:
    MoveList getMoves() { return moves; }

    this() {
        this.moves = new MoveList();
    }
    /** Generate moves for position and return the number of moves generated */
    uint generate(MailboxPosition pos) {
        this.pos = pos;
        this.side = pos.state.sideToMove;
        this.enemy = side.opposite();
        this.numMoves = 0;

        foreach(i; 0..64.as!square) {
            if(pos.isEmpty(i)) continue;
            Piece sqPiece = pos.pieceAt(i);
            if(pos.sideAt(i) == side) {
                generateForSquare(i, sqPiece);
            }
        }
        return numMoves;
    }
    Move popMove() {
        return moves.pop();
    }
private:
    MoveList moves;
    MailboxPosition pos;
    Side side;
    Side enemy;
    uint numMoves;
    
    void addMove(Move m, bool checkKing = true) {

        bool kingIsAttacked = false;

        // Don't add this move if the king is attacked
        if(checkKing) {
            byteboard tempBoard = pos.state.board[];

            square kingSquare = pos.kingSquare(side);
            if(pos.pieceAt(m.from()) == Piece.KING) {
                kingSquare = m.to();
            }
            
            makeMoveOnBoardOnly(tempBoard, m, side);
            kingIsAttacked = squareIsAttacked(tempBoard, kingSquare, side.opposite());

            // Note: This method is slower:
            // pos.makeMove(m);
            // kingIsAttacked = pos.isSquareAttacked(pos.kingSquare(side), side.opposite());
            // pos.unmakeMove();
        }

        if(!kingIsAttacked) {
            moves.push(m);
            numMoves++;
        } 
    }
    void addCapture(square from, square to) {
        addMove(Move(from, to, Move.Flag.NONE, Move.Flag2.CAPTURE));
    }
    void addCapture(square from, square to, Move.Flag flag) {
        addMove(Move(from, to, flag, Move.Flag2.CAPTURE));
    }

    void generateForSquare(square sq, Piece piece) {
        assert(sq != NO_SQUARE);

        uint file = file(sq);
        uint rank = rank(sq);

        final switch(piece) with(Piece) {
            case NONE: assert(false, "Piece should not be NONE"); break;
            case PAWN:  generatePawnMoves(sq, file, rank); break;
            case BISHOP: generateBishopMoves(sq, file, rank); break;
            case KNIGHT: generateKnightMoves(sq); break;
            case ROOK: generateRookMoves(sq, file, rank); break;
            case QUEEN:
                generateRookMoves(sq, file, rank);
                generateBishopMoves(sq, file, rank);
                break;
            case KING: generateKingMoves(sq, file, rank); break;
                break;
        }
    }
    void generatePawnMoves(square sq, int file, int rank) {
        int UP;
        int UP2;
        int UP_LEFT;
        int UP_RIGHT;
        int START_RANK;
        int PROMOTE_FROM_RANK;
        int ENPASSANT_FROM_RANK;

        if(side == Side.WHITE) {
            UP = 8;
            UP2 = 16;
            UP_LEFT = 7;
            UP_RIGHT = 9;
            START_RANK = 1;
            PROMOTE_FROM_RANK = 6;
            ENPASSANT_FROM_RANK = 4;
        } else {
            UP = -8;
            UP2 = -16;
            UP_LEFT = -9;
            UP_RIGHT = -7;
            START_RANK = 6;
            PROMOTE_FROM_RANK = 1;
            ENPASSANT_FROM_RANK = 3;
        }

        // moves
        if(pos.isEmpty(sq + UP)) {
            if(rank == START_RANK) {
                addMove(Move(sq, sq + UP, Move.Flag.PAWN_MOVE));
                if(pos.isEmpty(sq + UP2)) {
                    addMove(Move(sq, sq + UP2, Move.Flag.PAWN_MOVE));
                }
            } else if(rank==PROMOTE_FROM_RANK) {
                addMove(Move(sq, sq + UP, Move.Flag.PROMOTE_QUEEN));
                addMove(Move(sq, sq + UP, Move.Flag.PROMOTE_ROOK));
                addMove(Move(sq, sq + UP, Move.Flag.PROMOTE_KNIGHT));
                addMove(Move(sq, sq + UP, Move.Flag.PROMOTE_BISHOP));
            } else {
                addMove(Move(sq, sq + UP, Move.Flag.PAWN_MOVE));
            }
        }
        // attacks (up and left)
        if(file > 0) {
            if(pos.isOccupied(sq + UP_LEFT) && pos.sideAt(sq + UP_LEFT) == enemy) {
                if(rank == PROMOTE_FROM_RANK) {
                    addCapture(sq, sq + UP_LEFT, Move.Flag.PROMOTE_QUEEN);
                    addCapture(sq, sq + UP_LEFT, Move.Flag.PROMOTE_ROOK);
                    addCapture(sq, sq + UP_LEFT, Move.Flag.PROMOTE_BISHOP);
                    addCapture(sq, sq + UP_LEFT, Move.Flag.PROMOTE_KNIGHT);
                } else {
                    addCapture(sq, sq + UP_LEFT, Move.Flag.PAWN_MOVE);
                }
            }
        }
        // attacks (up and right)
        if(file < 7) {
            if(pos.isOccupied(sq + UP_RIGHT) && pos.sideAt(sq + UP_RIGHT) == enemy) {
                if(rank == PROMOTE_FROM_RANK) {
                    addCapture(sq, sq + UP_RIGHT, Move.Flag.PROMOTE_QUEEN);
                    addCapture(sq, sq + UP_RIGHT, Move.Flag.PROMOTE_ROOK);
                    addCapture(sq, sq + UP_RIGHT, Move.Flag.PROMOTE_BISHOP);
                    addCapture(sq, sq + UP_RIGHT, Move.Flag.PROMOTE_KNIGHT);
                } else {
                    addCapture(sq, sq + UP_RIGHT, Move.Flag.PAWN_MOVE);
                }
            }
        }
        // en passant
        if(pos.state.enPassantTargetSquare != NO_SQUARE && rank == ENPASSANT_FROM_RANK) {
            if(file > 0 && sq + UP_LEFT == pos.state.enPassantTargetSquare) {
                addCapture(sq, sq + UP_LEFT, Move.Flag.ENPASSANT_CAPTURE);
            } else if(file < 7 && sq + UP_RIGHT == pos.state.enPassantTargetSquare) {
                addCapture(sq, sq + UP_RIGHT, Move.Flag.ENPASSANT_CAPTURE);
            }
        }
    }
    void generateKnightMoves(square sq) {
        foreach(target; knightMoves(sq)) {
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
        }
    }
    void generateBishopMoves(square sq, int file, int rank) {
        square target = sq;
        int tx = file - 1;
        int ty = rank + 1;

        // up-left
        while(tx >= 0 && ty <= 7) {
            target += 7;
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
                tx--;
                ty++;
                continue;
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
            break;
        }
        // up-right
        target = sq;
        tx = file + 1;
        ty = rank + 1;
        while(tx <= 7 && ty <= 7) {
            target += 9;
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
                tx++;
                ty++;
                continue;
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
            break;
        }
        // down-right
        target = sq;
        tx = file + 1;
        ty = rank - 1;
        while(tx <= 7 && ty >= 0) {
            target -= 7;
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
                tx++;
                ty--;
                continue;
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
            break;
        }
        // down-left
        target = sq;
        tx = file - 1;
        ty = rank - 1;
        while(tx >= 0 && ty >= 0) {
            target -= 9;
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
                tx--;
                ty--;
                continue;
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
            break;
        }
    }
    void generateRookMoves(square sq, int file, int rank) {

        bool _addMove(square target) {
            if(pos.isEmpty(target)) {
                addMove(Move(sq, target));
                return false;
            } else if(pos.sideAt(target) == enemy) {
                addCapture(sq, target);
            }
            return true;
        }
        
        // left
        square target = sq;
        for(int i = file - 1; i >= 0; i--) {
            target--;
            if(_addMove(target)) break;
        }
        // right
        target = sq;
        for(int i = file + 1; i <= 7; i++) {
            target++;
            if(_addMove(target)) break;
        }
        // up
        target = sq;
        for(int i = rank + 1; i <= 7; i++) {
            target += 8;
            if(_addMove(target)) break;
        }
        // down
        target = sq;
        for(int i = rank - 1; i >= 0; i--) {
            target -= 8;
            if(_addMove(target)) break;
        }
    }
    void generateKingMoves(square sq, int file, int rank) {
        bool inCheck = squareIsAttacked(pos.state.board, sq, enemy);

        void _addMove(square target) {
            if(pos.isOccupied(target) && pos.sideAt(target) == side) return;

            // If the king is in check before the move we need to check it again after the move.
            // Otherwise we can assume that we only need to check the target square for check regardless
            // of the current king position. This is likely to be quicker than applying the move and then checking
            if(!inCheck) {
                if(squareIsAttacked(pos.state.board, target, enemy)) return;
            } else {
                // Remove the king and check the target square. This is slower for some reason.
                // pos.setEmpty(sq);
                // bool stillInCheck = squareIsAttacked(pos.state.board, target, enemy);
                // pos.set(sq, Piece.KING, side); 
                // if(stillInCheck) return;
            }

            auto flag2 = pos.isOccupied(target) ? Move.Flag2.CAPTURE : Move.Flag2.NONE;
            addMove(Move(sq, target, Move.Flag.NONE, flag2), inCheck);
        }

        if(file > 0) {
            // left
            _addMove(sq - 1);
            // up left
            if(rank < 7) {
                _addMove(sq + 7);
            }
            // down left
            if(rank > 0) {
                _addMove(sq - 9);
            }
        }
        if(file < 7) {
            // right
            _addMove(sq + 1);
            // up right
            if(rank < 7) {
                _addMove(sq + 9);
            }
            // down right
            if(rank > 0) {
                _addMove(sq - 7);
            }
        }
        if(rank < 7) {
            // up
            _addMove(sq + 8);
        }
        if(rank > 0) {
            // down
            _addMove(sq - 8);
        }

        // Castling 
        if(inCheck) return;

        if(pos.canCastleKingSide()) {
            if(pos.isEmpty(sq + 1) && pos.isEmpty(sq + 2)) {
                if(!pos.isSquareAttacked(sq + 1, enemy) &&
                   !pos.isSquareAttacked(sq + 2, enemy))
                {
                    addMove(Move(sq, sq + 2, Move.Flag.CASTLE, Move.Flag2.NONE), false);
                }
            }
        }
        if(pos.canCastleQueenSide()) {
            if(pos.isEmpty(sq - 1) && pos.isEmpty(sq - 2) && pos.isEmpty(sq - 3)) {
                if(!pos.isSquareAttacked(sq - 1, enemy) &&
                   !pos.isSquareAttacked(sq - 2, enemy))
                {
                    addMove(Move(sq, sq - 2, Move.Flag.CASTLE, Move.Flag2.NONE), false);
                }
            }
        }
    }
}
