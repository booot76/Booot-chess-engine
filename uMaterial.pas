unit uMaterial;
interface
uses uBoard,uBitBoards,uEndgame,uThread;
Type
   TMatEntry = record
                 MatKey    : int64;
                 EvalMid   : smallint;
                 EvalEnd   : smallint;
                 WScale    : byte;
                 BScale    : byte;
                 EvalFunc  : byte;
                 ScaleFunc : byte;
                 phase     : byte;
               end;
Const
   PawnValueMid=80;    PawnValueEnd=100;
   KnightValueMid=320; KnightValueEnd=350;
   BishopValueMid=325; BishopValueEnd=355;
   RookValueMid=495;   RookValueEnd=530;
   QueenValueMid=985;  QueenValueEnd=1040;
   DoubleBishopMid=40; DoubleBishopEnd=50;
   DoubleNoMinorMid=5; DoubleNoMinorEnd=10;
   MinorBonusMid=20;   MinorBonusEnd=5;
   KnightPawnMid=0;    KnightPawnEnd=5;
   RookPawnMid=5;      RookPawnEnd=0;
   DoubleRookMid=15;   DoubleRookEnd=30;

   PieseTypValue : array[Pawn..Queen] of integer = (0,KnightValueMid,BishopValueMid,RookValueMid,QueenValueMid); // ��� ���������� ������ make ����������� ��������� �� �����. ������� �������� ����� =0
   ScalePawn=80;
   ScaleNormal=64;
   ScaleOnePawn=48;
   ScaleOneFlang=50;
   ScaleOpposit=32;
   ScaleHardWin=8;
   ScaleDrawish=4;
   ScaleDraw=0;

   PhaseMinor=1;
   PhaseRook=3;
   PhaseQueen=6;
   MaxPhase=32;
   PhaseOpposit=2*PhaseMinor+2*PhaseQueen+2*PhaseRook;
var
   MatTable : array of TMatEntry;
   MatTableMask : int64;


Procedure InitMatTable(SizeMB:integer);
Procedure CalcImbalance(var ScoreMid:integer;var ScoreEnd:integer;wp,bp,wn,bn,wb,bb,wr,br,wq,bq:integer);inline;
Function EvaluateMaterial(var Board:TBoard):Cardinal; inline;

implementation

Procedure InitMatTable(SizeMB:integer);
// �� ����� - ����� ���������� �������� ����, ����������� �� ��������
var
   i,MatTableSize : int64;
begin
  MatTableSize:=SizeMb;
  MatTableSize:=(MatTableSize * 1024 * 1024) div (32*16); {����� 1/32 ���� ����. ������ ������ ����� 16}
  MatTableMask:=MatTableSize-1;
  SetLength(MatTable,0);
  SetLength(MatTable,MatTableSize);
  for i:=0 to MatTableMask do
    begin
      MatTable[i].MatKey:=0;
      MatTable[i].EvalMid:=0;
      MatTable[i].EvalEnd:=0;
      MatTable[i].WScale:=0;
      MatTable[i].BScale:=0;
      MatTable[i].EvalFunc:=0;
      MatTable[i].ScaleFunc:=0;
      MatTable[i].phase:=0;
    end;
end;

Procedure CalcImbalance(var ScoreMid:integer;var ScoreEnd:integer;wp,bp,wn,bn,wb,bb,wr,br,wq,bq:integer);inline;
// ������� ������������ ������ ��� ������ ���������� ����������� ���������
begin
  ScoreMid:=(wp-bp)*PawnValueMid+(wn-bn)*KnightValueMid+(wp-5)*wn*KnightPawnMid-(bp-5)*bn*KnightPawnMid+(wb-bb)*BishopValueMid+(wr-br)*RookValueMid-(wp-5)*wr*RookPawnMid+(bp-5)*br*RookPawnMid+(wq-bq)*QueenValueMid;
  ScoreEnd:=(wp-bp)*PawnValueEnd+(wn-bn)*KnightValueEnd+(wp-5)*wn*KnightPawnEnd-(bp-5)*bn*KnightPawnEnd+(wb-bb)*BishopValueEnd+(wr-br)*RookValueEnd-(wp-5)*wr*RookPawnEnd+(bp-5)*br*RookPawnEnd+(wq-bq)*QueenValueEnd;
  if wb>1 then
    begin
      ScoreMid:=ScoreMid+DoubleBishopMid;
      ScoreEnd:=ScoreEnd+DoubleBishopEnd;
      if (bn+bb=0) then
        begin
          ScoreMid:=ScoreMid+DoubleNoMinorMid;
          ScoreEnd:=ScoreEnd+DoubleNoMinorEnd;
        end;
    end;
  if bb>1 then
    begin
      ScoreMid:=ScoreMid-DoubleBishopMid;
      ScoreEnd:=ScoreEnd-DoubleBishopEnd;
      if (wn+wb=0) then
        begin
          ScoreMid:=ScoreMid-DoubleNoMinorMid;
          ScoreEnd:=ScoreEnd-DoubleNoMinorEnd;
        end;
    end;
  if (wn+wb>bn+bb+1) then
    begin
      ScoreMid:=ScoreMid+MinorBonusMid;
      ScoreEnd:=ScoreEnd+MinorBonusEnd;
    end else
  if (bn+bb>wn+wb+1) then
    begin
      ScoreMid:=ScoreMid-MinorBonusMid;
      ScoreEnd:=ScoreEnd-MinorBonusEnd;
    end;
  if wr>1 then
    begin
      ScoreMid:=ScoreMid-DoubleRookMid;
      ScoreEnd:=ScoreEnd-DoubleRookEnd;
    end;
  if br>1 then
    begin
      ScoreMid:=ScoreMid+DoubleRookMid;
      ScoreEnd:=ScoreEnd+DoubleRookEnd;
    end;
end;
Function EvaluateMaterial(var Board:TBoard):Cardinal; inline;
// ������ ��������� �� �����. ���������� ������ �� ������ � ������������ � ������������ ����������.
var
  ScoreMid,ScoreEnd,Wscale,BScale,NPW,NPB,phase,evalfun,scalefun : integer;
  wp,bp,wn,bn,wb,bb,wr,br,wq,bq : integer;
begin
  result:=Board.MatKey and MatTableMask;
  // ��������� �� ������� �� �� ��� ����������� ��������� �����?
  If Board.MatKey=Mattable[result].MatKey then exit;
  // ��� - ������� ���������
  wp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[white]);
  bp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[black]);
  wn:=BitCount(Board.Pieses[Knight] and Board.Occupancy[white]);
  bn:=BitCount(Board.Pieses[Knight] and Board.Occupancy[black]);
  wb:=BitCount(Board.Pieses[Bishop] and Board.Occupancy[white]);
  bb:=BitCount(Board.Pieses[Bishop] and Board.Occupancy[black]);
  wr:=BitCount(Board.Pieses[Rook]   and Board.Occupancy[white]);
  br:=BitCount(Board.Pieses[Rook]   and Board.Occupancy[black]);
  wq:=BitCount(Board.Pieses[Queen]  and Board.Occupancy[white]);
  bq:=BitCount(Board.Pieses[Queen]  and Board.Occupancy[black]);
  NPW:=Board.NonPawnMat[white];
  NPB:=Board.NonPawnMat[black];
  // ������� ������� �������������� ������������
  Wscale:=ScaleNormal;
  BScale:=ScaleNormal;
  if wp=0 then
    begin
      // � ����� ��� �����
      if NPW-NPB<=PieseTypValue[Bishop] then   // ���� � ����� �� ����� ������ ������ ������������ �� ������� ����� ���� ��������� ��� ����������. ������ ������ - KBBKN  ������� ���� �� �������� ��� ��� ���� ���� ������ ����  �����!
        begin
          if NPW<PieseTypValue[Rook] then Wscale:=ScaleDraw else   // ��* KNK* KBK*
            if NPB<=PieseTypValue[Bishop]
              then WScale:=ScaleDrawish   // KRKB* KRKN* KBNKB* etc
              else WScale:=ScaleHardWin;  // KRBKR*  etc.
        end;
    end else
  if wp=1 then
    begin
      // ���� �������� ��������� �����  �� ������� ���� ����� ���� �������
      if NPW-NPB<=PieseTypValue[Bishop] then WScale:=ScaleOnePawn;
    end;
  if bp=0 then
    begin
      // � ������ ��� �����
      if NPB-NPW<=PieseTypValue[Bishop] then   // ���� � ������ �� ����� ������ ������ ������������ �� ������� ����� ���� ��������� ��� ����������. ������ ������ - KBBKN  ������� ���� �� �������� ��� ��� ���� ���� ������ ���� ������ �����!
        begin
          if NPB<PieseTypValue[Rook] then Bscale:=ScaleDraw else   // ��* KNK* KBK*
            if NPW<=PieseTypValue[Bishop]
              then BScale:=ScaleDrawish   // KRKB* KRKN* KBNKB* etc
              else BScale:=ScaleHardWin;  // KRBKR*  etc.
        end;
    end else
  if bp=1 then
    begin
      // ���� �������� ��������� �����  �� ������� ���� ����� ���� �������
      if NPB-NPW<=PieseTypValue[Bishop] then BScale:=ScaleOnePawn;
    end;
  // ������ ������� ��������
  CalcImbalance(ScoreMid,ScoreEnd,wp,bp,wn,bn,wb,bb,wr,br,wq,bq);
  // ������� ����
  phase:=(wn+bn+wb+bb)*PhaseMinor+(wr+br)*PhaseRook+(wq+bq)*PhaseQueen;
  if phase>MaxPhase then phase:=MaxPhase;
  evalfun:=0;scalefun:=0;
  // ���� ��������� ������� ������� ������ � ���������������
  if wp+bp=0 then  // ����������� ��������
    begin
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[knight]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[knight]))) then evalfun:=f_knnk else
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[bishop]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[bishop]))) then evalfun:=f_kbnk else
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]>=PieseTypValue[rook])) or  ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]>=PieseTypValue[rook])) then evalfun:=f_kxk else  // ��� ��������� ������
     If ((Board.NonPawnMat[white]=PieseTypValue[rook]) and (Board.NonPawnMat[black]=PieseTypValue[queen])) or ((Board.NonPawnMat[white]=PieseTypValue[queen]) and (Board.NonPawnMat[black]=PieseTypValue[rook])) then evalfun:=f_kqkr;
    end;
  if (NPW=0) and (NPB=0) then // �������� ��������
    begin
     if (wp+bp)=1 then evalfun:=f_KPK else
       begin
        If Wscale=ScaleNormal then WScale:=ScalePawn;
        If Bscale=ScaleNormal then BScale:=ScalePawn;
        if bp=0 then scalefun:=F_KPSKW;
        if wp=0 then scalefun:=F_KPSKB;
       end;
    end;
  if (NPW=PieseTypValue[bishop]) and (NPB=0) and (wp>0) then scalefun:=F_KBPSKW;
  if (NPB=PieseTypValue[bishop]) and (NPW=0) and (bp>0) then scalefun:=F_KBPSKB;
  If (NPW=PieseTypValue[rook]) and (NPB=0) and (wp=0) and (bp=1) then evalfun:=f_KRKP;
  If (NPB=PieseTypValue[rook]) and (NPW=0) and (bp=0) and (wp=1) then evalfun:=f_KRKP;
  If (NPW=PieseTypValue[queen]) and (NPB=0) and (wp=0) and (bp=1) then evalfun:=f_KQKP;
  If (NPB=PieseTypValue[queen]) and (NPW=0) and (bp=0) and (wp=1) then evalfun:=f_KQKP;
  If (NPW=PieseTypValue[queen]) and (NPB=PieseTypValue[rook]) and (wp=0) and (bp>=1) then scalefun:=f_KQKRP;
  If (NPB=PieseTypValue[queen]) and (NPW=PieseTypValue[rook]) and (bp=0) and (wp>=1) then scalefun:=f_KQKRP;
  // ��������� ��� � ���
  MatTable[result].MatKey:=Board.MatKey;
  MatTable[result].EvalMid:=ScoreMid;
  MatTable[result].EvalEnd:=ScoreEnd;
  MatTable[result].WScale:=Wscale;
  MatTable[result].BScale:=BScale;
  MatTable[result].EvalFunc:=evalfun;
  MatTable[result].ScaleFunc:=scalefun;
  MatTable[result].phase:=phase;
end;
end.
