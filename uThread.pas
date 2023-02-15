unit uThread;

interface
uses Windows,SysUtils,uBoard,uSort,uMaterial,uPawn,uEval;
Const
  MaxThreads=16;
  MaxPV=130;
Type
  TPv = array[0..MaxPV] of smallint;
  TThread  = record
              Id       : integer;   // Идентификатор
              handle   : LongWord;  // хендл потока
              isRun    : boolean;  // Показывает что поток работает
              idle     : boolean;  // Показывает простой потока
              haswork  : boolean;  // Флаг наличия задания у потока
              AbortSearch : Boolean;
              FullDepth : integer;
              RootMoves: integer;
              Board    : TBoard;
              Tree     : TTree;
              SortUnit : TSortUnit;
              PVLine   : TPV;
              StablePv : TPV;
              RootList : TMoveList;
              stableMove : integer;
              BestValue  : integer;
              MatTable : array of TMatEntry;
              MatTableMask : int64;
              PawnTable : array of TPawnEntry;
              PawnTableMask : int64;
              EvalTable : array of TEvalEntry;
              EvalTableMask: int64;
            end;

var
   AllThreadsStop : boolean;
   Threads : array [1..MaxThreads] of TThread;
   SMPLock :TRTLCriticalSection;
   IdleEvent : THandle;
Threadvar
    global : ^Integer;

Procedure Init_Threads(n:integer);
Procedure StopThreads;
Function isThreadidle:boolean;
Procedure CopyThread(ThreadId:integer);
implementation
  uses uUci,uSearch,UHash;

Procedure CopyThread(ThreadId:integer);
var
  i: integer;
// Копирует данные из главного потока в вспомогательные
begin
  Threads[ThreadId].RootMoves:=Threads[1].RootMoves;
    Threads[ThreadId].PVLine[0]:=0;
  for i:=0 to Threads[ThreadId].RootMoves-1 do
    begin
     Threads[ThreadId].RootList[i].move:=Threads[1].RootList[i].move;
     Threads[ThreadId].RootList[i].value:=Threads[1].RootList[i].value;
    end;
  CopyBoard(Threads[1].Board,Threads[ThreadId].Board);
  NewSearch(ThreadId);
  Threads[ThreadId].FullDepth:=0;
  Threads[ThreadId].haswork:=true;
end;


Procedure Idle_loop (threadid : integer);
// Здесь потоки крутятся
begin
  Threads[threadid].Id:=Threadid;
  Threads[threadid].haswork:=false;
  Threads[threadid].isRun:=true;  // Поток поднялся - даем сигнал стартеру что все ок.
 // В этом цикле живет поток. Выход из цикла - по флагу. Тогда поток закрывается.
  while true do
   begin
    // закрытие потока
    if (AllThreadsStop)  then break;
    // Если для потока сейчас нет работы (например сразу после старта) - он спит.
    // Чтобы его разбудить надо дать ему наше событие !
    if (not Threads[threadid].haswork)  then
     begin
      Threads[threadid].idle:=true;
      WaitForSingleObject(IdleEvent, INFINITE);
      //  Тут поток ждет наступление нашего персонального события
     end;
    // Тут поток проснулся и ждет работу или сигнала закрыться. Активируется поток  в работу путем подачи на haswork true
    if Threads[threadid].haswork then
      begin
        Threads[threadid].idle:=false;
        Iterate(ThreadId);                       ////////////////////////////// функция запуска потока  в перебор
        Threads[threadid].haswork:=false;
        Threads[threadid].idle:=true;
      end;
   end;
// Закрытие потока
 Threads[threadid].isRun:=false;
end;
Procedure win_init(Par:Pointer);
// Базовая процедура старта потоков. Получаем в качестве параметра номер потока и запускаем
// его крутиться в цикле.
var
  i:integer;
begin
  global:=par;
  i:=global^;
  Idle_loop(i);
end;
Procedure Init_Threads(n:integer);
// Инициализация потоков. Все потоки переходят в спящее состояние и ждут работу
var
  i : integer;
  tr:longword;
begin
   AllThreadsStop:=false;
 // Стартуем потоки
  for i:=2 to n do
      begin
        Threads[i].haswork:=false;
        Threads[i].handle:=BeginThread(nil,0,addr(win_init),addr(i),0,tr);
        // Как только поток поднялся и сам проинициализировался - мы сразу из цикла выйдем
        while not Threads[i].isRun do;
      end;
end;
Function isThreadidle:boolean;
// Проверяем все ли потоки отработали - если кто-то еще работет - результат true
var
  i:integer;
begin
  for i:=2 to MaxThreads do
    if (Threads[i].idle=true) then
      begin
        result:=true;
        exit;
      end;
  result:=false;
end;
Function isThreadsrunning:boolean;
// Проверяем есть ли хоть один поток работающий
var
  i:integer;
begin
  for i:=2 to MaxThreads do
    if Threads[i].isRun then
      begin
        result:=true;
        exit;
      end;
  result:=false;
end;
Procedure StopThreads;
// Тушим потоки
begin
  // Подаем сигнал всем потокам завершить свою работу
  AllThreadsStop:=true;
  // Даем наступление события чтобы вызвать из спячки спящие потоки
  SetEvent(IdleEvent);
  // Ждем окончания работы всех потоков!
  while isThreadsrunning do;
  ResetEvent(IdleEvent);
end;

Initialization
// Инициализируем критическую секцию
InitializeCriticalSection(SmpLock);
// Инициализируем событие для синхронизации потоков
IdleEvent:=CreateEvent(nil,true,false,nil);

end.
