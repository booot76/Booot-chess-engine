unit Evaluation;

interface
 uses params,Board,safety,bitboards,attacks,endgame,material;
TYPE
    T8=array[0..8] of integer;
CONST
    WNSQ : TBytesArray =
     (
      -30,-25,-20,-15,-15,-20,-25,-30,
      -20,-15,-10, -5, -5,-10,-15,-20,
      -15, -5,  0,  5,  5,  0, -5,-15,
      -10,  0,  5, 10, 10,  5,  0,-10,
       -5,  5, 10, 15, 15, 10,  5, -5,
       -5,  5, 10, 15, 15, 10,  5, -5,
      -20,-10,  0,  5,  5,  0,-10,-20,
     -100,-25,-15,-10,-10,-15,-25,-100
     );
     WNESQ : TBytesArray  =
     (
      -40,-30,-20,-15,-15,-20,-30,-40,
      -30,-20,-10, -5, -5,-10,-20,-30,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -15, -5,  5, 10, 10,  5, -5,-15,
      -15, -5,  5, 10, 10,  5, -5,-15,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -30,-20,-10, -5, -5,-10,-20,-30,
      -40,-30,-20,-15,-15,-20,-30,-40
     );

     WBSQ : TBytesArray  =
     (
        -15,-15,-12,-10,-10,-12,-15,-15,
        -15,  2, -2,  0,  0, -2,  2,-15,
         -8,  0,  4,  2,  2,  4,  0, -8,
         -2,  2,  2,  8,  8,  2,  2, -2,
         -2,  2,  2,  8,  8,  2,  2, -2,
         -4, -2,  4,  2,  2,  4, -2, -4,
        -10,  0, -2,  0,  0, -2,  0,-10,
         -8, -8, -6, -5, -5, -6, -8, -8
     );
    WBESQ : TBytesArray  =
     (
        -18,-12, -9, -6, -6, -9,-12,-18,
        -12, -6, -3,  0,  0, -3, -6,-12,
         -9, -3,  0,  3,  3,  0, -3, -9,
         -6,  0,  3,  6,  6,  3,  0, -6,
         -6,  0,  3,  6,  6,  3,  0, -6,
         -9, -3,  0,  3,  3,  0, -3, -9,
        -12, -6, -3,  0,  0, -3, -6,-12,
        -18,-12, -9, -6, -6, -9,-12,-18
     );
     WRSQ : TBytesArray  =
     (
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6
     );

     WQSQ : TBytesArray  =
     (
       -7,-5,-5,-5,-5,-5,-5,-7,
       -5, 0, 0, 0, 0, 0, 0,-5,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
     );
     WQESQ : TBytesArray  =
     (
        -24,-16,-12, -8, -8,-12,-16,-24,
        -16, -8, -4,  0,  0, -4, -8,-16,
        -12, -4,  0,  4,  4,  0, -4,-12,
         -8,  0,  4,  8,  8,  4,  0, -8,
         -8,  0,  4,  8,  8,  4,  0, -8,
        -12, -4,  0,  4,  4,  0, -4,-12,
        -16, -8, -4,  0,  0, -4, -8,-16,
        -24,-16,-12, -8, -8,-12,-16,-24
     );
  
WOutPost=$00007e7e7e000000;
BoutPost=$0000007e7e7e0000;
Light=$55AA55AA55AA55AA;
Dark=$AA55AA55AA55AA55;
WhiteBishopStrong=$7EFFFF7E3C000000;
BlackBishopStrong=$0000003C7EFFFF7E;

KnightMobMid=5;
KnightMobEnd=2;
BishopMobMidStrong=7;
BishopMobEndStrong=4;
BishopMobMidWeak=3;
BishopMobEndWeak=2;
RookMobMid  =3;
RookMobEnd  =4;
QueenMobMid=3;
QueenMobEnd=2;
PxNmid=22;
PxNend=30;
PxBmid=22;
PxBend=30;
PxRmid=30;
PxRend=40;
PxQmid=35;
PxQend=45;

NxPMid=3;
NxPEnd=15;
NxBMid=9;
NxBEnd=18;
NxRQMid=18;
NxRQEnd=40;

BxPMid=3;
BxPEnd=15;
BxNMid=9;
BxNEnd=18;
BxRQMid=18;
BxRQEnd=40;

RxPMid=0;
RxPEnd=10;
RxBNMid=6;
RxBNEnd=18;
RxQMid=10;
RxQEnd=20;

QxMid=6;
QxEnd=15;

ForkMid=25;
ForkEnd=30;

BishopTrapped=125;
RookOpenFileMid = 20;
RookOpenFileEnd = 20;
RookHalfFileMid = 10;
RookHalfFileEnd = 10;
RookOn78Mid=20;
RookOn78End=40;
RookTrapped=70;
BadRook  : t8=(0,0,0,0,0,0,25,50,0);
BadQueen : t8=(0,0,0,0,0,0,0,25,0);
RookKing : t8=(30,5,0,0,0,0,0,0,0);
RookLook=15;
QueenOn78Mid=8;
QueenOn78End=16;
Outpost=5;
NOutpostProtected=5;
NGoodOutpost=5;
NCenterOutpost=5;
BGoodOutPost=7;
GoodBishop=2;
SideToMoveBonusMid=3;
SideToMoveBonusEnd=3;
Function Eval(var Board:Tboard):integer;
implementation
 uses Pawn,movegen;
Function Eval(var Board:Tboard):integer;
label ex;
var
   score,scoremid,scoreend,indexmat,indexpawn,idx,x,y,Wtropism,Btropism,WPsaf,BpSaf,saf,kx,dif,trap,wshelter,bshelter,WGoodAtt,BGoodAtt: integer;
   temp,temp1,WPAttacks,BPAttacks,WNAttacks,BNAttacks,WBAttacks,BBAttacks,WRAttacks,BRAttacks,WQAttacks,BQAttacks,WKAttacks,BKAttacks,WAllAttacks,BAllAttacks,AttBB,MobBB : TbitBoard;
   WkingZone,BkingZone,WmobSpace,BmobSpace : TbitBoard;
   sq,wking,bking,s1,minor : Tsquare;
   sp:boolean;
begin
  indexmat:=EvalMaterial(Board);
  scoremid:=MatTable[indexmat].scoreMid;
  scoreend:=MatTable[indexmat].scoreEnd;
  if (MatTable[indexmat].flag and SpecialEndgame)<>0 then
    begin
      sp:=EvalSpecialEndgames(Board,indexmat,scoremid,scoreend);
      if sp then goto ex;
    end;
  indexPawn:=EvalPawn(Board);
  scoremid:=scoremid+PawnTable[indexpawn].scoremid;
  scoreend:=scoreend+PawnTable[indexpawn].scoreend;

  EvalSafety(Board,MatTable[indexmat].flag,scoremid,scoreend,indexPawn,wshelter,bshelter);
  // ќценка фигур
  wking:=Board.KingSq[white];
  bking:=Board.KingSq[black];
  WPAttacks:=((Board.Pieses[WhitePawn] and (not FilesBB[1])) shl 7) or ((Board.Pieses[WhitePawn] and (not FilesBB[8])) shl 9);
  BPAttacks:=((Board.Pieses[BlackPawn] and (not FilesBB[1])) shr 9) or ((Board.Pieses[BlackPawn] and (not FilesBB[8])) shr 7);
  WKAttacks:=KingAttacksBB[wking];
  BKAttacks:=KingAttacksBB[bking];
  WkingZone:=WKAttacks or OnlyR00[wking];
  BkingZone:=BKAttacks or OnlyR00[bking];
  WmobSpace:=not(Board.CPieses[white] or BPAttacks);
  BmobSpace:=not(Board.CPieses[black] or WPAttacks);
  WNAttacks:=0;
  BNAttacks:=0;
  WBAttacks:=0;
  BBAttacks:=0;
  WRAttacks:=0;
  BRAttacks:=0;
  WQAttacks:=0;
  BQAttacks:=0;
  WPSaf:=0;
  BPSaf:=0;
  Wtropism:=0;
  Btropism:=0;
  WgoodAtt:=0;
  BgoodAtt:=0;
  if (WPAttacks and BkingZone)<>0 then inc(WPSaf);
  if (BPAttacks and WkingZone)<>0 then inc(BPSaf);
  // кони
  temp:=Board.Pieses[whiteknight];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      scoremid:=scoremid+WNSQ[sq];
      scoreend:=scoreend+WNESQ[sq];
      AttBB:=KnightAttacksBB[sq];
      if (AttBB and BkingZone)<>0 then
        begin
          inc(WPSaf);
          Wtropism:=Wtropism+KnightTropism;
        end;
      // динамика
      if ((OnlyR00[sq] and BPAttacks)<>0) then
        begin
          inc(BgoodAtt);
          scoremid:=scoremid-PxNMid;
          scoreend:=scoreend-PxNEnd;
        end;
      if (AttBB and Board.Pieses[BlackPawn] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+NxPMid;
          scoreend:=scoreend+NxPEnd;
        end;
       if (AttBB and Board.Pieses[BlackBishop] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+NxBMid;
          scoreend:=scoreend+NxBEnd;
        end;
        if (AttBB and (Board.Pieses[BlackRook] or Board.Pieses[BlackQueen]))<>0 then
        begin
          scoremid:=scoremid+NxRQMid;
          scoreend:=scoreend+NxRQEnd;
          inc(WGoodAtt);
        end;

      if ((OnlyR00[sq] and WoutPost)<>0) and ((PawnBackWardMaskBB[black,sq-8] and Board.Pieses[BlackPawn])=0) then
        begin
          scoremid:=scoremid+OutPost;
          scoreend:=scoreend+Outpost;
          if (PawnAttacksBB[black,sq] and Board.Pieses[WhitePawn])<>0 then
            begin
              scoremid:=scoremid+NoutPostProtected;
              scoreend:=scoreend+NoutPostProtected;
              if ((AttBB and BkingZone)<>0) or ((AttBB and Board.CPieses[black] and (not BPAttacks))<>0)  then
                begin
                  scoremid:=scoremid+NGoodOutpost;
                  scoreend:=scoreend+NGoodOutpost;
                  if (posx[sq] in [4,5]) or (posy[sq]=5) then
                    begin
                      scoremid:=scoremid+NCenterOutpost;
                      scoreend:=scoreend+NCenterOutpost;
                    end;
                end;
            end;
        end;
      WNAttacks:=WNAttacks or AttBB;
      MobBB:=AttBB and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+KnightMobMid*idx;
      scoreend:=scoreend+KnightMobEnd*idx;
      temp:=temp and NotOnlyR00[sq];
    end;
  temp:=Board.Pieses[blackknight];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      scoremid:=scoremid-WNSQ[63-sq];
      scoreend:=scoreend-WNESQ[63-sq];
      AttBB:=KnightAttacksBB[sq];
      if (AttBB and WkingZone)<>0 then
        begin
          inc(BPSaf);
          Btropism:=Btropism+KnightTropism;
        end;
      // динамика
      if ((OnlyR00[sq] and WPAttacks)<>0) then
        begin
          inc(WgoodAtt);
          scoremid:=scoremid+PxNMid;
          scoreend:=scoreend+PxNEnd;
        end;
      if (AttBB and Board.Pieses[WhitePawn] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-NxPMid;
          scoreend:=scoreend-NxPEnd;
        end;
       if (AttBB and Board.Pieses[WhiteBishop] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-NxBMid;
          scoreend:=scoreend-NxBEnd;
        end;
        if (AttBB and (Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen]))<>0 then
        begin
          scoremid:=scoremid-NxRQMid;
          scoreend:=scoreend-NxRQEnd;
          inc(BGoodAtt);
        end;

      if ((OnlyR00[sq] and BoutPost)<>0) and ((PawnBackWardMaskBB[white,sq+8] and Board.Pieses[WhitePawn])=0) then
        begin
          scoremid:=scoremid-OutPost;
          scoreend:=scoreend-Outpost;
          if (PawnAttacksBB[white,sq] and Board.Pieses[BlackPawn])<>0 then
            begin
              scoremid:=scoremid-NoutPostProtected;
              scoreend:=scoreend-NoutPostProtected;
              if ((AttBB and WkingZone)<>0) or ((AttBB and Board.CPieses[white] and (not WPAttacks))<>0)  then
                begin
                  scoremid:=scoremid-NGoodOutpost;
                  scoreend:=scoreend-NGoodOutpost;
                  if (posx[sq] in [4,5]) or (posy[sq]=4) then
                    begin
                      scoremid:=scoremid-NCenterOutpost;
                      scoreend:=scoreend-NCenterOutpost;
                    end;
                end;
            end;
        end;
      BNAttacks:=BNAttacks or AttBB;
      MobBB:=AttBB and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-KnightMobMid*idx;
      scoreend:=scoreend-KnightMobEnd*idx;
      temp:=temp and NotOnlyR00[sq];
    end;
  // слоны
  temp:=Board.Pieses[whitebishop];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      scoremid:=scoremid+WBSQ[sq];
      scoreend:=scoreend+WBESQ[sq];
      if (sq=a7) and (Board.Pos[b6]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end else
      if (sq=h7) and (Board.Pos[g6]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end;
      AttBB:=BishopMovesBB(sq,Board);
      if ((AttBB and BKingZone)<>0) then
        begin
          inc(WPSaf);
          Wtropism:=Wtropism+BishopTropism;
        end;
      // динамика
      if ((OnlyR00[sq] and BPAttacks)<>0) then
        begin
          inc(BgoodAtt);
          scoremid:=scoremid-PxBMid;
          scoreend:=scoreend-PxBEnd;
        end;
      if (AttBB and Board.Pieses[BlackPawn] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+BxPMid;
          scoreend:=scoreend+BxPEnd;
        end;
       if (AttBB and Board.Pieses[BlackKnight] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+BxNMid;
          scoreend:=scoreend+BxNEnd;
        end;
        if (AttBB and (Board.Pieses[BlackRook] or Board.Pieses[BlackQueen]))<>0 then
        begin
          scoremid:=scoremid+BxRQMid;
          scoreend:=scoreend+BxRQEnd;
          inc(WGoodAtt);
        end;

      if ((OnlyR00[sq] and WoutPost)<>0) and ((PawnBackWardMaskBB[black,sq-8] and Board.Pieses[BlackPawn])=0) then
        begin
          if (PawnAttacksBB[black,sq] and Board.Pieses[WhitePawn])<>0 then
            begin
              scoremid:=scoremid+OutPost;
              scoreend:=scoreend+OutPost;
              if ((AttBB and BkingZone)<>0) or ((AttBB and Board.CPieses[black] and (not BPAttacks))<>0)  then
                begin
                  scoremid:=scoremid+BGoodOutpost;
                  scoreend:=scoreend+BGoodOutpost;
                end;
            end;
        end;

      WBAttacks:=WBAttacks or AttBB;
      MobBB:=AttBB and WmobSpace and WhiteBishopStrong;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+BishopMobMidStrong*idx;
      scoreend:=scoreend+BishopMobEndStrong*idx;
      MobBB:=AttBB and WmobSpace and (not WhiteBishopStrong);
      idx:=BitCount(MobBB);
      scoremid:=scoremid+BishopMobMidWeak*idx;
      scoreend:=scoreend+BishopMobEndWeak*idx;
      temp:=temp and NotOnlyR00[sq];
    end;
  temp:=Board.Pieses[blackbishop];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      scoremid:=scoremid-WBSQ[63-sq];
      scoreend:=scoreend-WBESQ[63-sq];
      if (sq=a2) and (Board.Pos[b3]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end else
      if (sq=h2) and (Board.Pos[g3]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end;
      AttBB:=BishopMovesBB(sq,Board);
      if ((AttBB and WKingZone)<>0) then
        begin
          inc(BPSaf);
          Btropism:=Btropism+BishopTropism;
        end;
       // динамика
      if ((OnlyR00[sq] and WPAttacks)<>0) then
        begin
          inc(WgoodAtt);
          scoremid:=scoremid+PxBMid;
          scoreend:=scoreend+PxBEnd;
        end;
      if (AttBB and Board.Pieses[WhitePawn] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-BxPMid;
          scoreend:=scoreend-BxPEnd;
        end;
       if (AttBB and Board.Pieses[WhiteKnight] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-BxNMid;
          scoreend:=scoreend-BxNEnd;
        end;
        if (AttBB and (Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen]))<>0 then
        begin
          scoremid:=scoremid-BxRQMid;
          scoreend:=scoreend-BxRQEnd;
          inc(BGoodAtt);
        end;

      if ((OnlyR00[sq] and BoutPost)<>0) and ((PawnBackWardMaskBB[white,sq+8] and Board.Pieses[WhitePawn])=0) then
        begin
          if (PawnAttacksBB[white,sq] and Board.Pieses[BlackPawn])<>0 then
            begin
              scoremid:=scoremid-OutPost;
              scoreend:=scoreend-OutPost;
              if ((AttBB and WkingZone)<>0) or ((AttBB and Board.CPieses[white] and (not WPAttacks))<>0)  then
                begin
                  scoremid:=scoremid-BGoodOutpost;
                  scoreend:=scoreend-BGoodOutpost;
                end;
            end;
        end;

      BBAttacks:=BBAttacks or AttBB;
      MobBB:=AttBB and BmobSpace and BlackBishopStrong;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-BishopMobMidStrong*idx;
      scoreend:=scoreend-BishopMobEndStrong*idx;
      MobBB:=AttBB and BmobSpace and (not BlackBishopStrong);
      idx:=BitCount(MobBB);
      scoremid:=scoremid-BishopMobMidWeak*idx;
      scoreend:=scoreend-BishopMobEndWeak*idx;
      temp:=temp and NotOnlyR00[sq];
    end;

  // ладьи
  temp:=Board.Pieses[whiterook];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=Posy[sq];
      scoremid:=scoremid+WRSQ[sq];
      AttBB:=RookMovesBB(sq,Board);
      if ((AttBB and BKingZone)<>0) then
        begin
          inc(WPSaf);
          Wtropism:=Wtropism+RookTropism;
          if ((MatTable[indexmat].flag and DoBkingSafety)<>0) then scoremid:=scoremid+RookLook;
        end;
      // динамика
      if ((OnlyR00[sq] and BPAttacks)<>0) then
        begin
          inc(BgoodAtt);
          scoremid:=scoremid-PxRMid;
          scoreend:=scoreend-PxREnd;
        end;
      if (AttBB and Board.Pieses[BlackPawn] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+RxPMid;
          scoreend:=scoreend+RxPEnd;
        end;
       if (AttBB and (Board.Pieses[BlackKnight] or Board.Pieses[BlackBishop]) and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+RxBNMid;
          scoreend:=scoreend+RxBNEnd;
        end;
        if (AttBB and Board.Pieses[BlackQueen])<>0 then
        begin
          scoremid:=scoremid+RxQMid;
          scoreend:=scoreend+RxQEnd;
          inc(WGoodAtt);
        end;

      WRAttacks:=WRAttacks or AttBB;
      MobBB:=AttBB and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+RookMobMid*idx;
      scoreend:=scoreend+RookMobEnd*idx;
      if (FilesBB[x] and Board.Pieses[whitepawn])=0 then
        begin
          if (FilesBB[x] and Board.Pieses[blackpawn])=0 then
            begin
             scoremid:=scoremid+RookOpenFileMid;
             scoreend:=scoreend+RookOpenFileEnd;
             dif:=Abs(x-Posx[bking]);
             if (bking>sq) and ((MatTable[indexmat].flag and DoBkingSafety)<>0) then
               begin
                scoremid:=scoremid+RookKing[dif];
               end;
            end else
            begin
              scoremid:=scoremid+RookHalfFileMid;
              scoreend:=scoreend+RookHalfFileEnd;
            end;
        end else if  (idx<6) and ((posy[wking]=1) or (posy[wking]=y))  then
            begin
              trap:=0;
              kx:=Posx[wking];
              if (kx>=5) and (x>kx) then trap:=RookTrapped-5*idx;
              if (kx<5) and (x<kx)  then trap:=RookTrapped-5*idx;
              if (trap<>0) and ((Board.Castle and 3)<>0) then trap:=trap div 4;
              scoremid:=scoremid-trap;
              scoreend:=scoreend-trap;
            end;
      if (y>=7) and ((Posy[bking]>=y) or ((AttBB and RanksBB[y] and Board.Pieses[blackpawn])<>0)) then
        begin
          scoremid:=scoremid+RookOn78Mid;
          scoreend:=scoreend+RookOn78end;
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
  temp:=Board.Pieses[blackrook];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=Posy[sq];
      scoremid:=scoremid-WRSQ[63-sq];
      AttBB:=RookMovesBB(sq,Board);
      if ((AttBB and WKingZone)<>0) then
        begin
          inc(BPSaf);
          Btropism:=Btropism+RookTropism;
          if ((MatTable[indexmat].flag and DoWkingSafety)<>0) then scoremid:=scoremid-RookLook;
        end;
      // динамика
      if ((OnlyR00[sq] and WPAttacks)<>0) then
        begin
          inc(WgoodAtt);
          scoremid:=scoremid+PxRMid;
          scoreend:=scoreend+PxREnd;
        end;
      if (AttBB and Board.Pieses[WhitePawn] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-RxPMid;
          scoreend:=scoreend-RxPEnd;
        end;
       if (AttBB and (Board.Pieses[WhiteKnight] or Board.Pieses[WhiteBishop]) and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-RxBNMid;
          scoreend:=scoreend-RxBNEnd;
        end;
        if (AttBB and Board.Pieses[WhiteQueen])<>0 then
        begin
          scoremid:=scoremid-RxQMid;
          scoreend:=scoreend-RxQEnd;
          inc(BGoodAtt);
        end;

      BRAttacks:=BRAttacks or AttBB;
      MobBB:=AttBB and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-RookMobMid*idx;
      scoreend:=scoreend-RookMobEnd*idx;
      if (FilesBB[x] and Board.Pieses[blackpawn])=0 then
        begin
          if (FilesBB[x] and Board.Pieses[whitepawn])=0 then
            begin
              scoremid:=scoremid-RookOpenFileMid;
              scoreend:=scoreend-RookOpenFileEnd;
              dif:=Abs(x-Posx[wking]);
              if (wking<sq) and  ((MatTable[indexmat].flag and DoWkingSafety)<>0) then
               begin
                scoremid:=scoremid-RookKing[dif];
               end;
            end else
            begin
              scoremid:=scoremid-RookHalfFileMid;
              scoreend:=scoreend-RookHalfFileEnd;
            end;
        end else if  (idx<6) and ((posy[bking]=8) or (posy[bking]=y))  then
            begin
              trap:=0;
              kx:=Posx[bking];
              if (kx>=5) and (x>kx) then trap:=RookTrapped-5*idx;
              if (kx<5) and (x<kx)  then trap:=RookTrapped-5*idx;
              if (trap<>0) and ((Board.Castle and 12)<>0) then trap:=trap div 4;
              scoremid:=scoremid+trap;
              scoreend:=scoreend+trap;
            end;

      if (y<=2) and ((Posy[wking]<=y) or ((AttBB and RanksBB[y] and Board.Pieses[whitepawn])<>0)) then
        begin
          scoremid:=scoremid-RookOn78Mid;
          scoreend:=scoreend-RookOn78end;
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
   // ферзи
  temp:=Board.Pieses[whitequeen];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      y:=posy[sq];
      scoremid:=scoremid+WQSQ[sq];
      scoreend:=scoreend+WQESQ[sq];
      AttBB:=QueenMovesBB(sq,Board);
      if ((AttBB and BkingZone)<>0) then
        begin
          inc(WPSaf);
          Wtropism:=Wtropism+QueenTropism;
        end;
      // динамика
      if ((OnlyR00[sq] and BPAttacks)<>0) then
        begin
          inc(BgoodAtt);
          scoremid:=scoremid-PxQMid;
          scoreend:=scoreend-PxQEnd;
        end;
      if (AttBB and Board.CPieses[Black] and (not BPAttacks))<>0 then
        begin
          scoremid:=scoremid+QxMid;
          scoreend:=scoreend+QxEnd;
        end;

      WQAttacks:=WQAttacks or AttBB;
      MobBB:=AttBB and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+idx*QueenMobMid;
      scoreend:=scoreend+idx*QueenMobEnd;
      if (y>=7) and ((Posy[bking]>=y) or ((AttBB and RanksBB[y] and Board.Pieses[blackpawn])<>0)) then
        begin
          scoremid:=scoremid+QueenOn78Mid;
          scoreend:=scoreend+QueenOn78end;
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
  temp:=Board.Pieses[blackqueen];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
       y:=posy[sq];
      scoremid:=scoremid-WQSQ[63-sq];
      scoreend:=scoreend-WQESQ[63-sq];
      AttBB:=QueenMovesBB(sq,Board);
      if  ((AttBB and WKingZone)<>0) then
        begin
          inc(BPSaf);
          Btropism:=Btropism+QueenTropism;
        end;
      // динамика
      if ((OnlyR00[sq] and WPAttacks)<>0) then
        begin
          inc(WgoodAtt);
          scoremid:=scoremid+PxQMid;
          scoreend:=scoreend+PxQEnd;
        end;
      if (AttBB and Board.CPieses[white] and (not WPAttacks))<>0 then
        begin
          scoremid:=scoremid-QxMid;
          scoreend:=scoreend-QxEnd;
        end;

      BQAttacks:=BQAttacks or AttBB;
      MobBB:=AttBB and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-idx*QueenMobMid;
      scoreend:=scoreend-idx*QueenMobEnd;
      if (y<=2) and ((Posy[wking]<=y) or ((AttBB and RanksBB[y] and Board.Pieses[whitepawn])<>0)) then
        begin
          scoremid:=scoremid-QueenOn78Mid;
          scoreend:=scoreend-QueenOn78end;
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
  if WgoodAtt>1 then
    begin
      scoremid:=scoremid+ForkMid;
      scoreend:=scoreend+ForkMid;
    end;
  if BgoodAtt>1 then
    begin
      scoremid:=scoremid-ForkMid;
      scoreend:=scoreend-ForkMid;
    end;
  
  WALLAttacks:=WPAttacks or WNAttacks or WBAttacks or WRAttacks or WQAttacks or WKAttacks;
  BALLAttacks:=BPAttacks or BNAttacks or BBAttacks or BRAttacks or BQAttacks or BKAttacks;
  if (WkingZone and BkingZone)<>0 then
    begin
      inc(WPSaf);
      inc(BPsaf);
    end;
  if (Wtropism>0)  and (WPSaf>1)  then
    begin
      saf:=Wtropism*KPSafety[WPSaf] div 8;
      if (Board.Pieses[whitequeen]=0) then saf:=saf div 2;
      scoremid:=scoremid+saf;
    end;
  if (Btropism>0)  and (BPSaf>1)  then
    begin
      saf:=Btropism*KPSafety[BPSaf] div 8;
      if (Board.Pieses[blackqueen]=0) then saf:=saf div 2;
      scoremid:=scoremid-saf;
    end;
 
  if PawnTable[indexpawn].PasserBB<>0 then EvalPasser(Board,scoremid,scoreend,PawnTable[indexpawn].PasserBB,WAllAttacks,BAllAttacks,indexmat);
  scoremid:=scoremid+WKBSQ[Board.KingSq[white]]-WKBSQ[63-Board.KingSq[black]];
  scoreend:=scoreend+WKESQ[Board.KingSq[white]]-WKESQ[63-Board.KingSq[black]];
  if Board.Color=white then
    begin
      scoremid:=scoremid+SideToMoveBonusMid;
      scoreend:=scoreend+SideToMoveBonusEnd;
    end else
    begin
      scoremid:=scoremid-SideToMoveBonusMid;
      scoreend:=scoreend-SideToMoveBonusEnd;
    end;
ex:
  score:=(scoremid*Mattable[indexmat].phase+(24-Mattable[indexmat].phase)*scoreend) div 24;
  if (score>0) and (MatTable[indexmat].Wmul<>16) then score:=(score*MatTable[indexmat].Wmul) div 16 else
  if (score<0) and (MatTable[indexmat].Bmul<>16) then score:=(score*MatTable[indexmat].Bmul) div 16;
  if Board.Color=black then score:=-score;
  Result:=score;
end;


end.
