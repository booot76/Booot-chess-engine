unit uSort;

interface
uses uBoard,uAttacks,uBitBoards,uMagic;
Const
  HistoryMax=1024*1024;
  MaxKillersPly=127;

  TryHashMove=0;
  GenerateCaptures=1;
  TryGoodCaptures=2;
  GenerateChecks=3;
  TryKiller1=3;
  tryChecks=4;
  TryKiller2=4;
  TryCounterMove=5;
  GenerateOthers=6;
  TryGoodMoves=7;
  TryOthers=8;
  TryBadCaptures=9;
  GenerateEscapes=10;
  tryEscapes=11;

  DepthMargin=80;

Type
  Thistory = array[-King..King,a1..h8] of integer;
  PHistory = ^THistory;
  TSortUnit = record
                History      : THistory;
                CounterMoves : THistory;
                Killers      : array[1..MaxKillersply+2,0..1] of integer;
                HistorySats  : array[-King..King,a1..h8] of THistory;
              end;

var
  MVVLVA: array[-King..King,-King..King] of integer;
  DepthInc : array[0..128] of integer;


Procedure ClearHistory(var SortUnit:TSortUnit;var Tree:Ttree);
Function GetStatBonus(depth:integer):integer;inline;
Procedure FullSort(var MoveList:TMoveList;start:integer;stop:integer);inline;
Function GetHistoryValue(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;inline;
Procedure UpdateList(move:integer;start:integer;stop:integer;var MoveList:TmoveList);
Procedure UpdHistory(var SortUnit:TSortUnit;piese:integer;dest:integer;bonus:integer);inline;
Procedure UPdHistoryStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);inline;
Procedure UpdateStats(var SortUnit:TSortUnit;var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);inline;
Function Next(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var hashmove:integer;var killer1:integer;var killer2:integer;var countermove:integer;ply:integer;prevmove:integer;depth:integer;skip:boolean) :integer;inline;
Function NextFV(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var CheckInfo:TCheckInfo;var hashmove:integer;ply:integer;depth:integer;prevmove:integer ):integer; inline;
Procedure AddToHistory(move:integer;prevmove:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);
Function NextProbCut(var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer):integer; inline;

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
  for i:=1 to MaxKillersPly+2 do
   begin
     SortUnit.Killers[i,0]:=0;
     SortUnit.Killers[i,1]:=0;
   end;
  for i:=-king to king do
  for j:=a1 to h8 do
  for k:=-king to king do
  for l:=a1 to h8 do
    SortUnit.HistorySats[i,j][k,l]:=0;
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
      Tree[i].CurrStat:=@SortUnit.HistorySats[0,a1];
      Tree[i].CurrNum:=0;
      Tree[i].HistVal:=0;
    end;
end;
Function GetStatBonus(depth:integer):integer;inline;
begin
  result:=DepthInc[depth];
end;
Procedure UpdHistory(var SortUnit:TSortUnit;piese:integer;dest:integer;bonus:integer);inline;
begin
  SortUnit.History[piese,dest]:=Sortunit.History[piese,dest]-((Sortunit.History[piese,dest]*abs(bonus)) div 10692);
  SortUnit.History[piese,dest]:=Sortunit.History[piese,dest]+bonus;
end;
Procedure UPdHistoryStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);inline;
begin
  Tree[ply].CurrStat^[piese,dest]:=Tree[ply].CurrStat^[piese,dest]-((Tree[ply].CurrStat^[piese,dest]*abs(bonus)) div 29952);
  Tree[ply].CurrStat^[piese,dest]:=Tree[ply].CurrStat^[piese,dest]+bonus;
end;
Procedure UpdateStats(var SortUnit:TSortUnit;var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);inline;
begin
  If Tree[ply-1].CurrMove<>0 then UpdHistoryStats(Tree,ply-1,piese,dest,bonus);
  If Tree[ply-2].CurrMove<>0 then UpdHistoryStats(Tree,ply-2,piese,dest,bonus);
  If Tree[ply-4].CurrMove<>0 then UpdHistoryStats(Tree,ply-4,piese,dest,bonus);
end;
Function GetHistoryValue(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;inline;
begin
  result:=SortUnit.History[piese,dest]+Tree[ply-1].CurrStat^[piese,dest]+Tree[ply-2].CurrStat^[piese,dest]+Tree[ply-4].CurrStat^[piese,dest];
end;

Procedure AddToHistory(move:integer;prevmove:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);inline;
var
   Piese,dest,i,bonus : integer;
begin
  // Обновляем киллеры
  if (SortUnit.Killers[ply,0]<>move) then
    begin
      SortUnit.Killers[ply,1]:=SortUnit.Killers[ply,0];
      SortUnit.Killers[ply,0]:=move;
    end;
  If Margin>DepthMargin
    then bonus:=GetStatBonus(depth+1)
    else bonus:=GetStatBonus(depth);
  // Увеличиваем историю для успешного хода
  dest:=(move shr 6) and 63;
  Piese:=Board.Pos[move and 63]; // Фигура стоит на поле from
  UpdHistory(SortUnit,piese,dest,bonus);
  UpdateStats(SortUnit,Tree,ply,piese,dest,bonus);
  // Уменьшаем историю для рассмотренных ранее тихих ходов которые не привели к успеху
  for i:=1 to qsearched do
   if OldMoves[i].move<>move then
    begin
      Dest:=(OldMoves[i].move shr 6) and 63;
      Piese:=Board.Pos[OldMoves[i].move and 63];
      UpdHistory(SortUnit,piese,dest,-bonus);
      UpdateStats(SortUnit,Tree,ply,piese,dest,-bonus);
    end;
  // Записываем ход как опровергающий
  if (prevmove<>0) then
    begin
      dest:=(prevmove shr 6) and 63;
      Piese:=Board.Pos[dest];// Фигура уже стоит на поле dest
      SortUnit.CounterMoves[Piese,Dest]:=move;
    end;

end;

Procedure UpdateList(move:integer;start:integer;stop:integer;var MoveList:TmoveList);
var
  i : integer;
begin
  for i:=start to stop do
    if MoveList[i].move=move
      then MoveList[i].value:=HistoryMax
      else MoveList[i].value:=MaxMoves-i;
  FullSort(MoveList,start,stop);
end;
Procedure FullSort(var MoveList:TMoveList;start:integer;stop:integer);inline;
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

Function TakeBest(var MoveList:TmoveList;start:integer;stop:integer):integer;inline;
// Выбираем лучший ход из списка, ставим его на первое место в списке и возвращаем
var
  temp:Tmove;
  value,i,j : integer;
begin
  // Копируем первый элемент массива
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
  // Возвращаем максимальный элемент, стоящий теперь уже на первом месте в списке
  Result:=MoveList[start].move;
end;

Procedure ScoreCaptures(start:integer;stop:integer;var MoveList:TMoveList;var Board:TBoard);inline;
// Оценка взятий - по mvllva
var
  i : integer;
begin
  For i:=start to stop do
    MoveList[i].value:=MVVLVA[Board.Pos[(MoveList[i].move shr 6) and 63],Board.Pos[MoveList[i].move and 63]];
end;
Procedure ScoreMoves(start:integer;stop:integer;ply:integer;var MoveList:TMoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree);inline;
// Оценка простых ходов - по истории
var
  i,piese,dest : integer;
begin
  For i:=start to stop do
    begin
      dest:=(MoveList[i].move shr 6) and 63;
      piese:=Board.Pos[MoveList[i].move and 63];// Фигура еще стоит на месте
      MoveList[i].value:=GetHistoryValue(SortUnit,Tree,ply,piese,dest);
    end;
end;
Procedure ScoreEvasions(start:integer;stop:integer;var Movelist:TMoveList;var History:THistory;var Board:TBoard);inline;
var
  i,seevalue : integer;
begin
  for i:=start to stop do
    begin
      seevalue:=QuickSee(MoveList[i].move,Board);
      if seevalue<0 then MoveList[i].value:=seevalue-HistoryMax else
        if (MoveList[i].move and CaptureFlag)<>0
          then MoveList[i].value:=HistoryMax+MVVLVA[Board.Pos[(MoveList[i].move shr 6) and 63],Board.Pos[MoveList[i].move and 63]]
          else MoveList[i].value:=History[Board.Pos[MoveList[i].move and 63],(MoveList[i].move shr 6) and 63];
    end;
end;
Function Next(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var hashmove:integer;var killer1:integer;var killer2:integer;var countermove:integer;ply:integer;prevmove:integer;depth:integer;skip:boolean) :integer;inline;
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
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board);
       tree[ply].curr:=0;
       tree[ply].badcap:=0;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1);
          inc(tree[ply].curr);
          if move=hashmove then continue;       // Уже рассмотрен
          // Если это хорошее взятие - возвращаем его
          if QuickSee(move,Board)>=0 then
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
      tree[ply].max:=GeneratePseudoMoves(0,(not Board.AllPieses),Board,MoveList);
      tree[ply].curr:=0;
      // Оцениваем тихие ходы
      ScoreMoves(0,tree[ply].max-1,ply,MoveList,SortUnit,Board,Tree);
      tree[ply].value:=1;
    end;
   if tree[ply].Status=TryGoodMoves then
    begin
     // выбираем лучшие тихие ходы (хорошие = с оценкой истории больше 0)
      while (tree[ply].value>-4000*depth) and (not skip) and (tree[ply].curr<=tree[ply].max-1) do
        begin
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1);
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if (move=hashmove) or (move=killer1) or (move=killer2) or (move=countermove) then continue;       // Уже рассмотрены
          Result:=move;
          exit;
        end;
      inc(tree[ply].Status);
    end;
  if tree[ply].Status=tryOthers then
    begin
    // Здесь остались плохие тихие ходы. Сортировка тут только на больших глубинах
      while (tree[ply].curr<=tree[ply].max-1) and (not skip) do
        begin
          move:=MoveList[tree[ply].curr].move;
          inc(tree[ply].curr);
          if (move=hashmove) or (move=killer1) or (move=killer2) or (move=countermove)  then continue;    // Уже рассмотрены
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
      if tree[ply].max>1 then ScoreEvasions(0,tree[ply].max-1,MoveList,SortUnit.History,Board);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryEscapes then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          move:=TakeBest(MoveList,tree[ply].curr,tree[ply].max-1);
          inc(tree[ply].curr);
          if move=hashmove then continue;
          Result:=move;
          exit;
        end;
    end;
  Result:=0;
end;

Function NextFV(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var CheckInfo:TCheckInfo;var hashmove:integer;ply:integer;depth:integer;prevmove:integer ):integer; inline;
var
  move : integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        if Board.CheckersBB<>0 then tree[ply].Status:=GenerateEscapes;
        // Здесь пробуем хешход - пока ничего не генерируем
        If (hashmove<>0) and (isPseudoCorrect(hashmove,Board)) and ((depth>-5) or (((hashmove shr 6) and 63)=((prevmove shr 6) and 63)))   then
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
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board);
       tree[ply].curr:=0;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1);
          inc(tree[ply].curr);
          if move=hashmove then continue;       // Уже рассмотрен
          If (depth<=-5) and (((move shr 6) and 63)<>((prevmove shr 6) and 63)) then continue;
          Result:=move;
          exit;
        end;
      // Если пересмотрели все взятия то идем дальше
      inc(tree[ply].Status);
    end;
  if (tree[ply].Status=GenerateChecks) and (depth>=0) and (Board.CheckersBB=0) then
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
      if tree[ply].max>1 then ScoreEvasions(0,tree[ply].max-1,MoveList,SortUnit.History,Board);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryEscapes then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          move:=TakeBest(MoveList,tree[ply].curr,tree[ply].max-1);
          inc(tree[ply].curr);
          if move=hashmove then continue;
          Result:=move;
          exit;
        end;
    end;
  Result:=0;
end;
Function NextProbCut(var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer):integer; inline;
var
  move : integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        // Здесь пробуем хешход - пока ничего не генерируем
        If (hashmove<>0) and ((hashmove and CaptureFlag)<>0) and (isPseudoCorrect(hashmove,Board)) and (See(hashmove,Board)>=margin) then
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
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board);
       tree[ply].curr:=0;
       // Приступаем к выбору взятий
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // Выбираем лучший ход
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1);
          inc(tree[ply].curr);
          if (move=hashmove)  then continue;       // Уже рассмотрен   или это не взятие
          If See(move,Board)>=margin then
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
  i,j,mvv,lva:integer;
begin
  for i:=-King to King do
    For j:=-King to King do
      begin
        if i<0 then mvv:=SeeValues[-i] else
        if i>0 then mvv:=SeeValues[i] else mvv:=0;
        if j<0 then lva:=SeeValues[-j] else
        if j>0 then lva:=SeeValues[j] else lva:=0;
        MVVLVA[i,j]:=Mvv*16-lva;
      end;
  for i:=0 to 128 do
    if i<16
     then DepthInc[i]:=19*i*i+155*i-134
     else DepthInc[i]:=-8;


end;

initialization
SortInit;

end.
