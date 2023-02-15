unit Material;

interface
uses params,Board;
TYPE
    TMatHash = record
                 MatKey   : TmatKey;
                 scoreMid : smallint;
                 scoreend : smallint;
                 phase    : byte;
                 spacemul : byte;
                 Wmul     : byte;
                 Bmul     : byte;
                 flag     : integer;
               end;
   t8=array[0..8] of integer;
CONST
   PawnValueMid=80;
   PawnValueEnd=120;
   KnightValueMid=265;
   KnightValueEnd=355;
   BishopValueMid=280;
   BishopValueEnd=360;
   RookValueMid=405;
   RookValueEnd=610;
   QueenValueMid=800;
   QueenValueEnd=1150;
   BishopPairMid=35;
   BishopPairEnd=55;
   BishopPairBonusMid=5;
   BishopPairBonusEnd=5;
   KnightBonus : t8=(-25,-20,-15,-10,-5,0,5,10,15);
   RookBonus   : t8=(25,20,15,10,5,0,-5,-10,-15);
   BishopBonus : t8=(15,12,9,6,3,0,-3,-6,-9);
   RookRedundantMid=16;
   RookRedundantEnd=32;
   QueenRedundantMid=8;
   QueenRedundantEnd=16;
   TradeBonusMid=20;
   TradeBonusEnd=5;

   DoWkingSafety=1;
   DoBkingSafety=2;
   NoPawnEndgame=4;
   PawnEndgame=8;
   KBPK=16;
   RookEndgame=64;
   QueenEndgame=128;
   KBNK=256;
   KRPKR=512;
   SpaceFlag=1024;
   DifColorBishopFlag=2048;
   SpecialEndgame=NoPawnEndgame or PawnEndgame or KBPK;

   SpaceInd :t8 = (0,0,2,2,3,3,6,10,10);

VAR
   MatTable : array of TMatHash;


Function EvalMaterial(var Board:TBoard):integer;
implementation
uses BitBoards,evaluation;

Function EvalMaterial(var Board:TBoard):integer;
var
   index,wp,bp,wn,bn,wb,bb,wr,br,wq,bq,wminor,bminor,wmajor,bmajor,wshortmat,bshortmat,wtotal,btotal,spmul,scoremid,scoreend,phase,wmul,bmul,flag:integer;
begin
  index:=Board.MatKey and HashMatMask;
  result:=index;
  if (MatTable[index].MatKey=Board.MatKey)  then exit;
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
  wminor:=wn+wb;
  bminor:=bn+bb;
  wmajor:=wq*2+wr;
  bmajor:=bq*2+br;
  wtotal:=wmajor*2+wminor;
  btotal:=bmajor*2+bminor;
  wshortmat:=9*wq+5*wr+3*wminor;
  bshortmat:=9*bq+5*br+3*bminor;
  wmul:=10;
  bmul:=10;
  flag:=0;
  spmul:=0;
 // Устанавливаем флажки для некоторых типов эндшпилей
 // KBNK
 if (wp=0) and (bp=0) then
  begin
   flag:=flag or NoPawnEndgame;
   if (wtotal=2) and (btotal=0) and (wn=1) and (wb=1) then flag:=flag or KBNK;
   if (btotal=2) and (wtotal=0) and (bn=1) and (bb=1) then flag:=flag or KBNK;
  end;
 // Пешечный
 if (wtotal=0) and (btotal=0) and (wp+bp>0)  then
   begin
     flag:=flag or PawnEndgame;
     wmul:=14;
     bmul:=14;
   end;
 // Легкофигурный
 if (wtotal=1) and (btotal=1) and (wn=1) and (bn=1)  then
   begin
     wmul:=12;
     bmul:=12;
   end;
 if (wtotal=1) and (btotal=0) and (wb=1) and (wp>0) then flag:=flag or KBPK;
 if (btotal=1) and (wtotal=0) and (bb=1) and (bp>0) then flag:=flag or KBPK;
 // Ладейный
 if (wtotal=2) and (btotal=2) and (wr=1) and (br=1) then
  begin
   flag:=flag or RookEndgame;
   if (wp=1) and (bp=0) then flag:=flag or KRPKR;
   if (wp=0) and (bp=1) then flag:=flag or KRPKR;
  end;
// Ферзевый
 if (wtotal=4) and (btotal=4) and (wq=1) and (bq=1) then
  begin
   flag:=flag or QueenEndgame;
  end;
  // Разнопольные слоны
 if (wtotal=1) and (btotal=1) and (wb=1) and (bb=1) then  flag:=flag or DifColorBishopFlag;

// Безопасность
 if (wq>0) and (wtotal>4) then flag:=flag or DoBkingSafety;
 if (bq>0) and (btotal>4) then flag:=flag or DoWkingSafety;

 // Коэффициенты
 if wp=0 then
   begin
     if wtotal<=1 then wmul:=0; // 1 легкая фигура
     if wtotal=2 then     // 2 легкие или ладья
      begin
        if btotal=0 then
          begin
            if wn=2 then         //KNNK
              begin
                if bp>0
                  then wmul:=3
                  else wmul:=0;
              end;
          end;
         if btotal=1 then
           begin
             wmul:=1;
             if (wb=2) and (bn=1) then wmul:=8;   //KBBKN
             if (wr=1) and (bn=1) then wmul:=2;  //KRKN
           end;
         if btotal>=2 then wmul:=1;
      end;
     if (wtotal=3) and (wr=1) then   //KRB(N)-
      begin
        if (btotal=2) and (br=1) then wmul:=1;  //KRBKR KRNKR
        if (btotal=2) and (br=0) then
          begin
            wmul:=2;
            if (wb=1) and (bn=2) then wmul:=6; // KRBKNN
          end;
        if btotal>2 then wmul:=2;
      end;
     if (wtotal=3) and (wr=0) then
      begin
        if (btotal=2) and (br=1) then
         begin
           if (wn=2) then wmul:=2;  // KBNNKR
           if (wb=2) then wmul:=7; // KBBNKR
         end;
        if (btotal=2) and (br=0) then
          begin
            wmul:=2;
            if (wb=2) and (bn=2) then wmul:=4; //KBBNKNN
          end;
        if (btotal>2) then wmul:=2;
      end;
    if (wtotal=4) and (wq=1) then
      begin
        if (btotal=2) and (bn=2) then wmul:=2; //KQKNN
        if (btotal=2) and (bn=1) then wmul:=8; //KQKBN
        if (btotal=2) and (bb=2) then wmul:=7; //KQKBB
        if (btotal>2) then wmul:=1;
      end;
    if (wtotal=4) and (wr=2) then
      begin
        if (btotal=2) and (br=0) then wmul:=7;
        if (btotal=3) then  wmul:=2;
        if (btotal>3) then  wmul:=1;
      end;
    if (wtotal=4) and (wr=1) then
      begin
        if (btotal=3) and (br=1) then wmul:=3;
        if (btotal=3) and (br=0) then wmul:=2;
        if (btotal>3) then wmul:=2;
      end;
    if (wtotal=4) and (wq=0) and (wr=0) then
      begin
        if (btotal=3) and (br=1) then wmul:=4;
        if (btotal=3) and (br=0) then wmul:=2;
        if (btotal=4) and (bq=1) then wmul:=8;
        if (btotal=4) and (bq=0) then wmul:=1;
        if (btotal>4) then wmul:=1;
      end;
     if (wtotal=5) and (wq=1) then
      begin
        if (btotal=4) then wmul:=2;
        if (btotal=4) and (br=2) then
         begin
          if (wn=1) then wmul:=3;
          if (wb=1) then wmul:=7;
         end;
        if (btotal>4) then wmul:=1;
      end;
     if (wtotal=5) and (wr=1) then
      begin
        if (btotal=4) and (bq=1) then wmul:=9;
        if (btotal=4) and (br=2) then wmul:=7;
        if (btotal=4) and (br=1) then wmul:=3;
        if (btotal=4) and (br=0) and (bq=0) then wmul:=1;
        if (btotal>4) then wmul:=1;
      end;
    if (wtotal=5) and (wr=2) then
      begin
        if (btotal=4) and (bq=1) and (wb=1) then wmul:=8;
        if (btotal=4) and (bq=1) and (wn=1) then wmul:=7;
        if (btotal=4) and (br=2) then wmul:=3;
        if (btotal=4) and (br=1) then wmul:=2;
        if (btotal=4) and (br=0) and (bq=0) then wmul:=1;
        if (btotal>4) then wmul:=1;
      end;
    if (wtotal>5)  then
      begin
        if wshortmat>bshortmat+4 then wmul:=9;
        if wshortmat=bshortmat+4 then wmul:=7;
        if wshortmat=bshortmat+3 then wmul:=4;
        if wshortmat=bshortmat+2 then wmul:=2;
        if wshortmat<bshortmat+2 then wmul:=1;
      end;
   end else
 if wp=1 then
   begin
     if (btotal=1) then
       begin
         if (wtotal=1) then wmul:=3;
         if (wtotal=2) and (wn=2) then
           begin
             if (bp=0)
              then wmul:=3
              else wmul:=5;
           end;
         if (wtotal=2) and (wr=1) then wmul:=7;
       end;
      if (btotal=2) and (br=1) and (wtotal=2) and (wr=1) then wmul:=8;
      if (btotal=2) and (br=0) and (wtotal=2) then wmul:=4;
      if (btotal>2) and (bminor>0) and (wtotal=btotal)  then wmul:=3;
      if (btotal>2) and (bminor=0) and (wtotal=btotal)  then wmul:=5;
      if (btotal=4) and (bq=1) and (wtotal=btotal)  then wmul:=7;
   end;
 if bp=0 then
   begin
     if btotal<=1 then bmul:=0; // 1 легкая фигура
     if btotal=2 then     // 2 легкие или ладья
      begin
        if wtotal=0 then
          begin
            if bn=2 then         //KNNK
              begin
                if wp>0
                  then bmul:=3
                  else bmul:=0;
              end;
          end;
         if wtotal=1 then
           begin
             bmul:=1;
             if (bb=2) and (wn=1) then bmul:=8;   //KBBKN
             if (br=1) and (wn=1) then bmul:=2;  //KRKN
           end;
         if wtotal>=2 then bmul:=1;
      end;
     if (btotal=3) and (br=1) then   //KRB(N)-
      begin
        if (wtotal=2) and (wr=1) then bmul:=1;  //KRBKR KRNKR
        if (wtotal=2) and (wr=0) then
          begin
            bmul:=2;
            if (bb=1) and (wn=2) then bmul:=6; // KRBKNN
          end;
        if wtotal>2 then bmul:=2;
      end;
     if (btotal=3) and (br=0) then
      begin
        if (wtotal=2) and (wr=1) then
         begin
           if (bn=2) then bmul:=2;  // KBNNKR
           if (bb=2) then bmul:=7; // KBBNKR
         end;
        if (wtotal=2) and (wr=0) then
          begin
            bmul:=2;
            if (bb=2) and (wn=2) then bmul:=4; //KBBNKNN
          end;
        if (wtotal>2) then bmul:=2;
      end;
    if (btotal=4) and (bq=1) then
      begin
        if (wtotal=2) and (wn=2) then bmul:=2; //KQKNN
        if (wtotal=2) and (wn=1) then bmul:=8; //KQKBN
        if (wtotal=2) and (wb=2) then bmul:=7; //KQKBB
        if (wtotal>2) then bmul:=1;
      end;
    if (btotal=4) and (br=2) then
      begin
        if (wtotal=2) and (wr=0) then bmul:=7;
        if (wtotal=3) then  bmul:=2;
        if (wtotal>3) then  bmul:=1;
      end;
    if (btotal=4) and (br=1) then
      begin
        if (wtotal=3) and (wr=1) then bmul:=3;
        if (wtotal=3) and (wr=0) then bmul:=2;
        if (wtotal>3) then bmul:=2;
      end;
    if (btotal=4) and (bq=0) and (br=0) then
      begin
        if (wtotal=3) and (wr=1) then bmul:=4;
        if (wtotal=3) and (wr=0) then bmul:=2;
        if (wtotal=4) and (wq=1) then bmul:=8;
        if (wtotal=4) and (wq=0) then bmul:=1;
        if (wtotal>4) then bmul:=1;
      end;
     if (btotal=5) and (bq=1) then
      begin
        if (wtotal=4) then bmul:=2;
        if (wtotal=4) and (wr=2) then
         begin
          if (bn=1) then bmul:=3;
          if (bb=1) then bmul:=7;
         end;
        if (wtotal>4) then bmul:=1;
      end;
     if (btotal=5) and (br=1) then
      begin
        if (wtotal=4) and (wq=1) then bmul:=9;
        if (wtotal=4) and (wr=2) then bmul:=7;
        if (wtotal=4) and (wr=1) then bmul:=3;
        if (wtotal=4) and (wr=0) and (wq=0) then bmul:=1;
        if (wtotal>4) then bmul:=1;
      end;
    if (btotal=5) and (br=2) then
      begin
        if (wtotal=4) and (wq=1) and (bb=1) then bmul:=8;
        if (wtotal=4) and (wq=1) and (bn=1) then bmul:=7;
        if (wtotal=4) and (wr=2) then bmul:=3;
        if (wtotal=4) and (wr=1) then bmul:=2;
        if (wtotal=4) and (wr=0) and (wq=0) then bmul:=1;
        if (wtotal>4) then bmul:=1;
      end;
    if (btotal>5)  then
      begin
        if bshortmat>wshortmat+4 then bmul:=9;
        if bshortmat=wshortmat+4 then bmul:=7;
        if bshortmat=wshortmat+3 then bmul:=4;
        if bshortmat=wshortmat+2 then bmul:=2;
        if bshortmat<wshortmat+2 then bmul:=1;
      end;
   end else
 if bp=1 then
   begin
     if (wtotal=1) then
       begin
         if (btotal=1) then bmul:=3;
         if (btotal=2) and (bn=2) then
           begin
             if (wp=0)
              then bmul:=3
              else bmul:=5;
           end;
         if (btotal=2) and (br=1) then bmul:=7;
       end;
      if (wtotal=2) and (wr=1) and (btotal=2) and (br=1) then bmul:=8;
      if (wtotal=2) and (wr=0) and (btotal=2) then bmul:=4;
      if (wtotal>2) and (wminor>0) and (btotal=wtotal)  then bmul:=3;
      if (wtotal>2) and (wminor=0) and (btotal=wtotal)  then bmul:=5;
      if (wtotal=4) and (wq=1) and (btotal=wtotal)  then bmul:=7;
   end;


 // считаем фазу
  phase:=(wn+wb+bn+bb)+(wr+br)*3+(wq+bq)*6;
  if phase>32 then phase:=32;
 // пространство
  if (phase>=26) then
   begin
    flag:=flag or SpaceFlag;
    spmul:=(wminor+bminor);
   end;
// материальная оценка
  scoremid:=(wp-bp)*PawnValueMid+(wn-bn)*KnightValueMid+(wb-bb)*BishopValueMid+(wr-br)*RookValueMid+(wq-bq)*QueenValueMid;
  scoreend:=(wp-bp)*PawnValueEnd+(wn-bn)*KnightValueEnd+(wb-bb)*BishopValueEnd+(wr-br)*RookValueEnd+(wq-bq)*QueenValueEnd;

  scoremid:=scoremid+wr*RookBonus[wp]-br*RookBonus[bp];
  scoreend:=scoreend+wn*KnightBonus[wp]-bn*KnightBonus[bp];

  if (wminor>bminor) then
    begin
      scoremid:=scoremid+tradeBonusMid;
      scoreend:=scoreend+tradeBonusEnd;
    end;
  if (wminor<bminor)  then
    begin
      scoremid:=scoremid-TradeBonusMid;
      scoreend:=scoreend-TradeBonusEnd;
    end;

  if wb>1 then
    begin
      scoremid:=scoremid+BishopPairMid;
      scoreend:=scoreend+BishopPairEnd+BishopBonus[wp];
      if (Bminor=0) then
        begin
          scoremid:=scoremid+BishopPairBonusMid;
          scoreend:=scoreend+BishopPairBonusEnd;
        end;
    end;
  if bb>1 then
    begin
      scoremid:=scoremid-BishopPairMid;
      scoreend:=scoreend-BishopPairEnd-BishopBonus[bp];
      if (Wminor=0) then
        begin
          scoremid:=scoremid-BishopPairBonusMid;
          scoreend:=scoreend-BishopPairBonusEnd;
        end;
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

  if (wr+wq>1)   then
    begin
      scoremid:=scoremid-QueenRedundantMid;
      scoreend:=scoreend-QueenRedundantEnd;
    end;
  if (br+bq>1)  then
    begin
      scoremid:=scoremid+QueenRedundantMid;
      scoreend:=scoreend+QueenRedundantEnd;
    end;

  // Сохраняем данные
  MatTable[index].MatKey:=Board.MatKey;
  MatTable[index].scoreMid:=scoremid;
  MatTable[index].scoreend:=scoreend;
  MatTable[index].phase:=phase;
  MatTable[index].spacemul:=spmul;
  MatTable[index].Wmul:=wmul;
  MatTable[index].Bmul:=bmul;
  MatTable[index].flag:=flag;
end;

end.
