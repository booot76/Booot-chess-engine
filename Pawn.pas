unit Pawn;

interface
 uses params,board,material;
TYPE
    Tshelter = array[1..8] of byte;
    TPawnHash = record
                  PawnKey  : TPawnKey;
                  scoremid : smallint;
                  scoreend : smallint;
                  PasserBB : TBitBoard;
                  wshelter : integer;
                  bshelter : integer;
                end;
CONST
    PawnIsoMaskBB : TBBLine =
($0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040);

    PawnOpenFileMaskBB: TBBColorLine =
(($0101010101010100,$0202020202020200,$0404040404040400,$0808080808080800,$1010101010101000,$2020202020202000,$4040404040404000,$8080808080808000,
$0101010101010000,$0202020202020000,$0404040404040000,$0808080808080000,$1010101010100000,$2020202020200000,$4040404040400000,$8080808080800000,
$0101010101000000,$0202020202000000,$0404040404000000,$0808080808000000,$1010101010000000,$2020202020000000,$4040404040000000,$8080808080000000,
$0101010100000000,$0202020200000000,$0404040400000000,$0808080800000000,$1010101000000000,$2020202000000000,$4040404000000000,$8080808000000000,
$0101010000000000,$0202020000000000,$0404040000000000,$0808080000000000,$1010100000000000,$2020200000000000,$4040400000000000,$8080800000000000,
$0101000000000000,$0202000000000000,$0404000000000000,$0808000000000000,$1010000000000000,$2020000000000000,$4040000000000000,$8080000000000000,
$0100000000000000,$0200000000000000,$0400000000000000,$0800000000000000,$1000000000000000,$2000000000000000,$4000000000000000,$8000000000000000,
$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000
),($0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,
$0000000000000001,$0000000000000002,$0000000000000004,$0000000000000008,$0000000000000010,$0000000000000020,$0000000000000040,$0000000000000080,
$0000000000000101,$0000000000000202,$0000000000000404,$0000000000000808,$0000000000001010,$0000000000002020,$0000000000004040,$0000000000008080,
$0000000000010101,$0000000000020202,$0000000000040404,$0000000000080808,$0000000000101010,$0000000000202020,$0000000000404040,$0000000000808080,
$0000000001010101,$0000000002020202,$0000000004040404,$0000000008080808,$0000000010101010,$0000000020202020,$0000000040404040,$0000000080808080,
$0000000101010101,$0000000202020202,$0000000404040404,$0000000808080808,$0000001010101010,$0000002020202020,$0000004040404040,$0000008080808080,
$0000010101010101,$0000020202020202,$0000040404040404,$0000080808080808,$0000101010101010,$0000202020202020,$0000404040404040,$0000808080808080,
$0001010101010101,$0002020202020202,$0004040404040404,$0008080808080808,$0010101010101010,$0020202020202020,$0040404040404040,$0080808080808080));

    PawnChainMaskBB : TBBColorLine =
(($0000000000000002,$0000000000000005,$000000000000000A,$0000000000000014,$0000000000000028,$0000000000000050,$00000000000000A0,$0000000000000040,
$0000000000000202,$0000000000000505,$0000000000000A0A,$0000000000001414,$0000000000002828,$0000000000005050,$000000000000A0A0,$0000000000004040,
$0000000000020200,$0000000000050500,$00000000000A0A00,$0000000000141400,$0000000000282800,$0000000000505000,$0000000000A0A000,$0000000000404000,
$0000000002020000,$0000000005050000,$000000000A0A0000,$0000000014140000,$0000000028280000,$0000000050500000,$00000000A0A00000,$0000000040400000,
$0000000202000000,$0000000505000000,$0000000A0A000000,$0000001414000000,$0000002828000000,$0000005050000000,$000000A0A0000000,$0000004040000000,
$0000020200000000,$0000050500000000,$00000A0A00000000,$0000141400000000,$0000282800000000,$0000505000000000,$0000A0A000000000,$0000404000000000,
$0002020000000000,$0005050000000000,$000A0A0000000000,$0014140000000000,$0028280000000000,$0050500000000000,$00A0A00000000000,$0040400000000000,
$0002000000000000,$0005000000000000,$000A000000000000,$0014000000000000,$0028000000000000,$0050000000000000,$00A0000000000000,$0040000000000000
),($0000000000000200,$0000000000000500,$0000000000000A00,$0000000000001400,$0000000000002800,$0000000000005000,$000000000000A000,$0000000000004000,
$0000000000020200,$0000000000050500,$00000000000A0A00,$0000000000141400,$0000000000282800,$0000000000505000,$0000000000A0A000,$0000000000404000,
$0000000002020000,$0000000005050000,$000000000A0A0000,$0000000014140000,$0000000028280000,$0000000050500000,$00000000A0A00000,$0000000040400000,
$0000000202000000,$0000000505000000,$0000000A0A000000,$0000001414000000,$0000002828000000,$0000005050000000,$000000A0A0000000,$0000004040000000,
$0000020200000000,$0000050500000000,$00000A0A00000000,$0000141400000000,$0000282800000000,$0000505000000000,$0000A0A000000000,$0000404000000000,
$0002020000000000,$0005050000000000,$000A0A0000000000,$0014140000000000,$0028280000000000,$0050500000000000,$00A0A00000000000,$0040400000000000,
$0202000000000000,$0505000000000000,$0A0A000000000000,$1414000000000000,$2828000000000000,$5050000000000000,$A0A0000000000000,$4040000000000000,
$0200000000000000,$0500000000000000,$0A00000000000000,$1400000000000000,$2800000000000000,$5000000000000000,$A000000000000000,$4000000000000000));

   PawnPasserMaskBB : TBBColorLine =
(($0303030303030300,$0707070707070700,$0E0E0E0E0E0E0E00,$1C1C1C1C1C1C1C00,$3838383838383800,$7070707070707000,$E0E0E0E0E0E0E000,$C0C0C0C0C0C0C000,
$0303030303030000,$0707070707070000,$0E0E0E0E0E0E0000,$1C1C1C1C1C1C0000,$3838383838380000,$7070707070700000,$E0E0E0E0E0E00000,$C0C0C0C0C0C00000,
$0303030303000000,$0707070707000000,$0E0E0E0E0E000000,$1C1C1C1C1C000000,$3838383838000000,$7070707070000000,$E0E0E0E0E0000000,$C0C0C0C0C0000000,
$0303030300000000,$0707070700000000,$0E0E0E0E00000000,$1C1C1C1C00000000,$3838383800000000,$7070707000000000,$E0E0E0E000000000,$C0C0C0C000000000,
$0303030000000000,$0707070000000000,$0E0E0E0000000000,$1C1C1C0000000000,$3838380000000000,$7070700000000000,$E0E0E00000000000,$C0C0C00000000000,
$0303000000000000,$0707000000000000,$0E0E000000000000,$1C1C000000000000,$3838000000000000,$7070000000000000,$E0E0000000000000,$C0C0000000000000,
$0300000000000000,$0700000000000000,$0E00000000000000,$1C00000000000000,$3800000000000000,$7000000000000000,$E000000000000000,$C000000000000000,
$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000
),($0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,$0000000000000000,
$0000000000000003,$0000000000000007,$000000000000000E,$000000000000001C,$0000000000000038,$0000000000000070,$00000000000000E0,$00000000000000C0,
$0000000000000303,$0000000000000707,$0000000000000E0E,$0000000000001C1C,$0000000000003838,$0000000000007070,$000000000000E0E0,$000000000000C0C0,
$0000000000030303,$0000000000070707,$00000000000E0E0E,$00000000001C1C1C,$0000000000383838,$0000000000707070,$0000000000E0E0E0,$0000000000C0C0C0,
$0000000003030303,$0000000007070707,$000000000E0E0E0E,$000000001C1C1C1C,$0000000038383838,$0000000070707070,$00000000E0E0E0E0,$00000000C0C0C0C0,
$0000000303030303,$0000000707070707,$0000000E0E0E0E0E,$0000001C1C1C1C1C,$0000003838383838,$0000007070707070,$000000E0E0E0E0E0,$000000C0C0C0C0C0,
$0000030303030303,$0000070707070707,$00000E0E0E0E0E0E,$00001C1C1C1C1C1C,$0000383838383838,$0000707070707070,$0000E0E0E0E0E0E0,$0000C0C0C0C0C0C0,
$0003030303030303,$0007070707070707,$000E0E0E0E0E0E0E,$001C1C1C1C1C1C1C,$0038383838383838,$0070707070707070,$00E0E0E0E0E0E0E0,$00C0C0C0C0C0C0C0));

    PawnBackwardMaskBB :TBBColorLine =
(($0000000000000002,$0000000000000005,$000000000000000A,$0000000000000014,$0000000000000028,$0000000000000050,$00000000000000A0,$0000000000000040,
$0000000000000202,$0000000000000505,$0000000000000A0A,$0000000000001414,$0000000000002828,$0000000000005050,$000000000000A0A0,$0000000000004040,
$0000000000020202,$0000000000050505,$00000000000A0A0A,$0000000000141414,$0000000000282828,$0000000000505050,$0000000000A0A0A0,$0000000000404040,
$0000000002020202,$0000000005050505,$000000000A0A0A0A,$0000000014141414,$0000000028282828,$0000000050505050,$00000000A0A0A0A0,$0000000040404040,
$0000000202020202,$0000000505050505,$0000000A0A0A0A0A,$0000001414141414,$0000002828282828,$0000005050505050,$000000A0A0A0A0A0,$0000004040404040,
$0000020202020202,$0000050505050505,$00000A0A0A0A0A0A,$0000141414141414,$0000282828282828,$0000505050505050,$0000A0A0A0A0A0A0,$0000404040404040,
$0002020202020202,$0005050505050505,$000A0A0A0A0A0A0A,$0014141414141414,$0028282828282828,$0050505050505050,$00A0A0A0A0A0A0A0,$0040404040404040,
$0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040
),($0202020202020202,$0505050505050505,$0A0A0A0A0A0A0A0A,$1414141414141414,$2828282828282828,$5050505050505050,$A0A0A0A0A0A0A0A0,$4040404040404040,
$0202020202020200,$0505050505050500,$0A0A0A0A0A0A0A00,$1414141414141400,$2828282828282800,$5050505050505000,$A0A0A0A0A0A0A000,$4040404040404000,
$0202020202020000,$0505050505050000,$0A0A0A0A0A0A0000,$1414141414140000,$2828282828280000,$5050505050500000,$A0A0A0A0A0A00000,$4040404040400000,
$0202020202000000,$0505050505000000,$0A0A0A0A0A000000,$1414141414000000,$2828282828000000,$5050505050000000,$A0A0A0A0A0000000,$4040404040000000,
$0202020200000000,$0505050500000000,$0A0A0A0A00000000,$1414141400000000,$2828282800000000,$5050505000000000,$A0A0A0A000000000,$4040404000000000,
$0202020000000000,$0505050000000000,$0A0A0A0000000000,$1414140000000000,$2828280000000000,$5050500000000000,$A0A0A00000000000,$4040400000000000,
$0202000000000000,$0505000000000000,$0A0A000000000000,$1414000000000000,$2828000000000000,$5050000000000000,$A0A0000000000000,$4040000000000000,
$0200000000000000,$0500000000000000,$0A00000000000000,$1400000000000000,$2800000000000000,$5000000000000000,$A000000000000000,$4000000000000000));

    Posy : TBytesArray =
(1,1,1,1,1,1,1,1,
 2,2,2,2,2,2,2,2,
 3,3,3,3,3,3,3,3,
 4,4,4,4,4,4,4,4,
 5,5,5,5,5,5,5,5,
 6,6,6,6,6,6,6,6,
 7,7,7,7,7,7,7,7,
 8,8,8,8,8,8,8,8);
   Posx : TBytesArray =
(1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8,
 1,2,3,4,5,6,7,8);


    WPMidSQ : TbytesArray =
     (
          0,  0,  0,  0,  0,  0,  0,  0,
        -10, -5,  0,  5,  5,  0, -5, -10,
        -10, -5,  4, 15 ,15 , 4, -5, -10,
        -10, -5,  8, 25, 25,  8, -5, -10,
        -10, -5,  4, 15, 15,  4, -5, -10,
        -10, -5,  2,  5,  5,  2, -5, -10,
        -10, -5,  0,  5,  5,  0, -5, -10,
          0,  0,  0,  0,  0,  0,  0,   0
      );

DoubledPawnMid  = 8;
DoubledPawnEnd  = 16;
IsolatedPawnMid = 14;
IsolatedPawnEnd = 14;
BackWardPawnMid = 10;
BackWardPawnEnd = 12;
OpenIsoMid=10;
OpenIsoEnd=0;
OpenBackMid=10;
OpenBackEnd=0;
OpenDoubledMid=0;
OpenDoubledEnd=0;

ChainPawnMid   : TFileArray = ( 4, 4, 4, 5, 5, 4, 4, 4);
ChainPawnEnd   : TFileArray = ( 0, 0, 0, 0, 0, 0, 0, 0);

CandidatPasserMid : TRankArray = (0,2,2, 5,13,32,0,0);
CandidatPasserEnd : TRankArray = (0,4,4,10,26,64,0,0);

PasserBaseMid  : TRankArray = (0, 0, 0,15,45,90,150,0);
PasserBaseEnd  : TrankArray = (0,10,10,20,40,80,120,0);
QueenEnd       : TrankArray = (0, 0, 0, 5,10,20, 40,0);
PasserStrongEnd: TRankArray = (0,0,8,16,24,32,40,0);

MyKingDist     : TRankArray = (0,0,0,3, 9,18,30,0);
OPKingDist     : TRankArray = (0,0,0,5,14,27,45,0);

FreePasserSupported    : TRankArray = (0,0,0,13,40,80,120,0);
FreePasser             : TrankArray = (0,0,0,12,35,70,110,0);

BlockedPasserSupported : TrankArray = (0,0,0,10,30,60,100,0);
BlockedPasser          : TrankArray = (0,0,0, 6,18,36, 60,0);

FreeWay                : TrankArray = (0,0,0, 1,3,5,10,0);




VAR
   PawnTable : array of TPawnHash;

Function EvalPawn(var Board:Tboard):integer;
Function KingDist(kingsq:Tsquare;PawnSQ:Tsquare):integer;
Procedure EvalPasser(var Board:Tboard;var scoremid:integer;var scoreend:integer;PassersBB:TbitBoard;Watt:TbitBoard;BAtt:TbitBoard;indexmat:integer);
implementation
uses BitBoards,movegen,safety,attacks,evaluation;

Function EvalPawn(var Board:Tboard):integer;
var
   index,scoremid,scoreend,att,def,x,y : integer;
   sq,i : TSquare;
   PasserBB,Temp,temp1,WhitePawns,BlackPawns,AllPawns : TBitBoard;
   passer,strong,isolated,backward,doubled,candidat : Boolean;
   p1,p2,p3,p4 : int64;
   r:int64;
    wkside,wqside,wd,we,bkside,bqside,bd,be,wlight,blight,wdark,bdark : integer;

begin
  index:=Board.Pawnkey and HashPawnMask;
  result:=index;
  if Board.Pawnkey=PawnTable[index].PawnKey then exit;
  scoremid:=0;
  scoreend:=0;
  PasserBB:=0;
  wlight:=0;blight:=0;wdark:=0;bdark:=0;
  WhitePawns:=Board.Pieses[WhitePawn];
  BlackPawns:=Board.Pieses[BlackPawn];
  AllPawns:=WhitePawns or BlackPawns;
  Temp:=WhitePawns;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=Posy[sq];
      scoremid:=scoremid+WPMidSQ[sq];
      if ((PawnOpenFileMaskBB[white,sq] and WhitePawns)<>0) then doubled:=true else doubled:=false;
      if ((PawnChainMaskBB[white,sq] and WhitePawns)<>0) then strong:=true else strong:=false;
      if ((PawnPasserMaskBB[white,sq] and BlackPawns)=0) then passer:=true else passer:=false;
      if ((PawnIsoMaskBB[sq] and WhitePawns)=0) then isolated:=true else isolated:=false;
      if (passer) or (strong) or (isolated) or ((PawnBackWardMaskBB[white,sq] and WhitePawns)<>0) or ((PawnAttacksBB[white,sq] and BlackPawns)<>0) then backward:=false else
        begin
          backward:=true;
          i:=sq;
          while i<a8 do
            begin
              if (OnlyR00[i+8] and AllPawns)<>0 then break;
              if (PawnAttacksBB[white,i+8] and BlackPawns)<>0 then break;
              if (PawnAttacksBB[black,i+8] and WhitePawns)<>0 then
               begin
                backward:=false;
                break;
               end;
              i:=i+8;
            end;
        end;
      candidat:=false;
      if (not passer) and ((PawnOpenFileMaskBB[white,sq] and BlackPawns)=0) then
        begin
          temp1:=PawnBackWardMaskBB[white,sq] and WhitePawns;
          att:=BitCount(temp1);
          temp1:=PawnBackWardMaskBB[black,sq+8] and BlackPawns;
          def:=BitCount(temp1);
          if att>=def then candidat:=true;
        end;
      if (passer) and (doubled)  then passer:=false;
      if passer then
        begin
          PasserBB:=PasserBB or OnlyR00[sq];
          scoremid:=scoremid+PasserBaseMid[y];
        end;
      if isolated then
        begin
          scoremid:=scoremid-IsolatedPawnMid;
          scoreend:=scoreend-IsolatedPawnEnd;
          if ((PawnOpenFileMaskBB[white,sq] and BlackPawns)=0) then
           begin
            scoremid:=scoremid-OpenIsoMid;
            scoreend:=scoreend-OpenIsoEnd;
           end;
        end;
      if backward then
        begin
          scoremid:=scoremid-BackWardPawnMid;
          scoreend:=scoreend-BackWardPawnEnd;
          if ((PawnOpenFileMaskBB[white,sq] and BlackPawns)=0) then
           begin
             scoremid:=scoremid-OpenBackMid;
             scoreend:=scoreend-OpenBackEnd;
           end;
        end;
      if doubled then
        begin
          scoremid:=scoremid-DoubledPawnMid;
          scoreend:=scoreend-DoubledPawnEnd;
          if ((PawnOpenFileMaskBB[white,sq] and BlackPawns)=0) then
           begin
             scoremid:=scoremid-OpenDoubledMid;
             scoreend:=scoreend-OpenDoubledEnd;
           end;
        end;
      if strong then
        begin
          scoremid:=scoremid+ChainPawnMid[x];
          scoreend:=scoreend+ChainPawnEnd[x];
        end;
      if candidat then
        begin
          scoremid:=scoremid+CandidatPasserMid[y];
          scoreend:=scoreend+CandidatPasserEnd[y];
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
  Temp:=BlackPawns;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=9-Posy[sq];
      scoremid:=scoremid-WPMidSQ[63-sq];
      if ((PawnOpenFileMaskBB[black,sq] and BlackPawns)<>0) then doubled:=true else doubled:=false;
      if ((PawnChainMaskBB[black,sq] and BlackPawns)<>0) then strong:=true else strong:=false;
      if ((PawnPasserMaskBB[black,sq] and WhitePawns)=0) then passer:=true else passer:=false;
      if ((PawnIsoMaskBB[sq] and BlackPawns)=0) then isolated:=true else isolated:=false;
      if (passer) or (strong) or (isolated) or ((PawnBackWardMaskBB[black,sq] and BlackPawns)<>0) or ((PawnAttacksBB[black,sq] and WhitePawns)<>0) then backward:=false else
        begin
          backward:=true;
          i:=sq;
          while i>h1 do
            begin
              if (OnlyR00[i-8] and AllPawns)<>0 then break;
              if (PawnAttacksBB[black,i-8] and WhitePawns)<>0 then break;
              if (PawnAttacksBB[white,i-8] and BlackPawns)<>0 then
               begin
                backward:=false;
                break;
               end;
              i:=i-8;
            end;
        end;
      candidat:=false;
      if (not passer) and ((PawnOpenFileMaskBB[black,sq] and WhitePawns)=0) then
        begin
          temp1:=PawnBackWardMaskBB[black,sq] and BlackPawns;
          att:=BitCount(temp1);
          temp1:=PawnBackWardMaskBB[white,sq-8] and WhitePawns;
          def:=BitCount(temp1);
          if att>=def then candidat:=true;
        end;
      if (passer) and (doubled)  then passer:=false;
      if passer then
        begin
          PasserBB:=PasserBB or OnlyR00[sq];
          scoremid:=scoremid-PasserBaseMid[y];
        end;
      if isolated then
        begin
          scoremid:=scoremid+IsolatedPawnMid;
          scoreend:=scoreend+IsolatedPawnEnd;
          if ((PawnOpenFileMaskBB[black,sq] and WhitePawns)=0) then
           begin
            scoremid:=scoremid+OpenIsoMid;
            scoreend:=scoreend+OpenIsoEnd;
           end;
        end;
      if backward then
        begin
          scoremid:=scoremid+BackWardPawnMid;
          scoreend:=scoreend+BackWardPawnEnd;
          if ((PawnOpenFileMaskBB[black,sq] and WhitePawns)=0) then
           begin
            scoremid:=scoremid+OpenBackMid;
            scoreend:=scoreend+OpenBackEnd;
           end;
        end;
      if doubled then
        begin
          scoremid:=scoremid+DoubledPawnMid;
          scoreend:=scoreend+DoubledPawnEnd;
          if ((PawnOpenFileMaskBB[black,sq] and WhitePawns)=0) then
           begin
            scoremid:=scoremid+OpenDoubledMid;
            scoreend:=scoreend+OpenDoubledEnd;
           end;
        end;
      if strong then
        begin
          scoremid:=scoremid-ChainPawnMid[x];
          scoreend:=scoreend-ChainPawnEnd[x];
        end;
      if candidat then
        begin
          scoremid:=scoremid-CandidatPasserMid[y];
          scoreend:=scoreend-CandidatPasserEnd[y];
        end;
      temp:=temp and NotOnlyR00[sq];
    end;
  // Прикрытия для короля
  wkside:=Wlocation(Board,7,8,6); if wkside>255 then wkside:=255;
  wqside:=Wlocation(Board,2,1,3); if wqside>255 then wqside:=255;
  wd:=Wlocation(Board,4,3,5);if wd>255 then wd:=255;
  we:=Wlocation(Board,5,6,4);if we>255 then we:=255;
  bkside:=Blocation(Board,7,8,6); if bkside>255 then bkside:=255;
  bqside:=Blocation(Board,2,1,3); if bqside>255 then bqside:=255;
  bd:=Blocation(Board,4,3,5);if bd>255 then bd:=255;
  be:=Blocation(Board,5,6,4);if be>255 then be:=255;
 // Сохраняем
  PawnTable[index].PawnKey:=Board.Pawnkey;
  PawnTable[index].scoremid:=scoremid;
  PawnTable[index].scoreend:=scoreend;
  PawnTable[index].PasserBB:=PasserBB;
  PawnTable[index].Wshelter:=wqside or (wd shl 8) or (we shl 16) or (wkside shl 24);
  PawnTable[index].Bshelter:=bqside or (bd shl 8) or (be shl 16) or (bkside shl 24);

end;
Procedure EvalPasser(var Board:Tboard;var scoremid:integer;var scoreend:integer;PassersBB:TbitBoard;Watt:TbitBoard;BAtt:TbitBoard;indexmat:integer);
var
  temp,way,behind,MY,OPP,t1 : TBitBoard;
  sq,major : Tsquare;
  y,bonus : integer;
begin
  temp:=PassersBB and Board.Pieses[WhitePawn];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      y:=posy[sq];
      temp:=temp and NotOnlyR00[sq];
      bonus:=PasserBaseEnd[y];
      if (MatTable[indexmat].flag and QueenEndgame)<>0 then bonus:=bonus+QueenEnd[y];
      if ((PawnChainMaskBB[White,sq] and Board.Pieses[WhitePawn])<>0) then bonus:=bonus+PasserStrongEnd[y];
      bonus:=bonus+KingDist(Board.KingSq[black],sq+8)*OpKingDist[y];
      bonus:=bonus-KingDist(Board.KingSq[white],sq+8)*MyKingDist[y];
      if (Board.Pos[sq+8]=Empty) then
       begin
        way:=PawnOpenFileMaskBB[white,sq];
        behind:=PawnOpenFileMaskBB[black,sq];
        MY:=way and Watt;
        OPP:=way and (Batt or Board.CPieses[black]);
        t1:=(Board.Pieses[BlackRook] or Board.Pieses[BlackQueen]);
        if ( t1 and behind)<>0 then
         begin
           major:=BitScanBackWard(t1);
           if (Intersect[major,sq] and Board.AllPieses)=0 then opp:=way;
         end;
        if opp=0 then
            begin
               if way=My
                then bonus:=bonus+FreePasserSupported[y]
                else bonus:=bonus+FreePasser[y];
            end else
            begin
              if ((opp and My)=opp)
               then bonus:=bonus+BlockedPasserSupported[y]
               else bonus:=bonus+BlockedPasser[y];
            end;
       if (way and Board.CPieses[white])=0 then bonus:=bonus+FreeWay[y];
      end;
     if  ((MatTable[indexmat].flag and RookEndgame)<>0) and ((PawnOpenFileMaskBB[white,sq] and Board.Pieses[WhiteRook])<>0) then  bonus:=bonus-BadRook[y];
     if  ((MatTable[indexmat].flag and QueenEndgame)<>0) and ((PawnOpenFileMaskBB[white,sq] and Board.Pieses[WhiteQueen])<>0) then bonus:=bonus-BadQueen[y];
     if bonus<0 then bonus:=0;
     if (posx[sq] in [1,8]) then
       begin
         if (Board.Pieses[BlackQueen] or Board.Pieses[BlackRook])<>0 then bonus:=bonus-(bonus div 4) else
           if Board.Pieses[BlackBishop]=0 then bonus:=bonus+(bonus div 4);
       end;
     scoreend:=scoreend+bonus;
    end;
  temp:=PassersBB and Board.Pieses[BlackPawn];
  while temp<>0 do
    begin
     sq:=BitScanForward(temp);
     y:=9-posy[sq];
     temp:=temp and NotOnlyR00[sq];
     bonus:=PasserBaseEnd[y];
     if (MatTable[indexmat].flag and QueenEndgame)<>0 then bonus:=bonus+QueenEnd[y];
     if ((PawnChainMaskBB[black,sq] and Board.Pieses[BlackPawn])<>0) then bonus:=bonus+PasserStrongEnd[y];
     bonus:=bonus+KingDist(Board.KingSq[white],sq-8)*OpKingDist[y];
     bonus:=bonus-KingDist(Board.KingSq[black],sq-8)*MyKingDist[y];
     if (Board.Pos[sq-8]=Empty) then
      begin
       way:=PawnOpenFileMaskBB[black,sq];
       behind:=PawnOpenFileMaskBB[white,sq];
       MY:=way and Batt;
       OPP:=way and (Watt or Board.CPieses[white]);
       t1:=(Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen]);
       if ( t1 and behind)<>0 then
        begin
          major:=BitScanForWard(t1);
          if (Intersect[major,sq] and Board.AllPieses)=0 then opp:=way;
        end;
       if opp=0 then
            begin
               if way=My
                then bonus:=bonus+FreePasserSupported[y]
                else bonus:=bonus+FreePasser[y];
            end else
            begin
              if ((opp and My)=opp)
               then bonus:=bonus+BlockedPasserSupported[y]
               else bonus:=bonus+BlockedPasser[y];
            end;
       if (way and Board.CPieses[black])=0 then bonus:=bonus+FreeWay[y];
      end;
     if  ((MatTable[indexmat].flag and RookEndgame)<>0) and ((PawnOpenFileMaskBB[black,sq] and Board.Pieses[BlackRook])<>0) then bonus:=bonus-BadRook[y];
     if  ((MatTable[indexmat].flag and QueenEndgame)<>0) and ((PawnOpenFileMaskBB[black,sq] and Board.Pieses[BlackQueen])<>0) then bonus:=bonus-BadQueen[y];
     if bonus<0 then bonus:=0;
     if (posx[sq] in [1,8]) then
       begin
         if (Board.Pieses[WhiteQueen] or Board.Pieses[WhiteRook])<>0 then bonus:=bonus-(bonus div 4) else
           if Board.Pieses[WhiteBishop]=0 then bonus:=bonus+(bonus div 4);
       end;
     scoreend:=scoreend-bonus;
    end;
end;

Function KingDist(kingsq:Tsquare;PawnSQ:Tsquare):integer; inline;
var
  res:integer;
begin
  res:=Abs(posy[kingsq]-posy[pawnsq]);
  if Abs(posx[kingsq]-posx[pawnsq])>res then res:=Abs(posx[kingsq]-posx[pawnsq]);
  Result:=res;
end;

end.
