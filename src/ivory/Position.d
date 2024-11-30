module ivory.Position;

import ivory.all;

interface Position {

    uint key();
    
    void makeMove(Move);

    void unmakeMove();
}
