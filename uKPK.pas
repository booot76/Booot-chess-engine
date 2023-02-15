unit uKPK;

interface
uses uBitBoards,uBoard;
  Type
    TMlKPK = array[0..10] of integer;
Const
  MaxKPKIndex=24*64*64-1;
  Draw=0;
  DeadDraw=253;
  StaleMate=254;
  Broken=255;
  KPKWin=500;
  Pawnnum : array[0..23] of integer = (a2,a3,a4,a5,a6,a7,b2,b3,b4,b5,b6,b7,c2,c3,c4,c5,c6,c7,d2,d3,d4,d5,d6,d7);

  numpawn : array[a1..h8] of integer =
  (31,31,31,31,31,31,31,31,
    0, 6,12,18,31,31,31,31,
    1, 7,13,19,31,31,31,31,
    2, 8,14,20,31,31,31,31,
    3, 9,15,21,31,31,31,31,
    4,10,16,22,31,31,31,31,
    5,11,17,23,31,31,31,31,
   31,31,31,31,31,31,31,31);

var
  KPKW,KPKB : array[0..MaxKPKIndex] of byte;

Function KPKProbe(color,pawn,Wk,BK:integer):integer;
Procedure KPKAnalyze;
implementation

Function KPKIndex(pawn,wk,bk:integer):integer; inline;
begin
  result:=bk or (wk shl 6) or (numpawn[pawn] shl 12);
end;

Function KPKProbe(color,pawn,Wk,BK:integer):integer;
var
  index : integer;
begin
  index:=KPKIndex(pawn,wk,bk);
  if index>MaxKPKIndex then result:=Broken else
  If color=white
    then result:=KPKW[index]
    else result:=KPKB[index];
  if result in [broken,DeadDraw,Stalemate] then result:=Draw else
    if color=black
      then result:=-result;
end;

Procedure Index2Pos(index:integer;var pawn:integer;var wk:integer;var bk:integer);inline;
begin
  bk:=index and 63;
  wk:=(index shr 6) and 63;
  pawn:=PawnNum[(index shr 12) and 31];
end;

Procedure AddKPKMoves(piese:integer;Temp:TBitBoard;var ML:TMLKPK);inline;
var
  sq : integer;
begin
  While temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      temp:=temp and (temp-1);
      inc(Ml[0]);
      ML[ML[0]]:=piese or (sq shl 6);
    end;
end;

Procedure KPKMoves(color,pawn,wk,bk:integer;var Ml:TMLKPK);
var
  Temp : TBitBoard;
begin
 Ml[0]:=0;// Счетчик
 if color=white then
   begin
     // Королем
     temp:=KingAttacks[wk] and (not(KingAttacks[bk] or Only[pawn]));
     AddKPKMoves(wk,temp,ML);
     // Пешкой
     If (Only[pawn+8] and (Only[wk] or Only[bk]))=0 then
       begin
         inc(Ml[0]);
         ML[ML[0]]:=pawn or ((pawn+8) shl 6);
         if (pawn<a3) and ((Only[pawn+16] and (Only[wk] or Only[bk]))=0) then
           begin
             inc(Ml[0]);
             ML[ML[0]]:=pawn or ((pawn+16) shl 6);
           end;
       end;
   end else
   begin
     //  Королем
     temp:=KingAttacks[bk] and (not(KingAttacks[wk] or PawnAttacks[white,pawn]));
     AddKPKMoves(bk,temp,ML);
   end;
end;

Procedure KPKInit;
var
  index,pawn,wk,bk : integer;
  Ml : TMLKPK;
begin
  For index:=0 to MaxKPKIndex do
    begin
      KPKW[Index]:=Draw;
      KPKB[Index]:=Draw;
      Index2Pos(Index,pawn,wk,bk);
      // Невозможная
      if (wk=bk) or (wk=pawn) or (bk=pawn) or ((KingAttacks[wk] and Only[bk])<>0) then
        begin
          KPKW[Index]:=Broken;
          KPKB[Index]:=Broken;
          continue;
        end;
      // Шах черным пешкой при своем ходе
      If (PawnAttacks[white,pawn] and Only[bk])<>0 then KPKW[Index]:=Broken;
      // ход черных
      KPKMoves(black,pawn,wk,bk,ML);
      // смотрим пат
      If ML[0]=0 then
        KPKB[Index]:=StaleMate else
       // Черные могут забрать пешку
       if ((KingAttacks[bk] and Only[pawn])<>0) and ((KingAttacks[wk] and Only[pawn])=0) then KPKB[Index]:=DeadDraw;
      // ход белых
      if KPKW[Index]=Draw then
       begin
        KPKMoves(white,pawn,wk,bk,ML);
        // смотрим пат
        If ML[0]=0 then
           KPKW[Index]:=StaleMate else
        // Превращение в ферзя(ладью) безопасное
           if (pawn>h6) and ((Only[pawn+8] and (Only[wk] or Only[bk]))=0) and ( ((KingAttacks[bk] and Only[pawn+8])=0) or ((KingAttacks[wk] and Only[pawn+8])<>0) ) then KPKW[Index]:=1;
       end;
    end;
end;

Procedure KPKAnalyze;
var
  rang,index,wk,bk,pawn,i,newking,newpawn,newIndex,nodes  : integer;
  Ml : TMLKPK;
  fl : boolean;
begin
  KPKInit;
  rang:=1;nodes:=0;
while (nodes<>0) or (rang=1) do
 begin
  // Черный цикл
  For index:=0 to MaxKPKIndex do
   if KPKB[index]=Draw then
    begin
      Index2Pos(Index,pawn,wk,bk);
      KPKMoves(black,pawn,wk,bk,ml);
      fl:=false;
      For i:=1 to ML[0] do
        begin
          newking:=(ML[i] shr 6) and 63;
          newIndex:=KPKIndex(pawn,wk,newking);
          If KPKW[NewIndex] in [Draw,StaleMate,DeadDraw] then  fl:=true;
        end;
      if (not fl) then KPKB[Index]:=rang;
    end;
  // Белый цикл
  nodes:=0;inc(rang);
  For index:=0 to MaxKPKIndex do
   if KPKW[index]=Draw then
    begin
      Index2Pos(Index,pawn,wk,bk);
      KPKMoves(white,pawn,wk,bk,ml);
      fl:=false;
      For i:=1 to ML[0] do
        begin
          newking:=wk;
          newpawn:=pawn;
          if (Ml[i] and 63)=wk
            then newking:=(ML[i] shr 6) and 63
            else newpawn:=(ML[i] shr 6) and 63;
          newIndex:=KPKIndex(newpawn,newking,bk);
          If (newIndex<=MaxKPKIndex) and (KPKB[NewIndex]=rang-1) then
           begin
            fl:=true;
            break;
           end;
        end;
      if (fl) then
       begin
        inc(nodes);
        KPKW[Index]:=rang;
       end;
    end;
 end;

end;



end.
