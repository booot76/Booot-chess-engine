unit uPawn;

interface
 uses uBoard,uBitBoards,uthread,uAttacks,uMagic;

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
                 BPawn        : smallint;
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

  WeakMid=5;
  WeakEnd=3;

  LeverMid   : array[1..8] of integer=(0,0,0,0,6,13,0,0);
  LeverEnd   : array[1..8] of integer=(0,0,0,0,6,13,0,0);

  ConnectedBase : array[1..8] of integer =(0,1,2,4,16,32,64,128);

  ShelterMiddle   : array[1..8] of integer=(55,0,15,40,50,55,55,55);
  ShelterEdge     : array[1..8] of integer=(30,0, 5,15,20,25,25,25);
  ShelterCenter   : array[1..8] of integer=(30,0,10,20,25,30,30,30);

  StormMiddle       : array[1..8] of integer=(10,0,35,20,10,0,0,0);
  StormCenter       : array[1..8] of integer=(10,0,35,20,10,0,0,0);
  StormEdge         : array[1..8] of integer=( 5,0,30,15, 5,0,0,0);

  MaxShieldPenalty=255;

  PasserBaseMid : array[1..8] of Integer = (0,0,0,13,36,85,125,0);
  PasserBaseEnd : array[1..8] of Integer = (0,2,5,15,25,50, 75,0);

  PasserFreeWay : array[1..8] of Integer = (0,0,0,12,36,72,120,0);
  PasserFreePush: array[1..8] of Integer = (0,0,0, 6,18,36, 60,0);
  PasserSuppWay : array[1..8] of Integer = (0,0,0, 6,18,36, 60,0);
  PasserSuppPush: array[1..8] of Integer = (0,0,0, 3, 9,18, 30,0);
  PasSelfBlocked: array[1..8] of Integer = (0,0,1, 2, 5, 8, 12,0);
  WeakKingDist     : array[1..8] of integer = (0,0,0,4,12,24,40,0);
  StrongKingDist1  : array[1..8] of integer = (0,0,0,2, 5,10,20,0);
  StrongKingDist2  : array[1..8] of integer = (0,0,0,1, 2, 5,10,0);

  UnStopable=10;
var
   PawnTable : array of TPawnEntry;
   PawnTableMask : int64;
   ConnectedMid,ConnectedEnd : array[2..7,False..True,False..True,False..True] of integer;

Procedure InitPawnTable(SizeMB:integer);
Function EvaluatePawns(var Board:TBoard):cardinal;inline;
Function WKingSafety(PawnIndex:Cardinal;var Board:TBoard):integer;inline;
Function BKingSafety(PawnIndex:Cardinal;var Board:TBoard):integer;inline;
Function WKShield(king:integer;var Board:TBoard):integer; inline;
Function BKShield(king:integer;var Board:TBoard):integer; inline;
Procedure EvaluatePassers(var PassMid:integer;var PassEnd:integer;PassersBB:TBitBoard;var Board:TBoard;WAtt:TBitBoard;BAtt:TBitBoard);inline;

implementation

Procedure InitPawnTable(SizeMB:integer);
// На входе - ОБЩЕЕ количество мегабайт кеша, полученного от оболочки
var
   i,PawnTableSize : int64;
begin
  PawnTableSize:=SizeMb;
  PawnTableSize:=(PawnTableSize * 1024 * 1024) div (32*32);  {1/32 доля хеша. Размер ячейки берем 32 }
  PawnTableMask:=PawnTableSize-1;
  SetLength(PawnTable,0);
  SetLength(PawnTable,PawnTableMask);
  for i:=0 to PawnTableMask do
    begin
      PawnTable[i].PawnKey:=0;
      PawnTable[i].ScoreMid:=0;
      PawnTable[i].ScoreEnd:=0;
      PawnTable[i].PassersBB:=0;
      PawnTable[i].WShelter:=0;
      PawnTable[i].BShelter:=0;
      PawnTable[i].WKSq:=0;
      PawnTable[i].BKSq:=0;
      PawnTable[i].WCastle:=0;
      PawnTable[i].BCastle:=0;
      PawnTable[i].BPawn:=0;
    end;
end;

Function WKingSafety(PawnIndex:Cardinal;var Board:TBoard):integer;inline;
var
  isHash:boolean;
  new,curr,will:integer;
begin
  isHash:=false;
  // Пробуем секономить время и получить результат из кеша
  if (PawnTable[PawnIndex].PawnKey=Board.PawnKey) then
    begin
      // В ячейке есть эта конфигурация пешек
      if (PawnTable[PawnIndex].WKSq=Board.KingSq[white]) and (PawnTable[PawnIndex].WCastle=(Board.CastleRights and 3))  then
        begin
          // Возвращаем ранее сохраненное значение
          Result:=PawnTable[PawnIndex].WShelter;
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
       PawnTable[PawnIndex].WShelter:=result;
       PawnTable[PawnIndex].WKSq:=Board.KingSq[white];
       PawnTable[PawnIndex].WCastle:=(Board.CastleRights and 3);
     end;

end;
Function BKingSafety(PawnIndex:Cardinal;var Board:TBoard):integer;inline;
var
  isHash:boolean;
  new,curr,will:integer;
begin
  isHash:=false;
  // Пробуем секономить время и получить результат из кеша
  if (PawnTable[PawnIndex].PawnKey=Board.PawnKey) then
    begin
      // В ячейке есть эта конфигурация пешек
      if (PawnTable[PawnIndex].BKSq=Board.KingSq[black]) and (PawnTable[PawnIndex].BCastle=(Board.CastleRights and 12))  then
        begin
          // Возвращаем ранее сохраненное значение
          Result:=PawnTable[PawnIndex].BShelter;
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
       PawnTable[PawnIndex].BShelter:=result;
       PawnTable[PawnIndex].BKSq:=Board.KingSq[black];
       PawnTable[PawnIndex].BCastle:=(Board.CastleRights and 12);
     end;

end;
Function WKShield(king:integer;var Board:TBoard):integer; inline;
var
  Kx,Ky,mid,cen,edg,res,base,sq : integer;
  AllPawnsBB,MyPawnsBB,EnemyPawnsBB,temp : TBitBoard;
begin
  // Считаем значение прикрытыя
  res:=0;
  Kx:=Posx[King];Ky:=Posy[King];
  AllPawnsBB:=Board.Pieses[pawn] and (ForwardBB[white,King] or RanksBB[Ky]);
  MyPawnsBB   :=AllPawnsBB and Board.Occupancy[white];
  EnemyPawnsBB:=AllPawnsBB and Board.Occupancy[black];
  if Kx=1 then
    begin
      mid:=2;
      cen:=3;
      edg:=1;
    end else
  if Kx=8 then
    begin
      mid:=7;
      cen:=6;
      edg:=8;
    end else
    begin
      mid:=Kx;
      if Mid>4 then
        begin
          edg:=mid+1;
          cen:=mid-1;
        end else
        begin
          edg:=mid-1;
          cen:=mid+1;
        end;
    end;
                    //центр
  // Считаем дефекты пешечного щита перед королем
  temp:=FilesBB[mid] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterMiddle[1]    // Нет нашей пешки
    else res:=res+ShelterMiddle[Posy[BitScanForward(temp)]];
 // Считаем пешечный шторм противника
  temp:=FilesBB[mid] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormMiddle[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanForward(temp);
           base:=StormMiddle[Posy[sq]];
           if (Board.Pos[sq-8]=pawn) then base:=(base*2) div 3;     // Блокирована нашей пешкой
           res:=res+base;
         end;
                  // крайняя
  temp:=FilesBB[edg] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterEdge[1]    // Нет нашей пешки
    else res:=res+ShelterEdge[Posy[BitScanForward(temp)]];
 // Считаем пешечный шторм противника
  temp:=FilesBB[edg] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormEdge[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanForward(temp);
           base:=StormEdge[Posy[sq]];
           if (Board.Pos[sq-8]=pawn) then base:=(base*2) div 3;     // Блокирована  нашей пешкой
           res:=res+base;
         end;
                  // к центру доски
  temp:=FilesBB[cen] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterCenter[1]   // Нет нашей пешки
    else res:=res+ShelterCenter[Posy[BitScanForward(temp)]];

 // Считаем пешечный шторм противника
  temp:=FilesBB[cen] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormCenter[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanForward(temp);
           base:=StormCenter[Posy[sq]];
           if (Board.Pos[sq-8]=pawn) then base:=(base*2) div 3;     // Блокирована  нашей пешкой
           res:=res+base;
         end;
   if res>MaxShieldPenalty then res:=MaxShieldPenalty;
   Result:=res;
end;

Function BKShield(king:integer;var Board:TBoard):integer; inline;
var
  Kx,Ky,mid,cen,edg,res,base,sq : integer;
  AllPawnsBB,MyPawnsBB,EnemyPawnsBB,temp : TBitBoard;
begin
  // Считаем значение прикрытия
  res:=0;
  Kx:=Posx[king];Ky:=Posy[King];
  AllPawnsBB:=Board.Pieses[pawn] and (ForwardBB[black,King] or RanksBB[Ky]);
  MyPawnsBB   :=AllPawnsBB and Board.Occupancy[black];
  EnemyPawnsBB:=AllPawnsBB and Board.Occupancy[white];
  if Kx=1 then
    begin
      mid:=2;
      cen:=3;
      edg:=1;
    end else
  if Kx=8 then
    begin
      mid:=7;
      cen:=6;
      edg:=8;
    end else
    begin
      mid:=Kx;
      if Mid>4 then
        begin
          edg:=mid+1;
          cen:=mid-1;
        end else
        begin
          edg:=mid-1;
          cen:=mid+1;
        end;
    end;
                      // центр
  // Считаем дефекты пешечного щита перед королем
  temp:=FilesBB[mid] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterMiddle[1]    // Нет нашей пешки
    else res:=res+ShelterMiddle[9-Posy[BitScanBackward(temp)]];
 // Считаем пешечный шторм противника
  temp:=FilesBB[mid] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormMiddle[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanBackward(temp);
           base:=StormMiddle[9-posy[sq]];
           if (Board.Pos[sq+8]=-pawn) then base:=(base*2) div 3;     // Блокирована нашей пешкой
           res:=res+base;
         end;
                      // крайняя
  temp:=FilesBB[edg] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterEdge[1]    // Нет нашей пешки
    else res:=res+ShelterEdge[9-Posy[BitScanBackward(temp)]];
 // Считаем пешечный шторм противника
  temp:=FilesBB[edg] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormEdge[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanBackward(temp);
           base:=StormEdge[9-posy[sq]];
           if (Board.Pos[sq+8]=-pawn) then base:=(base*2) div 3;     // Блокирована  нашей пешкой
           res:=res+base;
         end;
                     // ближе к центру
  temp:=FilesBB[cen] and MyPawnsBB;
  if temp=0
    then res:=res+ShelterCenter[1]    // Нет нашей пешки
    else res:=res+ShelterCenter[9-Posy[BitScanBackward(temp)]];
 // Считаем пешечный шторм противника
  temp:=FilesBB[cen] and EnemyPawnsBB;
  if temp=0
    then res:=res+StormCenter[1]  // Нет вражеской пешки - (полу)открытая линия на короля
    else begin
           sq:=BitScanBackward(temp);
           base:=StormCenter[9-posy[sq]];
           if (Board.Pos[sq+8]=-pawn) then base:=(base*2) div 3;     // Блокирована нашей пешкой
           res:=res+base;
         end;
   if res>MaxShieldPenalty then res:=MaxShieldPenalty;
   Result:=res;
end;
Function EvaluatePawns(var Board:TBoard):cardinal;inline;
// Оценка пешек на доске. Возвращает индекс на ячейку с посчитанными и сохраненными значениями.
var
  ScoreMid,ScoreEnd,sq,x,y,sq1,y1,sq2,wlight,wdark,blight,bdark : integer;
  temp,PassersBB,WhitePawnsBB,BlackPawnsBB,AllPawnsBB,BB,SupportedBB,Stoppers,Neighbors : TBitBoard;
  isolated,doubled,opened,backward,passed,supported,phalanx,connected,lever,ssup : boolean;
begin
  result:=Board.PawnKey and PawnTableMask;
  // Проверяем не считали ли мы это соотношение материала ранее?
  If  (Board.PawnKey=Pawntable[result].PawnKey) then exit;
  ScoreMid:=0;ScoreEnd:=0; PassersBB:=0;wlight:=0;wdark:=0;blight:=0;bdark:=0;
  AllPawnsBB:=Board.Pieses[pawn];
  WhitePawnsBB:=AllPawnsBB and Board.Occupancy[white];
  BlackPawnsBB:=AllPawnsBB and Board.Occupancy[black];
  // Белые
  temp:=WhitePawnsBB;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      if (Only[sq] and LightSquaresBB)<>0
        then inc(wlight)
        else inc(wdark);
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
      if passed and (not doubled) then PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции
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
        end else
      if (not supported) then
        begin
          ScoreMid:=ScoreMid-WeakMid;
          ScoreEnd:=ScoreEnd-WeakEnd;
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
      if (Only[sq] and LightSquaresBB)<>0
        then inc(blight)
        else inc(bdark);
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
      if passed and (not doubled) then PassersBB:=PassersBB or Only[sq];   // Оценка проходных позже в отдельной функции
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
        end else
      if (not supported) then
        begin
          ScoreMid:=ScoreMid+WeakMid;
          ScoreEnd:=ScoreEnd+WeakEnd;
        end;
      if Connected then
        begin
          ScoreMid:=ScoreMid-ConnectedMid[9-y,opened,phalanx,ssup];
          ScoreEnd:=ScoreEnd-ConnectedEnd[9-y,opened,phalanx,ssup];
        end;
      temp:=temp and (temp-1);
    end;
  // Сохраняем в хеш
  PawnTable[result].PawnKey:=Board.PawnKey;
  PawnTable[result].ScoreMid:=ScoreMid;
  PawnTable[result].ScoreEnd:=ScoreEnd;
  PawnTable[result].PassersBB:=PassersBB;
  PawnTable[result].WKSq:=NonSq;
  PawnTable[result].BKSq:=NonSq;
  PawnTable[result].WCastle:=255;
  PawnTable[result].BCastle:=255;
  PawnTable[result].BPawn:=wlight or (wdark shl 4) or (blight shl 8) or (bdark shl 12);
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
      PassMid:=PassMid+PasserBaseMid[y];
      PassEnd:=PassEnd+PasserBaseEnd[y];
      if (y>3) then  // Для продвинутых проходных дополнительная эндшпильная оценка
        begin
         // Удаленность королей от поля перед проходной
         PassEnd:=PassEnd+SquareDist[sq+8,Board.KingSq[black]]*WeakKingDist[y];
         PassEnd:=PassEnd-SquareDist[sq+8,Board.KingSq[white]]*StrongKingDist1[y];
         if (y<7) then PassEnd:=PassEnd-SquareDist[sq+16,Board.KingSq[white]]*StrongKingDist2[y];
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
      PassMid:=PassMid-PasserBaseMid[9-y];
      PassEnd:=PassEnd-PasserBaseEnd[9-y];
      if (y<6) then  // Для продвинутых проходных дополнительная эндшпильная оценка
        begin
         // Удаленность королей от поля перед проходной
         PassEnd:=PassEnd-SquareDist[sq-8,Board.KingSq[white]]*WeakKingDist[9-y];
         PassEnd:=PassEnd+SquareDist[sq-8,Board.KingSq[black]]*StrongKingDist1[9-y];
         if (y>2) then PassEnd:=PassEnd+SquareDist[sq-16,Board.KingSq[black]]*StrongKingDist2[9-y];
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
      ConnectedEnd[y,open,phalanx,prot]:=(base*5) div 8;
    end;
end;
initialization
PawnEvalInit;

end.
