unit uSort;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBoard,uAttacks,uBitBoards;
Const
  MaxKillersPly=127;
  LowHistMax=4;

  HistDiv=16384;
  StatsDiv=32768;

  CorrDiv=512;
  CorrLimit=CorrDiv div 4;
  CorrSize=32768;

  ThreatValue=8192;

  TryHashMove=0;
  GenerateCaptures=1;
  TryGoodCaptures=2;
  GenerateChecks=3;
  TryKiller1=3;
  tryChecks=4;
  TryKiller2=4;
  TryCounterMove=5;
  GenerateOthers=6;
  TryOthers=7;
  TryBadCaptures=8;
  GenerateEscapes=10;
  tryEscapes=11;

  DepthMargin=80;

  MVV: array[Empty..King] of integer = (0,100,300,300,500,900,0);
Type
  TCorrHist = array[white..black,0..CorrSize-1] of smallint;
  PHistory  = ^THistory;
  TSortUnit = record
                History         : THistory;
                CounterMoves    : THistory;
                Killers         : array[1..MaxKillersply+2,0..1] of integer;
                HistorySats     : array[false..true,false..true,-King..King,a1..h8] of THistory;
                CapHistory      : array[-king..King,a1..h8,Empty..King] of smallint;
                PawnCorrHist    : TcorrHist;
                WNonPawnCorrHist: TcorrHist;
                BNonPawnCorrHist: TcorrHist;
              end;

var
  DepthInc : array[0..128] of integer;

Procedure ClearHistory(var SortUnit:TSortUnit;var Tree:Ttree);
Function GetStatBonus(depth:integer):integer;inline;
Procedure FullSort(var MoveList:TMoveList;start:integer;stop:integer);
Function GetHistoryValue(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
Procedure UpdateList(move:integer;start:integer;stop:integer;var MoveList:TmoveList);
Procedure UpdateStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;value:integer);
Function Next(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var hashmove:integer;var killer1:integer;var killer2:integer;var countermove:integer;ply:integer;depth:integer;skip:boolean) :integer;
Function NextFV(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var CheckInfo:TCheckInfo;var hashmove:integer;ply:integer;depth:integer;prevsq:integer ):integer;
Function NextProbCut(var SortUnit:TSortUnit;var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer):integer;
Procedure UpdateFullHistory(move:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;capsearched:integer;var OldCaptures:Tmovelist;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);
Procedure UpdateQuietMoveHistory(move:integer;ply:integer;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;value:integer);
Procedure UpdateKillersCounter(var SortUnit:TSortUnit;var Board:Tboard;var Tree:TTree;move:integer;ply:integer);
Procedure CellGravity(Cell:Psmallint;value,Range:integer);

implementation
Procedure ClearHistory(var SortUnit:TSortUnit;var Tree:Ttree);
var
  i,j,k,l : integer;
begin
  for i:=-king to king do
  for j:=a1 to h8 do
   begin
     SortUnit.History[i,j]:=0;
     SortUnit.CounterMoves[i,j]:=0;
   end;
  for i:=white to black do
  for j:=0 to CorrSize-1 do
    begin
      SortUnit.PawnCorrHist[i,j]:=0;
      SortUnit.WNonPawnCorrHist[i,j]:=0;
      SortUnit.BNonPawnCorrHist[i,j]:=0;
    end;

  for i:=1 to MaxKillersPly+2 do
   begin
     SortUnit.Killers[i,0]:=0;
     SortUnit.Killers[i,1]:=0;
   end;
  for i:=-king to king do
  for j:=a1 to h8 do
  for k:=-king to king do
  for l:=a1 to h8 do
   begin
    SortUnit.HistorySats[false,false,i,j][k,l]:=0;
    SortUnit.HistorySats[false,true,i,j][k,l]:=0;
    SortUnit.HistorySats[true,false,i,j][k,l]:=0;
    SortUnit.HistorySats[true,true,i,j][k,l]:=0;
   end;

  for i:=-king to king do
  for j:=a1 to h8 do
  for k:=empty to king do
    SortUnit.CapHistory[i,j,k]:=0;

  For i:=-4 to 129 do
    begin
      Tree[i].Status:=0;
      Tree[i].max:=0;
      Tree[i].curr:=0;
      Tree[i].badcap:=0;
      Tree[i].value:=0;
      Tree[i].key:=0;
      Tree[i].StatEval:=0;
      Tree[i].StatKey:=0;
      Tree[i].CurrMove:=0;
      Tree[i].CurrStat:=@SortUnit.HistorySats[false,false,0,a1];
      Tree[i].CurrNum:=0;
    end;
end;
Function GetStatBonus(depth:integer):integer;inline;
begin
  result:=DepthInc[depth];
end;
Procedure CellGravity(Cell:Psmallint;value,Range:integer);
begin
  Cell^:=Cell^+value-((Cell^*abs(value)) div Range);
end;

Procedure UpdateStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;value:integer);
begin
  If (ply>1) and  (Tree[ply-1].CurrMove<>0) then CellGravity(@Tree[ply-1].CurrStat^[piese,dest],value,StatsDiv);
  If (ply>2) and  (Tree[ply-2].CurrMove<>0) then CellGravity(@Tree[ply-2].CurrStat^[piese,dest],value,StatsDiv);
  If (ply>4) and  (Tree[ply-4].CurrMove<>0) then CellGravity(@Tree[ply-4].CurrStat^[piese,dest],value,StatsDiv);
end;
Function GetHistoryValue(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
var
  res : integer;
begin
  res:=2*SortUnit.History[piese,dest];
  if (ply>1) and  (Tree[ply-1].CurrMove<>0) then res:=res+Tree[ply-1].CurrStat^[piese,dest];
  if (ply>2) and  (Tree[ply-2].CurrMove<>0) then res:=res+Tree[ply-2].CurrStat^[piese,dest];
  if (ply>4) and  (Tree[ply-4].CurrMove<>0) then res:=res+Tree[ply-4].CurrStat^[piese,dest];
  Result:=res;
end;
Function GetQuietScore(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;move:integer;piese:integer;dest:integer):integer;
var
  res : integer;
begin
  res:=SortUnit.History[piese,dest];
  if (ply>1) and  (Tree[ply-1].CurrMove<>0) then res:=res+2*Tree[ply-1].CurrStat^[piese,dest];
  if (ply>2) and  (Tree[ply-2].CurrMove<>0) then res:=res+Tree[ply-2].CurrStat^[piese,dest];
  if (ply>4) and  (Tree[ply-4].CurrMove<>0) then res:=res+Tree[ply-4].CurrStat^[piese,dest];
  Result:=res;
end;
Function GetEscapeScore(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
var
  res : integer;
begin
  res:=SortUnit.History[piese,dest];
  if (ply>1) and  (Tree[ply-1].CurrMove<>0) then res:=res+2*Tree[ply-1].CurrStat^[piese,dest];
  Result:=res;
end;
Procedure UpdateKillersCounter(var SortUnit:TSortUnit;var Board:Tboard;var Tree:TTree;move:integer;ply:integer);
var
  piese,dest :integer;
begin
  // Обновляем киллеры
  if (SortUnit.Killers[ply,0]<>move) then
       begin
        SortUnit.Killers[ply,1]:=SortUnit.Killers[ply,0];
        SortUnit.Killers[ply,0]:=move;
       end;
      // Записываем ход как опровергающий
  if (Tree[ply-1].CurrMove<>0) then
       begin
        dest:=(Tree[ply-1].CurrMove shr 6) and 63;
        Piese:=Board.Pos[dest];// Фигура уже стоит на поле dest
        SortUnit.CounterMoves[Piese,Dest]:=move;
       end;
end;
Procedure UpdateQuietMoveHistory(move:integer;ply:integer;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;value:integer);
var
   Piese,dest : integer;
begin
  dest:=(move shr 6) and 63;
  Piese:=Board.Pos[move and 63]; // Фигура стоит на поле from
  CellGravity(@SortUnit.History[piese,dest],value,HistDiv);
  UpdateStats(Tree,ply,piese,dest,value);
end;

Procedure UpdateFullHistory(move:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;capsearched:integer;var OldCaptures:Tmovelist;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);
var
   Piese,dest,i,bonus,captured : integer;
begin
  If Margin>=DepthMargin      // 6 elo
    then bonus:=GetStatBonus(depth+1)
    else bonus:=GetStatBonus(depth);
  if (move and CaptureFlag)<>0 then
    begin
      Dest:=(move shr 6) and 63;
      Piese:=Board.Pos[move and 63];
      captured:=TypOfPiese[Board.Pos[dest]];
      CellGravity(@SortUnit.CapHistory[piese,dest,captured],bonus,HistDiv)
    end else
    begin
     UpdateKillersCounter(SortUnit,Board,Tree,move,ply);
     if ((qsearched>1) or (depth>4)) then UpdateQuietMoveHistory(move,ply,SortUnit,Board,Tree,bonus);
     // Уменьшаем историю для рассмотренных ранее тихих ходов которые не привели к успеху
       for i:=1 to qsearched do
        if OldMoves[i].move<>move then UpdateQuietMoveHistory(OldMoves[i].move,ply,SortUnit,Board,Tree,-bonus);
    end;
  // Уменьшаем историю для рассмотренных ранее взятий которые не привели к успеху
  for i:=1 to capsearched do
   if OldCaptures[i].move<>move then
    begin
      Dest:=(OldCaptures[i].move shr 6) and 63;
      Piese:=Board.Pos[OldCaptures[i].move and 63];
      Captured:=TypOfPiese[Board.Pos[dest]];
      CellGravity(@SortUnit.CapHistory[piese,dest,captured],-bonus,HistDiv)
    end;
end;
Procedure UpdateList(move:integer;start:integer;stop:integer;var MoveList:TmoveList);
var
  i : integer;
begin
  for i:=start to stop do
    if MoveList[i].move=move
      then MoveList[i].value:=MaxMoves+1
      else MoveList[i].value:=MaxMoves-i;
  FullSort(MoveList,start,stop);
end;
Procedure FullSort(var MoveList:TMoveList;start:integer;stop:integer);
// Сортировка полная
var
   i,j: integer;
   temp : tmove;
begin
  for i:=start+1 to stop do
    begin
      temp:=MoveList[i];
      j:=i-1;
      while (j>=start) and (MoveList[j].value<temp.value) do
        begin
          MoveList[j+1]:=MoveList[j];
          dec(j)
        end;
      MoveList[j+1]:=temp;
    end;
end;

Function TakeBest(var MoveList:TmoveList;start:integer;stop:integer;doSort:boolean):integer;
// Выбираем лучший ход из списка, ставим его на первое место в списке и возвращаем
var
  temp:Tmove;
  value,i,j : integer;
begin
  // Копируем первый элемент массива
  if doSort then
  begin
   temp:=MoveList[start];
   value:=temp.value;
   j:=start;
   // ищем максимальный элемент в списке, начиная со второго
   For i:=start+1 to stop do
    if MoveList[i].value>value then
      begin
        value:=MoveList[i].value;
        j:=i;
      end;
   // Если первый элемент в списке не оказался максималным, то меняем местами первый элемент и найденный максимальный
   if j<>start then
    begin
      MoveList[start]:=MoveList[j];
      MoveList[j]:=temp;
    end;
  end;
  // Возвращаем максимальный элемент, стоящий теперь уже на первом месте в списке
  Result:=MoveList[start].move;
end;

Procedure ScoreCaptures(start:integer;stop:integer;var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit);
// Оценка взятий - по mvllva
var
  i,piese,dest,captured : integer;
begin
  For i:=start to stop do
   begin
    dest:=(MoveList[i].move shr 6) and 63;
    piese:=Board.Pos[MoveList[i].move and 63]; // from
    captured:=TypOfPiese[Board.Pos[dest]]; // dest
    if (captured=Empty) and ((MoveList[i].move and CaptureFlag)<>0) then captured:=Pawn;
    MoveList[i].value:=MVV[captured]+(SortUnit.CapHistory[piese,dest,captured] div 16);
   end;
end;
Procedure ScoreMoves(start:integer;stop:integer;ply:integer;var MoveList:TMoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree);
// Оценка простых ходов - по истории
var
  i,piese,from,dest,sq : integer;
  PawnAttacks,MinorAttacks,RookAttacks,Temp,Threat : int64;
begin
  if Board.SideToMove=black
    then PawnAttacks:=(((Board.Pieses[pawn] and Board.Occupancy[white]) and (not FilesBB[1])) shl 7) or (((Board.Pieses[pawn] and Board.Occupancy[white]) and (not FilesBB[8])) shl 9)
    else PawnAttacks:=(((Board.Pieses[pawn] and Board.Occupancy[black]) and (not FilesBB[1])) shr 9) or (((Board.Pieses[pawn] and Board.Occupancy[black]) and (not FilesBB[8])) shr 7);
  MinorAttacks:=PawnAttacks;
  temp:=Board.Pieses[knight] and Board.Occupancy[Board.SideToMove xor 1];
  while temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      MinorAttacks:=MinorAttacks or KnightAttacks[sq];
      Temp:=Temp and (Temp-1);
    end;
  temp:=Board.Pieses[bishop] and Board.Occupancy[Board.SideToMove xor 1];
  while temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      MinorAttacks:=MinorAttacks or BishopAttacksBB(sq,Board.AllPieses);
      Temp:=Temp and (Temp-1);
    end;
  RookAttacks:=MinorAttacks;
  temp:=Board.Pieses[rook] and Board.Occupancy[Board.SideToMove xor 1];
  while temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      RookAttacks:=RookAttacks or RookAttacksBB(sq,Board.AllPieses);
      Temp:=Temp and (Temp-1);
    end;
  For i:=start to stop do
    begin
      from:=MoveList[i].move and 63;
      dest:=(MoveList[i].move shr 6) and 63;
      piese:=Board.Pos[MoveList[i].move and 63];// from
      MoveList[i].value:=GetQuietScore(SortUnit,Tree,ply,MoveList[i].move,piese,dest);
      if (TypOfPiese[piese]<>Pawn) and (TypOfPiese[piese]<>King) then
        begin
          if TypOfPiese[piese]=Knight then Threat:=PawnAttacks else
          if TypOfPiese[piese]=Bishop then Threat:=PawnAttacks else
          if TypOfPiese[piese]=Rook   then Threat:=MinorAttacks else
          if TypOfPiese[piese]=Queen  then Threat:=RookAttacks else Threat:=0;
          if (Only[from] and Threat)<>0 then MoveList[i].value:=MoveList[i].value+ThreatValue;
          if (Only[dest] and Threat)<>0 then MoveList[i].value:=MoveList[i].value-ThreatValue;
        end;

    end;
end;
Procedure ScoreEvasions(start:integer;stop:integer;ply:integer;var Movelist:TMoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:TTree);
var
  i,piese,dest,captured : integer;
begin
  for i:=start to stop do
    begin
      dest:=(MoveList[i].move shr 6) and 63;
      piese:=Board.Pos[MoveList[i].move and 63];//from
      captured:=TypOfPiese[Board.Pos[dest]]; // dest
      if (captured=0) and ((MoveList[i].move and CaptureFlag)<>0) then captured:=Pawn;

      if (MoveList[i].move and CaptureFlag)<>0
          then MoveList[i].value:= 10000000 + MVV[captured]
          else MoveList[i].value:=GetEscapeScore(SortUnit,Tree,ply,piese,dest);
    end;
end;
Function Next(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var hashmove:integer;var killer1:integer;var killer2:integer;var countermove:integer;ply:integer;depth:integer;skip:boolean) :integer;
var
  move: integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        if Board.CheckersBB<>0 then tree[ply].Status:=GenerateEscapes;
        // Здесь пробуем хешход - пока ничего не генерируем
        If (hashmove<>0) and (isPseudoCorrect(hashmove,Board)) then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // Если хешхода нет или некорректный то сразу переходим на следующую стадию - генерим взятия и превращения
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // Генерируем взятия и превращения
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // Оцениваем сгенерированные взятия и превращения
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].badcap:=0;
       tree[ply].value:=1 shl 24;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,true);
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // Уже рассмотрен
          // Если это хорошее взятие - возвращаем его
          if GoodSee(move,Board,0) then
            begin
             Result:=move;
             exit;
            end;
          // Если это плохое взятие - записываем его в конец списка ходов - расмотрим позже.
          inc(tree[ply].badcap);
          MoveList[MaxMoves-tree[ply].badcap].move:=move;
        end;
      // Если пересмотрели все взятия то идем дальше
      inc(tree[ply].Status);
    end;
  if tree[ply].Status=TryKiller1 then
    begin
      // Первый Киллер - до генерирования ходов
      inc(tree[ply].Status);
      if (killer1<>0) and (killer1<>hashmove) and (Board.Pos[(killer1 shr 6) and 63]=0) and (isPseudoCorrect(killer1,Board)) then
        begin
          Result:=killer1;
          exit;
        end else killer1:=0;
    end;
  if tree[ply].Status=TryKiller2 then
    begin
      // Второй Киллер - до генерирования ходов
      inc(tree[ply].Status);
      if (killer2<>0) and (killer2<>hashmove) and (killer2<>killer1) and (Board.Pos[(killer2 shr 6) and 63]=0) and (isPseudoCorrect(killer2,Board)) then
        begin
          Result:=killer2;
          exit;
        end else killer2:=0;
    end;
  if tree[ply].Status=TryCounterMove then
    begin
      // Смотрим  опровергающий  - до генерирования ходов
      inc(tree[ply].Status);
      if (countermove<>0) and (countermove<>hashmove) and (countermove<>killer1) and  (countermove<>killer2) and (Board.Pos[(countermove shr 6) and 63]=0) and (isPseudoCorrect(countermove,Board)) then
            begin
              result:=countermove;
              exit;
            end else countermove:=0;
    end;
  if tree[ply].Status=GenerateOthers  then
    begin
      // Генерируем тихие ходы
      inc(tree[ply].Status);
      if (not skip) then
        begin
         tree[ply].max:=GeneratePseudoMoves(0,(not Board.AllPieses),Board,MoveList);
         tree[ply].curr:=0;
         // Оцениваем тихие ходы
         ScoreMoves(0,tree[ply].max-1,ply,MoveList,SortUnit,Board,Tree);
         tree[ply].value:=1 shl 24;
        end;
    end;
   if tree[ply].Status=tryOthers then
    begin
     // выбираем лучшие тихие ходы
      while  (not skip) and (tree[ply].curr<=tree[ply].max-1) do
        begin
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,true);
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if (move=hashmove) or (move=killer1) or (move=killer2) or (move=countermove) then continue;       // Уже рассмотрены
          Result:=move;
          exit;
        end;
      inc(tree[ply].Status);
    end;

  if tree[ply].Status=tryBadCaptures then
    begin
      while tree[ply].badcap>0 do
        begin
          Result:=MoveList[MaxMoves-tree[ply].badcap].move;
          dec(tree[ply].badcap);
          exit;
        end;
    end;

  if tree[ply].Status=GenerateEscapes then
    begin
      inc(tree[ply].Status);
      tree[ply].max:= GeneratePseudoEscapes(0,Board,MoveList);
      if tree[ply].max>1 then ScoreEvasions(0,tree[ply].max-1,ply,MoveList,SortUnit,Board,Tree);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryEscapes then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          move:=TakeBest(MoveList,tree[ply].curr,tree[ply].max-1,true);
          inc(tree[ply].curr);
          if move=hashmove then continue;
          Result:=move;
          exit;
        end;
    end;
  Result:=0;
end;

Function NextFV(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var CheckInfo:TCheckInfo;var hashmove:integer;ply:integer;depth:integer;prevsq:integer ):integer;
var
  move : integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        if Board.CheckersBB<>0 then tree[ply].Status:=GenerateEscapes;
        // Здесь пробуем хешход - пока ничего не генерируем
        If (hashmove<>0) and (isPseudoCorrect(hashmove,Board))   then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // Если хешхода нет или некорректный то сразу переходим на следующую стадию - генерим взятия и превращения
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // Генерируем взятия и превращения
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // Оцениваем сгенерированные взятия и превращения
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].value:=1 shl 24;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,true);
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // Уже рассмотрен
          If (depth<=-5) and (((move shr 6) and 63)<>prevsq) then continue;
          Result:=move;
          exit;
        end;
      // Если пересмотрели все взятия то идем дальше
      inc(tree[ply].Status);
    end;
  if (tree[ply].Status=GenerateChecks) and (depth>=0) and (Board.CheckersBB=0) then     // (+)
    begin
      inc(tree[ply].Status);
      // Генерируем тихие шахи
      tree[ply].max:=GeneratePseudoChecks(0,not Board.AllPieses,Board,CheckInfo,MoveList);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryChecks then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=MoveList[tree[ply].curr].move;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // Уже рассмотрен
          Result:=move;
          exit;
        end;
      inc(tree[ply].Status);
    end;

  if tree[ply].Status=GenerateEscapes then
    begin
      inc(tree[ply].Status);
      tree[ply].max:= GeneratePseudoEscapes(0,Board,MoveList);
      if tree[ply].max>1 then ScoreEvasions(0,tree[ply].max-1,ply,MoveList,SortUnit,Board,Tree);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryEscapes then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          move:=TakeBest(MoveList,tree[ply].curr,tree[ply].max-1,true);
          inc(tree[ply].curr);
          if move=hashmove then continue;
          Result:=move;
          exit;
        end;
    end;
  Result:=0;
end;
Function NextProbCut(var SortUnit:TSortUnit;var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer):integer;
var
  move : integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        // Здесь пробуем хешход - пока ничего не генерируем
        If (hashmove<>0) and ((Board.Pos[(hashmove shr 6) and 63])<>Empty) and (isPseudoCorrect(hashmove,Board)) and (GoodSee(hashmove,Board,margin)) then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // Если хешхода нет или некорректный то сразу переходим на следующую стадию - генерим взятия и превращения
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // Генерируем взятия и превращения
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // Оцениваем сгенерированные взятия и превращения
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].value:= 1 shl 24;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,true);
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if (move=hashmove) or ((move and CaptureFlag)=0)  then continue;       // Уже рассмотрен   или это не взятие
          If GoodSee(move,Board,margin) then
            begin
             Result:=move;
             exit;
            end;
        end;
    end;
  Result:=0;
end;
Procedure SortInit;
var
  i,score:integer;
begin
 for i:=0 to 128 do
    begin
      score:=(9*i+270)*i-310;
      if score<0 then score:=0;
      if score>2150 then score:=2150;
      DepthInc[i]:=score;
    end;
end;

initialization
SortInit;

end.
