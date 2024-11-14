module ivory.Game;

import ivory.all;

final class Game {
public:
    MailboxPosition pos;
    int ply;

    this(FEN fen) {
        this.startPosition = fen;

        restart();
    }
    void restart() {
        ply = 0;
        pos = new MailboxPosition();
        pos.fromFEN(startPosition);
        moveGen = new MailboxMoveGenerator();
    }
    void setPosition(FEN fen) {
        // if fen == current FEN then ignore otherwise change the current pos

        FEN current = pos.getFEN();

        // Note that the opponent's move should now be applied and we can start searching 

    }
    void makeMove(Move m) {
        assert(isLegalMove(m));

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
        auto gen = new MailboxMoveGenerator();
        gen.generate(pos);
        auto legalMoves = gen.getMoves();
        return legalMoves.contains(m);
    }
private:
    FEN startPosition;
    MailboxMoveGenerator moveGen;
}
