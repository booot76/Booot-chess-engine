unit uEval;

interface
uses uBoard,uBitBoards,uMaterial,uPawn,uSort,umagic,uAttacks,uEndgame;

Type
  TAttacks = array[white..black,all..King] of TBitBoard;
  T6=array[pawn..king] of integer;
  T8=array[0..8] of integer;
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
   -9,-2, 4,20,20, 4,-2,-9,   //4
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

  KingAttackWeightsAll : array[pawn..King] of integer = (0,81,52,44,10,0);
  ShootValue=69;
  NoQueen=-873;
  QueenSafeCheck=780;
  RookSafeCheck=1080;
  BishopSafeCheck=635;
  KnightSafeCheck=790;
  StartValue=0;
  BadKingSquares=185;
  BishopDefender=-35;
  KnightDefender=-100;
  DangerPin=100;
  UnsafChecks=140;

  KnightMobMidMin=-30;KnightMobEndMin=-30;
  KnightMobMidMax=15; KnightMobENdMax=12;
  BishopMobMidMin=-20;BishopMobEndMin=-20;
  BishopMobMidMax=40;BishopMobEndMax=40;
  RookMobMidMin=-25; RookMobEndMin=-30;
  RookMobMidMax=25; RookMobEndMax=70;
  QueenMobMidMin=-15; QueenMobEndMin=-15;
  QueenMobMidMax=45; QueenMobEndMax=80;

  MinorGuardMid=3;
  MinorGuardEnd=3;

  KnightOutPostMid=20;
  KnightOutPostEnd=12;
  KnightOutPostReachedMid=10;
  KnightOutPostReachedEnd=6;

  BishopOutPostMid=12;
  BishopOutPostEnd=8;
  BishopActive=10;
  BishopPawnMid=1;
  BishopPawnEnd=3;
  MinorBehindPawn=6;
  LongDiagBishop=15;

  RookOpenMid=20;RookOpenEnd=10;
  RookHalfMid=8; RookHalfEnd=2;
  RookTrapped=35;
  RookActive=6;
  RookQueenMid=3;
  RookQueenEnd=5;

  ThreatStrongPawnMid=65;
  ThreatStrongPawnEnd=40;
  ThreatPawnPushMid=20;
  ThreatPawnPushEnd=15;


  MinorThreatMid:t6=( 2,12,15,35,20,0);
  MinorThreatEnd:t6=(12,15,20,50,65,0);
  RookThreatMid:t6=( 1,15,15, 0,20,0);
  RookThreatEnd:t6=( 5,16,25,20,15,15);

  KingThreatMid=10;
  KingThreatEnd=35;
  HangingMid=25;
  HangingEnd=12;
 
  Tempo=8;

var
   PiesePSTMid,PiesePstEnd : array[white..black,Pawn..King,a1..h8] of integer;
   KnightMobMid,KnightMobEnd : array[0..8] of integer;
   BishopMobMid,BishopMobEnd : array[0..13] of integer;
   RookMobMid,RookMobEnd : array[0..14] of integer;
   QueenMobMid,QueenMobEnd : array[0..27] of integer;

Procedure CalcFullPst(var PstMid:integer;var PSTEnd:integer; var Board:TBoard);inline;
Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer;inline;
Function EvaluateHCE(var Board:TBoard;ThreadID:integer;ply:integer):integer;inline;
implementation
   uses uThread,uSearch,Unn;


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

Procedure KingSafety(piesecol:integer;var Board:TBoard;var ExtraMid:TColor;var ExtraEnd:TColor;var KingAttackCount:Tcolor;var PAttacks:TAttacks;var Shield:TColor;var KingAttackWeight:TColor; var Attacked2:TColorZone;var KingAttackShoot:Tcolor;var KingZone:TcolorZone;var Pines:Tcolorzone); inline;
var
  weak,temp,temp1,safe,Qchecks,RChecks,BChecks,NChecks,UnsafeChecks:TBitBoard;
  count,bonus:integer;
  myQueen : integer;
begin
  myQueen:=BitCount(Board.Pieses[queen] and Board.Occupancy[piesecol]);
  bonus:=Shield[piesecol xor 1];
  Extramid[piesecol]:=Extramid[piesecol] + bonus;
  if  (KingAttackCount[piesecol]>1-myQueen) then
    begin
      UnsafeChecks:=0;
      //слабые поля для противника(атакованные нами, не защищенные им дважды и защищенное только королем или ферзем противника)
      weak:=PAttacks[piesecol,all] and (not Attacked2[piesecol xor 1]) and ((not PAttacks[piesecol xor 1, all]) or PAttacks[piesecol xor 1,king] or PAttacks[piesecol xor 1,queen]);
      // безопасные для нас поля для шахов: не занятые уже нашими фигурами, неатакованные противником вообще или слабые для противника поля, атакованные нами дважды
      safe:=(not Board.Occupancy[piesecol]) and ((not PAttacks[piesecol xor 1,all]) or (weak and Attacked2[piesecol]));
      // от чужого короля строим направления на поля откуда будут шахи
      temp:=(RookAttacksBB(Board.KingSq[piesecol xor 1],Board.AllPieses)) and (not Board.Occupancy[piesecol]);
      temp1:=(BishopAttacksBB(Board.KingSq[piesecol xor 1],Board.AllPieses)) and (not Board.Occupancy[piesecol]);
      count:=KingAttackCount[piesecol]*KingAttackWeight[piesecol]+StartValue;
        // Шахи ладьей
      RChecks:=(temp and PAttacks[piesecol,rook] and safe);
      If Rchecks<>0
       then count:=count+RookSafeCheck
       else UnsafeChecks:=UnsafeChecks or (temp and PAttacks[piesecol,rook]);
        // Шахи ферзем
      QChecks:=((temp or temp1) and PAttacks[piesecol,queen] and safe and (not Rchecks) and (not PAttacks[piesecol xor 1,queen]));
      If Qchecks<>0 then count:=count+QueenSafeCheck;
        // Шахи слоном
      BChecks:=(temp1 and PAttacks[piesecol,bishop] and safe and (not Qchecks));
      If Bchecks<>0
       then count:=count+BishopSafeCheck
       else UnsafeChecks:=UnsafeChecks or (temp1 and PAttacks[piesecol,bishop]);
        // Шахи Конем
      NChecks:=((KnightAttacksBB(Board.KingSq[piesecol xor 1]) and PAttacks[piesecol,knight] and safe)) and (not Board.Occupancy[piesecol]);
      If Nchecks<>0
       then count:=count+KnightSafeCheck
       else UnsafeChecks:=UnsafeChecks or (KnightAttacksBB(Board.KingSq[piesecol xor 1]) and PAttacks[piesecol,knight] and (not Board.Occupancy[piesecol]));
      count:=count+KingAttackShoot[piesecol]*ShootValue;
      count:=count+BadKingSquares*BitCount(weak and KingZone[piesecol xor 1]);
     // count:=count+(Shield[piesecol xor 1] div 4) ;
      count:=count+DangerPin*BitCount(Pines[piesecol xor 1]);
      If (Pattacks[piesecol xor 1,knight] and PAttacks[piesecol xor 1,king])<>0 then count:=count+KnightDefender;
      If (Pattacks[piesecol xor 1,bishop] and PAttacks[piesecol xor 1,king])<>0 then count:=count+BishopDefender;
      If myQueen=0 then count:=count+NoQueen;
      count:=count+BitCount(UnSafeChecks)*UnsafChecks;
      if count>100 then
        begin
          ExtraMid[piesecol]:=ExtraMid[piesecol]+((count*count) div 10000);
          ExtraEnd[piesecol]:=ExtraEnd[piesecol]+(count div 50);
        end;
    end;
end;

Procedure Threats(piesecol:integer;var Board:TBoard;var PAttacks:TAttacks;var ExtraMid:Tcolor;var ExtraEnd:TColor;var Attacked2:TColorZone);inline;
var
  Weak,Temp,Safe,SafeThreats,Protect,Defended,nonPawns:TBitBoard;
  ind,sq,piese:integer;
begin
 nonPawns:=Board.Occupancy[piesecol xor 1] and (not Board.Pieses[pawn]);
 Protect:=PAttacks[piesecol xor 1,pawn] or (Attacked2[piesecol xor 1] and (not Attacked2[piesecol]));
 Defended:=nonPawns and Protect;
 weak:=Board.Occupancy[piesecol xor 1] and (not Protect) and (PAttacks[piesecol,all]);
 if (Defended or weak)<>0 then
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
      Temp:=weak and PAttacks[piesecol,rook];
      While temp<>0 do
          begin
            sq:=BitScanForward(Temp);
            temp:=temp and (temp-1);
            piese:=TypOfPiese[Board.Pos[sq]];
            ExtraMid[piesecol]:=ExtraMid[piesecol]+RookThreatMid[piese];
            ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookThreatEnd[piese];
          end;
      // Атаки Королей
       Temp:=Weak and PAttacks[piesecol,king];
       If Temp<>0 then
         begin
           ExtraMid[piesecol]:=ExtraMid[piesecol]+KingThreatMid;
           ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KingThreatEnd;
         end;
      // Висячие фигуры
      Temp:=((not PAttacks[piesecol xor 1,all]) or (nonPawns and Attacked2[piesecol])) and weak;
      if Temp<>0 then
       begin
        ind:=BitCount(Temp);
        ExtraMid[piesecol]:=ExtraMid[piesecol]+HangingMid*ind;
        ExtraEnd[piesecol]:=ExtraEnd[piesecol]+HangingEnd*ind;
       end;
   end;
   Safe:=(not PAttacks[piesecol xor 1,all]) or Pattacks[piesecol,all];
   Temp:=Board.Pieses[pawn] and Board.Occupancy[piesecol] and safe;
   If piesecol=white
        then SafeThreats:=(((temp and (not FilesBB[1])) shl 7) or ((temp and (not FilesBB[8])) shl 9)) and nonPawns
        else SafeThreats:=(((temp and (not FilesBB[1])) shr 9) or ((temp and (not FilesBB[8])) shr 7)) and nonPawns;
   If SafeThreats<>0 then
       begin
         ind:=BitCount(SafeThreats);
         ExtraMid[piesecol]:=ExtraMid[piesecol]+ind*ThreatStrongPawnMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+ind*ThreatStrongPawnEnd;
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
  bonus:=BitCount(safe)+BitCount(safe and Behind and (not PAttacks[piesecol xor 1,all]));
  weight:=BitCount(Board.Occupancy[piesecol])-1;
  Extramid[piesecol]:=ExtraMid[piesecol]+(bonus*weight*weight) div 50;
end;


Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer; inline;
var
   evalfun,score,sf,wtm : integer;
begin
  // Быстро оцениваем специальные эндшпили на доске
  evalfun:=EvalShort(Board,ThreadId);
  If (evalfun=f_knnk) or (evalfun=f_kbnk) or (evalfun=f_kpk) then
    begin
      Result:=EvaluateSpecialEndgame(EvalFun,QueenValueMid,Board);
      exit;
    end;
  score:=ForwardPass(Board.SideToMove,Threads[ThreadID].Pass[ply]);
  if score>=0
    then wtm:=Board.SideToMove
    else wtm:=Board.SideToMove xor 1;
  If evalfun=f_kbpskw then
    begin
      sf:=64;
      KBPSKw(sf,Board);
      if sf<>64 then
        begin
          if ((Board.SideToMove=white) and (score>0)) or ((Board.SideToMove=black) and (score<0)) then score:=(score*sf) div 64;
        end;
    end;
  If evalfun=f_kbpskb then
    begin
      sf:=64;
      KBPSKb(sf,Board);
       if sf<>64 then
        begin
          if ((Board.SideToMove=black) and (score>0)) or ((Board.SideToMove=white) and (score<0)) then score:=(score*sf) div 64;
        end;
    end;
   if ((Board.Pieses[pawn] and Board.Occupancy[wtm])=0) and (((Board.NonPawnMat[wtm]-Board.NonPawnMat[wtm xor 1])<=PieseTYpValue[bishop]) or (Board.NonPawnMat[wtm]=2*PiesetypValue[knight])) then
    begin
      if Board.NonPawnMat[wtm]<=PieseTYpValue[queen]
        then score:=score div 4
        else score:=score div 2;
    end;
  Result:=score;
end;

Function EvaluateHCE(var Board:TBoard;ThreadID:integer;ply:integer):integer; inline;
var
  PawnIndex,MatIndex: int64;
  ScoreMid,ScoreEnd,score,WScale,BScale,Phase,PassMid,PassEnd,sq,ind,piesecol,x,Kx,Ky,binc,sf,strongside: integer;
  PAttacks : TAttacks;
  Temp,Att,temp1,WPLeft,WPRight,WDBLPAwn,BPLeft,BPRight,BDBLPawn,BlockedBB,Att2 : TBitBoard;
  KingAttackCount,KingAttackWeight,KingAttackShoot,Shield,MobilityMid,MobilityEnd,ExtraMid,ExtraEnd,BishopNum:TColor;
  MobilityArea,KingZone,Pines,BlockedPawns,Attacked2,OutBB : TcolorZone;
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
  // Обнуляем счетчики безопасности
  KingAttackCount[white]:=0;KingAttackCount[black]:=0;
  KingAttackWeight[white]:=0;KingAttackWeight[black]:=0;
  KingAttackShoot[white]:=0;KingAttackShoot[black]:=0;
  MobilityMid[white]:=0;MobilityMid[black]:=0;
  MobilityEnd[white]:=0;MobilityEnd[black]:=0;
  ExtraMid[white]:=0; ExtraMid[black]:=0;
  ExtraEnd[white]:=0; ExtraEnd[black]:=0;
  // Инициализируем битборды атак фигур
  PAttacks[white,knight]:=0; PAttacks[black,knight]:=0;
  PAttacks[white,bishop]:=0; PAttacks[black,bishop]:=0;
  PAttacks[white,rook]:=0; PAttacks[black,rook]:=0;
  PAttacks[white,queen]:=0; PAttacks[black,queen]:=0;
  //Битборды королей и пешек вычисляем сразу
  PAttacks[white,king]:=KingAttacks[Board.KingSq[white]];
  PAttacks[black,king]:=KingAttacks[Board.KingSq[black]];
  // белые пешки
  temp:=Board.Pieses[pawn] and Board.Occupancy[white];
  WPLeft:=((temp and (not FilesBB[1])) shl 7);WPRight:=((temp and (not FilesBB[8])) shl 9);
  PAttacks[white,pawn]:=WPLeft or WPRight;
  WDBLPawn:=WPLeft and WPRight;
  // черные пешки
  temp:=Board.Pieses[pawn] and Board.Occupancy[black];
  BPLeft:=((temp and (not FilesBB[1])) shr 9);
  BPRight:=((temp and (not FilesBB[8])) shr 7);
  PAttacks[black,pawn]:=BPLeft or BPRight;
  BDBLPawn:=BPLeft and BPRight;
  // инициализация битбордов атак
  PAttacks[white,all]:=PAttacks[white,king] or PAttacks[white,pawn];
  PAttacks[black,all]:=PAttacks[black,king] or PAttacks[black,pawn];
  // нициализация двойной атаки
  Attacked2[white]:=WDBLPawn or (PAttacks[white,king] and PAttacks[white,pawn]);
  Attacked2[black]:=BDBLPawn or (PAttacks[black,king] and PAttacks[black,pawn]);

  // Связки
  Pines[white]:=FindPinners(white,white,Board);
  Pines[black]:=FindPinners(black,black,Board);
  // Блокированные пешки и пешки на 2-3 горизонтали
  BlockedPawns[white]:=Board.Pieses[pawn] and Board.Occupancy[white] and ((Board.AllPieses shr 8) or RanksBB[3] or RanksBB[2] );
  BlockedPawns[black]:=Board.Pieses[pawn] and Board.Occupancy[black] and ((Board.AllPieses shl 8) or RanksBB[6] or RanksBB[7] );
  // Устанавливаем поля где считается подвижность за обе стороны
  MobilityArea[white]:=not(Pines[white] or BlockedPawns[white] or PAttacks[black,pawn] or Only[Board.KingSq[white]] or (Board.Pieses[queen] and Board.Occupancy[white]));
  MobilityArea[black]:=not(Pines[black] or BlockedPawns[black] or PAttacks[white,pawn] or Only[Board.KingSq[black]] or (Board.Pieses[queen] and Board.Occupancy[black]));
  // Пешечный щит
  Shield[white]:=WkingSafety(PawnIndex,Board,ThreadID);
  Shield[black]:=BkingSafety(PawnIndex,Board,ThreadId);
  // Инициализация безопасности короля
  KingZone[black]:=PAttacks[black,king] or Only[Board.KingSq[black]];
  If Posy[Board.KingSq[black]]=8 then KingZone[black]:=KingZone[black] or (KingZone[black] shr 8);
  If Posx[Board.KingSq[black]]=1 then KingZone[black]:=KingZone[black] or (KingZone[black] shl 1);
  If Posx[Board.KingSq[black]]=8 then KingZone[black]:=KingZone[black] or (KingZone[black] shr 1);

  KingZone[white]:=PAttacks[white,king] or Only[Board.KingSq[white]];
  If Posy[Board.KingSq[white]]=1 then KingZone[white]:=KingZone[white] or (KingZone[white] shl 8);
  If Posx[Board.KingSq[white]]=1 then KingZone[white]:=KingZone[white] or (KingZone[white] shl 1);
  If Posx[Board.KingSq[white]]=8 then KingZone[white]:=KingZone[white] or (KingZone[white] shr 1);

  If (PAttacks[white,pawn] and KingZone[black])<>0 then  KingAttackCount[white]:=KingAttackCount[white] + BitCount(PAttacks[white,pawn] and KingZone[black]);
  If (PAttacks[black,pawn] and KingZone[white])<>0 then  KingAttackCount[black]:=KingAttackCount[black] + BitCount(PAttacks[black,pawn] and KingZone[white]);

  KingZone[white]:=KingZone[white] and (not WDBLPawn);
  KingZone[black]:=KingZone[black] and (not BDBLPawn);

  OutBB[white]:=OutPostBB[white] and (PAttacks[white,pawn] or (Board.Pieses[pawn] shr 8)) and (not Threads[ThreadID].PawnTable[PawnIndex].BSpan);
  OutBB[black]:=OutPostBB[white] and (PAttacks[black,pawn] or (Board.Pieses[pawn] shl 8)) and (not Threads[ThreadID].PawnTable[PawnIndex].WSpan);
  // Кони
  temp:=Board.Pieses[knight];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     // Атакованные поля
     att:=KnightAttacks[sq];
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     Attacked2[piesecol]:=Attacked2[piesecol] or (att and PAttacks[piesecol,all]);
     PAttacks[piesecol,knight]:=PAttacks[piesecol,knight] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         KingAttackShoot[piesecol]:=KingAttackShoot[piesecol] + BitCount(Att and PAttacks[piesecol xor 1,king]);
         inc(KingAttackCount[piesecol]);
         KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[knight];
       end;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     MobilityMid[piesecol]:=MobilityMid[piesecol]+KnightMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+KnightMobEnd[ind];
    // Форпосты
     if (OutBB[piesecol]  and Only[sq])<>0 then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+KnightOutPostMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KnightOutPostEnd;
       end else
     if ((OutBB[piesecol] and Att and (not Board.Occupancy[piesecol]))<>0) then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+KnightOutPostReachedMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+KnightOutPostReachedEnd;
       end;
     // Легкая фигура за пешкой (своей или чужой)
     if ((Only[sq+step[piesecol]] and Board.Pieses[pawn])<>0) then ExtraMid[piesecol]:=ExtraMid[piesecol]+MinorBehindPawn;
     // Фигура далеко от короля
     ExtraMid[piesecol]:=ExtraMid[piesecol] - MinorGuardMid*SquareDist[sq,Board.KingSq[piesecol]];
     ExtraEnd[piesecol]:=ExtraEnd[piesecol] - MinorGuardEnd*SquareDist[sq,Board.KingSq[piesecol]];
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
     inc(BishopNum[piesecol]);
     // Атакованные поля
     att:=BishopAttacksBB(sq,Board.AllPieses and (not(temp1 and Board.Occupancy[piesecol])));
     Att2:=BishopAttacksBB(sq,Board.Pieses[pawn]);
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     Attacked2[piesecol]:=Attacked2[piesecol] or (att and PAttacks[piesecol,all]);
     PAttacks[piesecol,bishop]:=PAttacks[piesecol,bishop] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         KingAttackShoot[piesecol]:=KingAttackShoot[piesecol] + BitCount(Att and PAttacks[piesecol xor 1,king]);
         inc(KingAttackCount[piesecol]);
         KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[bishop];
       end else
     if (Att2 and KingZone[piesecol xor 1])<>0 then ExtraMid[piesecol]:=ExtraMid[piesecol]+BishopActive;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     MobilityMid[piesecol]:=MobilityMid[piesecol]+BishopMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+BishopMobEnd[ind];
     // Форпосты
     if (OutBB[piesecol]  and Only[sq])<>0 then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+BishopOutPostMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+BishopOutPostEnd;
       end;
     // Блокированность пешками
     If (Only[sq] and PAttacks[piesecol,pawn])<>0
      then binc:=0
      else binc:=1;
     If piesecol = white
        then BlockedBB:=(Board.Pieses[pawn] and Board.Occupancy[piesecol]) and (Board.AllPieses shr 8)
        else BlockedBB:=(Board.Pieses[pawn] and Board.Occupancy[piesecol]) and (Board.AllPieses shl 8);
     If (Only[sq] and DarkSquaresBB)<>0
       then ind:=BitCOunt(Board.Pieses[pawn] and Board.Occupancy[piesecol] and DarkSquaresBB)*(binc+BitCount(BishopBlockedBB[piesecol] and BlockedBB))
       else ind:=BitCOunt(Board.Pieses[pawn] and Board.Occupancy[piesecol] and LightSquaresBB)*(binc+BitCount(BishopBlockedBB[piesecol] and BlockedBB));
     ExtraMid[piesecol]:=ExtraMid[piesecol] - BishopPawnMid*ind;
     ExtraEnd[piesecol]:=ExtraEnd[piesecol] - BishopPawnEnd*ind;
     BlockedBB:=Att2 and CenterBB;
     If BitCOunt(BlockedBB)>1 then ExtraMid[piesecol]:=ExtraMid[piesecol] +LongDiagBishop;
     // Легкая фигура за пешкой (своей или чужой)
     if ((Only[sq+step[piesecol]] and Board.Pieses[pawn])<>0) then ExtraMid[piesecol]:=ExtraMid[piesecol]+MinorBehindPawn;
     // Фигура далеко от короля
     ExtraMid[piesecol]:=ExtraMid[piesecol] - MinorGuardMid*SquareDist[sq,Board.KingSq[piesecol]];
     ExtraEnd[piesecol]:=ExtraEnd[piesecol] - MinorGuardEnd*SquareDist[sq,Board.KingSq[piesecol]];
     temp:=temp and (temp-1);
    end;
  // Ладьи
  temp1:=(Board.Pieses[rook] or Board.Pieses[queen]);
  temp:=Board.Pieses[rook];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     piesecol:=PieseColor[Board.Pos[sq]];
     x:=posx[sq];
     If (FilesBB[x] and Board.Pieses[queen])<>0 then
       begin
         ExtraMid[piesecol]:=ExtraMid[piesecol]+RookQueenMid;
         ExtraEnd[piesecol]:=ExtraEnd[piesecol]+RookQueenEnd;
       end;
     // Атакованные поля
     att:=RookAttacksBB(sq,Board.AllPieses and (not(temp1 and Board.Occupancy[piesecol])));
     If (Only[sq] and Pines[piesecol])<>0 then Att:=Att and FullLine[sq,Board.KingSq[piesecol]];
     Attacked2[piesecol]:=Attacked2[piesecol] or (att and PAttacks[piesecol,all]);
     PAttacks[piesecol,rook]:=PAttacks[piesecol,rook] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         KingAttackShoot[piesecol]:=KingAttackShoot[piesecol] + BitCount(Att and PAttacks[piesecol xor 1,king]);
         inc(KingAttackCount[piesecol]);
         KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[rook];
       end else
     if (FilesBB[x] and KingZone[piesecol xor 1])<>0
       then ExtraMid[piesecol]:=ExtraMid[piesecol]+RookActive;
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
     Attacked2[piesecol]:=Attacked2[piesecol] or (att and PAttacks[piesecol,all]);
     PAttacks[piesecol,queen]:=PAttacks[piesecol,queen] or Att;
     PAttacks[piesecol,all]:=PAttacks[piesecol,all] or Att;
     // Атака на неприятельского короля
     if (Att and KingZone[piesecol xor 1])<>0 then
       begin
         KingAttackShoot[piesecol]:=KingAttackShoot[piesecol] + BitCount(Att and PAttacks[piesecol xor 1,king]);
         inc(KingAttackCount[piesecol]);
         KingAttackWeight[piesecol]:=KingAttackWeight[piesecol] + KingAttackWeightsAll[queen];
       end;
     // Подвижность
     ind:=BitCount(Att and MobilityArea[piesecol]);
     MobilityMid[piesecol]:=MobilityMid[piesecol]+QueenMobMid[ind];
     MobilityEnd[piesecol]:=MobilityEnd[piesecol]+QueenMobEnd[ind];
     temp:=temp and (temp-1);
    end;
  // Оценка безопасности короля
  KingSafety(white,Board,ExtraMid,ExtraEnd,KingAttackCount,PAttacks,Shield,KingAttackWeight,Attacked2,KingAttackShoot,KingZone,Pines);
  KingSafety(black,Board,ExtraMid,ExtraEnd,KingAttackCount,PAttacks,Shield,KingAttackWeight,Attacked2,KingAttackShoot,KingZone,Pines);

  //  Если есть проходные - запускаем специальную оценочную и для них
  if Threads[ThreadID].PawnTable[PawnIndex].PassersBB<>0 then
    begin
      EvaluatePassers(PassMid,PassEnd,Threads[ThreadID].PawnTable[PawnIndex].PassersBB,Board,PAttacks[white,all],PAttacks[black,all]);
      ScoreMid:=ScoreMid+PassMid;
      ScoreEnd:=ScoreEnd+PassEnd;
    end;

  //  Угрозы
  Threats(white,Board,PAttacks,ExtraMid,ExtraEnd,Attacked2);
  Threats(black,Board,PAttacks,ExtraMid,ExtraEnd,Attacked2);

  // Собираем оценки
  ScoreMid:=ScoreMid+MobilityMid[white]-MobilityMid[black]+ExtraMid[white]-ExtraMid[black];
  ScoreEnd:=ScoreEnd+MobilityEnd[white]-MobilityEnd[black]+ExtraEnd[white]-ExtraEnd[black];
  if (Board.NonPawnMat[white]+Board.NonPawnMat[black]>PhaseSpace) then
    begin
      // В миттельшпиле оцениваем пространство
      Space(white,Board,PAttacks,ExtraMid);
      Space(black,Board,PAttacks,ExtraMid);
    end;
 
  if ScoreEnd>0 then
    begin
      sf:=Wscale;
      strongside:=white;
    end else
    begin
      sf:=Bscale;
      strongside:=black;
    end;
  // Некоторые особенные эндшпильные случаи
  if sf=ScaleNormal then
    begin
     // Разноцвет
     If  (BishopNum[white]=1) and (BishopNum[black]=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then
       begin
         if (Board.NonPawnMat[white]=BishopValueMid) and (Board.NonPawnMat[black]=BishopValueMid)
           then sf:=18+4*BitCount(Threads[ThreadID].PawnTable[PawnIndex].PassersBB and Board.Occupancy[strongside])
           else sf:=22+3*BitCount(Board.Occupancy[strongside]);
       end else sf:=36+7*BitCount(Board.Pieses[pawn] and Board.Occupancy[strongside]);
     if sf>ScaleNormal then sf:=ScaleNormal;
    end;

    // Итоговая оценка в зависимости от материала на доске
  if sf<>ScaleNormal then ScoreEnd:=ScoreEnd*sf div ScaleNormal;
  score:=(ScoreMid*Phase+(MaxPhase-Phase)*ScoreEnd) div MaxPhase;
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
