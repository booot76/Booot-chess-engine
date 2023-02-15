unit Safety;

interface
  uses params,Board;
TYPE
  TKingPieseSafety = array[0..16] of integer;
CONST
     WKBSQ : TbytesArray =
     (
          -5,  0,-20,-35,-35,-20,  0, -5,
          -5,-10,-30,-40,-40,-30,-10, -5,
         -30,-30,-40,-60,-60,-40,-30,-30,
         -70,-70,-70,-70,-70,-70,-70,-70,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80
     );

  WKESQ : TbytesArray =
     (
        -60,-40,-30,-20,-20,-30,-40,-60,
        -40,-20,-10,  0,  0,-10,-20,-40,
        -30,-10,  0, 10, 10,  0,-10,-30,
        -20,  0, 10, 20, 20, 10,  0,-20,
        -20,  0, 10, 20, 20, 10,  0,-20,
        -30,-10,  0, 10, 10,  0,-10,-30,
        -40,-20,-10,  0,  0,-10,-20,-40,
        -60,-40,-30,-20,-20,-30,-40,-60
     );

  KingShelterEdge   : TRankArray = (36, 0,10,20,27,32,36,36);
  KingShelterMiddle : TRankArray = (54, 0,15,30,40,48,54,54);
  KingShelterCenter : TRankArray = (36, 0,10,20,27,32,36,36);
  KingStormMiddle   : TRankArray = (10, 0, 0,10,20,40, 0, 0);
  KingStormEdge     : TRankArray = (10, 0, 0,10,20,40, 0, 0);
  KingStormCenter   : TRankArray = (10, 0, 0,10,20,40, 0, 0);
  KnightTropism=35;
  BishopTropism=25;
  RookTropism=30;
  QueenTropism=65;
  Weak1Rank=10;
  KPSafety : TkingPieseSafety = (0,0,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32);
Function WLocation (var Board:Tboard;mid:integer;edg:integer;cen:integer):integer;
Function BLocation (var Board:Tboard;mid:integer;edg:integer;cen:integer):integer;
Function WKShelter(var Board:TBoard;wkingsq:Tsquare;pawnindex:integer):integer;
Function BKShelter(var Board:TBoard;bkingsq:Tsquare;pawnindex:integer):integer;
Procedure EvalSafety(var Board:Tboard;flag:integer;var scoremid:integer;var scoreend:integer;pawnindex:integer;var Wshelter:integer;var Bshelter:integer);
implementation
 uses pawn,BitBoards,Material,movegen;

Function WLocation (var Board:Tboard;mid:integer;edg:integer;cen:integer):integer;
var
  temp:TbitBoard;
  res:integer;
begin
  res:=0;
  temp:=Board.Pieses[WhitePawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingShelterMiddle[posy[BitScanForward(temp)]]
     else res:=res+KingShelterMiddle[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingShelterEDGE[posy[BitScanForward(temp)]]
     else res:=res+KingShelterEDGE[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingShelterCenter[posy[BitScanForward(temp)]]
     else res:=res+KingShelterCenter[1];
  if res=0 then res:=Weak1Rank;
  temp:=Board.Pieses[BlackPawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingStormMiddle[9-posy[BitScanForward(temp)]]
     else res:=res+KingStormMiddle[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingStormEDGE[9-posy[BitScanForward(temp)]]
     else res:=res+KingStormEDGE[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingStormCenter[9-posy[BitScanForward(temp)]]
     else res:=res+KingStormCenter[1];
 Result:=res;
end;
Function BLocation (var Board:Tboard;mid:integer;edg:integer;cen:integer):integer;
var
  temp:TbitBoard;
  res:integer;
begin
  res:=0;
  temp:=Board.Pieses[BlackPawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingShelterMiddle[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterMiddle[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingShelterEDGE[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterEDGE[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingShelterCenter[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterCenter[1];
  if res=0 then res:=Weak1Rank;
  temp:=Board.Pieses[WhitePawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingStormMiddle[posy[BitScanBackward(temp)]]
     else res:=res+KingStormMiddle[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingStormEDGE[posy[BitScanBackward(temp)]]
     else res:=res+KingStormEDGE[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingStormCenter[posy[BitScanBackward(temp)]]
     else res:=res+KingStormCenter[1];
 Result:=res;
end;

Function WKShelter(var Board:TBoard;wkingsq:Tsquare;pawnindex:integer):integer;
var
   x:integer;
begin
  x:=Posx[wkingsq];
  if x<4 then result:=PawnTable[pawnindex].Wshelter and 255
     else
  if x>5 then result:=(PawnTable[pawnindex].Wshelter shr 24) and 255
    else
  if x=4 then result:=(PawnTable[pawnindex].Wshelter shr 8)  and 255
         else result:=(PawnTable[pawnindex].Wshelter shr 16) and 255;
end;
Function BKShelter(var Board:TBoard;bkingsq:Tsquare;pawnindex:integer):integer;
var
   x:integer;
begin
  x:=Posx[bkingsq];
  if x<4 then result:=PawnTable[pawnindex].Bshelter and 255
     else
  if x>5 then result:=(PawnTable[pawnindex].Bshelter shr 24) and 255
    else
  if x=4 then result:=(PawnTable[pawnindex].Bshelter shr 8) and 255
         else result:=(PawnTable[pawnindex].Bshelter shr 16) and 255;
end;

Procedure EvalSafety(var Board:Tboard;flag:integer;var scoremid:integer;var scoreend:integer;pawnindex:integer;var Wshelter:integer;var Bshelter:integer);
var
   real,min,will,penalty : integer;
begin
  wshelter:=0;
  bshelter:=0;
  if (flag and DoWkingSafety)<>0 then
    begin
     real:=WKShelter(Board,Board.KingSq[white],pawnindex);
     min:=real;
     if (Board.Castle and CastleBits[white])<>0 then
        begin
          if (Board.Castle and CastleBits2[white,shortcastle])<>0 then
            begin
              will:=WKShelter(Board,g1,pawnindex);
              if will<min then min:=will;
            end;
          if (Board.Castle and CastleBits2[white,longcastle])<>0 then
            begin
              will:=WKShelter(Board,b1,pawnindex);
              if will<min then min:=will;
            end;
        end;
     if min=real
        then penalty:=real
        else penalty:=((min+real) div 2);
     Wshelter:=penalty;
     scoremid:=scoremid-penalty;
    end;
  if (flag and DoBkingSafety)<>0 then
    begin
      real:=BKShelter(Board,Board.KingSq[black],pawnindex);
      min:=real;
      if (Board.Castle and CastleBits[black])<>0 then
          begin
            if (Board.Castle and CastleBits2[black,shortcastle])<>0 then
              begin
                will:=BKShelter(Board,g8,pawnindex);
                if will<min then min:=will;
              end;
            if (Board.Castle and CastleBits2[black,longcastle])<>0 then
              begin
                will:=BKShelter(Board,b8,pawnindex);
                if will<min then min:=will;
              end;
          end;
      if min=real
          then penalty:=real
          else penalty:=((min+real) div 2);
      Bshelter:=penalty;    
      scoremid:=scoremid+penalty;
    end;
end;

end.
