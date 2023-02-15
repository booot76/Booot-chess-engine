unit Evaluation;

interface
 uses params,Board,safety,bitboards,attacks,endgame,material;
TYPE
    T8=array[0..8] of integer;
CONST
    WNSQ : TBytesArray =
     (
      -52,-41,-31,-26,-26,-31,-41,-52,
      -36,-26,-15, -9, -9,-15,-26,-36,
      -20, -9,  0,  5,  5,  0, -9,-20,
       -9,  0, 10, 16, 16, 10,  0, -9,
       -4,  5, 16, 21, 21, 16,  5, -4,
       -4,  5, 16, 21, 21, 16,  5, -4,
      -20, -9,  0,  5,  5,  0, -9,-20,
      -75,-26,-15, -9, -9,-15,-26,-75
     );
     WNESQ : TBytesArray  =
     (
      -40,-30,-21,-16,-16,-21,-30,-40,
      -30,-21,-11, -6, -6,-11,-21,-30,
      -21,-11, -2,  1,  1, -2,-11,-21,
      -16, -6,  1,  7,  7,  1, -6,-16,
      -16, -6,  1,  7,  7,  1, -6,-16,
      -21,-11, -2,  1,  1, -2,-11,-21,
      -30,-21,-11, -6, -6,-11,-21,-30,
      -40,-30,-21,-16,-16,-21,-30,-40
     );

     WBSQ : TBytesArray  =
     (
        -15,-15,-15,-10,-10,-15,-15,-15,
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
        -18,-15,-15, -6, -6,-15,-15,-18,
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


    WForward : TBBLine =
    ($FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,$FFFFFFFFFFFFFF00,
     $FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,$FFFFFFFFFFFF0000,
     $FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,$FFFFFFFFFF000000,
     $FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,$FFFFFFFF00000000,
     $FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,$FFFFFF0000000000,
     $FFFF000000000000,$FFFF000000000000,$FFFF000000000000,$FFFF000000000000,$FFFF000000000000,$FFFF000000000000,$FFFF000000000000,$FFFF000000000000,
     $FF00000000000000,$FF00000000000000,$FF00000000000000,$FF00000000000000,$FF00000000000000,$FF00000000000000,$FF00000000000000,$FF00000000000000,
     $0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000);

    BForWard : TBBLine =
   ($0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,
    $00000000000000FF,$00000000000000FF,$00000000000000FF,$00000000000000FF,$00000000000000FF,$00000000000000FF,$00000000000000FF,$00000000000000FF,
    $000000000000FFFF,$000000000000FFFF,$000000000000FFFF,$000000000000FFFF,$000000000000FFFF,$000000000000FFFF,$000000000000FFFF,$000000000000FFFF,
    $0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,$0000000000FFFFFF,
    $00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,$00000000FFFFFFFF,
    $000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,$000000FFFFFFFFFF,
    $0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,$0000FFFFFFFFFFFF,
    $00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF,$00FFFFFFFFFFFFFF);

Light=$55AA55AA55AA55AA;
Dark=$AA55AA55AA55AA55;
BSpaceMask=16954726998343680;
WspaceMask=1010580480;
Ranks78=$ffff000000000000;
Ranks678=$ffffff0000000000;
Ranks12=$000000000000ffff;
Ranks123=$00000000000ffffff;
WhiteOutpost=$00007e7e7e000000;
BlackOutpost=$0000007e7e7e0000;

KnightMobMid : t8=(0,6,12,18,24,30,36,42,48);
KnightMobEnd : t8=(0,8,16,24,32,40,48,56,64);
BishopMobMid :t16=(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80);
BishopMobEnd :t16=(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80);
RookMobMid   :t16=(0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32);
RookMobEnd   :t16=(0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48);

KnightOutPostMid=2;
KnightOutPostEnd=3;
KnightOutPostStrongMid=5;
KnightOutPostStrongEnd=5;
KnightOutPostCenterMid=3;
KnightOutPostCenterEnd=3;

BishopOutPostMid=1;
BishopOutPostEnd=2;
BishopOutPostStrongMid=3;
BishopOutPostStrongEnd=4;

RookOutPostMid=1;
RookOutPostEnd=2;
RookOutPostStrongMid=3;
RookOutPostStrongEnd=4;

PAttQMid=8;
PAttQEnd=12;
PAttRMid=7;
PAttREnd=10;
PAttMMid=5;
PAttMEnd=7;

MAttRQMid=7;
MAttRQEnd=10;
NAttBMid=5;
NAttBEnd=5;
NAttPMid=3;
NAttPEnd=4;

BAttPMid=3;
BAttPEnd=4;
BAttNMid=5;
BAttNEnd=5;

RAttQMid=5;
RAttQEnd=5;
RAttMMid=4;
RAttMEnd=5;
RAttPMid=2;
RAttPEnd=3;

MinorsUndefendedMid=10;
MinorsUndefendedEnd=5;

QdynMid=5;
QdynEnd=5;

QGuardMid=5;
QGuardEnd=2;
NGuardMid=4;
NGuardEnd=2;
BGuardMid=2;
BGuardEnd=1;
RGuardMid=3;
RGuardEnd=1;

BishopTrapped=75;

RookOpenFileMid = 20;
RookOpenFileEnd = 10;
RookHalfFileMid = 3;
RookHalfFileEnd = 6;
RookOpenFixedMid=10;
RookOpenFixedEnd=0;
RookOpenMinorMid=15;
RookOpenMinorEnd=5;
RookHalfOpenPawnMid=5;
RookHalfOpenPawnEnd=5;

RookOn8Mid=5;
RookOn8End=10;
RookOn7Mid=15;
RookOn7End=40;
RookOn6Mid= 5;
RookOn6End=15;
DoubleRook7Mid=10;
DoubleRook7End=20;

RookTrapped=50;
RookLook=10;
ActiveKing=5;

QueenOn7Mid=5;
Queenon7End=25;
QueenRook7Mid=10;
QueenRook7End=15;

ForkScaleMid=15;
ForkScaleEnd=25;
TempoMid=10;
TempoEnd=5;

Function Eval(var Board:Tboard;var dangereval:integer):integer;
implementation
 uses Pawn,movegen;
Function Eval(var Board:Tboard;var dangereval:integer):integer;
label ex;
var
   score,scoremid,scoreend,indexmat,indexpawn,idx,x,y,Wtropism,Btropism,Wfork,Bfork,WPsaf,BpSaf,saf,kx,trap,wshelter,bshelter,wlight,wdark,blight,bdark: integer;
   temp,temp1,WPAttacks,BPAttacks,WNAttacks,BNAttacks,WBAttacks,BBAttacks,WRAttacks,BRAttacks,WQAttacks,BQAttacks,WKAttacks,BKAttacks,WAllAttacks,BAllAttacks,AttBB,MobBB,Wdyn,Bdyn : TbitBoard;
   WkingZone,BkingZone,WkingRing,BkingRing,WmobSpace,BmobSpace,WgoodMinor,BgoodMinor : TbitBoard;
   sq,sq1,wking,bking : Tsquare;
   sp:boolean;
begin
  dangereval:=0;
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
  wlight:=PawnTable[indexpawn].blocked and 255;
  wdark:=(PawnTable[indexpawn].blocked shr 8) and 255;
  blight:=(PawnTable[indexpawn].blocked shr 16) and 255;
  bdark:=(PawnTable[indexpawn].blocked shr 24) and 255;
  wking:=Board.KingSq[white];
  bking:=Board.KingSq[black];
 if (Mattable[indexmat].flag and DoBkingSafety)=0
    then  bshelter:=0
    else  bshelter:=BKShelter(Board,bking,indexpawn);
 if (Mattable[indexmat].flag and DoWkingSafety)=0
    then wshelter:=0
    else wshelter:=WKShelter(Board,wking,indexpawn);

  // Оценка фигур
  WPAttacks:=((Board.Pieses[WhitePawn] and (not FilesBB[1])) shl 7) or ((Board.Pieses[WhitePawn] and (not FilesBB[8])) shl 9);
  BPAttacks:=((Board.Pieses[BlackPawn] and (not FilesBB[1])) shr 9) or ((Board.Pieses[BlackPawn] and (not FilesBB[8])) shr 7);
  WKAttacks:=KingAttacksBB[wking];
  BKAttacks:=KingAttacksBB[bking];
  WkingZone:=WKAttacks or OnlyR00[wking];
  BkingZone:=BKAttacks or OnlyR00[bking];
  WkingRing:=WkingZone or (WkingZone shl 8);
  BkingRing:=BkingZone or (BkingZone shr 8);
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
  Wfork:=0;
  Bfork:=0;
  Wtropism:=0;
  Btropism:=0;
  Wdyn:=Board.CPieses[Black] and (not BPAttacks);
  Bdyn:=Board.CPieses[white] and (not WPAttacks);
  WmobSpace:=not(Board.CPieses[white] or BPAttacks);
  BmobSpace:=not(Board.CPieses[black] or WPAttacks);
  WgoodMinor:=(Board.Pieses[WhiteKnight] or Board.Pieses[WhiteBishop]) and WPAttacks;
  BgoodMinor:=(Board.Pieses[BlackKnight] or Board.Pieses[BlackBishop]) and BPAttacks;
  if (WPAttacks and BkingZone)<>0 then inc(WPSaf);
  if (BPAttacks and WkingZone)<>0 then inc(BPSaf);

  // кони
  temp:=Board.Pieses[whiteknight];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid+WNSQ[sq];
      scoreend:=scoreend+WNESQ[sq];
      if (posy[sq]<5) and (Board.Pos[sq+24]=BlackPawn) then
        begin
          scoremid:=scoremid-(5-posy[sq]);
          scoreend:=scoreend-(5-posy[sq]);
        end;
      AttBB:=KnightAttacksBB[sq];
      WNAttacks:=WNAttacks or AttBB;
      if ((AttBB and BKingRing)<>0) then
        begin
          Wtropism:=Wtropism+KnightTropism;
          if ((AttBB and BKingZone)<>0) then inc(WPSaf);
        end;
      if ((AttBB and WkingZone)<>0) then
       begin
        scoremid:=scoremid+NGuardMid;
        scoreend:=scoreend+NGuardEnd;
       end;

      if (OnlyR00[sq] and BPAttacks)<>0 then
       begin
         inc(Bfork);
         scoremid:=scoremid-PAttMMid;
         scoreend:=scoreend-PAttMEnd;
       end;
      // динамика
       if (AttBB and (not BPAttacks) and Board.Pieses[BlackPawn])<>0 then
        begin
          scoremid:=scoremid+NAttPMid;
          scoreend:=scoreend+NAttPEnd;
        end;
       if (AttBB and (not BPAttacks) and Board.Pieses[BlackBishop])<>0 then
        begin
          scoremid:=scoremid+NAttBMid;
          scoreend:=scoreend+NAttBEnd;
        end;
       if (AttBB  and (Board.Pieses[BlackRook] or Board.Pieses[BlackQueen]))<>0 then
        begin
          inc(Wfork);
          scoremid:=scoremid+MAttRQMid;
          scoreend:=scoreend+MAttRQEnd;
        end;
     // форпосты
       if ((OnlyR00[sq] and WhiteOutPost)<>0) and ((PawnIsoMaskBB[sq] and Wforward[sq] and Board.Pieses[BlackPawn])=0) then
         begin
           scoremid:=scoremid+KnightOutPostMid;
           scoreend:=scoreend+KnightOutPostEnd;
           if (OnlyR00[sq] and WPAttacks)<>0 then
             begin
               scoremid:=scoremid+KnightOutPostMid;
               scoreend:=scoreend+KnightOutPostEnd;
               if (AttBB and (BkingZone or Wdyn))<>0 then
                 begin
                   scoremid:=scoremid+KnightOutPostStrongMid;
                   scoreend:=scoreend+KnightOutPostStrongEnd;
                   if (posy[sq]=5) then
                     begin
                       scoremid:=scoremid+KnightOutPostCenterMid;
                       scoreend:=scoreend+KnightOutPostCenterEnd;
                     end;
                    if (Posx[sq]=4) or (posx[sq]=5) then
                     begin
                       scoremid:=scoremid+KnightOutPostCenterMid;
                       scoreend:=scoreend+KnightOutPostCenterEnd;
                     end;
                 end;
             end;
         end;

    // подвижность
      MobBB:=AttBB and Wforward[sq] and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+KnightMobMid[idx];
      scoreend:=scoreend+KnightMobEnd[idx];
    end;
  temp:=Board.Pieses[blackknight];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid-WNSQ[63-sq];
      scoreend:=scoreend-WNESQ[63-sq];
      if (posy[sq]>4) and (Board.Pos[sq-24]=WhitePawn) then
        begin
          scoremid:=scoremid+(posy[sq]-4);
          scoreend:=scoreend+(posy[sq]-4);
        end;
      AttBB:=KnightAttacksBB[sq];
      BNAttacks:=BNAttacks or AttBB;
      if ((AttBB and WKingRing)<>0) then
        begin
          Btropism:=Btropism+KnightTropism;
          if ((AttBB and WKingZone)<>0) then  inc(BPSaf);
        end;
      if ((AttBB and BkingZone)<>0) then
       begin
        scoremid:=scoremid-NGuardMid;
        scoreend:=scoreend-NGuardEnd;
       end;

      if (OnlyR00[sq] and WPAttacks)<>0 then
       begin
         inc(Wfork);
         scoremid:=scoremid+PAttMMid;
         scoreend:=scoreend+PAttMEnd;
       end;
      // динамика
       if (AttBB and (not WPAttacks) and Board.Pieses[WhitePawn])<>0 then
        begin
          scoremid:=scoremid-NAttPMid;
          scoreend:=scoreend-NAttPEnd;
        end;
       if (AttBB and (not WPAttacks) and Board.Pieses[WhiteBishop])<>0 then
        begin
          scoremid:=scoremid-NAttBMid;
          scoreend:=scoreend-NAttBEnd;
        end;
       if (AttBB  and (Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen]))<>0 then
        begin
          inc(Bfork);
          scoremid:=scoremid-MAttRQMid;
          scoreend:=scoreend-MAttRQEnd;
        end;
     // форпосты
       if ((OnlyR00[sq] and BlackOutPost)<>0) and ((PawnIsoMaskBB[sq] and Bforward[sq] and Board.Pieses[WhitePawn])=0) then
         begin
           scoremid:=scoremid-KnightOutPostMid;
           scoreend:=scoreend-KnightOutPostEnd;
           if (OnlyR00[sq] and BPAttacks)<>0 then
             begin
               scoremid:=scoremid-KnightOutPostMid;
               scoreend:=scoreend-KnightOutPostEnd;
               if (AttBB and (WkingZone or Bdyn))<>0 then
                 begin
                   scoremid:=scoremid-KnightOutPostStrongMid;
                   scoreend:=scoreend-KnightOutPostStrongEnd;
                   if (posy[sq]=4) then
                     begin
                       scoremid:=scoremid-KnightOutPostCenterMid;
                       scoreend:=scoreend-KnightOutPostCenterEnd;
                     end;
                    if (Posx[sq]=4) or (posx[sq]=5) then
                     begin
                       scoremid:=scoremid-KnightOutPostCenterMid;
                       scoreend:=scoreend-KnightOutPostCenterEnd;
                     end;
                 end;
             end;
         end;

    // подвижность
      MobBB:=AttBB and Bforward[sq] and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-KnightMobMid[idx];
      scoreend:=scoreend-KnightMobEnd[idx];
    end;
  // слоны
  temp:=Board.Pieses[whitebishop];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid+WBSQ[sq];
      scoreend:=scoreend+WBESQ[sq];
      if (OnlyR00[sq] and Light)<>0 then
        begin
          scoremid:=scoremid-(wlight + (blight div 2));
          scoreend:=scoreend-(wlight + (blight div 2));
          temp1:=Board.Pieses[BlackPawn] and Light and (not BPAttacks) and WForward[sq];
          scoreend:=scoreend+BitCount(temp1)*2;
        end else
        begin
          scoremid:=scoremid-(wdark + (bdark div 2));
          scoreend:=scoreend-(wdark + (bdark div 2));
          temp1:=Board.Pieses[BlackPawn] and Dark and (not BPAttacks) and WForward[sq];
          scoreend:=scoreend+BitCount(temp1)*2;
        end;
       AttBB:=BishopMovesBB(sq,Board);
      // форпосты
       if ((OnlyR00[sq] and WhiteOutPost)<>0) and ((PawnIsoMaskBB[sq] and Wforward[sq] and Board.Pieses[BlackPawn])=0) then
         begin
           if (OnlyR00[sq] and WPAttacks)<>0 then
             begin
               scoremid:=scoremid+BishopOutPostMid;
               scoreend:=scoreend+BishopOutPostEnd;
               if (AttBB and (BkingZone or Wdyn))<>0 then
                 begin
                   scoremid:=scoremid+BishopOutPostStrongMid;
                   scoreend:=scoreend+BishopOutPostStrongEnd;
                 end;
             end;
         end;
     // Паттерны
      if (sq=a7) and (Board.Pos[b6]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end;
      if (sq=h7) and (Board.Pos[g6]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end;
      if (sq=a6) and (Board.Pos[b5]=WhitePawn) then
        begin
          scoremid:=scoremid-(BishopTrapped div 2);
          scoreend:=scoreend-(BishopTrapped div 2);
        end;
      if (sq=h6) and (Board.Pos[g5]=WhitePawn) then
        begin
          scoremid:=scoremid-(BishopTrapped div 2);
          scoreend:=scoreend-(BishopTrapped div 2);
        end;
      if (sq=h2) and (Board.Pos[g3]=WhitePawn) then
        begin
          scoremid:=scoremid-(BishopTrapped div 2);
          scoreend:=scoreend-(BishopTrapped div 2);
        end;
      if (sq=a2) and (Board.Pos[b3]=WhitePawn) then
        begin
          scoremid:=scoremid-(BishopTrapped div 2);
          scoreend:=scoreend-(BishopTrapped div 2);
        end;
      if (sq=h1) and (Board.Pos[f3]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end;
      if (sq=a1) and (Board.Pos[c3]=BlackPawn) then
        begin
          scoremid:=scoremid-BishopTrapped;
          scoreend:=scoreend-BishopTrapped;
        end;

      WBAttacks:=WBAttacks or AttBB;
      if ((AttBB and BKingRing)<>0)  then
        begin
          Wtropism:=Wtropism+BishopTropism;
          if ((AttBB and BKingZone)<>0) then  inc(WPSaf);
        end;

      if ((AttBB and WkingZone)<>0) then
       begin
        scoremid:=scoremid+BGuardMid;
        scoreend:=scoreend+BGuardEnd;
       end;

      // динамика
      if (OnlyR00[sq] and BPAttacks)<>0 then
        begin
          scoremid:=scoremid-PAttMMid;
          scoreend:=scoreend-PAttMEnd;
          inc(bfork);
        end;

       if (AttBB and (not BPAttacks) and Board.Pieses[BlackPawn])<>0 then
        begin
          scoremid:=scoremid+BAttPMid;
          scoreend:=scoreend+BAttPEnd;
        end;
        if (AttBB and (not BPAttacks) and Board.Pieses[BlackKnight])<>0 then
        begin
          scoremid:=scoremid+BAttNMid;
          scoreend:=scoreend+BAttNEnd;
        end;
        if (AttBB  and (Board.Pieses[BlackRook] or Board.Pieses[BlackQueen])<>0) then
        begin
          scoremid:=scoremid+MAttRQMid;
          scoreend:=scoreend+MAttRQEnd;
          inc(wfork);
        end;
     // подвижность
      MobBB:=AttBB and Wforward[sq] and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+BishopMobMid[idx];
      scoreend:=scoreend+BishopMobEnd[idx];
    end;
 temp:=Board.Pieses[blackbishop];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid-WBSQ[63-sq];
      scoreend:=scoreend-WBESQ[63-sq];
      if (OnlyR00[sq] and Light)<>0 then
        begin
          scoremid:=scoremid+(blight + (wlight div 2));
          scoreend:=scoreend+(blight + (wlight div 2));
          temp1:=Board.Pieses[WhitePawn] and Light and (not WPAttacks) and BForward[sq];
          scoreend:=scoreend-BitCount(temp1)*2;
        end else
        begin
          scoremid:=scoremid+(bdark + (wdark div 2));
          scoreend:=scoreend+(bdark + (wdark div 2));
          temp1:=Board.Pieses[WhitePawn] and Dark and (not WPAttacks) and BForward[sq];
          scoreend:=scoreend-BitCount(temp1)*2;
        end;
       AttBB:=BishopMovesBB(sq,Board);
      // форпосты
       if ((OnlyR00[sq] and BlackOutPost)<>0) and ((PawnIsoMaskBB[sq] and Bforward[sq] and Board.Pieses[WhitePawn])=0) then
         begin
           if (OnlyR00[sq] and BPAttacks)<>0 then
             begin
               scoremid:=scoremid-BishopOutPostMid;
               scoreend:=scoreend-BishopOutPostEnd;
               if (AttBB and (WkingZone or Bdyn))<>0 then
                 begin
                   scoremid:=scoremid-BishopOutPostStrongMid;
                   scoreend:=scoreend-BishopOutPostStrongEnd;
                 end;
             end;
         end;
     // Паттерны
      if (sq=a2) and (Board.Pos[b3]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end;
      if (sq=h2) and (Board.Pos[g3]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end;
      if (sq=a3) and (Board.Pos[b4]=BlackPawn) then
        begin
          scoremid:=scoremid+(BishopTrapped div 2);
          scoreend:=scoreend+(BishopTrapped div 2);
        end;
      if (sq=h3) and (Board.Pos[g4]=BlackPawn) then
        begin
          scoremid:=scoremid+(BishopTrapped div 2);
          scoreend:=scoreend+(BishopTrapped div 2);
        end;
      if (sq=h7) and (Board.Pos[g6]=BlackPawn) then
        begin
          scoremid:=scoremid+(BishopTrapped div 2);
          scoreend:=scoreend+(BishopTrapped div 2);
        end;
      if (sq=a7) and (Board.Pos[b6]=BlackPawn) then
        begin
          scoremid:=scoremid+(BishopTrapped div 2);
          scoreend:=scoreend+(BishopTrapped div 2);
        end;
      if (sq=h8) and (Board.Pos[f6]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end;
      if (sq=a8) and (Board.Pos[c6]=WhitePawn) then
        begin
          scoremid:=scoremid+BishopTrapped;
          scoreend:=scoreend+BishopTrapped;
        end;

      BBAttacks:=BBAttacks or AttBB;
      if ((AttBB and WKingRing)<>0)  then
        begin
          Btropism:=Btropism+BishopTropism;
          if ((AttBB and WKingZone)<>0) then  inc(BPSaf);
        end;

      if ((AttBB and BkingZone)<>0) then
       begin
        scoremid:=scoremid-BGuardMid;
        scoreend:=scoreend-BGuardEnd;
       end;

      // динамика
      if (OnlyR00[sq] and WPAttacks)<>0 then
        begin
          scoremid:=scoremid+PAttMMid;
          scoreend:=scoreend+PAttMEnd;
          inc(wfork);
        end;

       if (AttBB and (not WPAttacks) and Board.Pieses[WhitePawn])<>0 then
        begin
          scoremid:=scoremid-BAttPMid;
          scoreend:=scoreend-BAttPEnd;
        end;
        if (AttBB and (not WPAttacks) and Board.Pieses[WhiteKnight])<>0 then
        begin
          scoremid:=scoremid-BAttNMid;
          scoreend:=scoreend-BAttNEnd;
        end;
        if (AttBB  and (Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen])<>0) then
        begin
          scoremid:=scoremid-MAttRQMid;
          scoreend:=scoreend-MAttRQEnd;
          inc(bfork);
        end;
     // подвижность
      MobBB:=AttBB and Bforward[sq] and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-BishopMobMid[idx];
      scoreend:=scoreend-BishopMobEnd[idx];
    end;
  WmobSpace:=not(Board.CPieses[white] or BPAttacks or BNAttacks or BBAttacks);
  BmobSpace:=not(Board.CPieses[black] or WPAttacks or WNAttacks or WBAttacks);
  // ладьи
  temp:=Board.Pieses[whiterook];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      x:=Posx[sq];
      y:=Posy[sq];
      scoremid:=scoremid+WRSQ[sq];
      AttBB:=RookMovesBB(sq,Board);
      // форпосты
       if ((OnlyR00[sq] and WhiteOutPost)<>0) and ((PawnIsoMaskBB[sq] and Wforward[sq] and Board.Pieses[BlackPawn])=0) then
         begin
           if (OnlyR00[sq] and WPAttacks)<>0 then
             begin
               scoremid:=scoremid+RookOutPostMid;
               scoreend:=scoreend+RookOutPostEnd;
               if (AttBB and (BkingZone or Wdyn) and RanksBB[y])<>0 then
                 begin
                   scoremid:=scoremid+RookOutPostStrongMid;
                   scoreend:=scoreend+RookOutPostStrongEnd;
                 end;
             end;
         end;
      WRAttacks:=WRAttacks or AttBB;
       if ((AttBB and BKingRing)<>0) then
        begin
          Wtropism:=Wtropism+RookTropism;
          if ((AttBB and BKingZone)<>0) then  inc(WPSaf);
        end;
      if ((AttBB and WkingZone)<>0) then
       begin
        scoremid:=scoremid+RGuardMid;
        scoremid:=scoremid+RGuardEnd;
       end;
      // динамика
      if (OnlyR00[sq] and BPAttacks)<>0 then
       begin
         scoremid:=scoremid-PAttRMid;
         scoreend:=scoreend-PAttREnd;
         inc(Bfork);
       end;

       if (AttBB and (not BPAttacks) and Board.Pieses[BlackPawn])<>0 then
        begin
          scoremid:=scoremid+RAttPMid;
          scoreend:=scoreend+RAttPEnd;
        end;
        if (AttBB and (not BPAttacks) and (Board.Pieses[BlackKnight] or Board.Pieses[BlackBishop]))<>0 then
        begin
          scoremid:=scoremid+RAttMMid;
          scoreend:=scoreend+RAttMEnd;
        end;
        if ((AttBB  and Board.Pieses[BlackQueen])<>0) then
        begin
          scoremid:=scoremid+RAttQMid;
          scoreend:=scoreend+RAttQEnd;
          inc(wfork);
        end;
     // подвижность
      MobBB:=AttBB and WMobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+RookMobMid[idx];
      scoreend:=scoreend+RookMobEnd[idx];

      if (PawnOpenFileMaskBB[white,sq] and Board.Pieses[whitepawn])=0 then
        begin
          scoremid:=scoremid+RookHalfFileMid;
          scoreend:=scoreend+RookHalfFileEnd;
          if (Bkingzone and PawnOpenFileMaskBB[white,sq])<>0 then
               begin
                 scoremid:=scoremid+RookLook;
               end;
          if (PawnOpenFileMaskBB[white,sq] and Board.Pieses[blackpawn])=0 then
            begin
             temp1:=BgoodMinor and PawnOpenFileMaskBB[white,sq];
             if temp1=0 then
               begin
                scoremid:=scoremid+RookOpenFileMid;
                scoreend:=scoreend+RookOpenFileEnd;
               end else
               begin
                 sq1:=BitScanForward(temp1);
                 if ((PawnIsoMaskBB[sq1] and Bforward[sq1] and Board.Pieses[WhitePawn])=0)
                   then begin
                     scoremid:=scoremid+RookOpenFixedMid;
                     scoreend:=scoreend+RookOpenFixedEnd;
                   end else
                   begin
                     scoremid:=scoremid+RookOpenMinorMid;
                     scoreend:=scoreend+RookOpenMinorEnd;
                   end;
               end;
            end else
            begin
              temp1:=Board.Pieses[BlackPawn] and PawnOpenFileMaskBB[white,sq];
              if temp1<>0 then
               begin
                 sq1:=BitScanForward(temp1);
                 if ((PawnIsoMaskBB[sq1] and Wforward[sq1] and Board.Pieses[BlackPawn])=0)
                   then begin
                     scoremid:=scoremid+RookHalfOpenPawnMid;
                     scoreend:=scoreend+RookHalfOpenPawnEnd;
                   end
               end;
            end
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
      if (y=8) and ((Posy[bking]=8))  then
        begin
          scoremid:=scoremid+Rookon8Mid;
          scoreend:=scoreend+RookOn8End;
        end;
      if (y=7) and ((Posy[bking]>=7) or ((RanksBB[7] and Board.Pieses[blackpawn])<>0)) then
        begin
          scoremid:=scoremid+RookOn7Mid;
          scoreend:=scoreend+RookOn7end;
          if ((AttBB and RanksBB[7] and (Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen]))<>0) and (posy[bking]=8) then
              begin
                scoremid:=scoremid+DoubleRook7Mid;
                scoreend:=scoreend+DoubleRook7End;
              end;
        end;
      if (y=6) and ((Posy[bking]>=6) or (((RanksBB[7] or RanksBB[6])and Board.Pieses[blackpawn])<>0)) then
        begin
          scoremid:=scoremid+RookOn6Mid;
          scoreend:=scoreend+RookOn6end;
        end;
    end;
  temp:=Board.Pieses[blackrook];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      temp:=temp and NotOnlyR00[sq];
      x:=Posx[sq];
      y:=Posy[sq];
      scoremid:=scoremid-WRSQ[63-sq];
      AttBB:=RookMovesBB(sq,Board);
      // форпосты
       if ((OnlyR00[sq] and BlackOutPost)<>0) and ((PawnIsoMaskBB[sq] and Bforward[sq] and Board.Pieses[WhitePawn])=0) then
         begin
           if (OnlyR00[sq] and BPAttacks)<>0 then
             begin
               scoremid:=scoremid-RookOutPostMid;
               scoreend:=scoreend-RookOutPostEnd;
               if (AttBB and (WkingZone or Bdyn) and RanksBB[y])<>0 then
                 begin
                   scoremid:=scoremid-RookOutPostStrongMid;
                   scoreend:=scoreend-RookOutPostStrongEnd;
                 end;
             end;
         end;
      BRAttacks:=BRAttacks or AttBB;
       if ((AttBB and WKingRing)<>0) then
        begin
          Btropism:=Btropism+RookTropism;
          if ((AttBB and WKingZone)<>0) then  inc(BPSaf);
        end;
      if ((AttBB and BkingZone)<>0) then
       begin
        scoremid:=scoremid-RGuardMid;
        scoremid:=scoremid-RGuardEnd;
       end;
      // динамика
      if (OnlyR00[sq] and WPAttacks)<>0 then
       begin
         scoremid:=scoremid+PAttRMid;
         scoreend:=scoreend+PAttREnd;
         inc(Wfork);
       end;

       if (AttBB and (not WPAttacks) and Board.Pieses[WhitePawn])<>0 then
        begin
          scoremid:=scoremid-RAttPMid;
          scoreend:=scoreend-RAttPEnd;
        end;
        if (AttBB and (not WPAttacks) and (Board.Pieses[WhiteKnight] or Board.Pieses[WhiteBishop]))<>0 then
        begin
          scoremid:=scoremid-RAttMMid;
          scoreend:=scoreend-RAttMEnd;
        end;
        if ((AttBB  and Board.Pieses[WhiteQueen])<>0) then
        begin
          scoremid:=scoremid-RAttQMid;
          scoreend:=scoreend-RAttQEnd;
          inc(bfork);
        end;
     // подвижность
      MobBB:=AttBB and BMobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-RookMobMid[idx];
      scoreend:=scoreend-RookMobEnd[idx];

      if (PawnOpenFileMaskBB[black,sq] and Board.Pieses[blackpawn])=0 then
        begin
          scoremid:=scoremid-RookHalfFileMid;
          scoreend:=scoreend-RookHalfFileEnd;
          if (Wkingzone and PawnOpenFileMaskBB[black,sq])<>0 then
               begin
                 scoremid:=scoremid-RookLook;
               end;
          if (PawnOpenFileMaskBB[black,sq] and Board.Pieses[whitepawn])=0 then
            begin
             temp1:=WgoodMinor and PawnOpenFileMaskBB[black,sq];
             if temp1=0 then
               begin
                scoremid:=scoremid-RookOpenFileMid;
                scoreend:=scoreend-RookOpenFileEnd;
               end else
               begin
                 sq1:=BitScanBackward(temp1);
                 if ((PawnIsoMaskBB[sq1] and Wforward[sq1] and Board.Pieses[BlackPawn])=0)
                   then begin
                     scoremid:=scoremid-RookOpenFixedMid;
                     scoreend:=scoreend-RookOpenFixedEnd;
                   end else
                   begin
                     scoremid:=scoremid-RookOpenMinorMid;
                     scoreend:=scoreend-RookOpenMinorEnd;
                   end;
               end;
            end else
            begin
              temp1:=Board.Pieses[WhitePawn] and PawnOpenFileMaskBB[black,sq];
              if temp1<>0 then
               begin
                 sq1:=BitScanBackward(temp1);
                 if ((PawnIsoMaskBB[sq1] and Bforward[sq1] and Board.Pieses[WhitePawn])=0)
                   then begin
                     scoremid:=scoremid-RookHalfOpenPawnMid;
                     scoreend:=scoreend-RookHalfOpenPawnEnd;
                   end
               end;
            end
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

      if (y=1) and ((Posy[wking]=1))  then
        begin
          scoremid:=scoremid-Rookon8Mid;
          scoreend:=scoreend-RookOn8End;
        end;
      if (y=2) and ((Posy[wking]<=2) or ((RanksBB[2] and Board.Pieses[whitepawn])<>0)) then
        begin
          scoremid:=scoremid-RookOn7Mid;
          scoreend:=scoreend-RookOn7end;
          if ((AttBB and RanksBB[2] and (Board.Pieses[BlackRook] or Board.Pieses[BlackQueen]))<>0) and (posy[wking]=1) then
              begin
                scoremid:=scoremid-DoubleRook7Mid;
                scoreend:=scoreend-DoubleRook7End;
              end;
        end;
      if (y=3) and ((Posy[wking]<=3) or (((RanksBB[2] or RanksBB[3])and Board.Pieses[whitepawn])<>0)) then
        begin
          scoremid:=scoremid-RookOn6Mid;
          scoreend:=scoreend-RookOn6end;
        end;
    end;
  WmobSpace:=not(Board.CPieses[white] or BPAttacks or BNAttacks or BBAttacks or BRAttacks);
  BmobSpace:=not(Board.CPieses[black] or WPAttacks or WNAttacks or WBAttacks or WRAttacks);
   // ферзи
  temp:=Board.Pieses[whitequeen];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      y:=posy[sq];
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid+WQSQ[sq];
      scoreend:=scoreend+WQESQ[sq];
      AttBB:=QueenMovesBB(sq,Board);
      WQAttacks:=WQAttacks or AttBB;
      if ((AttBB and BKingRing)<>0) then
        begin
          Wtropism:=Wtropism+QueenTropism;
          if ((AttBB and BKingZone)<>0) then inc(WPSaf);
        end ;

      if ((AttBB and WkingZone)<>0) then
        begin
         scoremid:=scoremid+QGuardMid;
         scoreend:=scoreend+QGuardEnd;
        end;
      if (OnlyR00[sq] and BPAttacks)<>0 then
       begin
         inc(Bfork);
         scoremid:=scoremid-PAttQMid;
         scoreend:=scoreend-PAttQEnd;
       end;
      // динамика
       if (AttBB and Wdyn)<>0 then
        begin
          scoremid:=scoremid+QDynMid;
          scoreend:=scoreend+QDynEnd;
        end;
     if y=7 then
       begin
         if ((Board.Pieses[BlackPawn] or OnlyR00[bking]) and Ranks78)<>0 then
           begin
             scoremid:=scoremid+Queenon7Mid;
             scoreend:=scoreend+Queenon7End;
             if ((AttBB and RanksBB[7] and Board.Pieses[WhiteRook])<>0) and (posy[bking]=8) then
              begin
                scoremid:=scoremid+QueenRook7Mid;
                scoreend:=scoreend+QueenRook7End;
              end;
           end;
       end;
     // подвижность
      MobBB:=AttBB and WmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid+2*idx;
      scoreend:=scoreend+2*idx;
    end;
  temp:=Board.Pieses[blackqueen];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      y:=posy[sq];
      temp:=temp and NotOnlyR00[sq];
      scoremid:=scoremid-WQSQ[63-sq];
      scoreend:=scoreend-WQESQ[63-sq];
      AttBB:=QueenMovesBB(sq,Board);
      BQAttacks:=BQAttacks or AttBB;
      if ((AttBB and WKingRing)<>0) then
        begin
          Btropism:=Btropism+QueenTropism;
          if ((AttBB and WKingZone)<>0) then inc(BPSaf);
        end ;

      if ((AttBB and BkingZone)<>0) then
       begin
        scoremid:=scoremid-QGuardMid;
        scoreend:=scoreend-QGuardEnd;
       end;
      if (OnlyR00[sq] and WPAttacks)<>0 then
       begin
         inc(Wfork);
         scoremid:=scoremid+PAttQMid;
         scoreend:=scoreend+PAttQEnd;
       end;
      // динамика
      if (AttBB and Bdyn)<>0 then
        begin
          scoremid:=scoremid-QDynMid;
          scoreend:=scoreend-QDynEnd;
        end;
      if y=2 then
       begin
         if ((Board.Pieses[WhitePawn] or OnlyR00[wking]) and Ranks12)<>0 then
           begin
             scoremid:=scoremid-Queenon7Mid;
             scoreend:=scoreend-Queenon7End;
             if ((AttBB and RanksBB[2] and Board.Pieses[BlackRook])<>0) and (posy[wking]=1) then
              begin
                scoremid:=scoremid-QueenRook7Mid;
                scoreend:=scoreend-QueenRook7End;
              end;
           end;
       end;
     // подвижность
      MobBB:=AttBB and BmobSpace;
      idx:=BitCount(MobBB);
      scoremid:=scoremid-2*idx;
      scoreend:=scoreend-2*idx;
    end;
  if wfork>1 then
    begin
      scoremid:=scoremid+ForkScaleMid;
      scoreend:=scoreend+ForkScaleEnd;
    end;
  if bfork>1 then
    begin
      scoremid:=scoremid-ForkScaleMid;
      scoreend:=scoreend-ForkScaleEnd;
    end;

  WALLAttacks:=WPAttacks or WNAttacks or WBAttacks or WRAttacks or WQAttacks or WKAttacks;
  BALLAttacks:=BPAttacks or BNAttacks or BBAttacks or BRAttacks or BQAttacks or BKAttacks;



  if (WkingZone and BkingZone)<>0 then
    begin
      inc(WPSaf);
      inc(BPsaf);
    end;

  saf:=(((Wtropism)*KPSafety[WPSaf]) div 8);
  if Board.Pieses[WhiteQueen]=0 then
    begin
      temp:=Board.Pieses[WhiteKnight] or Board.Pieses[WhiteBishop] or Board.Pieses[WhiteRook];
      saf:=(saf*BitCount(temp)) div 8;
    end;
  saf:=saf+bshelter;
  scoremid:=scoremid+saf;
  if saf>dangereval then dangereval:=saf;

  saf:=(((Btropism)*KPSafety[BPSaf]) div 8);
  if Board.Pieses[BlackQueen]=0 then
    begin
      temp:=Board.Pieses[BlackKnight] or Board.Pieses[BlackBishop] or Board.Pieses[BlackRook];
      saf:=(saf*BitCount(temp)) div 8;
    end;
  saf:=saf+wshelter;
  scoremid:=scoremid-saf;
  if saf>dangereval then dangereval:=saf;
  if dangereval>255 then dangereval:=255;

  scoremid:=scoremid-WKBSQ[63-Board.KingSq[black]]+WKBSQ[Board.KingSq[white]];
  // Эндшпильная оценка короля
  scoreend:=scoreend+WKESQ[Board.KingSq[white]]-WKESQ[63-Board.KingSq[black]];
  temp:=KingAttacksBB[wking] and Board.Pieses[BlackPawn] and (not BPAttacks);

  if temp<>0 then scoreend:=scoreend+BitCount(temp)*ActiveKing;
  temp:=KingAttacksBB[bking] and Board.Pieses[WhitePawn] and (not WPAttacks);
  if temp<>0 then scoreend:=scoreend-BitCount(temp)*ActiveKing;

  temp:=(Board.Pieses[blackknight] or Board.Pieses[blackbishop]) and (not BAllAttacks);
  if temp<>0 then
    begin
      scoremid:=scoremid+MinorsUndefendedMid;
      scoreend:=scoreend+MinorsUndefendedEnd;
    end;
  temp:=(Board.Pieses[whiteknight] or Board.Pieses[whitebishop]) and (not WAllAttacks);
  if temp<>0 then
    begin
      scoremid:=scoremid-MinorsUndefendedMid;
      scoreend:=scoreend-MinorsUndefendedEnd;
    end;

  if PawnTable[indexpawn].PasserBB<>0 then EvalPasser(Board,scoremid,scoreend,PawnTable[indexpawn].PasserBB,WAllAttacks,BAllAttacks,indexmat);
ex:
   if Board.color=white then
    begin
      scoremid:=scoremid+TempoMid;
      scoreend:=scoreend+TempoEnd;
    end else
    begin
      scoremid:=scoremid-TempoMid;
      scoreend:=scoreend-TempoEnd;
    end;
  score:=(scoremid*Mattable[indexmat].phase+(32-Mattable[indexmat].phase)*scoreend) div 32;

  if (score>0) and (MatTable[indexmat].Wmul<>10) then score:=(score*MatTable[indexmat].Wmul) div 10 else
  if (score<0) and (MatTable[indexmat].Bmul<>10) then score:=(score*MatTable[indexmat].Bmul) div 10;
   // Разнопольные слоны
 if (MatTable[indexmat].flag and DifColorBishopFlag)<>0 then
   begin
     if (((Board.Pieses[WhiteBishop] and light)<>0) and ((Board.Pieses[BlackBishop] and dark)<>0)) or
        (((Board.Pieses[WhiteBishop] and dark)<>0) and ((Board.Pieses[BlackBishop] and light)<>0)) then score:=score div 2;
   end;

  if Board.Color=black then score:=-score;
  Result:=score;
end;

end.
