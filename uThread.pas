unit uThread;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses SyncObjs,SysUtils,uBoard,uSort,uNN,uHash,Classes;
Const
  MaxThreads=256;
  MaxPV=130;
Type
 Thread=class(TThread)
  private
   ThreadID : integer;
  protected
   procedure Execute;override;
  public
   constructor Create(CreateSuspended:boolean;Id:integer);
 end;
  TForwardThread = array[0..128] of TForwardPass;
  TPv = array[0..MaxPV] of smallint;
  TThread  = record
              Id       : integer;   // Идентификатор
              handle   : LongWord;  // хендл потока
              isRun    : boolean;  // Показывает что поток работает
              idle     : boolean;  // Показывает простой потока
              haswork  : boolean;  // Флаг наличия задания у потока
              AbortSearch : Boolean;
              RootDepth : integer;
              FullDepth : integer;
              SelDepth  : integer;
              RootMoves: integer;
              nullply  : integer;
              nullclr  : integer;
              Board    : TBoard;
              Tree     : TTree;
              PVLine   : TPV;
              OldPvMove: integer;
              StablePv : TPV;
              RootList : TMoveList;
              stableMove : integer;
              BestValue  : integer;
              WaitPonder : boolean;
              Fenflag : boolean;
              outname : shortstring;
              outfile : textfile;
              bookposnum : integer;
              TTLocal    :TTable;  // локальный хеш потока (для генерации фен позиций)
              clrflag    :boolean;   // флаг очистки хеша
              hashstart  : Pentry; // стартовая ячейка
              hashcnt    : int64; // количество для очистки
              repcnt     : integer;
            end;

var
   AllThreadsStop : boolean;
   Threads : array [1..MaxThreads] of TThread;
   SMPLock : TCriticalSection;
   IdleEvent : TEvent;
   SortUnitThread : array of TSortUnit;
   PassThread : array of TForwardThread;
 //  ThreadsPass : array of TForwardThread;


Procedure InitThreads(n:integer);
Procedure StopThreads;
Function isThreadidle:boolean;
Procedure CopyThread(ThreadId:integer);
implementation
  uses uUci,uSearch;

Constructor Thread.Create(CreateSuspended: Boolean;Id : integer);
begin
  inherited Create(CreateSuspended);
  ThreadId:=id;
end;



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
   Threads[ThreadId].RootDepth:=0;
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
      IdleEvent.WaitFor(INFINITE);
      //  Тут поток ждет наступление нашего персонального события
     end;
    // Тут поток проснулся и ждет работу или сигнала закрыться. Активируется поток  в работу путем подачи на haswork true
    if Threads[threadid].haswork then
      begin
        Threads[threadid].idle:=false;
        If Threads[ThreadId].Fenflag
          then SingleGenerator(ThreadID,threads[threadid].bookposnum) else   // Задача генерировать фенки
        if Threads[ThreadId].clrflag then multiclear(threadid)  // Задача чистить хещ
          else if threadid=1
            then Think                                      // первый поток
            else Iterate(ThreadId);                         // все остальные вспомогательные
        Threads[threadid].fenflag:=False;
        threads[threadid].clrflag:=False;
        Threads[threadid].haswork:=false;
      end;
   end;
// Закрытие потока
 Threads[threadid].isRun:=false;
end;
Procedure Thread.Execute;
begin
  Idle_loop(ThreadId);
end;

Procedure InitThreads(n:integer);
// Инициализация потоков. Все потоки переходят в спящее состояние и ждут работу
var
  i : integer;
  //tr:longword;
begin
   AllThreadsStop:=false;
 // Инициализация SortUnitThread
 SetLength(SortUnitThread,0);
 SetLength(SortUnitThread,n);
 // PassThread
 SetLength(PassThread,0);
 SetLength(PassThread,n+1);
 // Стартуем потоки
  for i:=1 to n do
      begin
        Threads[i].haswork:=false;
        Threads[i].Fenflag:=false;   // По умолчанию запускаемся в нормальном режиме для перебора
        Threads[i].clrflag:=False;
        Thread.Create(false,i);
        //Threads[i].handle:=BeginThread(nil,0,addr(win_init),addr(i),0,tr);
        // Как только поток поднялся и сам проинициализировался - мы сразу из цикла выйдем
        while not Threads[i].isRun do;
      end;
end;
Function isThreadidle:boolean;
// Проверяем все ли  вспомогательные потоки отработали - если кто-то еще работет - результат true
var
  i:integer;
begin
  result:=false;
  for i:=2 to MaxThreads do
    if (Threads[i].idle=false) then
      begin
        result:=true;
        exit;
      end;
end;
Function isThreadsrunning:boolean;
// Проверяем есть ли хоть один поток работающий (начиная с первого)
var
  i:integer;
begin
 result:=false;
  for i:=1 to MaxThreads do
    if Threads[i].isRun then
      begin
        result:=true;
        exit;
      end;
end;
Procedure StopThreads;
// Тушим потоки
begin
  // Подаем сигнал всем потокам завершить свою работу
  AllThreadsStop:=true;
  // Даем наступление события чтобы вызвать из спячки спящие потоки
  IdleEvent.SetEvent;
  // Ждем окончания работы всех потоков!
  while isThreadsrunning do;
  IdleEvent.ResetEvent;
end;

Initialization
// Инициализируем критическую секцию
SmpLock:=TCriticalSection.Create;
// Инициализируем событие для синхронизации потоков
IdleEvent:=TEvent.Create(nil,true,false,'main'{,false});
end.
