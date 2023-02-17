unit uPawn;

interface
 uses uBoard,uBitBoards,uAttacks,uMagic;

Type
  TPawnEntry = record
                 PawnKey      : int64;
                 ScoreMid     : smallint;
                 ScoreEnd     : smallint;
                 PassersBB    : TBitBoard;
                 WShelter     : byte;
                 BShelter     : byte;
                 WKSq         : shortint;
                 BKSq         : shortint;
                 WCastle      : byte;
                 BCastle      : byte;
                 WSpan        : TBitBoard;
                 BSpan        : TBitBoard;
               end;
Const
  IsolatedClosedMid =2;
  IsolatedClosedEnd =7;
  IsolatedOpenMid   =8;
  IsolatedOpenEnd   =17;

  BackWardClosedMid = 4;
  BackWardClosedEnd = 10;
  BackWardOpenMid   = 10;
  BackWardopenEnd   = 20;


  DoubledMid = 5;
  DoubledEnd =22;
  PawnSupported=5;


  ConnectedBase : array[1..8] of integer =(0,2,2,4,8,16,32,64);

  Shelter         : array[0..3,1..8] of integer =(
    (30,5, 0,10,15,25,25,25),
    (45,0,10,35,40,45,45,45),
    (35,0,10,20,30,35,35,35),
    (35,5,15,25,35,35,35,35)
  );

  Storm          : array[0..3,1..8] of integer =(
    (5,-90,-40,15,5,0,0,0),
    (5,-10, 60,15,5,0,0,0),
    (5, 40, 60,15,5,0,0,0),
    (5, 25, 60,15,5,0,0,0)
  );
  StormBlocked          : array[0..3,1..8] of integer =(
    ( 0,0,30, 0,0,0,0,0),
    ( 0,0,30, 0,0,0,0,0),
    ( 0,0,30, 0,0,0,0,0),
    ( 0,0,30, 0,0,0,0,0)
  );

  MaxShieldPenalty=255;
  PasserBaseMid : array[1..8] of Integer = (0, 4, 6, 8,25,65,110,0);
  PasserBaseEnd : array[1..8] of Integer = (0, 8,10,12,30,70,110,0);
  PasserBonus   : array[1..8] of Integer = (0, 0, 0, 1, 3, 5, 7, 0);

  WeakKingDist     : array[1..8] of integer = (0,0,0,5,15,25,35,0);
  StrongKingDist1  : array[1..8] of integer = (0,0,0,2, 6,10,14,0);
  StrongKingDist2  : array[1..8] of integer = (0,0,0,1, 3, 5, 7,0);

var
   ConnectedMid,ConnectedEnd : array[2..7,False..True,False..True,0..2] of integer;

Procedure InitPawnTable(SizeMB:integer);
Function EvaluatePawns(var Board:TBoard;ThreadId:integer):int64;inline;
Function WKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
Function BKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
Function WKShield(king:integer;var Board:TBoard):integer; inline;
Function BKShield(king:integer;var Board:TBoard):integer; inline;
Procedure EvaluatePassers(var TotalMid:integer;var TotalEnd:integer;PassersBB:TBitBoard;var Board:TBoard;WAtt:TBitBoard;BAtt:TBitBoard);inline;

implementation
  uses uThread,uSearch;
Procedure InitPawnTable(SizeMB:integer);
// На входе - ОБЩЕЕ количество мегабайт кеша, полученного от оболочки
var
   PawnTableSize,i : int64;
   j : integer;
begin
  PawnTableSize:=SizeMb;
  // Общая память под пешечный хеш
  PawnTableSize:=(PawnTableSize * 1024 * 1024) div (32*32);  {1/32 доля хеша. Размер ячейки берем 32 }
  // Для каждого потока устанавливаем параметры памяти
  for j:=1 to game.Threads do
   begin
    Threads[j].PawnTableMask:=(PawnTableSize div game.Threads)-1;
    SetLength(Threads[j].PawnTable,0);
    SetLength(Threads[j].PawnTable,Threads[j].PawnTableMask+1);
    for i:=0 to Threads[j].PawnTableMask do
     begin
      Threads[j].PawnTable[i].PawnKey:=0;
      Threads[j].PawnTable[i].ScoreMid:=0;
      Threads[j].PawnTable[i].ScoreEnd:=0;
      Threads[j].PawnTable[i].PassersBB:=0;
      Threads[j].PawnTable[i].WShelter:=0;
      Threads[j].PawnTable[i].BShelter:=0;
      Threads[j].PawnTable[i].WKSq:=0;
      Threads[j].PawnTable[i].BKSq:=0;
      Threads[j].PawnTable[i].WCastle:=0;
      Threads[j].PawnTable[i].BCastle:=0;
     end;
   end;
end;
Function SqDist(king,sq:integer):integer;inline;
begin
  Result:=SquareDist[king,sq];
  If Result>5 then Result:=5;
end;
Function WKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
var
  isHash:boolean;
  new,curr,will:integer;
begin
  isHash:=false;
  // Пробуем секономить время и получить результат из кеша
  if (Threads[ThreadId].PawnTable[PawnIndex].PawnKey=Board.PawnKey) then
    begin
      // В ячейке есть эта конфигурация пешек
      if (Threads[ThreadId].PawnTable[PawnIndex].WKSq=Board.KingSq[white]) and (Threads[ThreadId].PawnTable[PawnIndex].WCastle=(Board.CastleRights and 3))  then
        begin
          // Возвращаем ранее сохраненное значение
          Result:=Threads[ThreadId].PawnTable[PawnIndex].WShelter;
          exit;
        end;
      isHash:=true;
    end;
  // Считаем
   curr:=WKShield(Board.KingSq[white],Board);
   will:=curr;
   if (Board.CastleRights and WhiteShortCastleMask)<>0 then
     begin
       new:=WKShield(g1,Board);
       if new<will then will:=new;
     end;
   if (Board.CastleRights and WhiteLongCastleMask)<>0 then
     begin
       new:=WKShield(c1,Board);
       if new<will then will:=new;
     end;
  result:=(curr+will) div 2;
   // Сохраняем
  if isHash then
     begin
       Threads[ThreadId].PawnTable[PawnIndex].WShelter:=result;
       Threads[ThreadId].PawnTable[PawnIndex].WKSq:=Board.KingSq[white];
       Threads[ThreadId].PawnTable[PawnIndex].WCastle:=(Board.CastleRights and 3);
     end;

end;
Function BKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
var
  isHash:boolean;
  new,curr,will:integer;
begin
  isHash:=false;
  // Пробуем секономить время и получить результат из кеша
  if (Threads[ThreadId].PawnTable[PawnIndex].PawnKey=Board.PawnKey) then
    begin
      // В ячейке есть эта конфигурация пешек
      if (Threads[ThreadId].PawnTable[PawnIndex].BKSq=Board.KingSq[black]) and (Threads[ThreadId].PawnTable[PawnIndex].BCastle=(Board.CastleRights and 12))  then
        begin
          // Возвращаем ранее сохраненное значение
          Result:=Threads[ThreadId].PawnTable[PawnIndex].BShelter;
          exit;
        end;
      isHash:=true;
    end;
  // Считаем
   curr:=BKShield(Board.KingSq[black],Board);
   will:=curr;
   if (Board.CastleRights and BlackShortCastleMask)<>0 then
     begin
       new:=BKShield(g8,Board);
       if new<will then will:=new;
     end;
   if (Board.CastleRights and BlackLongCastleMask)<>0 then
     begin
       new:=BKShield(c8,Board);
       if new<will then will:=new;
     end;
  result:=(curr+will) div 2;
   // Сохраняем
  if isHash then
     begin
       Threads[ThreadId].PawnTable[PawnIndex].BShelter:=result;
       Threads[ThreadId].PawnTable[PawnIndex].BKSq:=Board.KingSq[black];
       Threads[ThreadId].PawnTable[PawnIndex].BCastle:=(Board.CastleRights and 12);
     end;

end;
Function WKShield(king:integer;var Board:TBoard):integer; inline;
var
  Kx,Ky,mid,res,sq,i,d : integer;
  AllPawnsBB,MyPawnsBB,EnemyPawnsBB,temp : TBitBoard;
begin
  // Считаем значение прикрытыя
  res:=0;
  Kx:=Posx[King];Ky:=Posy[King];
  AllPawnsBB:=Board.Pieses[pawn] and (ForwardBB[white,King] or RanksBB[Ky]);
  MyPawnsBB   :=AllPawnsBB and Board.Occupancy[white];
  EnemyPawnsBB:=AllPawnsBB and Board.Occupancy[black];
  mid:=Kx;
  If mid=1 then mid:=2 else
  If mid=8 then mid:=7;
  for i:=mid-1 to mid+1 do
    begin
      If i>4
        then d:=8-i
        else d:=i-1;
      // Считаем дефекты пешечного щита перед королем
      temp:=FilesBB[i] and MyPawnsBB;
      if temp=0
        then res:=res+Shelter[d,1]    // Нет нашей пешки
        else res:=res+Shelter[d,Posy[BitScanForward(temp)]];
      // Считаем пешечный шторм противника
      temp:=FilesBB[i] and EnemyPawnsBB;
      if temp=0
        then res:=res+Storm[d,1]  // Нет вражеской пешки - (полу)открытая линия на короля
        else begin
               sq:=BitScanForward(temp);
               if (Board.Pos[sq-8]=pawn)
                then  res:=res+StormBlocked[d,Posy[sq]]     // Блокирована  нашей пешкой
                else  res:=res+Storm[d,Posy[sq]];           // не заблокирована
             end;
    end;
   if res>MaxShieldPenalty then res:=MaxShieldPenalty;
   If res<0 then res:=0;
   Result:=res;
end;

Function BKShield(king:integer;var Board:TBoard):integer; inline;
var
  Kx,Ky,mid,res,sq,i,d : integer;
  AllPawnsBB,MyPawnsBB,EnemyPawnsBB,temp : TBitBoard;
begin
  // Считаем значение прикрытия
  res:=0;
  Kx:=Posx[king];Ky:=Posy[King];
  AllPawnsBB:=Board.Pieses[pawn] and (ForwardBB[black,King] or RanksBB[Ky]);
  MyPawnsBB   :=AllPawnsBB and Board.Occupancy[black];
  EnemyPawnsBB:=AllPawnsBB and Board.Occupancy[white];
  mid:=Kx;
  If mid=1 then mid:=2 else
  If mid=8 then mid:=7;
  for i:=mid-1 to mid+1 do
    begin
      If i>4
        then d:=8-i
        else d:=i-1;
      // Считаем дефекты пешечного щита перед королем
      temp:=FilesBB[i] and MyPawnsBB;
      if temp=0
        then res:=res+Shelter[d,1]    // Нет нашей пешки
        else res:=res+Shelter[d,9-Posy[BitScanBackward(temp)]];
      // Считаем пешечный шторм противника
      temp:=FilesBB[i] and EnemyPawnsBB;
      if temp=0
        then res:=res+Storm[d,1]  // Нет вражеской пешки - (полу)открытая линия на короля
        else begin
               sq:=BitScanBackward(temp);
               if (Board.Pos[sq+8]=-pawn)
                 then res:=res+StormBlocked[d,9-Posy[sq]]    // Блокирована  нашей пешкой
                 else res:=res+Storm[d,9-Posy[sq]]
             end;
    end;
  if res>MaxShieldPenalty then res:=MaxShieldPenalty;
  If res<0 then res:=0;
  Result:=res;
end;
Function EvaluatePawns(var Board:TBoard;ThreadId:integer):int64;inline;
// Оценка пешек на доске. Возвращает индекс на ячейку с посчитанными и сохраненными значениями.
var
  ScoreMid,ScoreEnd,sq,x,y : integer;
  temp,PassersBB,WhitePawnsBB,BlackPawnsBB,AllPawnsBB,SupportedBB,StoppersBB,NeighborsBB,LeverBB,LeverPushBB,BlockedBB,PhalanxBB,WSpan,BSpan : TBitBoard;
  doubled,opened,backward,passed,blocked,supported,phalanx,connected,isolated : boolean;
  cnt : integer;
begin
  result:=Board.PawnKey and Threads[ThreadId].PawnTableMask;
  // Проверяем не считали ли мы это соотношение материала ранее?
  If  (Board.PawnKey=Threads[ThreadId].Pawntable[result].PawnKey) then exit;
  ScoreMid:=0;ScoreEnd:=0; PassersBB:=0;
  AllPawnsBB:=Board.Pieses[pawn];
  WhitePawnsBB:=AllPawnsBB and Board.Occupancy[white];
  BlackPawnsBB:=AllPawnsBB and Board.Occupancy[black];
  WSpan:=((WhitePawnsBB and (not FilesBB[1])) shl 7) or ((WhitePawnsBB and (not FilesBB[8])) shl 9);
  BSpan:=((BlackPawnsBB and (not FilesBB[1])) shr 9) or ((BlackPawnsBB and (not FilesBB[8])) shr 7);
  // Белые
  temp:=WhitePawnsBB;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=posx[sq];y:=posy[sq];
      // Считаем статусы каждой пешки по очереди
      NeighborsBB:=(WhitePawnsBB and IsolatedBB[sq]);
      isolated:=(NeighborsBB=0);
      StoppersBB:=(BlackPawnsBB and PasserBB[white,sq]);
      BlockedBB:=(BlackPawnsBB and Only[sq+8]);
      blocked:=(BlockedBB<>0);
      doubled  :=(WhitePawnsBB and Only[sq-8])<>0;
      opened   :=(BlackPawnsBB and ForwardBB[white,sq] and FilesBB[x])=0;
      leverBB  :=(BlackPawnsBB and PawnAttacks[white,sq]);
      leverPushBB :=(BlackPawnsBB and PawnAttacks[white,sq+8]);
      PhalanxBB:=(WhitePawnsBB and PawnAttacks[black,sq+8]);
      phalanx  :=PhalanxBB<>0;
      supportedBB:=WhitePawnsBB and PawnAttacks[black,sq];
      supported:=(SupportedBB<>0);
      connected:=supported or phalanx;
       // Проверяем пешку на отсталость
      backward:=((NeighborsBB and ForwardBB[black,sq+8])=0) and ((LeverPushBB or BlockedBB)<>0);
      if (not backward) and (not blocked) then WSpan:=WSpan or (IsolatedBB[sq] and ForwardBB[white,sq]);
      passed:=((StoppersBB and (not LeverBB))=0) or (((StoppersBB and (not LeverPushBB))=0) and (Bitcount(PhalanxBB)>=BitCount(LeverPushBB)));
      if (passed) and  ((WhitePawnsBB and FilesBB[x] and ForwardBB[white,sq])<>0) then passed:=false;
         // Оцениваем пешку:
      if passed  then PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции
       if Connected then
        begin
          cnt:=BitCount(SupportedBB);
          ScoreMid:=ScoreMid+ConnectedMid[y,opened,phalanx,cnt];
          ScoreEnd:=ScoreEnd+ConnectedEnd[y,opened,phalanx,cnt];
        end else
      if isolated then
        begin
          if (not opened) and ((WhitePawnsBB and FilesBB[x] and ForwardBB[black,sq])<>0) and ((BlackPawnsBB and IsolatedBB[sq])=0) then
            begin
             ScoreMid:=ScoreMid-DoubledMid;
             ScoreEnd:=ScoreEnd-DoubledEnd;
            end else
          begin
           if opened then
            begin
              ScoreMid:=ScoreMid-IsolatedOpenMid;
              ScoreEnd:=ScoreEnd-IsolatedOpenEnd;
            end else
            begin
              ScoreMid:=ScoreMid-IsolatedClosedMid;
              ScoreEnd:=ScoreEnd-IsolatedClosedEnd;
            end;
          end;
        end else
      if backward then
        begin
          if opened then
            begin
              ScoreMid:=ScoreMid-BackWardOpenMid;
              ScoreEnd:=ScoreEnd-BackWardOpenEnd;
            end else
            begin
              ScoreMid:=ScoreMid-BackWardClosedMid;
              ScoreEnd:=ScoreEnd-BackWardClosedEnd;
            end;
        end;
      If (doubled)   then
            begin
             ScoreMid:=ScoreMid-DoubledMid;
             ScoreEnd:=ScoreEnd-DoubledEnd;
            end;
      temp:=temp and (temp-1);
    end;
  // Черные
  temp:=BlackPawnsBB;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=posx[sq];y:=posy[sq];
      // Считаем статусы каждой пешки по очереди
      NeighborsBB:=(BlackPawnsBB and IsolatedBB[sq]);
      isolated:=(NeighborsBB=0);
      StoppersBB:=(WhitePawnsBB and PasserBB[black,sq]);
      BlockedBB:=(WhitePawnsBB and Only[sq-8]);
      blocked:=(BlockedBB<>0);
      doubled  :=(BlackPawnsBB and Only[sq+8])<>0;
      opened   :=(WhitePawnsBB and ForwardBB[black,sq] and FilesBB[x])=0;
      leverBB  :=(WhitePawnsBB and PawnAttacks[black,sq]);
      leverPushBB :=(WhitePawnsBB and PawnAttacks[black,sq-8]);
      PhalanxBB :=(BlackPawnsBB and PawnAttacks[white,sq-8]);
      phalanx  :=PhalanxBB<>0;
      supportedBB:=BlackPawnsBB and PawnAttacks[white,sq];
      supported:=(SupportedBB<>0);
      connected:=supported or phalanx;
       // Проверяем пешку на отсталость
      backward:=((NeighborsBB and ForwardBB[white,sq-8])=0) and ((LeverPushBB or BlockedBB)<>0);
      if (not backward) and (not blocked) then BSpan:=BSpan or (IsolatedBB[sq] and ForwardBB[black,sq]);
      passed:=((StoppersBB and (not LeverBB))=0) or (((StoppersBB and (not LeverPushBB))=0) and (Bitcount(PhalanxBB)>=BitCount(LeverPushBB)));
      if (passed) and ((BlackPawnsBB and FilesBB[x] and ForwardBB[black,sq])<>0) then passed:=false;
         // Оцениваем пешку:
      if passed  then PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции

      if Connected then
        begin
          cnt:=BitCount(SupportedBB);
          ScoreMid:=ScoreMid-ConnectedMid[9-y,opened,phalanx,cnt];
          ScoreEnd:=ScoreEnd-ConnectedEnd[9-y,opened,phalanx,cnt];
        end else
       if isolated then
        begin
          if (not opened) and ((BlackPawnsBB and FilesBB[x] and ForwardBB[white,sq])<>0) and ((WhitePawnsBB and IsolatedBB[sq])=0) then
            begin
             ScoreMid:=ScoreMid+DoubledMid;
             ScoreEnd:=ScoreEnd+DoubledEnd;
            end else
          begin
          if opened then
            begin
              ScoreMid:=ScoreMid+IsolatedOpenMid;
              ScoreEnd:=ScoreEnd+IsolatedOpenEnd;
            end else
            begin
              ScoreMid:=ScoreMid+IsolatedClosedMid;
              ScoreEnd:=ScoreEnd+IsolatedClosedEnd;
            end;
          end;
        end else
      if backward then
        begin
          if opened then
            begin
              ScoreMid:=ScoreMid+BackWardOpenMid;
              ScoreEnd:=ScoreEnd+BackWardOpenEnd;
            end else
            begin
              ScoreMid:=ScoreMid+BackWardClosedMid;
              ScoreEnd:=ScoreEnd+BackWardClosedEnd;
            end;
        end;
      If (doubled)  then
            begin
             ScoreMid:=ScoreMid+DoubledMid;
             ScoreEnd:=ScoreEnd+DoubledEnd;
            end;
      temp:=temp and (temp-1);
    end;
  // Сохраняем в хеш
  Threads[ThreadId].PawnTable[result].PawnKey:=Board.PawnKey;
  Threads[ThreadId].PawnTable[result].ScoreMid:=ScoreMid;
  Threads[ThreadId].PawnTable[result].ScoreEnd:=ScoreEnd;
  Threads[ThreadId].PawnTable[result].PassersBB:=PassersBB;
  Threads[ThreadId].PawnTable[result].WSpan:=WSpan;
  Threads[ThreadId].PawnTable[result].BSpan:=BSpan;
  Threads[ThreadId].PawnTable[result].WKSq:=NonSq;
  Threads[ThreadId].PawnTable[result].BKSq:=NonSq;
  Threads[ThreadId].PawnTable[result].WCastle:=255;
  Threads[ThreadId].PawnTable[result].BCastle:=255;
end;

Procedure EvaluatePassers(var TotalMid:integer;var TotalEnd:integer;PassersBB:TBitBoard;var Board:TBoard;WAtt:TBitBoard;BAtt:TBitBoard);inline;
var
  sq,x,y,Passmid,Passend,ind : integer;
  temp,Way,Att,Back : TBitBoard;
begin
  TotalMid:=0;
  TotalEnd:=0;
  // белые
  Temp:=PassersBB and Board.Occupancy[white];
  While Temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
      PassMid:=PasserBaseMid[y];
      PassEnd:=PasserBaseEnd[y];
      if (y>3) then  // Для продвинутых проходных дополнительная эндшпильная оценка
        begin
         // Удаленность королей от поля перед проходной
         PassEnd:=PassEnd+SqDist(sq+8,Board.KingSq[black])*WeakKingDist[y];
         PassEnd:=PassEnd-SqDist(sq+8,Board.KingSq[white])*StrongKingDist1[y];
         if (y<7) then PassEnd:=PassEnd-SqDist(sq+16,Board.KingSq[white])*StrongKingDist2[y];
         // Поддержка проходной
         if Board.Pos[sq+8]=Empty then
           begin
             Way:= (ForwardBB[white,sq] and FilesBB[x]);
             Back:=(ForwardBB[black,sq] and FilesBB[x] and (Board.Pieses[queen] or Board.Pieses[rook]));
             Att := PasserBB[white,sq];
             if (Back and Board.Occupancy[black])=0 then Att:=Att and BAtt;
             If  Att=0 then ind:=35 else
             if (Att and Way)=0 then ind:=20 else
             if (Att and Only[sq+8])=0 then ind:=9
                                       else ind:=0;
             if ((Back and Board.Occupancy[white])<>0) or ((Watt and Only[sq+8])<>0) then ind:=ind+5;
             PassMid:=PassMid+ind*PasserBonus[y];
             PassEnd:=PassEnd+ind*PasserBonus[y];
           end;
        end;
      TotalMid:=TotalMid+PassMid;
      TotalEnd:=TotalEnd+PassEnd;
      temp:=temp and (temp-1);
    end;
  // черные
  Temp:=PassersBB and Board.Occupancy[black];
  While Temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
      PassMid:=PasserBaseMid[9-y];
      PassEnd:=PasserBaseEnd[9-y];
      if (y<6) then  // Для продвинутых проходных дополнительная эндшпильная оценка
        begin
         // Удаленность королей от поля перед проходной
         PassEnd:=PassEnd+SqDist(sq-8,Board.KingSq[white])*WeakKingDist[9-y];
         PassEnd:=PassEnd-SqDist(sq-8,Board.KingSq[black])*StrongKingDist1[9-y];
         if (y>2) then PassEnd:=PassEnd-SqDist(sq-16,Board.KingSq[black])*StrongKingDist2[9-y];
         // Поддержка проходной
         if Board.Pos[sq-8]=Empty then
           begin
             Way:= (ForwardBB[black,sq] and FilesBB[x]);
             Back:=(ForwardBB[white,sq] and FilesBB[x] and (Board.Pieses[queen] or Board.Pieses[rook]));
             Att := PasserBB[black,sq];
             if ((Back and Board.Occupancy[white])=0) then Att:=Att and WAtt;
             If  Att=0 then ind:=35 else
             if (Att and Way)=0 then ind:=20 else
             if (Att and Only[sq-8])=0 then ind:=9
                                       else ind:=0;
             if ((Back and Board.Occupancy[black])<>0) or ((Batt and Only[sq-8])<>0) then ind:=ind+5;
             PassMid:=PassMid+ind*PasserBonus[9-y];
             PassEnd:=PassEnd+ind*PasserBonus[9-y];
           end;
        end;
      TotalMid:=TotalMid-PassMid;
      TotalEnd:=TotalEnd-PassEnd;
      temp:=temp and (temp-1);
    end;
end;

Procedure PawnEvalInit;
var
  base,y,cnt,prot : integer;
  open,phalanx : boolean;
begin
  For y:=2 to 7 do
  for open:=false to true do
  for phalanx:=false to true do
  for prot:=0 to 2 do
    begin
      cnt:=2;
      if phalanx then inc(cnt);
      if (not open) then dec(cnt);
      base:=ConnectedBase[y]*cnt+prot*PawnSupported;
      ConnectedMid[y,open,phalanx,prot]:=base;
      ConnectedEnd[y,open,phalanx,prot]:=(base*(y-2)) div 4;
    end;

end;
initialization
PawnEvalInit;

end.
