unit uSearch;

interface
uses uBitBoards,uBoard,uThread,uEval,uSort,uMaterial,uEndgame,uPawn,uAttacks,uMagic,uHash,SysUtils,Windows;

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
              AbortSearch : Boolean;
              remain:integer;
              uciPonder : boolean;
              hashsize : integer;
            end;
Const
  MaxPly=127;
  Mate=32700;
  Infinite=Mate+1;
  Draw=0;
  Stalemate=Draw;

  FullInfo=0;
  OnlyDepth=1;
  TimeStat=2;
  LowerStat=3;

  DeltaMargin=50;
  PieseFutilityValue : array[-Queen..Queen] of integer =(QueenValueEnd,RookValueEnd,BishopValueEnd,KnightValueEnd,PawnValueEnd,0,PawnValueEnd,KnightValueEnd,BishopValueEnd,RookValueEnd,QueenValueEnd);

  RazorMargin=200;
  RazorInc=25;
  RazorDepth=4;

  StatixMargin=80;
  StatixDepth=7;

  CountMoveDepth=16;

  FutilityDepth=7;
  FutilityMargin=100;

  SeeDepth=4;

  SingularDepth=8;

  IIDDepth : array[false..true] of integer = (8,5);

  HistoryDepth=5;


var
  game:TGame;
  RazoringValue,StatixValue : array[0..16] of integer;
  PrunningCount : array[false..true,0..16] of integer;
  LMRREd : array[false..true,false..True,1..MaxPly,1..Maxmoves] of integer;

Procedure Think;
Function RootSearch(alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:ansistring;var BestMove:integer):integer;
Function Search(alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:ansistring;SkipPrunning:boolean;emove:integer;prevmove:integer;cut:boolean):integer;
Function FV(alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:ansistring;prevmove:integer):integer;

implementation
uses uUci;

Procedure PrintFullSearchInfo(iteration : integer;value:integer;pv:ansistring;TimeEnd:Cardinal;typ:integer);
var
 timetot:Cardinal;
 nps : integer;
 s:ansistring;
begin
  timetot:=timeend-game.timestart;
  // Даем статистику с небольшой задержкой, чтобы не перегружать оболочку данными и не терять время
  if TimeTot<500 then exit;
  // Тут выдаем полную информацию о переборе. Когда изменился лучший ход.
  if (typ=FullInfo) then
    begin
     if timetot=0 then nps:=0 else nps:=((Boards[1].Nodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
     if value<-Mate+MaxPly then s:=s+' score mate -'+inttostr(((value+mate) div 2)+1) else
     if value>Mate-MaxPly  then s:=s+' score mate ' +inttostr((mate-value) div 2) else
     s:=s+' score cp '+inttostr(value);
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(Boards[1].Nodes)+' nps '+inttostr(nps);
     s:=s+' pv '+pv;
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
      if timetot=0 then nps:=0 else nps:=((Boards[1].Nodes*1000) div timetot);
      s:='info depth '+inttostr(iteration);
      s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(Boards[1].Nodes)+' nps '+inttostr(nps);
    end else
  if (typ=LowerStat) then
    begin
     if value<-Mate+MaxPly then exit;
     if value>Mate-MaxPly  then exit;
     if timetot=0 then nps:=0 else nps:=((Boards[1].Nodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
     s:=s+' score cp '+inttostr(value);
     s:=s+' lowerbound';
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(Boards[1].Nodes)+' nps '+inttostr(nps);
     s:=s+' pv '+pv;
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
const
  beg : array[false..true] of real=(0.8,0.5);
  dvr : array[false..true] of real=(2.25,3);
  lev=1.5;
 var
  r :real;
begin
  r:=beg[pv]+(ln(depth)*ln(searched))/dvr[pv];
  if r>=lev
    then result:=trunc(r)
    else result:=0;
  if (not pv) and (not imp) and (result>1) then inc(result);
end;

Procedure Think;
// Основная функция , обеспечивающая перебор. Запускается когда оболочка получает команду go и выдает оболочке лучший ход и прочую информацию.
var
  i,n : integer;
  s : ansistring;
  RootList : TMoveList;
  TimeEnd : Cardinal;
  PVLine,smove,opv  : ansistring;
  RootAlpha,RootBeta,Delta,BestValue,BestMove,StableBestMove,Pondermove,v,OldBest: integer;
  NewBoard : TBoard;
begin
  NewSearch;
  PVLine:='';
  // Генерируем список ходов из корня позиции
  n:=GenerateLegals(0,Boards[1],RootList);
 // Если перебор невозможен (мат или пат) то выдаем об этом сообщение оболочке и уходим
  if n=0 then
    begin
      s:='info depth 0 score ';
      if Boards[1].CheckersBB<>0
        then s:=s+inttostr(-mate)
        else s:=s+'0';
      LWrite(s);
      exit;
    end;
  BestValue:=-infinite;
  RootAlpha:=-infinite;
  RootBeta:=infinite;
  Delta:=25;
  StableBestMove:=0; OldBest:=0;PonderMove:=0;
  // Запускаем цикл итераций начиная с 2
  for i:=2 to MaxPly do
    begin
     if i>=5 then
       begin
         Delta:=25;
         RootAlpha:=BestValue-Delta;
         if RootAlpha<-infinite then RootAlpha:=-infinite;
         RootBeta:=BestValue+Delta;
         if RootBeta>infinite then RootBeta:=infinite;
       end;
     While true do
       begin
         BestValue:=RootSearch(RootAlpha,RootBeta,i,Boards[1],Trees[1],SortUnits[1],RootList,n,PVLine,BestMove);
         if BestMove<>0 then
           begin
             StableBestMove:=BestMove;
             // Обновляем Порядок ходов в списке ходов из корня (лучший ход идет на первое место в списке)
             UpdateList(BestMove,0,n-1,RootList);
             CopyBoard(Boards[1],NewBoard);
             PV2Hash(NewBoard,PVLine);
           end;
         if game.AbortSearch then break;
         if BestValue<=RootAlpha then
           begin
             RootBeta:=(RootAlpha+RootBeta) div 2;
             RootAlpha:=BestValue-Delta;
             if RootAlpha<-infinite then RootAlpha:=-infinite;
             // Если оценка просела, то добавляем время на обдумывание
             If game.time<>game.rezerv then game.time:=game.rezerv;
           end else
         if BestValue>=RootBeta then
           begin
             PrintFullSearchInfo(i,BestValue,PVLine,GetTickCount,LowerStat);
             RootAlpha:=(RootAlpha+RootBeta) div 2;
             RootBeta:=BestValue+Delta;
             if RootBeta>infinite then RootBeta:=infinite;
           end else break;
         Delta:=Delta+Delta;
       end;
     // Завершили итерацию - обновляем статистику итерации (перебранные узлы и время)
     TimeEnd:=GetTickCount;
     if game.AbortSearch then break;
     // Пробуем вытащить PonderMove  если это возможно:
     PonderMove:=0;
     If length(pvline)>=9 then
       begin
         opv:=trim(pvline)+' ';
         v := pos(' ',opv);
         delete(opv,1,v); // Убираем первый ход
         v := pos(' ',opv);
         smove:= trim(copy(opv,1,v)); // Это пондер
         If smove<>'' then PonderMove:=StrTomove(smove,Boards[1]);
       end;
     OldBest:=BestValue;
     PrintFullSearchInfo(i,0,' ',TimeEnd,TimeStat);
     // После заверщившейся итерации возвращаем нормальный показатель времени
     game.time:=game.oldtime;
     // Если осталось не так много времени - выходим не начиная новую итерацию
     If (game.time<>game.rezerv) and ((TimeEnd-game.TimeStart)>(0.6*game.time)) then break;
    end;
  // Здесь мы вылетели из перебора. Если вылетели слишком быстро по времени, то печатаем хоть какую-то статистику для отображения:
  If (TimeEnd-game.TimeStart)<500 then
    begin
      TimeEnd:=game.TimeStart+500;
      PrintFullSearchInfo(i,OldBest,PVLine,TimeEnd,FullInfo);
    end;
  // Если в пондеррежиме достигли максимума по глубине - просто "зависаем" и ждем от оболочки команду на выход из пондеррежима
  if (i>=MaxPly-1) and (game.time>=48*3600*1000) and (game.rezerv>=48*3600*1000) and (game.uciPonder) then WaitPonderhit;
  // Печатаем оболочке лучший ход, полученный в процессе перебора ( и пондерход если находимся в соответствующем режиме)
  if StableBestMove=0 then StableBestMove:=RootList[0].move;
  s:=StringMove(StableBestmove);
  if (pondermove<>0) and (game.uciPonder)
        then s := s + ' ponder ' + StringMove(pondermove);
  LWrite('bestmove '+s);
end;
Function RootSearch(alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:ansistring;var BestMove:integer):integer;
var
   CheckInfo : TCheckInfo;
   Undo : TUndo;
   BestValue,j,extension,newdepth,value,R,D:integer;
   TimeEnd:Cardinal;
   isCheck,doresearch:boolean;
   Line:ansistring;
begin
  PVLine:='';
  // Инициализация
  tree[1].Key:=Board.Key;
   // Готовимся к перебору
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  // Печатаем текущую глубину
  TimeEnd:=GetTickCount;
  PrintFullSearchInfo(depth,0,' ',TimeEnd,OnlyDepth);
  BestValue:=-infinite;
  BestMove:=0;
  trees[1][-1].StatEval:=-infinite;
  trees[1][0].StatEval:=-infinite;
  if Boards[1].CheckersBB=0
    then trees[1][1].StatEval:=Evaluate(Boards[1])
    else trees[1][1].StatEval:=-infinite;
  // Крутим цикл ходов из корня
  for j:=0 to n-1 do
       begin
         // статистика о текущем перебираемом ходе
         if ((TimeEnd-game.TimeStart)>2000) then   Lwrite('info currmovenumber '+inttostr(j+1)+' info currmove '+StringMove(RootList[j].move));
         isCheck:=isMoveCheck(RootList[j].move,CheckInfo,Board);
         extension:=0;
         if (isCheck) and (quickSee(RootList[j].move,Board)>=0) then extension:=1;
         newdepth:=depth+extension-1;
         MakeMove(RootList[j].move,Board,Undo,isCheck);
         value:=-infinite;
         if (j=0) then value:=-Search(-Beta,-Alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,false) else
           begin
            doresearch:=true;
             // LMR Reduction
             if (extension=0) and (depth>=3) and (j>0) and (Board.CheckersBB=0) and (not isCheck) and ((RootList[j].move and CapPromoFlag)=0) then
               begin
                R:=LMRRED[true,true,depth,j+1];
                if R>0 then
                  begin
                   D:=newdepth-R;
                   if D<1 then D:=1;
                   value:=-Search(-alpha-1,-alpha,D,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,true);
                   doresearch:=(value>alpha);
                  end;
               end;
             if (doresearch) then value:=-Search(-alpha-1,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,true);
             if (value>alpha) then
              begin
               // Если ход из корня меняется - даем дополнительное время чтобы завершить его оценку
               If game.time<>game.rezerv then game.time:=game.rezerv;
               value:=-Search(-beta,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,false);
              end;
           end;
         UnMakeMove(RootList[j].move,Board,Undo);
         if game.AbortSearch then break;
         if value>BestValue then
          begin
           BestValue:=value;
           if value>alpha then
            begin
             // Сменился лучший ход из корня - печатаем полную статистику
             BestMove:=RootList[j].move;
             // Получаем обновленный основной вариант
             PVLine:=StringMove(RootList[j].move)+' '+Line;
             if value>=beta then break;
             PrintFullSearchInfo(Depth,BestValue,PVLine,GetTickCount,FullInfo);
             alpha:=value;
            end;
          end;
       end;
  Result:=BestValue;
end;

Function Search(alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:ansistring;SkipPrunning:boolean;emove:integer;prevmove:integer;cut:boolean):integer;
label l1;
var
  Undo : TUndo;
  CheckInfo : TCheckInfo;
  MList,OldMoves:TMoveList;
  value,hashmove,hashvalue,hashdepth,hashtyp,move,searched,qsearched,extension,newalpha,newbeta,newdepth,StaticEval,Eval,R,NullValue,D,BestValue,preddepth,BestMove,HistValue: integer;
  isCheck,pv,doresearch,SingularNode,imp: boolean;
  Line : ansiString;
  HashIndex,Key : int64;
begin
  // Листья
  if depth<=0 then
    begin
      Result:=FV(alpha,beta,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
      exit;
    end;
  // Подготовка к перебору
  inc(Board.Nodes);
  dec(Board.remain);
  tree[ply].Key:=Board.Key;
  pv:=beta-alpha>1;
  if Board.remain<=0 then
    begin
      Board.remain:=game.remain;
      poll(game.AbortSearch,Board);
    end;
  If (game.AbortSearch) or (ply>=MaxPly-1) or (isDraw(Board,tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board)
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
  if emove<>0 then Key:=Key xor Zexclude;
  // Hash
  HashIndex:=HashProbe(Board,Key);
  if HashIndex>=0 then
    begin
      Hashmove:=TT[HashIndex].move;
      HashValue:=ValueFromTT(TT[HashIndex].value,ply);
      Hashtyp:=TT[HashIndex].typage and 3;
      HashDepth:=TT[HashIndex].depth;
      if (not pv) then
        begin
         if (hashdepth>=depth) and (HashValue<>-infinite) then
          begin
            if (((hashtyp and HashLower)<>0) and (hashvalue>=beta)) or (((hashtyp and HashUpper)<>0) and (hashvalue<=alpha))  then
              begin
                Result:=HashValue;
                if (hashvalue>=beta) and (hashmove<>0) and ((hashmove and CapPromoFlag)=0) then AddToHistory(Hashmove,prevmove,depth,ply,0,OldMoves,SortUnit,Board);
                exit;
              end;
          end;
        end;
    end else
    begin
      HashMove:=0;
      HashValue:=-infinite;
      HashTyp:=0;
      Hashdepth:=0;
    end;
  SetUndo(Board,Undo);
  // Статическая оценка
  if (Board.CheckersBB=0) then
    begin
     if (prevmove=0) then StaticEval:=-tree[ply-1].StatEval+2*Tempo else
       if (tree[ply].StatKey=Board.Key)
         then StaticEval:=tree[ply].StatEval
         else StaticEval:=Evaluate(Board);
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
     Eval:=StaticEval;
     // Уточняем оценку хешем
     if (HashValue<>-infinite) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<Eval) then Eval:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>Eval) then Eval:=HashValue;
       end;
     if (not SkipPrunning) then
       begin
         // Если мы не под шахом - включаем дополнительные алгоритмы
         // Razoring
         if (not pv) and (depth<RazorDepth) and (HashMove=0) and (Eval+RazoringValue[depth]<=alpha) then
           begin
             if (depth<=1) and (Eval+RazoringValue[3]<=alpha) then
               begin
                 Result:=FV(alpha,beta,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
                 exit;
               end;
             newalpha:=alpha-RazoringValue[depth];
             value:=FV(newalpha,newalpha+1,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
             if value<=newalpha then
               begin
                 Result:=value;
                 exit;
               end;
           end;
         // Statix
         if (depth<StatixDepth) and (Eval-StatixValue[depth]>=beta) and (Board.NonPawnMat[Board.SideToMove]>0) then
           begin
             Result:=Eval-StatixValue[depth];
             exit;
           end;

         // NullMove
        If (not pv) and (depth>1) and (Eval>=beta) and (Board.NonPawnMat[Board.SideToMove]>0) then
           begin
             R:=3+(depth div 4);
             extension:=(Eval-beta) div PawnValueMid;
             if extension>2 then extension:=2;
             R:=R+extension;
             MakeNullMove(Board);
             newdepth:=depth-R;
             NullValue:=-Search(-beta,-beta+1,newdepth,ply+1,Board,Tree,SortUnit,PVLine,true,0,0,(not cut));
             UnMakeNullMove(Board,Undo);
             if NullValue>Mate-MaxPly then NullValue:=beta;
             if (NullValue>=beta) and (newdepth>0) and (depth>=12) then
               begin
                 value:=Search(alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,0,prevmove,false);
                 if (value>=beta) then
                   begin
                     Result:=NullValue;
                     exit;
                   end;
               end else
             if NullValue>=beta then
               begin
                 Result:=NullValue;
                 exit;
               end;
           end;
         // IID
        if (depth>=IIDDepth[pv]) and (hashmove=0) and ((pv) or (StaticEval+StatixMargin>=beta)) then
          begin
            newdepth:=depth-2;
            if (not pv) then newdepth:=newdepth - (depth div 4);
            search(alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,0,prevmove,true);
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
    end else
    begin
     StaticEval:=-infinite;
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
    end;

  pvline:='';
  FillCheckInfo(CheckInfo,Board);
  tree[ply].Status:=TryHashMove;
  BestMove:=0;
  searched:=0;qsearched:=0;
  BestValue:=-infinite;
  SingularNode:=(Depth>=SingularDepth) and (Hashmove<>0) and (abs(HashValue)<Mate-Maxply)  and (emove=0) and ((HashTyp and HashLower)<>0) and (HashDepth>=depth-3);
  imp:=(Tree[ply].StatEval>=tree[ply-2].StatEval) or (tree[ply].StatEval=-infinite) or (tree[ply-2].StatEval=-infinite);
  // Перебор
  move:=Next(MList,Board,SortUnit,tree,hashmove,ply,depth,prevmove);
  While move<>0 do
    begin
     if move=emove then goto l1;
     if islegal(move,CheckInfo.Pinned,Board) then
       begin
        inc(searched);
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        extension:=0;
        if (isCheck) and (quickSee(move,Board)>=0) then extension:=1;
        // Singular
        if (extension=0) and (SingularNode) and (move=hashmove) then
          begin
            newbeta:=hashvalue-2*depth;
            newdepth:=depth div 2;
            value:=Search(newbeta-1,newbeta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,move,prevmove,cut);
            tree[ply].Status:=GenerateCaptures;
            if Board.CheckersBB<>0 then tree[ply].Status:=GenerateEscapes;
            if value<newbeta then extension:=1;
          end;
        newdepth:=depth+extension-1;
        HistValue:=SortUnit.History[Board.Pos[(move and 63)],(move shr 6) and 63] ;
        // Блок селективностей
        if (extension=0) and (Board.CheckersBB=0) and (not isCheck) and ((move and CapPromoFlag)=0) and (bestvalue>-Mate+Maxply) and (not isDangerPawn(move,Board))  then
          begin
            // CountMovePrunning
            if (depth<CountMoveDepth) and (searched>=PrunningCount[imp,depth])  then goto l1;
            // History Prunning
            if (depth<HistoryDepth) and (tree[ply].Status>=GenerateOthers) and (HistValue<0) then goto l1;
            // FutilityPrunning
            preddepth:=newdepth-LMRRED[pv,imp,depth,searched];
            if preddepth<0 then preddepth:=0;
            if preddepth<FutilityDepth then
              begin
                value:=StaticEval+StatixValue[preddepth]+FutilityMargin;
                if value<=alpha then
                  begin
                    if value>bestvalue then bestvalue:=value;
                    goto l1;
                  end;
              end;
            // See LowDepth Prunning
            if (preddepth<SeeDepth) and (QuickSee(move,Board)<0) then goto l1;
          end;
        MakeMove(move,Board,Undo,isCheck);
        value:=-infinite;
        if (pv) and (searched=1) then value:=-Search(-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,false) else
        begin
          doresearch:=true;
          // LMR Reduction
          if (depth>=3) and (searched>1) and (extension=0) and (not isCheck) and ((move and CapPromoFlag)=0) and (Board.CheckersBB=0)  and (tree[ply].Status>=GenerateOthers) then
            begin
              R:=LMRRED[pv,imp,depth,searched];
              if ((not pv) and (cut)) or (HistValue<0) then inc(R);
              if R>0 then
                begin
                 D:=newdepth-R;
                 if D<1 then D:=1;
                 value:=-Search(-alpha-1,-alpha,D,ply+1,Board,Tree,SortUnit,Line,false,0,move,true);
                 doresearch:=(value>alpha);
                end;
            end;
          if doresearch then value:=-Search(-alpha-1,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,(not cut));
          if (pv) and (value>alpha) and (value<beta) then value:=-Search(-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,false);
        end;
        UnMakeMove(move,Board,Undo);
        if game.AbortSearch then break;
        if value>bestvalue then
         begin
          bestvalue:=value;
          if value>alpha then
           begin
            BestMove:=move;
            Pvline:=StringMove(move)+' '+Line;
            if value>=beta then break;
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
    l1:
       move:=Next(MList,Board,SortUnit,tree,hashmove,ply,depth,prevmove);
    end;
  if not game.AbortSearch then
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
     if (BestMove<>0) and ((BestMove and CapPromoFlag)=0) then AddToHistory(Bestmove,prevmove,depth,ply,qsearched,OldMoves,SortUnit,Board);
      // Сохраняем хеш
     if BestValue>=beta then HashStore(Key,Board,ValueToTT(Bestvalue,ply),depth,HashLower,Bestmove) else
     if (pv) and (BestMove<>0)
      then HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashExact,BestMove)
      else HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashUpper,0);
    end else bestvalue:=0;
  Result:=bestvalue;
end;
Function FV(alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:ansistring;prevmove:integer ):integer;
label l1;
var
  value,searched,move,bestvalue,futility: integer;
  CheckInfo:TCheckInfo;
  MList : TMoveList;
  Undo:TUndo;
  isCheck,isPrune : boolean;
  Line:ansistring;
begin
  inc(Board.Nodes);
  dec(Board.remain);
  tree[ply].Key:=Board.Key;
  // Выход ранний если ничья или перебор невозможен
  If (game.AbortSearch) or (ply>=MaxPly-1) or (isDraw(Board,Tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board)
       else result:=0;
     exit;
    end;
  // Статическая оценка и выход если нас она устраивает
  if Board.CheckersBB=0 then
    begin
      if (prevmove=0) then bestvalue:=-tree[ply-1].StatEval+2*Tempo else
        if tree[ply].StatKey=Board.Key
        then bestValue:=tree[ply].StatEval
        else bestvalue:=Evaluate(Board);

      tree[ply].StatEval:=bestvalue;
      tree[ply].StatKey:=Board.Key;
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
      bestvalue:=-infinite;
      futility:=-infinite;
      tree[ply].StatEval:=bestvalue;
      tree[ply].StatKey:=Board.Key;
    end;
  // Подготовка к перебору
  pvline:='';
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  searched:=0;
  tree[ply].Status:=TryHashMove;
  move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,0,ply,depth,prevmove);
  while move<>0 do
   begin
    isPrune:=(Board.CheckersBB<>0) and ((move and CaptureFlag)=0) and (bestvalue>-Mate+MaxPly);
    if ((Board.CheckersBB=0) or (isPrune)) and ((move and PromoteFlag)=0) and (QuickSee(move,Board)<0) then goto l1;
    if (isLegal(move,CheckInfo.Pinned,Board))  then
      begin
         inc(searched);
         isCheck:=isMoveCheck(move,CheckInfo,Board);
         if (Board.CheckersBB=0) and (not isCheck) and (futility>-Mate+MaxPly) and (not isDangerPawn(move,Board)) then
           begin
             value:=Futility+PieseFutilityValue[Board.Pos[(move shr 6) and 63]];
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
         MakeMove(move,Board,Undo,isCheck);
         value:=-FV(-beta,-alpha,depth-1,ply+1,Board,SortUnit,Tree,Line,move);
         UnMakeMove(move,Board,Undo);
         if value>bestvalue then
          begin
           bestvalue:=value;
           if value>alpha then
             begin
              Pvline:=StringMove(move)+' '+Line;
              if value>=beta then
                begin
                 Result:=value;
                 exit;
                end;
              alpha:=value;
             end;
          end;
      end;
  l1:
     move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,0,ply,depth,prevmove);
   end;
 // Отслеживаем мат
  if not game.AbortSearch then
   begin
    if (Board.CheckersBB<>0) and (Searched=0)  then
     begin
      result:=-Mate+ply;
      exit;
     end;
   end else bestvalue:=0;
  Result:=bestvalue;
end;

Procedure SearchInit;
var
  i,j:integer;
  imp : boolean;
begin
  for i:=0 to 16 do
    begin
      RazoringValue[i]:=RazorMargin+RazorInc*i;
      StatixValue[i]:=StatixMargin*i;
      PrunningCount[false,i]:=3+((i*i) div 2);
      PrunningCount[true,i]:=3+(i*i);
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
