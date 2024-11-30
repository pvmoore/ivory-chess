module ivory.board.Castling;

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

__gshared {
    private enum Z   = 0b1111;
    private enum W   = 0b1100;
    private enum B   = 0b0011;
    private enum WKS = 0b1110;
    private enum WQS = 0b1101;
    private enum BKS = 0b1011;
    private enum BQS = 0b0111;

    immutable(uint)[] SQ_CASTLE_MASKS = [
      // Note: These squares go from 0 to 63 ie the ranks are the opposite of the standard board layout

        WQS, Z, Z, Z, W, Z, Z, WKS,
          Z, Z, Z, Z, Z, Z, Z, Z,
          Z, Z, Z, Z, Z, Z, Z, Z,
          Z, Z, Z, Z, Z, Z, Z, Z,
          Z, Z, Z, Z, Z, Z, Z, Z,
          Z, Z, Z, Z, Z, Z, Z, Z,
          Z, Z, Z, Z, Z, Z, Z, Z,
        BQS, Z, Z, Z, B, Z, Z, BKS
    ];
}
