unit Material;

interface
uses params,Board;
TYPE
    TMatHash = record
                 MatKey   : TmatKey;
                 scoreMid : smallint;
                 scoreend : smallint;
                 phase    : byte;
                 Wmul     : byte;
                 Bmul     : byte;
                 flag     : integer;
               end;
CONST
   PawnValueMid=80;
   PawnValueEnd=100;
   KnightValueMid=325;
   KnightValueEnd=325;
   BishopValueMid=325;
   BishopValueEnd=325;
   RookValueMid=500;
   RookValueEnd=500;
   QueenValueMid=975;
   QueenValueEnd=975;
   BishopPairMid=50;
   BishopPairEnd=50;

   RookRedundantMid=16;
   RookRedundantEnd=32;
   QueenRedundantMid=8;
   QueenRedundantEnd=16;
   TradeBonusMid=30;
   TradeBonusEnd=30;

   DoWkingSafety=1;
   DoBkingSafety=2;
   NoPawnEndgame=4;
   PawnEndgame=8;
   KBPK=16;
   RookEndgame=64;
   QueenEndgame=128;
   KBNK=256;
   KRPKR=512;
   SpecialEndgame=NoPawnEndgame or PawnEndgame or KBPK or KRPKR;
VAR
   MatTable : array of TMatHash;


Function EvalMaterial(var Board:TBoard):integer;
implementation
uses BitBoards,evaluation;

Function EvalMaterial(var Board:TBoard):integer;
var
   index,wp,bp,wn,bn,wb,bb,wr,br,wq,bq,wminor,bminor,wmajor,bmajor,wtotal,btotal,scoremid,scoreend,phase,wmul,bmul,flag,wmat:integer;
begin
  index:=Board.MatKey and HashMatMask;
  result:=index;
//  if MatTable[index].MatKey=Board.MatKey then exit;
  // Инициализация
  wp:=BitCount(Board.Pieses[WhitePawn]);
  bp:=BitCount(Board.Pieses[BlackPawn]);
  wn:=BitCount(Board.Pieses[WhiteKnight]);
  bn:=BitCount(Board.Pieses[BlackKnight]);
  wb:=BitCount(Board.Pieses[WhiteBishop]);
  bb:=BitCount(Board.Pieses[BlackBishop]);
  wr:=BitCount(Board.Pieses[WhiteRook]);
  br:=BitCount(Board.Pieses[BlackRook]);
  wq:=BitCount(Board.Pieses[WhiteQueen]);
  bq:=BitCount(Board.Pieses[BlackQueen]);

 { wq:=0;
  bq:=0;
  wr:=0;
  br:=1;
  wb:=1;
  bb:=0;
  wn:=1;
  bn:=0;
  wp:=5;
  bp:=5;
 }
  wminor:=wn+wb;
  bminor:=bn+bb;
  wmajor:=wq*2+wr;
  bmajor:=bq*2+br;
  wtotal:=wmajor*2+wminor;
  btotal:=bmajor*2+bminor;
  wmul:=16;
  bmul:=16;
  flag:=0;
 // Устанавливаем флажки для некоторых типов эндшпилей
 if (wp=0) and (bp=0) then
  begin
   flag:=flag or NoPawnEndgame;
   if (wtotal=2) and (btotal=0) and (wn=1) and (wb=1) then flag:=flag or KBNK;
   if (btotal=2) and (wtotal=0) and (bn=1) and (bb=1) then flag:=flag or KBNK;
  end;
 if (wtotal=0) and (btotal=0)  then
   begin
     flag:=flag or PawnEndgame;
     wmul:=24;
     bmul:=24;
   end;
 if (wtotal=1) and (btotal=0) and (wb=1) and (wp>0) then flag:=flag or KBPK;
 if (btotal=1) and (wtotal=0) and (bb=1) and (bp>0) then flag:=flag or KBPK;
 if (wtotal=2) and (btotal=2) and (wr=1) and (br=1) then
  begin
   flag:=flag or RookEndgame;
   if (wp=1) and (bp=0) then flag:=flag or KRPKR;
   if (wp=0) and (bp=1) then flag:=flag or KRPKR;
  end;
 if (wtotal=4) and (btotal=4) and (wq=1) and (bq=1) then flag:=flag or QueenEndgame;
 // Коэффициенты
 if wp=0 then
   begin
     if wtotal<=1 then wmul:=0 else // KB(N)K*
     if (wtotal=2) and (wn=2) then // KNNK*
       begin
         if (btotal>0) or (bp=0) then wmul:=0
                                 else wmul:=4;
       end else
     if (wtotal=2) and (wb=2) and (Btotal=1) and (bn=1) then wmul:=8  else //KBBKN
     if (wtotal-btotal<2) and (wmajor<=2) then wmul:=4; // Недостающий для мата материал
   end else
 if wp=1 then
   begin
     if (bminor>0) then
       begin
         // Можно отдать фигуру за единственную пешку
         if wtotal=1 then wmul:=8 else
         if (wtotal=2) and (wn=2) then wmul:=8 else
         if ((wtotal+1-btotal)<2) and (wmajor<=2) then wmul:=12;
       end else
     if (br>0) then
       begin
         // Можно отдать ладью за единственную пешку
         if wtotal=1 then wmul:=4 else
         if (wtotal=2) and (wn=2) then wmul:=4 else
         if ((wtotal+2-btotal)<2) and (wmajor<=2) then wmul:=8;
       end;
   end;
 if bp=0 then
   begin
     if btotal<=1 then bmul:=0 else // KB(N)K*
     if (btotal=2) and (bn=2) then // KNNK*
       begin
         if (wtotal>0) or (wp=0) then bmul:=0
                                 else bmul:=4;
       end else
     if (btotal=2) and (bb=2) and (wtotal=1) and (wn=1) then bmul:=8  else //KBBKN
     if (btotal-wtotal<2) and (bmajor<=2) then bmul:=4; // Недостающий для мата материал
   end else
 if bp=1 then
   begin
     if (wminor>0) then
       begin
         // Можно отдать фигуру за единственную пешку
         if btotal=1 then bmul:=8 else
         if (btotal=2) and (bn=2) then bmul:=8 else
         if ((btotal+1-wtotal)<2) and (bmajor<=2) then bmul:=12;
       end else
     if (wr>0) then
       begin
         // Можно отдать ладью за единственную пешку
         if btotal=1 then bmul:=4 else
         if (btotal=2) and (bn=2) then bmul:=4 else
         if ((btotal+2-wtotal)<2) and (bmajor<=2) then bmul:=8;
       end;
   end;
 // Разнопольные слоны
 if (wtotal=1) and (btotal=1) and (wb=1) and (bb=1) then
   begin
     if (((Board.Pieses[WhiteBishop] and light)<>0) and ((Board.Pieses[BlackBishop] and dark)<>0)) or
        (((Board.Pieses[WhiteBishop] and dark)<>0) and ((Board.Pieses[BlackBishop] and light)<>0)) then
       begin
         wmul:=8;
         bmul:=8;
       end;
   end;


 // считаем фазу
  phase:=(wn+wb+bn+bb)+(wr+br)*2+(wq+bq)*4;
  if phase>24 then phase:=24;
  
 // теперь безопасность королей
  if (wq>0)   then flag:=flag or DoBKingSafety;
  if (bq>0)   then flag:=flag or DoWKingSafety;
// материальная оценка
  wmat:=(wn-bn)*KnightValueMid+(wb-bb)*BishopValueMid+(wr-br)*RookValueMid+(wq-bq)*QueenValueMid;
  scoremid:=(wp-bp)*PawnValueMid+wmat;
  scoreend:=(wp-bp)*PawnValueEnd+(wn-bn)*KnightValueEnd+(wb-bb)*BishopValueEnd+(wr-br)*RookValueEnd+(wq-bq)*QueenValueEnd;
  if (wmat>0) and (wmul=16) then
    begin
      scoremid:=scoremid+TradeBonusMid;
      scoreend:=scoreend+TradeBonusEnd;
    end else
  if  (wmat<0) and (bmul=16) then
    begin
      scoremid:=scoremid-TradeBonusMid;
      scoreend:=scoreend-TradeBonusEnd;
    end;
  if wb>1 then
    begin
      scoremid:=scoremid+BishopPairMid;
      scoreend:=scoreend+BishopPairEnd;
    end;
  if bb>1 then
    begin
      scoremid:=scoremid-BishopPairMid;
      scoreend:=scoreend-BishopPairEnd;
    end;
  if wr>1 then
    begin
      scoremid:=scoremid-RookRedundantMid;
      scoreend:=scoreend-RookRedundantEnd;
    end;
  if br>1 then
    begin
      scoremid:=scoremid+RookRedundantMid;
      scoreend:=scoreend+RookRedundantEnd;
    end;
 if (wq>0) and ((wr+wq)>1) then
    begin
      scoremid:=scoremid-QueenRedundantMid;
      scoreend:=scoreend-QueenRedundantEnd;
    end;
  if (bq>0) and ((br+bq)>1) then
    begin
      scoremid:=scoremid+QueenRedundantMid;
      scoreend:=scoreend+QueenRedundantEnd;
    end;
  // Сохраняем данные
  MatTable[index].MatKey:=Board.MatKey;
  MatTable[index].scoreMid:=scoremid;
  MatTable[index].scoreend:=scoreend;
  MatTable[index].phase:=phase;
  MatTable[index].Wmul:=wmul;
  MatTable[index].Bmul:=bmul;
  MatTable[index].flag:=flag;
end;

end.
