unit captures;
// Юнит отвечает за генерирование "форсированных" ходов.
interface
uses params,bitboards;
Procedure GetCaptures(color:integer;ply:integer;var Wpieses:int64;var Bpieses:int64);

implementation

Procedure GetCaptures(color:integer;ply:integer;var Wpieses:int64;var Bpieses:int64);
// Данная процедура генерирует   псевдолегальные взятия + превращения пешек в ферзя.
// Превращения пешек в другие фигуры (в том числе и взятия) рассматриваются в процедуре GetMoves.
var
   temp,attack,space : bitboard;
   from,dest,count,point,indx,piese : integer;
   shablon,shablon1 : move;
  begin
   // Вычисляем индекс в массиве ходов
    point:=ply shl 7;
    count:=point;
if color=white then
 Begin   // Белые взятия

  // Взятия конями
    temp:=WhiteKnights;
    shablon:=Captureflag or (knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and BPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((-WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

  // Взятия слонами
    temp:=WhiteBishops;
    shablon:=Captureflag or (bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and BPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((-WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

  // Взятия ладьями
    temp:=WhiteRooks;
 //   PrintBitBoard(allpieses);
 //   PrintBitBoard(BlackPieses);
    shablon:=Captureflag or (rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and BPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((-WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   // Взятия ферзями
    temp:=WhiteQueens;
    shablon:=Captureflag or (queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and BPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((-WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

    // Взятия королем
        from:=tree[ply].wking;
        attack:=KingsMove[from] and BPieses;
        shablon1:=Captureflag or (king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((-WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;

    space:=not AllPieses;
 // Рассматриваем пешечные превращения в ферзя
   temp:=((WhitePawns and Ranks[7]) shl 8) and space;
   while temp<>0 do
     begin
       dest:=BitScanForward(temp);
       inc(count);
       takes[count]:=PromoteFlag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
       temp:=temp and NotOnly[dest];
     end;
 // теперь пешечные взятия (в том числе и взятие на проходе)
     if tree[ply].EnnPass<>0
       then
           space:=BPieses or Only[tree[ply].EnnPass]
       else
           space:=BPieses;
     //Взятия пешек "влево"
     temp :=((WhitePawns and noafile) shl 7) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest<a8) then
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 takes[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest-7)
                              else
                 takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
             end
                      else
             begin
               inc(count);
               piese:=-WhatPiese(dest);
               takes[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
             end;
         temp:=temp and NotOnly[dest];
       end;
      //Взятия пешек "вправо"
     temp :=((WhitePawns and nohfile) shl 9) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest<a8) then
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 takes[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest-9)
                              else
                 takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
             end
                      else
             begin
               inc(count);
               piese:=-WhatPiese(dest);
               takes[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
             end;
         temp:=temp and NotOnly[dest];
       end;

 End
           else
 Begin  // Черные взятия
   // Взятия конями
    temp:=BlackKnights;
    shablon:=Captureflag or (knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and WPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
  // Взятия слонами
    temp:=BlackBishops;
    shablon:=Captureflag or (bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and WPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

  // Взятия ладьями
    temp:=BlackRooks;
    shablon:=Captureflag or (rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and WPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   // Взятия ферзями
    temp:=BlackQueens;
    shablon:=Captureflag or (queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and WPieses;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

    // Взятия королем
        from:=tree[ply].Bking;
        attack:=KingsMove[from] and WPieses;
        shablon1:=Captureflag or (king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            takes[count]:=shablon1 or (dest shl 8) or ((WhatPiese(dest)) shl 20);
            attack:=attack and NotOnly[dest];
          end;
    space:=not AllPieses;
 // Рассматриваем пешечные превращения в ферзя
   temp:=((BlackPawns and Ranks[2]) shr 8) and space;
   while temp<>0 do
     begin
       dest:=BitScanForward(temp);
       inc(count);
       takes[count]:=PromoteFlag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
       temp:=temp and NotOnly[dest];
     end;
 // теперь пешечные взятия (в том числе и взятие на проходе)
    if tree[ply].EnnPass<>0 then
                              space:=WPieses or Only[tree[ply].EnnPass]
                            else
                              space:=WPieses;
     //Взятия пешек "влево"
     temp :=((BlackPawns and noafile) shr 9) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest>h1) then
             begin
               piese:=WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 takes[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest+9)
                              else
                 takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
             end
                      else
             begin
               inc(count);
               piese:=WhatPiese(dest);

               takes[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
             end;
         temp:=temp and NotOnly[dest];
       end;
      //Взятия пешек "вправо"
     temp :=((BlackPawns and nohfile) shr 7) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest>h1) then
             begin
               piese:=WhatPiese(dest);

               inc(count);
               if piese=Empty then
                 takes[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest+7)
                              else
                 takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
             end
                      else
             begin
               inc(count);

               piese:=WhatPiese(dest);
               takes[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
             end;
         temp:=temp and NotOnly[dest];
       end;

 End;
 // Напоследок обновляем счетчик взятий
   takes[point]:=count-point;
  end;

end.


