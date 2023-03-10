unit uSort;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBoard,uAttacks,uBitBoards;
Const
  MaxKillersPly=127;
  HistDiv=15000;
  StatsDiv=30000;
  CapDiv = 10000;
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
  Thistory = array[-King..King,a1..h8] of integer;
  PHistory = ^THistory;
  TSortUnit = record
                History      : THistory;
                CounterMoves : THistory;
                Killers      : array[1..MaxKillersply+2,0..1] of integer;
                HistorySats  : array[false..true,false..true,-King..King,a1..h8] of THistory;
                CapHistory   : array[-king..King,a1..h8,Empty..King] of integer
              end;

var
  DepthInc : array[0..128] of integer;

Procedure ClearHistory(var SortUnit:TSortUnit;var Tree:Ttree);
Function GetStatBonus(depth:integer):integer;inline;
Procedure FullSort(var MoveList:TMoveList;start:integer;stop:integer);
Function GetHistoryValue(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
Function GetStatsValue(var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
Procedure UpdateList(move:integer;start:integer;stop:integer;var MoveList:TmoveList);
Procedure UpdHistory(var SortUnit:TSortUnit;piese:integer;dest:integer;bonus:integer);
Procedure UPdHistoryStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);
Procedure UpdateStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);
Function Next(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var hashmove:integer;var killer1:integer;var killer2:integer;var countermove:integer;ply:integer;depth:integer;skip:boolean) :integer;
Function NextFV(var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit;var tree:TTree;var CheckInfo:TCheckInfo;var hashmove:integer;ply:integer;depth:integer;prevsq:integer ):integer;
Function NextProbCut(var SortUnit:TSortUnit;var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer;depth:integer):integer;
Procedure UpdateQuietHistory(move:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;bonus:integer);
Procedure UpdateFullHistory(move:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;capsearched:integer;var OldCaptures:Tmovelist;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);

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
Procedure UpdHistory(var SortUnit:TSortUnit;piese:integer;dest:integer;bonus:integer);
begin
  SortUnit.History[piese,dest]:=Sortunit.History[piese,dest]-((Sortunit.History[piese,dest]*abs(bonus)) div HistDiv);  //-HistDiv .. HistDiv
  SortUnit.History[piese,dest]:=Sortunit.History[piese,dest]+bonus;
end;
Procedure UPdHistoryStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);
begin
  Tree[ply].CurrStat^[piese,dest]:=Tree[ply].CurrStat^[piese,dest]-((Tree[ply].CurrStat^[piese,dest]*abs(bonus)) div StatsDiv); // -StatsDiv .. StatsDiv
  Tree[ply].CurrStat^[piese,dest]:=Tree[ply].CurrStat^[piese,dest]+bonus;
end;
Procedure UpdCapHistory(var SortUnit:TSortUnit;piese:integer;dest:integer;captured:integer;bonus:integer);
begin
  SortUnit.CapHistory[piese,dest,captured]:=Sortunit.CapHistory[piese,dest,captured]-((Sortunit.CapHistory[piese,dest,captured]*abs(bonus)) div CapDiv);  //-CapDiv .. CapDiv
  SortUnit.CapHistory[piese,dest,captured]:=Sortunit.CapHistory[piese,dest,captured]+bonus;
end;
Procedure UpdateStats(var Tree:TTree;ply:integer;piese:integer;dest:integer;bonus:integer);
begin
  If (ply>1) and  (Tree[ply-1].CurrMove<>0) then UpdHistoryStats(Tree,ply-1,piese,dest,bonus);
  If (ply>2) and  (Tree[ply-2].CurrMove<>0) then UpdHistoryStats(Tree,ply-2,piese,dest,bonus);
  If (ply>4) and  (Tree[ply-4].CurrMove<>0) then UpdHistoryStats(Tree,ply-4,piese,dest,bonus);
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
Function GetQuietScore(var Sortunit:TSortUnit;var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
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
Function GetStatsValue(var Tree:Ttree;ply:integer;piese:integer;dest:integer):integer;
var
  res : integer;
begin
  res:=0;
  if (ply>1) and  (Tree[ply-1].CurrMove<>0) then res:=res+Tree[ply-1].CurrStat^[piese,dest];
  if (ply>2) and  (Tree[ply-2].CurrMove<>0) then res:=res+Tree[ply-2].CurrStat^[piese,dest];
  if (ply>4) and  (Tree[ply-4].CurrMove<>0) then res:=res+Tree[ply-4].CurrStat^[piese,dest];
  Result:=res;
end;
Procedure UpdateQuietHistory(move:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;bonus:integer);
var
   Piese,dest,i : integer;
begin
  // ?????????????????? ??????????????
  if (SortUnit.Killers[ply,0]<>move) then
    begin
      SortUnit.Killers[ply,1]:=SortUnit.Killers[ply,0];
      SortUnit.Killers[ply,0]:=move;
    end;
  // ?????????????????????? ?????????????? ?????? ?????????????????? ????????
  dest:=(move shr 6) and 63;
  Piese:=Board.Pos[move and 63]; // ???????????? ?????????? ???? ???????? from
  UpdHistory(SortUnit,piese,dest,bonus);
  UpdateStats(Tree,ply,piese,dest,bonus);
  // ?????????????????? ?????????????? ?????? ?????????????????????????? ?????????? ?????????? ?????????? ?????????????? ???? ?????????????? ?? ????????????
  for i:=1 to qsearched do
   if OldMoves[i].move<>move then
    begin
      Dest:=(OldMoves[i].move shr 6) and 63;
      Piese:=Board.Pos[OldMoves[i].move and 63];
      UpdHistory(SortUnit,piese,dest,-bonus);
      UpdateStats(Tree,ply,piese,dest,-bonus);
    end;
  // ???????????????????? ?????? ?????? ??????????????????????????
  if (Tree[ply-1].CurrMove<>0) then
    begin
      dest:=(Tree[ply-1].CurrMove shr 6) and 63;
      Piese:=Board.Pos[dest];// ???????????? ?????? ?????????? ???? ???????? dest
      SortUnit.CounterMoves[Piese,Dest]:=move;
    end;
end;
Procedure UpdateFullHistory(move:integer;depth:integer;ply:integer;qsearched:integer;var OldMoves:TmoveList;capsearched:integer;var OldCaptures:Tmovelist;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree;margin:integer);
var
   Piese,dest,i,bonus,captured : integer;
begin
  If Margin>=DepthMargin
    then bonus:=GetStatBonus(depth+1)
    else bonus:=GetStatBonus(depth);
  if (move and CaptureFlag)<>0 then
    begin
      Dest:=(move shr 6) and 63;
      Piese:=Board.Pos[move and 63];
      captured:=TypOfPiese[Board.Pos[dest]];
      UpdCapHistory(SortUnit,piese,dest,captured,bonus);
    end else UpdateQuietHistory(move,ply,qsearched,OldMoves,SortUnit,Board,Tree,bonus);
  // ?????????????????? ?????????????? ?????? ?????????????????????????? ?????????? ???????????? ?????????????? ???? ?????????????? ?? ????????????
  for i:=1 to capsearched do
   if OldCaptures[i].move<>move then
    begin
      Dest:=(OldCaptures[i].move shr 6) and 63;
      Piese:=Board.Pos[OldCaptures[i].move and 63];
      Captured:=TypOfPiese[Board.Pos[dest]];
      UpdCapHistory(SortUnit,piese,dest,captured,-bonus);
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
// ???????????????????? ????????????
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
// ???????????????? ???????????? ?????? ???? ????????????, ???????????? ?????? ???? ???????????? ?????????? ?? ???????????? ?? ????????????????????
var
  temp:Tmove;
  value,i,j : integer;
begin
  // ???????????????? ???????????? ?????????????? ??????????????
  if doSort then
  begin
   temp:=MoveList[start];
   value:=temp.value;
   j:=start;
   // ???????? ???????????????????????? ?????????????? ?? ????????????, ?????????????? ???? ??????????????
   For i:=start+1 to stop do
    if MoveList[i].value>value then
      begin
        value:=MoveList[i].value;
        j:=i;
      end;
   // ???????? ???????????? ?????????????? ?? ???????????? ???? ???????????????? ??????????????????????, ???? ???????????? ?????????????? ???????????? ?????????????? ?? ?????????????????? ????????????????????????
   if j<>start then
    begin
      MoveList[start]:=MoveList[j];
      MoveList[j]:=temp;
    end;
  end;
  // ???????????????????? ???????????????????????? ??????????????, ?????????????? ???????????? ?????? ???? ???????????? ?????????? ?? ????????????
  Result:=MoveList[start].move;
end;

Procedure ScoreCaptures(start:integer;stop:integer;var MoveList:TMoveList;var Board:TBoard;var SortUnit:TSortUnit);
// ???????????? ???????????? - ???? mvllva
var
  i,piese,dest,captured : integer;
begin
  For i:=start to stop do
   begin
    dest:=(MoveList[i].move shr 6) and 63;
    piese:=Board.Pos[MoveList[i].move and 63]; // from
    captured:=TypOfPiese[Board.Pos[dest]]; // dest
    MoveList[i].value:=6*MVV[captured]+SortUnit.CapHistory[piese,dest,captured];
   end;
end;
Procedure ScoreMoves(start:integer;stop:integer;ply:integer;var MoveList:TMoveList;var SortUnit:TSortUnit;var Board:TBoard;var Tree:Ttree);
// ???????????? ?????????????? ?????????? - ???? ??????????????
var
  i,piese,dest : integer;
begin
  For i:=start to stop do
    begin
      dest:=(MoveList[i].move shr 6) and 63;
      piese:=Board.Pos[MoveList[i].move and 63];// from
      MoveList[i].value:=GetQuietScore(SortUnit,Tree,ply,piese,dest);
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
      if (MoveList[i].move and CaptureFlag)<>0
          then MoveList[i].value:=MVV[captured]-TypOfPiese[piese]
          else MoveList[i].value:=GetEscapeScore(SortUnit,Tree,ply,piese,dest) - (1 shl 24);
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
        // ?????????? ?????????????? ???????????? - ???????? ???????????? ???? ????????????????????
        If (hashmove<>0) and (isPseudoCorrect(hashmove,Board)) then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // ???????? ?????????????? ?????? ?????? ???????????????????????? ???? ?????????? ?????????????????? ???? ?????????????????? ???????????? - ?????????????? ???????????? ?? ??????????????????????
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // ???????????????????? ???????????? ?? ??????????????????????
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // ?????????????????? ?????????????????????????????? ???????????? ?? ??????????????????????
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].badcap:=0;
       tree[ply].value:=1 shl 24;
       // ???????????????????? ?? ???????????? ????????????
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // ???????????????? ???????????? ??????
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,(tree[ply].value>=-3000*depth));
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // ?????? ????????????????????
          // ???????? ?????? ?????????????? ???????????? - ???????????????????? ??????
          if GoodSee(move,Board,0) then
            begin
             Result:=move;
             exit;
            end;
          // ???????? ?????? ???????????? ???????????? - ???????????????????? ?????? ?? ?????????? ???????????? ?????????? - ?????????????????? ??????????.
          inc(tree[ply].badcap);
          MoveList[MaxMoves-tree[ply].badcap].move:=move;
        end;
      // ???????? ???????????????????????? ?????? ???????????? ???? ???????? ????????????
      inc(tree[ply].Status);
    end;
  if tree[ply].Status=TryKiller1 then
    begin
      // ???????????? ???????????? - ???? ?????????????????????????? ??????????
      inc(tree[ply].Status);
      if (killer1<>0) and (killer1<>hashmove) and (Board.Pos[(killer1 shr 6) and 63]=0) and (isPseudoCorrect(killer1,Board)) then
        begin
          Result:=killer1;
          exit;
        end else killer1:=0;
    end;
  if tree[ply].Status=TryKiller2 then
    begin
      // ???????????? ???????????? - ???? ?????????????????????????? ??????????
      inc(tree[ply].Status);
      if (killer2<>0) and (killer2<>hashmove) and (killer2<>killer1) and (Board.Pos[(killer2 shr 6) and 63]=0) and (isPseudoCorrect(killer2,Board)) then
        begin
          Result:=killer2;
          exit;
        end else killer2:=0;
    end;
  if tree[ply].Status=TryCounterMove then
    begin
      // ??????????????  ??????????????????????????  - ???? ?????????????????????????? ??????????
      inc(tree[ply].Status);
      if (countermove<>0) and (countermove<>hashmove) and (countermove<>killer1) and  (countermove<>killer2) and (Board.Pos[(countermove shr 6) and 63]=0) and (isPseudoCorrect(countermove,Board)) then
            begin
              result:=countermove;
              exit;
            end else countermove:=0;
    end;
  if tree[ply].Status=GenerateOthers  then
    begin
      // ???????????????????? ?????????? ????????
      inc(tree[ply].Status);
      if (not skip) then
        begin
         tree[ply].max:=GeneratePseudoMoves(0,(not Board.AllPieses),Board,MoveList);
         tree[ply].curr:=0;
         // ?????????????????? ?????????? ????????
         ScoreMoves(0,tree[ply].max-1,ply,MoveList,SortUnit,Board,Tree);
         tree[ply].value:=1 shl 24;
        end;
    end;
   if tree[ply].Status=tryOthers then
    begin
     // ???????????????? ???????????? ?????????? ???????? (?????????????? = ?? ?????????????? ?????????????? ???????????? 0)
      while  (not skip) and (tree[ply].curr<=tree[ply].max-1) do
        begin
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,(tree[ply].value>=-3000*depth));
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if (move=hashmove) or (move=killer1) or (move=killer2) or (move=countermove) then continue;       // ?????? ??????????????????????
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
        // ?????????? ?????????????? ???????????? - ???????? ???????????? ???? ????????????????????
        If (hashmove<>0) and (isPseudoCorrect(hashmove,Board)) and ( (Board.CheckersBB<>0) or (depth>-5) or (((hashmove shr 6) and 63)=prevsq))   then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // ???????? ?????????????? ?????? ?????? ???????????????????????? ???? ?????????? ?????????????????? ???? ?????????????????? ???????????? - ?????????????? ???????????? ?? ??????????????????????
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // ???????????????????? ???????????? ?? ??????????????????????
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // ?????????????????? ?????????????????????????????? ???????????? ?? ??????????????????????
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].value:=1 shl 24;
       // ???????????????????? ?? ???????????? ????????????
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // ???????????????? ???????????? ??????
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,(tree[ply].value>=-3000*depth));
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // ?????? ????????????????????
          If (depth<=-5) and (((move shr 6) and 63)<>prevsq) then continue;
          Result:=move;
          exit;
        end;
      // ???????? ???????????????????????? ?????? ???????????? ???? ???????? ????????????
      inc(tree[ply].Status);
    end;
  if (tree[ply].Status=GenerateChecks) and (depth>=0) and (Board.CheckersBB=0) then
    begin
      inc(tree[ply].Status);
      // ???????????????????? ?????????? ????????
      tree[ply].max:=GeneratePseudoChecks(0,not Board.AllPieses,Board,CheckInfo,MoveList);
      tree[ply].curr:=0;
    end;
  if tree[ply].Status=tryChecks then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // ???????????????? ???????????? ??????
          move:=MoveList[tree[ply].curr].move;
          inc(tree[ply].curr);
          if move=hashmove then continue;       // ?????? ????????????????????
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
Function NextProbCut(var SortUnit:TSortUnit;var MoveList:TMoveList;var Board:TBoard;var tree:TTree;var hashmove:integer;ply:integer;margin:integer;depth:integer):integer;
var
  move : integer;
begin
   if tree[ply].Status=TryHashMove then
      begin
        inc(tree[ply].Status);
        // ?????????? ?????????????? ???????????? - ???????? ???????????? ???? ????????????????????
        If (hashmove<>0) and ((Board.Pos[(hashmove shr 6) and 63])<>Empty) and (isPseudoCorrect(hashmove,Board)) and (GoodSee(hashmove,Board,margin)) then
         begin
          Result:=hashmove;
          exit;
         end else hashmove:=0;
       // ???????? ?????????????? ?????? ?????? ???????????????????????? ???? ?????????? ?????????????????? ???? ?????????????????? ???????????? - ?????????????? ???????????? ?? ??????????????????????
      end;
   if tree[ply].Status=GenerateCaptures then
     begin
       inc(tree[ply].Status);
       // ???????????????????? ???????????? ?? ??????????????????????
       tree[ply].max:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,MoveList);
       // ?????????????????? ?????????????????????????????? ???????????? ?? ??????????????????????
       ScoreCaptures(0,tree[ply].max-1,MoveList,Board,SortUnit);
       tree[ply].curr:=0;
       tree[ply].value:= 1 shl 24;
       // ???????????????????? ?? ???????????? ????????????
     end;
  if tree[ply].Status=TryGoodCaptures then
    begin
      while tree[ply].curr<=tree[ply].max-1 do
        begin
          // ???????????????? ???????????? ??????
          move:=TakeBest(MOveList,tree[ply].curr,tree[ply].max-1,(tree[ply].value>=-3000*depth));
          tree[ply].value:=MoveList[tree[ply].curr].value;
          inc(tree[ply].curr);
          if (move=hashmove) or ((move and CaptureFlag)=0)  then continue;       // ?????? ????????????????????   ?????? ?????? ???? ????????????
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
