program Booot4150;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  bitboards in 'bitboards.pas',
  params in 'params.pas',
  init in 'init.pas',
  captures in 'captures.pas',
  genmoves in 'genmoves.pas',
  attacks in 'attacks.pas',
  make in 'make.pas',
  perft in 'perft.pas',
  x in 'x.pas',
  preeval in 'preeval.pas',
  eval in 'eval.pas',
  hash in 'hash.pas',
  escape in 'escape.pas',
  see in 'see.pas',
  history in 'history.pas',
  next in 'next.pas',
  search in 'search.pas',
  epd in 'epd.pas',
  think in 'think.pas',
  fors in 'fors.pas',
  root in 'root.pas',
  book in 'book.pas',
  egtb in 'egtb.pas',
  pawnev in 'pawnev.pas',
  safety in 'safety.pas';

label opros,s1,s2;
var
   i,j,mov:integer;
   strmove:string[20];
   inputstring :AnsiString;
   dest,From,ran : integer;
begin
GetStd;
hasbook := BookInitialize(0);
Fill_Work_Arrays;
Do_BitBoards;
FillEvalData;
Randomize;
FillZobrist;
ReadConfig;
UCImode:=false;
XBoardMode:=false;
timer.TimeMode:=ExactTime;
timer.NumberMoves:=0;
timer.BaseTime:=10;
timer.Increment:=0;
OldRootDepth:=0;
PredictedMove:=0;
canuseeg:=CanUseEGTB;
NewGame;
//Printbitboard(Bback[e4]);
opros:
While (not MoveNow) or (ForceMode) do
  begin
   // Читаем очередную команду от оболочки
   readln(inputstring);
   recognize(inputstring);
  end;
if ExitNow then
  begin
   exit;
  end;
ran:=0; RootEval:=0;mov:=0;MateInOne:=false;
if (sidetomove=white) and (wforce<>0) then
  begin
    dec(MovesToControl,wforce);
    wforce:=0;
    bforce:=0;
  end else
if (sidetomove=black) and (bforce<>0) then
  begin
    dec(MovesToControl,bforce);
    wforce:=0;
    bforce:=0;
  end;
// Пробуем воспользоваться нашей дебютной библиотекой
if (usebook = true) then
   begin
    ran:= ProbeBook(notc);
   end;
  if ran>1 then
  begin
     if MovesToControl<=0 then MovesToControl:=timer.NumberMoves;
     i:=random(ran);
     for j:=1 to 256 do
       begin
       if BookCandidat[j,2]>=i then
          begin
            mov:=BookCandidat[j,1];
            break;
          end;
       i:=i-BookCandidat[j,2];
       end ;

     mov:=CalcMove(mov);
     dec(MovesToControl);
     if (not isvalidmove(sidetomove,mov,1)) then
        begin
          inc(MovesToControl);
          usebook:=false;
          goto s2;
        end;

     goto s1;
  end
     else usebook:=false;
s2:
canadd:=false;added:=false;
// Расчитываем время на ход:
If (timer.TimeMode=ExactTime)
     then
         // Если установлен режим "время на ход"
         begin
         EngineTime:=timer.BaseTime*100;
         RemainNodes:=50000;
         end
     else
        begin
         if (timer.TimeMode=Convection)
              // Если установлен уровень: количество ходов за время
              then
                 begin
                 if MovesToControl<=0
                     then
                          MovesToControl:=timer.NumberMoves;

                 if MovesToControl=1
                          then EngineTime:=trunc(EngineClock*0.7)
                          else EngineTime:=trunc(EngineClock/MovesToControl);
                 if EngineTime>500 then RemainNodes:=250000
                 else
                 if EngineTime>200 then RemainNodes:=100000
                 else RemainNodes:=1000;
                 rezerv:=EngineClock div 2;
                 if (rezerv>Enginetime) and (rezerv>1000) then canadd:=true;
                 dec(MovesToControl);
                 end
              else
                 begin
                 // Уровень: время до конца партии (как вариант -  с добавлением)
                 if (timer.Increment=0) or (EngineClock<1000)
                   then EngineTime:=trunc(EngineClock/30)
                   else EngineTime:=trunc(EngineClock/20)+timer.Increment*100;
                 if EngineTime<200 then RemainNodes:=100000
                                   else RemainNodes:=250000;
                 rezerv:=EngineClock div 2;
                 if (rezerv>Enginetime) and (rezerv>1000) then canadd:=true;
                 end;


        end;
       
inc(age);
if age>100 then age:=0;
score:=0;
wking:=tree[1].Wking;
bking:=tree[1].Bking;
RootEval:=0;
mov:=iterate;
s1:
if (mov=0)  then
           begin
           MoveNow:=false;
           goto opros;
           end;
from:=mov and 255;
dest:=(mov shr 8) and 255;

strmove:=Decode[From ]+Decode[Dest];
//Проверяем на слабое превращение
if   ((WhatPiese(from)=Pawn) and (Dest>h7))
  or ((WhatPiese(from)=-Pawn) and (Dest<h2))
  then
  case ((mov shr 24) and 15) of
    Knight : strmove:=strmove+'n';
    Rook : strmove:=strmove+'r';
    Bishop : strmove:=strmove+'b';
    Queen : strmove:=strmove+'q';
    end;
MakeMove(sidetomove,mov,1);
Notation[notc]:=mov and 16383;
inc(notc);
tree[1]:=tree[2];
Rule50[1]:=Rule50[2];
HashGame[Rule50[1]]:=tree[1].HashKey;
SideToMove:=SideToMove xor 1;
backundo(sidetomove);
if XboardMode
 then  Lprint('move '+strmove)
 else  Lprint('bestmove '+strmove);
if MateInOne then begin
                   if SideToMove=white
                   then LPrint('0-1 {Black Mates}')
                   else LPrint('1-0 {White Mates}');
                  end;
if Rule50[1]>=100 then Lprint('1/2-1/2 {50 Moves Rule}');
if isDrawRep then LPrint('1/2-1/2 {Repetition}');
if isInsuff(1) then LPrint('1/2-1/2 {Insufficient Material}');
// Если оценка позиции плохая, то сдаемся:
if RootEval<-Resign then inc(resCount)
                    else resCount:=0;
if Rescount>2 then
LPrint('resign');                   

MoveNow:=false;
goto opros;
end.
