unit uUci;

interface
uses Windows,SysUtils,uBoard,uBitBoards,uSearch,uSort,uEval,uPawn,uMaterial,uHash,uAttacks,uMagic,uEndgame;
Const
     MaxBufer=16384;
     StartPositionFen='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

VAR
   stin,stout : cardinal;
   isConsole:boolean;

Procedure MainLoop;
procedure LWrite(s:ansistring);
Procedure poll(var Board:Tboard);
Procedure NewSearch(ThreadId:integer);
Function StrToMove(smove:ansistring;var Board:Tboard):integer;
Procedure WaitPonderhit;

implementation
   uses uThread;

Procedure SetupChanels;
var mode: cardinal;
begin
  stin := GetStdHandle(STD_INPUT_HANDLE);
  stout := GetStdHandle(STD_OUTPUT_HANDLE);
  IsConsole := GetConsoleMode(stin,mode);
  if IsConsole then
    begin
     mode := mode and not (ENABLE_WINDOW_INPUT or ENABLE_MOUSE_INPUT);
     SetConsoleMode(stin,mode);
     FlushConsoleInputBuffer(stin);
    end;
end;

procedure WriteData(pbuff:pointer; n:integer);
var nw: cardinal;
begin
  WriteFile(stout,pbuff^,n,nw,nil);
end;

procedure LWrite(s:ansistring);
begin
  s := s + #10;
  WriteData(pansichar(s),length(s));
end;

function CheckInput: integer;
var
 n,bytesread,bytesleft: cardinal;
 i: integer;
 Inp: array[0..MaxBufer-1] of ansichar;
begin
  result := 0;
  if IsConsole then
    begin
     GetNumberOfConsoleInputEvents(stin,n);
     if n > 1 then result := 256;
     exit;
    end;
  PeekNamedPipe(stin,@Inp,MaxBufer,@bytesread,@n,@bytesleft);
  if bytesread = 0 then exit;
  for i := 0 to bytesread-1 do
  if (Inp[i] = #10) or (Inp[i] = #13) then
    begin
     result:= i+1;
     break;
    end;
  if bytesread >= MaxBufer then result := MaxBufer;
end;

function ReadInput(total:integer):ansistring;
var
 n: cardinal;
 Inp: array[0..MaxBufer-1] of ansichar;
begin
  Readfile(stin,Inp,total,n,nil);
  Inp[n] := #0;
  result := Inp;
  result := trim(result);
end;
Procedure SetHash(size:integer);
begin
  InitTT(size);
  InitPawnTable(size);
  InitMatTable(size);
end;
Procedure SetRemain;
// В зависимости от оставшегося времени определяем частоту его проверки:
begin
  If (game.time=64*3600*1000) then game.remain:=10000 else // Пондеринг всегда в самом быстром режиме проверки
  If (game.time=48*3600*1000) then game.remain:=1000000 else // Режим анализа - всегда в самом медленном режиме проверки
  If (game.time>5000) then game.remain:=1000000 else // Если больше 5 секунд на ход  - проверка через каждый миллион позиций
  If (game.time>1000) then game.remain:=200000  else // Если больше 1 секунд на ход  - проверка через каждые 200к позиций
  If (game.time>300)  then game.remain:=20000   else // Если больше 0,3 секунд на ход  - проверка через каждые 20к позиций
                           game.remain:=10000; // Если меньше 0,3 секунд на ход  - проверка через каждые 10к позиций
end;
Procedure NewGame;
var
  i : integer;
begin
  If game.Threads>1 then
    begin
      StopThreads;
      Init_Threads(game.Threads);
    end;
  SetBoard(StartPositionFen,Threads[1].Board);
  SetHash(game.hashsize);
  game.time:=0;
  SetRemain;
  game.HashAge:=0;
  for i:=1 to game.Threads do
   ClearHistory(Threads[i].Sortunit,Threads[i].Tree);
end;

Procedure NewSearch(ThreadId:integer);
begin
  Threads[ThreadId].Board.Nodes:=0;
  Threads[ThreadId].AbortSearch:=false;
  If ThreadId=1 then
    begin
     game.HashAge:=game.HashAge+4;
     if game.HashAge>=256 then game.HashAge:=0;
     game.TimeStart:=GetTickCount;
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
  PrevKey,LastKey : int64;
begin
  mlist := trim(mlist) + ' ';
  PrevKey:=0;LastKey:=0;
  repeat
    v := pos(' ',mlist);
    smove:= trim(copy(mlist,1,v));
    if length(smove)>=4 then
      begin
        move:=StrTomove(smove,Board);
        SetUndo(Board,Undo);
        FillCheckInfo(CheckInfo,Board);
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        LastKey:=PrevKey;
        PrevKey:=Board.Key;
        MakeMove(move,Board,Undo,isCheck);
      end;
    delete(mlist,1,v);
  until length(mlist) < 4;
  Tree[-1].key:=LastKey;
  Tree[0].key:=PrevKey;
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
  HashSizes : array[1..13] of integer = (16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536);
var
  i : integer;
begin
  i:=1;
  while (i<=13) and (HashSizes[i]<val) do
    inc(i);
 {$IFDEF WIN64}
    i:=i;
 {$ELSE}
    If i>7 then i:=7;   // Для 32 битной версии максимум хеша - 1ГБ
 {$ENDIF}
  Result:=HashSizes[i];
end;
Procedure Parser(s:ansistring);
// Процедура коммуникации с оболочкой - получает и отправляет команды
var
   n,wtime,btime,winc,binc,movestocontrol,val,clock,incr,movetime : integer;
   fen,mlist:ansistring;
   //pondermove:integer;
   sval:string;
begin
  if s='' then exit;
  if (pos('eval',s)>0) then
    begin
      Lwrite('Score = '+InttoStr(Evaluate(Threads[1].Board,1,-Inf,Inf)));                         // Статическая оценка позиции
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
  if pos('uci',s) = 1  then                                                               //uci
    begin
     LWrite('id name ' + GetFullVersionName);
     LWrite('id author Alex Morozov (booot76@gmail.com)');
     // Тут вываливаем список параметров движка
     LWrite('option name Hash type spin default 128 min 16 max 65536');
     LWrite('option name Ponder type check default false');
     LWrite('option name Threads type spin default 1 min 1 max '+inttostr(MaxThreads));
     LWrite('uciok');
     exit;
    end;
  if (pos('isready',s)>0) then                                                         //isready
    begin
     LWrite('readyok');
     exit;
    end;
  if pos('setoption ',s) = 1 then                                               // setoption
    begin
     n := pos('value ',s);
     if n > 1 then
       begin
        sval := trim(copy(s,n+6,length(s)));
        if (pos('name Hash',s) > 0) or (pos('name hash',s) > 0)   then
         begin
          val := StrToIntDef(sval,128);
          if val<16 then val:=16;
          val:=TakeHashSize(val);
          game.hashsize:=val;
          SetHash(val);
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
           ClearThreadMemory;
           NewGame;
         end;
       end;
     exit;
    end;
  if pos('ucinewgame',s) >0 then
    begin                                                                       // ucinewgame
      NewGame;
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
      Threads[1].tree[0].key:=0;
      Threads[1].tree[-1].key:=0;
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
        game.chng:=48*3600*1000;
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
            //Контроль времени
            game.time:=clock div (movestocontrol+1);
            If (clock>10000) and (movestoControl>2)
              then  game.rezerv:=clock div 2
              else  game.rezerv:=game.time;
          end else
          begin
            // sudden death
            if incr>0 then
              begin
                // С добавлением
                game.time:=(clock div 20)+(incr div 2);
                If clock>10000
                  then  game.rezerv:=clock div 2
                  else  game.rezerv:=game.time;
              end else
              begin
                // без добавления
                game.time:=clock div 30;
                If clock>20000
                  then  game.rezerv:=game.time*2
                  else  game.rezerv:=game.time;
                if movetime<>0 then
                  begin
                    game.time:=movetime;
                    game.rezerv:=movetime;
                  end;
              end;
          end;
         game.chng:=(game.time+game.rezerv) div 2;
         if pos('ponder',s) > 0 then
           begin
             game.pondertime:=game.time;
             game.ponderrezerv:=game.rezerv;
             game.ponderchng:=game.chng;
             game.time:=64*3600*1000;
             game.rezerv:=64*3600*1000;
             game.chng:=64*3600*1000;
           end;
         game.oldtime:=game.time;
       end;
     Think;
  end;
end;

Procedure MainLoop;
var
  n,i:integer;
  s:ansistring;
begin
  SetupChanels;
  game.uciPonder:=false;
  game.hashsize:=128;

  for i:=1 to MaxThreads do
    begin
      Threads[i].isRun:=false;
      Threads[i].idle:=true;
    end;
  game.Threads:=1;
  NewGame;
  repeat
    n := CheckInput;
    if n = 0 then
      begin
        sleep(10);
        continue;
      end;
    s := ReadInput(n);
   // Получили команду на выход
    if (pos('quit',s)>0) then
      begin
        stopthreads;
        exit;
      end;
   // Разбираем полученную команду
   Parser(s);
  until false;
end;

Procedure poll(var Board:Tboard);
var
   n,i:integer;
   s:ansistring;
   timetot:cardinal;
begin
  Timetot:=gettickcount - game.TimeStart;
  if timetot>=game.time then Threads[1].AbortSearch:=true;
  n := CheckInput;
  if n = 0 then exit;
  s := ReadInput(n);
  if (pos('stop',s)>0)  or (pos('quit',s)>0) then
    begin
     for i:=1 to game.Threads do
       Threads[i].AbortSearch:=true;
     game.time:=game.pondertime;
     game.rezerv:=game.ponderrezerv;
     game.chng:=game.ponderchng;
     game.oldtime:=game.time;
     SetRemain;
     Board.remain:=0;
    end;
  if pos('ponderhit',s)>0  then
    begin
      game.time:=game.pondertime;
      game.rezerv:=game.ponderrezerv;
      game.chng:=game.ponderchng;
      game.oldtime:=game.time;
      SetRemain;
      Board.remain:=0;
    end;
end;
Procedure WaitPonderhit;
var
  n : integer;
  s : ansistring;
begin
  while true  do
   begin
    n := CheckInput;
    if n = 0 then
      begin
       sleep(25);
       continue;
      end;
    s := ReadInput(n);
    if (pos('stop',s)>0) or (pos('quit',s)>0) or (pos('ponderhit',s)>0)  then break;
   end;
end;

end.
