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
