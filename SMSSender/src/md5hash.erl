%% @author Dmitry
%% @doc @todo Add description to md5hash.


-module(md5hash).

%% ====================================================================
%% API functions
%% ====================================================================
-export([md5_hex/1]).

  md5_hex(S) ->
  	Md5_bin = erlang:md5(S),
  	Md5_list = binary_to_list(Md5_bin),
  	lists:flatten(list_to_hex(Md5_list)).

 
%% ====================================================================
%% Internal functions
%% ====================================================================

list_to_hex(L)->
  	lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
  	[hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
  	$0+N;
hex(N) when N >= 10, N < 16 ->
	$a + (N-10).
