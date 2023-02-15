unit History;

interface
 uses params,board;
TYPE
    THistory = array[BlackKing..WhiteKing,a1..h8] of integer;
    Tkillers = array[0..MaxPly,1..2] of Tmove;
    Tdepthinc = array[0..MaxPly*FullPly] of integer;
    TSortUnit = record
                  Killer : Tkillers;
                  History: Thistory;
                end;

VAR
    DepthInc : TDepthInc; // Заполняется в Init

Procedure ClearHistory(var SortUnit:TsortUnit);
Procedure AddHistory(var Board:Tboard;var SortUnit:TsortUnit;move:Tmove;ply:integer;depth:integer;Piese:Tpiese;Dest:Tsquare;var BadMovesList:TmoveList);
implementation
   uses move,sort;

Procedure ClearHistory(var SortUnit:TsortUnit);
var
  i,p: integer;
begin
  for i:= 0 to MaxPly*FullPly do
   begin
    SortUnit.Killer[i,1]:=MoveNone;
    SortUnit.Killer[i,2]:=MoveNone;
   end;
 For p:=BlackKing to WhiteKing do
   for i:=a1 to h8 do
     SortUnit.History[p,i]:=0;
end;

Procedure AddHistory(var Board:Tboard;var SortUnit:TsortUnit;move:Tmove;ply:integer;depth:integer;Piese:Tpiese;Dest:Tsquare;var BadMovesList:TmoveList);
var
  p,i,j,ps,ds : integer;
begin
if (move and CapPromoFlag)<>0 then exit;
  SortUnit.History[piese,dest]:=SortUnit.History[piese,dest]+DepthInc[depth];
  if SortUnit.History[piese,dest]>=HistoryMax then
    begin
     for p:=BlackKing to WhiteKing do
       for i:=a1 to h8 do
         SortUnit.History[p,i]:=SortUnit.History[p,i] div 2;
    end;
  if SortUnit.Killer[ply,1]<>move then
    begin
      SortUnit.Killer[ply,2]:=SortUnit.Killer[ply,1];
      SortUnit.Killer[ply,1]:=move;
    end;
for j:=1 to BadMovesList.count do
  if (BadMovesList.Moves[j] and CappromoFlag)=0 then
    begin
      ps:=Board.Pos[BadMovesList.Moves[j] and 63];
      ds:=(BadMovesList.Moves[j] shr 6) and 63;
      SortUnit.History[ps,ds]:=SortUnit.History[ps,ds]-DepthInc[depth];
      if SortUnit.History[ps,ds]<=-HistoryMax then
        begin
         for p:=BlackKing to WhiteKing do
           for i:=a1 to h8 do
             SortUnit.History[p,i]:=SortUnit.History[p,i] div 2;
        end;
    end;

end;

end.
