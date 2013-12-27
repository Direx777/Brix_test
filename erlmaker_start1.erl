-module(erlmaker_start1).
-export([start/0]).
start() ->
application:load(ranch),
application:start(ranch),
application:load(cowlib),
application:start(cowlib),
application:load(crypto),
application:start(crypto),
application:load(cowboy),
application:start(cowboy),
application:load(epgsql),
application:start(epgsql),
application:load(poolboy),
application:start(poolboy),
application:load(brix_test),
application:start(brix_test),
io:format("All loaded~n" ).
