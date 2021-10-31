#define Mutex byte

chan barmanChannel = [100] of {int};
chan makeChannel = [100] of {int};
chan smokeChannel = [100] of {int};

Mutex tobaccoAndPaper = 0;
Mutex tobaccoAndMatches = 0;
Mutex matchesAndPaper = 0;

Mutex isSmoking = 0;
Mutex emptyTable = 1;

int nextSmoker;

inline unlock(mutex) { atomic { mutex < 1; mutex++; }}
inline lock(mutex) { atomic{ mutex > 0 ; mutex--; }}

inline makeCigarette(mutex) { lock(mutex); unlock(emptyTable); unlock(isSmoking); }
inline smokeCigarette() { lock(isSmoking); }

proctype Barman() {
    do ::
        emptyTable == 1; 
        lock(emptyTable);
        nextSmoker = 0; select( nextSmoker : 2 .. 4); barmanChannel ! nextSmoker;
        if 
            :: nextSmoker == 2 -> unlock(tobaccoAndPaper);
            :: nextSmoker == 3 -> unlock(tobaccoAndMatches);
            :: nextSmoker == 4 -> unlock(matchesAndPaper);
        fi
    od
}

proctype SmokerMike() {
    do
        :: tobaccoAndPaper == 1; 
           isSmoking == 0; 
           makeCigarette(tobaccoAndPaper); makeChannel ! 1; 
           smokeCigarette(); smokeChannel ! _pid;
    od
}

proctype SmokerAndrew() {
    do
        :: tobaccoAndMatches == 1; 
           isSmoking == 0; 
           makeCigarette(tobaccoAndMatches); makeChannel ! 1; 
           smokeCigarette(); smokeChannel ! _pid;
    od
}

proctype SmokerJake() {
    do
        :: matchesAndPaper == 1; 
           isSmoking == 0; 
           makeCigarette(matchesAndPaper); makeChannel ! 1; 
           smokeCigarette(); smokeChannel ! _pid;
    od
}

init{
    atomic{
        run Barman();
        run SmokerMike();
        run SmokerAndrew();
        run SmokerJake();
    }
}

