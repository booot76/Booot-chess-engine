unit Endgame;

interface
 uses params,material,board,pawn,bitboards;

CONST
WeakKingMate :TbytesArray =
    (100, 90, 80, 70, 70, 80, 90, 100,
     90, 70, 60, 50, 50, 60, 70,  90,
     80, 60, 40, 30, 30, 40, 60,  80,
     70, 50, 30, 20, 20, 30, 50,  70,
     70, 50, 30, 20, 20, 30, 50,  70,
     80, 60, 40, 30, 30, 40, 60,  80,
     90, 70, 60, 50, 50, 60, 70,  90,
    100, 90, 80, 70, 70, 80, 90, 100);

KingDistBonus : TRankArray = (0,50,40,30,20,10,0,0);

BN_light:TBytesArray=
             (  20, 30, 40, 50, 60, 70, 80,100,   //1
                30, 20, 30, 40, 50, 60, 70, 80,   //2
                40, 30, 20, 30, 40, 50, 60, 70,   //3
                50, 40, 30, 20, 30, 40, 50, 60,   //4
                60, 50, 40, 30, 20, 30, 40, 50,   //5
                70, 60, 50, 40, 30, 20, 30, 40,   //6
                80, 70, 60, 50, 40, 30, 20, 30,   //7
               100, 80, 70, 60, 50, 40, 30, 20);  //8
BN_dark:TBytesArray=
             ( 100, 80, 70, 60, 50, 40, 30, 20,   //1
                80, 70, 60, 50, 40, 30, 20, 30,   //2
                70, 60, 50, 40, 30, 20, 30, 40,   //3
                60, 50, 40, 30, 20, 30, 40, 50,   //4
                50, 40, 30, 20, 30, 40, 50, 60,   //5
                40, 30, 20, 30, 40, 50, 60, 70,   //6
                30, 20, 30, 40, 50, 60, 70, 80,   //7
                20, 30, 40, 50, 60, 70, 80,100);  //8

Function EvalSpecialEndgames(var Board:Tboard;indexmat:integer;var scoremid:integer;var scoreend:integer):boolean;
implementation
 uses evaluation;

Function EvalSpecialEndgames(var Board:Tboard;indexmat:integer;var scoremid:integer;var scoreend:integer):boolean; 
var
  pawn,prom,wr,br:TSquare;
begin
  if (Mattable[indexmat].flag and PawnEndgame)<>0 then
    begin
      // Пешки на крайних вертикалях а король успел в угол:
      if ((Board.Pieses[WhitePawn] and FilesBB[1])<>0) and ((Board.Pieses[WhitePawn] and (not FilesBB[1]))=0) and (KingDist(Board.KingSq[black],a8)<=1) then
        begin
          scoremid:=0;
          scoreend:=0;
          result:=true;
          exit;
        end;
       if ((Board.Pieses[WhitePawn] and FilesBB[8])<>0) and ((Board.Pieses[WhitePawn] and (not FilesBB[8]))=0) and (KingDist(Board.KingSq[black],h8)<=1) then
        begin
          scoremid:=0;
          scoreend:=0;
          result:=true;
          exit;
        end;
       if ((Board.Pieses[BlackPawn] and FilesBB[1])<>0) and ((Board.Pieses[BlackPawn] and (not FilesBB[1]))=0) and (KingDist(Board.KingSq[white],a1)<=1) then
        begin
          scoremid:=0;
          scoreend:=0;
          result:=true;
          exit;
        end;
      if ((Board.Pieses[BlackPawn] and FilesBB[8])<>0) and ((Board.Pieses[BlackPawn] and (not FilesBB[8]))=0) and (KingDist(Board.KingSq[white],h1)<=1) then
        begin
          scoremid:=0;
          scoreend:=0;
          result:=true;
          exit;
        end;
    end else
if (Mattable[indexmat].flag and NoPawnEndgame)<>0 then
    begin
      // KNBK
      if (Mattable[indexmat].flag and KBNK)<>0 then
        begin
          if (Board.Pieses[WhiteBishop]<>0) then
           begin
            if Board.Pieses[WhiteBishop] and Light<>0
                        then scoremid:=scoremid+BN_light[Board.KingSq[black]]+KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])]
                        else scoremid:=scoremid+BN_dark[Board.KingSq[black]]+KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])];
           end else
           begin
            if Board.Pieses[BlackBishop] and Light<>0
                        then scoremid:=scoremid-BN_light[Board.KingSq[white]]-KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])]
                        else scoremid:=scoremid-BN_dark[Board.KingSq[white]]-KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])];

           end;
          scoreend:=scoremid;
          result:=true;
          exit;
        end else
       begin
         // В общем случае держим своего короля ближе к чужому:
         if scoremid>0
           then scoremid:=scoremid+KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])]
           else scoremid:=scoremid-KingDistBonus[KingDist(Board.KingSq[white],Board.KingSq[black])];
         scoreend:=scoremid;
         result:=false;
         exit;  
       end; 
    end;
// KRPKR
if (Mattable[indexmat].flag and KRPKR)<>0 then
  begin
   if scoremid>0 then
    begin
     Mattable[indexmat].Wmul:=16;
     pawn:=BitScanForward(Board.Pieses[WhitePawn]);
     prom:=h7+posx[pawn];
     wr:=BitScanForward(Board.Pieses[WhiteRook]);
     br:=BitScanForward(Board.Pieses[BlackRook]);
     if Board.KingSq[black]=prom then
        begin
          if (posx[pawn]<5) and (posx[br]-2>posx[pawn]) then Mattable[indexmat].Wmul:=4 else
            if (posx[pawn]>4) and (posx[br]+2<posx[pawn]) then Mattable[indexmat].Wmul:=4;
        end else
      if (posx[Board.KingSq[black]]=posx[pawn]) and (Board.KingSq[white]>pawn) then Mattable[indexmat].Wmul:=4 else
      if (posx[pawn]=7) and (pawn+8=wr) and (posx[pawn]=posx[br]) then
         begin
           if ((posx[pawn]<5) and (Board.KingSq[black] in [g7,h7])) or ((posx[pawn]>4) and (Board.KingSq[black] in [a7,b7])) then
              begin
                if (Posy[br]<4) and (KingDist(Board.KingSq[white],pawn)>1) then Mattable[indexmat].Wmul:=4 else
                if (Posy[br]>3) and (KingDist(Board.KingSq[white],pawn)>2) then Mattable[indexmat].Wmul:=4;
              end;
         end;
    end else
    begin
     Mattable[indexmat].Bmul:=16;
     pawn:=BitScanForward(Board.Pieses[BlackPawn]);
     prom:=posx[pawn]-1;
     wr:=BitScanForward(Board.Pieses[WhiteRook]);
     br:=BitScanForward(Board.Pieses[BlackRook]);
     if Board.KingSq[white]=prom then
        begin
          if (posx[pawn]<5) and (posx[wr]-2>posx[pawn]) then Mattable[indexmat].Bmul:=4 else
            if (posx[pawn]>4) and (posx[wr]+2<posx[pawn]) then Mattable[indexmat].Bmul:=4;
        end else
      if (posx[Board.KingSq[white]]=posx[pawn]) and (Board.KingSq[white]<pawn) then Mattable[indexmat].Bmul:=4 else
      if (posx[pawn]=2) and (pawn-8=br) and (posx[pawn]=posx[wr]) then
         begin
           if ((posx[pawn]<5) and (Board.KingSq[white] in [g2,h2])) or ((posx[pawn]>4) and (Board.KingSq[white] in [a2,b2])) then
              begin
                if (Posy[wr]>5) and (KingDist(Board.KingSq[white],pawn)>1) then Mattable[indexmat].Bmul:=4 else
                if (Posy[br]<6) and (KingDist(Board.KingSq[white],pawn)>2) then Mattable[indexmat].Bmul:=4;
              end;
         end;
    end;
    Result:=false;
    exit;
  end;
if (Mattable[indexmat].flag and KBPK)<>0 then
  begin
    if ((Board.Pieses[WhitePawn] and FilesBB[1])<>0) and (Board.Pieses[WhitePawn]  and (not FilesBB[1])=0)
             and ((Board.Pieses[WhiteBishop] and dark)<>0) and (KingDist(Board.KingSq[black],a8)<=1) then
             begin
               scoremid:=0;
               scoreend:=0;
               Result:=true;
               exit;
             end;
    if ((Board.Pieses[WhitePawn] and FilesBB[8])<>0) and (Board.Pieses[WhitePawn]  and (not FilesBB[8])=0)
             and ((Board.Pieses[WhiteBishop] and light)<>0) and (KingDist(Board.KingSq[black],h8)<=1) then
             begin
               scoremid:=0;
               scoreend:=0;
               Result:=true;
               exit;
             end;
     if ((Board.Pieses[BlackPawn] and FilesBB[1])<>0) and (Board.Pieses[BlackPawn]  and (not FilesBB[1])=0)
             and ((Board.Pieses[BlackBishop] and light)<>0) and (KingDist(Board.KingSq[white],a1)<=1) then
             begin
               scoremid:=0;
               scoreend:=0;
               Result:=true;
               exit;
             end;
    if ((Board.Pieses[BlackPawn] and FilesBB[8])<>0) and (Board.Pieses[BlackPawn]  and (not FilesBB[8])=0)
             and ((Board.Pieses[BlackBishop] and dark)<>0) and (KingDist(Board.KingSq[white],h1)<=1) then
             begin
               scoremid:=0;
               scoreend:=0;
               Result:=true;
               exit;
             end;
  end;
  Result:=false;
end;
end.
