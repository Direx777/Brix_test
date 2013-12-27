%%Главный модуль тестирования Brix

-module(brix_test_app).
-behaviour(application).
-export([start/2, stop/1]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([]).



%% ====================================================================
%% Behavioural functions
%% ====================================================================

%% start/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/apps/kernel/application.html#Module:start-2">application:start/2</a>
-spec start(Type :: normal | {takeover, Node} | {failover, Node}, Args :: term()) ->
	{ok, Pid :: pid()}
	| {ok, Pid :: pid(), State :: term()}
	| {error, Reason :: term()}.
%% ====================================================================
start(_Type, _StartArgs) ->
	{ok, _}	= ranch:start_listener(bt_tcp_devices, 2, ranch_tcp, [{port,7068}], bt_device_proto, []), %Прослушка девайсов
    {ok, _} = ranch:start_listener(bt_tcp_supervisor, 2, ranch_tcp, [{port, 7075}], bt_supervisor_proto, []), %супервизор (отладка)
	brix_test_sup:start_link().

%% stop/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/apps/kernel/application.html#Module:stop-1">application:stop/1</a>
-spec stop(State :: term()) ->  Any :: term().
%% ====================================================================
stop(State) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================


