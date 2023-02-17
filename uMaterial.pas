unit uMaterial;
interface
uses uBoard,uBitBoards,uEndgame;
Type
   TMatEntry = record
                 MatKey    : int64;
                 EvalMid   : smallint;
                 EvalEnd   : smallint;
                 WScale    : byte;
                 BScale    : byte;
                 EvalFunc  : byte;
                 ScaleFunc : byte;
                 phase     : byte;
               end;
Const
   PawnValueMid=80;    PawnValueEnd=100;
   KnightValueMid=320; KnightValueEnd=310;
   BishopValueMid=325; BishopValueEnd=320;
   RookValueMid=500;   RookValueEnd=510;
   QueenValueMid=960;  QueenValueEnd=970;
   DoubleBishopMid=40; DoubleBishopEnd=50;
   DoubleNoMinorMid=10;DoubleNoMinorEnd=15;
   MinorBonusMid=15;   MinorBonusEnd=30;
   KnightPawnMid=5;    KnightPawnEnd=5;
   RookPawnMid=10;     RookPawnEnd=10;
   DoubleRookMid=16;   DoubleRookEnd=32;
   ExtraMajorMid=8;    ExtraMajorEnd=16;

   PieseTypValue : array[Pawn..Queen] of integer = (0,KnightValueMid,BishopValueMid,RookValueMid,QueenValueMid); // Для обновления внутри make непешечного материала на доске. Поэтому ценность пешки =0
   ScalePawn=80;
   ScaleNormal=64;
   ScaleOnePawn=48;
   ScaleOpposit=32;
   ScaleTought=24;
   ScaleHardWin=12;
   ScaleDrawish=4;
   ScaleDraw=0;
   RPPScale : array[1..8] of integer=(0,ScaleHardWin,ScaleHardWin,ScaleTought,ScaleOpposit,ScaleOnePawn,ScaleNormal,0);
   PhaseMinor=1;
   PhaseRook=3;
   PhaseQueen=6;
   MaxPhase=32;
   PhaseOpposit=2*PhaseMinor+2*PhaseQueen+2*PhaseRook;
   PhaseSpace=2*PhaseQueen+4*PhaseRook+2*Phaseminor;

Procedure InitMatTable(SizeMB:integer);
Procedure CalcImbalance(var ScoreMid:integer;var ScoreEnd:integer;wp,bp,wn,bn,wb,bb,wr,br,wq,bq:integer);inline;
Function EvaluateMaterial(var Board:TBoard;ThreadID:integer):int64; inline;

implementation
  uses uThread,uSearch;
Procedure InitMatTable(SizeMB:integer);
// На входе - ОБЩЕЕ количество мегабайт кеша, полученного от оболочки
var
   i,MatTableSize : int64;
   j : integer;
begin
  MatTableSize:=SizeMb;
  // Суммарная память под хещ
  MatTableSize:=(MatTableSize * 1024 * 1024) div (32*16); {берем 1/32 долю хеша. Размер ячейки берем 16}
  // Устанавливаем для каждого потока отдельно память под материальный хеш
  for j:=1 to game.Threads do
    begin
     Threads[j].MatTableMask:=(MatTableSize div game.Threads)-1;
     SetLength(Threads[j].MatTable,0);
     SetLength(Threads[j].MatTable,(Threads[j].MatTableMask+1));
     for i:=0 to Threads[j].MatTableMask do
      begin
       Threads[j].MatTable[i].MatKey:=0;
       Threads[j].MatTable[i].EvalMid:=0;
       Threads[j].MatTable[i].EvalEnd:=0;
       Threads[j].MatTable[i].WScale:=0;
       Threads[j].MatTable[i].BScale:=0;
       Threads[j].MatTable[i].EvalFunc:=0;
       Threads[j].MatTable[i].ScaleFunc:=0;
       Threads[j].MatTable[i].phase:=0;
      end;
    end;
end;

Procedure CalcImbalance(var ScoreMid:integer;var ScoreEnd:integer;wp,bp,wn,bn,wb,bb,wr,br,wq,bq:integer);inline;
// Считает материальную оценку при данном конкретном соотношении материала
begin
  ScoreMid:=(wp-bp)*PawnValueMid+(wn-bn)*KnightValueMid+(wp-5)*wn*KnightPawnMid-(bp-5)*bn*KnightPawnMid+(wb-bb)*BishopValueMid+(wr-br)*RookValueMid-(wp-5)*wr*RookPawnMid+(bp-5)*br*RookPawnMid+(wq-bq)*QueenValueMid;
  ScoreEnd:=(wp-bp)*PawnValueEnd+(wn-bn)*KnightValueEnd+(wp-5)*wn*KnightPawnEnd-(bp-5)*bn*KnightPawnEnd+(wb-bb)*BishopValueEnd+(wr-br)*RookValueEnd-(wp-5)*wr*RookPawnEnd+(bp-5)*br*RookPawnEnd+(wq-bq)*QueenValueEnd;
  if wb>1 then
    begin
      ScoreMid:=ScoreMid+DoubleBishopMid;
      ScoreEnd:=ScoreEnd+DoubleBishopEnd;
      if (bn+bb=0) then
        begin
          ScoreMid:=ScoreMid+DoubleNoMinorMid;
          ScoreEnd:=ScoreEnd+DoubleNoMinorEnd;
        end;
    end;
  if bb>1 then
    begin
      ScoreMid:=ScoreMid-DoubleBishopMid;
      ScoreEnd:=ScoreEnd-DoubleBishopEnd;
      if (wn+wb=0) then
        begin
          ScoreMid:=ScoreMid-DoubleNoMinorMid;
          ScoreEnd:=ScoreEnd-DoubleNoMinorEnd;
        end;
    end;
  if (wn+wb>bn+bb+1) then
    begin
      ScoreMid:=ScoreMid+MinorBonusMid;
      ScoreEnd:=ScoreEnd+MinorBonusEnd;
    end else
  if (bn+bb>wn+wb+1) then
    begin
      ScoreMid:=ScoreMid-MinorBonusMid;
      ScoreEnd:=ScoreEnd-MinorBonusEnd;
    end;
  if wr>1 then
    begin
      ScoreMid:=ScoreMid-DoubleRookMid;
      ScoreEnd:=ScoreEnd-DoubleRookEnd;
    end;
  if br>1 then
    begin
      ScoreMid:=ScoreMid+DoubleRookMid;
      ScoreEnd:=ScoreEnd+DoubleRookEnd;
    end;
  if wr+wq>1 then
    begin
      ScoreMid:=ScoreMid-ExtraMajorMid;
      ScoreEnd:=ScoreEnd-ExtraMajorEnd;
    end;
  if br+bq>1 then
    begin
      ScoreMid:=ScoreMid+ExtraMajorMid;
      ScoreEnd:=ScoreEnd+ExtraMajorEnd;
    end;
end;
Function EvaluateMaterial(var Board:TBoard;ThreadID:integer):int64; inline;
// Оценка материала на доске. Возвращает индекс на ячейку с посчитанными и сохраненными значениями.
var
  ScoreMid,ScoreEnd,Wscale,BScale,NPW,NPB,phase,evalfun,scalefun : integer;
  wp,bp,wn,bn,wb,bb,wr,br,wq,bq : integer;
begin
  result:=Board.MatKey and Threads[ThreadId].MatTableMask;
  // Проверяем не считали ли мы это соотношение материала ранее?
  If Board.MatKey=Threads[ThreadId].Mattable[result].MatKey then exit;
  // Нет - считаем полностью
  wp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[white]);
  bp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[black]);
  wn:=BitCount(Board.Pieses[Knight] and Board.Occupancy[white]);
  bn:=BitCount(Board.Pieses[Knight] and Board.Occupancy[black]);
  wb:=BitCount(Board.Pieses[Bishop] and Board.Occupancy[white]);
  bb:=BitCount(Board.Pieses[Bishop] and Board.Occupancy[black]);
  wr:=BitCount(Board.Pieses[Rook]   and Board.Occupancy[white]);
  br:=BitCount(Board.Pieses[Rook]   and Board.Occupancy[black]);
  wq:=BitCount(Board.Pieses[Queen]  and Board.Occupancy[white]);
  bq:=BitCount(Board.Pieses[Queen]  and Board.Occupancy[black]);
  NPW:=Board.NonPawnMat[white];
  NPB:=Board.NonPawnMat[black];
  // Сначала считаем масштабирующие коэффициенты
  Wscale:=ScaleNormal;
  BScale:=ScaleNormal;
  if wp=0 then
    begin
      // У белых нет пешек
      if NPW-NPB<=PieseTypValue[Bishop] then   // Если у белых не более легкой фигуры преимущества то выигрыш может быть затруднен или невозможен. Особый случай - KBBKN  который сюда не попадает так как цена коня меньше цены  слона!
        begin
          if NPW<PieseTypValue[Rook] then Wscale:=ScaleDraw else   // КК* KNK* KBK*
            if NPB<=PieseTypValue[Bishop]
              then WScale:=ScaleDrawish   // KRKB* KRKN* KBNKB* etc
              else WScale:=ScaleHardWin;  // KRBKR*  etc.
        end;
    end else
  if wp=1 then
    begin
      // Если осталась последняя пешка  то выигрыш тоже может быть непрост
      if NPW-NPB<=PieseTypValue[Bishop] then WScale:=ScaleOnePawn;
    end;
  if bp=0 then
    begin
      // У черных нет пешек
      if NPB-NPW<=PieseTypValue[Bishop] then   // Если у черных не более легкой фигуры преимущества то выигрыш может быть затруднен или невозможен. Особый случай - KBBKN  который сюда не попадает так как цена коня меньше цены одного слона!
        begin
          if NPB<PieseTypValue[Rook] then Bscale:=ScaleDraw else   // КК* KNK* KBK*
            if NPW<=PieseTypValue[Bishop]
              then BScale:=ScaleDrawish   // KRKB* KRKN* KBNKB* etc
              else BScale:=ScaleHardWin;  // KRBKR*  etc.
        end;
    end else
  if bp=1 then
    begin
      // Если осталась последняя пешка  то выигрыш тоже может быть непрост
      if NPB-NPW<=PieseTypValue[Bishop] then BScale:=ScaleOnePawn;
    end;
  // Теперь считаем материал
  CalcImbalance(ScoreMid,ScoreEnd,wp,bp,wn,bn,wb,bb,wr,br,wq,bq);
  // Считаем фазу
  phase:=(wn+bn+wb+bb)*PhaseMinor+(wr+br)*PhaseRook+(wq+bq)*PhaseQueen;
  if phase>MaxPhase then phase:=MaxPhase;
  evalfun:=0;scalefun:=0;
  // Ищем возможные внешние функции оценки и масштабирования
  if wp+bp=0 then  // беспешечные эндшпили
    begin
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[knight]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[knight]))) then evalfun:=f_knnk else   //KNNK
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[bishop]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[bishop]))) then evalfun:=f_kbnk else   //KBNK
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]>=PieseTypValue[rook])) or  ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]>=PieseTypValue[rook])) then evalfun:=f_kxk else  // Мат одинокому королю
     If ((Board.NonPawnMat[white]=PieseTypValue[rook]) and (Board.NonPawnMat[black]=PieseTypValue[queen])) or ((Board.NonPawnMat[white]=PieseTypValue[queen]) and (Board.NonPawnMat[black]=PieseTypValue[rook])) then evalfun:=f_kqkr;     //KQKR
    end;
  if (NPW=0) and (NPB=0) then // Пешечный эндшпиль
    begin
     if (wp+bp)=1 then evalfun:=f_KPK else
       begin
        If Wscale=ScaleNormal then WScale:=ScalePawn;
        If Bscale=ScaleNormal then BScale:=ScalePawn;
        scalefun:=F_KPSK;  // Предварительно надо проверить на ничейность ладейных пешек
       end;
    end;
  if (NPW=PieseTypValue[bishop]) and (wb=1) and (wp>0) then scalefun:=F_KBPSKW;
  if (NPB=PieseTypValue[bishop]) and (bb=1) and (bp>0) then scalefun:=F_KBPSKB;
  If (NPW=PieseTypValue[rook]) and (NPB=0) and (wp=0) and (bp=1) then evalfun:=f_KRKP;
  If (NPB=PieseTypValue[rook]) and (NPW=0) and (bp=0) and (wp=1) then evalfun:=f_KRKP;
  If (NPW=PieseTypValue[queen]) and (NPB=0) and (wp=0) and (bp=1) then evalfun:=f_KQKP;
  If (NPB=PieseTypValue[queen]) and (NPW=0) and (bp=0) and (wp=1) then evalfun:=f_KQKP;
  If (NPW=PieseTypValue[queen]) and (NPB=PieseTypValue[rook]) and (wp=0) and (bp>=1) then scalefun:=f_KQKRP;
  If (NPB=PieseTypValue[queen]) and (NPW=PieseTypValue[rook]) and (bp=0) and (wp>=1) then scalefun:=f_KQKRP;
  If (NPW=PieseTypValue[rook])  and (NPB=PieseTypValue[bishop]) and (wp=1) and (bp=0) then scalefun:=f_KRKBPW;
  If (NPB=PieseTypValue[rook])  and (NPW=PieseTypValue[bishop]) and (bp=1) and (wp=0) then scalefun:=f_KRKBPB;
  If (NPW=PieseTypValue[rook])  and (NPB=PieseTypValue[rook]) and (wp=2) and (bp=1) then scalefun:=f_RPPRPW;
  If (NPW=PieseTypValue[rook])  and (NPB=PieseTypValue[rook]) and (wp=1) and (bp=2) then scalefun:=f_RPPRPB;
  // Сохраняем все в хеш
  Threads[ThreadId].MatTable[result].MatKey:=Board.MatKey;
  Threads[ThreadId].MatTable[result].EvalMid:=ScoreMid;
  Threads[ThreadId].MatTable[result].EvalEnd:=ScoreEnd;
  Threads[ThreadId].MatTable[result].WScale:=Wscale;
  Threads[ThreadId].MatTable[result].BScale:=BScale;
  Threads[ThreadId].MatTable[result].EvalFunc:=evalfun;
  Threads[ThreadId].MatTable[result].ScaleFunc:=scalefun;
  Threads[ThreadId].MatTable[result].phase:=phase;
end;
end.
