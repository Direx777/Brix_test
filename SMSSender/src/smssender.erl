%% @author Dmitry
%% @doc @todo Add description to smssender.
%% Пару слов об этом модуле. Он зарегестрирован под именем, супервизор если что поднимет, но вообще-то вылетов быть не должно
%%Служит для отправки СМС через http (используя всякие разные сервисы, которые кстати говоря отдельно реализованы, но пока вместе)
-module(smssender).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% ====================================================================
%% API functions
%% ====================================================================
%Какие же функции API Должны быть? Часто меня спрашивают люди
%Отправка нового СМС, изменение статуса старого
-export([sendsms/2,changesmsstate/2]).

sendsms(Phone,Text)->gen_server:call(?MODULE, {newsms,{Phone,Text}}). % Отправляет СМС на номер, возврат идентификатор СМС

changesmsstate(ID,NewState)->gen_server:call(?MODULE, {change,{ID,NewState}}). %Меняет статус СМС (такое нужно для коллбеков)



%% ====================================================================
%% Internal functions
%% ====================================================================
-record(state, {tableID, lastID=0}).
%Инициалищация:
%Создаем мнезию, туда будем пихать смс, также создаем последний номер смс. Вообще инит надо бы нам с параметрами, 
%например к каой таблице подрубаться, но попозже думаю
init([]) ->
	TableID=ets:new(smstable), 
	%А номер у нас и так создан
    {ok, #state{tableID=TableID}}.

handle_call({newsms,{Phone,Text}},_From, State)-> %Новое СМС
	TableID=State#state.tableID,
	ets:insert(TableID, {key,val}),

	Reply

handle_call({new_message,{new,BaseProtoID},{reg,Params}}, _From, State) -> %регистрация
	%При регистрации нам надо зарегать человека, зарегать тачку
	%Нам передается там протокол, номер телефона человека, IMEI, Ping, 
	%ну пинг понятно куда ставить, тачку регаем в синхронном режиме, а вот человека регаем в асинхронном и передаем ему SMS отдельно
    %что ответить:
	Reply ={ok,{trash}},
    {reply, Reply, State};
handle_call({new_message,{new,BaseProtoID},{auth1,Params}}, _From, State) -> %авторизация
	Reply ={ok,{}},
    {reply, Reply, State};
handle_call({new_message,{auth,AuthTryParams},{auth2,Params}}, _From, State) -> %авторизация 2
	Reply ={ok,{}},
    {reply, Reply, State};
handle_call({new_message,{normal,BaseProtoID},Msg}, _From, State) -> %Нормальный режим работы
	Reply ={ok,{}},
    {reply, Reply, State};
handle_call(_Any, _From, State) -> %Все остальное (ошибка по сути)
	Reply ={ok,{}},
    {reply, Reply, State}.

