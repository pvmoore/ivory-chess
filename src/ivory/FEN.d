module ivory.FEN;

import ivory.all;

/**
 * https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
 *
 * Chess start position:
 *      rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1 
 */
final class FEN {
public:
    __gshared static START_POSITION = new FEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    byteboard board;        // List of (Piece | (Side<<3)) from A1-H1, B1-H2 etc
    Side sideToMove;
    uint castlingPermissions;
    square enPassantTargetSquare = NO_SQUARE;
    uint halfMoveClock;     // number of halfmoves since the last capture or pawn advance
    uint fullMoveNumber;    // incremented after black's move
    
    this(string s) {
        this.fenString = s;
        parse();
    }
    this(byteboard board, Side sideToMove, uint castlingPermissions, square enPassantTargetSquare, uint halfMoveClock, uint fullMoveNumber) {
        this.board = board;
        this.sideToMove = sideToMove;
        this.castlingPermissions = castlingPermissions;
        this.enPassantTargetSquare = enPassantTargetSquare;
        this.halfMoveClock = halfMoveClock;
        this.fullMoveNumber = fullMoveNumber;
        this.fenString = generateFenString();
    }

    bool opEquals(FEN other) {
        return sideToMove == other.sideToMove &&
               castlingPermissions == other.castlingPermissions &&
               enPassantTargetSquare == other.enPassantTargetSquare &&
               halfMoveClock == other.halfMoveClock &&
               fullMoveNumber == other.fullMoveNumber &&
               board[] == other.board;
    }
    override string toString() { 
        return fenString; 
    }
private:
    string fenString; 

    string generateFenString() {
        string fen;

        for(int r = 7; r>=0; r--) {
            int count = 0;
            for(int f = 0; f < 8; f++) {
                ubyte b = board[f + r*8];
                if(b == 0) {
                    count++;
                } else {
                    if(count > 0) {
                        fen ~= ('0' + count);
                        count = 0;
                    }
                    Piece piece = (b & 0b111).as!Piece;
                    Side side = (b>>>3).as!Side;
                    fen ~= fenChar(piece, side);
                }
            }    
            if(count > 0) {
                fen ~= ('0' + count);
            }
            if(r > 0) fen ~= "/";
        }
        fen ~= " %s".format(sideToMove == Side.WHITE ? "w" : "b");
        if(castlingPermissions) {
            fen ~= " %s%s%s%s".format(
                canCastleKingSide(castlingPermissions, Side.WHITE) ? "K" : "",
                canCastleQueenSide(castlingPermissions, Side.WHITE) ? "Q" : "",
                canCastleKingSide(castlingPermissions, Side.BLACK) ? "k" : "",
                canCastleQueenSide(castlingPermissions, Side.BLACK) ? "q" : "");
        } else {
            fen ~= " -";
        }
        fen ~= " %s".format(enPassantTargetSquare == NO_SQUARE ? "-" : algebraic(enPassantTargetSquare));
        fen ~= " %s".format(halfMoveClock);
        fen ~= " %s".format(fullMoveNumber);
        return fen;
    }
    void parse() {
        uint src = 0;
        char ch;
        uint rank = 56;
        uint file = 0;

        char _peek() { return src < fenString.length ? fenString[src] : 0; }
        char _consume() { char c = _peek(); src++; return c; }
        
        // Pieces
        outer: while(true) {
            uint count = 1;
            Piece piece = Piece.NONE;
            Side side = Side.WHITE;
            ch = _consume();

            switch(ch) {
                case 'P': piece = Piece.PAWN; side = Side.WHITE; break;
                case 'p': piece = Piece.PAWN; side = Side.BLACK; break;
                case 'B': piece = Piece.BISHOP; side = Side.WHITE; break;
                case 'b': piece = Piece.BISHOP; side = Side.BLACK; break;
                case 'N': piece = Piece.KNIGHT; side = Side.WHITE; break;
                case 'n': piece = Piece.KNIGHT; side = Side.BLACK; break;
                case 'R': piece = Piece.ROOK; side = Side.WHITE; break;
                case 'r': piece = Piece.ROOK; side = Side.BLACK; break;
                case 'Q': piece = Piece.QUEEN; side = Side.WHITE; break;
                case 'q': piece = Piece.QUEEN; side = Side.BLACK; break;
                case 'K': piece = Piece.KING; side = Side.WHITE; break;
                case 'k': piece = Piece.KING; side = Side.BLACK; break;
                case '1': ..case '9':
                    count = ch-'0';
                    break;
                case '/':
                    rank -= 8;
                    file = 0;
                    continue;
                default: break outer;
            }

            foreach(n; 0..count) {
                board[rank+file] = (piece | (side << 3)).as!ubyte;
                file++;
            }
        }

        // Side to move
        sideToMove = _consume() == 'w' ? Side.WHITE : Side.BLACK;
        throwIfNot(_consume() == ' ');
        
        // Castling permissions
        if(_peek() == 'K') {
            castlingPermissions |= Castling.WHITE_OO;
            _consume();
        }
        if(_peek() == 'Q') {
            castlingPermissions |= Castling.WHITE_OOO;
            _consume();
        }
        if(_peek() == 'k') {
            castlingPermissions |= Castling.BLACK_OO;
            _consume();
        }
        if(_peek() == 'q') {
            castlingPermissions |= Castling.BLACK_OOO;
            _consume();
        }
        if(castlingPermissions == 0) {
            throwIfNot(_consume() == '-');
        }
        throwIfNot(_consume() == ' ');

        // En passant square
        if(_peek() == '-') {
            _consume();
        } else {
            auto f = _consume() - 'a';
            auto r = _consume() - '1' - 1;
            enPassantTargetSquare = f + r*8;
        }
        throwIfNot(_consume() == ' ');

        // Half move clock
        import std.conv : to;
        string hmc = "";
        while((ch=_consume()) != ' ') {
            hmc ~= ch;
        }
        halfMoveClock = hmc.to!uint;

        // Full move number (starting from 1)
        string fm = "";
        while(true) {
            char c = _consume();
            if(c && c!=' ') fm ~= c; else break;
        }
        fullMoveNumber = fm.to!uint;
    }
} 
