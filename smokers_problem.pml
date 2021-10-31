#define Mutex byte

/* Каналы для моделирования работы программы */
chan barmanChannel = [100] of {int};
chan makeChannel = [100] of {int};
chan smokeChannel = [100] of {int};

/* Мьютексы курильщиков */
Mutex tobaccoAndPaper = 0;
Mutex tobaccoAndMatches = 0;
Mutex matchesAndPaper = 0;

Mutex isSmoking = 0;
Mutex emptyTable = 1;

/* ID следующего курильщика */
int nextSmoker;

/* Процедуры работы с мьютексами */
inline unlock(mutex) { atomic { mutex < 1; mutex++; }}
inline lock(mutex) { atomic{ mutex > 0 ; mutex--; }}

/*  Процедуры работы потока курильщика */
inline makeCigarette(mutex) { lock(mutex); unlock(emptyTable); unlock(isSmoking); }
inline smokeCigarette() { lock(isSmoking); }

proctype Barman() {
    do ::
        emptyTable == 1;				// Если стол свободен
        lock(emptyTable);
        nextSmoker = 0; select( nextSmoker : 2 .. 4); barmanChannel ! nextSmoker;			// Выбираем случайного курильщика
        if 
            :: nextSmoker == 2 -> unlock(tobaccoAndPaper);
            :: nextSmoker == 3 -> unlock(tobaccoAndMatches);
            :: nextSmoker == 4 -> unlock(matchesAndPaper);
        fi
    od
}

proctype SmokerMike() {
    do
        :: tobaccoAndPaper == 1; 			 		// Если выложены табак и бумага
           isSmoking == 0; 			      		// И никто в данный момент не курит 
           makeChannel ! 1; makeCigarette(tobaccoAndPaper); 
           smokeChannel ! _pid; smokeCigarette();  
    od
}

proctype SmokerAndrew() {
    do
        :: tobaccoAndMatches == 1; 					// Если выложены табак и спички
           isSmoking == 0; 					// И никто в данный момент не курит 
           makeChannel ! 1; makeCigarette(tobaccoAndMatches); 
           smokeChannel ! _pid; smokeCigarette();  
    od
}

proctype SmokerJake() {
    do
        :: matchesAndPaper == 1; 					// Если выложены спички и бумага
           isSmoking == 0; 					// И никто в данный момент не курит
           makeChannel ! 1; makeCigarette(matchesAndPaper); 
           smokeChannel ! _pid; smokeCigarette(); 
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

