module ivory.Piece;

import ivory.all;

enum Piece {   
    NONE    = 0,
    PAWN    = 1,   
    BISHOP  = 2, 
    KNIGHT  = 3, 
    ROOK    = 4,   
    QUEEN   = 5,  
    KING    = 6   
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
