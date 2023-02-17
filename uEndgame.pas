unit uEndgame;

interface
uses uBitBoards,uBoard,uMagic,uAttacks;

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
F_KPsK=5;
F_KBPsKW=7;
F_KBPsKB=8;
F_KPK=9;
F_KRKP=10;
F_KQKP=11;
F_KQKRP=12;
F_KRKBPW=13;
F_KRKBPB=14;
F_RPPRPW=15;
F_RPPRPB=16;

Function KXK(score:integer;var Board:TBoard):integer;inline;
Function KNNK:integer;inline;
Function KBNK(score:integer;var Board:TBoard):integer;inline;
Function KQKR(score:integer;var Board:TBoard):integer;inline;
Procedure KPSKw(var WScale:integer;var Board:TBoard);inline;
Procedure KPSKb(var BScale:integer;var Board:TBoard);inline;
Procedure KBPSKw(var WScale:integer;var Board:TBoard);inline;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);inline;
Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;inline;
Procedure GetSpecialScales(scalenum:integer;var WScale:integer;var BScale:integer;var Board:TBoard);inline;
Function KPK(var Board:TBoard):integer;inline;
Function KRKP(var Board:TBoard):integer;inline;
Function KQKP(var Board:TBoard):integer;inline;
Procedure KQKRP(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KRKBPW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KRKBPB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KRPPKRPW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KRPPKRPB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KBPKNW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Procedure KBPKNB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
implementation
 uses uMaterial,uKPK;

Function isOppositColor(sq1:integer;sq2:integer):boolean;inline;
begin
  If (((Only[sq1] and DarkSquaresBB)<>0) and ((Only[sq2] and LightSquaresBB)<>0)) or  (((Only[sq2] and DarkSquaresBB)<>0) and ((Only[sq1] and LightSquaresBB)<>0))
    then result:=true
    else result:=false;
end;
Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;inline;
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
Procedure GetSpecialScales(scalenum:integer;var WScale:integer;var BScale:integer;var Board:TBoard);inline;
// Определяет масштабные коэффициенты для специфических эндшпилей
begin
  if scalenum=F_KPsK then
   begin
    KPSKw(WScale,Board);
    KPSKb(BScale,Board);
   end else
  if scalenum=F_KBPsKW then KBPSKw(WScale,Board) else
  if scalenum=F_KBPsKB then KBPSKb(BScale,Board) else
  if scalenum=F_KQKRP  then KQKRP(WScale,BScale,Board) else
  if scalenum=F_KRKBPW  then KRKBPW(WScale,BScale,Board) else
  if scalenum=F_KRKBPB  then KRKBPB(WScale,BScale,Board) else
  if scalenum=F_RPPRPW  then KRPPKRPW(WScale,BScale,Board) else
  if scalenum=F_RPPRPB  then KRPPKRPB(WScale,BScale,Board) else  exit;
end;
Function KPK(var Board:TBoard):integer;inline;
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
Function KXK(score:integer;var Board:TBoard):integer;inline;
// Мат одинокому королю если у противоположной стороны минимум ладья преимущества. На входе - Эндшпильная материальная оценка которая корректируется
// Оценка сильнейшей стороны увеличивается если вражеский король в углу и между королями минимальное расстояние.
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // Белые ставят мат
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Черные ставят мат
  if Board.SideToMove=black then result:=-result;
end;

Function KNNK:integer;inline;
// Всегда возвращает ничейную оценку. Случаи мата отслеживаются в переборной функции
begin
  result:=0;
end;

Function KBNK(score:integer;var Board:TBoard):integer;inline;
// Мат слоном и конем используется специальную оценочную функцию подсказывающую в какой угол надо гнать одинокого короля
begin
  if (Board.NonPawnMat[black]=0)  then    // Белые ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score+BN_Dark[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score+BN_Light[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Белопольный слон
    end                           else   // Черные ставят мат
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score-BN_Dark[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Чернопольный слон
        else result:=score-BN_Light[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // Белопольный слон
    end;
  if Board.SideToMove=black then result:=-result;
end;

Function KQKR(score:integer;var Board:TBoard):integer;inline;
// Ферзь против ладьи использует похожую логику как и матование одинокого короля
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // Белые ставят мат
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // Черные ставят мат
  if Board.SideToMove=black then result:=-result;
end;

Procedure KPSKw(var WScale:integer;var Board:TBoard);inline;
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

Procedure KPSKb(var BScale:integer;var Board:TBoard);inline;
var
   PawnsBB : TBitBoard;
   KSq,SQ : integer;
begin
  KSq:=Board.KingSq[white];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) then
    begin
      SQ:=BitScanForWard(PawnsBB and FilesBB[1]);
      if (Posy[Ksq]<Posy[Sq]) and ((SquareDIst[Sq-8,KSq]<=1) or (SquareDist[a1,Ksq]<=1)) then Bscale:=ScaleDraw;
    end else
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) then
    begin
      SQ:=BitScanForWard(PawnsBB and FilesBB[8]);
      if (Posy[Ksq]<Posy[Sq]) and ((SquareDIst[Sq-8,KSq]<=1) or (SquareDist[h1,Ksq]<=1)) then Bscale:=ScaleDraw;
    end;
end;

Procedure KBPSKw(var WScale:integer;var Board:TBoard);inline;
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[black];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a8,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Wscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h8,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Wscale:=ScaleDraw;
  If ((Board.Pieses[pawn] and (Board.Pieses[pawn]-1))=0) and (Board.NonPawnMat[black]=PieseTypValue[knight]) then KBPKNW(Wscale,Ksq,Board);
end;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);inline;
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[white];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a1,Ksq]<=1) and ((Board.Pieses[bishop] and LightSquaresBB)<>0) then Bscale:=ScaleDraw;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h1,Ksq]<=1) and ((Board.Pieses[bishop] and DarkSquaresBB)<>0)  then Bscale:=ScaleDraw;
  If ((Board.Pieses[pawn] and (Board.Pieses[pawn]-1))=0) and (Board.NonPawnMat[white]=PieseTypValue[knight]) then KBPKNB(Ksq,BScale,Board);
end;


Function KRKP(var Board:TBoard):integer;inline;
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
Function KQKP(var Board:TBoard):integer;inline;
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
Procedure KQKRP(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  StrongKing,WeakKing,Rk:integer;
begin
  Rk:=BitScanForward(Board.Pieses[rook]);
  If (Board.Pieses[pawn] and Board.Occupancy[black])<>0 then
    begin
      // Белые - сильнейшая сторона
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      If (posy[WeakKing]>=7) and (Posy[StrongKing]<=5) and (posy[Rk]=6) and ((Board.Pieses[pawn] and KingAttacks[weakKing] and PawnAttacks[white,Rk])<>0)  then WScale:=ScaleDraw;
    end else
    begin
      // Черные - сильнейшая сторона
      StrongKing:=Board.KingSq[black];
      WeakKing:=Board.KingSq[white];
      If (posy[WeakKing]<=2) and (Posy[StrongKing]>=4) and (posy[Rk]=3) and ((Board.Pieses[pawn] and KingAttacks[weakKing] and PawnAttacks[black,Rk])<>0)  then BScale:=ScaleDraw;
    end;
end;
Procedure KRKBPW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  KD,Bs,pn:integer;
begin
  if ((Board.Pieses[pawn] and FilesBB[1])<>0) and ((Board.Pieses[pawn] and (not FilesBB[1]))=0) then
    begin
      bs:=BitScanForward(Board.Pieses[bishop]);
      pn:=BitScanForward(Board.Pieses[pawn]);
      // на 5 горизонтали
      If (posy[pn]=5) and ((Only[bs] and DarkSquaresBB)<>0) then
        begin
          KD:=SquareDist[Board.KingSq[black],a8];
          If (KD<=2) and (not((KD=0) and (Board.KingSq[white]=a6)))
            then WScale:=ScaleTought
            else WScale:=ScaleOnePawn;
        end;
      // На 6 горизонтали
      If (posy[pn]=6) and (SquareDist[Board.KingSq[black],a8]<=1) and ((BishopFullAttacks[bs] and Only[a7])<>0) and (SquareDist[pn,bs]>1) then Wscale:=ScaleHardWin;
    end;
  if ((Board.Pieses[pawn] and FilesBB[8])<>0) and ((Board.Pieses[pawn] and (not FilesBB[8]))=0) then
    begin
      bs:=BitScanForward(Board.Pieses[bishop]);
      pn:=BitScanForward(Board.Pieses[pawn]);
      // на 5 горизонтали
      If (posy[pn]=5) and ((Only[bs] and LightSquaresBB)<>0) then
        begin
          KD:=SquareDist[Board.KingSq[black],h8];
          If (KD<=2) and (not((KD=0) and (Board.KingSq[white]=h6)))
            then WScale:=ScaleTought
            else WScale:=ScaleOnePawn;
        end;
      // На 6 горизонтали
      If (posy[pn]=6) and (SquareDist[Board.KingSq[black],h8]<=1) and ((BishopFullAttacks[bs] and Only[h7])<>0) and (SquareDist[pn,bs]>1) then Wscale:=ScaleHardWin;
    end;
end;
Procedure KRKBPB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  KD,Bs,pn:integer;
begin
  if ((Board.Pieses[pawn] and FilesBB[1])<>0) and ((Board.Pieses[pawn] and (not FilesBB[1]))=0) then
    begin
      bs:=BitScanForward(Board.Pieses[bishop]);
      pn:=BitScanForward(Board.Pieses[pawn]);
      // на 4 горизонтали
      If (posy[pn]=4) and ((Only[bs] and LightSquaresBB)<>0) then
        begin
          KD:=SquareDist[Board.KingSq[white],a1];
          If (KD<=2) and (not((KD=0) and (Board.KingSq[black]=a3)))
            then BScale:=ScaleTought
            else BScale:=ScaleOnePawn;
        end;
      // На 3 горизонтали
      If (posy[pn]=3) and (SquareDist[Board.KingSq[white],a1]<=1) and ((BishopFullAttacks[bs] and Only[a2])<>0) and (SquareDist[pn,bs]>1) then Bscale:=ScaleHardWin;
    end;
  if ((Board.Pieses[pawn] and FilesBB[8])<>0) and ((Board.Pieses[pawn] and (not FilesBB[8]))=0) then
    begin
      bs:=BitScanForward(Board.Pieses[bishop]);
      pn:=BitScanForward(Board.Pieses[pawn]);
      // на 4 горизонтали
      If (posy[pn]=4) and ((Only[bs] and DarkSquaresBB)<>0) then
        begin
          KD:=SquareDist[Board.KingSq[white],h1];
          If (KD<=2) and (not((KD=0) and (Board.KingSq[black]=h3)))
            then BScale:=ScaleTought
            else BScale:=ScaleOnePawn;
        end;
      // На 3 горизонтали
      If (posy[pn]=3) and (SquareDist[Board.KingSq[white],h1]<=1) and ((BishopFullAttacks[bs] and Only[h2])<>0) and (SquareDist[pn,bs]>1) then Bscale:=ScaleHardWin;
    end;
end;
Procedure KRPPKRPW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  p1,p2,k,y : integer;
  PWW,PBB : TBitBoard;
begin
  PWW:=Board.Pieses[pawn] and Board.Occupancy[white];
  p1:=BitScanForward(PWW);
  p2:=BitScanBackward(PWW);
  k:=Board.KingSq[black];
  PBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  If ((PasserBB[white,p1] and PBB)<>0) and ((PasserBB[white,p2] and PBB)<>0) then
    begin
      If posy[p1]>=posy[p2]
        then y:=posy[p1]
        else y:=posy[p2];
      If (FileDist[k,p1]<2) and (FileDist[k,p2]<2) and (posy[k]>y) then WScale:=RPPScale[y];
    end;
end;
Procedure KRPPKRPB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  p1,p2,k,y : integer;
  PWW,PBB : TBitBoard;
begin
  PWW:=Board.Pieses[pawn] and Board.Occupancy[black];
  p1:=BitScanForward(PWW);
  p2:=BitScanBackward(PWW);
  k:=Board.KingSq[white];
  PBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  If ((PasserBB[black,p1] and PBB)<>0) and ((PasserBB[black,p2] and PBB)<>0) then
    begin
      If posy[p1]<=posy[p2]
        then y:=posy[p1]
        else y:=posy[p2];
      If (FileDist[k,p1]<2) and (FileDist[k,p2]<2) and (posy[k]<y) then BScale:=RPPScale[9-y];
    end;
end;
Procedure KBPKNW(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  wk,pn,bs : integer;
begin
  wk:=Board.KingSq[black];
  pn:=BitScanForward(Board.Pieses[pawn]);
  bs:=BitScanForward(Board.Pieses[bishop] and Board.Occupancy[white]);
  If (posx[wk]=posx[pn]) and (posy[wk]>posy[pn]) and ((posy[wk]<=6) or (isOppositColor(wk,bs))) then WScale:=ScaleDraw;
end;
Procedure KBPKNB(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  wk,pn,bs : integer;
begin
  wk:=Board.KingSq[white];
  pn:=BitScanForward(Board.Pieses[pawn]);
  bs:=BitScanForward(Board.Pieses[bishop] and Board.Occupancy[black]);
  If (posx[wk]=posx[pn]) and (posy[wk]<posy[pn]) and ((posy[wk]>=3) or (isOppositColor(wk,bs))) then BScale:=ScaleDraw;
end;
end.
