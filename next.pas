unit next;

interface
 uses params,history,genmoves,captures,see,escape,bitboards;

Function NextMoveAll(color : integer; ply: integer):integer;
Function NextEscape(color :integer;ply:integer):integer;
implementation
Function NextMoveAll(color : integer; ply: integer):integer;
label l1;
// Поставляет ходы в рутину перебора
var
   i,cpoint,sort,j,vvalue,avalue,pvalue,see,piese,dest:integer;
begin
 cpoint:=ply shl 7;
  if tree[ply].status=init then
     begin
       OldMoves[cpoint]:=0;
       GetMovesAll(color,ply);
        for i:=cpoint+1 to cpoint+moves[cpoint] do
         if (Moves[i]=tree[ply].Hashmove) then MValues[i]:=HashValue else
           if (Moves[i] and CapPromoFlag)<>0 then
             begin
               avalue:=PiesePrice[(Moves[i] shr 16) and 15];
               vvalue:=PiesePrice[(Moves[i] shr 20) and 15];
               pvalue:=PiesePrice[(Moves[i] shr 24) and 15];
               MValues[i]:=ForsValue+(vvalue+pvalue)*32-avalue;
             end else
           if Moves[i]=killer[ply,1] then MValues[i]:=KillerValue else
           if Moves[i]=killer[ply,2] then MValues[i]:=KillerValue-1 else
           if (ply>2) and (Moves[i]=killer[ply-2,1]) then MValues[i]:=KillerValue-2 else
           if (ply>2) and (Moves[i]=killer[ply-2,2]) then MValues[i]:=KillerValue-3 else
            begin
             piese:=(Moves[i] shr 16) and 15;
             dest:=(Moves[i] shr 8) and 255;
             MValues[i]:=Hist[piese,dest];
            end;
       tree[ply].status:=tryOther;
     end;
l1:
// Последовательно выбираем все отсортированные хорошие взятия
      sort:=Used;j:=cpoint;
      For i:=cpoint+1 to cpoint+Moves[cpoint] do
        if (MValues[i]>sort) then
          begin
            j:=i;
            sort:=Mvalues[i];
          end;
      if sort=used then
        begin
          Result:=0;
          exit;
        end;
      if (sort>=ForsValue) and (sort<HashValue) then
        begin
          see:=StaticEE(color,Moves[j]);
          if see<0 then
            begin
              MValues[j]:=-ForsValue+see;
              goto l1;
            end;
        end;
       MValues[j]:=used;
       OldMoves[cpoint]:=OldMoves[cpoint]+1;
       OldMoves[cpoint+Oldmoves[cpoint]]:=Moves[j];
       Result:=Moves[j];
end;

Function NextEscape(color :integer;ply:integer):integer;
// Функция поставляет ходы в основную модель, если король находится под шахом.
label l1;
var
   cpoint,i,j,sort,see,avalue,vvalue,pvalue,piese,dest : integer;
begin
  cpoint:=ply shl 7;
 // Первым выбирается хеш ход (если он есть)
  if tree[ply].status=init then
     begin
       GetEscapes(color,ply);
       for i:=cpoint+1 to cpoint+takes[cpoint] do
         if (Takes[i]=tree[ply].Hashmove) then Mtakes[i]:=HashValue else
           if (Takes[i] and CapPromoFlag)<>0 then
             begin
               avalue:=PiesePrice[(Takes[i] shr 16) and 15];
               vvalue:=PiesePrice[(Takes[i] shr 20) and 15];
               pvalue:=PiesePrice[(Takes[i] shr 24) and 15];
               MTakes[i]:=ForsValue+(vvalue+pvalue)*32-avalue;
             end else
           if Takes[i]=killer[ply,1] then MTakes[i]:=KillerValue else
           if Takes[i]=killer[ply,2] then MTakes[i]:=KillerValue-1 else
           if (ply>2) and (Takes[i]=killer[ply-2,1]) then MTakes[i]:=KillerValue-2 else
           if (ply>2) and (Takes[i]=killer[ply-2,2]) then MTakes[i]:=KillerValue-3 else
            begin
             piese:=(Takes[i] shr 16) and 15;
             dest:=(Takes[i] shr 8) and 255;
             MTakes[i]:=Hist[piese,dest];
           end;
       tree[ply].status:=tryOther;
     end;
l1:
      sort:=Used;j:=cpoint;
      For i:=cpoint+1 to cpoint+Takes[cpoint] do
        if (MTakes[i]>sort) then
          begin
            j:=i;
            sort:=MTakes[i];
          end;
      if sort=used then
        begin
          Result:=0;
          exit;
        end;
      if (sort>=ForsValue) and (sort<HashValue) then
        begin
          see:=StaticEE(color,Takes[j]);
          if see<0 then
            begin
              MTakes[j]:=-ForsValue+see;
              goto l1;
            end;
        end;
       MTakes[j]:=used;
       Result:=Takes[j];
end;
end.

