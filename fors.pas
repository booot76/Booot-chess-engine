unit fors;

interface
uses params,eval,escape,captures,see,make,attacks,hash;
Function FV(color:integer;alpha : integer;beta:integer;ply:integer;docheck:boolean;stand:integer):integer;
Procedure GenerateChecks(color:integer;ply:integer;counts:integer;var Wpieses:int64;var Bpieses:int64);
implementation
uses search,bitboards,egtb,history;

Function FV(color:integer;alpha : integer;beta:integer;ply:integer;docheck:boolean;stand:integer):integer;
label l1,l2,l3;
var
   standpat,i,point,temp,temp1,eval,opking,j,optvalue,avalue,pvalue,vvalue,move,score,bestvalue,deltavalue,mymat:integer;
   onerep,nextcheck : boolean;
   WPieses,BPieses : int64;
begin
 
  if (ply>=MaxPly-1)  then
     begin
       Result:=Evaluate(color,ply,alpha,beta,ply);
       exit;
     end;
  if Rule50[ply]>100 then
     begin
       Result:=0;
       exit;
     end
        else HashGame[rep+ply-1]:=tree[ply].HashKey;
 if Repetition(ply) then
     begin
       Result:=0;
       exit;
     end;
 if alpha>Mate-ply then
     begin
       Result:=alpha;
       exit;
     end;
  PVlen[ply]:=ply-1;
  if color=white
   then
       begin
       opking:=tree[ply].bking;
       mymat:=tree[ply].Wmat;
       end
   else
      begin
      opking:=tree[ply].Wking;
      mymat:=tree[ply].Bmat;
      end;
  point:=ply shl 7;
  tree[ply].bmove:=0;
  bestvalue:=-Mate;
  onerep:=false;

// Если мы под шахом - пробуем защититься
   if (tree[ply].onCheck)  then
     begin
       GetEscapes(color,ply);
       if Takes[point]=0 then
          begin
           Result:=-Mate+ply-1;
           exit;
          end else
         if Takes[point]=1 then onerep:=true;
 // Приписываем оценки всем защитам от шаха
       for i:=point+1 to point+Takes[point] do
          if (Takes[i] and CapPromoflag)<>0
            then
              begin
               avalue:=PiesePrice[(Takes[i] shr 16) and 15];
               vvalue:=PiesePrice[(Takes[i] shr 20) and 15];
               pvalue:=PiesePrice[(Takes[i] shr 24) and 15];
               Mtakes[i]:=ForsValue+(vvalue+pvalue)*32-avalue;
              end
            else Mtakes[i]:=Hist[(Takes[i] shr 16) and 15,(Takes[i] shr 8) and 255];
      goto l1;
     end;
  if stand=-mate
     then standpat:=Evaluate(color,ply,alpha,beta,ply)
     else standpat:=stand;
  
  if standpat>bestvalue then bestvalue:=standpat;
  if standpat>alpha then
          begin
            if standpat>=beta then
               begin
                 Result:=standpat;
                 exit;
               end;
            alpha:=standpat;
          end;
  WPieses:=WhitePieses;
  BPieses:=BlackPieses;
  deltavalue:=alpha-standpat-delta;
  if (deltavalue>=PawnValue) and (beta-alpha=1) and (mymat>9)  then
    begin
      Wpieses:=Wpieses and (not WhitePawns);
      Bpieses:=Bpieses and (not BlackPawns);
      if deltavalue>=KnightValue then
       begin
        Wpieses:=Wpieses and (not (WhiteKnights or WhiteBishops));
        Bpieses:=Bpieses and (not (BlackKnights or blackBishops));
        if deltavalue>=RookValue then
         begin
          Wpieses:=Wpieses and (not WhiteRooks);
          Bpieses:=Bpieses and (not BlackRooks);
          if deltavalue>=QueenValue then
           begin
            Wpieses:=Wpieses and (not WhiteQueens);
            Bpieses:=Bpieses and (not BlackQueens);
           end;
         end;
       end;
    end;
  GetCaptures(color,ply,Wpieses,BPieses);
  for i:=point+1 to point+Takes[point] do
     begin
       avalue:=PiesePrice[(Takes[i] shr 16) and 15];
       vvalue:=PiesePrice[(Takes[i] shr 20) and 15];
       pvalue:=PiesePrice[(Takes[i] shr 24) and 15];
       Mtakes[i]:=(vvalue+pvalue)*32-avalue;
     end;
            // Теперь сортируем
l1:    for i:= point+1 to point+Takes[point] do
     begin
       move:=Takes[i];
       score:=Mtakes[i];
       For j:=i+1 to point+Takes[point] do
               begin
                  temp:=Takes[j];
                  temp1:=Mtakes[j];
                  if temp1>score then
                    begin
                      Takes[j]:=move;
                      Mtakes[j]:=score;
                      move:=temp;
                      score:=temp1;
                    end;
               end;
  // Рассматриваем по очереди полученные отсортированные ходы
  
     if  (not tree[ply].onCheck)   then
       if (StaticEE(color,move)<0) then goto l2;
     if MakeMove(color,move,ply) then
        begin
        tree[ply+1].onCheck:=isAttack(color,opking);
        nextcheck:=false;
        if (docheck) and ((tree[ply+1].onCheck) or (onerep)) then nextcheck:=true;
        eval:=-FV(color xor 1,-beta,-alpha,ply+1,nextcheck,-mate);
        UnMakeMove(color,move,ply);
          if eval>bestvalue then
            begin
              bestvalue:=eval;
              tree[ply].bmove:=move;
            end;
          if eval>alpha then
             begin
               if eval>=beta then
                  begin
                    Result:=eval;
                    exit;
                  end;
               alpha:=eval;
               pvlen[ply]:=ply-1;
               CollectPV(ply,move);
             end;
        end
           else UnMakeMove(color,move,ply);
  l2:
       end;
// Пробуем давать тихие непроигрывающие шахи
 if  (docheck) and (not tree[ply].onCheck) then
    begin
     GenerateChecks(color,ply,0,Wpieses,Bpieses);
   // перебираем шахи последовательно
     for i:=point+1 to point+Takes[point] do
     begin
      if (Mtakes[i]<>OpenCheck) and (StaticEE(color,Takes[i])<0) then goto l3;
      if MakeMove(color,Takes[i],ply) then
       begin
         tree[ply+1].onCheck:=isAttack(color,opking);
         if tree[ply+1].onCheck
          then eval:=-FV(color xor 1,-beta,-alpha,ply+1,true,-mate)
          else eval:=bestvalue;
         UnMakeMove(color,Takes[i],ply);
         if eval>bestvalue then
            begin
              bestvalue:=eval;
              tree[ply].bmove:=Takes[i];
            end;
          if eval>alpha then
             begin
               if eval>=beta then
                  begin
                    Result:=eval;
                    exit;
                  end;
               alpha:=eval;
               pvlen[ply]:=ply-1;
               CollectPV(ply,Takes[i]);
             end;
       end
          else UnMakeMove(color,Takes[i],ply);
  l3:
      end;
    end;
Result:=bestvalue;
end;


Procedure GenerateChecks(color:integer;ply:integer;counts:integer;var Wpieses:int64;var Bpieses:int64);
var
   point,count,sq,shablon,shablon1,king,dest,indx,checksnow,i,piese:integer;
   emptysq,temp,kingknight,kingbishop,kingrook,kingqueen,kingpawn,kingpawn2,space,tspace,enemy:bitboard;
   pin : boolean;
begin
  point:=ply shl 7;
  count:=point+counts;
  emptysq:=not AllPieses;
if color=white then
 begin
  emptysq:=emptysq or (BlackPieses and (not BPieses));
  enemy:=not WhitePieses;
  king:=tree[ply].Bking;
  temp:=WhiteKnights;
  kingknight:=KnightsMove[king] and emptysq;
  shablon:=knight shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(black,king,sq);
      if pin
         then
         space:=knightsmove[sq] and enemy
         else
         space:=knightsmove[sq] and kingknight;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=-WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

  temp:=WhiteBishops;
  indx:=(AllDh1 shr Dsh1[king]) and MaskDh1[king];
  kingbishop:=RBDh1[king,indx];
  indx:=(AllDa1 shr Dsa1[king]) and MaskDa1[king];
  kingbishop:=(kingbishop or RBDa1[king,indx]) and emptysq;

  shablon:=bishop shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(black,king,sq);
      if pin
         then tspace:=enemy
         else
         tspace:=kingbishop;

      indx:=(AllDh1 shr Dsh1[sq]) and MaskDh1[sq];
      space:=RBDh1[sq,indx];
      indx:=(AllDa1 shr Dsa1[sq]) and MaskDa1[sq];
      space:=(space or RBDa1[sq,indx]) and tspace;

      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=-WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

  temp:=WhiteRooks;
  indx:=(AllPieses shr (Posyy[king] shl 3)) and 255;
  kingrook:=RB[king,indx];
  indx:=(AllR90 shr (Posxx[king] shl 3)) and 255;
  kingrook:=(kingrook or RBR90[king,indx]) and emptysq;
  shablon:=rook shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(black,king,sq);
      if pin
         then tspace:=enemy
         else
         tspace:=kingrook;

     indx:=(AllPieses shr (Posyy[sq] shl 3)) and 255;
     space:=RB[sq,indx];
     indx:=(AllR90 shr (Posxx[sq] shl 3)) and 255;
     space:=(space or RBR90[sq,indx]) and tspace;

      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=-WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

 temp:=WhiteQueens;
  kingqueen:=kingbishop or kingrook;
  shablon:=queen shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      indx:=(AllDh1 shr Dsh1[sq]) and MaskDh1[sq];
      space:=RBDh1[sq,indx];
      indx:=(AllDa1 shr Dsa1[sq]) and MaskDa1[sq];
      space:=(space or RBDa1[sq,indx]);
      indx:=(AllPieses shr (Posyy[sq] shl 3)) and 255;
      space:=(space or RB[sq,indx]);
      indx:=(AllR90 shr (Posxx[sq] shl 3)) and 255;
      space:=(space or RBR90[sq,indx]) and kingqueen;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=-WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;
 temp:=WhitePawns;
 kingpawn:=BPAttacks[king] and (not AllPieses);
 kingpawn2:=BPAttacks[king] and  BlackPieses and (not BPieses);
 shablon:=pawn shl 16;
 while temp<>0 do
   begin
     sq:=BitScanForward(temp);
     if posy[sq]<7 then
     begin
     shablon1:=shablon or sq;
     pin:=Pinned(black,king,sq);
     // Ход пешкой вперед
     if (Posx[sq]<>Posx[king]) and (pin)
        then space:=not AllPieses
        else space:=kingpawn;
     if (Only[sq+8] and space)<>0 then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq+8) shl 8);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     if (Posy[sq]=2) and ((Only[sq+8] and AllPieses)=0) and ((Only[sq+16] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq+16) shl 8);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
    // Взятия
     if (pin)
        then space:=BlackPieses
        else space:=kingpawn2;
     if (posx[sq]>1) and ((Only[sq+7] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq+7) shl 8);
          piese:=-WhatPiese(sq+7);
          if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     if (posx[sq]<8) and ((Only[sq+9] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq+9) shl 8);
          piese:=-WhatPiese(sq+9);
          if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     end;
     temp:=temp and NotOnly[sq];
   end;

end
   else
begin
  emptysq:=emptysq or (WhitePieses and (not WPieses));
  enemy:=not BlackPieses;
  king:=tree[ply].Wking;
  temp:=BlackKnights;
  kingknight:=KnightsMove[king] and emptysq;
  shablon:=knight shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(white,king,sq);
      if pin
         then space:=knightsmove[sq] and enemy
         else
         space:=knightsmove[sq] and kingknight;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

  temp:=BlackBishops;
  indx:=(AllDh1 shr Dsh1[king]) and MaskDh1[king];
  kingbishop:=RBDh1[king,indx];
  indx:=(AllDa1 shr Dsa1[king]) and MaskDa1[king];
  kingbishop:=(kingbishop or RBDa1[king,indx]) and emptysq;

  shablon:=bishop shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(white,king,sq);
      if pin
         then tspace:=enemy
         else
         tspace:=kingbishop;
      indx:=(AllDh1 shr Dsh1[sq]) and MaskDh1[sq];
      space:=RBDh1[sq,indx];
      indx:=(AllDa1 shr Dsa1[sq]) and MaskDa1[sq];
      space:=(space or RBDa1[sq,indx]) and tspace;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

  temp:=BlackRooks;
  indx:=(AllPieses shr (Posyy[king] shl 3)) and 255;
  kingrook:=RB[king,indx];
  indx:=(AllR90 shr (Posxx[king] shl 3)) and 255;
  kingrook:=(kingrook or RBR90[king,indx]) and emptysq;
  shablon:=rook shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      pin:=Pinned(white,king,sq);
      if pin
         then tspace:=enemy
         else
         tspace:=kingrook;
      indx:=(AllPieses shr (Posyy[sq] shl 3)) and 255;
      space:=RB[sq,indx];
      indx:=(AllR90 shr (Posxx[sq] shl 3)) and 255;
      space:=(space or RBR90[sq,indx]) and tspace;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;

 temp:=BlackQueens;
  kingqueen:=kingbishop or kingrook;
  shablon:=queen shl 16;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      indx:=(AllDh1 shr Dsh1[sq]) and MaskDh1[sq];
      space:=RBDh1[sq,indx];
      indx:=(AllDa1 shr Dsa1[sq]) and MaskDa1[sq];
      space:=(space or RBDa1[sq,indx]);
      indx:=(AllPieses shr (Posyy[sq] shl 3)) and 255;
      space:=(space or RB[sq,indx]);
      indx:=(AllR90 shr (Posxx[sq] shl 3)) and 255;
      space:=(space or RBR90[sq,indx]) and kingqueen;
      shablon1:=shablon or sq;
      while space<>0 do
         begin
           dest:=BitScanForward(space);
           inc(count);
           Takes[count]:=shablon1 or (dest shl 8);
           piese:=WhatPiese(dest);
           if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
           space:=space and NotOnly[dest];
         end;
       temp:=temp and NotOnly[sq];
    end;
 temp:=BlackPawns;
 kingpawn:=WPAttacks[king] and (not AllPieses);
 kingpawn2:=WPAttacks[king] and  WhitePieses and (not WPieses);
 shablon:=pawn shl 16;
 while temp<>0 do
   begin
     sq:=BitScanForward(temp);
     if posy[sq]>2 then
     begin
     shablon1:=shablon or sq;
     pin:=Pinned(white,king,sq);
     // Ход пешкой вперед
     if (Posx[sq]<>Posx[king]) and (pin)
        then space:=not AllPieses
        else space:=kingpawn;
     if (Only[sq-8] and space)<>0 then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq-8) shl 8);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     if (Posy[sq]=7) and ((Only[sq-8] and AllPieses)=0) and ((Only[sq-16] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq-16) shl 8);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     // Взятия
     if (pin)
        then space:=WhitePieses
        else space:=kingpawn2;
     if (posx[sq]>1) and ((Only[sq-9] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq-9) shl 8);
          piese:=WhatPiese(sq-9);
          if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     if (posx[sq]<8) and ((Only[sq-7] and space)<>0) then
        begin
          inc(count);
          Takes[count]:=shablon1 or ((sq-7) shl 8);
          piese:=WhatPiese(sq-7);
          if piese<>0 then Takes[count]:=Takes[count] or CaptureFlag or (piese shl 20);
          if pin
             then Mtakes[count]:=OpenCheck
             else Mtakes[count]:=0;
        end;
     end;
     temp:=temp and NotOnly[sq];
   end;

end;
Takes[point]:=count-point;
end;


end.

