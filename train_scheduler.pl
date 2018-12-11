:- use_module(library(clpfd)).
:- dynamic edge/4, train/5, vertices/1, num_trains/1, rpath/2.

schedule_trains(L, Sum):-
	num_trains(N),
	length(L, N),
	init_trains(L, 1),
	release_time(L, 1),
	flatten(L, Flat),
	check_different_direction(L),
	check_same_direction(Flat),
	get_departures(Flat, D),
	tardiness(L, 1, Sum),
	labeling([ff, min(Sum)], [Sum|D]). 

%Release Time constraint for each train
%First departure of each train is constrained according to release time
release_time([], _).
release_time([[stop(_, _, Departure, _)|_]|T], Index):-
	train(Index, Release, _, _, _),
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
	nth1(Len, H, stop(_, _, _, Arrival)),
	train(Index, _, Due, _, _),
	D #= abs(Arrival - Due).

init_trains([],_).
init_trains([H|T],Counter):-
	train(Counter,_,_, From, To),
	findPath(From, To, Path),
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
init_lines([stop(Start,End,Departure,Arrival)|Rest],[Departure, Arrival|RestVars], [Start,End|T]):-
	[Departure, Arrival] ins 0..400,
	edge(Start, End, Duration, _),
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
check_edge_with_stop((Start, End), [stop(Start, End, Departure, _)|T], [Departure|Rest], [10|Rest2]):-
	check_edge_with_stop((Start, End), T, Rest, Rest2).
	
check_edge_with_stop((Start, End), [stop(Start2, End2, _, _)|T], Rest1, Rest2):-
	(Start \= Start2;End \= End2),
	check_edge_with_stop((Start, End), T, Rest1, Rest2).
	
all_edges([], []).
all_edges([V|VT], [Edges|ET]):-
	all_edges_helper(V, VT, Edges),
	all_edges(VT, ET). 

all_edges_helper(_, [], []).
all_edges_helper(V, [H|T], [(V, H), (H, V)|Rest]):-
	edge(V, H, _, _),
	all_edges_helper(V, T, Rest).
all_edges_helper(V, [H|T], Rest):-
	\+edge(V, H, _, _),
	\+edge(H, V, _, _),
	all_edges_helper(V, T, Rest).
	
check_different_direction([_]).
check_different_direction([H|T]):-
	check_train_with_rest(H, T),
	check_different_direction(T).

check_train_with_rest([], _).
check_train_with_rest([H|T], Trains):-
	flatten(Trains, Flat),
	check_stop_with_train(H, Flat),
	check_train_with_rest(T, Trains).

 
check_stop_with_train(_, []).

%Use cumulative for double connections
check_stop_with_train(stop(Start, End, Departure1, Arrival1), [stop(End, Start, _, _)|T]):-
	edge(Start, End, _, 2),
	check_stop_with_train(stop(Start, End, Departure1, Arrival1), T).

%Use serialized for single connections
check_stop_with_train(stop(Start, End, Departure1, Arrival1), [stop(End, Start, Departure2, _)|T]):-
	edge(Start, End, Duration, 1),
	serialized([Departure1, Departure2], [Duration, Duration]),
	check_stop_with_train(stop(Start, End, Departure1, Arrival1), T).

check_stop_with_train(stop(Start1, End1, Departure1, Arrival1), [stop(Start2, End2, _, _)|T]):-
	%(Start1 \= Start2; End1 \= End2),
	(Start1 \= End2; End1 \= Start2),
	check_stop_with_train(stop(Start1, End1, Departure1, Arrival1), T).
	
	
get_departures([], []).
get_departures([stop(_, _, _, D)|T], [D|Rest]):-
	get_departures(T, Rest).

/*
num_trains(11).
train(1,0,240, f, a).
train(2,60,270, i, a).
train(3,30,210, i, m).
train(4,60,300, m, a).
train(5,180,360, a, j).
train(6,120,330, a, f).
train(7,90,240, c, m).
train(8,30,210, h, f).
train(9,60,300, m, g).
train(10,90,300, m, d).
train(11,150,300, f, i).

vertices([a, b, c, d, e, f, g, h, i, j, l, m, k]).
edge(a,b,40, 1).
edge(b,a,40, 1).
edge(b,c,40, 2).
edge(c,b,40, 2).
edge(c,k,60, 1).
edge(k,c,60, 1).
edge(c,d,50, 1).
edge(d,c,50, 1).
edge(d,e,35, 1).
edge(e,d,35, 1).
edge(e,f,35, 1).
edge(f,e,35, 1).
edge(d,g,30, 2).
edge(g,d,30, 2).
edge(g,h,30, 1).
edge(h,g,30, 1).
edge(h,i,25, 1).
edge(i,h,25, 1).
edge(h,j,30, 1).
edge(j,h,30, 1).
edge(j,l,60, 2).
edge(l,j,60, 2).
edge(l,m,20, 1).
edge(m,l,20, 1).
edge(l,k,60, 1).
edge(k,l,60, 1).*/

%Dijkstra's algorithm to obtain fastest path
path(From,To,Dist) :- edge(To,From,Dist, _).
 
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
 
findPath(From, To,Path) :-
	traverse(From),                   % Find all distances
	rpath([To|RPath], _)->         % If the target was reached
	  reverse([To|RPath], Path).