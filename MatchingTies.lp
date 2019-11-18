ties(salmon;green;brown).
person(mr_salmon;mr_brown;mr_green).
1{outfit(T,P):ties(T)}1 :- person(P).
1{outfit(T,P):person(P)}1 :- ties(T).
:- outfit(salmon, mr_salmon; green,mr_green; brown, mr_brown; green,mr_brown).
