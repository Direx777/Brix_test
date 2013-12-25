%%Это просто модуль по обработке входящих сообщений
%ConState: {Type,ProtoID}  PID передавать в процесс не надо, но вот MDI можно, т.к. по нему можно найти верзний протокол
%Type: new | auth | normal Из-за двойной авторизации здесь такое происходит
%Соединение хранит данные: protoID (это базовый protoID) | sesID,MDI,uniq | MDI,uniq
%{Msg_type,[{params,[]},{named,[]}]} named раздела может не быть, а там по сути proplist очередной
%При поступлении оповещения от девайса мы получаем его протокол и парсим команду, ответ имеет следующий вид:
%[{standart,[history,push,sms..]},{action,{M,F,A}]
%Какие могут быть ответы: {ok,[{newstate,{...}},{send,{Msg}}]} - В ответе проп лист того, что надо сделать (кстати важен порядок) 

-module(bnp2).

%% ====================================================================
%% API functions
%% ====================================================================
-export([new_notice/2]). %Это стандартный вид для обработчика нового сообщения

new_notice({new,BaseProtoID},{reg,Params})->
	[MDI_name,OwnerPhone,UniqNumber,Ping]=Params, %Получили параметры запроса
	{ok,MDI}=mdimanager:getmdi(MDI_name), %Преобращовали имя в конкретный номер строки в таблице с MDI
	{ok,High_proto}=protocolmanager:gethighprotocol({proto,BaseProtoID}),
	{ok,Low_proto}=protocolmanager:getlowproto(MDI), %По MDI можно получить протокол
	{ok,DeviceLogin,DeviceID}=devicemanager:new_auto(MDI,UniqNumber), %Получили регистрацию для автомобиля
	{ok,PersonID}=personmanager:newperson(OwnerPhone), %Эта функция вернет существующего владельца если он есть с таким номером
	{ok,LinkID}=linkmanager:newlink(DeviceID,PersonID), %грубая прикидка
	%по Msg надо смотреть спеки
	{ok,[{newstate,[{normal,Low_proto}]},{send,{Msg}}]};
new_notice({new,BaseProtoID},{auth1,Params})->
		
	{ok,[{newstate,[{auth,Low_proto},{}]},{send,{Msg}}]};
new_notice({auth,AuthTryParams},{auth2,Params})->
	{ok,[{newstate,{}},{send,{Msg}}]};
new_notice({normal,ProtoID},Msg)->
	{ok,[{newstate,{}},{send,{Msg}}]}.

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
    {reply, Reply, State}.



%% ====================================================================
%% Internal functions
%% ====================================================================


