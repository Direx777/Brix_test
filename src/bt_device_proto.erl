%%Это обработчик TCP запросов (протокол в терминологии рэнча)
%%Для девайсов (автомобилей в нашем случае)

-module(bt_device_proto).
-behaviour(gen_server).
-behaviour(ranch_protocol).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/4]).
-export([init/4]).
-export([stop/0]).

%% ====================================================================
%% API functions
%% ====================================================================
%-export([parse_ext_data/1]).



%% ====================================================================
%% Behavioural functions 
%% ====================================================================

-record(innerstate, {ref, socket, transport, opts}). %Такой будет статус (внутренний, для его нужд) у этого ген-сервера передаваться
%ConState: {Type,ProtoID}  PID передавать в процесс не надо, но вот MDI можно, т.к. по нему можно найти верзний протокол
%Type: new | auth | normal Из-за двойной авторизации здесь такое происходит
%Соединение хранит данные: protoID (это базовый protoID) | sesID,MDI,uniq | MDI,uniq
%State будет иметь такой вид: {innerstate,outerstate}
%Про статусы надо сказать 
%
%
%outerstate: 	1. new | auth | normal
%				2. Kernel_MDI_name | Low_proto | 

start_link(Ref, Socket, Transport, Opts) ->
    proc_lib:start_link(?MODULE, init, [Ref, Socket, Transport, Opts]).

init(Ref, Socket, Transport, Opts = []) ->
    ok = proc_lib:init_ack({ok, self()}),
    %% Perform any required state initialization here.
    ok = ranch:accept_ack(Ref),
	%единичный прием, короче делаем так всегда, чтобы от флуда не страдать и помимо этого прием сообщений от TCP в посылке
    ok = Transport:setopts(Socket, [{active, once},{packet,line}]), %Чтение до #13#10
    gen_server:enter_loop(?MODULE, [], #innerstate{ref = Ref, socket = Socket, transport = Transport, opts = Opts}).
%{ok, #state{type = accept_client, ref = Ref, socket = Socket, transport = Transport, opts = Opts}, 0}
init([]) ->
    {ok, #innerstate{}}.

stop() ->
    gen_server:cast(self(), stop).

handle_call(Request, From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(Msg, State) ->
    {noreply, State}.


handle_info(Info, State) ->
    Socket = State#innerstate.socket,
    Transport = State#innerstate.transport,
    {OK, Closed, Error} = Transport:messages(),
    {RemoteIP, RemotePort} = get_ip_and_port(Transport, Socket),
    case Info of
        {OK, Socket, Data} ->
            ok = Transport:setopts(Socket, [{active, once}]),
            io:format(">>> Data received from ~w:~w ('~w'). Data = ~p~n", [RemoteIP, RemotePort, self(), Data]),
			send_data_to_client(State, [<<"You send ">>,Data]),
            %parse_ext_data(Data),
            {noreply, State};
		{send,Data} ->
			io:format(">>> Sending data ~w:~w ('~w'). Data = ~p~n", [RemoteIP, RemotePort, self(), Data]),
			send_data_to_client(State, Data),
			{noreply, State};
        {Closed, Socket} ->
            io:format(">>> Client '~w' did disconnected.~n", [self()]),
            {stop, normal, State};
        {Error, Socket, Reason} ->
            io:format(">>> Error happend. Client ~w:~w ('~w'). Reason = ~p~n", [RemoteIP, RemotePort, self(), Reason]),
            ok = Transport:setopts(Socket, [{active, once}]),
            {noreply, State};
        _ ->
            io:format("Unknown handle_info info. Info = ~w~n", [Info]),
            {noreply, State}
    end.


terminate(Reason, State) ->
    ok.

code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================
get_ip_and_port(Transport, Socket) ->
    PeerName = Transport:peername(Socket),
    {RemoteIP, RemotePort} = case PeerName of
                                 {ok, {Address, Port}} ->
                                     {Address, Port};
                                 _ ->
                                     {unknown_ip, unknown_port}
                             end,
    {RemoteIP, RemotePort}.

send_data_to_client(State, Packet) ->
    Socket = State#innerstate.socket,
    Transport = State#innerstate.transport,
	%[<<End/binary,"~r~n">>]
    case Transport:send(Socket, [Packet,<<13,10>>]) of
        ok ->
            ok;
        Error ->
            {RemoteIP, RemotePort} = get_ip_and_port(Transport, Socket),
            case Error of
                {error, closed} ->
                    io:format(">>> Client '~w' did disconnected.~n", [self()]),
                    stop();
                _ ->
                    io:format("Unknown error send data to ~w:~w ('~w'). Error = ~w. Data = ~p~n", [RemoteIP, RemotePort, self(), Error, Packet])
            end,
            ok
    end.


