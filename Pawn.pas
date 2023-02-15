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
                  wsafety : smallint;
                  bsafety : smallint;
                  wking   : byte;
                  bking   : byte;
                  blocked : integer;
                  wcastle : byte;
                  bcastle : byte;
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

 BlockedPawn :TbytesArray =

( 0, 0, 0, 0, 0, 0, 0, 0,
  1, 1, 2, 2, 2, 2, 1, 1,
  1, 2, 3, 3, 3, 3, 2, 1,
  1, 2, 3, 5, 5, 3, 2, 1,
  1, 2, 3, 5, 5, 3, 2, 1,
  1, 2, 3, 3, 3, 3, 2, 1,
  1, 1, 2, 2, 2, 2, 1, 1,
  0, 0, 0, 0, 0, 0, 0, 0
);

    WPMidSQ : TbytesArray =
     (
          0,  0,  0,  0,  0,  0,  0,  0,
         -8, -2,  2,  5,  5,  2, -2, -8,
         -8, -2,  2, 12, 12,  2, -2, -8,
         -8, -2,  5, 18, 18,  5, -2, -8,
         -8, -2,  2, 12, 12,  2, -2, -8,
         -8, -2,  2,  5,  5,  2, -2, -8,
         -8, -2,  1,  5,  5,  1, -2, -8,
          0,  0,  0,  0,  0,  0,  0,   0
      );

IslandMid=0;
IslandEnd=5;
ChainMid=2;
ChainEnd=0;
HoleMid=1;
HoleEnd=2;
DoubledClosedMid    =2;
DoubledClosedEnd    =5;
DoubledIsoClosedMid =3;
DoubledIsoClosedEnd =5;
DoubledOpenMid      =5;
DoubledOpenEnd      =10;
DoubledIsoOpenMid   =10;
DoubledIsoOpenEnd   =15;

IsolatedClosedMid   =7;
IsolatedClosedEnd   =10;
IsolatedOpenMid     =15;
IsolatedOpenEnd     =20;

BackWardClosedMid   =5;
BackWardClosedEnd   =7;
BackWardOpenMid     =10;
BackWardOpenEnd     =15;

CandidatPasserMid : TRankArray = (0,0,0,5,10,20,0,0);
CandidatPasserEnd : TRankArray = (0,0,0,5,15,25,0,0);

PasserBaseMid  : TRankArray = (0, 0,  0,10,20,40,60,0);
PasserBaseEnd  : TrankArray = (0, 5,  5,10,25,50,80,0);
KingSupported  : TRankArray = (0, 0,  0, 5,12,25,50,0);
OutPasserMid  : TRankArray = (0, 0, 0, 0, 2, 5,10,0);
OutPasserEnd  : TrankArray = (0, 0, 0, 0, 5,10,20,0);

ConnectedPawnMid : TRankArray = (0, 0, 0, 0, 5,10,20,0);
ConnectedPawnEnd : TRankArray = (0, 0, 0, 0,10,15,30,0);

ProtectedPawnMid : TRankArray = (0, 0, 0, 0, 5,10,15,0);
ProtectedPawnEnd : TRankArray = (0, 0, 0, 0,10,15,25,0);

QueenEnd       : TrankArray = (0, 0, 0, 5,10,20,40,0);

MyKingDist     : TRankArray = (0,0,0,1,2,3, 5,0);
OpKingDist     : TRankArray = (0,0,0,2,4,6,10,0);

FreePasser : TrankArray = (0,0,0,0,10,20,40,0);
NotBlocked : TrankArray = (0,0,0,2, 3, 5,10,0);

OpFreeWay  : TrankArray = (0,0,0,0,10,30,50,0);
MeFreeWay  : TrankArray = (0,0,0,0, 0, 5,10,0);

BadRook  : TrankArray=(0,0,0,0,0,25,50,0);
BadQueen : TrankArray=(0,0,0,0,0, 0,10,0);

CutKing : TrankArray =(0,0,0,5,10,20,30,0);


VAR
   PawnTable : array of TPawnHash;
   ConnectedMaskBB,LeftFlangBB,RightFlangBB,HoleBB :array[a1 .. h8] of TBitBoard;

Function EvalPawn(var Board:Tboard):integer;
Function KingDist(kingsq:Tsquare;PawnSQ:Tsquare):integer;
Procedure EvalPasser(var Board:Tboard;var scoremid:integer;var scoreend:integer;PassersBB:TbitBoard;Watt:TbitBoard;BAtt:TbitBoard;indexmat:integer);
Function WPawnKingDist(kingsq:Tsquare;WPawnSQ:Tsquare):integer; inline;
Function BPawnKingDist(kingsq:Tsquare;BPawnSQ:Tsquare):integer; inline;

implementation
uses BitBoards,movegen,safety,attacks,evaluation;

Function EvalPawn(var Board:Tboard):integer;
var
   index,scoremid,scoreend,att,def,x,y : integer;
   sq,sq1,i : TSquare;
   PasserBB,Temp,temp1,WhitePawns,BlackPawns,AllPawns,ConnPawns : TBitBoard;
   passer,open,isolated,backward,doubled,chain : Boolean;
   wlight,blight,wdark,bdark: integer;
begin
  index:=Board.Pawnkey and HashPawnMask;
  result:=index;
  if (Board.Pawnkey=PawnTable[index].PawnKey)  then exit;
  scoremid:=0;
  scoreend:=0;
  PasserBB:=0;
  ConnPawns:=0;
  wlight:=0;blight:=0;wdark:=0;bdark:=0;
  WhitePawns:=Board.Pieses[WhitePawn];
  BlackPawns:=Board.Pieses[BlackPawn];
  AllPawns:=WhitePawns or BlackPawns;

  // Штрафуем пешечные островки
  sq:=0;
  for i:=1 to 8 do
    begin
      if (WhitePawns and FilesBB[i])=0
        then sq:=0
        else  begin
                if sq=0 then
                  begin
                    scoremid:=scoremid-IslandMid;
                    scoreend:=scoreend-IslandEnd;
                  end;
                 sq:=1;
              end;
    end;

    // Теперь пешки
  Temp:=WhitePawns;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=Posy[sq];
      // Заполняем штрафы для слонов, блокированных нашими пешками
      if (OnlyR00[sq] and Light)<>0 then
        begin
          wlight:=wlight+BlockedPawn[sq];
          if (Board.pos[sq+8]=BlackPawn) then wlight:=wlight+BlockedPawn[sq];
        end else
        begin
          wdark:=wdark+BlockedPawn[sq];
          if (Board.pos[sq+8]=BlackPawn) then wdark:=wdark+BlockedPawn[sq];
        end;
      // PST
      scoremid:=scoremid+WPMidSQ[sq];
      // Оцениваем "дырявость пешки"
      if ((WhitePawns and HoleBB[sq])<>0) and ((WhitePawns and WForward[sq-8] and FilesBB[x-1])=0) then
        begin
          scoremid:=scoremid-HoleMid;
          scoreend:=scoreend-HoleEnd;
        end;

      // Статусы  пешек
      if ((PawnOpenFileMaskBB[white,sq] and WhitePawns)<>0) then doubled:=true else doubled:=false;
      if ((PawnOpenFileMaskBB[white,sq] and AllPawns)=0) then open:=true else open:=false;
      if ((PawnPasserMaskBB[white,sq] and BlackPawns)=0) then passer:=true else passer:=false;
      if ((PawnIsoMaskBB[sq] and WhitePawns)=0) then isolated:=true else isolated:=false;
      if ((PawnChainMaskBB[white,sq] and WhitePawns)<>0) then chain:=true else chain:=false;
      if open then
        BEGIN
          // для пешки на открытой вертикали
          if doubled then
           begin
            scoremid:=scoremid-DoubledOpenMid;
            scoreend:=scoreend-DoubledOpenEnd;
            if isolated then
             begin
              scoremid:=scoremid-DoubledIsoOpenMid;
              scoreend:=scoreend-DoubledIsoOpenEnd;
             end;
           end;
          if chain then
           begin
             scoremid:=scoremid+ChainMid;
             scoreend:=scoreend+ChainEnd;
           end;
          if isolated then
           begin
            scoremid:=scoremid-IsolatedOpenMid;
            scoreend:=scoreend-IsolatedOpenEnd;
           end;
          backward:=false;
          if (not passer) and (not isolated) and (not chain) and ((PawnAttacksBB[white,sq] and BlackPawns)=0) and (y<6) then
           begin
             // Определяем отсталость пешки - кандидатом будет пешка у которой рядом или сзади нет поддержки
             if ((PawnBackWardMaskBB[white,sq] and WhitePawns)=0) then
               begin
                 i:=sq+8;
                 // Если пешка блокирована или поле перед ней контролируется вражеской пешкой - она отсталая
                 if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[white,i] and BlackPawns)<>0)  then backward:=true else
                   begin
                     // Если сделав ход рядом не окажется дружеской пешки - смотрим движение еще на 1 поле вперед
                     if (PawnAttacksBB[white,sq] and WhitePawns)=0 then
                       begin
                         i:=i+8;
                         // Если и это поле блокировано или под контролем вражеской пешки - отсталая
                         if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[white,i] and BlackPawns)<>0)  then backward:=true else
                          begin
                            // Если даже пройдя на 2 поля рядом не будет дружеской пешки - значит отсталая
                            if (PawnAttacksBB[white,sq+8] and WhitePawns)=0 then backward:=true;
                          end;
                       end;
                   end;
               end;
           end;
           if backward then
            begin
             scoremid:=scoremid-BackWardOpenMid;
             scoreend:=scoreend-BackWardOpenEnd;
            end;
        END   else
        BEGIN
         // для пешки на закрытой вертикали
          if doubled then
           begin
            scoremid:=scoremid-DoubledClosedMid;
            scoreend:=scoreend-DoubledClosedEnd;
            if isolated then
             begin
              scoremid:=scoremid-DoubledIsoClosedMid;
              scoreend:=scoreend-DoubledIsoClosedEnd;
             end;
           end;
          if chain then
           begin
             scoremid:=scoremid+ChainMid;
             scoreend:=scoreend+ChainEnd;
           end;
          if isolated then
           begin
            scoremid:=scoremid-IsolatedClosedMid;
            scoreend:=scoreend-IsolatedClosedEnd;
           end;
          backward:=false;
         if (not passer) and (not isolated) and (not chain) and ((PawnAttacksBB[white,sq] and BlackPawns)=0) and (y<6) then
           begin
             // Определяем отсталость пешки - кандидатом будет пешка у которой рядом или сзади нет поддержки
             if ((PawnBackWardMaskBB[white,sq] and WhitePawns)=0) then
               begin
                 i:=sq+8;
                 // Если пешка блокирована или поле перед ней контролируется вражеской пешкой - она отсталая
                 if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[white,i] and BlackPawns)<>0)  then backward:=true else
                   begin
                     // Если сделав ход рядом не окажется дружеской пешки - смотрим движение еще на 1 поле вперед
                     if (PawnAttacksBB[white,sq] and WhitePawns)=0 then
                       begin
                         i:=i+8;
                         // Если и это поле блокировано или под контролем вражеской пешки - отсталая
                         if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[white,i] and BlackPawns)<>0)  then backward:=true else
                          begin
                            // Если даже пройдя на 2 поля рядом не будет дружеской пешки - значит отсталая
                            if (PawnAttacksBB[white,sq+8] and WhitePawns)=0 then backward:=true;
                          end;
                       end;
                   end;
               end;
           end;
           if backward then
            begin
             scoremid:=scoremid-BackWardClosedMid;
             scoreend:=scoreend-BackWardClosedEnd;
            end;
        END;
        // Проходные и кандидаты
        if passer then
            begin
             if (not doubled) then
              begin
               PasserBB:=PasserBB or OnlyR00[sq];
               scoremid:=scoremid+PasserBaseMid[y];
               scoreend:=scoreend+PasserBaseEnd[y];
               if (PawnAttacksBB[black,sq] and WhitePawns)<>0 then
                begin
                 scoremid:=scoremid+ProtectedPawnMid[y];
                 scoreend:=scoreend+ProtectedPawnEnd[y];
                end;
               if ((LeftFlangBB[sq] and BlackPawns)=0) or ((RightFlangBB[sq] and BlackPawns)=0) then
                begin
                 scoremid:=scoremid+OutPasserMid[y];
                 scoreend:=scoreend+OutPasserEnd[y];
                end;
               temp1:=ConnPawns and ConnectedMaskBB[sq];
               ConnPawns:=ConnPawns or OnlyR00[sq];
               if temp1<>0 then
                 begin
                   sq1:=BitScanBackWard(temp1);
                   temp1:=temp1 and NotOnlyR00[sq1];
                   if y>=posy[sq1] then
                     begin
                      scoremid:=scoremid+ConnectedPawnMid[y]+ConnectedPawnMid[posy[sq1]];
                      scoreend:=scoreend+ConnectedPawnEnd[y]+ConnectedPawnEnd[posy[sq1]];
                     end;
                   if temp1<>0 then
                    begin
                     sq1:=BitScanBackWard(temp1);
                     if y>=posy[sq1] then
                       begin
                        scoremid:=scoremid+ConnectedPawnMid[y]+ConnectedPawnMid[posy[sq1]];
                        scoreend:=scoreend+ConnectedPawnEnd[y]+ConnectedPawnEnd[posy[sq1]];
                       end;
                    end;
                 end;
              end;
            end else
            if open then
              begin
                temp1:=PawnBackWardMaskBB[white,sq] and WhitePawns;
                att:=BitCount(temp1);
                temp1:=PawnBackWardMaskBB[black,sq+8] and BlackPawns;
                def:=BitCount(temp1);
                if att>=def then
                  begin
                    scoremid:=scoremid+CandidatPasserMid[y];
                    scoreend:=scoreend+CandidatPasserEnd[y];
                  end;
              end;
      temp:=temp and NotOnlyR00[sq];
    end;
  ConnPawns:=0;
  // Штрафуем пешечные островки
  sq:=0;
  for i:=1 to 8 do
    begin
      if (BlackPawns and FilesBB[i])=0
        then sq:=0
        else  begin
                if sq=0 then
                  begin
                    scoremid:=scoremid+IslandMid;
                    scoreend:=scoreend+IslandEnd;
                  end;
                 sq:=1;
              end;
    end;
  // Черные пешки
  Temp:=BlackPawns;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];
      y:=Posy[sq];
      // Заполняем штрафы для слонов, блокированных нашими пешками
      if (OnlyR00[sq] and Light)<>0 then
        begin
          blight:=blight+BlockedPawn[sq];
          if (Board.pos[sq-8]=WhitePawn) then blight:=blight+BlockedPawn[sq];
        end else
        begin
          bdark:=bdark+BlockedPawn[sq];
          if (Board.pos[sq-8]=WhitePawn) then bdark:=bdark+BlockedPawn[sq];
        end;
      // PST
      scoremid:=scoremid-WPMidSQ[63-sq];
      // Оцениваем "дырявость пешки"
      if ((BlackPawns and HoleBB[sq])<>0) and ((BlackPawns and BForward[sq+8] and FilesBB[x-1])=0) then
        begin
          scoremid:=scoremid+HoleMid;
          scoreend:=scoreend+HoleEnd;
        end;

      // Статусы  пешек
      if ((PawnOpenFileMaskBB[black,sq] and BlackPawns)<>0) then doubled:=true else doubled:=false;
      if ((PawnOpenFileMaskBB[black,sq] and AllPawns)=0) then open:=true else open:=false;
      if ((PawnPasserMaskBB[black,sq] and WhitePawns)=0) then passer:=true else passer:=false;
      if ((PawnIsoMaskBB[sq] and BlackPawns)=0) then isolated:=true else isolated:=false;
      if ((PawnChainMaskBB[black,sq] and BlackPawns)<>0) then chain:=true else chain:=false;
      if open then
        BEGIN
          // для пешки на открытой вертикали
          if doubled then
           begin
            scoremid:=scoremid+DoubledOpenMid;
            scoreend:=scoreend+DoubledOpenEnd;
            if isolated then
             begin
              scoremid:=scoremid+DoubledIsoOpenMid;
              scoreend:=scoreend+DoubledIsoOpenEnd;
             end;
           end;
          if chain then
           begin
             scoremid:=scoremid-ChainMid;
             scoreend:=scoreend-ChainEnd;
           end;
          if isolated then
           begin
            scoremid:=scoremid+IsolatedOpenMid;
            scoreend:=scoreend+IsolatedOpenEnd;
           end;
          backward:=false;
          if (not passer) and (not isolated) and (not chain) and ((PawnAttacksBB[black,sq] and WhitePawns)=0) and (y>3) then
           begin
             // Определяем отсталость пешки - кандидатом будет пешка у которой рядом или сзади нет поддержки
             if ((PawnBackWardMaskBB[black,sq] and BlackPawns)=0) then
               begin
                 i:=sq-8;
                 // Если пешка блокирована или поле перед ней контролируется вражеской пешкой - она отсталая
                 if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[black,i] and WhitePawns)<>0)  then backward:=true else
                   begin
                     // Если сделав ход рядом не окажется дружеской пешки - смотрим движение еще на 1 поле вперед
                     if (PawnAttacksBB[black,sq] and BlackPawns)=0 then
                       begin
                         i:=i-8;
                         // Если и это поле блокировано или под контролем вражеской пешки - отсталая
                         if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[black,i] and WhitePawns)<>0)  then backward:=true else
                          begin
                            // Если даже пройдя на 2 поля рядом не будет дружеской пешки - значит отсталая
                            if (PawnAttacksBB[black,sq-8] and BlackPawns)=0 then backward:=true;
                          end;
                       end;
                   end;
               end;
           end;
           if backward then
            begin
             scoremid:=scoremid+BackWardOpenMid;
             scoreend:=scoreend+BackWardOpenEnd;
            end;
        END   else
        BEGIN
         // для пешки на закрытой вертикали
          if doubled then
           begin
            scoremid:=scoremid+DoubledClosedMid;
            scoreend:=scoreend+DoubledClosedEnd;
            if isolated then
             begin
              scoremid:=scoremid+DoubledIsoClosedMid;
              scoreend:=scoreend+DoubledIsoClosedEnd;
             end;
           end;
          if chain then
           begin
             scoremid:=scoremid-ChainMid;
             scoreend:=scoreend-ChainEnd;
           end;
          if isolated then
           begin
            scoremid:=scoremid+IsolatedClosedMid;
            scoreend:=scoreend+IsolatedClosedEnd;
           end;
         backward:=false;
         if (not passer) and (not isolated) and (not chain) and ((PawnAttacksBB[black,sq] and WhitePawns)=0) and (y>3) then
           begin
             // Определяем отсталость пешки - кандидатом будет пешка у которой рядом или сзади нет поддержки
             if ((PawnBackWardMaskBB[black,sq] and BlackPawns)=0) then
               begin
                 i:=sq-8;
                 // Если пешка блокирована или поле перед ней контролируется вражеской пешкой - она отсталая
                 if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[black,i] and WhitePawns)<>0)  then backward:=true else
                   begin
                     // Если сделав ход рядом не окажется дружеской пешки - смотрим движение еще на 1 поле вперед
                     if (PawnAttacksBB[black,sq] and BlackPawns)=0 then
                       begin
                         i:=i-8;
                         // Если и это поле блокировано или под контролем вражеской пешки - отсталая
                         if ((OnlyR00[i] and AllPawns)<>0) or ((PawnAttacksBB[black,i] and WhitePawns)<>0)  then backward:=true else
                          begin
                            // Если даже пройдя на 2 поля рядом не будет дружеской пешки - значит отсталая
                            if (PawnAttacksBB[black,sq-8] and BlackPawns)=0 then backward:=true;
                          end;
                       end;
                   end;
               end;
           end;
           if backward then
            begin
             scoremid:=scoremid+BackWardClosedMid;
             scoreend:=scoreend+BackWardClosedEnd;
            end;
        END;
        // Проходные и кандидаты
        if passer then
            begin
             if (not doubled) then
              begin
               PasserBB:=PasserBB or OnlyR00[sq];
               scoremid:=scoremid-PasserBaseMid[9-y];
               scoreend:=scoreend-PasserBaseEnd[9-y];
               if (PawnAttacksBB[white,sq] and BlackPawns)<>0 then
                begin
                 scoremid:=scoremid-ProtectedPawnMid[9-y];
                 scoreend:=scoreend-ProtectedPawnEnd[9-y];
                end;
               if ((LeftFlangBB[sq] and WhitePawns)=0) or ((RightFlangBB[sq] and WhitePawns)=0) then
                begin
                 scoremid:=scoremid-OutPasserMid[9-y];
                 scoreend:=scoreend-OutPasserEnd[9-y];
                end;
               temp1:=ConnPawns and ConnectedMaskBB[sq];
               ConnPawns:=ConnPawns or OnlyR00[sq];
               if temp1<>0 then
                 begin
                   sq1:=BitScanForWard(temp1);
                   temp1:=temp1 and NotOnlyR00[sq1];
                   if y<=posy[sq1] then
                    begin
                     scoremid:=scoremid-ConnectedPawnMid[9-y]-ConnectedPawnMid[9-posy[sq1]];
                     scoreend:=scoreend-ConnectedPawnEnd[9-y]-ConnectedPawnEnd[9-posy[sq1]];
                    end;
                   if temp1<>0 then
                    begin
                     sq1:=BitScanForWard(temp1);
                     if y<=posy[sq1] then
                      begin
                       scoremid:=scoremid-ConnectedPawnMid[9-y]-ConnectedPawnMid[9-posy[sq1]];
                       scoreend:=scoreend-ConnectedPawnEnd[9-y]-ConnectedPawnEnd[9-posy[sq1]];
                      end;
                    end;
                 end;
              end;
            end else
            if open then
              begin
                temp1:=PawnBackWardMaskBB[black,sq] and BlackPawns;
                att:=BitCount(temp1);
                temp1:=PawnBackWardMaskBB[white,sq-8] and WhitePawns;
                def:=BitCount(temp1);
                if att>=def then
                  begin
                    scoremid:=scoremid-CandidatPasserMid[9-y];
                    scoreend:=scoreend-CandidatPasserEnd[9-y];
                  end;
              end;
      temp:=temp and NotOnlyR00[sq];
    end;
   // Сохраняем
  if wlight>255 then wlight:=255;
  if blight>255 then blight:=255;
  if wdark>255 then wdark:=255;
  if bdark>255 then bdark:=255;
  PawnTable[index].PawnKey:=Board.Pawnkey;
  PawnTable[index].scoremid:=scoremid;
  PawnTable[index].scoreend:=scoreend;
  PawnTable[index].PasserBB:=PasserBB;
  PawnTable[index].wking:=255;
  PawnTable[index].bking:=255;
  PawnTable[index].wcastle:=Board.Castle and 3;
  PawnTable[index].bcastle:=Board.Castle and 12;
  PawnTable[index].blocked:=wlight or (wdark shl 8) or (blight shl 16) or (bdark shl 24);
end;

Procedure EvalPasser(var Board:Tboard;var scoremid:integer;var scoreend:integer;PassersBB:TbitBoard;Watt:TbitBoard;BAtt:TbitBoard;indexmat:integer);
var
  temp,way,behind,MY,OPP,t1 : TBitBoard;
  sq,major,wking,bking : Tsquare;
  x,y : integer;
begin
  wking:=Board.KingSq[white];
  bking:=Board.KingSq[black];
  temp:=PassersBB and Board.Pieses[WhitePawn];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=posx[sq];
      y:=posy[sq];
      temp:=temp and NotOnlyR00[sq];
      if y>3 then
       begin
        if (MatTable[indexmat].flag and QueenEndgame)<>0 then
         begin
          scoremid:=scoremid+QueenEnd[y];
          scoreend:=scoreend+QueenEnd[y];
          if ((PawnOpenFileMaskBB[white,sq] and Board.Pieses[WhiteQueen])<>0) then scoreend:=scoreend-BadQueen[y];
         end;
        if (MatTable[indexmat].flag and RookEndgame)<>0 then
         begin
          if ((PawnOpenFileMaskBB[white,sq] and Board.Pieses[WhiteRook])<>0) then  scoreend:=scoreend-BadRook[y];
          if ((x=1) and ((FilesBB[2] and Board.Pieses[BlackRook])<>0)) or ((x=8) and ((FilesBB[7] and Board.Pieses[BlackRook])<>0)) then scoreend:=scoreend-CutKing[y];
         end;
        scoreend:=scoreend+WPawnKingDist(bking,sq+8)*OpKingDist[y];
        scoreend:=scoreend-WPawnKingDist(wking,sq+8)*MyKingDist[y];
        if ((KingAttacksBB[sq+8] and OnlyR00[wking])<>0) then
          begin
            if (posy[wking]>y)
              then scoreend:=scoreend+KingSupported[y]
              else scoreend:=scoreend+(KingSupported[y] div 2);
          end;
        if (Board.Pos[sq+8]=Empty) then scoreend:=scoreend+NotBlocked[y];
        if ((PawnOpenFileMaskBB[white,sq] and Board.CPieses[white])=0) then scoreend:=scoreend+MeFreeWay[y];
        if ((PawnOpenFileMaskBB[white,sq] and Board.CPieses[black])=0) then scoreend:=scoreend+OpFreeWay[y];
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
        if ((opp and My)=opp) then scoreend:=scoreend+FreePasser[y];
       end;
    end;
  temp:=PassersBB and Board.Pieses[BlackPawn];
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=posx[sq];
      y:=9-posy[sq];
      temp:=temp and NotOnlyR00[sq];
      if y>3 then
       begin
        if (MatTable[indexmat].flag and QueenEndgame)<>0 then
         begin
          scoremid:=scoremid-QueenEnd[y];
          scoreend:=scoreend-QueenEnd[y];
          if ((PawnOpenFileMaskBB[black,sq] and Board.Pieses[BlackQueen])<>0) then scoreend:=scoreend+BadQueen[y];
         end;
        if (MatTable[indexmat].flag and RookEndgame)<>0 then
         begin
          if ((PawnOpenFileMaskBB[black,sq] and Board.Pieses[BlackRook])<>0) then  scoreend:=scoreend+BadRook[y];
          if ((x=1) and ((FilesBB[2] and Board.Pieses[WhiteRook])<>0)) or ((x=8) and ((FilesBB[7] and Board.Pieses[WhiteRook])<>0)) then scoreend:=scoreend+CutKing[y];
         end;
        scoreend:=scoreend-BPawnKingDist(wking,sq-8)*OpKingDist[y];
        scoreend:=scoreend+BPawnKingDist(bking,sq-8)*MyKingDist[y];
        if ((KingAttacksBB[sq-8] and OnlyR00[bking])<>0) then
          begin
            if (posy[bking]<9-y)
              then scoreend:=scoreend-KingSupported[y]
              else scoreend:=scoreend-(KingSupported[y] div 2);
          end;
        if (Board.Pos[sq-8]=Empty) then scoreend:=scoreend-NotBlocked[y];
        if ((PawnOpenFileMaskBB[black,sq] and Board.CPieses[black])=0) then scoreend:=scoreend-MeFreeWay[y];
        if ((PawnOpenFileMaskBB[black,sq] and Board.CPieses[white])=0) then scoreend:=scoreend-OpFreeWay[y];
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
        if ((opp and My)=opp) then scoreend:=scoreend-FreePasser[y];
       end;
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

Function WPawnKingDist(kingsq:Tsquare;WPawnSQ:Tsquare):integer; inline;
var
  res:integer;
begin
  if posy[kingsq]>posy[WPawnSq]
    then res:=3*(Abs(posy[kingsq]-posy[Wpawnsq]))
    else res:=6*(Abs(posy[kingsq]-posy[Wpawnsq]));
  if 6*Abs(posx[kingsq]-posx[Wpawnsq])>res then res:=6*Abs(posx[kingsq]-posx[Wpawnsq]);
  Result:=res;
end;
Function BPawnKingDist(kingsq:Tsquare;BPawnSQ:Tsquare):integer; inline;
var
  res:integer;
begin
  if posy[kingsq]<posy[BPawnSq]
    then res:=3*(Abs(posy[kingsq]-posy[Bpawnsq]))
    else res:=6*(Abs(posy[kingsq]-posy[Bpawnsq]));
  if 6*abs(posx[kingsq]-posx[Bpawnsq])>res then res:=6*Abs(posx[kingsq]-posx[Bpawnsq]);
  Result:=res;
end;

end.
