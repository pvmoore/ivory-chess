module ivory.eval.Evaluator;

import ivory.all;

interface Evaluator {
    int evaluate(Position pos);
}

float getEndgamePercentage(uint numWhitePieces, uint numBlackPieces) {
    // Assume 1: Likely max total number of pieces is 32
    // Assume 2: If number of pieces is 6 we are fully in the endgame
    
    uint totalPieces = minOf(numWhitePieces + numBlackPieces, ENDGAME.length.as!uint - 1);
    return ENDGAME[totalPieces];
}

__gshared {
    immutable(float)[] ENDGAME = [
        //0   1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16
        1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0, 

        //17  18   19   20   21   22   23   24   25   26   27  28   29   30    31   32   
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
    ];
}
