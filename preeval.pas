unit preeval;
// Юнит содержит элементарные функции вычисления материала на доске.
interface
uses params,bitboards;
Function CalcMatShort (color :integer):integer;
Function CalcMat:integer;
Function isInsuff(ply : integer):boolean;
implementation

Function CalcMatShort (color :integer):integer;
// Функция вычисляет "короткое количество материала на доске" цвета color.
  begin
   if color=white
      then Result:=minorshort*BitCount(WhiteKnights or WhiteBishops)+rookshort*BitCount(WhiteRooks)+queenshort*BitCount(WhiteQueens)
      else Result:=minorshort*BitCount(BlackKnights or BlackBishops)+rookshort*BitCount(BlackRooks)+queenshort*BitCount(BlackQueens);
  end;

Function CalcMat:integer;
// Функция вычисляет текущее материальное соотношение на доске.
  begin
    Result:=PawnValue*BitCount(WhitePawns)+KnightValue*BitCount(WhiteKnights)+BishopValue*BitCount(WhiteBishops)+RookValue*BitCount(WhiteRooks)+QueenValue*BitCount(WhiteQueens)
          -(PawnValue*BitCount(BlackPawns)+KnightValue*BitCount(BlackKnights)+BishopValue*BitCount(BlackBishops)+RookValue*BitCount(BlackRooks)+QueenValue*BitCount(BlackQueens));
  end;
Function isInsuff(ply : integer):boolean;
var
   res:boolean;
begin
  res:=false;
  if (WhitePawns or BlackPawns)=0 then
     if (tree[ply].Wmat<=minorshort) and (tree[ply].Bmat<=minorshort) and (tree[ply].Wmat+tree[ply].Bmat<>6)
       then res:=true;

result:=res;
end;

end.
