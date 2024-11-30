module ivory.utils;

import ivory.all;

struct Stack(T,uint CAP) {
public:
    void push(T v) { 
        assert(pos < CAP, "push() %s >= %s".format(pos, CAP));
        array[pos++] = v; 
    }
    T pop() { 
        assert(pos > 0, "pop() stack is empty");
        return array[--pos]; 
    }
    uint length() { return pos; }

    /** While fn returns true, iterate through elements in LIFO order calling fn with the element ref */
    void iterateWhile(bool delegate(ref T) fn) {
        foreach_reverse(i; 0..pos) {
            if(!fn(array[i])) return;
        }
    }
private:
    T[CAP] array;
    int pos;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
struct ElasticArray(T) {
public:
    void reset() {
        array.length = 0;
    }
    void set(uint index, T value) {
        if(index >= array.length) array.length = index + 1;
        array[index] = value;
    }
    T get(uint index) {
        if(index >= array.length) return T.init;
        return array[index];
    }
    T[] getSlice() {
        return array[];
    }
private:
    T[] array;
}
//──────────────────────────────────────────────────────────────────────────────────────────────────
T maxOf(T)(T a, T b) {
    return a > b ? a : b;
}
T minOf(T)(T a, T b) {
    return a < b ? a : b;
}

private import std.stdio    : File, writeln, writefln, write, writef, readln;
private import std.string   : strip;

__gshared File uciLogger;

private void logUci(A...)(string fmt, A args) {
    if(!uciLogger.isOpen) {
        uciLogger.open(".logs/uci.log", "w");
    }
    uciLogger.write(format(fmt, args));
    uciLogger.write("\n");
    uciLogger.flush();
}

string uciReadLine() {
    string line = readln();
    logUci(">> %s", line.strip());
    return line;
}
void uciWriteLine(A...)(string fmt, A args) {
    uciWriteLine(format(fmt, args));
}    
void uciWriteDebugLine(A...)(string fmt, A args) {
    uciWriteLine(format("debug: " ~ fmt, args));
}
void uciWriteLine(string line) {    
    writeln(line);
    flushConsole();
    logUci("<< %s", line);
}
