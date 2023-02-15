unit see;

interface
uses params,bitboards,attacks;
var
   QR,QB : bitboard;
Function StaticEE(color : integer;move:integer):integer;
Procedure AddRentgen(const from:integer;const dir:integer;var AllAttacks:bitboard);
Function StaticSQ(color : integer;dest:integer):integer;
implementation

Function StaticEE(color : integer;move:integer):integer;
var
   AllAttacks : bitboard;
   from,dest,counter,col,PrevPiese,PrevValue,square : integer;
   TakesList : array[1..32] of integer;
   promo : integer;
begin

  from:=move and 255;
  dest:=(move shr 8) and 255;
  promo:=(move shr 24) and 15;
  square:=0;
  QR:=WQR or BQR;
  QB:=WQB or BQB;
  //1. —оздаем битборд, содержащий все вз€ти€ за оба цвета на искомом поле
  AllAttacks:=AttackedFrom(dest);
  //2. —оздаем последовательность вз€тий, состо€щую из  вз€тий
 // фигур наименьшей ценности на поле Dest. –азумеетс€ первый элемент этой после
 //довательности будет исследуемое вз€тие.
  PrevPiese:=WhatPiese(from);
  if promo>0
     then PrevValue:=PiesePrice[promo]-PawnValue
     else PrevValue:=PiesePrice[PrevPiese];
  counter:=1;
  TakesList[1]:=PiesePrice[WhatPiese(dest)]+PiesePrice[promo];
  AllAttacks:=AllAttacks and NotOnly[from];
  if abs(PrevPiese) in [Pawn,Bishop,Rook,Queen] then
          AddRentgen(from,direction[dest,from],AllAttacks);
  // “еперь идет цикл последовательных определений вз€тий
  col:=color;
  While AllAttacks<>0 do
    begin
      col:=col xor 1;
      if col=white then
        begin
          // провер€ем последовательно от младшей фигуры к старшей- именно в таком пор€дке нам надо
         // разместить цепочку фигур перед минимаксом.  ороли тоже участвуют (у них настолько высока€ оценка
         // что бить они будут в самую последнюю очередь)
         if (WhitePawns and AllAttacks)<>0
                          then square:=BitScanForward(WhitePawns and AllAttacks)
         else
          if (WhiteKnights and AllAttacks)<>0
                          then square:=BitScanForward(WhiteKnights and AllAttacks)
         else
          if (WhiteBishops and AllAttacks)<>0
                          then square:=BitScanForward(WhiteBishops and AllAttacks)
         else
          if (WhiteRooks and AllAttacks)<>0
                          then square:=BitScanForward(WhiteRooks and AllAttacks)
         else
          if (WhiteQueens and AllAttacks)<>0
                          then square:=BitScanForward(WhiteQueens and AllAttacks)
         else
          if (WhiteKing and AllAttacks)<>0
                          then square:=BitScanForward(WhiteKing and AllAttacks)
         else break;
       end
          else
        begin
         if (BlackPawns and AllAttacks)<>0
                          then square:=BitScanForward(BlackPawns and AllAttacks)
         else
          if (BlackKnights and AllAttacks)<>0
                          then square:=BitScanForward(BlackKnights and AllAttacks)
         else
          if (BlackBishops and AllAttacks)<>0
                          then square:=BitScanForward(BlackBishops and AllAttacks)
         else
          if (BlackRooks and AllAttacks)<>0
                          then square:=BitScanForward(BlackRooks and AllAttacks)
         else
          if (BlackQueens and AllAttacks)<>0
                          then square:=BitScanForward(BlackQueens and AllAttacks)
         else
          if (BlackKing and AllAttacks)<>0
                          then square:=BitScanForward(BlackKing and AllAttacks)
         else break;
        end;
     inc(counter);
     TakesList[counter]:=-TakesList[counter-1]+PrevValue;
     PrevPiese:=WhatPiese(Square);
     PrevValue:=PiesePrice[PrevPiese];
     AllAttacks:=AllAttacks and NotOnly[square];
     if abs(PrevPiese)in [Pawn,Bishop,Rook,Queen]
                                    then AddRentgen(Square,Direction[dest,square],AllAttacks);
    end;
// 3. Ќебольшой минимакс дл€ определени€ момента, когда одна из сторон может отказатьс€
// от вз€ти€.
 while counter>1 do
    begin
     if TakesList[counter]>-TakesList[counter-1] then TakesList[counter-1]:=-TakesList[counter];
    dec(counter);
    end;

// ¬озвращаем прогнозируемый выигрыш
Result:=TakesList[1];
end;

Procedure AddRentgen(const from:integer;const dir:integer;var AllAttacks:bitboard);
// ѕроцедура ищет рентгены, наход€щиес€ за скольз€щими фигурами на поле from
// и если находит,то добавл€ет их в общий список вз€тий (иде€ слизана у Crafty).
begin
  case dir of
   -10 : AllAttacks:=AllAttacks or (RooksRankMove(from) and (QR) and LDir[from]);
    10 : AllAttacks:=AllAttacks or (RooksRankMove(from) and (QR) and RDir[from]);
   -1  : AllAttacks:=AllAttacks or (RooksFileMove(from) and (QR) and DDir[from]);
    1  : AllAttacks:=AllAttacks or (RooksFileMove(from) and (QR) and UDir[from]);
   -11 : AllAttacks:=AllAttacks or (Bishopsa1Move(from) and (QB) and DLDir[from]);
    11 : AllAttacks:=AllAttacks or (Bishopsa1Move(from) and (QB) and URDir[from]);
   -9  : AllAttacks:=AllAttacks or (Bishopsh1Move(from) and (QB) and ULDir[from]);
    9  : AllAttacks:=AllAttacks or (Bishopsh1Move(from) and (QB) and DRDir[from]);
    end;
end;
Function StaticSQ(color : integer;dest:integer):integer;
var
   AllAttacks : bitboard;
   counter,col,PrevPiese,PrevValue,square : integer;
   TakesList : array[1..32] of integer;
begin
  square:=0;
  QR:=WQR or BQR;
  QB:=WQB or BQB;
  //1. —оздаем битборд, содержащий все вз€ти€ за оба цвета на искомом поле
  AllAttacks:=AttackedFrom(dest);
  //2. —оздаем последовательность вз€тий, состо€щую из  вз€тий
 // фигур наименьшей ценности на поле Dest. –азумеетс€ первый элемент этой после
 //довательности будет исследуемое вз€тие.
  PrevPiese:=WhatPiese(dest);
  PrevValue:=PiesePrice[PrevPiese];
  counter:=1;
  TakesList[1]:=0;
  // “еперь идет цикл последовательных определений вз€тий
  col:=color;
  While AllAttacks<>0 do
    begin
      col:=col xor 1;
      if col=white then
        begin
          // провер€ем последовательно от младшей фигуры к старшей- именно в таком пор€дке нам надо
         // разместить цепочку фигур перед минимаксом.  ороли тоже участвуют (у них настолько высока€ оценка
         // что бить они будут в самую последнюю очередь)
         if (WhitePawns and AllAttacks)<>0
                          then square:=BitScanForward(WhitePawns and AllAttacks)
         else
          if (WhiteKnights and AllAttacks)<>0
                          then square:=BitScanForward(WhiteKnights and AllAttacks)
         else
          if (WhiteBishops and AllAttacks)<>0
                          then square:=BitScanForward(WhiteBishops and AllAttacks)
         else
          if (WhiteRooks and AllAttacks)<>0
                          then square:=BitScanForward(WhiteRooks and AllAttacks)
         else
          if (WhiteQueens and AllAttacks)<>0
                          then square:=BitScanForward(WhiteQueens and AllAttacks)
         else
          if (WhiteKing and AllAttacks)<>0
                          then square:=BitScanForward(WhiteKing and AllAttacks)
         else break;
       end
          else
        begin
         if (BlackPawns and AllAttacks)<>0
                          then square:=BitScanForward(BlackPawns and AllAttacks)
         else
          if (BlackKnights and AllAttacks)<>0
                          then square:=BitScanForward(BlackKnights and AllAttacks)
         else
          if (BlackBishops and AllAttacks)<>0
                          then square:=BitScanForward(BlackBishops and AllAttacks)
         else
          if (BlackRooks and AllAttacks)<>0
                          then square:=BitScanForward(BlackRooks and AllAttacks)
         else
          if (BlackQueens and AllAttacks)<>0
                          then square:=BitScanForward(BlackQueens and AllAttacks)
         else
          if (BlackKing and AllAttacks)<>0
                          then square:=BitScanForward(BlackKing and AllAttacks)
         else break;
        end;
     inc(counter);
     TakesList[counter]:=-TakesList[counter-1]+PrevValue;
     PrevPiese:=WhatPiese(Square);
     PrevValue:=PiesePrice[PrevPiese];
     AllAttacks:=AllAttacks and NotOnly[square];
     if abs(PrevPiese)in [Pawn,Bishop,Rook,Queen]
                                    then AddRentgen(Square,Direction[dest,square],AllAttacks);
    end;
// 3. Ќебольшой минимакс дл€ определени€ момента, когда одна из сторон может отказатьс€
// от вз€ти€.
 while counter>1 do
    begin
     if TakesList[counter]>-TakesList[counter-1] then TakesList[counter-1]:=-TakesList[counter];
    dec(counter);
    end;

// ¬озвращаем прогнозируемый выигрыш
Result:=TakesList[1];
end;
end.
