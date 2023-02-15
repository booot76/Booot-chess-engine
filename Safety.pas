unit Safety;

interface
  uses params,Board;
TYPE
  TKingPieseSafety = array[0..16] of integer;
  TDiagArray=array[1..8,1..8] of integer;
CONST
     WKBSQ : TbytesArray =
     (
         -10,  0,-20,-40,-40,-20,  0,-10,
         -20,-10,-30,-50,-50,-30,-10,-20,
         -40,-30,-50,-70,-70,-50,-30,-40,
         -50,-40,-60,-80,-80,-60,-40,-50,
         -60,-50,-70,-90,-90,-70,-50,-60,
         -70,-60,-80,-99,-99,-80,-60,-70,
         -70,-60,-80,-99,-99,-80,-60,-70,
         -70,-60,-80,-99,-99,-80,-60,-70
     );

  WKESQ : TbytesArray =
     (
        -25,-20,-15,-10,-10,-15,-20,-25,
        -20,-10, -5,  0,  0, -5,-10,-20,
        -15, -5,  5, 10, 10,  5, -5,-15,
        -10,  0, 10, 20, 20, 10,  0,-10,
        -10,  0, 10, 20, 20, 10,  0,-10,
        -15, -5,  5, 10, 10,  5, -5,-15,
        -20,-10, -5,  0,  0, -5,-10,-20,
        -25,-20,-15,-10,-10,-15,-20,-25
     );



  KingShelterEdge   : TRankArray = (30, 0, 5,15,20,25,25,25);
  KingShelterMiddle : TRankArray = (55, 0,15,40,50,55,55,55);
  KingShelterCenter : TRankArray = (35, 0,10,20,25,30,30,30);

  KingStormMiddle   : TRankArray = (10, 0, 0,10,20,50,35,0);
  KingStormEdge     : TRankArray = ( 5, 0, 0, 5,15,35,25,0);
  KingStormCenter   : TRankArray = (10, 0, 0,10,20,50,35,0);

  KnightTropism=15;
  BishopTropism=15;
  RookTropism=30;
  QueenTropism=60;
  ZeroShelter=10;
  KPSafety : TkingPieseSafety = (0,1,4,9,16,25,36,49,64,64,64,64,64,64,64,64,64);

Function WLocation (var Board:Tboard;king:integer;mid:integer;edg:integer;cen:integer):integer;
Function BLocation (var Board:Tboard;king:integer;mid:integer;edg:integer;cen:integer):integer;
Function WKShelter(var Board:TBoard;wkingsq:Tsquare;pawnindex:integer):integer;
Function BKShelter(var Board:TBoard;bkingsq:Tsquare;pawnindex:integer):integer;

var
   KingShelterDiagBB : array[a1..h8] of TBitBoard;

implementation
 uses pawn,BitBoards,Material,movegen;

Function WLocation (var Board:Tboard;king:integer;mid:integer;edg:integer;cen:integer):integer;
var
  temp:TbitBoard;
  sq,res:integer;
begin
  res:=0;
  temp:=Board.Pieses[WhitePawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingShelterMiddle[posy[BitScanForward(temp)]]
     else res:=res+KingShelterMiddle[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingShelterCenter[posy[BitScanForward(temp)]]
     else res:=res+KingShelterCenter[1];
  temp:=Board.Pieses[WhitePawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingShelterEDGE[posy[BitScanForward(temp)]]
     else res:=res+KingShelterEDGE[1];
  if res=0 then res:=ZeroShelter;

  temp:=Board.Pieses[BlackPawn] and FilesBB[mid];
  if temp<>0
     then
      begin
       sq:=BitScanForward(temp);
       if (Board.Pos[sq-8]=WhitePawn)
         then res:=res+(KingStormMiddle[9-posy[sq]] div 2)
         else res:=res+(KingStormMiddle[9-posy[sq]]);
      end
     else res:=res+KingStormMiddle[1];

  temp:=Board.Pieses[BlackPawn] and FilesBB[cen];
  if temp<>0
     then
      begin
       sq:=BitScanForward(temp);
       if (Board.Pos[sq-8]=WhitePawn)
         then res:=res+(KingStormCenter[9-posy[sq]] div 2)
         else res:=res+(KingStormCenter[9-posy[sq]]);
      end
     else res:=res+KingStormCenter[1];

  temp:=Board.Pieses[BlackPawn] and FilesBB[edg];
  if temp<>0
     then
      begin
       sq:=BitScanForward(temp);
       if (Board.Pos[sq-8]=WhitePawn)
         then res:=res+(KingStormEdge[9-posy[sq]] div 2)
         else res:=res+(KingStormEdge[9-posy[sq]]);
      end
     else res:=res+KingStormEdge[1];
 Result:=res;
end;
Function BLocation (var Board:Tboard;king:integer;mid:integer;edg:integer;cen:integer):integer;
var
  temp:TbitBoard;
  sq,res:integer;
begin
  res:=0;
  temp:=Board.Pieses[BlackPawn] and FilesBB[mid];
  if temp<>0
     then res:=res+KingShelterMiddle[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterMiddle[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[cen];
  if temp<>0
     then res:=res+KingShelterCenter[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterCenter[1];
  temp:=Board.Pieses[BlackPawn] and FilesBB[edg];
  if temp<>0
     then res:=res+KingShelterEDGE[9-posy[BitScanBackward(temp)]]
     else res:=res+KingShelterEDGE[1];
  if res=0 then res:=ZeroShelter;

  temp:=Board.Pieses[WhitePawn] and FilesBB[mid];
  if temp<>0
     then
      begin
       sq:=BitScanBackward(temp);
       if (Board.Pos[sq+8]=BlackPawn)
         then res:=res+(KingStormMiddle[posy[sq]] div 2)
         else res:=res+(KingStormMiddle[posy[sq]]);
      end
     else res:=res+KingStormMiddle[1];

  temp:=Board.Pieses[WhitePawn] and FilesBB[cen];
  if temp<>0
     then
      begin
       sq:=BitScanBackward(temp);
       if (Board.Pos[sq+8]=BlackPawn)
         then res:=res+(KingStormCenter[posy[sq]] div 2)
         else res:=res+(KingStormCenter[posy[sq]]);
      end
     else res:=res+KingStormCenter[1];
   temp:=Board.Pieses[WhitePawn] and FilesBB[edg];
   if temp<>0
     then
      begin
       sq:=BitScanBackward(temp);
       if (Board.Pos[sq+8]=BlackPawn)
         then res:=res+(KingStormEdge[posy[sq]] div 2)
         else res:=res+(KingStormEdge[posy[sq]]);
      end
     else res:=res+KingStormEdge[1];
 Result:=res;
end;

Function WKShelter(var Board:TBoard;wkingsq:Tsquare;pawnindex:integer):integer;
var
   x,cen,edg,res,will:integer;
begin
  x:=posx[wkingsq];
  if x=8 then x:=7 else
  if x=1 then x:=2;
  if (PawnTable[pawnindex].wking=x) and ((Board.Castle and 3)=PawnTable[pawnindex].wcastle) then
    begin
      result:=PawnTable[pawnindex].wsafety;
      exit;
    end;
  if x>4 then
    begin
     edg:=x+1;
     cen:=x-1;
     res:=WLocation(Board,wkingsq,x,edg,cen);
     if (Board.Castle and 1)<>0 then
      begin
       will:=10+Wlocation(Board,g1,7,8,6);
       if will<res then res:=will;
      end;
     if (Board.Castle and 2)<>0 then
      begin
       will:=10+Wlocation(Board,b1,2,1,3);
       if will<res then res:=will;
      end;
    end else
    begin
     edg:=x-1;
     cen:=x+1;
     res:=WLocation(Board,wkingsq,x,edg,cen);
    end;

  PawnTable[pawnindex].wking:=x;
  PawnTable[pawnindex].wsafety:=res;
  PawnTable[pawnindex].wcastle:=Board.Castle and 3;


  Result:=res;
end;
Function BKShelter(var Board:TBoard;bkingsq:Tsquare;pawnindex:integer):integer;
var
   x,cen,edg,res,will:integer;
begin
  x:=posx[bkingsq];
  if x=8 then x:=7 else
  if x=1 then x:=2;
  if (PawnTable[pawnindex].bking=x) and ((Board.Castle and 12)=PawnTable[pawnindex].bcastle) then
    begin
      result:=PawnTable[pawnindex].bsafety;
      exit;
    end;
  if x>4 then
    begin
     edg:=x+1;
     cen:=x-1;
     res:=BLocation(Board,bkingsq,x,edg,cen);
     if (Board.Castle and 4)<>0 then
      begin
       will:=10+Blocation(Board,g8,7,8,6);
       if will<res then res:=will;
      end;
     if (Board.Castle and 8)<>0 then
      begin
       will:=10+Blocation(Board,b8,2,1,3);
       if will<res then res:=will;
      end;
    end else
    begin
     edg:=x-1;
     cen:=x+1;
     res:=BLocation(Board,bkingsq,x,edg,cen);
    end;

  PawnTable[pawnindex].bking:=x;
  PawnTable[pawnindex].bsafety:=res;
  PawnTable[pawnindex].bcastle:=Board.Castle and 12;
  Result:=res;
end;



end.
