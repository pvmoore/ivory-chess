module ivory.Game;

import ivory.all;

final class Game {
public:
    MBPosition pos;
    int ply;
    ulong whiteTimeMs;
    ulong blackTimeMs;

    this(FEN fen) {
        restart();
    }
    void restart() {
        this.ply = 0;
        this.pos = createMailboxPosition(FEN.START_POSITION);
    }
    void setPosition(Position pos) {
        this.pos = pos.as!MBPosition;
    }
    Move findBestMove() {
        auto search = new Search(new MBMoveGenerator(), new MBEvaluator());
        return search.getBestMove(pos, pos.state.sideToMove == Side.WHITE ? whiteTimeMs : blackTimeMs);
    }
    void asyncFindBestMove(void delegate(Move) andThen) {
        auto search = new Search(new MBMoveGenerator(), new MBEvaluator());
        Move move = search.asyncGetBestMove(pos, pos.state.sideToMove == Side.WHITE ? whiteTimeMs : blackTimeMs);
        andThen(move);
    }
    void makeMove(Move m) {
        assert(isLegalMove(m));

        if(pos.isRepeatMove(m)) {
            uciWriteDebugLine("!! repeat move");
        } 

        uciWriteDebugLine("making move %s", m);

        ply++;
        pos.makeMove(m);
    }
    void unmakeMove() {
        assert(ply > 0);
        assert(pos.history.length() > 0);
        ply--;
        pos.unmakeMove();
    }
    bool isLegalMove(Move m) {
        auto gen = new MBMoveGenerator();
        gen.generate(pos, false);
        auto legalMoves = gen.getMoves();
        return legalMoves.contains(m);
    }
private:
}
