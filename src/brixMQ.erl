%%Очередь сообщений, тут хранятся сообщения в виде:
%%{{MDI,uniq},ID,[{conf,fun}]} - короче вторая часть это проплист реакций на разное действие
%%Как вообще выглядит каноничная команда? Почему я вообще сейчас делаю команды, когда должен делать оповещения? да потому что вся отправка через   
%%Что вообще надо сделать по отправке например или по таймауту, или по подтверждению? 
%%Как работает данное хранилище? Можно добавить сообщение, можно провести какие-то действия (подтвердить регистрацию, отправить пуш например)
%%Короче на самом деле общий алгорит таков: все обработки идут в BNP, на потоках соединений
%%Из хранилищ мы только черпаем данные что нужно сделать
%%А когда данные пропадают отсюда? только при достижении финального статуса
%%Вообще-то это жесть какая-то в виде того, что тут усложнение невертятное. Что реально надо сделать - ввести для команд статус "отменена и время"
%%Все сообщения с нефинальным статусом переотправляются при пересоединении

-module(brixMQ).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([]).


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
	TableID=ets:new(test, [duplicate_bag]), 	%Тут сумка теперь
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
handle_cast({change,{{MDI,Uniq},Sync,NewState}}, State) -> %Запрос на изменение статуса команды
	[{table,TableID}|T]=State, %получили номер таблицы
	Find=ets:lookup(TableID, {MDI,Uniq}), %Допустим мы нашли что-то по такому номеру, но кстати тут должен быть bag
	%Теперь надо найти среди них по синку
	[{{MDI,Uniq},FSync,ReactionList}]=lists:filter(fun({{_MDI,_Uniq},FSync,_ReactionList})->FSync=:=Sync end, Find), %Будем считать, что нашли такой синк
	Reaction=proplists:get_value(NewState,ReactionList),
	%Далее надо определить какие сообщения удовлетворяют условию из Reaction (который применяется к списку Find)
	
	
	case Find of %ищем по ID
			[{_ID, none}] -> Reply={error,none};
			[{_ID, PID}] -> Reply={ok,PID};
			_Any -> Reply={error,Res}
	end,	
handle_cast(Msg, State) ->
	
	[{table,TableID}|	
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


