module ivory.move.Move;

import ivory.all;

enum NO_MOVE = Move(0, 0, Move.Flag.NONE);

/**
 * [0 000 000000 000000] 16 bits
 *  | |   |      |
 *  | |   |      from
 *  | |   to
 *  | flag
 *  unused
 */
struct Move {
public:
    enum Flag { // 3 bits
        NONE              = 0,
        PROMOTE_BISHOP    = 1,
        PROMOTE_KNIGHT    = 2,
        PROMOTE_ROOK      = 3,
        PROMOTE_QUEEN     = 4,
        CASTLE            = 5,
        ENPASSANT_CAPTURE = 6,  
        CAPTURE           = 7   
    }

    this(square from, square to) {
        data |= (from).as!ushort;
        data |= (to<<6).as!ushort;
    }
    this(square from, square to, Flag flag) {
        data |= (from).as!ushort;
        data |= (to<<6).as!ushort;
        data |= (flag<<12).as!ushort;
    }

    /** Calculate board square from algebraic string eg. "a2a4" */
    static Move fromAlgebraic(string s) {
        if(s.length < 4) return NO_MOVE;
        Flag flag = Flag.NONE;
        uint f1 = s[0] - 'a';
        uint r1 = s[1] - '1';
        if(f1 > 7 || r1 > 7) return NO_MOVE;

        uint i = 2;
        if(s[i] == 'x') {
            i++;
            flag = Flag.CAPTURE;
        }

        uint f2 = s[i++] - 'a';
        uint r2 = s[i++] - '1';
        if(f2 > 7 || r2 > 7) return NO_MOVE;

        square from = f1 + r1 * 8;
        square to   = f2 + r2 * 8;

        if(i < s.length-1) {
            switch(s[i]) {
                case 'q': flag = Flag.PROMOTE_QUEEN; break;
                case 'r': flag = Flag.PROMOTE_ROOK; break;
                case 'n': flag = Flag.PROMOTE_KNIGHT; break;
                case 'b': flag = Flag.PROMOTE_BISHOP; break;
                default: return NO_MOVE;
            }
        }
        return Move(from, to, flag);
    }

    square from() { return data & 0b111111; }
    square to() { return (data >>> 6) & 0b111111; }
    bool isCastle() { return flag() == Flag.CASTLE; }
    bool isEnPassantCapture() { return flag() == Flag.ENPASSANT_CAPTURE; }
    bool isSpecial() { return flag() != Flag.NONE; }
    bool isPromotion() {
        Flag f = flag();
        return f==Flag.PROMOTE_BISHOP ||
               f==Flag.PROMOTE_KNIGHT ||
               f==Flag.PROMOTE_ROOK   ||
               f==Flag.PROMOTE_QUEEN;
    }
    Piece promotionPiece() { 
        Flag f = flag();
        return f==Flag.PROMOTE_QUEEN  ? Piece.QUEEN :
               f==Flag.PROMOTE_ROOK   ? Piece.ROOK :
               f==Flag.PROMOTE_KNIGHT ? Piece.KNIGHT :
               f==Flag.PROMOTE_BISHOP ? Piece.BISHOP : Piece.NONE;
    }
    bool isMove(square from, square to) {
        return this.from() == from && this.to() == to;
    }
    string toString() {
        if(from==0 && to==0) return "NO_MOVE";
        string c = isCapture() ? "x" : "";
        string p = isPromotion() ? "" ~ fenChar(promotionPiece(), Side.BLACK) : "";
        string s = "%s%s%s%s%s%s".format(fileChar(from()), rankChar(from()), c, 
                                         fileChar(to()), rankChar(to()), p);
        return s;
    }
private:
    ushort data;

    bool isCapture() { return flag() == Flag.CAPTURE || flag() == Flag.ENPASSANT_CAPTURE; }

    Flag flag() { return ((data >>> 12) & 0b111).as!Flag; }
}
