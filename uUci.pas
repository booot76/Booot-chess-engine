unit uUci;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses SyncObjs,SysUtils,DateUtils,uBoard,uBitBoards,uSearch,uSort,uEval,uHash,uAttacks;
Const
     StartPositionFen='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';


Procedure MainLoop;
Procedure poll();
Procedure NewSearch(ThreadId:integer);
Function StrToMove(smove:ansistring;var Board:Tboard):integer;
Procedure WaitPonderhit;
Procedure SetHash(var TT:TTable;size:integer);
Procedure NewGame;
Procedure SetRemain;

implementation
   uses uThread,Unn,Ubenchmark;


Procedure SetHash(var TT:TTable;size:integer);
begin
  InitTT(TT,size);
end;
Procedure SetRemain;
// В зависимости от оставшегося времени определяем частоту его проверки:
begin
  If (game.time=64*3600*1000) then game.remain:=10000 else // Пондеринг всегда в самом быстром режиме проверки
  If (game.time=48*3600*1000) then game.remain:=1000000 else // Режим анализа - всегда в самом медленном режиме проверки
  If (game.time>5000) then game.remain:=1000000 else // Если больше 5 секунд на ход
  If (game.time>1000) then game.remain:=100000  else // Если больше 1 секунд на ход
  If (game.time>500)  then game.remain:=50000   else // Если больше 0,5 секунд на ход
                           game.remain:=10000; // Если меньше 0,5 секунд на ход
end;
Procedure NewGame;
// запускается при получении команды ucinewgame
var
  i : integer;
begin
  // Начальная позиция - в первый поток
  SetBoard(StartPositionFen,Threads[1].Board);
  game.movestocontrolmax:=0;
  // Чистим глобальный хеш и историю для всех потоков
  ClearHash(TTGlobal,game.threads);
  for i:=1 to game.Threads do
   begin
    ClearHistory(SortUnitThread[i-1],Threads[i].Tree);
   end;
end;

Procedure NewSearch(ThreadId:integer);
// запускается каждый раз после получения команды go для каждого потока
begin
  Threads[ThreadId].Board.Nodes:=0;
   Threads[ThreadId].Board.tbhits:=0;
  Threads[ThreadId].AbortSearch:=false;
  If ThreadId=1 then
    begin
     // Для основного потока увеличиваем счетчик возраста глобального хеша
     TTGlobal.Age:=TTGlobal.Age+AgeInc;
     SetRemain;
     Threads[1].Board.remain:=game.remain;
    end;
end;
Function FindSq(s:ansistring):integer;
var
  i:integer;
begin
  result:=NonSq;
  For i:=a1 to h8 do
   if DecodeSQ[i]=s then
     begin
       result:=i;
       exit;
     end;
end;
Function StrToMove(smove:ansistring;var Board:Tboard):integer;
var
   from,dest : integer;
   res:integer;
begin
 from:=FindSq(smove[1]+smove[2]);
 dest:=FindSq(smove[3]+smove[4]);
 res:=(dest shl 6) or from;
 if Board.Pos[dest]<>0 then res:=res or CaptureFlag;
 if ((Board.Pos[from]=Pawn) or (Board.Pos[from]=-Pawn)) and (Board.EnPassSq=dest) then res:=res or CaptureFlag;
 if length(smove)=5 then
   case smove[5] of
     'q' : res:=res or (Queen shl 12);
     'r' : res:=res or (Rook shl 12);
     'b' : res:=res or (Bishop shl 12);
     'n' : res:=res or (Knight shl 12);
   end;
 result:=res;
end;
Procedure ForceMoves(var Board:Tboard; var Tree:TTree;mlist:ansistring);
var
  v               : integer;
  smove           : ansistring;
  move            :integer;
  CheckInfo       :TCheckInfo;
  isCheck         : boolean;
  Undo            : TUndo;
begin
  mlist := trim(mlist) + ' ';
  repeat
    v := pos(' ',mlist);
    smove:= trim(copy(mlist,1,v));
    if length(smove)>=4 then
      begin
        move:=StrTomove(smove,Board);
        SetUndo(Board,Undo);
        FillCheckInfo(CheckInfo,Board);
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        MakeMove(move,Board,Undo,isCheck);
        // история "до корня" записывается только в части цепочки ходов до взятия или движения пешки
        rep.cnt:=Board.Rule50;
        rep.keys[rep.cnt]:=Board.Key;
      end;
    delete(mlist,1,v);
  until length(mlist) < 4;
end;

function FindStringParam(from:ansistring;what:ansistring): string;
var n: integer;
begin
  result := '';
  n := pos(what,from);
  if n < 1 then exit;
  delete(from,1,n+length(what)-1);
  from := trim(from) + ' ';
  result := copy(from,1,pos(' ',from)-1);
end;

function GetParam(from:ansistring;what:ansistring): integer;
var
  temp:string;
begin
  temp:=FindStringParam(from,what);
  if temp=''
    then result:=0
    else result := StrToIntDef(temp,0);
end;

Function TakeHashSize(val : integer):integer;
// Выбирает ближайшее значение хеша, являющееся степенью 2
const
  HashSizes : array[1..15] of integer = (16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144);
var
  i : integer;
begin
  i:=1;
  while (i<=15) and (HashSizes[i]<val) do
    inc(i);
  Result:=HashSizes[i];
end;
Procedure Parser(s:ansistring);
// Процедура коммуникации с оболочкой - получает и отправляет команды
var
   n,wtime,btime,winc,binc,movestocontrol,val,clock,incr,movetime,i : integer;
   fen,mlist:ansistring;
   //pondermove:integer;
   sval:string;
begin
  if s='' then exit;
  if (pos('eval',s)>0) then
    begin
      FillWhiteAcc16(Globalmodel, Threads[1].Board,PassThread[0][1]);
      FillBlackAcc16(Globalmodel,Threads[1].Board,PassThread[0][1]);
      Writeln(' Static Score = '+InttoStr(Evaluate(Threads[1].Board,1,1)));                         // Статическая оценка позиции
      Writeln('FV Score = ',FV(TTGlobal,1,-mate,mate,0,1,Threads[1].Board,SortUnitThread[0],Threads[1].Tree,Threads[1].PVLine));
      Writeln(' Best FV moves : ',MakePVString(Threads[1].PVLine));
      Flush(Output);
      exit;
    end;
  if pos('perft ',s)=1 then                                                     // тест perft
    begin
      n:=pos(' ',s);
      sval:=trim(copy(s,n,length(s)));
      val:=StrToInt(sval);
      Perft(true,now,Threads[1].Board,val);
      exit;
    end;
  if pos('ucinewgame',s) >0 then
    begin                                                                       // ucinewgame
      NewGame;
      exit;
    end;
  if pos('uci',s) = 1  then                                                               //uci
    begin
     Writeln(Output,'id name ' + GetFullVersionName);
     Writeln(Output,'id author Alex Morozov (booot76@gmail.com)');
     // Тут вываливаем список параметров движка
     Writeln(Output,'option name Hash type spin default 128 min 16 max 242144');
     Writeln(Output,'option name Ponder type check default false');
     Writeln(Output,'option name Threads type spin default 1 min 1 max '+inttostr(MaxThreads));
     Writeln(Output,'uciok');
     Flush(Output);
     exit;
    end;
  if (pos('isready',s)>0) then                                                         //isready
    begin
     Writeln(Output,'readyok');
     Flush(Output);
     exit;
    end;
  if pos('bench',s) = 1 then bench;                                          // Benchmark

  if pos('setoption ',s) = 1 then                                               // setoption
    begin
     n := pos('value ',s);
     if n > 1 then
       begin
        sval := trim(copy(s,n+6,length(s)));
        if (pos('name Hash',s) > 0) or (pos('name hash',s) > 0)   then
         begin
          // Устанавливаем новый размер глобального хеша движка
          val := StrToIntDef(sval,128);
          if val<16 then val:=16;
          val:=TakeHashSize(val);
          game.hashsize:=val;
          SetHash(TTGlobal,val);
         end else
        if (pos('name ponder',s) > 0) or (pos('name Ponder',s) > 0) then
         begin
           if pos('true',sval) > 0 then game.uciPonder:=true else
           if pos('false',sval) > 0  then game.uciPonder:=false;
         end else
        if (pos('name threads',s) > 0) or (pos('name Threads',s) > 0) then
         begin
           val := StrToIntDef(sval,1);
           if val>MaxThreads then val:=MaxThreads;
            // Останавливаем потоки которые могли быть запущены ранее
           StopThreads;
           game.Threads:=val;
           // Запускаем инициализацию нужного количества потоков
           InitThreads(game.Threads);
         end;
       end;
     exit;
    end;

  if pos('position',s) = 1 then
    begin                                                                        //Position
     fen:=StartPositionFen;
     n := pos('moves ',s);
     if n > 0 then
       begin
        mlist := copy(s,n+5,length(s));
        fen := copy(s,1,length(s)-length(mlist)-5);
       end   else
       begin
        mlist := '';
        fen := s;
       end;
      n := pos('fen ',fen);
      if n > 0 then fen := copy(fen,n+4,length(fen)) else fen := '';
      if (fen='') or (fen='startpos') then fen:=StartPositionFEN;
      SetBoard(fen,Threads[1].Board);
      ForceMoves(Threads[1].Board,Threads[1].tree,mlist);
     // PrintBoard(Boards[1]);
      Threads[1].tree[1].key:=Threads[1].Board.Key;
      exit;
     end;
  if pos('go ',s) = 1 then
   begin                                                                         //go
     if pos('infinite',s) > 0 then
       begin                                                                     // infinite
        game.time:=48*3600*1000;
        game.rezerv:=48*3600*1000;
        game.oldtime:=game.time;
       end else
       begin
        wtime:=GetParam(s,'wtime');
        btime:=GetParam(s,'btime');
        winc:=GetParam(s,'winc');
        binc:=GetParam(s,'binc');
        movetime:=GetParam(s,'movetime');
        movestocontrol:=GetParam(s,'movestogo');
        if Threads[1].Board.SideToMove=white then
          begin
            clock:=wtime;
            incr:=winc;
          end else
          begin
            clock:=btime;
            incr:=binc;
          end;
        // Здесь считаем контроль времени
        if movestocontrol>0 then
          begin
            if movestocontrol>game.movestocontrolmax then game.movestocontrolmax:=movestocontrol;
            //Контроль времени
            if movestocontrol>1
             then game.time:=clock div movestocontrol
             else game.time:=clock div 2;
            if movestocontrol>(game.movestocontrolmax div 2) then game.time:=game.time+(game.time div 2);
            If (clock>1000) and (movestocontrol>1)
              then  game.rezerv:=clock div 4
              else  game.rezerv:=game.time;
          end else
          begin
            if incr>0 then
              begin
                // С добавлением
                game.time:=(clock div 15) + (incr div 2);
                if clock>1000
                  then game.rezerv:=(clock div 4)
                  else game.rezerv:=game.time;
              end else
              begin
                // без добавления
                game.time:=clock div 30;
                If clock>2000
                  then  game.rezerv:=game.time*2
                  else  game.rezerv:=game.time;
                if movetime<>0 then
                  begin
                    game.time:=movetime;
                    game.rezerv:=movetime;
                  end;
              end;
          end;
         If game.rezerv<game.time then game.rezerv:=game.time;
         if pos('ponder',s) > 0 then
           begin
             game.pondertime:=game.time;
             game.ponderrezerv:=game.rezerv;
             game.time:=64*3600*1000;
             game.rezerv:=64*3600*1000;
           end;
         game.oldtime:=game.time;
       end;
     // Запускаем первый поток
     Threads[1].haswork:=true;
     IdleEvent.SetEvent; // чтобы запустить Think
  end;
 if (pos('stop',s)>0)  then
    begin
     for i:=1 to game.Threads do
       Threads[i].AbortSearch:=true;
     SetRemain;
     Threads[1].Board.remain:=0;
     game.time:=0;
     game.rezerv:=0;
     Threads[1].WaitPonder:=false;
    end;
  if pos('ponderhit',s)>0  then
    begin
      game.time:=game.pondertime;
      game.rezerv:=game.ponderrezerv;
      game.oldtime:=game.time;
      SetRemain;
      Threads[1].Board.remain:=0;
      Threads[1].WaitPonder:=false;
    end;

end;

Procedure MainLoop;
var
  s:ansistring;
begin
  while True do
   begin
    readln(s);
    // Получили команду на выход
    if (pos('quit',s)>0) then
      begin
        stopthreads;
        exit;
      end;
    // Разбираем полученную команду
    Parser(s);
   end;
end;

Procedure poll();
var
   timetot:int64;
begin
  Timetot:=MilliSecondsBetween(game.StartTime,now);
  if (timetot>=game.time) and (not Threads[1].fenflag) then Threads[1].AbortSearch:=true;
end;

Procedure WaitPonderhit;
begin
  Threads[1].WaitPonder:=true;
  while Threads[1].WaitPonder  do;
end;

end.
