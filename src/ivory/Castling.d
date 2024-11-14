module ivory.Castling;

import ivory.all;

enum Castling {
    WHITE_OO    = 1,    // King side
    WHITE_OOO   = 2,    // Queen side
    BLACK_OO    = 4,    // King side
    BLACK_OOO   = 8     // Queen side
}

bool canCastleKingSide(uint permissions, Side side) {
    return side == Side.WHITE ? (permissions&Castling.WHITE_OO) != 0
                              : (permissions&Castling.BLACK_OO) != 0;
}
bool canCastleQueenSide(uint permissions, Side side) {
    return side == Side.WHITE ? (permissions&Castling.WHITE_OOO) != 0
                              : (permissions&Castling.BLACK_OOO) != 0;
}
void removePermission(ref uint permissions, Castling perm) {
    permissions &= ~perm;
}
