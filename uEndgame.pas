unit uEndgame;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBitBoards,uBoard;

CONST
WeakKingMate :array[a1..h8] of integer =
             (  100, 90, 80, 70, 70, 80, 90, 100, //1
                 90, 70, 60, 50, 50, 60, 70,  90, //2
                 80, 60, 40, 30, 30, 40, 60,  80, //3
                 70, 50, 30, 20, 20, 30, 50,  70, //4
                 70, 50, 30, 20, 20, 30, 50,  70, //5
                 80, 60, 40, 30, 30, 40, 60,  80, //6
                 90, 70, 60, 50, 50, 60, 70,  90, //7
                100, 90, 80, 70, 70, 80, 90, 100);//8

KingDistBonus : array[1..8] of integer = (0,50,40,30,20,10,5,0);

BN_light: array[a1..h8] of integer =
             (  20, 30, 40, 50, 60, 70, 80,100,   //1
                30, 20, 30, 40, 50, 60, 70, 80,   //2
                40, 30, 20, 30, 40, 50, 60, 70,   //3
                50, 40, 30, 20, 30, 40, 50, 60,   //4
                60, 50, 40, 30, 20, 30, 40, 50,   //5
                70, 60, 50, 40, 30, 20, 30, 40,   //6
                80, 70, 60, 50, 40, 30, 20, 30,   //7
               100, 80, 70, 60, 50, 40, 30, 20);  //8
BN_dark: array[a1..h8] of integer =
             ( 100, 80, 70, 60, 50, 40, 30, 20,   //1
                80, 70, 60, 50, 40, 30, 20, 30,   //2
                70, 60, 50, 40, 30, 20, 30, 40,   //3
                60, 50, 40, 30, 20, 30, 40, 50,   //4
                50, 40, 30, 20, 30, 40, 50, 60,   //5
                40, 30, 20, 30, 40, 50, 60, 70,   //6
                30, 20, 30, 40, 50, 60, 70, 80,   //7
                20, 30, 40, 50, 60, 70, 80,100);  //8

F_KXK=1;
F_KNNK=2;
F_KBNK=3;
F_KQKR=4;
F_KBPsKW=5;
F_KBPsKB=6;
F_KPK=7;
F_KRKP=8;
F_KQKP=9;


ScaleNormal=64;
ScaleDraw=0;



Function SpecialCases(var Board:TBoard):integer;
Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;
Procedure KBPSKw(var WScale:integer;var Board:TBoard);
Procedure KBPSKb(var BScale:integer;var Board:TBoard);

implementation
 uses uKPK;

Function isOppositColor(sq1:integer;sq2:integer):boolean;inline;
begin
  If (((Only[sq1] and DarkSquaresBB)<>0) and ((Only[sq2] and LightSquaresBB)<>0)) or  (((Only[sq2] and DarkSquaresBB)<>0) and ((Only[sq1] and LightSquaresBB)<>0))
    then result:=true
    else result:=false;
end;
Function KNNK:integer;inline;
// Всегда возвращает ничейную оценку. Случаи мата отслеживаются в переборной функции
begin
  result:=0;
end;
Function KPK(var Board:TBoard):integer;
var
  wk,bk,paw,color,res:integer;
// Оцениваем по битовым таблицам
begin
  if (Board.Occupancy[white] and Board.Pieses[pawn])<>0 then
    begin
      WK:=Board.KingSq[white];
      BK:=Board.KingSq[black];
      paw:=BitScanForward(Board.Pieses[pawn]);
      color:=Board.SideToMove;
    end else
    begin
      WK:=VertReflectSQ[Board.KingSq[black]];
      BK:=VertReflectSQ[Board.KingSq[white]];
      paw:=VertReflectSq[BitScanForward(Board.Pieses[pawn])];
      color:=Board.SideToMove xor 1;
    end;
  if numpawn[paw]>23 then
    begin
      paw:=HorReflectSQ[paw];
      WK:=HorReflectSQ[WK];
      BK:=HorReflectSQ[BK];
    end;
  res:=KPKProbe(color,paw,wk,bk);
  if res=0 then result:=0 else
  if res>0 then result:=KPKWin-res*5
           else result:=-KPKwin+res*5;
end;
Function KXK(score:integer;var Board:TBoard):integer;
// Мат одинокому королю если у противоположной стороны минимум ладья преимущества. На входе - Эндшпильная материальная оценка которая корректируется
// Оценка сильнейшей стороны увеличивается если вражеский король в углу и между королями минимальное расстояние.
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // Белые ставят мат
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Черные ставят мат
  if Board.SideToMove=black then result:=-result;
end;


Function KBNK(score:integer;var Board:TBoard):integer;
// Мат слоном и конем используется специальную оценочную функцию подсказывающую в какой угол надо гнать одинокого короля
begin
  if (Board.NonPawnMat[black]=0)  then    // Белые ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score+BN_Dark[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score+BN_Light[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Белопольный слон
      if Board.SideToMove=black then result:=-result;
    end                           else   // Черные ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score-BN_Dark[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score-BN_Light[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Белопольный слон
       if Board.SideToMove=white then result:=-result;
    end;
end;

Function KQKR(score:integer;var Board:TBoard):integer;
// Ферзь против ладьи использует похожую логику как и матование одинокого короля
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // Белые ставят мат
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Черные ставят мат
  if Board.SideToMove=black then result:=-result;
end;

Procedure KPSKw(var WScale:integer;var Board:TBoard);
var
   PawnsBB : TBitBoard;
   KSq,SQ : integer;
begin
  KSq:=Board.KingSq[black];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) then
    begin
      SQ:=BitScanBackWard(PawnsBB and FilesBB[1]);
      if (Posy[Ksq]>Posy[Sq]) and ((SquareDIst[Sq+8,KSq]<=1) or (SquareDist[a8,Ksq]<=1)) then Wscale:=ScaleDraw;
    end else
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) then
    begin
      SQ:=BitScanBackWard(PawnsBB and FilesBB[8]);
      if (Posy[Ksq]>Posy[Sq]) and ((SquareDIst[Sq+8,KSq]<=1) or (SquareDist[h8,Ksq]<=1)) then Wscale:=ScaleDraw;
    end;
end;

Procedure KBPKNW(var WScale:integer; var Board:TBoard);
var
  wk,pn,bs : integer;
begin
  wk:=Board.KingSq[black];
  pn:=BitScanForward(Board.Pieses[pawn]);
  bs:=BitScanForward(Board.Pieses[bishop] and Board.Occupancy[white]);
  If (posx[wk]=posx[pn]) and (posy[wk]>posy[pn]) and ((posy[wk]<=6) or (isOppositColor(wk,bs))) then WScale:=ScaleDraw;
end;
Procedure KBPKNB(var BScale:integer; var Board:TBoard);
var
  wk,pn,bs : integer;
begin
  wk:=Board.KingSq[white];
  pn:=BitScanForward(Board.Pieses[pawn]);
  bs:=BitScanForward(Board.Pieses[bishop] and Board.Occupancy[black]);
  If (posx[wk]=posx[pn]) and (posy[wk]<posy[pn]) and ((posy[wk]>=3) or (isOppositColor(wk,bs))) then BScale:=ScaleDraw;
end;


Procedure KBPSKw(var WScale:integer;var Board:TBoard);
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[black];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a8,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Wscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h8,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Wscale:=ScaleDraw;
  If ((Board.Pieses[pawn] and (Board.Pieses[pawn]-1))=0) and (Board.NonPawnMat[black]=PieseTypValue[knight]) then KBPKNW(Wscale,Board);
end;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[white];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a1,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Bscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h1,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Bscale:=ScaleDraw;
  If ((Board.Pieses[pawn] and (Board.Pieses[pawn]-1))=0) and (Board.NonPawnMat[white]=PieseTypValue[knight]) then KBPKNB(BScale,Board);
end;


Function KRKP(var Board:TBoard):integer;
var
   StrongKing,WeakKing,Rk,pn,QSquare,pawndist,rookdist : integer;
begin
  rk:=BitScanForward(Board.Pieses[rook]);
  pn:=BitScanForward(Board.Pieses[pawn]);
  If (Board.Pieses[pawn] and Board.Occupancy[black])<>0 then
    begin
      // Белые - сильнейшая сторона
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      QSquare:=Posx[pn]-1;
      // Если король сильнейшей стороны успел встать перед пешкой - это победа
      If (StrongKing<pn) and (Posx[StrongKing]=Posx[pn]) then
        begin
          Result:=RookValueEnd-SquareDist[StrongKing,Pn];
        end else
        begin
         // Если слабейший король далеко от пешки и ее можно забрать - то выигрыш
         PawnDist:=SquareDist[Pn,WeakKing];
         RookDist:=SquareDist[Rk,WeakKing];
         IF Board.SideToMove=black then dec(PawnDist);
         If (PawnDist>=3) and (RookDist>=3) then
           begin
             Result:=RookValueEnd-SquareDist[StrongKing,Pn];
           end else
           begin
            // Если пешка далеко продвинута и сильнейший король далеко - ничья
            PawnDist:=SquareDist[StrongKing,Pn];
            If Board.SideToMove=white then dec(PawnDist);
            If (Posy[WeakKing]<=3) and (Posy[StrongKing]>=4) and (SquareDist[Pn,WeakKing]=1) and (PawnDist>2)
              then Result:=32-4*PawnDist
              else Result:=80-4*(SquareDist[StrongKing,Pn-8]-SquareDist[WeakKing,Pn-8]-SquareDist[Pn,QSquare]);
           end;
        end;
    end else
    begin
      // Черные - сильнейшая сторона
      StrongKing:=Board.KingSq[black];
      WeakKing:=Board.KingSq[white];
      QSquare:=56+(Posx[pn]-1);
      // Если король сильнейшей стороны успел встать перед пешкой - это победа
      If (StrongKing>pn) and (Posx[StrongKing]=Posx[pn]) then
        begin
          Result:=RookValueEnd-SquareDist[StrongKing,Pn];
        end else
        begin
         // Если слабейший король далеко от пешки и ее можно забрать - то выигрыш
         PawnDist:=SquareDist[Pn,WeakKing];
         RookDist:=SquareDist[Rk,WeakKing];
         IF Board.SideToMove=white then dec(PawnDist);
         If (PawnDist>=3) and (RookDist>=3) then
           begin
             Result:=RookValueEnd-SquareDist[StrongKing,Pn];
           end else
           begin
            // Если пешка далеко продвинута и сильнейший король далеко - ничья
            PawnDist:=SquareDist[StrongKing,Pn];
            If Board.SideToMove=black then dec(PawnDist);
            If (Posy[WeakKing]>=6) and (Posy[StrongKing]<=5) and (SquareDist[Pn,WeakKing]=1) and (PawnDist>2)
              then Result:=32-4*PawnDist
              else Result:=80-4*(SquareDist[StrongKing,Pn+8]-SquareDist[WeakKing,Pn+8]-SquareDist[Pn,QSquare]);
           end;
        end;
      Result:=-Result;
    end;
 IF Board.SideToMove=black then result:=-result;
end;
Function KQKP(var Board:TBoard):integer;
var
  pn,WeakKing,StrongKing:integer;
begin
  pn:=BitScanForward(Board.Pieses[pawn]);
  If (Board.Pieses[pawn] and Board.Occupancy[black])<>0 then
    begin
      // Белые - сильнейшая сторона
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      Result:=KingDistBonus[SquareDist[StrongKing,WeakKing]];
      If (Posy[Pn]<>2) or (SquareDist[pn,WeakKing]<>1) or (Posx[pn] in [2,4,5,7]) then Result:=Result+QueenValueEnd-PawnValueEnd;
    end else
    begin
      // Черные - сильнейшая сторона
      StrongKing:=Board.KingSq[black];
      WeakKing:=Board.KingSq[white];
      Result:=KingDistBonus[SquareDist[StrongKing,WeakKing]];
      If (Posy[Pn]<>7) or (SquareDist[pn,WeakKing]<>1) or (Posx[pn] in [2,4,5,7]) then Result:=Result+QueenValueEnd-PawnValueEnd;
      Result:=-Result;
    end;
  If Board.SideToMove=black then Result:=-result;
end;

Function SpecialCases(var Board:TBoard):integer;
// Быстрая оценка материала и специальных случаев на доске
var
  NPW,NPB,evalfun: integer;
  wp,bp: integer;
begin
  evalfun:=0;
  wp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[white]);
  bp:=BitCount(Board.Pieses[Pawn]   and Board.Occupancy[black]);
  NPW:=Board.NonPawnMat[white];
  NPB:=Board.NonPawnMat[black];
  // Ищем возможные внешние функции оценки и масштабирования
  if wp+bp=0 then  // беспешечные эндшпили
    begin
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[knight]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[knight]))) then evalfun:=f_knnk else   //KNNK
     If ((Board.NonPawnMat[white]=0) and (Board.NonPawnMat[black]=(PieseTypValue[knight]+PieseTypValue[bishop]))) or ((Board.NonPawnMat[black]=0) and (Board.NonPawnMat[white]=(PieseTypValue[knight]+PieseTypValue[bishop]))) then evalfun:=f_kbnk else   //KBNK
     If (Board.NonPawnMat[white]<PieseTypValue[rook]) and (Board.NonPawnMat[black]<PieseTypValue[rook]) then evalfun:=f_knnk;
    end;
  if (NPW=0) and (NPB=0) then // Пешечный эндшпиль
    begin
     if (wp+bp)=1 then evalfun:=f_KPK ;
    end;
  if (NPW=PieseTypValue[bishop])  and (wp>0) then evalfun:=F_KBPSKW;
  if (NPB=PieseTypValue[bishop])  and (bp>0) then evalfun:=F_KBPSKB;
  Result:=evalfun;
end;

Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;
// Функция входная
begin
  result:=0;
  if FuncNum=F_KXK then result:=KXK(score,Board) else
  if FuncNum=F_KNNK then result:=KNNK else
  if FuncNum=F_KBNK then result:=KBNK(score,Board) else
  if Funcnum=f_KPK then result:=KPK(Board) else
  if FuncNum=F_KQKR then result:=KQKR(score,Board) else
  if FuncNum=F_KRKP then result:=KRKP(Board) else
  if FuncNum=F_KQKP then result:=KQKP(Board) else exit;
end;


end.
