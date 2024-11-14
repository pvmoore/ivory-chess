module ivory.mailbox.MailboxEnprise;

import ivory.all;
/+
final class BasicEnprise {
public:
    static bool isSquareAttacked(BasicPosition pos, square sq, Side bySide) {
        int file = file(sq);
        int rank = rank(sq);

        return getPawnAttacker(pos, sq, file, rank, bySide) != NO_SQUARE ||
               getBishopAttacker(pos, sq, file, rank, bySide) != NO_SQUARE ||
               getKnightAttacker(pos, sq, file, rank, bySide) != NO_SQUARE ||
               getRookAttacker(pos, sq, file, rank, bySide) != NO_SQUARE ||
               getQueenAttacker(pos, sq, file, rank, bySide) != NO_SQUARE ||
               getKingAttacker(pos, sq, file, rank, bySide) != NO_SQUARE;
    }
    // static string toString(BasicPosition pos, bool material) {
    //     string buf;
    //     for(int rank = 7; rank >= 0; rank--) {
    //         for(int file = 0; file<8; file++) {
    //             int e = enpriseForSquare(pos, file + (rank<<3));

    //             if(material) e &= 0xffff; else e >>= 16;
    //             auto score = e;

    //             if(score>=0) buf ~= " %s ".format(score);
    //             else buf ~= "%s ".format(score);
    //         }
    //         buf.append("\n");
    //     }
    //     return buf.toString();
    // }
private:
    static square getPawnAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint pawn = Piece.PAWN | (side<<3);

        // todo - handle enpassant

        if(side == Side.WHITE) {
            if(rank > 1) {
                // white
                if(file > 0 && pos.board(sq - 9) == pawn) return checkKing(pos, side, sq - 9);
                if(file < 7 && pos.board(sq - 7) == pawn) return checkKing(pos, side, sq - 7);
            }
        } else {
            if(rank < 6) {
                // black
                if(file > 0 && pos.board(sq + 7) == pawn) return checkKing(pos, side, sq + 7);
                if(file < 7 && pos.board(sq + 9) == pawn) return checkKing(pos, side, sq + 9);
            }
        }
        return NO_SQUARE;
    }
    static square getBishopAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint bishop = Piece.BISHOP | (side<<3);
        return checkKing(pos, side, getDiagonalAttacker(pos, sq, file, rank, bishop));
    }
    static square getRookAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint rook = Piece.ROOK | (side<<3);
        return checkKing(pos, side, (getRankAndFileAttacker(pos, sq, file, rank, rook)));
    }
    static square getQueenAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint queen = Piece.QUEEN | (side<<3);

        square r = checkKing(pos, side, (getRankAndFileAttacker(pos, sq, file, rank, queen)));
        if(r!=NO_SQUARE) return r;

        return checkKing(pos, side, getDiagonalAttacker(pos, sq, file, rank, queen));
    }
    static square getKnightAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint knight = Piece.KNIGHT | (side<<3);

        if(rank < 6) {
            if(file > 0 && pos.board(sq + 15) == knight) return checkKing(pos, side, sq+15);
            if(file < 7 && pos.board(sq + 17) == knight) return checkKing(pos, side, sq+17);
        }
        if(rank > 1) {
            if(file > 0 && pos.board(sq - 17) == knight) return checkKing(pos, side, sq-17);
            if(file < 7 && pos.board(sq - 15) == knight) return checkKing(pos, side, sq-15);
        }
        if(file < 6) {
            if(rank < 7 && pos.board(sq + 10) == knight) return checkKing(pos, side, sq+10);
            if(rank > 0 && pos.board(sq - 6)  == knight) return checkKing(pos, side, sq-6);
        }
        if(file > 1) {
            if(rank < 7 && pos.board(sq + 6)  == knight) return checkKing(pos, side, sq+6);
            if(rank > 0 && pos.board(sq - 10) == knight) return checkKing(pos, side, sq-10);
        }
        return NO_SQUARE;
    }
    static square getDiagonalAttacker(BasicPosition pos, square sq, int file, int rank, uint squareValue) {
        // up left
        square p = sq;
        for(int xx = file - 1, yy = rank + 1; xx >= 0 && yy <= 7; xx--, yy++) {
            p += 7;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        // up right
        p = sq;
        for(int xx = file + 1, yy = rank + 1; xx <= 7 && yy <= 7; xx++, yy++) {
            p += 9;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        // down left
        p = sq;
        for(int xx = file - 1, yy = rank - 1; xx >= 0 && yy >= 0; xx--, yy--) {
            p -= 9;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        // down right
        p = sq;
        for(int xx = file + 1, yy = rank - 1; xx <= 7 && yy >= 0; xx++, yy--) {
            p -= 7;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        return NO_SQUARE;
    }
    static square getRankAndFileAttacker(BasicPosition pos, square sq, int file, int rank, uint squareValue) {
        // left
        square p = sq;
        for(int xx = file - 1; xx >= 0; xx--) {
            uint t = pos.board(--p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        // right
        p = sq;
        for(int xx = file + 1; xx <= 7; xx++ ) {
            uint t = pos.board(++p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        // up
        p = sq;
        for(int yy = rank + 1; yy <= 7; yy++) {
            p += 8;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }

        // down
        p = sq;
        for(int yy = rank - 1; yy >= 0; yy--) {
            p -= 8;
            uint t = pos.board(p);
            if(t != 0) {
                if(t == squareValue) return p;
                break;
            }
        }
        return NO_SQUARE;
    }
    static square getKingAttacker(BasicPosition pos, square sq, int file, int rank, Side side) {
        uint king  = Piece.KING | (side<<3);

        if(file > 0) {
            if(pos.board(sq - 1) == king) return sq - 1;	// left

            if(rank > 0) {
                if(pos.board(sq - 9) == king) return sq - 9;	// down left
            }
            if(rank < 7) {
                if(pos.board(sq + 7) == king) return sq + 7;	// up left
            }
        }
        if(file < 7) {
            if(pos.board(sq + 1) == king) return sq + 1;	// right
            if(rank > 0) {
                if(pos.board(sq - 7) == king) return sq - 7; // down right
            }
            if(rank < 7) {
                if(pos.board(sq + 9) == king) return sq + 9; // up right
            }
        }
        if(rank > 0) {
            if(pos.board(sq - 8) == king) return sq - 8;	// down
        }
        if(rank < 7) {
            if(pos.board(sq + 8) == king) return sq + 8;	// up
        }
        return NO_SQUARE;
    }
    /**
     * Do a quick check to see whether the king has become exposed to attack
     * after an enprise move of a piece away from sq.
     * We only need to check for sliding attacks.
     */
    static square checkKing(BasicPosition pos, Side side, square sq) {
        if(sq == NO_SQUARE) return sq;

        square ksq = pos.kingSquare(side);
        int kFile = file(ksq);
        int kRank = rank(ksq);

        int sqFile = file(sq);
        int sqRank = rank(sq);
        int diff   = sq - ksq;
        Side enemy = side.opposite();

        if(kRank == sqRank) { // If king is on the same rank
            if(ksq < sq) {
                // Check right of the king
                for(square i = ksq + 1; (i&7) != 0; i++) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isRookOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            } else {
                // Check left of the king
                for(square i = ksq - 1; (i&7) != 7; i--) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isRookOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            }
        } else if(kFile == sqFile) { // If king is on same file
            if(ksq < sq) {
                // Check down
                for(square i = ksq - 8; i >= 0; i -= 8) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isRookOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            } else {
                // Check up
                for(square i = ksq + 8; i < 64; i += 8) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isRookOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            }
        } else if((diff%7)==0) { // If king is on \ diagonal
            if(ksq < sq) {
                // Check down-right
                for(square i = ksq - 7; i >= 0 && (i&7) != 0; i -= 7) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isBishopOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            } else {
                // Check up-left
                for(square i = ksq + 7; i < 64 && (i&7) != 7; i += 7) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isBishopOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            }
        } else if((diff%9)==0) {  // If king is on / diagonal
            if(ksq<sq) {
                // Check up-right
                for(square i = ksq + 9; i < 64 && (i&7) != 0; i += 9) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isBishopOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            } else {
                // Check down-left
                for(square i = ksq - 9; i >= 0 && (i&7) != 7; i -= 9) {
                    if(i==sq) continue; // this is the square that will be empty
                    if(pos.isOccupied(i)) {
                        if(pos.pieceAt(i).isBishopOrQueen() && pos.sideAt(i)==enemy) return NO_SQUARE;
                        break;
                    }
                }
            }
        }
        return sq;
    }
}
+/
