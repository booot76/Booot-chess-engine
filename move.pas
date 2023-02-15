unit move;

interface
uses params,board,bitboards;

CONST
     CaptureFlag = 1 shl 15;
     PromoteFlag = (1 shl 12) or (1 shl 13) or (1 shl 14);
     CapPromoFlag = CaptureFlag or PromoteFlag;
     MoveNone=0;
Procedure MakeMove(color:Tcolor;move:tmove;var Board:Tboard;var Undo:TUndo); inline;
Procedure UnMakeMove(color:Tcolor;var Board:Tboard;var Undo:Tundo);inline;
Procedure MakeNullMove(var Board:Tboard;var Undo:TUndo);inline;
Procedure UnMakeNullMove(color:Tcolor;var Board:TBoard;var Undo:TUndo);inline;
Procedure InitNodeUndo(var Board:Tboard;var Undo:TUndo);inline;
Procedure InitNodeUndo2(var Board:Tboard;var Undo:TUndo);
Procedure ClearSquare(color:Tcolor;sq:Tsquare;piese:Tpiese;var Board:Tboard;update:boolean);inline;
Procedure SetSquare(color:Tcolor;sq:Tsquare;piese:Tpiese;var Board:Tboard;update : boolean);inline;
Procedure SetMove(color:Tcolor;from:Tsquare;dest:Tsquare;piese:Tpiese;Var Board:Tboard;update:boolean);inline;
Function MoveToStr(move:Tmove):string;
Function StrToMove(smove:string;var Board:Tboard):Tmove;

implementation
 uses MoveGen,hash;

Procedure MakeMove(color:Tcolor;move:tmove;var Board:Tboard;var Undo:TUndo);inline;

var
   pdelta,pc,pdouble,penpass,old,new: integer;
begin
  // Разбираем ход
  undo.from:=move and 63;
  undo.dest:=(move shr 6) and 63;
  undo.piese:=Board.Pos[undo.from];
  undo.promo:=(move shr 12) and 7;
  undo.captured:=Board.Pos[undo.dest];
  undo.isCastle:=false;
  inc(Board.Rule50);
  Board.Color:=Board.Color xor 1;
  Board.Key:=Board.Key xor Zcolor;
  old:=Board.Castle;
  new:=old and CastleSq[undo.from] and CastleSq[undo.dest];
  Board.Castle:=new;
  if old<>new then Board.Key:=Board.Key xor CastleZobr[old] xor CastleZobr[new];
  if Board.EnnPassSQ>=a1 then
    begin
      Board.Key:=Board.Key xor PieseZobr[0,Board.EnnPassSQ];
      Board.EnnPassSQ:=-1;
    end;
  if color=white then
    begin
      pc:=-1;
      pdouble:=16;
      penpass:=8;
    end  else
    begin
      pc:=1;
      pdouble:=-16;
      penpass:=-8;
    end;

  if (undo.piese=Whitepawn) or (undo.piese=BlackPawn) then
    begin
      Board.Rule50:=0;
      pdelta:=undo.Dest-undo.from;
      if (pdelta=pdouble) and ((PawnAttacksBB[color,(undo.from+penpass)] and Board.Pieses[pc*pawn])<>0) then
        begin
          Board.EnnPassSQ:=undo.from+penpass;
          Board.Key:=Board.Key xor PieseZobr[0,Board.EnnPassSQ];
        end;
    end;
  // Убираем побитую фигуру с доски
  if (move and captureflag)<>0 then
    begin
      Board.Rule50:=0;
      undo.capsq:=undo.dest;
      if undo.captured=Empty then
       begin
        undo.capsq:=undo.dest-penpass;
        undo.captured:=pc*pawn;
       end;
      if (pc*undo.Captured>Pawn) then dec(Board.PieseCount[color xor 1]);
      ClearSquare(color xor 1,undo.capsq,undo.captured,Board,true);
    end;

  // Переставляем фигуру:
  // Если ход - превращение:
  if undo.promo<>Empty then
    begin
      inc(Board.PieseCount[color]);
      ClearSquare(color,undo.from,undo.piese,Board,true);
      SetSquare(color,undo.dest,-undo.promo*pc,Board,true);
    end else SetMove(color,undo.from,undo.dest,undo.piese,Board,true); // Обычный ход
  // Если ход - рокировка то переставляем ладью:
  if ((undo.piese=WhiteKing) or (undo.piese=BlackKing)) and ((undo.From-undo.Dest=2) or (undo.From-undo.Dest=-2))   then
    begin
      undo.isCastle:=true;
      if undo.dest=g1 then SetMove(color,h1,f1,WhiteRook,Board,true) else
      if undo.dest=c1 then SetMove(color,a1,d1,WhiteRook,Board,true) else
      if undo.dest=g8 then SetMove(color,h8,f8,BlackRook,Board,true)
                 else SetMove(color,a8,d8,BlackRook,Board,true);

    end;
  inc(board.scount);
  Board.Stack[Board.scount]:=Board.Key;
end;

Procedure UnMakeMove(color:Tcolor;var Board:Tboard;var Undo:Tundo);inline;
var
   pc:integer;
begin
  dec(Board.scount);
  if color=white then pc:=1 else pc:=-1;
  // Если рокировка - двигаем ладью:
  if undo.isCastle  then
    begin
      if undo.dest=g1 then SetMove(color,f1,h1,WhiteRook,Board,false) else
      if undo.dest=c1 then SetMove(color,d1,a1,WhiteRook,Board,false) else
      if undo.dest=g8 then SetMove(color,f8,h8,BlackRook,Board,false)
                 else SetMove(color,d8,a8,BlackRook,Board,false);
    end;
  // Двигаем фигуру:
  if undo.promo<>Empty then
    begin
      dec(Board.PieseCount[color]);
      ClearSquare(color,undo.dest,undo.promo*pc,Board,false);
      SetSquare(color,undo.from,undo.piese,Board,false);
    end else
     SetMove(color,undo.dest,undo.from,undo.piese,Board,false);
  // ставим побитую фигуру:
  if undo.captured<>empty then
   begin
    if ((-pc*undo.Captured)>Pawn) then inc(Board.PieseCount[color xor 1]);
    SetSquare(color xor 1,undo.Capsq,undo.captured,Board,false);
   end;
  // служебная инфа доски:
  board.Color:=color;
  board.Rule50:=undo.Rule50;
  board.Castle:=undo.Castle;
  board.EnnPassSQ:=undo.EnnPassSq;
  board.oncheck:=undo.oncheck;
  Board.Key:=Undo.Key;
  Board.Pawnkey:=Undo.Pawnkey;
  Board.MatKey:=Undo.MatKey;
end;
Procedure MakeNullMove(var Board:Tboard;var Undo:TUndo);inline;
begin
  Board.Rule50:=0;
  inc(board.scount);
  Board.Stack[Board.scount]:=Board.Key;
  Board.Color:=Board.Color xor 1;
  Board.Key:=Board.Key xor Zcolor;
  if Board.EnnPassSQ>=a1 then
    begin
      Board.Key:=Board.Key xor PieseZobr[0,Board.EnnPassSQ];
      Board.EnnPassSQ:=-1;
    end;
end;
Procedure UnMakeNullMove(color:Tcolor;var Board:TBoard;var Undo:TUndo);inline;
begin
  dec(Board.scount);
  board.Color:=color;
  board.Rule50:=undo.Rule50;
  board.EnnPassSQ:=undo.EnnPassSq;
  Board.Key:=Undo.Key;
end;
Procedure ClearSquare(color:Tcolor;sq:Tsquare;piese:Tpiese;var Board:Tboard;update:boolean);inline;
var
   piesecount:integer;
begin
  Board.Pos[sq]:=Empty;
  Board.Pieses[piese]:=Board.Pieses[piese] and NotOnlyR00[sq];
  Board.CPieses[color]:=Board.CPieses[color] and NotOnlyR00[sq];
  Board.AllPieses:=Board.AllPieses and NotOnlyR00[sq];
  Board.AllR90:=Board.AllR90 and NotOnlyR90[sq];
  Board.AllBh1:=Board.AllBh1 and NotOnlyBh1[sq];
  Board.AllBa1:=Board.AllBa1 and NotOnlyBa1[sq];
  if update then
    begin
      Board.Key:=Board.Key xor PieseZobr[piese,sq];
      if (piese=WhitePawn) or (Piese=BlackPawn) then Board.Pawnkey:=Board.Pawnkey xor PawnZobr[color,sq];
      piesecount:=BitCount(Board.Pieses[piese]);
      Board.MatKey:=(Board.MatKey xor MatZobr[piese,piesecount+1]) xor MatZobr[piese,piesecount];
    end;

end;

Procedure SetSquare(color:Tcolor;sq:Tsquare;piese:Tpiese;var Board:Tboard;update : boolean);inline;
var
   piesecount:integer;
begin
  Board.Pos[sq]:=piese;
  Board.Pieses[piese]:=Board.Pieses[piese] or OnlyR00[sq];
  Board.CPieses[color]:=Board.CPieses[color] or OnlyR00[sq];
  Board.AllPieses:=Board.AllPieses or OnlyR00[sq];
  Board.AllR90:=Board.AllR90 or OnlyR90[sq];
  Board.AllBh1:=Board.AllBh1 or OnlyBh1[sq];
  Board.AllBa1:=Board.AllBa1 or OnlyBa1[sq];
   if update then
    begin
      Board.Key:=Board.Key xor PieseZobr[piese,sq];
      if (piese=WhitePawn) or (Piese=BlackPawn) then Board.Pawnkey:=Board.Pawnkey xor PawnZobr[color,sq];
      piesecount:=BitCount(Board.Pieses[piese]);
      Board.MatKey:=(Board.MatKey xor MatZobr[piese,piesecount]) xor MatZobr[piese,piesecount-1];
    end;
  
end;

Procedure SetMove(color:Tcolor;from:Tsquare;dest:Tsquare;piese:Tpiese;Var Board:Tboard;update:Boolean);inline;
var
   bmove,bmover90,bmovebh1,bmoveba1:TbitBoard;
begin
  Board.Pos[from]:=Empty;
  Board.Pos[dest]:=piese;
  bmove:=OnlyR00[from] or OnlyR00[dest];
  bmover90:=OnlyR90[from] or OnlyR90[dest];
  bmovebh1:=OnlyBh1[from] or OnlyBh1[dest];
  bmoveba1:=OnlyBa1[from] or OnlyBa1[dest];
  Board.CPieses[color]:=Board.CPieses[color] xor bmove;
  Board.AllPieses:=Board.AllPieses xor bmove;
  Board.AllR90:=Board.AllR90 xor bmover90;
  Board.AllBh1:=Board.AllBh1 xor bmovebh1;
  Board.AllBa1:=Board.AllBa1 xor bmoveba1;
  if ((piese=WhiteKing) or (Piese=BlackKing))
    then Board.KingSq[color]:=dest
    else Board.Pieses[piese]:=Board.Pieses[piese] xor bmove;
  if update then
    begin
      Board.Key:=Board.Key xor PieseZobr[piese,from] xor PieseZobr[piese,dest];
      if (piese=WhitePawn) or (Piese=BlackPawn) then Board.Pawnkey:=Board.Pawnkey xor PawnZobr[color,from] xor PawnZobr[color,dest];
    end;
end;
Procedure InitNodeUndo(var Board:Tboard;var Undo:TUndo); inline;
begin
  undo.Key:=Board.Key;
  undo.Pawnkey:=Board.Pawnkey;
  undo.MatKey:=Board.MatKey;
  undo.Rule50:=board.Rule50;
  undo.Castle:=board.Castle;
  undo.oncheck:=board.oncheck;
  undo.EnnPassSq:=board.EnnPassSQ;
end;
Procedure InitNodeUndo2(var Board:Tboard;var Undo:TUndo);
begin
  undo.Key:=Board.Key;
  undo.Pawnkey:=Board.Pawnkey;
  undo.MatKey:=Board.MatKey;
  undo.Rule50:=board.Rule50;
  undo.Castle:=board.Castle;
  undo.oncheck:=board.oncheck;
  undo.EnnPassSq:=board.EnnPassSQ;
end;

Function MoveToStr(move:Tmove):string;
var
  k : integer;
  res:string;
begin
  res:=Decode[move and 63]+Decode[(move shr 6) and 63];
  k:=((move shr 12) and 7);
  if k<>0 then
    begin
      case k of
        whiteknight : res:=res + 'n';
        whitebishop : res:=res + 'b';
        whiterook : res:=res + 'r';
        whitequeen : res:=res + 'q';
      end;
    end;
  result:=res;
end;
Function FindSq(sq:string):Tsquare;
var
   i:integer;
begin
  for i:=a1 to h8 do
    if decode[i]=sq then
      begin
        result:=i;
        exit;
      end;
  result:=-1
end;
Function StrToMove(smove:string;var Board:Tboard):Tmove;
var
   from,dest : Tsquare;
   res:Tmove;
begin
  from:=FindSq(smove[1]+smove[2]);
  dest:=FindSq(smove[3]+smove[4]);
 res:=(dest shl 6) or from;
 if Board.Pos[dest]<>0 then res:=res or CaptureFlag;
 if ((Board.Pos[from]=WhitePawn) or (Board.Pos[from]=BlackPawn)) and (Board.EnnPassSQ=dest) then res:=res or CaptureFlag;
 
 if length(smove)=5 then
   case smove[5] of
     'q' : res:=res or (WhiteQueen shl 12);
     'r' : res:=res or (WhiteRook shl 12);
     'b' : res:=res or (WhiteBishop shl 12);
     'n' : res:=res or (WhiteKnight shl 12);
   end;
 result:=res;
end;

end.
