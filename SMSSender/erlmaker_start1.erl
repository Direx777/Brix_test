-module(erlmaker_start1).
-export([start/0]).
start() ->
application:load(smssender),
application:start(smssender),
io:format("All loaded~n" ).
