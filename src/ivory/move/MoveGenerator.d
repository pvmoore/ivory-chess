module ivory.move.MoveGenerator;

import ivory.all;

interface MoveGenerator {
    /**
     * Generate moves for Position and return the number of moves generated.
     */
    uint generate(Position pos, bool capturesOnly);

    /** 
     * Return the next Move
     */
    Move popMove();

    /**
     * Return the number of moves which can be popped.
     */
    uint getNumMoves();

    /** 
     * Discard num moves 
     */
    void discardMoves(uint num);
}
