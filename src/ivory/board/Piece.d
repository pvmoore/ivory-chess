module ivory.board.Piece;

import ivory.all;

enum Piece {   
    NONE    = 0,
    PAWN    = 1,   
    BISHOP  = 2, 
    KNIGHT  = 3, 
    ROOK    = 4,   
    QUEEN   = 5,  
    KING    = 6,
    MAX     = KING   
}

bool isRookOrQueen(Piece p) {
    return p == Piece.ROOK || p == Piece.QUEEN;
}
bool isBishopOrQueen(Piece p) {
    return p == Piece.BISHOP || p == Piece.QUEEN;
}
char fenChar(Piece p, Side s) {
    enum blackPieces = " pbnrqk";
    enum whitePieces = " PBNRQK";   
    return s == Side.WHITE ? whitePieces[p.as!int] : blackPieces[p.as!int];
}
char unicodeChar(Piece p, Side s) {
    enum blackPieces = " ♙♗♘♖♕♔";
    enum whitePieces = " ♟♝♞♜♛♚";   
    return s == Side.WHITE ? whitePieces[p.as!int] : blackPieces[p.as!int];
}
int material(Piece p) {
    final switch(p) with(Piece) {
        case NONE: return 0;   
        case PAWN: return 100;   
        case BISHOP: return 300;  
        case KNIGHT: return 300; 
        case ROOK: return 500;     
        case QUEEN: return 900;  
        case KING: return 100000;  
    }
}
