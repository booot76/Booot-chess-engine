unit uSearch;

interface
uses uBitBoards,uBoard,uThread,uEval,uSort,uMaterial,uEndgame,uPawn,uAttacks,uMagic,uHash,SysUtils,Windows,Math;
Type
  Tgame = record
              TimeStart : Cardinal;
              time  : Cardinal;
              rezerv:Cardinal;
              pondertime  : Cardinal;
              ponderrezerv : Cardinal;
              oldtime:cardinal;
              HashAge : integer;
              NodesTotal : cardinal;
              remain:integer;
              uciPonder : boolean;
              hashsize : integer;
              Threads : integer;
              showtext : boolean;
              doIIR : boolean;
              doLMP : boolean;
              gendepth:integer;
              saveENNPass : boolean;
            end;
   Trand=record
     beg : integer;
     en  : integer;
   end;

Const

  BuferSize=10000;
  MaxPly=127;
  Mate=32700;
  Inf=Mate+1;
  Draw=0;
  Stalemate=Draw;

  FullInfo=0;
  OnlyDepth=1;
  TimeStat=2;
  LowerStat=3;

  DeltaMargin=80;
  PieseFutilityValue : array[-Queen..Queen] of integer =(QueenValueEnd,RookValueEnd,BishopValueEnd,KnightValueEnd,PawnValueEnd,0,PawnValueEnd,KnightValueEnd,BishopValueEnd,RookValueEnd,QueenValueEnd);

  RazorMargin=225;
  RazorDepth=4;

  StatixMargin=80;
  StatixDepth=7;

  ProbCutDepth=5;
  ProbCutRed=4;
  ProbCutMargin=85;

  CountMoveDepth=16;

  FutilityMargin=100;

  SingularDepth=8;

  HistoryDepth=3;

  IIDDepth = 8;
  IIDRed=7;
type
   TBufferFen = array[0..BuferSize] of shortstring;
var
  game:TGame;
  RazoringValue,StatixLValue : array[0..16] of integer;
  StatixValue : array[false..True,0..16] of integer;
  PrunningCount : array[false..true,0..16] of integer;
  LMRREd : array[false..True,1..MaxPly,1..Maxmoves] of integer;
  Reductions : array[1..64] of real;
  BookFen : array of ansistring;
  PositionHash : array of int64;
  blockscount : integer;
  usebook : boolean;
  booksize : integer;
  StartTime : TdateTime;
  FenNumber,PosHashSize,PosHashMask : int64;

Procedure Think;
Procedure Iterate(ThreadId:integer);
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
Function Search(ThreadID:integer;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;emove:integer;cut:boolean):integer;
Function FV(ThreadID:integer;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV):integer;
Procedure gamegen(ThreadId:integer;var cnt:integer;var FENS:TBufferFen);
Procedure FenGenerator(depth:integer;megafens:integer;cpu:integer;book:shortstring;outfilename:shortstring;hashmb:integer;poshashmb:integer);
Procedure SingleGenerator(ThreadID:integer;var bookposnum:integer);
implementation
uses uUci,uNN;
Function MakePvString(var PV:TPV):ansistring;
var
  i : integer;
  s:ansistring;
begin
  s:='';
  For i:=1 to Pv[0] do
    begin
      if Pv[i]=0 then
        begin
          Pv[0]:=i-1;
          break;
        end;
      s:=s+' '+StringMove(Pv[i]);
    end;
  Result:=s;
end;
Procedure PrintFullSearchInfo(value:integer;pv:TPV;TimeEnd:Cardinal;typ:integer);
var
 timetot:Cardinal;
 nps,i : integer;
 s:ansistring;
 FullNodes : int64;
begin
  If game.Threads=1
    then FullNodes:=Threads[1].Board.Nodes
    else begin
           FullNodes:=0;
           for i:=1 to game.Threads do
             FullNodes:=FullNodes+Threads[i].Board.Nodes;
         end;
  timetot:=timeend-game.timestart;
  // Даем статистику с небольшой задержкой, чтобы не перегружать оболочку данными и не терять время
  if (TimeTot<250) or (not game.showtext) then exit;
  // Тут выдаем полную информацию о переборе. Когда изменился лучший ход.
  if (typ=FullInfo) then
    begin
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(Threads[1].rootdepth);
     if value<-Mate+MaxPly then s:=s+' score mate -'+inttostr(((value+mate) div 2)+1) else
     if value>Mate-MaxPly  then s:=s+' score mate ' +inttostr((mate-value) div 2) else
     s:=s+' score cp '+inttostr(value);
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
     s:=s+' pv '+MakePvString(PV);
     LWrite(s);
    end else
// Выдаем только информацию о начавшейся новой итерации
  if (typ=OnlyDepth)  then
    begin
      s:='info depth '+inttostr(Threads[1].rootdepth);
      Lwrite(s);
    end else
// Выдаем статистику по только что завершившейся итерации
  if (typ=TimeStat) then
    begin
      if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
      s:='info depth '+inttostr(Threads[1].rootdepth);
      s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
      Lwrite(s);
    end else
  if (typ=LowerStat) then
    begin
     if value<-Mate+MaxPly then exit;
     if value>Mate-MaxPly  then exit;
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(Threads[1].rootdepth);
     s:=s+' score cp '+inttostr(value);
     s:=s+' lowerbound';
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
     s:=s+' pv '+MakePVString(pv);
     LWrite(s);
    end
end;
Function isDraw(var Board:TBoard;var Tree:TTree;ply:integer):boolean;inline;
var
  MList:TMoveList;
  stop,i : integer;
begin
  // Если достигли правила 50 ходов:
  if (Board.Rule50>=100) and ((Board.CheckersBB=0) or (GenerateLegals(0,Board,MList)>0)) then
    begin
      Result:=true;
      exit;
    end;
  // Если на ветке произошло повторение (в том числе с корневой позицией)
  if Board.nullcnt<Board.Rule50
    then stop:=ply-Board.nullcnt
    else stop:=ply-Board.Rule50;
  i:=ply-2;
  while i>=stop do
    begin
      if i<-1 then break;
      if tree[i].Key=tree[ply].Key then
        begin
          Result:=true;
          exit;
        end;
      i:=i-2;
    end;
  Result:=false;
end;

Function draw_value(var Board:TBoard):integer;
begin
  Result:=2*(Board.Nodes and 1)-1;
end;

Function isCastle(piese:integer;from:integer;dest:integer):boolean;inline;
begin
  result:=(abs(piese)=king) and (abs(from-dest)=2);
end;

Function LMRReduction(imp:boolean;depth:integer;searched:integer):integer;
 var
  r :integer;
  k:real;
begin
  if depth>64 then depth:=64;
  if searched>64 then searched:=64;
  r:=trunc(reductions[depth]*reductions[searched]);
  k:=(r+500)/1000;
  if (r>1000) and (not imp) then k :=k+1;
  if k<0 then k:=0;
  result:=trunc(k);
end;
Procedure AddPV(move:integer;var PVLine:TPV;var Line:TPV);
var
  i : integer;
begin
  If (Line[0]>MaxPly) or (Line[0]<0)
    then Line[0]:=0;
  PVLine[1]:=move;
  for i:=1 to Line[0] do
    PVLine[i+1]:=Line[i];
  PVLine[0]:=Line[0]+1;
end;

Procedure Iterate(ThreadId:integer);
// Крутит цикл итераций (на нужном потоке)
var
  RootAlpha,RootBeta,BestMove,BestValue,Delta,RootDepth,newdepth,CurrBestMove,OldBestMove : integer;
  TimeEnd : Cardinal;
  hbc : integer ;
begin
  BestValue:=-Inf;
  RootAlpha:=-Inf;
  RootBeta:=Inf;
  Delta:=10;
  Threads[ThreadId].StableMove:=0;
  Threads[ThreadId].BestValue:=-Inf;
  RootDepth:=0;BestMove:=0; OldBestMove:=0;Threads[ThreadId].OldPvMove:=0;CurrBestMove:=0;
  // Запускаем цикл итераций
  While RootDepth<=MaxPly do
    begin
     // Главный поток просто увеличивает глубину на 1
     inc(RootDepth);
     Threads[ThreadID].RootDepth:=RootDepth;
     if RootDepth>5 then
       begin
         Delta:=10;
         RootAlpha:=BestValue-Delta;
         If RootAlpha<-Inf then RootAlpha:=-Inf;
         RootBeta:=BestValue+Delta;
         if RootBeta>Inf then RootBeta:=Inf;
       end;
     hbc:=0;
     While true do
      begin
       newdepth:=rootDepth-hbc;
       if newdepth<1 then newdepth:=1;
       BestValue:=RootSearch(ThreadId,RootAlpha,RootBeta,newdepth,Threads[ThreadId].Board,Threads[ThreadId].Tree,Threads[ThreadId].Sortunit,Threads[ThreadId].RootList,Threads[ThreadID].RootMoves,Threads[ThreadId].PVLine,BestMove);
       if Threads[ThreadId].AbortSearch then break;
       if BestMove<>0 then
        begin
          Threads[ThreadId].StableMove:=BestMove;
          // Обновляем Порядок ходов в списке ходов из корня (лучший ход идет на первое место в списке)
          UpdateList(BestMove,0,Threads[ThreadId].RootMoves-1,Threads[ThreadID].RootList);
          Threads[ThreadId].BestValue:=BestValue;
          AddPv(Bestmove,Threads[ThreadId].StablePv,Threads[ThreadId].Pvline);
        end;
       if BestValue<=RootAlpha then
        begin
          hbc:=0;
          RootBeta:=(RootAlpha+RootBeta) div 2;
          RootAlpha:=BestValue-Delta;
          if RootAlpha<-Inf then RootAlpha:=-Inf;
          // Если оценка просела, то добавляем время на обдумывание
          If (ThreadId=1) and  (game.time<>game.rezerv) then game.time:=game.rezerv;
        end else
       if BestValue>=RootBeta then
        begin
          inc(hbc);
          If (ThreadID=1) then PrintFullSearchInfo(BestValue,Threads[ThreadId].PVLine,GetTickCount,LowerStat);
          RootBeta:=BestValue+Delta;
          if RootBeta>Inf then RootBeta:=Inf;
          // Если оценка просела, то добавляем время на обдумывание
          If (ThreadId=1) and  (game.time<>game.rezerv) then game.time:=game.rezerv;
        end else break;
       Delta:=Delta+(Delta div 4)+2;
      end;
      if Threads[ThreadId].AbortSearch then break;
      Threads[ThreadId].FullDepth:=RootDepth;
      Threads[ThreadId].BestValue:=BestValue;
      Threads[ThreadId].OldPvMove:=CurrBestMove;
      CurrBestMove:=BestMove;
      AddPv(Bestmove,Threads[ThreadId].StablePv,Threads[ThreadId].Pvline);
     // Завершили итерацию - обновляем статистику итерации (перебранные узлы и время)
     If ThreadID=1 then
      begin
       TimeEnd:=GetTickCount;
       PrintFullSearchInfo(0,Threads[ThreadId].StablePv,TimeEnd,TimeStat);
       // После заверщившейся итерации возвращаем нормальный показатель времени
       If (OldBestMove=CurrBestMove)
         then game.time:=game.oldtime
         else game.time:=game.rezerv;
       OldBestMove:=CurrBestMove;
        // Если осталось не так много времени - выходим не начиная новую итерацию
       If (game.time<>game.rezerv) and ((TimeEnd-game.TimeStart)>(0.7*game.time)) then break;
      end;

    end;
end;
Procedure Think;
// Основная функция , обеспечивающая перебор. Запускается когда оболочка получает команду go и выдает оболочке лучший ход и прочую информацию.
Label
  l1;
var
  n,j : integer;
  s : ansistring;
  TimeEnd : Cardinal;
  Pondermove,BestID: integer;
begin
  NewSearch(1);
  Threads[1].PVLine[0]:=0;
  // Генерируем список ходов из корня позиции
  n:=GenerateLegals(0,Threads[1].Board,Threads[1].RootList);
  Threads[1].RootMoves:=n;
 // Если перебор невозможен (мат или пат) то выдаем об этом сообщение оболочке и уходим
  if n=0 then
    begin
      s:='info depth '+inttoStr(MaxPly)+' score ';
      if Threads[1].Board.CheckersBB<>0
        then s:=s+inttostr(-mate)
        else s:=s+'0';
      If game.showtext then LWrite(s);
      BestId:=1;
      Threads[BestId].FullDepth:=MaxPly;
      Threads[BestId].RootList[0].move:=0;
      goto  l1;
    end;

  // Запускаем вспомогательные потоки
  IF game.Threads>1 then
    begin
       // Заполняем структуры в потоках при многопоточном переборе
      For j:=2 to game.Threads do
        CopyThread(j);
      SetEvent(IdleEvent);
    end;
  // Запускаем основной поток и ждем его завершения по таймауту или пользователем
  Iterate(1);
  BestID:=1;
  If game.Threads>1 then
   begin
     // Останавливаем оставшиеся потоки
    For j:=2 to game.Threads do
     Threads[j].AbortSearch:=true;
    ResetEvent(IdleEvent);
    While isThreadIdle do;
    // Смотрим: нет ли среди вспомогательных потоков того, кто перебрал на большую глубину или имеет лучшую оценку:
    For j:=2 to game.Threads do
     If (Threads[j].FullDepth>Threads[BestID].FullDepth) or ((Threads[j].FullDepth=Threads[BestID].FullDepth) and (Threads[j].BestValue>Threads[BestId].BestValue)) then BestId:=j;
   end;
  TimeEnd:=GetTickCount;
  // Если вылетели слишком быстро по времени, то печатаем хоть какую-то статистику для отображения:
  If (TimeEnd-game.TimeStart)<200 then
    begin
      TimeEnd:=game.TimeStart+200;
      PrintFullSearchInfo(Threads[BestId].BestValue,Threads[BestId].PVLine,TimeEnd,FullInfo);
    end else
  // Если лучший результат достигнут во вспомогательном потоке - выводим информацию об этом
  If BestID<>1 then PrintFullSearchInfo(Threads[BestId].BestValue,Threads[BestId].StablePV,TimeEnd,FullInfo);
l1:
  // Если в пондеррежиме достигли максимума по глубине - просто "зависаем" и ждем от оболочки команду на выход из пондеррежима
  if (Threads[BestId].FullDepth>=MaxPly-1) and (game.time>=48*3600*1000) and (game.rezerv>=48*3600*1000) and (game.uciPonder) then WaitPonderhit;
  // Печатаем оболочке лучший ход, полученный в процессе перебора ( и пондерход если находимся в соответствующем режиме)
  if Threads[BestId].StableMove=0 then Threads[BestId].StableMove:=Threads[BestId].RootList[0].move;
  // Пробуем вытащить PonderMove  если это возможно:
  If (game.uciPonder) and (Threads[BestId].StableMove<>0)
    then Pondermove:=FindPonder(Threads[BestId].StableMove,Threads[1].Board)
    else Pondermove:=0;
  s:=StringMove(Threads[BestId].Stablemove);
  if (pondermove<>0) and (game.uciPonder)
        then s := s + ' ponder ' + StringMove(pondermove);
  If (Threads[BestId].StableMove<>0) and (game.showtext) then LWrite('bestmove '+s);
end;
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
var
   CheckInfo : TCheckInfo;
   Undo : TUndo;
   BestValue,j,extension,newdepth,value,R,D,move,qsearched,capsearched,hashmove,piese,from,dest,histvalue:integer;
   TimeEnd:Cardinal;
   isCheck,doresearch,pv,hashcap,imp:boolean;
   Line:TPV;
   OldMoves,OldCaptures:TMoveList;
begin
  // Инициализация
  pv:=beta-alpha>1;
  PVLine[0]:=0;
  line[0]:=0;
  TimeEnd:=0;
  qsearched:=0;capsearched:=0;
  tree[1].Key:=Board.Key;
  Threads[Threadid].nullply:=0;
  Threads[Threadid].nullclr:=-1;
   // Готовимся к перебору
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  // Аккумуляторы
  FillWhiteAcc16(Net.model,Board,Threads[ThreadId].Pass[1]);
  FillBlackAcc16(Net.model,Board,Threads[ThreadId].Pass[1]);
  // Печатаем текущую глубину
  If (threadId=1) then
    begin
     TimeEnd:=GetTickCount;
     PrintFullSearchInfo(0,PVLine,TimeEnd,OnlyDepth);
    end;
  BestValue:=-Inf;
  BestMove:=0;
  Tree[-1].StatEval:=-Inf;
  Tree[0].StatEval:=-Inf;
  tree[1].dblext:=0;
  if Board.CheckersBB=0
    then Tree[1].StatEval:=Evaluate(Board,1,1)
    else Tree[1].StatEval:=-Inf;
  hashmove:=RootList[0].move;
  imp:=false;
  hashcap:=(hashmove and CaptureFlag)<>0;
  // Крутим цикл ходов из корня
  for j:=0 to n-1 do
       begin
         move:=RootList[j].move;
         from:=move and 63;
         dest:=(move shr 6) and 63;
         piese:=Board.Pos[from];
         // статистика о текущем перебираемом ходе
         if (ThreadID=1) and ((TimeEnd-game.TimeStart)>2000) and (game.showtext) then   Lwrite('info currmovenumber '+inttostr(j+1)+' info currmove '+StringMove(move));
         isCheck:=isMoveCheck(move,CheckInfo,Board);
         extension:=0;
         if (isCheck) and (((CheckInfo.DiscoverCheckBB and Only[from])<>0) or (GoodSee(move,Board,0))) then extension:=1;
         newdepth:=depth+extension-1;
         Tree[1].CurrMove:=move;
         Tree[1].CurrNum:=j+1;
         Tree[1].CurrStat:=@Sortunit.HistorySats[(Board.CheckersBB<>0),((move and CaptureFlag)<>0),piese,dest];
         MakeMove(move,Board,Undo,isCheck);
         //Обновляем аккумуляторы
         UpdAcc16(move,Board,Undo,Threads[ThreadId].Pass[1],Threads[ThreadId].Pass[2]);
         value:=-Inf;
         if (j=0) then value:=-Search(ThreadId,-Beta,-Alpha,newdepth,2,Board,Tree,SortUnit,Line,0,false) else
           begin
            doresearch:=true;
             // LMR Reduction
             if (depth>=3) and (j>2)  and ((move and CapPromoFlag)=0) then
               begin
                R:=LMRRED[imp,depth,j+1];
                If pv then R:=R-trunc(2+15/(depth+3));
                If hashcap then inc(R);
                HistValue:=GetHistoryValue(SortUnit,Tree,1,piese,dest)-4000;
                R:=R-(HistValue div 16000);
                if R>0 then
                  begin
                   D:=newdepth-R;
                   if D<1 then D:=1;
                   value:=-Search(ThreadId,-alpha-1,-alpha,D,2,Board,Tree,SortUnit,Line,0,true);
                   doresearch:=(value>alpha);
                  end;
               end;
             if (doresearch) then value:=-Search(ThreadId,-alpha-1,-alpha,newdepth,2,Board,Tree,SortUnit,Line,0,true);
             if (value>alpha)   then
              begin
               // Если ход из корня меняется - даем дополнительное время чтобы завершить его оценку
               If (ThreadId=1) and (game.time<>game.rezerv) then game.time:=game.rezerv;
               value:=-Search(ThreadId,-beta,-alpha,newdepth,2,Board,Tree,SortUnit,Line,0,false);
              end;
           end;
         UnMakeMove(move,Board,Undo);
         if Threads[ThreadId].AbortSearch then break;
      // Если сменился лучший ход из корня (или он первый) то запоминаем это на случай если вся итерация не успеет завершиться.
         If (j=0) or  (value>alpha) then
           begin
             Threads[ThreadId].FullDepth:=depth;
             Threads[ThreadId].BestValue:=value;
             Threads[ThreadId].stableMove:=move;
             Threads[ThreadId].StablePv[0]:=1;
             Threads[ThreadId].StablePv[1]:=move;
           end;
         if value>BestValue then
          begin
           BestValue:=value;
           if value>alpha then
            begin
             // Сменился лучший ход из корня - печатаем полную статистику
             BestMove:=move;
             // Получаем обновленный основной вариант
             AddPv(Bestmove,PVLine,Line);
             if value>=beta then break;
             If (ThreadId=1) then PrintFullSearchInfo(BestValue,PVLine,GetTickCount,FullInfo);
             alpha:=value;
            end;
          end;
        // Тихие  ходы сохраняем отдельно
         if bestmove<>move then
          begin
           if  ((move and CaptureFlag)=0) then
            begin
             inc(qsearched);
             OldMoves[qsearched].move:=move;
            end else
            begin
             inc(capsearched);
             OldCaptures[capsearched].move:=move;
            end;
          end;
       end;
  if not Threads[ThreadId].AbortSearch then
    begin
     // Обновляем историю
     if (BestMove<>0) then UpdateFullHistory(Bestmove,depth,1,qsearched,OldMoves,capsearched,OldCaptures,SortUnit,Board,Tree,BestValue-beta);
    end else BestValue:=0;
  Result:=BestValue;
end;

Function Search(ThreadID:integer;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;emove:integer;cut:boolean):integer;
label l1;
var
  Undo : TUndo;
  CheckInfo : TCheckInfo;
  MList,OldMoves,OldCaptures:TMoveList;
  value,hashmove,hashvalue,hashdepth,hashtyp,move,searched,qsearched,capsearched,extension,newbeta,newdepth,StaticEval,Eval,R,NullValue,D,BestValue,preddepth,BestMove,HistValue,piese,from,dest: integer;
  killer1,killer2,countermove,oldstat,hashm,ProbMar,probcnt : integer;
  pv,isCheck,doresearch,SingularNode,imp,skip,hashcap,badprobcut,quietsingular: boolean;
  Line : TPV;
  HashIndex : int64;
begin
  // Листья
  if depth<=0 then
    begin
      Result:=FV(ThreadId,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine);
      exit;
    end;
  // Подготовка к перебору
  inc(Board.Nodes);
  dec(Board.remain);
  pv:=(beta-alpha)>1;
  qsearched:=0;capsearched:=0;
  tree[ply].Key:=Board.Key;
  SortUnit.Killers[ply+2,0]:=0;
  SortUnit.Killers[ply+2,1]:=0;
  if (ThreadID=1) and (Board.remain<=0) then
    begin
      Board.remain:=game.remain;
      poll(Board);
    end;
  If (Threads[ThreadId].AbortSearch) or (ply>=MaxPly-1) or (isDraw(Board,tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board,ThreadID,ply)
       else result:=draw_value(Board);
     exit;
    end;
  // Mate Prunning
  if alpha<-Mate+ply then alpha:=-Mate+ply;
  if beta>Mate-ply then beta:=Mate-ply;
  if alpha>=beta then
    begin
      Result:=alpha;
      exit;
    end;
  // Hash
  if emove<>0
     then HashIndex:=-1
     else HashIndex:=HashProbe(Board,Board.Key);
  if HashIndex>=0 then
    begin
      Hashmove:=TT[HashIndex].move;
      HashValue:=ValueFromTT(TT[HashIndex].value,ply);
      Hashtyp:=TT[HashIndex].typage and 3;
      HashDepth:=TT[HashIndex].depth;
      StaticEval:=TT[HashIndex].steval;
      if (not pv) then
        begin
         if (hashdepth>=depth) and (HashValue<>-Inf) then
          begin
            if (((hashtyp and HashLower)<>0) and (hashvalue>=beta)) or (((hashtyp and HashUpper)<>0) and (hashvalue<=alpha))  then
              begin
                If HashMove<>0 then
                  begin
                    If HashValue>=beta then
                      begin
                        If ((Hashmove and CaptureFlag)=0) then UpdateQuietHistory(Hashmove,depth,ply,qsearched,OldMoves,SortUnit,Board,Tree,DepthInc[depth]);
                        If (tree[ply-1].CurrNum<3) and (Tree[ply-1].CurrMove<>0) and ((Tree[ply-1].CurrMove and CaptureFlag)=0) then UpdateStats(SortUnit,Tree,ply-1,Board.Pos[(tree[ply-1].CurrMove shr 6) and 63],(tree[ply-1].CurrMove shr 6) and 63,-GetStatBonus(depth+1));
                      end else
                    If ((Hashmove and CaptureFlag)=0) then
                      begin
                        value:=-GetStatBonus(depth);
                        piese:=Board.Pos[Hashmove and 63];
                        dest:=(Hashmove shr 6) and 63;
                        UpdHistory(SortUnit,piese,dest,value);
                        UpdHistoryStats(Tree,ply,piese,dest,value);
                      end;
                  end;
               if Board.Rule50<90 then
                begin
                 Result:=HashValue;
                 exit;
                end;
              end;
          end;
        end;
    end else
    begin
      HashMove:=0;
      HashValue:=-Inf;
      HashTyp:=0;
      Hashdepth:=-Maxply;
      StaticEval:=-inf;
    end;
    SetUndo(Board,Undo);
    FillCheckInfo(CheckInfo,Board);
  // Статическая оценка
  if (Board.CheckersBB=0) then
    begin
     If StaticEval=-inf then
      begin
       if (tree[ply].StatKey=Board.Key)
         then StaticEval:=tree[ply].StatEval
         else StaticEval:=Evaluate(Board,ThreadID,ply);
      end;
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
     Eval:=StaticEval;
     if (HashIndex>=0) and (eval=0) and (TT[HashIndex].steval=0)  then eval:=draw_value(Board);
     // Уточняем оценку хешем
     if (HashIndex>=0) and (HashValue<>-Inf) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<Eval) then Eval:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>Eval) then Eval:=HashValue;
       end;
     imp:=(ply>1) and (Tree[ply].StatEval>tree[ply-2].StatEval);
     // Если мы не под шахом - включаем дополнительные алгоритмы
     // Razoring
     if (not pv) and (depth<RazorDepth)  and (Eval<=alpha-RazorMargin*depth) then
           begin
             value:=FV(ThreadID,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine);
             if value<=alpha then
               begin
                Result:=value;
                exit;
               end;
           end;
         // Statix
         if (not pv) and (depth<StatixDepth) and (Eval-StatixValue[imp,depth]>=beta)  then
           begin
             Result:=Eval;
             exit;
           end;

         // NullMove
        If (not pv) and (Tree[ply-1].CurrMove<>0) and (emove=0) and (Eval>=beta) and (Eval>=StaticEval) and (Board.NonPawnMat[Board.SideToMove]>0)  and (StaticEval>=beta-14*depth+90) and ((ply>=Threads[ThreadId].nullply) or (Threads[Threadid].nullclr<>Board.SideToMove)) then
           begin
             R:=4+(depth div 4);
             extension:=(Eval-beta) div PawnValueMid;
             if extension>3 then extension:=3;
             R:=R+extension;
             MakeNullMove(Board);
             //Копируем аккумуляторы
             CopyAcc16(Threads[ThreadId].Pass[ply],Threads[ThreadId].Pass[ply+1]);
             Tree[ply].CurrStat:=@SortUnit.HistorySats[false,false,0,a1];
             Tree[ply].CurrMove:=0;
             Tree[ply].CurrNum:=0;
             newdepth:=depth-R;
             If newdepth>0
               then NullValue:=-Search(ThreadId,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,PVLine,0,(not cut))
               else NullValue:=-FV(ThreadId,-beta,-alpha,0,ply+1,Board,SortUnit,Tree,PVLine);
             UnMakeNullMove(Board,Undo);
             If NullValue>=beta then
               begin
                if NullValue>Mate-MaxPly then NullValue:=beta;
                If (depth<12) or (Threads[ThreadId].nullply<>0) then
                  begin
                    Result:=NullValue;
                    exit;
                  end;
                Threads[ThreadId].nullply:=ply+(3*newdepth div 4);
                Threads[ThreadId].nullclr:=Board.SideToMove;
                If newdepth>0
                  then value:=Search(ThreadId,alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,0,false)
                  else value:=FV(ThreadId,alpha,beta,0,ply,Board,Sortunit,Tree,PVLine);
                Threads[ThreadId].nullply:=0;
                Threads[ThreadId].nullclr:=-1;
                If value>=beta then
                  begin
                    Result:=NullValue;
                    exit;
                  end;
               end;
           end;
        newbeta:=beta+ProbCutMargin;
        If newbeta>Mate then newbeta:=Mate;
        badprobcut:=(HashIndex>=0) and (HashDepth>=depth-3) and (HashValue<>-inf) and (HashValue<newbeta);
        // ProbCut
        If (not pv) and (depth>=ProbCutDepth) and (Abs(beta)<Mate-MaxPly) and (not badprobcut) then
          begin
            newdepth:=depth-ProbCutRed;
            tree[ply].Status:=TryHashMove;
            hashm:=hashmove;
            ProbMar:=NewBeta-StaticEval;
            probcnt:=0;
            move:=NextProbCut(SortUnit,MList,Board,Tree,hashm,ply,ProbMar,depth-3);
            While (move<>0) do
              begin
                if  (move<>emove) and (islegal(move,CheckInfo.Pinned,Board)) then
                  begin
                    inc(probcnt);
                    isCheck:=isMoveCheck(move,CheckInfo,Board);
                    tree[ply].CurrMove:=move;
                    Tree[ply].CurrStat:=@Sortunit.HistorySats[false,(move and CaptureFlag)<>0,Board.Pos[move and 63],(move shr 6) and 63];
                    Tree[ply].CurrNum:=probcnt;
                    MakeMove(move,Board,Undo,isCheck);
                     //Обновляем аккумуляторы
                    UpdAcc16(move,Board,Undo,Threads[ThreadId].Pass[ply],Threads[ThreadId].Pass[ply+1]);
                    value:=-FV(ThreadId,-newbeta,-newbeta+1,0,ply+1,Board,SortUnit,Tree,PVLine);
                    if value>=newbeta
                      then value:=-Search(ThreadId,-newbeta,-newbeta+1,newdepth,ply+1,Board,Tree,SortUnit,PVLine,0,(not cut));
                    UnMakeMove(move,Board,Undo);
                    If value>=newbeta then
                      begin
                        Result:=value;
                        exit;
                      end;
                  end;
                move:=NextProbCut(SortUnit,MList,Board,Tree,hashm,ply,ProbMar,depth-3);
              end;
          end;
    // IIR
    if (game.doIIR) and  (pv) and (Hashmove=0)  then
      begin
         dec(depth,2);
         if depth<=0 then
           begin
             result:=FV(ThreadId,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine);
             exit;
           end;
      end;
    if (game.doIIR) and (cut) and (hashmove=0) and (depth>=8) then dec(depth);
    end else
    begin
     StaticEval:=-Inf;
     imp:=false;
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
    end;
  pvline[0]:=0;
  line[0]:=0;
  tree[ply].Status:=TryHashMove;
  BestMove:=0;
  searched:=0;
  BestValue:=-Inf;
  SingularNode:=(Depth>=SingularDepth) and (Hashmove<>0) and (abs(HashValue)<Mate-Maxply)  and (emove=0) and ((HashTyp and HashLower)<>0) and (HashDepth>=depth-3);
  Killer1:=SortUnit.Killers[ply,0];
  Killer2:=SortUnit.Killers[ply,1];
  If Tree[ply-1].CurrMove<>0 then
    begin
      dest:=(Tree[ply-1].CurrMove shr 6) and 63;
      piese:=Board.Pos[dest];
      countermove:=SortUnit.CounterMoves[piese,dest];
    end else countermove:=0;
  skip:=false;
  quietsingular:=false;
  hashcap:=(HashMove<>0) and ((hashmove and CaptureFlag)<>0) ;
  // Перебор
  move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,countermove,ply,depth,skip);
  While move<>0 do
    begin
     if move=emove then goto l1;
     if islegal(move,CheckInfo.Pinned,Board) then
       begin
        inc(searched);
        from:=move and 63;
        dest:=(move shr 6) and 63;
        piese:=Board.Pos[from]; //  Еще ход на доске не сделан
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        extension:=0;
        newdepth:=depth-1;
        // Блок селективностей
        if  (bestvalue>-Mate+Maxply)   and (Board.NonPawnMat[Board.SideToMove]>0)  then
         begin
          skip:=(game.doLMP) and (depth<CountMoveDepth) and (searched>=PrunningCount[imp,depth]);
          If (not isCheck) and ((move and CapPromoFlag)=0)  then
           begin
            preddepth:=newdepth-LMRRED[imp,depth,searched];
            if preddepth<0 then preddepth:=0;
            // HistoryPrunning
            If (preddepth<HistoryDepth) and (move<>killer1) and (move<>killer2) and (move<>countermove)  and (Tree[ply-1].CurrStat^[piese,dest]<0) and (Tree[ply-2].CurrStat^[piese,dest]<0)  then goto l1;
            // FutilityPrunning
            if (preddepth<StatixDepth) and (Board.CheckersBB=0) then
              begin
                value:=StaticEval+StatixLValue[preddepth];
                if value<=alpha then goto l1;
              end;
            // See LowDepth Prunning
            if  (not GoodSee(move,Board,-10*preddepth*preddepth)) then goto l1;
           end else
          If (not GoodSee(Move,Board,-PawnValueEnd*depth)) then goto l1;
         end;
        if ply<Threads[ThreadId].RootDepth*2 then
         begin
          // Singular
          if (SingularNode) and (move=hashmove) then
            begin
             newbeta:=hashvalue-2*depth;
             newdepth:=depth div 2;
             oldstat:=tree[ply].Status;
             value:=Search(ThreadId,newbeta-1,newbeta,newdepth,ply,Board,Tree,SortUnit,PVLine,move,cut);
             tree[ply].Status:=oldstat;
             if value<newbeta then
               begin
                extension:=1;
                quietsingular:=not hashcap;
                if (not pv) and (value<newbeta-15) and (tree[ply-1].dblext<=8) then extension:=2;
               end
               else if (newbeta>=beta) then
                 begin
                   Result:=newbeta;
                   exit;
                 end
               else if (HashValue>=beta) then extension:=-1;
            end else
          if (isCheck) and (((CheckInfo.DiscoverCheckBB and Only[from])<>0) or (GoodSee(move,Board,0))) then extension:=1;
         end;
        if extension=2
          then tree[ply].dblext:=tree[ply-1].dblext+1
          else tree[ply].dblext:=tree[ply-1].dblext;
        newdepth:=depth+extension-1;
        Tree[ply].CurrMove:=move;
        Tree[ply].CurrStat:=@Sortunit.HistorySats[(Board.CheckersBB<>0),((move and CaptureFlag)<>0),piese,dest];
        Tree[ply].CurrNum:=searched;
        MakeMove(move,Board,Undo,isCheck);
         //Обновляем аккумуляторы
        UpdAcc16(move,Board,Undo,Threads[ThreadId].Pass[ply],Threads[ThreadId].Pass[ply+1]);
        value:=-Inf;
        if (pv) and (searched=1) then value:=-Search(ThreadId,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,0,false) else
        begin
          doresearch:=true;
          // LMR Reduction
          if  (depth>=3) and (searched>1) and ((move and CapPromoFlag)=0)  then
            begin
              R:=LMRRED[imp,depth,searched];
              If pv then R:=R-trunc(2+15/(depth+3));
              If hashcap then inc(R);
              if quietsingular then dec(R);
              if (cut) and (move<>killer1) then inc(R,2);
              HistValue:=GetHistoryValue(SortUnit,Tree,ply,piese,dest)-4000;
              R:=R-(HistValue div 16000);
              if R>0 then
                begin
                 D:=newdepth-R;
                 if D<1 then D:=1;
                 value:=-Search(ThreadId,-alpha-1,-alpha,D,ply+1,Board,Tree,SortUnit,Line,0,true);
                 doresearch:=(value>alpha);
                end;
            end;
          if doresearch then value:=-Search(ThreadId,-alpha-1,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,0,(not cut));
          if (pv) and (value>alpha) and (value<beta) then value:=-Search(ThreadId,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,0,false);
        end;
        UnMakeMove(move,Board,Undo);
        if Threads[ThreadId].AbortSearch then break;
        if value>bestvalue then
         begin
          bestvalue:=value;
          if value>alpha then
           begin
            BestMove:=move;
            If pv then AddPv(Bestmove,PVLine,Line);
            If pv and (value<beta)
              then  alpha:=value
              else  break;
           end;
         end;
       //неудачные  ходы сохраняем отдельно
         if bestmove <> move then
          begin
           if  ((move and CapTureFlag)=0)  then
            begin
             inc(qsearched);
             OldMoves[qsearched].move:=move;
            end else
            begin
             inc(capsearched);
             OldCaptures[capsearched].move:=move;
            end;
          end;
       end;
    l1:
       move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,countermove,ply,depth,skip);
    end;
  if not Threads[ThreadId].AbortSearch then
    begin
     // Если ходов в позиции нет, то либо это мат либо пат
     if (searched=0)  then
       begin
        if emove<>0 then BestValue:=alpha else
        if Board.CheckersBB<>0
          then BestValue:=-Mate+ply
          else BestValue:=0;
       end else
      // Обновляем историю
     if (BestMove<>0) then
       begin
         UpdateFullHistory(Bestmove,depth,ply,qsearched,OldMoves,capsearched,OldCaptures,SortUnit,Board,Tree,BestValue-beta);
       end else
     If ((depth>=4) or (pv)) and ((Tree[ply-1].CurrMove)<>0) and  ((Tree[ply-1].CurrMove and CaptureFlag)=0) then UpdateStats(SortUnit,Tree,ply-1,Board.Pos[(tree[ply-1].CurrMove shr 6) and 63],(tree[ply-1].CurrMove shr 6) and 63,GetStatBonus(depth));
     If emove=0 then
      begin
       // Сохраняем хеш
       if BestValue>=beta then HashStore(Board.Key,Board,ValueToTT(Bestvalue,ply),depth,HashLower,Bestmove,staticEval) else
       if (pv) and (BestMove<>0)
        then HashStore(Board.Key,Board,valueToTT(bestvalue,ply),depth,HashExact,BestMove,StaticEval)
        else HashStore(Board.Key,Board,valueToTT(bestvalue,ply),depth,HashUpper,BestMove,StaticEval);
      end;
    end else bestvalue:=0;
  Result:=bestvalue;
end;
Function FV(ThreadID:integer;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV):integer;
label l1;
var
  value,move,bestvalue,futility,qDepth,hashmove,hashvalue,hashdepth,hashtyp,bestmove,cappiese,StaticEval,searched,quietevasions,prevsq,piese,dest: integer;
  HashIndex :int64;
  CheckInfo:TCheckInfo;
  MList : TMoveList;
  Undo:TUndo;
  pv,isCheck,isCapture: boolean;
  Line:TPV;
begin
  inc(Board.Nodes);
  dec(Board.remain);
  pv:=(beta-alpha)>1;
  tree[ply].Key:=Board.Key;
  If pv then line[0]:=0;
  // Выход ранний если ничья или перебор невозможен
  If  (ply>=MaxPly-1) or (isDraw(Board,Tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board,ThreadId,ply)
       else result:=0;
     exit;
    end;
  if (Board.CheckersBB<>0) or (depth>=0)
    then qDepth:=0
    else qDepth:=-1;
  // Hash
  HashIndex:=HashProbe(Board,Board.Key);
  if HashIndex>=0 then
    begin
      Hashmove:=TT[HashIndex].move;
      HashValue:=ValueFromTT(TT[HashIndex].value,ply);
      Hashtyp:=TT[HashIndex].typage and 3;
      HashDepth:=TT[HashIndex].depth;
      StaticEval:=TT[HashIndex].steval;
      if (not pv) then
        begin
         if (hashdepth>=qDepth) and (HashValue<>-Inf) then
          begin
            if (((hashtyp and HashLower)<>0) and (hashvalue>=beta)) or (((hashtyp and HashUpper)<>0) and (hashvalue<=alpha))  then
              begin
                Result:=HashValue;
                exit;
              end;
          end;
        end;
    end else
    begin
      HashMove:=0;
      HashValue:=-Inf;
      HashTyp:=0;
      StaticEval:=-inf;
    end;

  // Статическая оценка и выход если нас она устраивает
  if Board.CheckersBB=0 then
    begin
      If StaticEval=-inf then
        begin
        if tree[ply].StatKey=Board.Key
          then StaticEval:=tree[ply].StatEval
          else StaticEval:=Evaluate(Board,ThreadId,ply);
        end;
      tree[ply].StatEval:=StaticEval;
      tree[ply].StatKey:=Board.Key;
      bestvalue:=StaticEval;
      // Уточняем оценку хешем
     if (Hashindex>=0) and (HashValue<>-Inf) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<bestvalue) then bestvalue:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>bestvalue) then bestvalue:=HashValue;
       end;
      if bestvalue>alpha then
       begin
        if bestvalue>=beta then
         begin
          if (HashIndex<0) then HashStore(Board.Key,Board,ValueToTT(bestvalue,ply),-5,HashLower,0,StaticEval);
          Result:=bestvalue;
          exit;
         end;
        alpha:=bestvalue;
       end;
      futility:=bestvalue+DeltaMargin;
    end else
    begin
      bestvalue:=-Inf;
      StaticEval:=-inf;
      futility:=-Inf;
      tree[ply].StatEval:=bestvalue;
      tree[ply].StatKey:=Board.Key;
    end;
  // Подготовка к перебору
  quietevasions:=0;
  Bestmove:=0;
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  tree[ply].Status:=TryHashMove;
  searched:=0;
  If Tree[ply-1].CurrMove<>0
    then prevsq:=(tree[ply-1].CurrMove shr 6) and 63
    else prevsq:=-1;
  move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,prevsq);
  while move<>0 do
   begin
    if (isLegal(move,CheckInfo.Pinned,Board))  then
      begin
        inc(searched);
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        isCapture:=(move and CaptureFlag)<>0;
        piese:=Board.Pos[move and 63];
        dest:=(move shr 6) and 63;
        // Futility
        if  (not isCheck) and (futility>-Mate+MaxPly) and (bestvalue>-Mate+Maxply) and ((move and PromoteFlag)=0) and (dest<>prevsq) then
           begin
             If searched>2 then goto l1;
             cappiese:=Board.Pos[dest];
             value:=Futility+PieseFutilityValue[cappiese];
             If (cappiese=0) and ((move and CaptureFlag)<>0) then value:=value+PieseFutilityValue[pawn];
             if value<=alpha then
               begin
                 if value>bestvalue then bestvalue:=value;
                 goto l1;
               end;
             if (futility<=alpha) and (not GoodSee(move,Board,1)) then
               begin
                 if futility>bestvalue then bestvalue:=futility;
                 goto l1;
               end;
           end;
        if  (bestvalue>-Mate+MaxPly) then
          begin
           if (not GoodSee(move,Board,0)) then goto l1;
           if (not isCapture) and (Tree[ply-1].CurrStat^[piese,dest]<0) and (Tree[ply-2].CurrStat^[piese,dest]<0)  then goto l1;
           if (not isCapture) and (Board.CheckersBB<>0) and (quietevasions>1) then goto l1;
          end;
        if (not isCapture) and (Board.CheckersBB<>0) then inc(quietevasions);
        Tree[ply].CurrMove:=move;
        Tree[ply].CurrStat:=@Sortunit.HistorySats[(Board.CheckersBB<>0),isCapture,piese,dest];
        Tree[ply].CurrNum:=searched;
        MakeMove(move,Board,Undo,isCheck);
         //Обновляем аккумуляторы
        UpdAcc16(move,Board,Undo,Threads[ThreadId].Pass[ply],Threads[ThreadId].Pass[ply+1]);
        value:=-FV(ThreadId,-beta,-alpha,depth-1,ply+1,Board,SortUnit,Tree,Line);
        UnMakeMove(move,Board,Undo);
        if value>bestvalue then
          begin
           bestvalue:=value;
           if value>alpha then
             begin
              Bestmove:=move;
              If pv then  AddPv(Bestmove,PVLine,Line);
              If pv and (value<beta) then
                begin
                 alpha:=value;
                end else
                begin
                 HashStore(Board.Key,Board,ValueToTT(value,ply),qDepth,HashLower,move,StaticEval);
                 Result:=value;
                 exit;
                end;
             end;
          end;
      end;
  l1:
     move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,prevsq);
   end;
 // Отслеживаем мат
  if (Board.CheckersBB<>0) and (bestvalue=-Inf)  then
     begin
      result:=-Mate+ply;
      exit;
     end;
  HashStore(Board.Key,Board,valueToTT(bestvalue,ply),qDepth,HashUpper,BestMove,StaticEval);
  Result:=bestvalue;
end;

Function isUnic(Key:int64):boolean;
var
   ind : integer;
begin
  ind:=Key and PosHashMask;
  result:=(PositionHash[ind]<>key);
end;
Procedure FenGenerator(depth:integer;megafens:integer;cpu:integer;book:shortstring;outfilename:shortstring;hashmb:integer;poshashmb:integer);
const
  MaxBookSize=500000;
var
  i,j : integer;
 // t1,t2 : TdateTime;
  f :  textfile;
  s : ansistring;

begin
  // инициализация случайного генератора
  Randomize;
  game.gendepth:=depth;
  game.doIIR:=False;
  game.doLMP:=False;
  game.saveENNPass:=False;
  // Файлы на диске для FEN
  if fileexists(outfilename+'1.dat') then
    begin
      writeln('File already exists - be careful!');
      readln;
    end;
  blockscount:=0;
  // Считываем дебютную книгу если она есть
  if fileexists(book) then
    begin
      usebook:=true;
      SetLength(BookFen,0);
      SetLength(BookFen,MaxBookSize);
      assign(f,book);
      reset(f);
      booksize:=0;
      while not eof(f) do
        begin
          readln(f,s);
          BookFen[booksize]:=s;
          inc(booksize);
          If booksize>=MaxBookSize then break;
        end;
      close(f);
      writeln('Loaded ',booksize,' positions from book');
    end else usebook:=false;
  // инициализация потоков
  for i:=1 to MaxThreads do
    begin
      Threads[i].isRun:=false;
      Threads[i].idle:=true;
      threads[i].bookposnum:=0;
      threads[i].AbortSearch:=false;
    end;

  game.Threads:=cpu;
  FenNumber:=megafens*1000000;

  If game.Threads>1 then
    begin
      StopThreads;
      Init_Threads(game.Threads);
    end;
  SetBoard(StartPositionFen,Threads[1].Board);
  writeln('Create files');
  for i:=1 to cpu do
   begin
    Threads[i].outname:=outfilename+inttostr(i)+'.dat';
    assign(threads[i].outfile,Threads[i].outname);
    if fileexists(Threads[i].outname)
        then append(Threads[i].outfile)
        else rewrite(threads[i].outfile);
   end;
  // и установка хеша
  writeln('Set Zobrist Hash');
  game.hashsize:=hashmb;
  SetHash(game.hashsize);
  writeln('Set Position Hash');
  PosHashSize:=poshashmb*1024*1024;
  PosHashMask:=PosHashSize-1;
  SetLength(PositionHash,0);
  SetLength(PositionHash,PosHashSize+1);
  // инициализируем глобальные переменные для перебора
  game.uciPonder:=false;
  game.time:=48*3600*1000;
  game.rezerv:=48*3600*1000;
  game.oldtime:=game.time;
  game.showtext:=false;
  game.remain:=1000000000;
  game.HashAge:=0;
  // расбрасываем по потокам
  Threads[1].AbortSearch:=false;
  StartTime:=now;
  writeln('Start working...');
  while  not threads[1].AbortSearch  do
   begin
    ClearHAsh;
    // Запускаем вспомогательные потоки
    IF game.Threads>1 then
      begin
        For j:=2 to game.Threads do
          begin
           Threads[j].AbortSearch:=false;
           Threads[j].Fenflag:=true; // переключаем в режим генерирования FEN
           Threads[j].haswork:=true;
          end;
        SetEvent(IdleEvent);
      end;
    // Запускаем основной поток и ждем его завершения
    SingleGenerator(1,threads[1].bookposnum);
    // Ждем когда финишируют все потоки
    If game.Threads>1 then While isThreadIdle do;
    writeln ('circle');
   end;
  writeln('All stopped-bye!');
  for i:=1 to cpu do
     close(Threads[i].outfile);
  StopThreads;
  readln;
end;
Procedure SingleGenerator(ThreadID:integer;var bookposnum:integer);
var
   FENS : TBufferFen;
   cnt : integer;
   s:ansistring;
begin
  // Инициализируем буфер.
  cnt:=0;
  Threads[threadid].savedblock:=false;
  While not Threads[1].AbortSearch do
   begin
    // Устанавливаем новую позицию (начальную или из книги) и генерируем партию, сохраняя позиции FEN.
    If usebook then
      begin
        s:=BookFEN[bookposnum];
        SetBoard(s,Threads[ThreadId].Board);
        inc(bookposnum);
        if bookposnum>=booksize-1 then bookposnum:=0;
      end else SetBoard(StartPositionFen,Threads[ThreadId].Board);
    gamegen(ThreadId,cnt,FENS);
    //writeln(ThreadId,' ',cnt);
    if (Threads[threadid].savedblock)  then break;
   end;
end;
Procedure SafeSave(ThreadId:integer;cnt:integer;var FENS: TBufferFen);
var
 i : integer;
begin
   EnterCriticalSection(SMPLock);
   for i:=0 to cnt-1 do
   writeln(threads[threadid].outfile,FENS[i]);
   inc(blockscount);
   writeln('Saved ',blockscount,' Block (',BuferSize,' positions) after ',(now-StartTime)*86400:6:0,' seconds, ',inttostr(threadid));
   LeaveCriticalSection(SMPLock);
end;
Function SelectRandomMove(ThreadId:integer;depth:integer):integer;
var
   Roulette : array[0..MaxMoves] of integer;
   Undo : TUndo;
   Checkinfo : TcheckInfo;
   i,cdepth,value,val,bestmove,n,num,cnum:integer;
   ischeck : boolean;
   Mlist : TmoveList;
   Line : TPV;
begin
  FillCheckInfo(CheckInfo,Threads[ThreadID].Board);
  SetUndo(Threads[ThreadID].Board,Undo);
  cdepth:=depth-3;
  value:=-Mate-1;
 // printboard(Threads[Threadid].Board);
  For i:=0 to Threads[ThreadID].RootMoves-1 do
    begin
       isCheck:=isMoveCheck(Threads[ThreadID].RootList[i].move,CheckInfo,Threads[ThreadID].Board);
       MakeMove(Threads[ThreadID].RootList[i].move,Threads[ThreadID].Board,Undo,isCheck);
       n:=GenerateLegals(0,Threads[ThreadId].Board,MList);
       Threads[ThreadID].RootList[i].value:=-RootSearch(ThreadId,-Mate,Mate,cdepth,Threads[ThreadID].Board,Threads[ThreadID].Tree,Threads[ThreadID].SortUnit,Mlist,n,Line,bestmove);
       UnMakeMove(Threads[ThreadID].RootList[i].move,Threads[ThreadID].Board,Undo);
       if Threads[ThreadID].RootList[i].value>value then value:=Threads[ThreadID].RootList[i].value;
    end;
  cnum:=0;
  for i:=0 to Threads[ThreadID].RootMoves-1 do
    begin
      val:=abs(value-Threads[ThreadID].RootList[i].value);
      if val>500 then num:=0 else
      if val>250 then num:=1 else
      if val>100 then num:=2 else
      if val>50  then num:=8 else
      if val>25  then num:=16 else
      if val>15  then num:=24
                 else num:=32;
      Roulette[i]:=cnum+num;
     // writeln(i,' ',Decodesq[Threads[ThreadID].RootList[i].move and 63],Decodesq[(Threads[ThreadID].RootList[i].move shr 6) and 63],' ',Threads[ThreadID].RootList[i].value,' Roulette - ',Roulette[i]) ;
      cnum:=cnum+num;
    end;
  num:=Random(cnum);
  i:=0;
  while Roulette[i]<num do
    inc(i);
 // writeln ('Choose ',i,' num-',num);
  Result:=i;
end;
Procedure gamegen(ThreadId:integer;var cnt:integer;var FENS: TBufferFen);
label l1,ex;
const
  RandomMin=4;
  RandomMax=6;
  maxrandomply=20;
  writeminply=10;
  maxply=400;
  MaxEval=1000;
  SafeMargin=250;
var
  n,i,j,ply,value,BestMove,Randomnum,drawcnt,resigncnt,mrandomply,gameres,writeply,SimpleEval,cdepth: integer;
  wp,wn,wb,wr,wq,bp,bn,bb,br,bq,wind,bind:integer;
  keys : array[0..128] of int64;
  randommap : array[0..maxply+1] of boolean;
  Undo : TUndo;
  Checkinfo : TcheckInfo;
  isCheck : boolean;
  s:ansistring;
  GameFen : array[0..maxply] of shortstring;
  gamecnt : integer;
  isQuiet : boolean;
begin
  keys[0]:=Threads[ThreadId].Board.Key;
  ply:=0;
  // Генерим список ходов, которые будут случайные
  for i:=0 to maxply do
    RandomMap[i]:=false;
  RandomNum:=RandomMin+Random(RandomMax-RandomMin+1);
  mrandomply:=-1;
  for i:=1 to RandomNum do
    begin
l1:
      n:=Random(maxrandomply)+1;
      if RandomMap[n] then  goto l1;
      RandomMap[n]:=True;
      if n>mrandomply then mrandomply:=n;
    end;
   writeply:=writeminply;
   if mrandomply>writeply then writeply:=mrandomply;
   // играем партию
  ClearHistory(Threads[THreadId].SortUnit,Threads[THreadId].Tree);
  drawcnt:=0; resigncnt:=0;
  gamecnt:=0;
  while True do
    begin
     ply:=ply+1;  // ply начинается с 1
     SetUndo(Threads[ThreadId].Board,Undo);
     FillCheckInfo(CheckInfo,Threads[ThreadId].Board);
     // Генерируем список ходов из корня позиции
     n:=GenerateLegals(0,Threads[ThreadId].Board,Threads[ThreadId].RootList);
     // Если нет легальных ходов - выход (пат или мат)
     if n=0 then
       begin
        If Threads[ThreadId].Board.CheckersBB<>0 then
          begin
            if Threads[ThreadId].Board.SideToMove=white
              then gameres:=-1
              else gameres:=1;
          end else gameres:=0;
        goto ex;
       end;
     Threads[ThreadId].RootMoves:=n;
     // Смотрим : нужно ли нам делать перебор или берем случайный ход
     if RandomMap[ply] then
       begin
         // Тут просто выбираем случайный ход
         if n=1
           then j:=0
           else j:=SelectRandomMove(ThreadId,game.gendepth);
         BestMove:=Threads[ThreadId].RootList[j].move;
         value:=0;
         drawcnt:=0;
         resigncnt:=0;
       end else
       begin
         // Тут делаем перебор и выбираем лучший ход
         // инициализация нового перебора
         Threads[ThreadId].Board.remain:=game.remain;
         Threads[ThreadID].Board.Nodes:=0;
         Threads[ThreadId].PVLine[0]:=0;
         BestMove:=0;
         SimpleEval:=RootSearch(ThreadId,-mate,mate,2,Threads[ThreadId].Board,Threads[ThreadId].Tree,Threads[ThreadId].Sortunit,Threads[ThreadId].RootList,Threads[ThreadId].RootMoves,Threads[ThreadId].PVLine,BestMove);
         Threads[ThreadId].Board.remain:=game.remain;
         Threads[ThreadID].Board.Nodes:=0;
         Threads[ThreadId].PVLine[0]:=0;
         if ((BestMove and CapPromoFlag)=0) and (Threads[ThreadId].Board.CheckersBB=0) then
           begin
             isQuiet:=True;
             cdepth:=game.gendepth;
           end else
           begin
             isQuiet:=False;
             cdepth:=game.gendepth-3;
           end;
        // Ставим лучший ход из микроперебора на 1 место в списке
         for i:=0 to n-1 do
           if Threads[ThreadId].RootList[i].move=BestMove then
             begin
               Threads[ThreadId].RootList[i].move:=Threads[ThreadId].RootList[0].move;
               Threads[ThreadId].RootList[0].move:=BestMove;
               break;
             end;
         BestMove:=0;
         value:=RootSearch(ThreadId,-mate,mate,cdepth,Threads[ThreadId].Board,Threads[ThreadId].Tree,Threads[ThreadId].Sortunit,Threads[ThreadId].RootList,Threads[ThreadId].RootMoves,Threads[ThreadId].PVLine,BestMove);
         if abs(value)<=1
          then inc(drawcnt);
       end;
     isCheck:=isMoveCheck(Bestmove,CheckInfo,Threads[ThreadId].Board);
     IF Threads[1].AbortSearch then goto ex;
     // Сохраняем FEN если только что рассмотренная позиция удовлетворяет условиям.
     if (ply>writeply) and (not RandomMap[ply]) and isQuiet and (abs(value)<MaxEval) and (abs(value-SimpleEval)<=SafeMargin) and (BestMove<>0) and ((BestMove and CapPromoFlag)=0)  and (Threads[ThreadId].Board.CheckersBB=0)  and (Threads[ThreadId].Board.rule50<80) and (isUnic(Threads[ThreadId].Board.Key)) then
       begin
         PositionHash[Threads[ThreadId].Board.Key and PosHashMask]:=Threads[ThreadId].Board.Key;
         wp:=BitCOunt(Threads[ThreadId].Board.Pieses[pawn] and Threads[ThreadId].Board.Occupancy[white]);
         wn:=BitCOunt(Threads[ThreadId].Board.Pieses[knight] and Threads[ThreadId].Board.Occupancy[white]);
         wb:=BitCOunt(Threads[ThreadId].Board.Pieses[bishop] and Threads[ThreadId].Board.Occupancy[white]);
         wr:=BitCOunt(Threads[ThreadId].Board.Pieses[rook] and Threads[ThreadId].Board.Occupancy[white]);
         wq:=BitCOunt(Threads[ThreadId].Board.Pieses[queen] and Threads[ThreadId].Board.Occupancy[white]);
         bp:=BitCOunt(Threads[ThreadId].Board.Pieses[pawn] and Threads[ThreadId].Board.Occupancy[black]);
         bn:=BitCOunt(Threads[ThreadId].Board.Pieses[knight] and Threads[ThreadId].Board.Occupancy[black]);
         bb:=BitCOunt(Threads[ThreadId].Board.Pieses[bishop] and Threads[ThreadId].Board.Occupancy[black]);
         br:=BitCOunt(Threads[ThreadId].Board.Pieses[rook] and Threads[ThreadId].Board.Occupancy[black]);
         bq:=BitCOunt(Threads[ThreadId].Board.Pieses[queen] and Threads[ThreadId].Board.Occupancy[black]);
         wind:=wp+10*wn+100*wb+1000*wr+10000*wq+100000;
         bind:=bp+10*bn+100*bb+1000*br+10000*bq+100000;
         s:=inttostr(value)+' '+inttostr(Threads[Threadid].Board.KingSq[white])+' '+inttostr(Threads[Threadid].Board.KingSq[black])+' '+inttostr(wind)+' '+inttostr(bind)+' '+PackFen(Threads[ThreadId].Board);
         GameFen[gamecnt]:=s;
         inc(gamecnt);
       end;
     MakeMove(BestMove,Threads[ThreadId].Board,Undo,isCheck);
     keys[Threads[ThreadId].Board.rule50]:=Threads[ThreadId].Board.Key;
     // Определяем момент окончания партии
     if not RandomMap[ply] then
        begin
          //0. Если оценка превышает лимит
          if abs(value)>=MaxEval then
            begin
             inc(resigncnt);
             if resigncnt>3 then
               begin
                // Одна из сторон сдается
                If value>0 then
                  begin
                    If Threads[ThreadId].Board.SideToMove=white  // Ход только что сделан
                      then gameres:=-1
                      else gameres:=1;
                  end else
                  begin
                    If Threads[ThreadId].Board.SideToMove=white  // Ход только что сделан
                      then gameres:=1
                      else gameres:=-1;
                  end;
                goto ex;
               end;
            end;
         //1. присуждение партии исходя из материала на доске в беспешечных эндшпилях
          if (Threads[ThreadId].Board.Pieses[pawn]=0) then
            begin
             // Если недостаточный для мата материал
             if (Threads[ThreadId].Board.NonPawnMat[white]<=BishopValueMid) and (Threads[ThreadId].Board.NonPawnMat[black]<=BishopValueMid) then
                begin
                 gameres:=0;
                 goto ex;
                end;
             if (Threads[ThreadId].Board.NonPawnMat[white]=2*KnightValueMid) and (Threads[ThreadId].Board.NonPawnMat[black]<=BishopValueMid) then
                begin
                 gameres:=0;
                 goto ex;
                end;
             if (Threads[ThreadId].Board.NonPawnMat[black]=2*KnightValueMid) and (Threads[ThreadId].Board.NonPawnMat[white]<=BishopValueMid) then
                begin
                 gameres:=0;
                 goto ex;
                end;
             // В технически выигранных эндшпилях с большим материальным преимуществом
             if (Threads[ThreadId].Board.NonPawnMat[black]<=BishopValueMid) and (Threads[ThreadId].Board.NonPawnMat[white]>=Threads[ThreadId].Board.NonPawnMat[black]+RookValueMid) then
               begin
                 gameres:=1;
                 goto ex;
               end;
             if (Threads[ThreadId].Board.NonPawnMat[white]<=BishopValueMid) and (Threads[ThreadId].Board.NonPawnMat[black]>=Threads[ThreadId].Board.NonPawnMat[white]+RookValueMid) then
               begin
                 gameres:=-1;
                 goto ex;
               end;
            end;
          //2. Если правило 50 ходов
          if Threads[ThreadId].Board.rule50>=100 then
           begin
            gameres:=0;
            goto ex;
           end;
          // 3 Если партия затянулась
          if ply>=maxply then
            begin
             gameres:=100;
             goto ex;
            end;
          // 4 Если случились повторения позиции
          i:=Threads[ThreadId].Board.rule50-2;
          j:=0;
          while i>=0  do
           begin
             if Threads[ThreadId].Board.key=keys[i] then inc(j);
             i:=i-2;
           end;
          if j>1 then
            begin
             if value=0
               then gameres:=0
               else gameres:=100;
             goto ex;
            end;
          // 5 Если последние несколько ходов оба противника показывают ничью
          if drawcnt>5 then
            begin
             gameres:=0;
             goto ex;
            end;
        end;
      end;
ex:  // Мы сыграли партию - тут мы проставляем ее результат всем сохраненным ранее позициям и сохраняем их в буфер.
     for i:=0 to gamecnt-1 do
       begin
         Fens[cnt]:=GameFen[i]+' '+inttostr(gameres);
         inc(cnt);
         // Сохраняем заполнившийся буфер на диск
         if cnt>BuferSize-1 then
           begin
             SafeSave(ThreadId,cnt,Fens);
             cnt:=0;
             Threads[threadid].savedblock:=true;
             if (not Threads[1].AbortSearch) then
               begin
                  // Если уже сохранили нужное количество позиций - посылаем оснвному потоку сигнал закрываться
                 If Blockscount*BuferSize>=FenNumber then Threads[1].AbortSearch:=true;
               end;
              break;
           end;
       end;
end;

Procedure SearchInit;
var
  i,j:integer;
  imp : boolean;
begin
  for i:=0 to 16 do
  for imp:=false to true do
    begin
      If imp
       then StatixValue[imp,i]:=StatixMargin*(i-1)
       else StatixValue[imp,i]:=StatixMargin*i;
      if StatixValue[imp,i]<0 then StatixValue[imp,i]:=0;
      StatixLValue[i]:=StatixMargin*i+FutilityMargin;
      PrunningCount[false,i]:=round((5+i*i) / 2);
      PrunningCount[true,i]:=5+i*i;
    end;
  for i:=1 to 64 do
    reductions[i]:=21*ln(i);

  for i:=1 to Maxply do
  for j:=1 to MaxMoves do
  for imp:=false to true do
    LMRRED[imp,i,j]:=LMRReduction(imp,i,j);
  game.showtext:=true;
end;

initialization
SearchInit;
end.
