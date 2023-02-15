unit Uci;

interface
uses Windows,SysUtils,params,Board,Search,Move,hash,attacks,movegen,history,evaluation;
Const
     MaxBufer=8192;
VAR
   stin,stout : int64;
   isConsole:boolean;

Procedure SetupChanels;
procedure LWrite(s:ansistring);
Procedure Parser(s:string;var Board:Tboard;var SortUnit:TsortUnit;var PV:TPVLine);
function GetParam(from:string;what:string): integer;
Procedure Main;
Procedure ForceMoves(var Board:Tboard;mlist:string);
Procedure poll(var AbortSearch:boolean);
Procedure WaitPonderhit;
implementation

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

function ReadInput(total:integer): ansistring;
var
 n: cardinal;
 Inp: array[0..MaxBufer-1] of ansichar;
begin
  Readfile(stin,Inp,total,n,nil);
  Inp[n] := #0;
  result := Inp;
  result := trim(result);
end;

Procedure Main;
var
   n:integer;
   Board : Tboard; // Основная структура
   SortUnit : TsortUnit;// Основная структура
   PV:TPVLIne;
   s:ansistring;
begin
  repeat
    n := CheckInput;
    if n = 0 then
      begin
        sleep(50);
        continue;
      end;
    s := ReadInput(n);
  // Получили команду на выход
    if s='quit' then break;
  // Разбираем полученную команду
  Parser(s,Board,SortUnit,PV);
  until false;
end;
Procedure CalcEngineTime(var Board:Tboard;wtime:integer;btime:integer;winc:integer;binc:integer;movestocontrol:integer);
var
   mytime,myinc : integer;
begin
  if Board.Color=white then
    begin
      mytime:=wtime;
      myinc:=winc;
    end else
    begin
      mytime:=btime;
      myinc:=binc;
    end;
  if movestocontrol=0 then
    begin
      if myinc>0 then
        begin
          game.time:=(mytime div 20)+myinc;
          game.rezerv:=(mytime div 2);
        end else
        begin
          // SuddenDeath
          game.time:=(mytime div 30);
          game.rezerv:=(mytime div 4);
        end;
    end else
    begin
      if movestocontrol=1 then
        begin
          game.time:=(mytime div 2);
          game.rezerv:=(mytime div 4)*3;
        end else
        begin
          if movestocontrol<20
           then game.time:=(mytime div movestoControl)
           else game.time:=mytime div 20;
         game.rezerv:=(mytime div 4);
        end;
    end;
  if game.time>game.rezerv then game.time:=game.rezerv;
end;
Procedure Parser(s:string;var Board:Tboard;var SortUnit:TsortUnit;var PV:TPVLine);
var
   n,wtime,btime,winc,binc,movestocontrol,val : integer;
   fen,mlist,sval:string;
   pondermove:Tmove;
begin
  if s='' then exit;
  if s='eval' then
    begin
      Lwrite('Score = '+IntToStr(Eval(Board,val)));
    end;
  if s='uci' then                                                                //uci
    begin
     LWrite('id name ' + EngineName);
     LWrite('id author Alex Morozov');
     // Тут вываливаем списко параметров движка
     LWrite('option name Hash type spin default 64 min 8 max 512');
     LWrite('option name Ponder type check default true');
     LWrite('uciok');
     exit;
    end;
  if s = 'isready' then                                                          //isready
    begin
     LWrite('readyok');
     exit;
    end;
  if pos('setoption ',s) = 1 then
    begin
     s := lowercase(s);
     n := pos('value ',s);
     if n > 1 then
       begin
        sval := trim(copy(s,n+6,length(s)));
        if (pos('name hash',s) > 0) or ((pos('name Hash',s) > 0)) then
         begin
          val := StrToIntDef(sval,0);
          SetHash(TT,val*16384);
         end else
        if (pos('name ponder',s) > 0) or (pos('name Ponder',s) > 0) then
         begin
           if pos('true',sval) > 0 then game.uciPonder:=true else
           if pos('false',sval) > 0  then game.uciPonder:=false;
         end;
       end;
     exit;
    end;
  if pos('ucinewgame ',s) >0 then
    begin                                                                       // ucinewgame
      ClearHash(TT,HashSize);
      SetBoard(StartPositionFEN,Board);
      exit;
    end;
  if pos('position ',s) = 1 then
    begin                                                                        //Position
     n := pos('moves ',s);
     if n > 0 then
       begin
        mlist := copy(s,n+5,length(s));
        fen := copy(s,1,n-1);
       end   else
       begin
        mlist := '';
        fen := s;
       end;
      n := pos('fen ',fen);
      if n > 0 then fen := copy(fen,n+4,length(fen)) else fen := '';
      SetBoard(fen,Board);
      ForceMoves(Board,mlist);
      exit;
     end;
  if pos('fv',s) = 1 then
    begin
      game.remain:=50000;
      writeln(FV(Board,0,1,0,1,pv));
    end;
  if pos('go ',s) = 1 then
   begin                                                                         //go
     if pos('infinite',s) > 0 then
       begin                                                                     // infinite
        game.time:=48*3600*1000;
        game.rezerv:=48*3600*1000;
        Think(Board,SortUnit,Pv);
       end else
       begin
        wtime:=GetParam(s,'wtime');
        btime:=GetParam(s,'btime');
        winc:=GetParam(s,'winc');
        binc:=GetParam(s,'binc');
        movestocontrol:=GetParam(s,'movestogo');
        // Здесь считаем контроль времени
        CalcEngineTime(Board,wtime,btime,winc,binc,movestocontrol);
        game.pondertime:=game.time;
        game.ponderrezerv:=game.rezerv;
        if (pos('ponder',s) > 0) or (pos('Ponder',s) > 0)
           then
            begin
             game.time:=24*3600*1000;
             game.rezerv:=24*3600*1000;
             think(Board,SortUnit,pv);
            end
           else think(Board,SortUnit,pv);
       end;
     s := MoveToStr(PV.Moves[1]);
     pondermove:=PV.Moves[2];
     if (pondermove <> MoveNone) and (game.uciPonder)
        then s := s + ' ponder ' + MoveToStr(pondermove);
     Lwrite('bestmove ' + s);
     exit;
  end;
end;
function FindStringParam(from:string;what:string): string;
var n: integer;
begin
  result := '';
  n := pos(what,from);
  if n < 1 then exit;
  delete(from,1,n+length(what)-1);
  from := trim(from) + ' ';
  result := copy(from,1,pos(' ',from)-1);
end;

function GetParam(from:string;what:string): integer;
var
  temp:string;
begin
  temp:=FindStringParam(from,what);
  if temp=''
    then result:=0
    else result := StrToIntDef(temp,0);
end;
Procedure ForceMoves(var Board:Tboard;mlist:string);
var
 v: integer;
 smove: string;
 move:Tmove;
 Undo:Tundo;
begin
  mlist := trim(mlist) + ' ';
  repeat
    v := pos(' ',mlist);
    smove:= trim(copy(mlist,1,v));
    if smove<>'' then
      begin
        move:=StrTomove(smove,Board);
        MakeMove(Board.Color,move,Board,Undo);
        Board.oncheck:=isAttackedBy(Board.Color xor 1,board.KingSq[board.Color],Board);
      end;
    delete(mlist,1,v);
  until length(mlist) < 4;
end;
Procedure poll(var AbortSearch:boolean);
var
   n:integer;
   s:string;
   timetot:cardinal;
begin
  Timetot:=gettickcount - game.TimeStart;
  if timetot>=game.time then AbortSearch:=true;
  game.remain:=50000;
  n := CheckInput;
  if n = 0 then exit;
  s := ReadInput(n);
  if (s='quit') or (s='stop') then AbortSearch:=true;
  if (s='ponderhit') then
    begin
      game.time:=game.pondertime;
      game.rezerv:=game.ponderrezerv;
      game.oldtime:=game.time;
    end;
end;
Procedure WaitPonderhit;
var
  n : integer;
  s : ansistring;
begin
  n:=0;
  while n=0  do
   begin
    n := CheckInput;
    if n = 0 then continue;
    s := ReadInput(n);
    if (s='stop') or (s='quit') or (s='ponderhit')  then break
   end;
end;
end.
