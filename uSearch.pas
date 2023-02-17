unit uSearch;

interface
uses uBitBoards,uBoard,uThread,uEval,uSort,uMaterial,uEndgame,uPawn,uAttacks,uMagic,uHash,SysUtils,Windows,Math;
Type
  Tgame = record
              TimeStart : Cardinal;
              time  : Cardinal;
              rezerv:Cardinal;
              chng  : Cardinal;
              pondertime  : Cardinal;
              ponderrezerv : Cardinal;
              ponderchng   : Cardinal;
              oldtime:cardinal;
              HashAge : integer;
              NodesTotal : cardinal;
              remain:integer;
              uciPonder : boolean;
              hashsize : integer;
              Threads : integer;
              RootDepth : integer;
            end;

Const
  MaxPly=127;
  Mate=32700;
  Inf=Mate+1;
  Draw=0;
  Stalemate=Draw;

  FullInfo=0;
  OnlyDepth=1;
  TimeStat=2;
  LowerStat=3;

  DeltaMargin=50;
  PieseFutilityValue : array[-Queen..Queen] of integer =(QueenValueEnd,RookValueEnd,BishopValueEnd,KnightValueEnd,PawnValueEnd,0,PawnValueEnd,KnightValueEnd,BishopValueEnd,RookValueEnd,QueenValueEnd);

  RazorMargin=200;
  RazorInc=20;
  RazorDepth=3;

  StatixMargin=70;
  StatixMarginimp=50;
  StatixMarginL=80;
  StatixDepth=5;

  ProbCutDepth=5;
  ProbCutRed=4;
  ProbCutMargin=85;
  ProbCutMarginimp=65;

  CountMoveDepth=16;

  FutilityDepth=5;
  FutilityMargin=100;

  SeeDepth=4;

  SingularDepth=8;

  HistoryDepth=3;

  IIDDepth = 8;
  IIDRed=7;

var
  game:TGame;
  RazoringValue,StatixLValue : array[0..16] of integer;
  StatixValue : array[false..True,0..16] of integer;
  PrunningCount : array[false..true,0..16] of integer;
  LMRREd : array[false..true,false..True,1..MaxPly,1..Maxmoves] of integer;

Procedure Think;
Procedure Iterate(ThreadId:integer);
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
Function Search(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;SkipPrunning:boolean;emove:integer;cut:boolean):integer;
Function FV(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV):integer;

implementation
uses uUci;
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
Procedure PrintFullSearchInfo(iteration : integer;value:integer;pv:TPV;TimeEnd:Cardinal;typ:integer);
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
  if TimeTot<250 then exit;
  // Тут выдаем полную информацию о переборе. Когда изменился лучший ход.
  if (typ=FullInfo) then
    begin
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
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
      s:='info depth '+inttostr(iteration);
      Lwrite(s);
    end else
// Выдаем статистику по только что завершившейся итерации
  if (typ=TimeStat) then
    begin
      if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
      s:='info depth '+inttostr(iteration);
      s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
      Lwrite(s);
    end else
  if (typ=LowerStat) then
    begin
     if value<-Mate+MaxPly then exit;
     if value>Mate-MaxPly  then exit;
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
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

Function isDangerPawn(move:integer;var Board:TBoard):boolean;inline;
begin
  if Board.SideToMove=white
   then result:=(Board.Pos[move and 63]=Pawn) and (posy[(move shr 6) and 63]>4)
   else result:=(Board.Pos[move and 63]=-Pawn) and (posy[(move shr 6) and 63]<5);
end;

Function LMRReduction(pv:boolean;imp:boolean;depth:integer;searched:integer):integer;
 var
  r :real;
begin
  if depth>63 then depth:=63;
  if searched>63 then searched:=63;
  r:=ln(depth)*ln(searched)/1.95;
  result:=round(r);
  If pv then
    begin
      Dec(Result);
      if result<0 then result:=0;
    end;
  if (not pv) and (not imp) and (result>1) then inc(result);
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
Const
  SMPLength : array[0..19] of integer=(1,1,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4);
  SMPMask   : array[0..19] of integer=(0,1,0,1,2,3,0,1,2,3,4,5,0,1,2,3,4,5,6,7);
// Крутит цикл итераций (на нужном потоке)
var
  RootAlpha,RootBeta,BestMove,BestValue,Delta,RootDepth,cnt,CurrBestMove : integer;
  TimeEnd : Cardinal;
begin
  BestValue:=-Inf;
  RootAlpha:=-Inf;
  RootBeta:=Inf;
  Delta:=10;
  Threads[ThreadId].StableMove:=0;
  Threads[ThreadId].BestValue:=-Inf;
  RootDepth:=0;BestMove:=0; Threads[ThreadId].OldPvMove:=0;CurrBestMove:=0;
  // Запускаем цикл итераций
  While RootDepth<=MaxPly do
    begin
     // Главный поток просто увеличивает глубину на 1
     inc(RootDepth);
     If threadID<>1 then
       begin
         // Вспомогательные потоки имеют различную глубину перебора пропуская иногда обычный порядок
         cnt:=(ThreadId-1) mod 20;
         If (((RootDepth+SMPMask[cnt]) div SMPLength[cnt]) mod 2) =0 then Continue;
       end;
     if RootDepth>5 then
       begin
         Delta:=10;
         RootAlpha:=BestValue-Delta;
         If RootAlpha<-Inf then RootAlpha:=-Inf;
         RootBeta:=BestValue+Delta;
         if RootBeta>Inf then RootBeta:=Inf;
       end;
     While true do
      begin
       Threads[ThreadId].PVchange:=0;
       BestValue:=RootSearch(ThreadId,RootAlpha,RootBeta,RootDepth,Threads[ThreadId].Board,Threads[ThreadId].Tree,Threads[ThreadId].Sortunit,Threads[ThreadId].RootList,Threads[ThreadID].RootMoves,Threads[ThreadId].PVLine,BestMove);
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
          RootBeta:=(RootAlpha+RootBeta) div 2;
          RootAlpha:=BestValue-Delta;
          if RootAlpha<-Inf then RootAlpha:=-Inf;
          // Если оценка просела, то добавляем время на обдумывание
          If (ThreadId=1) and  (game.time<>game.rezerv) then game.time:=game.rezerv;
        end else
       if BestValue>=RootBeta then
        begin
          If (ThreadID=1) then PrintFullSearchInfo(RootDepth,BestValue,Threads[ThreadId].PVLine,GetTickCount,LowerStat);
          RootBeta:=BestValue+Delta;
          if RootBeta>Inf then RootBeta:=Inf;
        end else break;
       Delta:=Delta+(Delta div 4)+5;
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
       PrintFullSearchInfo(RootDepth,0,Threads[ThreadId].StablePv,TimeEnd,TimeStat);
       // После заверщившейся итерации возвращаем нормальный показатель времени
       If (Threads[ThreadId].PVchange<2) and (Threads[Threadid].OldPvMove=CurrBestMove)
         then game.time:=game.oldtime
         else game.time:=game.chng;
        // Если осталось не так много времени - выходим не начиная новую итерацию
       If (game.time<>game.rezerv) and ((TimeEnd-game.TimeStart)>(0.8*game.time)) then break;
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
  game.RootDepth:=0;
 // Если перебор невозможен (мат или пат) то выдаем об этом сообщение оболочке и уходим
  if n=0 then
    begin
      s:='info depth '+inttoStr(MaxPly)+' score ';
      if Threads[1].Board.CheckersBB<>0
        then s:=s+inttostr(-mate)
        else s:=s+'0';
      LWrite(s);
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
    While not isThreadIdle do;
    // Смотрим: нет ли среди вспомогательных потоков того, кто перебрал на большую глубину или имеет лучшую оценку:
    For j:=2 to game.Threads do
     If (Threads[j].FullDepth>Threads[BestID].FullDepth) or ((Threads[j].FullDepth=Threads[BestID].FullDepth) and (Threads[j].BestValue>Threads[BestId].BestValue)) then BestId:=j;
   end;
  TimeEnd:=GetTickCount;
  // Если вылетели слишком быстро по времени, то печатаем хоть какую-то статистику для отображения:
  If (TimeEnd-game.TimeStart)<200 then
    begin
      TimeEnd:=game.TimeStart+200;
      PrintFullSearchInfo(Threads[BestId].FullDepth,Threads[BestId].BestValue,Threads[BestId].PVLine,TimeEnd,FullInfo);
    end else
  // Если лучший результат достигнут во вспомогательном потоке - выводим информацию об этом
  If BestID<>1 then PrintFullSearchInfo(Threads[BestId].FullDepth,Threads[BestId].BestValue,Threads[BestId].StablePV,TimeEnd,FullInfo);
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
  If Threads[BestId].StableMove<>0 then LWrite('bestmove '+s);
end;
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
var
   CheckInfo : TCheckInfo;
   Undo : TUndo;
   BestValue,j,extension,newdepth,value,R,D,move,qsearched:integer;
   TimeEnd:Cardinal;
   isCheck,doresearch:boolean;
   Line:TPV;
   OldMoves:TMoveList;
begin
  // Инициализация
  PVLine[0]:=0;
  line[0]:=0;
  TimeEnd:=0;
  Tree[1].CurrMove:=0;
  Tree[1].CurrStat:=@SortUnit.HistorySats[0,a1];
  Tree[1].CurrNum:=0;
  Tree[1].HistVal:=0;
  Tree[2].HistVal:=0;
  Tree[3].HistVal:=0;
  qsearched:=0;
  tree[1].Key:=Board.Key;
  Threads[Threadid].nullply:=0;
  Threads[Threadid].nullclr:=-1;
   // Готовимся к перебору
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  // Печатаем текущую глубину
  If (threadId=1) then
    begin
     TimeEnd:=GetTickCount;
     PrintFullSearchInfo(depth,0,PVLine,TimeEnd,OnlyDepth);
    end;
  BestValue:=-Inf;
  BestMove:=0;
  Tree[-1].StatEval:=-Inf;
  Tree[0].StatEval:=-Inf;
  if Board.CheckersBB=0
    then Tree[1].StatEval:=Evaluate(Board,1,-Inf,Inf)
    else Tree[1].StatEval:=-Inf;

  // Крутим цикл ходов из корня
  for j:=0 to n-1 do
       begin
         move:=RootList[j].move;
         // статистика о текущем перебираемом ходе
         if (ThreadID=1) and ((TimeEnd-game.TimeStart)>2000) then   Lwrite('info currmovenumber '+inttostr(j+1)+' info currmove '+StringMove(move));
         isCheck:=isMoveCheck(move,CheckInfo,Board);
         extension:=0;
         if (isCheck) and (quickSee(move,Board)>=0) then extension:=1;
         newdepth:=depth+extension-1;
         MakeMove(move,Board,Undo,isCheck);
         Tree[1].CurrMove:=move;
         Tree[1].CurrNum:=j+1;
         Tree[1].CurrStat:=@Sortunit.HistorySats[Board.Pos[(move shr 6) and 63],(move shr 6) and 63];
         value:=-Inf;
         if (j=0) then value:=-Search(ThreadId,true,-Beta,-Alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,false) else
           begin
            doresearch:=true;
             // LMR Reduction
             if (depth>=3) and (j>0)  and (not isCheck) and ((move and CapPromoFlag)=0) then
               begin
                R:=LMRRED[true,true,depth,j+1];
                if R>0 then
                  begin
                   D:=newdepth-R;
                   if D<1 then D:=1;
                   value:=-Search(ThreadId,false,-alpha-1,-alpha,D,2,Board,Tree,SortUnit,Line,false,0,true);
                   doresearch:=(value>alpha);
                  end;
               end;
             if (doresearch) then value:=-Search(ThreadId,false,-alpha-1,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,true);
             if (value>alpha)   then
              begin
               // Если ход из корня меняется - даем дополнительное время чтобы завершить его оценку
               If (ThreadId=1) and (game.time<>game.rezerv) then game.time:=game.rezerv;
               value:=-Search(ThreadId,true,-beta,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,false);
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
             inc(Threads[ThreadId].PVchange);
             // Сменился лучший ход из корня - печатаем полную статистику
             BestMove:=move;
             // Получаем обновленный основной вариант
             AddPv(Bestmove,PVLine,Line);
             if value>=beta then break;
             If (ThreadId=1) then PrintFullSearchInfo(Depth,BestValue,PVLine,GetTickCount,FullInfo);
             alpha:=value;
            end;
          end;
        // Тихие  ходы сохраняем отдельно
         if  ((move and CapPromoFlag)=0) and (move<>Bestmove) then
           begin
            inc(qsearched);
            OldMoves[qsearched].move:=move;
           end;
       end;
  if not Threads[ThreadId].AbortSearch then
    begin
     // Обновляем историю
     if (BestMove<>0) and ((BestMove and CapPromoFlag)=0) then AddToHistory(Bestmove,0,depth,1,qsearched,OldMoves,SortUnit,Board,Tree,BestValue-beta);
    end else BestValue:=0;
  Result:=BestValue;
end;

Function Search(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;SkipPrunning:boolean;emove:integer;cut:boolean):integer;
label l1;
var
  Undo : TUndo;
  CheckInfo : TCheckInfo;
  MList,OldMoves:TMoveList;
  value,hashmove,hashvalue,hashdepth,hashtyp,move,searched,qsearched,extension,newalpha,newbeta,newdepth,StaticEval,Eval,R,NullValue,D,BestValue,preddepth,BestMove,HistValue,piese,from,dest,rmove,Rhist: integer;
  killer1,killer2,countermove,oldstat,hashm,ProbMar,probcnt : integer;
  isCheck,doresearch,SingularNode,imp,lmp,m1,m2,m4,skip,pvex,hashcap: boolean;
  Line : TPV;
  HashIndex,Key : int64;
begin
  // Листья
  if depth<=0 then
    begin
      Result:=FV(ThreadId,pv,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine);
      exit;
    end;
  // Подготовка к перебору
  inc(Board.Nodes);
  dec(Board.remain);
  Tree[ply].CurrMove:=0;
  Tree[ply].CurrStat:=@SortUnit.HistorySats[0,a1];
  Tree[ply].CurrNum:=0;
  Tree[ply+2].HistVal:=0;
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
       then Result:=Evaluate(Board,ThreadID,alpha,beta)
       else result:=0;
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
  Key:=Board.Key;
  if emove<>0 then Key:=Key xor int64(emove shl 16);
  // Hash
  HashIndex:=HashProbe(Board,Key);
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
                        If ((Hashmove and CapPromoFlag)=0) then AddToHistory(Hashmove,Tree[ply-1].CurrMove,depth,ply,0,OldMoves,SortUnit,Board,Tree,0);
                        If (tree[ply-1].CurrNum=1) and ((Tree[ply-1].CurrMove and CapPromoFlag)=0) then UpdateStats(SortUnit,Tree,ply-1,Board.Pos[(tree[ply-1].CurrMove shr 6) and 63],(tree[ply-1].CurrMove shr 6) and 63,-GetStatBonus(depth+1));
                      end else
                    If ((Hashmove and CapPromoFlag)=0) then
                      begin
                        value:=-GetStatBonus(depth);
                        piese:=Board.Pos[Hashmove and 63];
                        dest:=(Hashmove shr 6) and 63;
                        UpdHistory(SortUnit,piese,dest,value);
                        UpdHistoryStats(Tree,ply,piese,dest,value);
                      end;
                  end;
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
       if (Tree[ply-1].CurrMove=0) then StaticEval:=-tree[ply-1].StatEval+2*Tempo else
       if (tree[ply].StatKey=Board.Key)
         then StaticEval:=tree[ply].StatEval
         else StaticEval:=Evaluate(Board,ThreadID,alpha,beta);
      end;
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
     Eval:=StaticEval;
     // Уточняем оценку хешем
     if (HashIndex>=0) and (HashValue<>-Inf) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<Eval) then Eval:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>Eval) then Eval:=HashValue;
       end;
     imp:=(Tree[ply].StatEval>=tree[ply-2].StatEval);
     if (not SkipPrunning) and (Board.NonPawnMat[Board.SideToMove]>0) then
       begin
         // Если мы не под шахом - включаем дополнительные алгоритмы
         // Razoring
         if (not pv) and (depth<RazorDepth)  and (Eval+RazoringValue[depth]<=alpha) then
           begin
             newalpha:=alpha;
             If depth>=2 then newalpha:=newalpha-RazoringValue[depth];
             value:=FV(ThreadID,false,newalpha,newalpha+1,0,ply,Board,SortUnit,Tree,PVLine);
             if (depth<2) or  (value<=newalpha) then
               begin
                 Result:=value;
                 exit;
               end;
           end;
         // Statix
         if  (depth<StatixDepth) and (Eval-StatixValue[imp,depth]>=beta)  then
           begin
             Result:=Eval;
             exit;
           end;

         // NullMove
        If (not pv) and (Eval>=beta) and (StaticEval>=beta-14*depth+90) and ((ply>=Threads[ThreadId].nullply) or (Threads[Threadid].nullclr<>Board.SideToMove)) then
           begin
             R:=3+(depth div 4);
             extension:=(Eval-beta) div PawnValueMid;
             if extension>2 then extension:=2;
             R:=R+extension;
             MakeNullMove(Board);
             Tree[ply].CurrStat:=@SortUnit.HistorySats[0,a1];
             Tree[ply].CurrMove:=0;
             Tree[ply].CurrNum:=0;
             newdepth:=depth-R;
             If newdepth>0
               then NullValue:=-Search(ThreadId,false,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,PVLine,true,0,(not cut))
               else NullValue:=-FV(ThreadId,false,-beta,-alpha,0,ply+1,Board,SortUnit,Tree,PVLine);
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
                  then value:=Search(ThreadId,false,alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,0,false)
                  else value:=FV(ThreadId,false,alpha,beta,0,ply,Board,Sortunit,Tree,PVLine);
                Threads[ThreadId].nullply:=0;
                Threads[ThreadId].nullclr:=-1;
                If value>=beta then
                  begin
                    Result:=NullValue;
                    exit;
                  end;
               end;
           end;
        // ProbCut
        If (not pv) and (depth>=ProbCutDepth) and (Abs(beta)<Mate-MaxPly) then
          begin
            If imp
              then newbeta:=beta+ProbCutMarginimp
              else newbeta:=beta+ProbCutMargin;
            If newbeta>Mate then newbeta:=Mate;
            newdepth:=depth-ProbCutRed;
            tree[ply].Status:=TryHashMove;
            hashm:=hashmove;
            ProbMar:=NewBeta-StaticEval;
            probcnt:=0;
            move:=NextProbCut(MList,Board,Tree,hashm,ply,ProbMar);
            While (move<>0) and (probcnt<3) do
              begin
                if islegal(move,CheckInfo.Pinned,Board) then
                  begin
                    inc(probcnt);
                    isCheck:=isMoveCheck(move,CheckInfo,Board);
                    MakeMove(move,Board,Undo,isCheck);
                    tree[ply].CurrMove:=move;
                    Tree[ply].CurrStat:=@Sortunit.HistorySats[Board.Pos[(move shr 6) and 63],(move shr 6) and 63];
                    Tree[ply].CurrNum:=0;
                    value:=-Search(ThreadId,false,-newbeta,-newbeta+1,newdepth,ply+1,Board,Tree,SortUnit,PVLine,false,0,(not cut));
                    UnMakeMove(move,Board,Undo);
                    If value>=newbeta then
                      begin
                        Result:=value;
                        exit;
                      end;
                  end;
                move:=NextProbCut(MList,Board,Tree,hashm,ply,ProbMar);
              end;
          end;

         // IID
        if (depth>=IIDDepth) and (hashmove=0)  then
          begin
            newdepth:=depth-IIDRed;
            value:=search(ThreadId,pv,alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,emove,Cut);
            If value<>-Inf then
              begin
               HashIndex:=HashProbe(Board,Key);
               if HashIndex>=0 then
                begin
                 Hashmove:=TT[HashIndex].move;
                 HashValue:=ValueFromTT(TT[HashIndex].value,ply);
                 Hashtyp:=TT[HashIndex].typage and 3;
                 HashDepth:=TT[HashIndex].depth;
                end;
              end;
          end;
       end;
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
  searched:=0;qsearched:=0;
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
  m1:=(tree[ply-1].CurrMove<>0);
  m2:=(tree[ply-2].CurrMove<>0);
  m4:=(tree[ply-4].CurrMove<>0);
  skip:=false;
  hashcap:=false;
  pvex:=pv and (hashtyp=HashExact);
  // Перебор
  move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,countermove,ply,Tree[ply-1].CurrMove,depth,skip);
  While move<>0 do
    begin
     if move=emove then goto l1;
     if islegal(move,CheckInfo.Pinned,Board) then
       begin
        inc(searched);
        lmp:=(depth<CountMoveDepth) and (searched>=PrunningCount[imp,depth]);
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        extension:=0;
        // Singular
        if (SingularNode) and (move=hashmove) then
          begin
            newbeta:=hashvalue-2*depth;
            newdepth:=depth div 2;
            oldstat:=tree[ply].Status;
            value:=Search(ThreadId,false,newbeta-1,newbeta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,move,cut);
            tree[ply].Status:=oldstat;
            if value<newbeta then extension:=1;
          end else
        if (not lmp) and (isCheck) and (quickSee(move,Board)>=0) then extension:=1;
        newdepth:=depth+extension-1;
        from:=move and 63;
        dest:=(move shr 6) and 63;
        piese:=Board.Pos[from]; //  Еще ход на доске не сделан
        // Блок селективностей
        if  (bestvalue>-Mate+Maxply)   and (Board.NonPawnMat[Board.SideToMove]>0)  then
         begin
          If (not isCheck) and ((move and CapPromoFlag)=0) and (not isDangerPawn(move,Board)) then
           begin
            // CountMovePrunning
            if lmp then
             begin
              skip:=true;
              goto l1;
             end;
            preddepth:=newdepth-LMRRED[pv,imp,depth,searched];
            if preddepth<0 then preddepth:=0;
            // HistoryPrunning
            If (preddepth<HistoryDepth)  and ((Tree[ply-1].CurrStat^[piese,dest]<0) or (not m1)) and ((Tree[ply-2].CurrStat^[piese,dest]<0) or (not m2)) and  ((Tree[ply-4].CurrStat^[piese,dest]<0) or (not m4) or (m1 and m2)) then goto l1;
            // FutilityPrunning
            if (preddepth<FutilityDepth) and (Board.CheckersBB=0) then
              begin
                value:=StaticEval+StatixLValue[preddepth];
                if value<=alpha then goto l1;
              end;
            // See LowDepth Prunning
            if (preddepth<SeeDepth) and (QuickSee(move,Board)<0) then goto l1;
           end else
          If (depth<FutilityDepth) and (extension=0) and  (QuickSee(Move,Board)<-PawnValueEnd*depth) then goto l1;
         end;
        If (move=Hashmove) and ((move and CapPromoFlag)<>0) then hashcap:=true;
        MakeMove(move,Board,Undo,isCheck);
        Tree[ply].CurrMove:=move;
        Tree[ply].CurrStat:=@Sortunit.HistorySats[Board.Pos[(move shr 6) and 63],(move shr 6) and 63];
        Tree[ply].CurrNum:=searched;
        value:=-Inf;
        if (pv) and (searched=1) then value:=-Search(ThreadId,true,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,false) else
        begin
          doresearch:=true;
          // LMR Reduction
          if  (depth>=3) and (searched>1) and (((move and CapPromoFlag)=0) or (lmp))  then
            begin
              R:=LMRRED[pv,imp,depth,searched];
              If ((move and CapPromoFlag)<>0) then
                begin
                  If R>0 then dec(R);
                end else
                begin
                 If (tree[ply-1].CurrNum>15) then dec(R);
                 If pvex then dec(R);
                 If hashcap then inc(R);
                 if (cut) then inc(R,2);
                 If (TypOfPiese[piese]<>Pawn) and (TypOfPiese[piese]<>King) then
                  begin
                   rmove:=dest or (from shl 6);
                   If (See(rmove,Board)<0) then dec(R,2);
                  end;
                 HistValue:=GetHistoryValue(SortUnit,Tree,ply,piese,dest)-4000;
                 tree[ply].HistVal:=HistValue;
                 If (HistValue>0) and (tree[ply-1].HistVal<0) then Dec(R);
                 If (HistValue<0) and (tree[ply-1].HistVal>0) then Inc(R);
                 Rhist:=HistValue div 20000;
                 If Rhist<-2 then Rhist:=-2 else
                 If Rhist>2 then RHist:=2;
                 R:=R-Rhist;
                end;
              if R>0 then
                begin
                 D:=newdepth-R;
                 if D<1 then D:=1;
                 value:=-Search(ThreadId,false,-alpha-1,-alpha,D,ply+1,Board,Tree,SortUnit,Line,false,0,true);
                 doresearch:=(value>alpha);
                end;
            end;
          if doresearch then value:=-Search(ThreadId,false,-alpha-1,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,(not cut));
          if (pv) and (value>alpha) and (value<beta) then value:=-Search(ThreadId,true,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,false);
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
              else begin
                     If tree[ply].HistVal<0 then tree[ply].HistVal:=0;
                     break;
                   end;
           end;
         end;
       // Тихие  ходы сохраняем отдельно
         if  ((move and CapPromoFlag)=0) and (move<>Bestmove) then
           begin
            inc(qsearched);
            OldMoves[qsearched].move:=move;
           end;
       end;
    l1:
       move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,countermove,ply,Tree[ply-1].CurrMove,depth,skip);
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
         If ((BestMove and CapPromoFlag)=0) then AddToHistory(Bestmove,Tree[ply-1].CurrMove,depth,ply,qsearched,OldMoves,SortUnit,Board,Tree,BestValue-beta);
         If (tree[ply-1].CurrNum=1) and ((Tree[ply-1].CurrMove and CapPromoFlag)=0) then UpdateStats(SortUnit,Tree,ply-1,Board.Pos[(tree[ply-1].CurrMove shr 6) and 63],(tree[ply-1].CurrMove shr 6) and 63,-GetStatBonus(depth+1));
       end else
     If ((depth>=3) or (pv)) and ((Tree[ply-1].CurrMove)<>0) and  ((Tree[ply-1].CurrMove and CapPromoFlag)=0) then UpdateStats(SortUnit,Tree,ply-1,Board.Pos[(tree[ply-1].CurrMove shr 6) and 63],(tree[ply-1].CurrMove shr 6) and 63,GetStatBonus(depth));
     If emove=0 then
      begin
       // Сохраняем хеш
       if BestValue>=beta then HashStore(Key,Board,ValueToTT(Bestvalue,ply),depth,HashLower,Bestmove,staticEval) else
       if (pv) and (BestMove<>0)
        then HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashExact,BestMove,StaticEval)
        else HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashUpper,BestMove,StaticEval);
      end;
    end else bestvalue:=0;
  Result:=bestvalue;
end;
Function FV(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV):integer;
label l1;
var
  value,move,bestvalue,futility,qDepth,hashmove,hashvalue,hashdepth,hashtyp,oldalpha,bestmove,cappiese,StaticEval,searched: integer;
  HashIndex :int64;
  CheckInfo:TCheckInfo;
  MList : TMoveList;
  Undo:TUndo;
  isCheck,isPrune : boolean;
  Line:TPV;
begin
  inc(Board.Nodes);
  dec(Board.remain);
  tree[ply].Key:=Board.Key;
  Tree[ply].CurrMove:=0;
  If pv then
    begin
      pvline[0]:=0;
      line[0]:=0;
    end;
   oldalpha:=alpha;
  // Выход ранний если ничья или перебор невозможен
  If  (ply>=MaxPly-1) or (isDraw(Board,Tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board,ThreadId,alpha,beta)
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
        if (Tree[ply-1].CurrMove=0) then StaticEval:=-tree[ply-1].StatEval+2*Tempo else
        if tree[ply].StatKey=Board.Key
          then StaticEval:=tree[ply].StatEval
          else StaticEval:=Evaluate(Board,ThreadId,alpha,beta);
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
  Bestmove:=0;
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  tree[ply].Status:=TryHashMove;
  searched:=0;
  move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,Tree[ply-1].CurrMove);
  while move<>0 do
   begin
    isCheck:=isMoveCheck(move,CheckInfo,Board);
    inc(searched);
    // Futility
    if (Board.CheckersBB=0) and (not isCheck) and (futility>-Mate+MaxPly) and (not isDangerPawn(move,Board)) and (Board.NonPawnMat[Board.SideToMove]>0) then
           begin
             cappiese:=Board.Pos[(move shr 6) and 63];
             value:=Futility+PieseFutilityValue[cappiese];
             If (cappiese=0) and ((move and CaptureFlag)<>0) then value:=value+PieseFutilityValue[pawn];
             if value<=alpha then
               begin
                 if value>bestvalue then bestvalue:=value;
                 goto l1;
               end;
             if (futility<=alpha) and (See(move,Board)<=0) then
               begin
                 if futility>bestvalue then bestvalue:=futility;
                 goto l1;
               end;
           end;
    isPrune:=(Board.CheckersBB<>0) and ((depth<>0) or (searched>2)) and ((move and CaptureFlag)=0) and (bestvalue>-Mate+MaxPly);
    if ((Board.CheckersBB=0) or (isPrune)) and ((move and PromoteFlag)=0) and (QuickSee(move,Board)<0) then goto l1;
    if (isLegal(move,CheckInfo.Pinned,Board))  then
      begin
        MakeMove(move,Board,Undo,isCheck);
        Tree[ply].CurrMove:=move;
        value:=-FV(ThreadId,pv,-beta,-alpha,depth-1,ply+1,Board,SortUnit,Tree,Line);
        UnMakeMove(move,Board,Undo);
        if value>bestvalue then
          begin
           bestvalue:=value;
           if value>alpha then
             begin
              If pv then  AddPv(Bestmove,PVLine,Line);
              If pv and (value<beta) then
                begin
                 Bestmove:=move;
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
     move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,Tree[ply-1].CurrMove);
   end;
 // Отслеживаем мат
  if (Board.CheckersBB<>0) and (bestvalue=-Inf)  then
     begin
      result:=-Mate+ply;
      exit;
     end;
  if (pv) and (bestvalue>oldalpha)
      then HashStore(Board.Key,Board,valueToTT(bestvalue,ply),qDepth,HashExact,BestMove,StaticEval)
      else HashStore(Board.Key,Board,valueToTT(bestvalue,ply),qDepth,HashUpper,BestMove,StaticEval);
  Result:=bestvalue;
end;

Procedure SearchInit;
var
  i,j:integer;
  imp : boolean;
begin
  for i:=0 to 16 do
  for imp:=false to true do
    begin
      RazoringValue[i]:=RazorMargin+RazorInc*(i);
      If imp
       then StatixValue[imp,i]:=StatixMarginimp*i
       else StatixValue[imp,i]:=StatixMargin*i;
      StatixLValue[i]:=StatixMarginL*i+FutilityMargin;
      PrunningCount[false,i]:=round(2.4+0.74*power(i,1.78));
      PrunningCount[true,i]:=round(5.0+1.00*power(i,2.00));
    end;
  for i:=1 to Maxply do
  for j:=1 to MaxMoves do
  for imp:=false to true do
    begin
      LMRRED[true,imp,i,j]:=LMRReduction(true,imp,i,j);
      LMRRED[false,imp,i,j]:=LMRReduction(false,imp,i,j);
    end;
end;

initialization
SearchInit;
end.
