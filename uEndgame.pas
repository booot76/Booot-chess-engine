unit uEndgame;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBitBoards,uBoard;

CONST


WeakKingMate :array[a1..h8] of integer =
             (  100, 90, 80, 70, 70, 80, 90, 100, //1
                 90, 70, 60, 50, 50, 60, 70,  90, //2
                 80, 60, 40, 30, 30, 40, 60,  80, //3
                 70, 50, 30, 20, 20, 30, 50,  70, //4
                 70, 50, 30, 20, 20, 30, 50,  70, //5
                 80, 60, 40, 30, 30, 40, 60,  80, //6
                 90, 70, 60, 50, 50, 60, 70,  90, //7
                100, 90, 80, 70, 70, 80, 90, 100);//8

KingDistBonus : array[1..8] of integer = (0,0,50,25,10,5,2,0);

BN_light: array[a1..h8] of integer =
             (  20, 30, 40, 50, 60, 70, 80,100,   //1
                30, 20, 30, 40, 50, 60, 70, 80,   //2
                40, 30, 20, 30, 40, 50, 60, 70,   //3
                50, 40, 30, 20, 30, 40, 50, 60,   //4
                60, 50, 40, 30, 20, 30, 40, 50,   //5
                70, 60, 50, 40, 30, 20, 30, 40,   //6
                80, 70, 60, 50, 40, 30, 20, 30,   //7
               100, 80, 70, 60, 50, 40, 30, 20);  //8
BN_dark: array[a1..h8] of integer =
             ( 100, 80, 70, 60, 50, 40, 30, 20,   //1
                80, 70, 60, 50, 40, 30, 20, 30,   //2
                70, 60, 50, 40, 30, 20, 30, 40,   //3
                60, 50, 40, 30, 20, 30, 40, 50,   //4
                50, 40, 30, 20, 30, 40, 50, 60,   //5
                40, 30, 20, 30, 40, 50, 60, 70,   //6
                30, 20, 30, 40, 50, 60, 70, 80,   //7
                20, 30, 40, 50, 60, 70, 80,100);  //8

F_MatDraw=1;
F_KBNK=2;
F_KBPsKW=3;
F_KBPsKB=4;
F_KPK=5;
F_Pawnless=6;


ScaleNormal=64;
ScaleDraw=0;

NearlyWin=2500;


Function SpecialCases(var Board:TBoard):integer;
Function EvaluateSpecialEndgame(funcnum:integer;var Board :TBoard):integer;
Procedure KBPSKw(var WScale:integer;var Board:TBoard);
Procedure KBPSKb(var BScale:integer;var Board:TBoard);

implementation
 uses uKPK;


Function KPK(var Board:TBoard):integer;
var
  wk,bk,paw,color,res:integer;
// Оцениваем по битовым таблицам
begin
  if (Board.Occupancy[white] and Board.Pieses[pawn])<>0 then
    begin
      WK:=Board.KingSq[white];
      BK:=Board.KingSq[black];
      paw:=BitScanForward(Board.Pieses[pawn]);
      color:=Board.SideToMove;
    end else
    begin
      WK:=VertReflectSQ[Board.KingSq[black]];
      BK:=VertReflectSQ[Board.KingSq[white]];
      paw:=VertReflectSq[BitScanForward(Board.Pieses[pawn])];
      color:=Board.SideToMove xor 1;
    end;
  if numpawn[paw]>23 then
    begin
      paw:=HorReflectSQ[paw];
      WK:=HorReflectSQ[WK];
      BK:=HorReflectSQ[BK];
    end;
  res:=KPKProbe(color,paw,wk,bk);
  if res=0 then result:=0 else
  if res>0 then result:=KPKWin-res*5
           else result:=-KPKwin+res*5;
end;
Function PawnLess(var Board:TBoard):integer;
//  Оценка беспешечных эндшпилей.
var
   score,bonus,extra:integer;
begin
  extra:=0;
  score:=Board.NonPawnMat[white]-Board.NonPawnMat[black];
  if score>TypOfPiese[Bishop] then extra:=NearlyWin else
  if score<-TypOfPiese[Bishop] then extra:=-NearlyWin;
  if score>MinorDif  then bonus:=WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]] else
  if score<-MinorDif then bonus:=-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]] else
                          bonus:=WeakKingMate[Board.KingSq[black]]-WeakKingMate[Board.KingSq[white]];
  // Если недостаточно преимущества - оценка ближе к ничейной.
  if abs(score)<=PieseTypValue[bishop] then
    begin
     score:=(score+bonus) div 4;
     if (Board.NonPawnMat[white]<=TypOfPiese[Rook]) and (Board.NonPawnMat[black]<=TypOfPiese[Rook]) then score:=score div 2;
    end
    else score:=score+bonus+extra;
  if Board.SideToMove=black then score:=-score;
  result:=score;
end;


Function KBNK(var Board:TBoard):integer;
// Мат слоном и конем используется специальную оценочную функцию подсказывающую в какой угол надо гнать одинокого короля
var
  score:integer;
begin
  score:=PieseTypValue[bishop]+PieseTypValue[knight]+NearlyWin;
  if (Board.NonPawnMat[black]=0)  then    // Белые ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score+2*BN_Dark[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score+2*BN_Light[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Белопольный слон
      if Board.SideToMove=black then result:=-result;
    end                           else   // Черные ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score-2*BN_Dark[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score-2*BN_Light[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Белопольный слон
       if Board.SideToMove=white then result:=-result;
    end;
end;


Procedure KBPSKw(var WScale:integer;var Board:TBoard);
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[black];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a8,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Wscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h8,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Wscale:=ScaleDraw;
end;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[white];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a1,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Bscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h1,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Bscale:=ScaleDraw;
end;


Function SpecialCases(var Board:TBoard):integer;
// Быстрая оценка материала и специальных случаев на доске
var
  NPW,NPB,evalfun: integer;
  wp,bp: integer;
begin
  evalfun:=0;
  wp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[white]);
  bp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[black]);
  NPW:=Board.NonPawnMat[white];
  NPB:=Board.NonPawnMat[black];
  // Ищем возможные внешние функции оценки и масштабирования
  if wp+bp=0 then  // беспешечные эндшпили
    begin
     evalfun:=F_PawnLess;
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[bishop]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[bishop]))) then evalfun:=f_kbnk else   //KBNK
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[knight]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[knight]))) then evalfun:=f_MatDraw else   //KNNK
     If (Board.NonPawnMat[white]<PieseTypValue[rook]) and (Board.NonPawnMat[black]<PieseTypValue[rook]) then evalfun:=f_MatDraw;
    end;
  if (NPW=0) and (NPB=0) then // Пешечный эндшпиль
    begin
     if (wp+bp)=1 then evalfun:=f_KPK ;
    end;
  if (NPW=PieseTypValue[bishop])  and (wp>0) then evalfun:=F_KBPSKW;
  if (NPB=PieseTypValue[bishop])  and (bp>0) then evalfun:=F_KBPSKB;
  Result:=evalfun;
end;

Function EvaluateSpecialEndgame(funcnum:integer;var Board :TBoard):integer;
// Функция входная
begin
  result:=0;
  if FuncNum=F_KBNK then result:=KBNK(Board) else
  if Funcnum=f_KPK then result:=KPK(Board) else
  if FuncNum=F_PawnLess then result:=PawnLess(Board) else
  if FuncNum=F_MatDraw then  result:=0;

end;


end.
