%% @author Dmitry
%% @doc @todo Add description to smssender.
%% Пару слов об этом модуле. Он зарегестрирован под именем, супервизор если что поднимет, но вообще-то вылетов быть не должно
%%Служит для отправки СМС через http (используя всякие разные сервисы, которые кстати говоря отдельно реализованы, но пока вместе)
%%
%%В сооотв. с принципом divide and empire (DEA) план действий таков:
%%Есть прием таска, с выдачей номера, далее есть изменение статуса, проверка на финальность и удаление с сохранением 
-module(smssender).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% ====================================================================
%% API functions
%% ====================================================================
%Какие же функции API Должны быть? Часто меня спрашивают люди
%Отправка нового СМС, изменение статуса старого
%
%Статусы СМС: 0 - принята нами, 1 - принята серваком агрегатора, 2 - доставлено, 3х - ошибки   
%
-export([sendsms/3,changesmsstate/2]).
-export([getsmsstate/1]).
-export([start_link/0]).

sendsms(Phone,Text,Meta)->gen_server:call(?MODULE, {newsms,{Phone,Text,Meta}}). % Отправляет СМС на номер, возврат идентификатор СМС

changesmsstate(UID,NewState)->gen_server:call(?MODULE, {change,{UID,NewState}}). %Меняет статус СМС (такое нужно для коллбеков)

getsmsstate(UID)->gen_server:call(?MODULE, {getsmsstate,UID}).

start_link() ->
		gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Internal functions
%% ====================================================================
-define(SEND_URL,"http://127.0.0.1:7068/auth1?param=").
-define(END_STATE,2).
%-record(state, {req_TID,uid_TID, lastID=0}).
-record(sms,{time,phone,text,meta,msgstate}). %uid вынесен преднамеренно, т.к. является ключом кортежа
%Какая мета-информация может быть: [{personID,ID()},{...}] - в общем просто проп-лист
%А какие времена: [time_apply,time_server,time_end] - иногда, в случае ошибок, time_end - совпадает с time_server
%%=====================================================================
%Инициализация:
%Создаем мнезию, туда будем пихать смс, также создаем последний номер смс. Вообще инит надо бы нам с параметрами, 
%например к каой таблице подрубаться, но попозже думаю
init([]) ->
	Req_TID=ets:new(sms_req_table,[]),%Таблица запросов
	UID_TID=ets:new(sms_uid_table,[]),%Иаблица уникальных идентификторов
	LastUID=0,
	%А номер у нас и так создан
    {ok, {Req_TID,UID_TID,LastUID}}.

%% handle_call/3
%% ====================================================================
handle_call({newsms,{Phone,Text,Meta}},_From, State)-> %Новое СМС
	{Req_TID,UID_TID,LastUID}=State,
	CurrentUID=LastUID+1, %Вычислили текущий ID
	ets:insert(UID_TID, {CurrentUID,#sms{time=[erlang:localtime()],phone=Phone,text=Text,meta=Meta,msgstate=0}}), %Вставили по UID
	%Теперь самое сложное, отправить это куда-то
	{ok, RequestID}=httpc:request(get, {string:concat(?SEND_URL, integer_to_list(CurrentUID)), []}, [], [{sync, false}]),
	ets:insert(Req_TID, {RequestID,CurrentUID}), %Вставили по идентификатору запроса
	Reply={ok,CurrentUID}, %ответим просто идентификатор текущий
	NewState={Req_TID,UID_TID,CurrentUID}, %Новый статус
	{reply,Reply,NewState};
		

handle_call({change,{UID,NewMsgState}},_From, State) -> %Изменить статус СМС
	{_Req_TID,UID_TID,_LastUID}=State,
	case get_sms(UID_TID,UID) of
				{ok,{UID,SMS}}-> %Нашли
							Reply=change_sms_state(UID_TID,UID,SMS,NewMsgState);
				{error,Reason}-> %Не нашли по какой-то причине
							Reply={error,Reason}
	end,
	{reply,Reply,State};	

handle_call({getsmsstate,UID}, _From, State) -> %Получить статус СМС
	{_Req_TID,UID_TID,_LastUID}=State,
	case get_sms(UID_TID,UID) of
				{ok,{UID,SMS}}-> %Нашли
							Reply={ok,{UID,SMS#sms.msgstate}};
				{error,Reason}-> %Не нашли по какой-то причине
							Reply={error,Reason}
	end,
	
    {reply, Reply, State};
	
handle_call(_Any, _From, State) -> %Все остальное (ошибка по сути)
	Reply ={ok,{}},
    {reply, Reply, State}.

%% handle_cast/2
%% ====================================================================
handle_cast(_Msg, State) ->
    {noreply, State}.

%% handle_info/2
%% ====================================================================
%Здесь у нас будет получение пакета: {http, {ReqestId, Result}}
handle_info({http, {RequestID, Result}}, State) ->
	{Req_TID,UID_TID,LastUID}=State, %Получили все переменные 
	%Распарсим ответ
	NewMsgState=parse_sms_result(Result),
	%Теперь нам надо определить UID СМСки по RequestID
	case get_sms_by_req(Req_TID,UID_TID,RequestID) of
				{ok,{UID,SMS}} -> %Нашли хорошую СМС-ку
							change_sms_state(UID_TID,UID,SMS,NewMsgState); %поменяли статус СМС (её удалили если надо)			
				{error,Reason} -> true		%Здесь error какой-то, я хз, пока ничего не надо делать										
	end,								
	ets:delete(Req_TID,RequestID), %Удалим запрос в любом случае, он уже отработал								
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% terminate/2
%% ====================================================================
terminate(Reason, State) ->
    ok.

%% code_change/3
%% ====================================================================
code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================


%Parse SMS result проверяет что мы там получили, какие варианты: 
%{status_line(), headers(), Body}
%{error,reason}
parse_sms_result(Result)->
	case Result of
		{_Status,_Headers,Body} -> %Ответ какой-никакой
							case Body of
									<<"1">> -> 1;
									_Any -> 30
							end;
		{error,_ErrorReason} -> 30
	end.

%Внесение изменений в статус
%Ответы: {{ok,changed},del|normal} | {{error,missed},normal}
change_sms_state(UID_TID,UID,SMS,NewMsgState)->
	%Теперь здесь безусловная смена
	case NewMsgState<?END_STATE of
			true-> %Пока удалять не надо
				NewSMS=SMS#sms{msgstate=NewMsgState},
				ets:insert(UID_TID, {UID,NewSMS}),
				{ok,changed};
			false-> %Уже удаляем из таблицы и сохраняем в БД
				NewSMS=SMS#sms{msgstate=NewMsgState}, %Изменили статус
				save_to_base(UID,NewSMS),	%сохранили в БД
				ets:delete(UID_TID,UID), 	%Удалили из таблицы
				{ok,deleted}			%Изменение удалось
	end.
		
%Get SMS
get_sms(UID_TID,UID)->
	case ets:lookup(UID_TID, UID) of
			[{UID,SMS}]-> %Нашли
						{ok,{UID,SMS}};							
			[] -> %Не нашли
					{error,missed_uid}
	end.

%Найти СМС по номеру запроса, либо миссед (30). При этом есть две ошибки здесь missed_uid, и missed_req
get_sms_by_req(Req_TID,UID_TID,RequestID)->
	case ets:lookup(Req_TID, RequestID) of
		[{RequestID,CurrentUID}] ->	%Нашли соответствие запроса к номеру СМС
									case get_sms(UID_TID,CurrentUID) of
											{ok,{CurrentUID,SMS}} -> {ok,{CurrentUID,SMS}}; %Нашли и вернули СМС
											{error,Reason} -> {error,Reason}				%Не нашли СМС  			
									end;
		[] -> {error,missed_req} %Не нашли запрос даже
	end.
	

%Сохранение в БД СМСки:
save_to_base(UID,SMS) -> true.

%Какие должны быть функции: внести изменения, сохранить в базу, удалить из базы. Но база у нас составная
%Можно расширить: найти, изменить, сохранить в БД, удалить из локала
	
	
	

