module ivory.MoveList;

import ivory.all;

final class MoveList {
public:
    uint length() { return pos; }
    
    this() {
        moves.length = 1024;
    }
    void push(Move m) {
        assert(pos < moves.length);
        moves[pos++] = m;
    }
    Move pop() {
        assert(pos > 0);
        return moves[--pos];
    }
    bool contains(Move m) {
        return moves[0..pos].any!(it=>it == m);
    }
    Move find(square from, square to) {
        return moves[0..pos].find!(it=>it.from() == from && it.to() == to).frontOrElse(NO_MOVE);
    }
    override string toString() {
        return "%s".format(moves[0..pos]);
    }
private:
    Move[] moves;
    uint pos;
}
