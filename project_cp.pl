:- use_module(library(clpfd)).

schedule_trains(L, Sum):-
	length(L, 1),
	init_trains(L, 1),
	release_time(L, 1),
	flatten(L, Flat),
	check_trains(L),
	check_same_direction(Flat),
	get_departures(Flat, D),
	tardiness(L, 1, Sum),
	!,
	labeling([ff, min(Sum)], [Sum|D]). 

%Release Time constraint for each train
%First departure of each train is constrained according to release time
release_time([], _).
release_time([[(_, _, Departure, _)|_]|T], Index):-
	train(Index, Release, _, _),
	Departure #>= Release,
	Index1 is Index+1,
	release_time(T, Index1).
	
tardiness([], _, 0).
tardiness([H|T], Index, Sum):-
	difference(H, Index, D),
	Index1 is Index+1,
	Sum #= D + Interm,
	tardiness(T, Index1, Interm).

difference(H, Index, D):-
	length(H, Len),
	nth1(Len, H, (_, _, _, Arrival)),
	train(Index, _, Due, _),
	D #= abs(Arrival - Due).

init_trains([],_).
init_trains([H|T],Counter):-
	train(Counter,_,_, Path),
	init_train(H,Path),
	Counter1 is Counter+1,
	init_trains(T,Counter1).

init_train(Train,Path):-
	length(Path,PathLength),
	TrainPathLength is PathLength-1,
	length(Train,TrainPathLength),
	init_lines(Train,Vars,Path),
	chain(Vars, #=<).

init_lines([],[], _).
init_lines([(Start,End,Departure,Arrival)|Rest],[Departure, Arrival|RestVars], [Start,End|T]):-
	[Departure, Arrival] ins 0..400,
	edge(Start, End, Duration),
	Arrival #= Departure + Duration,
	init_lines(Rest, RestVars, [End|T]).

check_same_direction(TrainStops):-
	vertices(V),
	all_edges(V, E),
	flatten(E, Edges),
	check_all_edges_with_stops(Edges, TrainStops).
	
check_all_edges_with_stops([], _).
check_all_edges_with_stops([Edge|Edges], TrainStops):-
	check_edge_with_stop(Edge, TrainStops, Departures, Durations),
	serialized(Departures, Durations),
	check_all_edges_with_stops(Edges, TrainStops).	

check_edge_with_stop(_, [], [], []).
check_edge_with_stop((Start, End), [(Start, End, Departure, _)|T], [Departure|Rest], [10|Rest2]):-
	check_edge_with_stop((Start, End), T, Rest, Rest2).
	
check_edge_with_stop((Start, End), [(Start2, End2, _, _)|T], Rest1, Rest2):-
	(Start \= Start2;End \= End2),
	check_edge_with_stop((Start, End), T, Rest1, Rest2).
	
all_edges([], []).
all_edges([V|VT], [Edges|ET]):-
	all_edges_helper(V, VT, Edges),
	all_edges(VT, ET). 

all_edges_helper(_, [], []).
all_edges_helper(V, [H|T], [(V, H), (H, V)|Rest]):-
	edge(V, H, _),
	all_edges_helper(V, T, Rest).
all_edges_helper(V, [H|T], Rest):-
	\+edge(V, H, _),
	\+edge(H, V, _),
	all_edges_helper(V, T, Rest).
	
check_trains([_]).
check_trains([H|T]):-
	check_train_with_all(H, T),
	check_trains(T).

check_train_with_all([], _).
check_train_with_all([H|T], Trains):-
	flatten(Trains, Flat),
	check_edge_with_train(H, Flat),
	check_train_with_all(T, Trains).


check_edge_with_train(_, []).
/*
check_edge_with_train((Start, End, Departure1, Arrival1), [(Start, End, Departure2, _)|T]):-
	%abs(Departure1 - Departure2) #>= 10,
	serialized([Departure1, Departure2], [10, 10]),
	check_edge_with_train((Start, End, Departure1, Arrival1), T).
*/
check_edge_with_train((Start, End, Departure1, Arrival1), [(End, Start, Departure2, _)|T]):-
	edge(Start, End, Duration),
	%abs(Departure1 - Departure2) #>= Duration,
	serialized([Departure1, Departure2], [Duration, Duration]),
	check_edge_with_train((Start, End, Departure1, Arrival1), T).

check_edge_with_train((Start1, End1, Departure1, Arrival1), [(Start2, End2, _, _)|T]):-
	%(Start1 \= Start2; End1 \= End2),
	(Start1 \= End2; End1 \= Start2),
	check_edge_with_train((Start1, End1, Departure1, Arrival1), T).
	
	
get_departures([], []).
get_departures([(_, _, _, D)|T], [D|Rest]):-
	get_departures(T, Rest).

train(1,0,240, [f, e, d, c, b, a]).
train(2,60,270, [i, h, g, d, c, b, a]).
train(3,30,210, [i, h, j, l, m]).
train(4,60,300, [m, l, k, c, b, a]).
train(5,180,360, [a, b, c, d, g, h, j]).
train(6,120,330, [a, b, c, d, e, f]).
train(7,90,240, [c, k, l, m]).
train(8,30,210, [h, g, d, e, f]).
train(9,60,300, [m, l, j, h, g]).
train(10,90,300, [m, l, j, h, g, d]).
train(11,150,300, [f, e, d, g, h, i]). 

vertices([a, b, c, d, e, f, g, h, i, j, l, m, k]).
edge(a,b,40).
edge(b,a,40).
edge(b,c,40).
edge(c,b,40).
edge(c,k,60).
edge(k,c,60).
edge(c,d,50).
edge(d,c,50).
edge(d,e,35).
edge(e,d,35).
edge(e,f,35).
edge(f,e,35).
edge(d,g,30).
edge(g,d,30).
edge(g,h,30).
edge(h,g,30).
edge(h,i,25).
edge(i,h,25).
edge(h,j,30).
edge(j,h,30).
edge(j,l,60).
edge(l,j,60).
edge(l,m,20).
edge(m,l,20).
edge(l,k,60).
edge(k,l,60).

/*
%Helpers to find possible collisions and add constraints
collision(_, []).
collision(Route1, [Route2|T]):-
	collision_helper(Route1, Route2),
	collision(Route1, T).

collision_helper([], _).
collision_helper([(Start, End, Departure, Arrival)|T], Route2):-
	member((End, Start, Departure2, Arrival2), Route2),
	(edge(Start, End, Duration);edge(End, Start, Duration)),
	%serialized([Departure, Departure2], [Duration, Duration]),
	cumulative([task(Departure, Duration, Arrival, 1, _), task(Departure2, Duration, Arrival2, 1, _)]),
	collision_helper(T, Route2).
collision_helper([(Start, End, Departure, _)|T], Route2):-
	\+member((End, Start, _, _), Route2),
	collision_helper(T, Route2). 
	
edges([]).
edges([H|L]):-
	% print(H),nl,
	helper_edges(H),
	edges(L).
%Helper edges takes a list of tuples and constraints the arrival and departure
helper_edges([(_,_,_,_)]).
helper_edges([]).
helper_edges([(From, To, Departure, Arrival),(From2,To2,Departure2,Arrival2)|L]):-
	(edge(From,To,Length);edge(To,From,Length)),
	(edge(From2,To2,Length2);edge(To2,From2,Length2)),
	% print(From),print(To),nl,
	% print(Length),nl,
	% print(From2),print(To2),nl,
	% print(Length2),nl,
	%Node= [(From2 ,To2,Departure2,Arrival2)],
	Arrival #= Departure+Length,
	Departure2 #>= Arrival,
	Arrival2#=Departure2+Length2,
	%append(Node,L,L1),
	% print(L1),nl,
	helper_edges([(From2,To2,Departure2,Arrival2)|L]).	


get_departure([],[]).
get_departure([H|L],Departures):-
	get_departure_helper(H,Departure1),
	get_departure(L,Departure2),
	append(Departure1,Departure2,Departures).
 
 
get_departure_helper([(_,_,Dep,Arrival)|L],Departures):-
	Departure=[Dep,Arrival],
	get_departure_helper(L,Departure2),
	append(Departure,Departure2,Departures).
 
get_departure_helper([],[]).



check_same_direction([]).
check_same_direction([H|T]):-
check_train_with_all(H,T),
check_same_direction(T).
 
check_train_with_all([],_).
check_train_with_all([H|T],Trains):-
check_edge_with_all(H,Trains),
check_train_with_all(T,Trains).
 
check_edge_with_all(_,[]).
check_edge_with_all(Edge,[Train|Trains]):-
check_edge_with_train(Edge,Train),
check_edge_with_all(Edge,Trains).
 
check_edge_with_train(_,[]).
check_edge_with_train((From,To,Departure,Arrival),[(X,Y,_,_)|Edges]):-
(X \= From;Y \= To),
check_edge_with_train((From,To,Departure,Arrival),Edges).
 
 
check_edge_with_train((From,To,Departure,Arrival),[(From,To,Dept,_)|Edges]):-
abs(Departure-Dept) #>= 10,
check_edge_with_train((From,To,Departure,Arrival),Edges).

	
%Constraint for trains using the same edge in different directions
diff_dir([]).
diff_dir([H|T]):-
	collision(H, T),
	diff_dir(T).


 
path(From,To,Dist) :- edge(To,From,Dist).
path(From,To,Dist) :- edge(From,To,Dist).
 
shorterPath([H|Path], Dist) :-		       % path < stored path? replace it
	rpath([H|_], D), !, Dist < D,          % match target node [H|_]
	retract(rpath([H|_],_)),
	assert(rpath([H|Path], Dist)).
shorterPath(Path, Dist) :-		       % Otherwise store a new path
	assert(rpath(Path,Dist)).
 
traverse(From, Path, Dist) :-		    % traverse all reachable nodes
	path(From, T, D),		    % For each neighbor
	not(memberchk(T, Path)),	    %	which is unvisited
	shorterPath([T,From|Path], Dist+D), %	Update shortest path and distance
	traverse(T,[From|Path],Dist+D).	    %	Then traverse the neighbor
 
traverse(From) :-
	retractall(rpath(_,_)),           % Remove solutions
	traverse(From,[],0).              % Traverse from origin
traverse(_).
 
go(From, To,Path) :-
	traverse(From),                   % Find all distances
	rpath([To|RPath], _)->         % If the target was reached
	  reverse([To|RPath], Path).
 */