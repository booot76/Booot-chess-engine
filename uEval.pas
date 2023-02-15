unit uEval;

interface
uses uBoard,uBitBoards,uMaterial,uPawn,uSort,umagic,uAttacks,uEndgame;

Type
  TAttacks = array[white..black,all..King] of TBitBoard;
  Tcolor = array[white..black] of integer;
  TColorZone = array[white..black] of TBitBoard;
  TEvalEntry = record
                  Key : int64;
                  value : smallint;
                end;
Const
  PawnPstMid : array[a1..h8] of integer =(
    0, 0, 0, 0, 0, 0, 0, 0,   //1
   -9,-2, 0, 3, 3, 0,-2,-9,   //2
   -9,-2, 2,10,10, 2,-2,-9,   //3
   -9,-2, 4,16,16, 4,-2,-9,   //4
   -9,-2, 2,10,10, 2,-2,-9,   //5
   -9,-2, 0, 3, 3, 0,-2,-9,   //6
   -9,-2, 0, 3, 3, 0,-2,-9,   //7
    0, 0, 0, 0, 0, 0, 0, 0    //8
   );

  KnightPstMid : array[a1..h8] of integer =(

  -55,-40,-30,-25,-25,-30,-40,-55, //1
  -35,-20,-10, -5, -5,-10,-20,-35, //2
  -30,-10,  0,  5,  5,  0,-10,-30, //3
  -10,  5, 15, 20, 20, 15,  5,-10, //4
  -10,  5, 15, 25, 25, 15,  5,-10, //5
   -5, 15, 25, 30, 30, 25, 15, -5, //6
  -25, -5,  0,  5,  5,  0, -5,-25, //7
  -75,-25,-15,-10,-10,-15,-25,-75);//8

  KnightPstEnd : array[a1..h8] of integer =(

  -40,-35,-20, -5, -5,-20,-35,-40, //1
  -25,-20, -5,  5,  5, -5,-20,-25, //2
  -20,-15,  0, 10, 10,  0,-15,-20, //3
  -15,-10,  5, 15, 15,  5,-10,-15, //4
  -15,-10,  5, 15, 15,  5,-10,-15, //5
  -20,-15,  0, 10, 10,  0,-15,-20, //6
  -25,-20,-10,  5,  5,-10,-20,-25, //7
  -45,-35,-15,  0,  0,-15,-35,-45);//8

  BishopPstMid : array[a1..h8] of integer =(

  -20, -8,-12,-16,-16,-12, -8,-20, //1
  -12,  4,  0, -4, -4,  0,  4,-12, //2
   -8,  8,  4,  0,  0,  4,  8, -8, //3
  -10,  8,  4,  0,  0,  4,  8,-10, //4
  -10,  6,  2,  0,  0,  2,  6,-10, //5
  -10,  4,  0, -2, -2,  0,  4,-10, //6
  -12,  4, -2, -4, -4, -2,  4,-12, //7
  -16, -8,-10,-12,-12,-10, -8,-16);//8

  BishopPstEnd : array[a1..h8] of integer =(

  -25,-16,-18,-10,-10,-18,-16,-25, //1
  -16, -8,-10,  0,  0,-10, -8,-16, //2
  -12, -4, -6,  4,  4, -6, -4,-12, //3
  -14, -6, -7,  4,  4, -7, -6,-14, //4
  -14, -6, -7,  3,  3, -7, -6,-14, //5
  -14, -6, -5,  0,  0, -5, -6,-14, //6
  -16, -8, -8,  0,  0, -8, -8,-16, //7
  -25,-16,-16,-10,-10,-16,-16,-25);//8

  RookPstMid : array[a1..h8] of integer =(

  -10, -6, -6, -3, -3, -6, -6,-10, //1
   -8, -3, -1,  1,  1, -1, -3, -8, //2
   -8, -3, -1,  1,  1, -1, -3, -8, //3
   -8, -1,  0,  1,  1,  0, -1, -8, //4
   -8, -1,  0,  1,  1,  0, -1, -8, //5
   -8, -1,  0,  1,  1,  0, -1, -8, //6
   -4,  2,  3,  5,  5,  3,  2, -4, //7
   -8, -6, -4, -2, -2, -4, -6, -8);//8

  QueenPstMid : array[a1..h8] of integer =(

    0,  0,  0,  0,  0,  0,  0,  0, //1
   -2,  2,  4,  4,  4,  4,  2, -2, //2
   -1,  2,  4,  4,  4,  4,  2, -1, //3
    0,  2,  4,  4,  4,  4,  2,  0, //4
   -1,  2,  2,  3,  3,  2,  2, -1, //5
   -1,  2,  2,  3,  3,  2,  2, -1, //6
   -1,  2,  2,  2,  2,  2,  2, -1, //7
   -1, -1,  0,  0,  0,  0, -1, -1);//8

  QueenPstEnd : array[a1..h8] of integer =(

   -30,-25,-15,-10,-10,-15,-25,-30, //1
   -25,-15,-10,  0,  0,-10,-15,-25, //2
   -15, -5, -2,  2,  2, -2, -5,-15, //3
   -10, -2,  4,  6,  6,  4, -2,-10, //4
   -10, -2,  4,  8,  8,  4, -2,-10, //5
   -15, -6, -4,  0,  0, -4, -6,-15, //6
   -20,-15,-10, -5, -5,-10,-15,-20, //7
   -30,-20,-15,-10,-10,-15,-20,-30);//8

  KingPstMid : array[a1..h8] of integer =(

   -15,  0,-15,-50,-50,-15,  0,-15, //1
   -15, -5,-30,-60,-60,-30, -5,-15, //2
   -45,-30,-55,-80,-80,-55,-30,-45, //3
   -55,-55,-65,-85,-85,-65,-55,-55, //4
   -65,-65,-80,-95,-95,-80,-65,-65, //5
   -80,-80,-95,-95,-95,-95,-80,-80, //6
   -95,-95,-95,-95,-95,-95,-95,-95, //7
   -95,-95,-95,-95,-95,-95,-95,-95);//8

  KingPstEnd : array[a1..h8] of integer =(

   10, 30, 40, 45, 45, 40, 30, 10, //1
   25, 45, 60, 65, 65, 60, 45, 25, //2
   40, 65, 75, 80, 80, 75, 65, 40, //3
   50, 75, 80, 85, 85, 80, 75, 50, //4
   50, 75, 85, 90, 90, 85, 75, 50, //5
   45, 70, 75, 80, 80, 75, 70, 45, //6
   25, 45, 60, 65, 65, 60, 45, 25, //7
   10, 30, 40, 45, 45, 40, 30, 10);//8

  KingAttackWeightsAll : array[pawn..King] of integer = (0,15,15,25,45,0);
  KingSafetyTable : array[0..15] of integer=(0,1,4,9,16,25,36,49,64,81,100,100,100,100,100,100);
  KingSafetyDivider=8;

  QueenContactCheck=25;
  QueenSafeCheck=20;
  RookSafeCheck=15;
  BishopSafeCheck=10;
  KnightSafeCheck=10;
  UndefendedSquare=10;
  BadKing=20;

  KnightMobMidMin=0;KnightMobEndMin=0;
  KnightMobMidMax=28; KnightMobENdMax=32;
  BishopMobMidMin=0;BishopMobEndMin=0;
  BishopMobMidMax=40;BishopMobEndMax=38;
  RookMobMidMin=0; RookMobEndMin=0;
  RookMobMidMax=20; RookMobEndMax=70;
  QueenMobMidMin=0; QueenMobEndMin=0;
  QueenMobMidMax=35; QueenMobEndMax=60;

  KnightOutPostMid=4;
  KnightOutPostEnd=6;
  KnightOutPostProtectedMid=15;
  KnightOutPostProtectedEnd=25;
  KnightOutPostDanger=5;

  BishopOutPostMid=2;
  BishopOutPostEnd=3;
  BishopOutPostProtectedMid=6;
  BishopOutPostProtectedEnd=8;
  BishopOutPostDanger=3;
  BishopPawnMid=2;
  BishopPawnEnd=5;
  BishopWeakMid=4;
  BishopWeakEnd=6;
  MinorBehindPawn=5;

  RookOpenMid=16;RookOpenEnd=8;
  RookHalfMid=8; RookHalfEnd=4;
  RookPawn=5;
  Rookon7Mid=10;
  RookOn7End=25;
  DoubRook7Mid=10;
  DoubRook7End=15;
  RookTrapped=35;

  ThreatHangingPawnMid=25;
  ThreatHangingPawnEnd=25;
  ThreatStrongPawnMid=40;
  ThreatStrongPawnEnd=40;
  ForkMid=25;
  ForkEnd=25;
  KingThreatOne=15;
  KingThreatMulti=25;
  HangingMid=20;
  HangingEnd=10;
  PawnUnProtectedEnd=5;
  PieseUnProtected=10;
  Tempo=8;
var
   EvalTable : array of TEvalEntry;
   EvalTableMask: int64;
   PiesePSTMid,PiesePstEnd : array[white..black,Pawn..King,a1..h8] of integer;
   KnightMobMid,KnightMobEnd : array[0..8] of integer;
   BishopMobMid,BishopMobEnd : array[0..13] of integer;
   RookMobMid,RookMobEnd : array[0..14] of integer;
   QueenMobMid,QueenMobEnd : array[0..27] of integer;

Procedure InitEvalTable(SizeMB:integer);
Procedure CalcFullPst(var PstMid:integer;var PSTEnd:integer; var Board:TBoard);inline;
Function Evaluate(var Board:TBoard):integer;inline;

implementation

Procedure InitEvalTable(SizeMB:integer);
// На входе - ОБЩЕЕ количество мегабайт кеша, полученного от оболочки
var
   i,EvalTableSize : int64;
begin
  EvalTableSize:=SizeMb;
  EvalTableSize:=(EvalTableSize * 1024 * 1024) div (16*8); {Берем 1/16 от общего количества памяти под хеш. Принимаем размер ячейки за 8 (на самом деле 10) Оставляем 1/16 на пешечный и материальный хеш}
  EvalTableMask:=EvalTableSize-1;
  SetLength(EvalTable,0);
  SetLength(EvalTable,EvalTableSize);
  for i:=0 to EvalTableMask do
    begin
      EvalTable[i].Key:=0;
      EvalTable[i].value:=0;
    end;
end;

Function GetLogValue(Min:real;Max:real;i:integer;Total:integer):integer;
const
  offset=1.0;
var
  factor,value:real;
begin
  Min:=Min*1.075;
  Max:=Max*1.075;
  factor:=(Max-Min)/ln(Total+offset);
  value:=Min+factor*ln(i+offset);
  Result:=round(value);
end;
Function  GetLinValue(Min:real;Max:real;i:integer;Total:integer):integer;
var
  range,range1,range2 : real;
  step1,step2 : real;
  full,half1,half2 : integer;
begin
  range:=Max-Min;
  range1:=trunc(0.66*range);
  range2:=range-range1;
  full:=Total-1;
  Half1:=Full div 2;
  Half2:=Full-Half1;
  Step1:=range1/half1;
  step2:=range2/half2;
  If i=0 then result:=trunc(Min-2*step1) else
  If i=Total then result:=trunc(Max) else
    begin
      if i<=Half1
        then result:=trunc(Min+step1*i)
        else result:=trunc(range1+step2*(i-half1));
    end;
end;

Function Evaluate(var Board:TBoard):integer;inline;
var
  EvalIndex : int64;
  PawnIndex,MatIndex: Cardinal;
  ScoreMid,ScoreEnd,score,WScale,BScale,Phase,PassMid,PassEnd,sq,ind,piesecol,bonus,x,wb,bb,Kx,Ky: integer;
  PAttacks : TAttacks;
  Temp,Att,temp1,Undefended,Weak,SafeThreats,Temp2 : TBitBoard;
  KingAttackCount,KingAttackWeight,Shield:TColor;
  MobilityArea,KingZone,Pines,BlockedPawns : TcolorZone;
begin
  // Пробуем воспрльзоваться хешем
  EvalIndex:=Board.Key and EvalTableMask;
  If Evaltable[EvalIndex].Key=Board.Key then
    begin
      Result:=Evaltable[EvalIndex].value;
      exit;
    end;
  // Сначала считаем материальную оценку
     // Получаем индекс в таблице с посчитанными данными по материалу.
  MatIndex:=EvaluateMaterial(Board);
     // Если на доске эндшпиль, где нужна специальная оценочная функция то вызываем ее и возвращаемся
  if MatTable[MatIndex].EvalFunc<>0 then
    begin
      Result:=EvaluateSpecialEndgame(MatTable[MatIndex].EvalFunc,MatTable[MatIndex].EvalEnd,Board);
      exit;
    end;
    // Берем данные для инициализации
  ScoreMid:=MatTable[MatIndex].EvalMid;
  ScoreEnd:=MatTable[MatIndex].EvalEnd;
  WScale:=MatTable[MatIndex].WScale;
  BScale:=MatTable[MatIndex].BScale;
  Phase :=MatTable[MatIndex].phase;
     // Если на доске соотношение материала, требующее дополнительной оценки для получения мастабирующих коэффициентов - считаем и их
  if MatTable[MatIndex].ScaleFunc<>0 then GetSpecialScales(MatTable[MatIndex].ScaleFunc,Wscale,BScale,Board);
  // Обнуляем счетчики безопасности
  KingAttackCount[white]:=0;KingAttackCount[black]:=0;
  KingAttackWeight[white]:=0;KingAttackWeight[black]:=0;
  // Инициализируем битборды атак фигур
  PAttacks[white,all]:=0; PAttacks[black,all]:=0;
  PAttacks[white,knight]:=0; PAttacks[black,knight]:=0;
  PAttacks[white,bishop]:=0; PAttacks[black,bishop]:=0;
  PAttacks[white,rook]:=0; PAttacks[black,rook]:=0;
  PAttacks[white,queen]:=0; PAttacks[black,queen]:=0;
  //Битборды королей и пешек вычисляем сразу
  PAttacks[white,king]:=KingAttacks[Board.KingSq[white]] or Only[Board.KingSq[white]]; PAttacks[black,king]:=KingAttacks[Board.KingSq[black]] or Only[Board.KingSq[black]];
  PAttacks[white,all]:=PAttacks[white,all] or PAttacks[white,king];
  PAttacks[black,all]:=PAttacks[black,all] or PAttacks[black,king];
  temp:=Board.Pieses[pawn] and Board.Occupancy[white];
  PAttacks[white,pawn]:=((temp and (not FilesBB[1])) shl 7) or ((temp and (not FilesBB[8])) shl 9);
  temp:=Board.Pieses[pawn] and Board.Occupancy[black];
  PAttacks[black,pawn]:=((temp and (not FilesBB[1])) shr 9) or ((temp and (not FilesBB[8])) shr 7);
  PAttacks[white,all]:=PAttacks[white,all] or PAttacks[white,pawn];
  PAttacks[black,all]:=PAttacks[black,all] or PAttacks[black,pawn];
  // Связки
  Pines[white]:=FindPinners(white,white,Board);
  Pines[black]:=FindPinners(black,black,Board);
  // Блокированные пешки и пешки на 2-3 горизонтали
  BlockedPawns[white]:=Board.Pieses[pawn] and Board.Occupancy[white] and ((Board.Occupancy[white] shr 8) or RanksBB[3] or RanksBB[2] );
  BlockedPawns[black]:=Board.Pieses[pawn] and Board.Occupancy[black] and ((Board.Occupancy[black] shl 8) or RanksBB[6] or RanksBB[7] );
  // Устанавливаем поля где считается подвижность за обе стороны
  MobilityArea[white]:=not(BlockedPawns[white] or PAttacks[black,pawn] or Only[Board.KingSq[white]]);
  MobilityArea[black]:=not(BlockedPawns[black] or PAttacks[white,pawn] or Only[Board.KingSq[black]]);
  //Теперь оценка пешек
  PawnIndex:=EvaluatePawns(Board);
  ScoreMid:=ScoreMid+PawnTable[PawnIndex].ScoreMid;
  ScoreEnd:=ScoreEnd+PawnTable[PawnIndex].ScoreEnd;
  Shield[white]:=WkingSafety(PawnIndex,Board);
  Shield[black]:=BkingSafety(PawnIndex,Board);
  if Board.NonPawnMat[white]>=PieseTypValue[queen]
    then KingZone[black]:=PAttacks[black,king] or (PAttacks[black,king] shr 8)
    else KingZone[black]:=0;
  if Board.NonPawnMat[black]>=PieseTypValue[queen]
    then KingZone[white]:=PAttacks[white,king] or (PAttacks[white,king] shl 8)
    else KingZone[white]:=0;

   // Атака пешек на короля.
   If (KingZone[black]<>0) and ((PAttacks[black,king] and PAttacks[white,pawn])<>0) then inc(KingAttackCount[white]);
   If (KingZone[white]<>0) and ((PAttacks[white,king] and PAttacks[black,pawn])<>0) then inc(KingAttackCount[black]);
   // Атака королей друг на друга
   If (KingZone[white]<>0) and ((PAttacks[white,king] and PAttacks[black,king])<>0) then inc(KingAttackCount[black]);
   If (KingZone[black]<>0) and ((PAttacks[white,king] and PAttacks[black,king])<>0) then inc(KingAttackCount[white]);
  // Оценка фигур
  ScoreMid:=ScoreMid+Board.PstMid;
  ScoreEnd:=ScoreEnd+Board.PstEnd;
  // Кони
  temp:=Board.Pieses[knight];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     // Атакованные поля
     att:=KnightAttacks[sq];
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     PAttacks[piesecol,knight]:=PAttacks[piesecol,knight] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         inc(KingAttackCount[piesecol]);
         If ((Att and PAttacks[piesecol xor 1,king])<>0) then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[knight];
       end;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     if piesecol=white then
       begin
         ScoreMid:=ScoreMid+KnightMobMid[ind];
         ScoreEnd:=ScoreEnd+KnightMobEnd[ind];
         // Форпосты
         If ((ForwardBB[white,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[black])=0) and ((OutPostBB[white] and Only[sq])<>0) then
           begin
             if ((PawnAttacks[black,sq] and Board.Pieses[pawn] and Board.Occupancy[white])<>0) then
               begin
                 ScoreMid:=ScoreMid+KnightOutPostProtectedMid;
                 ScoreEnd:=ScoreEnd+KnightOutPostProtectedEnd;
                 if (Att and KingZone[piesecol xor 1])<>0 then ScoreMid:=ScoreMid+KnightOutPostDanger;
               end else
               begin
                 ScoreMid:=ScoreMid+KnightOutPostMid;
                 ScoreEnd:=ScoreEnd+KnightOutPostEnd;
               end;
           end;
         if (posy[sq]<5) and ((Only[sq+8] and Board.Pieses[pawn])<>0) then ScoreMid:=ScoreMid+MinorBehindPawn;
       end else
       begin
         ScoreMid:=ScoreMid-KnightMobMid[ind];
         ScoreEnd:=ScoreEnd-KnightMobEnd[ind];
         // Форпосты
         If ((ForwardBB[black,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[white])=0) and ((OutPostBB[black] and Only[sq])<>0) then
           begin
             if ((PawnAttacks[white,sq] and Board.Pieses[pawn] and Board.Occupancy[black])<>0) then
               begin
                 ScoreMid:=ScoreMid-KnightOutPostProtectedMid;
                 ScoreEnd:=ScoreEnd-KnightOutPostProtectedEnd;
                 if (Att and KingZone[piesecol xor 1])<>0 then ScoreMid:=ScoreMid-KnightOutPostDanger;
               end else
               begin
                 ScoreMid:=ScoreMid-KnightOutPostMid;
                 ScoreEnd:=ScoreEnd-KnightOutPostEnd;
               end;
           end;
         if (posy[sq]>4) and ((Only[sq-8] and Board.Pieses[pawn])<>0) then ScoreMid:=ScoreMid-MinorBehindPawn;
       end;
     temp:=temp and (temp-1);
    end;
  // Слоны
  wb:=0;
  bb:=0;
  temp1:=(Board.Pieses[bishop] or Board.Pieses[queen]);
  temp:=Board.Pieses[bishop];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     // Атакованные поля
     att:=BishopAttacksBB(sq,Board.AllPieses and (not(temp1 and Board.Occupancy[piesecol])) );
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     PAttacks[piesecol,bishop]:=PAttacks[piesecol,bishop] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         inc(KingAttackCount[piesecol]);
         If ((Att and PAttacks[piesecol xor 1,king])<>0) then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[bishop];
       end;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     if piesecol=white then
       begin
         inc(wb);
         ScoreMid:=ScoreMid+BishopMobMid[ind];
         ScoreEnd:=ScoreEnd+BishopMobEnd[ind];
         // Форпосты
         If ((ForwardBB[white,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[black])=0) and ((OutPostBB[white] and Only[sq])<>0)  then
           begin
             if ((PawnAttacks[black,sq] and Board.Pieses[pawn] and Board.Occupancy[white])<>0) then
               begin
                 ScoreMid:=ScoreMid+BishopOutPostProtectedMid;
                 ScoreEnd:=ScoreEnd+BishopOutPostProtectedEnd;
                 if (Att and KingZone[piesecol xor 1])<>0 then ScoreMid:=ScoreMid+BishopOutPostDanger;
               end else
               begin
                 ScoreMid:=ScoreMid+BishopOutPostMid;
                 ScoreEnd:=ScoreEnd+BishopOutPostEnd;
               end;
           end;
        // Блокированность пешками
        if (Only[sq] and LightSquaresBB)<>0 then
          begin
            ScoreMid:=ScoreMid-BishopPawnMid*(PawnTable[PawnIndex].BPawn and 15);
            ScoreEnd:=ScoreEnd-BishopPawnEnd*(PawnTable[PawnIndex].BPawn and 15);
          end else
          begin
            ScoreMid:=ScoreMid-BishopPawnMid*((PawnTable[PawnIndex].BPawn shr 4) and 15);
            ScoreEnd:=ScoreEnd-BishopPawnEnd*((PawnTable[PawnIndex].BPawn shr 4) and 15);
          end;
        if (posy[sq]<5) then
          begin
           if ((Only[sq+8] and Board.Pieses[pawn])<>0) then ScoreMid:=ScoreMid+MinorBehindPawn;
           Temp2:=(BishopFullAttacks[sq] and ForwardBB[white,sq] and (RanksBB[Posy[sq]+1] or RanksBB[Posy[sq]+2]) and Board.Pieses[pawn] and Board.Occupancy[white]);
           if Temp2<>0 then
             begin
               ind:=BitCount(temp2);
               ScoreMid:=ScoreMid-BishopWeakMid*ind;
               ScoreEnd:=ScoreEnd-BishopWeakEnd*ind;
             end;
          end;
       end else
       begin
         inc(bb);
         ScoreMid:=ScoreMid-BishopMobMid[ind];
         ScoreEnd:=ScoreEnd-BishopMobEnd[ind];
         // Форпосты
         If ((ForwardBB[black,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[white])=0) and ((OutPostBB[black] and Only[sq])<>0) then
           begin
             if ((PawnAttacks[white,sq] and Board.Pieses[pawn] and Board.Occupancy[black])<>0) then
               begin
                 ScoreMid:=ScoreMid-BishopOutPostProtectedMid;
                 ScoreEnd:=ScoreEnd-BishopOutPostProtectedEnd;
                 if (Att and KingZone[piesecol xor 1])<>0 then ScoreMid:=ScoreMid-BishopOutPostDanger;
               end else
               begin
                 ScoreMid:=ScoreMid-BishopOutPostMid;
                 ScoreEnd:=ScoreEnd-BishopOutPostEnd;
               end;
           end;
         // Блокированность пешками
        if (Only[sq] and LightSquaresBB)<>0 then
          begin
            ScoreMid:=ScoreMid+BishopPawnMid*((PawnTable[PawnIndex].BPawn shr 8) and 15);
            ScoreEnd:=ScoreEnd+BishopPawnEnd*((PawnTable[PawnIndex].BPawn shr 8) and 15);
          end else
          begin
            ScoreMid:=ScoreMid+BishopPawnMid*((PawnTable[PawnIndex].BPawn shr 12) and 15);
            ScoreEnd:=ScoreEnd+BishopPawnEnd*((PawnTable[PawnIndex].BPawn shr 12) and 15);
          end;
        if (posy[sq]>4) then
          begin
           if ((Only[sq-8] and Board.Pieses[pawn])<>0) then ScoreMid:=ScoreMid-MinorBehindPawn;
           Temp2:=(BishopFullAttacks[sq] and ForwardBB[black,sq] and (RanksBB[Posy[sq]-1] or RanksBB[Posy[sq]-2]) and Board.Pieses[pawn] and Board.Occupancy[black]);
           if Temp2<>0 then
             begin
               ind:=BitCount(temp2);
               ScoreMid:=ScoreMid+BishopWeakMid*ind;
               ScoreEnd:=ScoreEnd+BishopWeakEnd*ind;
             end;
          end;
       end;
     temp:=temp and (temp-1);
    end;
  // Ладьи
  temp1:=(Board.Pieses[rook] or Board.Pieses[queen]);
  temp:=Board.Pieses[rook];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     x:=posx[sq];
     piesecol:=PieseColor[Board.Pos[sq]];
     // Атакованные поля
     att:=RookAttacksBB(sq,Board.AllPieses and (not(temp1 and Board.Occupancy[piesecol])) );
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     PAttacks[piesecol,rook]:=PAttacks[piesecol,rook] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         inc(KingAttackCount[piesecol]);
         If ((Att and PAttacks[piesecol xor 1,king])<>0) then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[rook];
       end;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     if piesecol=white then
       begin
         ScoreMid:=ScoreMid+RookMobMid[ind];
         ScoreEnd:=ScoreEnd+RookMobEnd[ind];
         // Специфика для Ладьи
         If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[white])=0 then
           begin
            If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[black])=0 then
             begin
              ScoreMid:=ScoreMid+RookOpenMid;
              ScoreEnd:=ScoreEnd+RookOpenEnd;
             end else
             begin
              ScoreMid:=ScoreMid+RookHalfMid;
              ScoreEnd:=ScoreEnd+RookHalfEnd;
             end;
           end else
         if (ind<4) and ((Board.CastleRights and 3)=0) then
           begin
             Kx:=Posx[Board.KingSq[white]];
             Ky:=Posy[Board.KingSq[white]];
             if (((Kx<5) and (x<Kx)) or ((Kx>=5) and (X>Kx))) and ((Ky=1) or (Ky=Posy[sq])) then ScoreMid:=ScoreMid-RookTrapped;
           end;
         If (Posy[sq]=7) and (Posy[Board.KingSq[black]]>=7) then
           begin
             ScoreMid:=Scoremid+RookOn7Mid;
             ScoreEnd:=ScoreEnd+RookOn7End;
             If (Att and RanksBB[7] and (Board.Pieses[rook] or Board.Pieses[queen]) and Board.Occupancy[white])<>0 then
               begin
                 ScoreMid:=ScoreMid+DoubRook7Mid;
                 ScoreEnd:=ScoreEnd+DoubRook7End;
               end;
           end;
         If (Posy[sq]>4) and ((RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[black])<>0) then ScoreEnd:=ScoreEnd+RookPawn*BitCount(RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[black]);
       end else
       begin
         ScoreMid:=ScoreMid-RookMobMid[ind];
         ScoreEnd:=ScoreEnd-RookMobEnd[ind];
         // Специфика для Ладьи
         If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[black])=0 then
           begin
            If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[white])=0 then
             begin
              ScoreMid:=ScoreMid-RookOpenMid;
              ScoreEnd:=ScoreEnd-RookOpenEnd;
             end else
             begin
              ScoreMid:=ScoreMid-RookHalfMid;
              ScoreEnd:=ScoreEnd-RookHalfEnd;
             end;
           end else
         if (ind<4) and ((Board.CastleRights and 12)=0) then
           begin
             Kx:=Posx[Board.KingSq[black]];
             Ky:=Posy[Board.KingSq[black]];
             if (((Kx<5) and (x<Kx)) or ((Kx>=5) and (X>Kx))) and ((Ky=8) or (Ky=Posy[sq])) then ScoreMid:=ScoreMid+RookTrapped;
           end;
         If (Posy[sq]=2) and (Posy[Board.KingSq[white]]<=2) then
           begin
             ScoreMid:=Scoremid-RookOn7Mid;
             ScoreEnd:=ScoreEnd-RookOn7End;
             If (Att and RanksBB[2] and (Board.Pieses[rook] or Board.Pieses[queen]) and Board.Occupancy[black])<>0 then
               begin
                 ScoreMid:=ScoreMid-DoubRook7Mid;
                 ScoreEnd:=ScoreEnd-DoubRook7End;
               end;
           end;
         If (Posy[sq]<5) and ((RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[white])<>0) then ScoreEnd:=ScoreEnd-RookPawn*BitCount(RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[white]);
       end;
     temp:=temp and (temp-1);
    end;
  // Ферзи
  temp:=Board.Pieses[queen];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     // Атакованные поля
     att:=QueenAttacksBB(sq,Board.AllPieses);
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     PAttacks[piesecol,queen]:=PAttacks[piesecol,queen] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         inc(KingAttackCount[piesecol]);
         If ((Att and PAttacks[piesecol xor 1,king])<>0) then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[queen];
       end;
     // Подвижность
     Att:=Att and (not(Pattacks[piesecol xor 1,knight] or Pattacks[piesecol xor 1,bishop] or Pattacks[piesecol xor 1,rook]));
     ind:=BitCount(Att and MobilityArea[piesecol]);
     if piesecol=white then
       begin
         ScoreMid:=ScoreMid+QueenMobMid[ind];
         ScoreEnd:=ScoreEnd+QueenMobEnd[ind];
       end else
       begin
         ScoreMid:=ScoreMid-QueenMobMid[ind];
         ScoreEnd:=ScoreEnd-QueenMobEnd[ind];
       end;
     temp:=temp and (temp-1);
    end;
  // Оценка безопасности короля
  ScoreMid:=ScoreMid-Shield[white]+Shield[black];
  if KingAttackCount[white]>0 then
    begin
     if (KingAttackCount[white]>1) and ((Board.Pieses[queen] and Board.Occupancy[white])<>0) then
       begin
        KingAttackWeight[white]:=KingAttackWeight[white]+(Shield[black] div 4);
        If (PAttacks[black,king] and (not(PAttacks[white,all] or Board.Occupancy[black])))=0 then KingAttackWeight[white]:=KingAttackWeight[white]+BadKing;
       end;
     Undefended:=PAttacks[white,all] and PAttacks[black,king] and (not(PAttacks[black,pawn] or PAttacks[black,bishop] or PAttacks[black,knight] or PAttacks[black,rook] or PAttacks[black,queen]));
     If Undefended<>0 then KingAttackWeight[white]:=KingAttackWeight[white]+UndefendedSquare*BitCount(Undefended);
     Undefended:=Undefended and PAttacks[white,queen] and ( not Board.Occupancy[white]);
     If (Undefended<>0) then
       begin
         Undefended:=Undefended and (PAttacks[white,pawn] or PAttacks[white,knight] or PAttacks[white,bishop] or PAttacks[white,rook] or PAttacks[white,king]);
         If Undefended<>0 then KingAttackWeight[white]:=KingAttackWeight[white]+QueenContactCheck;
       end;
     Undefended:= not (PAttacks[black,all] or Board.Occupancy[white]);
     temp:=RookAttacksBB(Board.KingSq[black],Board.AllPieses) and Undefended;
     temp1:=BishopAttacksBB(Board.KingSq[black],Board.AllPieses) and Undefended;
     // Шахи ферзем
     If ((temp or temp1) and PAttacks[white,queen])<>0 then
       begin
         KingAttackWeight[white]:=KingAttackWeight[white]+QueenSafeCheck;
       end;
     // Шахи ладьей
     If (temp and PAttacks[white,rook])<>0 then
       begin
         KingAttackWeight[white]:=KingAttackWeight[white]+RookSafeCheck;
       end;
     // Шахи слоном
     If (temp1 and PAttacks[white,bishop])<>0 then
       begin
         KingAttackWeight[white]:=KingAttackWeight[white]+BishopSafeCheck;
       end;
     // Шахи Конем
     If (KnightAttacksBB(Board.KingSq[black]) and Undefended and PAttacks[white,knight])<>0 then
       begin
         KingAttackWeight[white]:=KingAttackWeight[white]+KnightSafeCheck;
       end;
     bonus:=((KingSafetyTable[KingAttackCount[white]]*KingAttackWeight[white]) div KingSafetyDivider);
     if (Board.Pieses[queen] and Board.Occupancy[white])=0 then bonus:=bonus div 2;
     ScoreMid:=ScoreMid+bonus;
    end;
  if KingAttackCount[black]>0 then
    begin
     if (KingAttackCount[black]>1) and ((Board.Pieses[queen] and Board.Occupancy[black])<>0) then
       begin
        KingAttackWeight[black]:=KingAttackWeight[black]+(Shield[white] div 4);
        If (PAttacks[white,king] and (not(PAttacks[black,all] or Board.Occupancy[white])))=0 then KingAttackWeight[black]:=KingAttackWeight[black]+BadKing;
       end;
     Undefended:=PAttacks[black,all] and PAttacks[white,king] and (not(PAttacks[white,pawn] or PAttacks[white,bishop] or PAttacks[white,knight] or PAttacks[white,rook] or PAttacks[white,queen]));
     If Undefended<>0 then KingAttackWeight[black]:=KingAttackWeight[black]+UndefendedSquare*BitCount(Undefended);
     Undefended:=Undefended and PAttacks[black,queen] and ( not Board.Occupancy[black]);
     If (Undefended<>0) then
       begin
         Undefended:=Undefended and (PAttacks[black,pawn] or PAttacks[black,knight] or PAttacks[black,bishop] or PAttacks[black,rook] or PAttacks[black,king]);
         If Undefended<>0 then KingAttackWeight[black]:=KingAttackWeight[black]+QueenContactCheck;
       end;
     Undefended:= not (PAttacks[white,all] or Board.Occupancy[black]);
     temp:=RookAttacksBB(Board.KingSq[white],Board.AllPieses) and Undefended;
     temp1:=BishopAttacksBB(Board.KingSq[white],Board.AllPieses) and Undefended;
     // Шахи ферзем
     If ((temp or temp1) and PAttacks[black,queen])<>0 then
       begin
         KingAttackWeight[black]:=KingAttackWeight[black]+QueenSafeCheck;
       end;
     // Шахи ладьей
     If (temp and PAttacks[black,rook])<>0 then
       begin
         KingAttackWeight[black]:=KingAttackWeight[black]+RookSafeCheck;
       end;
     // Шахи слоном
     If (temp1 and PAttacks[black,bishop])<>0 then
       begin
         KingAttackWeight[black]:=KingAttackWeight[black]+BishopSafeCheck;
       end;
     // Шахи Конем
     If (KnightAttacksBB(Board.KingSq[white]) and Undefended and PAttacks[black,knight])<>0 then
       begin
         KingAttackWeight[black]:=KingAttackWeight[black]+KnightSafeCheck;
       end;
     bonus:=((KingSafetyTable[KingAttackCount[black]]*KingAttackWeight[black]) div KingSafetyDivider);
     if (Board.Pieses[queen] and Board.Occupancy[black])=0 then bonus:=bonus div 2;
     ScoreMid:=ScoreMid-bonus;
    end;

  //  Если есть проходные - запускаем специальную оценочную и для них
  if PawnTable[PawnIndex].PassersBB<>0 then
    begin
      EvaluatePassers(PassMid,PassEnd,PawnTable[PawnIndex].PassersBB,Board,PAttacks[white,all],PAttacks[black,all]);
      ScoreMid:=ScoreMid+PassMid;
      ScoreEnd:=ScoreEnd+PassEnd;
    end;
  //  Угрозы
 // Фигуры противника атакованы нашими пешками
 Weak:=(Board.Occupancy[black] and (not Board.Pieses[pawn])) and PAttacks[white,pawn];
 if Weak<>0 then
   begin
     Temp:=(Board.Pieses[pawn] and Board.Occupancy[white]) and ((not PAttacks[black,all]) or PAttacks[white,all]);
     SafeThreats:=(((temp and (not FilesBB[1])) shl 7) or ((temp and (not FilesBB[8])) shl 9)) and Weak;
     If (Weak and (not SafeThreats))<>0 then
       begin
         ScoreMid:=ScoreMid+ThreatHangingPawnMid;
         ScoreEnd:=ScoreEnd+ThreatHangingPawnEnd;
       end;
     If SafeThreats<>0 then
       begin
         ind:=BitCount(SafeThreats);
         ScoreMid:=ScoreMid+ind*ThreatStrongPawnMid;
         ScoreEnd:=ScoreEnd+ind*ThreatStrongPawnEnd;
       end;
   end;
 Weak:=(Board.Occupancy[white] and (not Board.Pieses[pawn])) and PAttacks[black,pawn];
 if Weak<>0 then
   begin
     Temp:=(Board.Pieses[pawn] and Board.Occupancy[black]) and ((not PAttacks[white,all]) or PAttacks[black,all]);
     SafeThreats:=(((temp and (not FilesBB[1])) shr 9) or ((temp and (not FilesBB[8])) shr 7)) and Weak;
     If (Weak and (not SafeThreats))<>0 then
       begin
         ScoreMid:=ScoreMid-ThreatHangingPawnMid;
         ScoreEnd:=ScoreEnd-ThreatHangingPawnEnd;
       end;
     If SafeThreats<>0 then
       begin
         ind:=BitCount(SafeThreats);
         ScoreMid:=ScoreMid-ind*ThreatStrongPawnMid;
         ScoreEnd:=ScoreEnd-ind*ThreatStrongPawnEnd;
       end;
   end;
  // Вилки легкими фигурами
  Weak:=(Board.Occupancy[black] and (Board.Pieses[rook] or Board.Pieses[queen])) and (PAttacks[white,knight] or PAttacks[white,bishop]);
  If Weak<>0 then
    begin
      ind:=BitCount(Weak);
      ScoreMid:=ScoreMid+ForkMid*ind;
      ScoreEnd:=ScoreEnd+ForkEnd*ind;
    end;
  Weak:=(Board.Occupancy[white] and (Board.Pieses[rook] or Board.Pieses[queen])) and (PAttacks[black,knight] or PAttacks[black,bishop]);
  If Weak<>0 then
    begin
      ind:=BitCount(Weak);
      ScoreMid:=ScoreMid-ForkMid*ind;
      ScoreEnd:=ScoreEnd-ForkEnd*ind;
    end;
  // Атаки Королей
  Weak:=Board.Occupancy[black] and (not PAttacks[black,pawn]) and PAttacks[white,king];
  If Weak<>0 then
    begin
      If (Weak and (Weak-1))<>0
        then ScoreEnd:=ScoreEnd+KingThreatMulti
        else ScoreEnd:=ScoreEnd+KingThreatOne;
    end;

  Weak:=Board.Occupancy[white] and (not PAttacks[white,pawn]) and PAttacks[black,king];
  If Weak<>0 then
    begin
      If (Weak and (Weak-1))<>0
        then ScoreEnd:=ScoreEnd-KingThreatMulti
        else ScoreEnd:=ScoreEnd-KingThreatOne;
    end;
   // Висячие фигуры (не защищенные под атакой)
  Weak:=Board.Occupancy[black] and PAttacks[white,all] and (not PAttacks[black,all]);
  if Weak<>0 then
    begin
      ind:=BitCount(Weak);
      ScoreMid:=ScoreMid+HangingMid*ind;
      ScoreEnd:=ScoreEnd+HangingEnd*ind;
    end;

  Weak:=Board.Occupancy[white] and PAttacks[black,all] and (not PAttacks[white,all]);
  if Weak<>0 then
    begin
      ind:=BitCount(Weak);
      ScoreMid:=ScoreMid-HangingMid*ind;
      ScoreEnd:=ScoreEnd-HangingEnd*ind;
    end;
  // Атаки на незащищенные пешками цели
  Temp:=Board.Occupancy[black] and (PAttacks[white,knight] or PAttacks[white,bishop] or PAttacks[white,rook]) and (not PAttacks[black,pawn]);
  // На пешки
  Weak:=Temp and Board.Pieses[pawn];
  If Weak<>0 then ScoreEnd:=ScoreEnd+PawnUnProtectedEnd*BitCount(weak);
  // На легкие фигуры
  Weak:=Temp and (Board.Pieses[knight] or Board.Pieses[bishop]);
  If Weak<>0 then
    begin
      ind:=BitCount(weak);
      ScoreMid:=ScoreMid+ind*PieseUnProtected;
      ScoreEnd:=ScoreEnd+ind*PieseUnProtected;
    end;
  Temp:=Board.Occupancy[white] and (PAttacks[black,knight] or PAttacks[black,bishop] or PAttacks[black,rook]) and (not PAttacks[white,pawn]);
  // На пешки
  Weak:=Temp and Board.Pieses[pawn];
  If Weak<>0 then ScoreEnd:=ScoreEnd-PawnUnProtectedEnd*BitCount(weak);
  // На легкие фигуры
  Weak:=Temp and (Board.Pieses[knight] or Board.Pieses[bishop]);
  If Weak<>0 then
    begin
      ind:=BitCount(weak);
      ScoreMid:=ScoreMid-ind*PieseUnProtected;
      ScoreEnd:=ScoreEnd-ind*PieseUnProtected;
    end;
  if (Phase<=PhaseOpposit) then
    begin
      // Слоновый эндшпиль ( Возможные разноцветные слоны)
      If  (wb=1) and (bb=1) then OppositeBishops(WScale,BScale,Board);
      If (Abs(ScoreEnd)<300) then
        begin
          // Король успел под пешки противника
          If ((BScale=ScaleNormal) or (BScale=ScaleOnePawn)) and ((PasserBB[white,Board.KingSq[white]] and Board.Pieses[pawn] and Board.Occupancy[black])=(Board.Pieses[pawn] and Board.Occupancy[black])) then BScale:=BScale-ScaleHardWin;
          If ((WScale=ScaleNormal) or (WScale=ScaleOnePawn)) and ((PasserBB[black,Board.KingSq[black]] and Board.Pieses[pawn] and Board.Occupancy[white])=(Board.Pieses[pawn] and Board.Occupancy[white])) then WScale:=WScale-ScaleHardWin;
        end;
    end;
  // Итоговая оценка в зависимости от материала на доске
  score:=(ScoreMid*Phase+(32-Phase)*scoreend) div 32;
  // Масштабируем оценку если надо
  if (score>0) and (WScale<>ScaleNormal) then score:=((score*WScale) div ScaleNormal) else
  if (score<0) and (BScale<>ScaleNormal) then score:=((score*BScale) div ScaleNormal);
  // Если ход черных то даем оценку с их стороны
  if Board.SideToMove=black
    then score:=-score+Tempo
    else score:=score+Tempo;
  // Пишем в хеш
  EvalTable[EvalIndex].Key:=Board.Key;
  EvalTable[EvalIndex].value:=score;
  Result:=score;
end;


Procedure CalcFullPst(var PstMid:integer;var PSTEnd:integer; var Board:TBoard);inline;
// Считает полную оценку позиций всех фигур на доске. Нужна для отладки
var
  Temp : TBitBoard;
  sq,color,piese,pieseTyp: integer;
begin
  PstMid:=0;PstEnd:=0;
  temp:=Board.AllPieses;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      Piese:=Board.Pos[sq];
      color:=PieseColor[piese];
      PieseTyp:=TypOfPiese[piese];
      PstMid:=PstMid+PiesePstMid[color,piesetyp,sq];
      PstEnd:=PstEnd+PiesePstEnd[color,piesetyp,sq];
      temp:=temp and (temp-1);
    end;
end;
Procedure EvalInit;
var
  i,j,k : integer;
begin
  for i:=white to black do
  for j:=pawn to king do
  for k:=a1 to h8 do
   begin
    PiesePstMid[i,j,k]:=0;
    PiesePstEnd[i,j,k]:=0;
   end;

  for i:=a1 to h8 do
    begin
      PiesePstMid[white,pawn,i]:=PawnPstMid[i];
      PiesePstMid[black,pawn,i]:=-PawnPstMid[63-i];
    end;
  for i:=a1 to h8 do
    begin
      PiesePstMid[white,knight,i]:=KnightPstMid[i];
      PiesePstMid[black,knight,i]:=-KnightPstMid[63-i];
      PiesePstEnd[white,knight,i]:=KnightPstEnd[i];
      PiesePstEnd[black,knight,i]:=-KnightPstEnd[63-i];
    end;
  for i:=a1 to h8 do
    begin
      PiesePstMid[white,bishop,i]:=BishopPstMid[i];
      PiesePstMid[black,bishop,i]:=-BishopPstMid[63-i];
      PiesePstEnd[white,bishop,i]:=BishopPstEnd[i];
      PiesePstEnd[black,bishop,i]:=-BishopPstEnd[63-i];
    end;
  for i:=a1 to h8 do
    begin
      PiesePstMid[white,rook,i]:=RookPstMid[i];
      PiesePstMid[black,rook,i]:=-RookPstMid[63-i];
    end;
  for i:=a1 to h8 do
    begin
      PiesePstMid[white,queen,i]:=QueenPstMid[i];
      PiesePstMid[black,queen,i]:=-QueenPstMid[63-i];
      PiesePstEnd[white,queen,i]:=QueenPstEnd[i];
      PiesePstEnd[black,queen,i]:=-QueenPstEnd[63-i];
    end;
  for i:=a1 to h8 do
    begin
      PiesePstMid[white,king,i]:=KingPstMid[i];
      PiesePstMid[black,king,i]:=-KingPstMid[63-i];
      PiesePstEnd[white,king,i]:=KingPstEnd[i];
      PiesePstEnd[black,king,i]:=-KingPstEnd[63-i];
    end;
  For i:=0 to 8 do
    begin
      KnightMobMid[i]:=GetLinValue(KnightMobMidMin,KnightMobMidMax,i,9);
      KnightMobEnd[i]:=GetLinValue(KnightMobEndMin,KnightMobEndMax,i,9);
    end;
  For i:=0 to 13 do
    begin
      BishopMobMid[i]:=GetLinValue(BishopMobMidMin,BishopMobMidMax,i,14);
      BishopMobEnd[i]:=GetLinValue(BishopMobEndMin,BishopMobEndMax,i,14);
    end;
  For i:=0 to 14 do
    begin
      RookMobMid[i]:=GetLinValue(RookMobMidMin,RookMobMidMax,i,15);
      RookMobEnd[i]:=GetLinValue(RookMobEndMin,RookMobEndMax,i,15);
    end;
  For i:=0 to 27 do
    begin
      QueenMobMid[i]:=GetLinValue(QueenMobMidMin,QueenMobMidMax,i,28);
      QueenMobEnd[i]:=GetLinValue(QueenMobEndMin,QueenMobEndMax,i,28);
    end;
end;

initialization
EvalInit;
end.
