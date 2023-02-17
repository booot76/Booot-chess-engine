unit uEval;

interface
uses uBoard,uBitBoards,uMaterial,uPawn,uSort,umagic,uAttacks,uEndgame;

Type
  TAttacks = array[white..black,all..King] of TBitBoard;
  T6=array[pawn..king] of integer;
  Tcolor = array[white..black] of integer;
  TColorZone = array[white..black] of TBitBoard;
  TEvalEntry = record
                  Key : int64;
                  value : smallint;
                end;
Const
  step : array[white..black] of integer =(8,-8);
  RelRank : array[white..black,1..8] of integer =((1,2,3,4,5,6,7,8),(8,7,6,5,4,3,2,1));
  lig=0;
  dar=1;
  BishopShift : array[white..black,lig..dar] of integer = ((0,4),(8,12));
  CastleCheck : array[white..black] of integer = (3,12);
  PawnPstMid : array[a1..h8] of integer =(
    0, 0, 0, 0, 0, 0, 0, 0,   //1
   -9,-2, 0, 3, 3, 0,-2,-9,   //2
   -9,-2, 2,10,10, 2,-2,-9,   //3
   -9,-2, 4,15,15, 4,-2,-9,   //4
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
  KnightSafeCheck=15;
  UndefendedSquare=15;
  BadKing=25;

  Guard:t6=(0,2,4,4,1,0);

  KnightMobMidMin=-30;KnightMobEndMin=-30;
  KnightMobMidMax=15; KnightMobENdMax=12;
  BishopMobMidMin=-20;BishopMobEndMin=-20;
  BishopMobMidMax=40;BishopMobEndMax=40;
  RookMobMidMin=-25; RookMobEndMin=-30;
  RookMobMidMax=25; RookMobEndMax=70;
  QueenMobMidMin=-15; QueenMobEndMin=-15;
  QueenMobMidMax=45; QueenMobEndMax=80;

  KnightOutPostMid=4;
  KnightOutPostEnd=6;
  KnightOutPostProtectedMid=15;
  KnightOutPostProtectedEnd=25;

  BishopOutPostMid=2;
  BishopOutPostEnd=3;
  BishopOutPostProtectedMid=6;
  BishopOutPostProtectedEnd=8;

  BishopPawnMid=3;
  BishopPawnEnd=5;
  MinorBehindPawn=5;

  RookOpenMid=16;RookOpenEnd=8;
  RookHalfMid=8; RookHalfEnd=4;
  RookPawn=10;
  RookTrapped=35;
  Rookon7Mid=25;
  RookOn7End=45;

  ThreatHangingPawnMid=25;
  ThreatHangingPawnEnd=25;
  ThreatStrongPawnMid=65;
  ThreatStrongPawnEnd=65;

  MinorThreatMid:t6=( 0,15,15,25,20,0);
  MinorThreatEnd:t6=(10,15,15,40,45,0);
  RookThreatMid:t6=( 0,10,10, 0,15,0);
  RookThreatEnd:t6=( 5,15,15,10,20,0);

  KingThreatOne=25;
  KingThreatMulti=40;
  HangingMid=15;
  HangingEnd=10;
  CheckMid=5;
  CheckEnd=5;
  Tempo=8;

  LazyMargin=600;

var
   PiesePSTMid,PiesePstEnd : array[white..black,Pawn..King,a1..h8] of integer;
   KnightMobMid,KnightMobEnd : array[0..8] of integer;
   BishopMobMid,BishopMobEnd : array[0..13] of integer;
   RookMobMid,RookMobEnd : array[0..14] of integer;
   QueenMobMid,QueenMobEnd : array[0..27] of integer;

Procedure CalcFullPst(var PstMid:integer;var PSTEnd:integer; var Board:TBoard);inline;
Function Evaluate(var Board:TBoard;ThreadID:integer;alpha:integer;beta:integer):integer;inline;

implementation
   uses uThread,uSearch;


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
Const
  P1Level=0.15;
  P2Level=0.25;
  PHLevel=0.7;
var
  range,range1,range2,p1,p2,ph : real;
  step1,step2 : real;
  full,half1,half2 : integer;
begin
  full:=Total;  // Общее количество точек
  Half2:=Full div 2;
  Half1:=Full-Half2; // Первая половинка может быть на один интервал длиннее для коней и ладей

  range:=Max-Min;  // Общий разлет
  range1:=(PHLevel-P2Level)*range; // Первый предел
  range2:=(1-PHLevel)*range; // Второй предел

  Step1:=range1/(half1-2); // шаг первой половины
  step2:=range2/(half2-1); // шаг второй половины
  p1:=Min+P1Level*Range;
  p2:=Min+P2Level*Range;
  ph:=Min+PhLevel*Range;
  If i=0 then result:=Round(Min) else
  If i=Total-1 then result:=Round(Max) else
    begin
      // первые две точки отдельно
      If I=1 then result:=Round(p1) else
      If I=2 then result:=Round(p2) else
      // Последующие - в интервали по шагам
      if i<=Half1
        then result:=round(p2+step1*(i-2))
        else result:=round(ph+step2*(i-half1));
    end;
end;

Procedure KingSafety(piesecol:integer;var Board:TBoard;var ExtraMid:TColor;var ExtraEnd:TColor;var KingAttackCount:Tcolor;var PAttacks:TAttacks;var Shield:TColor;var KingAttackWeight:TColor);inline;
Const
   MaxShield=100;
var
  Undefended,temp,temp1,Others:TBitBoard;
  bonus:integer;
  myQueen : boolean;
begin
  myQueen:=((Board.Pieses[queen] and Board.Occupancy[piesecol])<>0);
  bonus:=Shield[piesecol xor 1];
  if (myQueen) and (KingAttackCount[piesecol]>1) then
    begin
      If Shield[piesecol xor 1]>MaxShield
        then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+(MaxShield div 4)
        else KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+(Shield[piesecol xor 1] div 4);
      If (PAttacks[piesecol xor 1,king] and (not(PAttacks[piesecol,all] or Board.Occupancy[piesecol xor 1])))=0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+BadKing;
      Undefended:=PAttacks[piesecol,all] and PAttacks[piesecol xor 1,king] and (not(PAttacks[piesecol xor 1,pawn] or PAttacks[piesecol xor 1,bishop] or PAttacks[piesecol xor 1,knight] or PAttacks[piesecol xor 1,rook] or PAttacks[piesecol xor 1,queen]));
      If Undefended<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+UndefendedSquare*BitCount(Undefended);
      Undefended:=Undefended and PAttacks[piesecol,queen] and ( not Board.Occupancy[piesecol]);
      If (Undefended<>0) then
        begin
          Undefended:=Undefended and (PAttacks[piesecol,pawn] or PAttacks[piesecol,knight] or PAttacks[piesecol,bishop] or PAttacks[piesecol,rook] or PAttacks[piesecol,king]);
          If Undefended<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+QueenContactCheck;
        end;
      Undefended:= not (PAttacks[piesecol xor 1,all] or Board.Occupancy[piesecol]);
      Others:=not(PAttacks[piesecol xor 1,pawn] or (Board.Occupancy[piesecol] and Board.Pieses[pawn]));
      temp:=RookAttacksBB(Board.KingSq[piesecol xor 1],Board.AllPieses);
      temp1:=BishopAttacksBB(Board.KingSq[piesecol xor 1],Board.AllPieses);
        // Шахи ферзем
      If ((temp or temp1) and PAttacks[piesecol,queen] and Undefended)<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+QueenSafeCheck;
        // Шахи ладьей
      If (temp and PAttacks[piesecol,rook] and Undefended)<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+RookSafeCheck else
      If (temp and PAttacks[piesecol,rook] and Others)<>0 then
        begin
          ExtraMid[piesecol]:=ExtraMid[piesecol]+CheckMid;
          ExtraEnd[piesecol]:=ExtraEnd[piesecol]+CheckEnd;
        end;
        // Шахи слоном
      If (temp1 and PAttacks[piesecol,bishop] and Undefended)<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+BishopSafeCheck else
      If (temp1 and PAttacks[piesecol,bishop] and Others)<>0 then
        begin
          ExtraMid[piesecol]:=ExtraMid[piesecol]+CheckMid;
          ExtraEnd[piesecol]:=ExtraEnd[piesecol]+CheckEnd;
        end;
        // Шахи Конем
      If (KnightAttacksBB(Board.KingSq[piesecol xor 1]) and Undefended and PAttacks[piesecol,knight])<>0 then KingAttackWeight[piesecol]:=KingAttackWeight[piesecol]+KnightSafeCheck else
      If (KnightAttacksBB(Board.KingSq[piesecol xor 1]) and Others and PAttacks[piesecol,knight])<>0 then
        begin
          ExtraMid[piesecol]:=ExtraMid[piesecol]+CheckMid;
          ExtraEnd[piesecol]:=ExtraEnd[piesecol]+CheckEnd;
        end;
    end;
 If KingAttackCount[piesecol]>0 then  bonus:=bonus+((KingSafetyTable[KingAttackCount[piesecol]]*KingAttackWeight[piesecol]) div KingSafetyDivider);
 if (not myQueen) then bonus:=bonus div 2;
 ExtraMid[piesecol]:=ExtraMid[piesecol]+bonus;
end;

Procedure Threats(piesecol:integer;var Board:TBoard;var PAttacks:TAttacks;var ExtraMid:Tcolor;var ExtraEnd:TColor);inline;
var
  Weak,Temp,SafeThreats,Protect,Defended:TBitBoard;
  ind,sq,piese:integer;
begin
   // Фигуры противника атакованы нашими пешками
 Weak:=(Board.Occupancy[piesecol xor 1] and (not Board.Pieses[pawn])) and PAttacks[piesecol,pawn];
 if Weak<>0 then
   begin
     Temp:=(Board.Pieses[pawn] and Board.Occupancy[piesecol]) and ((not PAttacks[piesecol xor 1,all]) or PAttacks[piesecol,all]);
     If piesecol=white
        then SafeThreats:=(((temp and (not FilesBB[1])) shl 7) or ((temp and (not FilesBB[8])) shl 9)) and Weak
        else SafeThreats:=(((temp and (not FilesBB[1])) shr 9) or ((temp and (not FilesBB[8])) shr 7)) and Weak;
     If (Weak and (not SafeThreats))<>0 then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+ThreatHangingPawnMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+ThreatHangingPawnEnd;
       end;
     If SafeThreats<>0 then
       begin
         ind:=BitCount(SafeThreats);
         ExtraMid[piesecol]:=ExtraMid[piesecol]+ind*ThreatStrongPawnMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+ind*ThreatStrongPawnEnd;
       end;
   end;

  Protect:=PAttacks[piesecol xor 1,pawn] or (PAttacks[piesecol xor 1,all] and (not PAttacks[piesecol,all]));
  Defended:=(Board.Occupancy[piesecol xor 1] and (not Board.Pieses[pawn])) and Protect;
  Weak:=Board.Occupancy[piesecol xor 1] and (not Protect) and PAttacks[piesecol,all];

  If (Weak or Defended)<>0 then
    begin
      // Легкими фигурами
      Temp:=(Defended or Weak) and (PAttacks[piesecol,knight] or PAttacks[piesecol,bishop]);
      While temp<>0 do
          begin
            sq:=BitScanForward(Temp);
            temp:=temp and (temp-1);
            piese:=TypOfPiese[Board.Pos[sq]];
            ExtraMid[piesecol]:=ExtraMid[piesecol]+MinorThreatMid[piese];
            ExtraEnd[piesecol]:=ExtraEnd[piesecol]+MinorThreatEnd[piese];
          end;
      // Ладьями
      Temp:=((Board.Occupancy[piesecol xor 1] and Board.Pieses[queen]) or weak) and PAttacks[piesecol,rook];
      While temp<>0 do
          begin
            sq:=BitScanForward(Temp);
            temp:=temp and (temp-1);
            piese:=TypOfPiese[Board.Pos[sq]];
            ExtraMid[piesecol]:=ExtraMid[piesecol]+RookThreatMid[piese];
            ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookThreatEnd[piese];
          end;
       // Висячие фигуры (не защищенные под атакой)
      Temp:=Weak and (not PAttacks[piesecol xor 1,all]);
      if Temp<>0 then
       begin
        ind:=BitCount(Temp);
        ExtraMid[piesecol]:=ExtraMid[piesecol]+HangingMid*ind;
        ExtraEnd[piesecol]:=ExtraEnd[piesecol]+HangingEnd*ind;
       end;
       // Атаки Королей в эндшпиле
       Temp:=Weak and PAttacks[piesecol,king];
       If Temp<>0 then
         begin
          If (Temp and (Temp-1))<>0
           then ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KingThreatMulti
           else ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KingThreatOne;
         end;
    end;
end;

Procedure Space(piesecol:integer;var Board:TBoard;var PAttacks:TAttacks;var ExtraMid:Tcolor);inline;
var
   Safe,Behind:TBitBoard;
   bonus,weight:integer;
begin
  Safe:=SpaceBB[piesecol] and (not(Board.Pieses[pawn] and Board.Occupancy[piesecol])) and (not PAttacks[piesecol xor 1,pawn]);
  Behind:=Board.Pieses[pawn] and Board.Occupancy[piesecol];
  If piesecol=white then
    begin
     Behind:=Behind or (Behind shr 8);
     Behind:=Behind or (Behind shr 16);
    end else
    begin
     Behind:=Behind or (Behind shl 8);
     Behind:=Behind or (Behind shl 16);
    end;
  bonus:=BitCount(safe)+BitCount(safe and Behind);
  If bonus>16 then bonus:=16;
  weight:=BitCount(Board.Occupancy[piesecol]);
  Extramid[piesecol]:=ExtraMid[piesecol]+(bonus*weight*weight) div 50;
end;


Function Evaluate(var Board:TBoard;ThreadID:integer;alpha:integer;beta:integer):integer;inline;
var
  PawnIndex,MatIndex: int64;
  ScoreMid,ScoreEnd,score,WScale,BScale,Phase,PassMid,PassEnd,sq,ind,piesecol,x,y,Kx,Ky,lazy: integer;
  PAttacks : TAttacks;
  Temp,Att,temp1 : TBitBoard;
  KingAttackCount,KingAttackWeight,Shield,MobilityMid,MobilityEnd,ExtraMid,ExtraEnd,BishopNum:TColor;
  MobilityArea,KingZone,Pines,BlockedPawns : TcolorZone;
begin

  // Сначала считаем материальную оценку
     // Получаем индекс в таблице с посчитанными данными по материалу.
  MatIndex:=EvaluateMaterial(Board,ThreadID);
     // Если на доске эндшпиль, где нужна специальная оценочная функция то вызываем ее и возвращаемся
  if Threads[ThreadID].MatTable[MatIndex].EvalFunc<>0 then
    begin
      Result:=EvaluateSpecialEndgame(Threads[ThreadID].MatTable[MatIndex].EvalFunc,Threads[ThreadID].MatTable[MatIndex].EvalEnd,Board);
      exit;
    end;
    // Берем данные для инициализации
  ScoreMid:=Threads[ThreadID].MatTable[MatIndex].EvalMid;
  ScoreEnd:=Threads[ThreadID].MatTable[MatIndex].EvalEnd;
  WScale:=Threads[ThreadID].MatTable[MatIndex].WScale;
  BScale:=Threads[ThreadID].MatTable[MatIndex].BScale;
  Phase :=Threads[ThreadID].MatTable[MatIndex].phase;
     // Если на доске соотношение материала, требующее дополнительной оценки для получения мастабирующих коэффициентов - считаем и их
  if Threads[ThreadID].MatTable[MatIndex].ScaleFunc<>0 then GetSpecialScales(Threads[ThreadID].MatTable[MatIndex].ScaleFunc,Wscale,BScale,Board);
  // Оценка фигур
  ScoreMid:=ScoreMid+Board.PstMid;
  ScoreEnd:=ScoreEnd+Board.PstEnd;
  //Теперь оценка пешек
  PawnIndex:=EvaluatePawns(Board,ThreadId);
  ScoreMid:=ScoreMid+Threads[ThreadID].PawnTable[PawnIndex].ScoreMid;
  ScoreEnd:=ScoreEnd+Threads[ThreadID].PawnTable[PawnIndex].ScoreEnd;

  // Lazy exit
  If (beta-alpha=1) and (Wscale=ScaleNormal) and (Bscale=ScaleNormal) then
    begin
      lazy:=(ScoreMid+ScoreEnd) div 2;
      If Board.SideToMove=black then lazy:=-lazy;
      If Abs(lazy)>=LazyMargin then
        begin
          Result:=Lazy;
          exit;
        end;
    end;

  // Обнуляем счетчики безопасности
  KingAttackCount[white]:=0;KingAttackCount[black]:=0;
  KingAttackWeight[white]:=0;KingAttackWeight[black]:=0;
  MobilityMid[white]:=0;MobilityMid[black]:=0;
  MobilityEnd[white]:=0;MobilityEnd[black]:=0;
  ExtraMid[white]:=0; ExtraMid[black]:=0;
  ExtraEnd[white]:=0; ExtraEnd[black]:=0;
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
  BlockedPawns[white]:=Board.Pieses[pawn] and Board.Occupancy[white] and ((Board.AllPieses shr 8) or RanksBB[3] or RanksBB[2] );
  BlockedPawns[black]:=Board.Pieses[pawn] and Board.Occupancy[black] and ((Board.AllPieses shl 8) or RanksBB[6] or RanksBB[7] );
  // Устанавливаем поля где считается подвижность за обе стороны
  MobilityArea[white]:=not(BlockedPawns[white] or PAttacks[black,pawn] or Only[Board.KingSq[white]]);
  MobilityArea[black]:=not(BlockedPawns[black] or PAttacks[white,pawn] or Only[Board.KingSq[black]]);
  // Пешечный щит
  Shield[white]:=WkingSafety(PawnIndex,Board,ThreadID);
  Shield[black]:=BkingSafety(PawnIndex,Board,ThreadId);
  // Инициализация безопасности короля
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

  // Кони
  temp:=Board.Pieses[knight];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     If (Only[sq] and KingZone[piesecol])<>0 then ExtraMid[piesecol]:=ExtraMid[piesecol]+Guard[knight];
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
     MobilityMid[piesecol]:=MobilityMid[piesecol]+KnightMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+KnightMobEnd[ind];
     // Форпосты
     If ((ForwardBB[piesecol,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol xor 1])=0) and ((OutPostBB[piesecol] and Only[sq])<>0) then
       begin
         if ((PawnAttacks[piesecol xor 1,sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol])<>0) then
         begin
           ExtraMid[piesecol]:=ExtraMid[piesecol]+KnightOutPostProtectedMid;
           ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KnightOutPostProtectedEnd;
         end else
         begin
           ExtraMid[piesecol]:=ExtraMid[piesecol]+KnightOutPostMid;
           ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KnightOutPostEnd;
         end;
       end;
     // Легкая фигура за пешкой (своей или чужой)
     if (RelRank[piesecol,posy[sq]]<5) and ((Only[sq+step[piesecol]] and Board.Pieses[pawn])<>0) then ExtraMid[piesecol]:=ExtraMid[piesecol]+MinorBehindPawn;
     temp:=temp and (temp-1);
    end;
  // Слоны
  BishopNum[white]:=0;
  BishopNum[black]:=0;
  temp1:=(Board.Pieses[bishop] or Board.Pieses[queen]);
  temp:=Board.Pieses[bishop];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     If (Only[sq] and KingZone[piesecol])<>0 then ExtraMid[piesecol]:=ExtraMid[piesecol]+Guard[bishop];
     inc(BishopNum[piesecol]);
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
     MobilityMid[piesecol]:=MobilityMid[piesecol]+BishopMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+BishopMobEnd[ind];
     // Форпосты
     If ((ForwardBB[piesecol,sq] and IsolatedBB[sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol xor 1])=0) and ((OutPostBB[piesecol] and Only[sq])<>0)  then
       begin
         if ((PawnAttacks[piesecol xor 1,sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol])<>0) then
           begin
             ExtraMid[piesecol]:=ExtraMid[piesecol]+BishopOutPostProtectedMid;
             ExtraEnd[piesecol]:=ExtraEnd[piesecol]+BishopOutPostProtectedEnd;
           end else
           begin
             ExtraMid[piesecol]:=ExtraMid[piesecol]+BishopOutPostMid;
             ExtraEnd[piesecol]:=ExtraEnd[piesecol]+BishopOutPostEnd;
           end;
       end;
     // Блокированность пешками
     if (Only[sq] and LightSquaresBB)<>0 then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]-BishopPawnMid*((Threads[ThreadID].PawnTable[PawnIndex].BPawn shr BishopShift[piesecol,lig]) and 15);
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]-BishopPawnEnd*((Threads[ThreadID].PawnTable[PawnIndex].BPawn shr BishopShift[piesecol,lig]) and 15);
       end else
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]-BishopPawnMid*((Threads[ThreadID].PawnTable[PawnIndex].BPawn shr BishopShift[piesecol,dar]) and 15);
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]-BishopPawnEnd*((Threads[ThreadID].PawnTable[PawnIndex].BPawn shr BishopShift[piesecol,dar]) and 15);
       end;
     // Легкая фигура за пешкой (своей или чужой)
     if (RelRank[piesecol,posy[sq]]<5) and ((Only[sq+step[piesecol]] and Board.Pieses[pawn])<>0) then ExtraMid[piesecol]:=ExtraMid[piesecol]+MinorBehindPawn;
     temp:=temp and (temp-1);
    end;
  // Ладьи
  temp1:=(Board.Pieses[rook] or Board.Pieses[queen]);
  temp:=Board.Pieses[rook];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     If (Only[sq] and KingZone[piesecol])<>0 then ExtraMid[piesecol]:=ExtraMid[piesecol]+Guard[rook];
     x:=posx[sq];y:=posy[sq];
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
     MobilityMid[piesecol]:=MobilityMid[piesecol]+RookMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+RookMobEnd[ind];
     // Открытые и полуоткрытые вертикали
     If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[piesecol])=0 then
       begin
         If (FilesBB[x] and Board.Pieses[pawn] and Board.Occupancy[piesecol xor 1])=0 then
           begin
             ExtraMid[piesecol]:=ExtraMid[piesecol]+RookOpenMid;
             ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookOpenEnd;
           end else
           begin
             ExtraMid[piesecol]:=ExtraMid[piesecol]+RookHalfMid;
             ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookHalfEnd;
           end;
       end else
     // Запертая ладья
     if (ind<4) and ((Board.CastleRights and CastleCheck[piesecol])=0) then
       begin
         Kx:=Posx[Board.KingSq[piesecol]];
         Ky:=Posy[Board.KingSq[piesecol]];
         if (((Kx<5) and (x<Kx)) or ((Kx>=5) and (X>Kx))) and ((RelRank[piesecol,Ky]=1) or (Ky=Posy[sq])) then ExtraMid[piesecol]:=ExtraMid[piesecol]-RookTrapped;
       end;
     // Активная ладья в эндшпиле
     If (RelRank[piesecol,y]>4) and ((RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol xor 1])<>0) then ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookPawn*BitCount(RookFullAttacks[sq] and Board.Pieses[pawn] and Board.Occupancy[piesecol xor 1]);
     If (RelRank[piesecol,y]=7) and (RelRank[piesecol,Posy[Board.KingSq[piesecol xor 1]]]=8) and ((KingAttacks[Board.KingSq[piesecol xor 1]] and RanksBB[y] and (not Att))=0) then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+RookOn7Mid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookOn7End;
       end;
     temp:=temp and (temp-1);
    end;
  // Ферзи
  temp:=Board.Pieses[queen];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     If (Only[sq] and KingZone[piesecol])<>0 then ExtraMid[piesecol]:=ExtraMid[piesecol]+Guard[queen];
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
     MobilityMid[piesecol]:=MobilityMid[piesecol]+QueenMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+QueenMobEnd[ind];
     temp:=temp and (temp-1);
    end;
  // Оценка безопасности короля
  KingSafety(white,Board,ExtraMid,ExtraEnd,KingAttackCount,PAttacks,Shield,KingAttackWeight);
  KingSafety(black,Board,ExtraMid,ExtraEnd,KingAttackCount,PAttacks,Shield,KingAttackWeight);

  //  Если есть проходные - запускаем специальную оценочную и для них
  if Threads[ThreadID].PawnTable[PawnIndex].PassersBB<>0 then
    begin
      EvaluatePassers(PassMid,PassEnd,Threads[ThreadID].PawnTable[PawnIndex].PassersBB,Board,PAttacks[white,all],PAttacks[black,all]);
      ScoreMid:=ScoreMid+PassMid;
      ScoreEnd:=ScoreEnd+PassEnd;
    end;

  //  Угрозы
  Threats(white,Board,PAttacks,ExtraMid,ExtraEnd);
  Threats(black,Board,PAttacks,ExtraMid,ExtraEnd);

  // Собираем оценки
  ScoreMid:=ScoreMid+MobilityMid[white]-MobilityMid[black]+ExtraMid[white]-ExtraMid[black];
  ScoreEnd:=ScoreEnd+MobilityEnd[white]-MobilityEnd[black]+ExtraEnd[white]-ExtraEnd[black];
  if (Phase>PhaseSpace) then
    begin
      // В миттельшпиле оцениваем пространство
      Space(white,Board,PAttacks,ExtraMid);
      Space(black,Board,PAttacks,ExtraMid);
    end;

  // Некоторые особенные эндшпильные случаи
  if (Phase<=PhaseOpposit) then
    begin
      // Слоновый эндшпиль ( Возможные разноцветные слоны)
      If  (BishopNum[white]=1) and (BishopNum[black]=1) then OppositeBishops(WScale,BScale,Board);
      If (Abs(ScoreEnd)<300) then
        begin
          // Король успел под пешки противника
          If ((BScale=ScaleNormal) or (BScale=ScaleOnePawn)) and ((PasserBB[white,Board.KingSq[white]] and Board.Pieses[pawn] and Board.Occupancy[black])=(Board.Pieses[pawn] and Board.Occupancy[black])) then BScale:=BScale-ScaleHardWin;
          If ((WScale=ScaleNormal) or (WScale=ScaleOnePawn)) and ((PasserBB[black,Board.KingSq[black]] and Board.Pieses[pawn] and Board.Occupancy[white])=(Board.Pieses[pawn] and Board.Occupancy[white])) then WScale:=WScale-ScaleHardWin;
        end;
    end;

    
  // Итоговая оценка в зависимости от материала на доске
  score:=(ScoreMid*Phase+(MaxPhase-Phase)*scoreend) div MaxPhase;
  // Масштабируем оценку если надо
  if (score>0) and (WScale<>ScaleNormal) then score:=((score*WScale) div ScaleNormal) else
  if (score<0) and (BScale<>ScaleNormal) then score:=((score*BScale) div ScaleNormal);
  // Если ход черных то даем оценку с их стороны
  if Board.SideToMove=black
    then score:=-score+Tempo
    else score:=score+Tempo;
  
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
