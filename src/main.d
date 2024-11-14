module main;

import ivory.all;

void main() {

	//createData();


	Ivory ivory = new Ivory();

	// Run stdin/stdout repl until 'quit' is received
	ivory.repl();
}

/+
void createData() {

	MailboxMoveGenerator gen = new MailboxMoveGenerator();
	MailboxPosition pos = new MailboxPosition();

	uint[][uint] hash;

	ulong m = 0;

	ulong[64] counts;

	foreach(sq; 0..64) {
		pos.set(sq, Piece.ROOK, Side.WHITE);
		uint numMoves = gen.generate(pos);

		assert(numMoves == 14);
		pos.setEmpty(sq);

		m = maxOf(m, numMoves);

		foreach(i; 0..numMoves) {
			Move mv = gen.popMove();
			assert(mv.from() == sq);

			hash[sq] ~= mv.to();
		}

		uint[] list = hash[sq];
		list.sort();
		foreach(j; 0..14) {
			uint v = j < list.length ? list[j] : 0;
			writef("%s, ", v);
		}
		counts[sq] = hash[sq].length;

		writefln(" // %s", sq);
	}

	writefln("m = %s", m);
	writefln("counts = %s", counts);
}
+/
