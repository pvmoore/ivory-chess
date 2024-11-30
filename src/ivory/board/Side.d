module ivory.board.Side;

import ivory.all;

enum Side {
    WHITE   = 0,
    BLACK   = 1
}

Side opposite(Side s) {
    return s == Side.WHITE ? Side.BLACK : Side.WHITE;
}
