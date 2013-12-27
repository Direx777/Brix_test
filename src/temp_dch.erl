%%Temporary device connection holder
%%Временное хранилище коннектов
%%Здесь есть записи двух видов: {{MDI,uniq},auth,PID} - это девайс, который авторизовывается
%%{{MDI,uniq},reg} - девайс, который регается (его данные лежат в  таблице уже, с пометкой temp)
%%А зачем нам вообще этот список? или мы отсюда щлем команду подтверждения?

-module(temp_dch).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([]).
%Подтверждение участия дает в ответе данные для того, чтобы зарегать тачку
accept(MDI,Uniq)->gen_server:call(?MODULE,{accept,{MDI,Uniq}}).
%Отклонение регистрации/авторизации
decline(MDI,Uniq)->gen_server:call(?MODULE,{decline,{MDI,Uniq}}).



%% ====================================================================
%% Behavioural functions 
%% ====================================================================
-record(state, {}).

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
%% ====================================================================
init([]) ->
    process_flag(trap_exit, true),
	TableID=ets:new(test, []), 	%without opts [set,protected,{keypos,1}]
    {ok, [{table,TableID}]}.	%return TableID, здесь как будто бы proplist


%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
%% ====================================================================
handle_call(Request, From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
%% ====================================================================
handle_cast(Msg, State) ->
    {noreply, State}.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
%% ====================================================================
handle_info(Info, State) ->
    {noreply, State}.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
%% ====================================================================
terminate(Reason, State) ->
    ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
%% ====================================================================
code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================


