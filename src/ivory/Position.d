module ivory.Position;

import ivory.all;

alias PosKey = ulong; 

interface Position {

    PosKey key();
    
    void makeMove(Move);

    void unmakeMove();
}
