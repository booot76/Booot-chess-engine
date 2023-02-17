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
               end;
Const
  IsolatedClosedMid =12;
  IsolatedClosedEnd =11;
  IsolatedOpenMid   =18;
  IsolatedOpenEnd   =16;

  BackWardClosedMid = 16;
  BackWardClosedEnd =  8;
  BackWardOpenMid   = 22;
  BackWardopenEnd   = 13;

  DoubledMid = 7;
  DoubledEnd =15;


  LeverMid   : array[1..8] of integer=(0,0,0,0,6,13,0,0);
  LeverEnd   : array[1..8] of integer=(0,0,0,0,6,13,0,0);

  ConnectedBase : array[1..8] of integer =(0,2,6,6,20,32,64,128);

  Shelter         : array[0..3,1..8] of integer =(
    (30,5, 0,10,15,25,25,25),
    (45,0, 5,25,35,45,45,45),
    (35,0,15,20,30,35,35,35),
    (35,5,10,20,30,35,35,35)
  );

  Storm          : array[0..3,1..8] of integer =(
    ( 5,-80, 0,15,5,0,0,0),
    ( 5,-10,80,10,0,0,0,0),
    ( 5, 40,80,20,0,0,0,0),
    ( 5, 25,50,15,5,0,0,0)
  );
  StormBlocked          : array[0..3,1..8] of integer =(
    ( 0,0,35, 0,0,0,0,0),
    ( 0,0,45, 0,0,0,0,0),
    ( 0,0,35, 0,0,0,0,0),
    ( 0,0,30, 0,0,0,0,0)
  );

  MaxShieldPenalty=255;
  PasserBaseMid : array[1..8] of Integer = (0,2,2,12,30,65,100,0);
  PasserBaseEnd : array[1..8] of Integer = (0,3,6,15,30,65,100,0);

  PasserFreeWay : array[1..8] of Integer = (0,0,0,15,45,90,150,0);
  PasserFreePush: array[1..8] of Integer = (0,0,0, 7,21,42, 70,0);
  PasserSuppWay : array[1..8] of Integer = (0,0,0, 5,15,30, 50,0);
  PasserSuppPush: array[1..8] of Integer = (0,0,0, 3, 9,18, 30,0);
  PasSelfBlocked: array[1..8] of Integer = (0,0,1, 2, 5, 8, 12,0);
  WeakKingDist     : array[1..8] of integer = (0,0,0,4,12,24,40,0);
  StrongKingDist1  : array[1..8] of integer = (0,0,0,2, 5,10,16,0);
  StrongKingDist2  : array[1..8] of integer = (0,0,0,1, 2, 5, 8,0);

  UnStopable=10;
var
   ConnectedMid,ConnectedEnd : array[2..7,False..True,False..True,False..True] of integer;

Procedure InitPawnTable(SizeMB:integer);
Function EvaluatePawns(var Board:TBoard;ThreadId:integer):int64;inline;
Function WKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
Function BKingSafety(PawnIndex:int64;var Board:TBoard;ThreadId:integer):integer;inline;
Function WKShield(king:integer;var Board:TBoard):integer; inline;
Function BKShield(king:integer;var Board:TBoard):integer; inline;
Procedure EvaluatePassers(var PassMid:integer;var PassEnd:integer;PassersBB:TBitBoard;var Board:TBoard;WAtt:TBitBoard;BAtt:TBitBoard);inline;

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
  ScoreMid,ScoreEnd,sq,x,y,sq1,y1,sq2 : integer;
  temp,PassersBB,WhitePawnsBB,BlackPawnsBB,AllPawnsBB,BB,SupportedBB,Stoppers,Neighbors : TBitBoard;
  isolated,doubled,opened,backward,passed,supported,phalanx,connected,lever,ssup : boolean;
begin
  result:=Board.PawnKey and Threads[ThreadId].PawnTableMask;
  // Проверяем не считали ли мы это соотношение материала ранее?
  If  (Board.PawnKey=Threads[ThreadId].Pawntable[result].PawnKey) then exit;
  ScoreMid:=0;ScoreEnd:=0; PassersBB:=0;
  AllPawnsBB:=Board.Pieses[pawn];
  WhitePawnsBB:=AllPawnsBB and Board.Occupancy[white];
  BlackPawnsBB:=AllPawnsBB and Board.Occupancy[black];
  // Белые
  temp:=WhitePawnsBB;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=posx[sq];y:=posy[sq];
      // Считаем статусы каждой пешки по очереди
      Neighbors:=(WhitePawnsBB and IsolatedBB[sq]);
      Stoppers:=(BlackPawnsBB and PasserBB[white,sq]);
      isolated :=(neighbors=0);
      doubled  :=(WhitePawnsBB and ForwardBB[white,sq] and FilesBB[x])<>0;
      opened   :=(BlackPawnsBB and ForwardBB[white,sq] and FilesBB[x])=0;
      passed   :=(Stoppers=0);
      lever    :=(BlackPawnsBB and PawnAttacks[white,sq])<>0;
      phalanx  :=(WhitePawnsBB and PawnAttacks[black,sq+8])<>0;
      supportedBB:=WhitePawnsBB and PawnAttacks[black,sq];
      supported:=(SupportedBB<>0);
      ssup:=(SupportedBB and (SupportedBB-1))<>0;
      connected:=supported or phalanx;
       // Проверяем пешку на отсталость
      if (isolated) or (lever) or (y>4)  or ((Neighbors and ForwardBB[black,sq+8])<>0)  then backward:=false else
         begin
           // ищем пешку любого цвета впереди на соседних вертикалях с данной
           BB:=IsolatedBB[sq] and ForwardBB[white,sq] and AllPawnsBB;
           sq1:=BitScanForward(BB);
           y1:=Posy[sq1];
           // Если путь к этой пешке блокирован другой пешкой - данная пешка отсталая!
           sq2:=sq+(y1-y+1)*8;
           if (InterSect[sq,sq2] and AllPawnsBB)<>0
             then backward:=true   // Если не блокирована, но ближайшая пешка - вражеская или путь к ближайшей своей атакован вражеской, то тоже отсталая
             else backward:=((RanksBB[y1] or RanksBB[y1+1]) and BB and BlackPawnsBB)<>0;
         end;
         // Оцениваем пешку:
      if passed and (not doubled) then
       begin
        PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции
        ScoreMid:=ScoreMid+PasserBaseMid[y];
        ScoreEnd:=ScoreEnd+PasserBaseEnd[y];
       end;
      if doubled then
        begin
          sq2:=BitScanBackWard(WhitePawnsBB and ForwardBB[white,sq] and FilesBB[x]);
          ScoreMid:=ScoreMid-(DoubledMid div SquareDist[sq,sq2]);
          ScoreEnd:=ScoreEnd-(DoubledEnd div SquareDist[sq,sq2]);
        end;
      if lever then
        begin
          ScoreMid:=ScoreMid+LeverMid[y];
          ScoreEnd:=ScoreEnd+LeverEnd[y];
        end;
      if isolated then
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
      if Connected then
        begin
          ScoreMid:=ScoreMid+ConnectedMid[y,opened,phalanx,ssup];
          ScoreEnd:=ScoreEnd+ConnectedEnd[y,opened,phalanx,ssup];
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
      Neighbors:=(BlackPawnsBB and IsolatedBB[sq]);
      Stoppers:=(WhitePawnsBB and PasserBB[black,sq]);
      isolated :=(neighbors=0);
      doubled  :=(BlackPawnsBB and ForwardBB[black,sq] and FilesBB[x])<>0;
      opened   :=(WhitePawnsBB and ForwardBB[black,sq] and FilesBB[x])=0;
      passed   :=(Stoppers=0);
      lever    :=(WhitePawnsBB and PawnAttacks[black,sq])<>0;
      phalanx  :=(BlackPawnsBB and PawnAttacks[white,sq-8])<>0;
      supportedBB:=BlackPawnsBB and PawnAttacks[white,sq];
      supported:=(SupportedBB<>0);
      ssup:=(SupportedBB and (SupportedBB-1))<>0;
      connected:=supported or phalanx;
       // Проверяем пешку на отсталость
      if (isolated) or (lever) or (y<5)  or ((Neighbors and ForwardBB[white,sq-8])<>0)   then backward:=false else
         begin
           // ищем пешку любого цвета впереди на соседних вертикалях с данной
           BB:=IsolatedBB[sq] and ForwardBB[black,sq] and AllPawnsBB;
           sq1:=BitScanBackward(BB);
           y1:=Posy[sq1];
           // Если путь к этой пешке блокирован другой пешкой - данная пешка отсталая!
           sq2:=sq-(y-y1+1)*8;
           if (InterSect[sq,sq2] and AllPawnsBB)<>0
             then backward:=true  // Если не блокирована, но ближайшая пешка - вражеская или путь к ближайшей своей атакован вражеской, то тоже отсталая
             else backward:=((RanksBB[y1] or RanksBB[y1-1]) and BB and WhitePawnsBB)<>0;
         end;
         // Оцениваем пешку:
      if passed and (not doubled) then
       begin
        PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции
        ScoreMid:=ScoreMid-PasserBaseMid[9-y];
        ScoreEnd:=ScoreEnd-PasserBaseEnd[9-y];
       end;
      if doubled then
        begin
          sq2:=BitScanForWard(BlackPawnsBB and ForwardBB[black,sq] and FilesBB[x]);
          ScoreMid:=ScoreMid+(DoubledMid div SquareDist[sq,sq2]);
          ScoreEnd:=ScoreEnd+(DoubledEnd div SquareDist[sq,sq2]);
        end;
      if lever then
        begin
          ScoreMid:=ScoreMid-LeverMid[9-y];
          ScoreEnd:=ScoreEnd-LeverEnd[9-y];
        end;
      if isolated then
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
      if Connected then
        begin
          ScoreMid:=ScoreMid-ConnectedMid[9-y,opened,phalanx,ssup];
          ScoreEnd:=ScoreEnd-ConnectedEnd[9-y,opened,phalanx,ssup];
        end;
      temp:=temp and (temp-1);
    end;
  // Сохраняем в хеш
  Threads[ThreadId].PawnTable[result].PawnKey:=Board.PawnKey;
  Threads[ThreadId].PawnTable[result].ScoreMid:=ScoreMid;
  Threads[ThreadId].PawnTable[result].ScoreEnd:=ScoreEnd;
  Threads[ThreadId].PawnTable[result].PassersBB:=PassersBB;
  Threads[ThreadId].PawnTable[result].WKSq:=NonSq;
  Threads[ThreadId].PawnTable[result].BKSq:=NonSq;
  Threads[ThreadId].PawnTable[result].WCastle:=255;
  Threads[ThreadId].PawnTable[result].BCastle:=255;
end;

Procedure EvaluatePassers(var PassMid:integer;var PassEnd:integer;PassersBB:TBitBoard;var Board:TBoard;WAtt:TBitBoard;BAtt:TBitBoard);inline;
var
  sq,x,y : integer;
  temp,Way,Att,Def,Back,QR : TBitBoard;
begin
  PassMid:=0;
  PassEnd:=0;
  // белые
  Temp:=PassersBB and Board.Occupancy[white];
  While Temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
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
             Back:=(ForwardBB[black,sq] and FilesBB[x]);
             QR:=Back and (Board.Pieses[rook] or Board.Pieses[queen]) and (RookAttacksBB(sq,Board.AllPieses));
             if (QR and Board.Occupancy[white])<>0
               then Att:=Way
               else Att:=Watt and Way;
             if (QR and Board.Occupancy[black])<>0
               then Def:=Way
               else Def:=Way and (BAtt or Board.Occupancy[black]);
             // Если путь не защищен противником
             if Def=0 then
               begin
                 PassMid:=PassMid+PasserFreeWay[y];
                 PassEnd:=PassEnd+PasserFreeWay[y];
               end else
             if (Def and Only[sq+8])=0 then
               begin
                 PassMid:=PassMid+PasserFreePush[y];
                 PassEnd:=PassEnd+PasserFreePush[y];
               end;
             // Если пешка поддержана своими фигурами
             if Att=Way then
               begin
                 PassMid:=PassMid+PasserSuppWay[y];
                 PassEnd:=PassEnd+PasserSuppWay[y];
               end else
             if (Att and Only[sq+8])<>0 then
               begin
                 PassMid:=PassMid+PasserSuppPush[y];
                 PassEnd:=PassEnd+PasserSuppPush[y];
               end;
           end else If Board.Pos[sq+8]>Empty then
             begin
               PassMid:=PassMid+PasSelfBlocked[y];
               PassEnd:=PassEnd+PasSelfBlocked[y];
             end;
        end;
      temp:=temp and (temp-1);
    end;
  // черные
  Temp:=PassersBB and Board.Occupancy[black];
  While Temp<>0 do
    begin
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
      if (y<6) then  // Для продвинутых проходных дополнительная эндшпильная оценка
        begin
         // Удаленность королей от поля перед проходной
         PassEnd:=PassEnd-SqDist(sq-8,Board.KingSq[white])*WeakKingDist[9-y];
         PassEnd:=PassEnd+SqDist(sq-8,Board.KingSq[black])*StrongKingDist1[9-y];
         if (y>2) then PassEnd:=PassEnd+SqDist(sq-16,Board.KingSq[black])*StrongKingDist2[9-y];
         // Поддержка проходной
         if Board.Pos[sq-8]=Empty then
           begin
             Way:= (ForwardBB[black,sq] and FilesBB[x]);
             Back:=(ForwardBB[white,sq] and FilesBB[x]);
             QR:=Back and (Board.Pieses[rook] or Board.Pieses[queen]) and (RookAttacksBB(sq,Board.AllPieses));
             if (QR and Board.Occupancy[black])<>0
               then Att:=Way
               else Att:=Batt and Way;
             if (QR and Board.Occupancy[white])<>0
               then Def:=Way
               else Def:=Way and (WAtt or Board.Occupancy[white]);
             // Если путь не защищен противником
             if Def=0 then
               begin
                 PassMid:=PassMid-PasserFreeWay[9-y];
                 PassEnd:=PassEnd-PasserFreeWay[9-y];
               end else
             if (Def and Only[sq-8])=0 then
               begin
                 PassMid:=PassMid-PasserFreePush[9-y];
                 PassEnd:=PassEnd-PasserFreePush[9-y];
               end;
             // Если пешка поддержана своими фигурами
             if Att=Way then
               begin
                 PassMid:=PassMid-PasserSuppWay[9-y];
                 PassEnd:=PassEnd-PasserSuppWay[9-y];
               end else
             if (Att and Only[sq-8])<>0 then
               begin
                 PassMid:=PassMid-PasserSuppPush[9-y];
                 PassEnd:=PassEnd-PasserSuppPush[9-y];
               end;
           end else If Board.Pos[sq-8]<Empty then
             begin
               PassMid:=PassMid-PasSelfBlocked[9-y];
               PassEnd:=PassEnd-PasSelfBlocked[9-y];
             end;
        end;
      temp:=temp and (temp-1);
    end;
  // Пешечный эндшпиль
  If (Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=0) then
    begin
      Temp:=PassersBB and Board.Occupancy[white];
      if temp<>0  then
        begin
          sq:=BitScanBackward(temp);
          y:=posy[sq];
          PassEnd:=PassEnd+Unstopable*y;
        end;
      Temp:=PassersBB and Board.Occupancy[black];
      if temp<>0  then
        begin
          sq:=BitScanForward(temp);
          y:=9-posy[sq];
          PassEnd:=PassEnd-Unstopable*y;
        end;
    end;
end;

Procedure PawnEvalInit;
var
  base,y : integer;
  open,phalanx,prot : boolean;
begin
  For y:=2 to 7 do
  for open:=false to true do
  for phalanx:=false to true do
  for prot:=false to true do
    begin
      base:=ConnectedBase[y];
      if phalanx then base:=base+((ConnectedBase[y+1]-ConnectedBase[y]) div 2);
      if (not open) then base:=base div 2;
      if prot then base:=base + (base div 2);
      ConnectedMid[y,open,phalanx,prot]:=base;
      ConnectedEnd[y,open,phalanx,prot]:=(base*(y-2)) div 4;
    end;
end;
initialization
PawnEvalInit;

end.
