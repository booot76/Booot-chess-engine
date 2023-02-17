unit uBoard;

interface
uses ubitboards,uMagic,SysUtils;

Const
  White=0;
  Black=1;

  King=6;
  Queen=5;
  Rook=4;
  Bishop=3;
  Knight=2;
  Pawn=1;
  Empty=0;
  All=0;

  TypOfPiese : array[-king..King] of integer=(king,queen,rook,bishop,knight,pawn,Empty,pawn,knight,bishop,rook,queen,king);

  NonSq=-1;

  WhiteShortCastleMask=1;
  WhiteLongCastleMask=2;
  BlackShortCastleMask=4;
  BlackLongCastleMask=8;

  CastleRightsSq : array[a1..h8] of integer =
   (253,255,255,255,252,255,255,254,
    255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,255,
    255,255,255,255,255,255,255,255,
    247,255,255,255,243,255,255,251);

  Posx : array[a1..h8] of integer =
  (1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8,
   1,2,3,4,5,6,7,8);

  Posy : array[a1..h8] of integer =
  (1,1,1,1,1,1,1,1,
   2,2,2,2,2,2,2,2,
   3,3,3,3,3,3,3,3,
   4,4,4,4,4,4,4,4,
   5,5,5,5,5,5,5,5,
   6,6,6,6,6,6,6,6,
   7,7,7,7,7,7,7,7,
   8,8,8,8,8,8,8,8);

  VertReflectSq : array[a1..h8] of integer =
  (a8,b8,c8,d8,e8,f8,g8,h8,
   a7,b7,c7,d7,e7,f7,g7,h7,
   a6,b6,c6,d6,e6,f6,g6,h6,
   a5,b5,c5,d5,e5,f5,g5,h5,
   a4,b4,c4,d4,e4,f4,g4,h4,
   a3,b3,c3,d3,e3,f3,g3,h3,
   a2,b2,c2,d2,e2,f2,g2,h2,
   a1,b1,c1,d1,e1,f1,g1,h1);

  HorReflectSq : array[a1..h8] of integer =
  (h1,g1,f1,e1,d1,c1,b1,a1,
   h2,g2,f2,e2,d2,c2,b2,a2,
   h3,g3,f3,e3,d3,c3,b3,a3,
   h4,g4,f4,e4,d4,c4,b4,a4,
   h5,g5,f5,e5,d5,c5,b5,a5,
   h6,g6,f6,e6,d6,c6,b6,a6,
   h7,g7,f7,e7,d7,c7,b7,a7,
   h8,g8,f8,e8,d8,c8,b8,a8);

  MaxMoves=256;

  CaptureFlag  = 1 shl 15;
  PromoteFlag  =(1 shl 12) or (1 shl 13) or (1 shl 14);
  CapPromoFlag =CaptureFlag or PromoteFlag;

  StrongPromo=0;
  WeakPromos=1;
  AllPromos=2;

  PawnPush : array[white..black] of integer =(8,-8);
Type
  TBoard=record
           SideToMove   : Integer;
           Pieses       : array [Pawn..Queen] of TBitBoard;
           Occupancy    : array [White..Black] of TBitBoard;
           Pos          : array [a1..h8] of integer;
           KingSq       : array [white..black] of integer;
           AllPieses    : TBitBoard;
           EnPassSq     : Integer;
           CastleRights : Integer;
           Rule50       : Integer;
           MoveNum      : integer;
           CheckersBB   : TBitBoard;
           CapturedPiese: integer;
           Key          : int64;
           PawnKey      : int64;
           MatKey       : int64;
           NonPawnMat   : array[white..black] of integer;
           PstMid       : integer;
           PstEnd       : integer;
           Nodes        : int64;
           remain       : integer;
           nullcnt      : integer;
         end;
  TUndo = record
           isCapture    : boolean;
           isCastle     : boolean;
           isEnnPass    : boolean;
           EnPassSq     : Integer;
           CastleRights : Integer;
           Rule50       : Integer;
           CheckersBB   : TBitBoard;
           CapturedPiese: integer;
           Key          : int64;
           PawnKey      : int64;
           MatKey       : int64;
           NonPawnMat   : array[white..black] of integer;
           PstMid       : integer;
           PstEnd       : integer;
           nullcnt      : integer;
          end;
  Thistory = array[-King..King,a1..h8] of integer;
  PHistory = ^THistory;
  TTreeEntry = record
                 Status   : integer;
                 max      : integer;
                 curr     : integer;
                 badcap   : integer;
                 value    : integer;
                 key      : int64;
                 StatEval : integer;
                 StatKey  : int64;
                 CurrMove : integer;
                 CurrStat : PHistory;
                 CurrNum  : integer;
                 HistVal  : integer;
               end;
  Ttree = array [-101..129]  of TTreeEntry;
  TCheckInfo = record
                 DiscoverCheckBB : TBitBoard;
                 DirectCheckBB : array [Pawn..King] of TBitBoard;
                 Pinned : TBitBoard;
                 EnemyKingSq : integer;
               end;
  Tmove = record
            move  : integer;
            value : integer;
          end;
  TMoveList=array[0..MaxMoves] of TMove;


Procedure SetBoard(FEN : ansistring; var Board:TBoard);
procedure PrintBoard(Board : TBoard);
Function StringMove(move:integer):shortstring;
Function CalcNonPawnMat(color:integer;var Board:TBoard):integer;
Function GeneratePseudoMoves(beg:integer;Target:TBitBoard;var Board:TBoard;var MList:TMoveList):integer;
Function GeneratePseudoCaptures(beg:integer;Target:TBitBoard;var Board:TBoard;var MList:TMoveList):integer;
Function GeneratePseudoEscapes(beg:integer;var Board:TBoard;var MList:TMoveList):integer;
Function GeneratePseudoChecks(beg:integer; Target:TBitBoard; var Board:TBoard; var CheckInfo:TCheckInfo; var MList:TmoveList):integer;
Function GenerateLegals(beg:integer;var Board:TBoard;var MList:TMoveList):integer;
Procedure SetUndo(var Board:TBoard;var Undo:TUndo);inline;
Procedure MakeMove(move : integer;var Board:TBoard;var Undo:TUndo;isCheck:boolean); inline;
Procedure UnMakeMove(move : integer;var Board:TBoard; var Undo:TUndo); inline;
Procedure CopyBoard (var Board:TBoard; var NewBoard:TBoard );
Function CompareBoards(var Board:TBoard; var NewBoard:TBoard):boolean;
Procedure ReflectBoard(var Board:TBoard;var NewBoard:TBoard);
Function Perft(Root:boolean;t1:TDateTime;var Board:TBoard;depth:integer):int64;
Procedure MakeNullMove(var Board:TBoard);inline;
Procedure UnMakeNullMove(var Board:TBoard;var Undo:TUndo);inline;
implementation
uses uAttacks,DateUtils,uHash,uMaterial,uPawn,uEval,uEndGame,uUci,uThread,uSort;

Procedure ClearBoard(var Board:TBoard);
var
  i:integer;
begin
  // Чистим доску
  for i:=Pawn to Queen do
    Board.Pieses[i]:=0;
  for i:=a1 to h8 do
    Board.Pos[i]:=Empty;
  Board.KingSq[white]:=Empty;
  Board.KingSq[black]:=Empty;
  Board.Occupancy[white]:=Empty;
  Board.Occupancy[black]:=Empty;
  Board.AllPieses:=Empty;
  Board.EnPassSq:=NonSq;
  Board.CastleRights:=0;
  Board.Rule50:=0;
  Board.SideToMove:=white;
  Board.MoveNum:=1;
  Board.CheckersBB:=0;
  Board.CapturedPiese:=0;
  Board.Key:=0;
  Board.PawnKey:=0;
  Board.MatKey:=0;
  Board.NonPawnMat[white]:=0;
  Board.NonPawnMat[black]:=0;
  Board.PstMid:=0;
  Board.PstEnd:=0;
  Board.nullcnt:=0;
end;

Procedure SetBoard(FEN : ansistring; var Board:TBoard);
// Устанавливает доску по FEN
var
  x,y,i,sq,j : integer;
  str : ansistring;
begin
  ClearBoard(Board);
  //1 . Устанавливаем фигуры
  x:=1;y:=8;i:=1;
  while FEN[i]<>' ' do
   begin
     sq:=pboard[x*10+y];
     case FEN[i] of

       'K' : begin
               Board.KingSq[White]:=sq;
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=King;
             end;
       'Q' : begin
               Board.Pieses[Queen]:=Board.Pieses[Queen] or Only[sq];
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=Queen;
             end;
       'R' : begin
               Board.Pieses[Rook]:=Board.Pieses[Rook] or Only[sq];
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=Rook;
             end;
       'B' : begin
               Board.Pieses[Bishop]:=Board.Pieses[Bishop] or Only[sq];
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=Bishop;
             end;
       'N' : begin
               Board.Pieses[Knight]:=Board.Pieses[Knight] or Only[sq];
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=Knight;
             end;
       'P' : begin
               Board.Pieses[Pawn]:=Board.Pieses[Pawn] or Only[sq];
               Board.Occupancy[white]:=Board.Occupancy[white] or Only[sq];
               Board.Pos[sq]:=Pawn;
             end;
       'k' : begin
               Board.KingSq[Black]:=sq;
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-King;
             end;
       'q' : begin
               Board.Pieses[Queen]:=Board.Pieses[Queen] or Only[sq];
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-Queen;
             end;
       'r' : begin
               Board.Pieses[Rook]:=Board.Pieses[Rook] or Only[sq];
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-Rook;
             end;
       'b' : begin
               Board.Pieses[Bishop]:=Board.Pieses[Bishop] or Only[sq];
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-Bishop;
             end;
       'n' : begin
               Board.Pieses[Knight]:=Board.Pieses[Knight] or Only[sq];
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-Knight;
             end;
       'p' : begin
               Board.Pieses[Pawn]:=Board.Pieses[Pawn] or Only[sq];
               Board.Occupancy[black]:=Board.Occupancy[black] or Only[sq];
               Board.Pos[sq]:=-Pawn;
             end;
       '/' : begin
               dec(y);
               x:=0;
             end;

       '1' : x:=x+0;
       '2' : x:=x+1;
       '3' : x:=x+2;
       '4' : x:=x+3;
       '5' : x:=x+4;
       '6' : x:=x+5;
       '7' : x:=x+6;
       '8' : x:=x+7;

     end; //case
    inc(x);
    inc(i);
   end; //while
   Board.AllPieses:=Board.Occupancy[white] or Board.Occupancy[black];
   inc(i); // После пробела
  // 2. Очередь хода
  if FEN[i]='w' then
    begin
     Board.SideToMove:=white;
     Board.CheckersBB:=SquareAttackedBB(Board.KingSq[white],Board.AllPieses,Board) and Board.Occupancy[black];
    end
        else
    begin
      Board.SideToMove:=black;
      Board.CheckersBB:=SquareAttackedBB(Board.KingSq[black],Board.AllPieses,Board) and Board.Occupancy[white];
    end;
  inc(i,2); // После пробела
  // 3. Рокировки
  while FEN[i]<>' ' do
    begin
      case FEN[i] of
        'K' : Board.CastleRights:=Board.CastleRights or WhiteShortCastleMask;
        'Q' : Board.CastleRights:=Board.CastleRights or WhiteLongCastleMask;
        'k' : Board.CastleRights:=Board.CastleRights or BlackShortCastleMask;
        'q' : Board.CastleRights:=Board.CastleRights or BlackLongCastleMask;
        '-' : Board.CastleRights:=0;
      end;
      inc(i);
    end;
  inc(i); // После пробела
  // 4. Взятие на проходе
  if FEN[i]<>'-' then
    begin
     for j:=a1 to h8 do
       if (FEN[i]+FEN[i+1])=DecodeSQ[j] then
         begin
           Board.EnPassSq:=j;
           break;
         end;
     inc(i); // переходим на второй символ двухсимвольного поля
    end;
  inc(i,2); // После пробела
  // 5. Счетчик полуходов
  if i<=length(FEN) then
   begin
    str:='';
    while FEN[i]<>' ' do
     begin
      str:=str+FEN[i];
      inc(i);
     end;
    Board.Rule50:=strtoint(string(trim(str)));
   end;
    inc(i); // После пробела
  //6. Счетчик целых ходов
  if i<=length(FEN) then
   begin
    str:='';
    for j:=i to length(FEN) do
     begin
      str:=str+FEN[i];
      inc(i);
     end;
     Board.MoveNum:=StrToInt(trim(str));
   end;
  Board.Key:=CalcFullKey(Board);
  Board.PawnKey:=CalcFullPawnKey(Board);
  Board.MatKey:=CalcFullMatKey(Board);
  Board.NonPawnMat[white]:=CalcNonPawnMat(white,Board);
  Board.NonPawnMat[black]:=CalcNonPawnMat(black,Board);
  CalcFullPST(Board.PstMid,Board.PstEnd,Board);
  Threads[1].Board.nullcnt:=Threads[1].Board.Rule50;
end;

procedure PrintBoard(Board : TBoard);
  // Процедура печати доски на экран в символьном виде
  var
    BitMassiv : array[1..64] of char; // Массив символов для печати доски
    i,j: byte;
    s: ansistring;
  begin
    for i:=a1 to h8 do
      begin
       // Заполняем следующую ячейку массива соответствующим символом
        case Board.Pos[i] of
          King        : BitMassiv[i+1]:='K';
          Queen       : BitMassiv[i+1]:='Q';
          Rook        : BitMassiv[i+1]:='R';
          Bishop      : BitMassiv[i+1]:='B';
          Knight      : BitMassiv[i+1]:='N';
          Pawn        : BitMassiv[i+1]:='P';
          Empty       : BitMassiv[i+1]:='.';
          -King       : BitMassiv[i+1]:='k';
          -Queen      : BitMassiv[i+1]:='q';
          -Rook       : BitMassiv[i+1]:='r';
          -Bishop     : BitMassiv[i+1]:='b';
          -Knight     : BitMassiv[i+1]:='n';
          -Pawn       : BitMassiv[i+1]:='p';
        end;
      end;
    // Печатаем соответствующий массив в виде доски
    for j:=7 downto 0 do
      begin
        write(j+1,'  '); // Подписываем горизонтали
        for i:=1 to 8 do
          write(BitMassiv[j*8+i]);
        writeln;
      end;
    //И подписываем вертикали
    writeln('   abcdefgh');
   // Печатаем другую информацию:
   if Board.SideToMove=white
     then s:='White move '
     else s:='Black move ';
   if Board.EnPassSq<>NonSq then s:=s+'EnPass-'+DecodeSQ[Board.EnPassSq]+' ';
   if (Board.CastleRights and WhiteShortCastleMask)<>0 then s:=s+'W0-0 ';
   if (Board.CastleRights and WhiteLongCastleMask)<>0 then s:=s+'W0-0-0 ';
   if (Board.CastleRights and BlackShortCastleMask)<>0 then s:=s+'B0-0 ';
   if (Board.CastleRights and BlackLongCastleMask)<>0 then s:=s+'B0-0-0 ';
   s:=s+Inttostr(Board.Rule50)+' '+inttostr(Board.MoveNum);
   writeln(s);
  end;
Function CalcNonPawnMat(color:integer;var Board:TBoard):integer;
var
  temp:TBitBoard;
  sq:integer;
begin
  result:=0;
  temp:=Board.Occupancy[color] and (not (Board.Pieses[pawn] or Only[Board.KingSq[color]]));
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      result:=result+PiesetypValue[TypOfPiese[Board.Pos[sq]]];
      temp:=temp and (temp-1);
    end;
end;
Function StringMove(move:integer):shortstring;
// Текст хода
var
  s:ansistring;
begin
  s:=DecodeSQ[move and 63];
  s:=s+DecodeSq[(move shr 6) and 63];
  if (move and PromoteFlag)<>0 then
    case (move shr 12) and 7 of
      knight : s:=s+'n';
      bishop : s:=s+'b';
      rook   : s:=s+'r';
      queen  : s:=s+'q';
    end;
  Result:=s;
end;

Procedure AddPawnPseudoMoves(delta:integer;BB:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список ходов по ранее сгенерированному битборду ходов пешек.  НЕ Ставит флаг взятия. Не работает с превращениями
var
  sq:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      MList[cnt].move:=(sq shl 6) or (sq+delta);
      inc(cnt);
      BB:=BB and (BB-1);
    end;
end;


Procedure AddPawnPseudoCaptures(delta:integer;BB:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список взятий по ранее сгенерированному битборду . Ставит флаг взятия. Не работает с превращениями
var
  sq:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      MList[cnt].move:=CaptureFlag or (sq shl 6) or (sq+delta);
      inc(cnt);
      BB:=BB and (BB-1);
    end;
end;
Procedure AddPawnPseudoPromos(delta:integer;typ:integer;BB:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список ходов по ранее сгенерированному битборду ходов пешек-превращений.  НЕ Ставит флаг взятия.
var
  sq,promo:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      promo:=(sq shl 6) or (sq+delta);
      if typ=AllPromos then
        begin
          // Все превращения
          MList[cnt].move:=promo or (Queen shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Knight shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Rook shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Bishop shl 12);
          inc(cnt);
        end else
      if typ=StrongPromo then
        begin
          // Только ферзь
          MList[cnt].move:=promo or (Queen shl 12);
          inc(cnt);
        end else
        begin
          // Слабые превращения
          MList[cnt].move:=promo or (Knight shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Rook shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Bishop shl 12);
          inc(cnt);
        end;
      BB:=BB and (BB-1);
    end;
end;
Procedure AddPawnPseudoCapPromos(delta:integer;typ:integer;BB:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список ходов по ранее сгенерированному битборду взятий пешек-превращений.Ставит флаг взятия.
var
  sq,promo:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      promo:=CaptureFlag or (sq shl 6) or (sq+delta);
      if typ=AllPromos then
        begin
          // Все превращения
          MList[cnt].move:=promo or (Queen shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Knight shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Rook shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Bishop shl 12);
          inc(cnt);
        end else
      if typ=StrongPromo then
        begin
          // Только ферзь
          MList[cnt].move:=promo or (Queen shl 12);
          inc(cnt);
        end else
        begin
          // Слабые превращения
          MList[cnt].move:=promo or (Knight shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Rook shl 12);
          inc(cnt);
          MList[cnt].move:=promo or (Bishop shl 12);
          inc(cnt);
        end;
      BB:=BB and (BB-1);
    end;
end;
Procedure AddPseudoMoves(from:integer;BB:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список ходов по ранее сгенерированному битборду ходов фигур.  НЕ Ставит флаг взятия. Не работает с пешками (превращениями)
var
  sq:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      MList[cnt].move:=(sq shl 6) or from;
      inc(cnt);
      BB:=BB and (BB-1);
    end;
end;

Procedure AddPseudoCaptures(from:integer;BB:TBitBoard;var cnt:integer;var Board:TBoard;var MList:TmoveList);inline;
// Процедура заполняет список взятий по ранее сгенерированному битборду ходов фигур.Ставит флаг взятия. Не работает с пешками (превращениями)
var
  sq:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      MList[cnt].move:=CaptureFlag or (sq shl 6) or from;
      inc(cnt);
      BB:=BB and (BB-1);
    end;
end;
Procedure AddPseudoAll(from:integer;BB:TBitBoard;AllPieses:TBitBoard;var cnt:integer;var MList:TmoveList);inline;
// Процедура заполняет список ходов по ранее сгенерированному битборду ходов фигур.Ставит флаг взятия если надо. Не работает с пешками (превращениями)
var
  sq:integer;
begin
  while BB<>0 do
    begin
      sq:=BitScanForward(BB);
      MList[cnt].move:=(sq shl 6) or from;
      if (AllPieses and Only[sq])<>0 then Mlist[cnt].move:=Mlist[cnt].move or CaptureFlag;
      inc(cnt);
      BB:=BB and (BB-1);
    end;
end;

Function GeneratePseudoMoves(beg:integer;Target:TBitBoard;var Board:TBoard;var MList:TMoveList):integer;
// Генерирует  тихие псевдоходы за сторону чья очередь хода на поля, указанные в Target; Возвращает число записанных в список ходов
var
 from:integer;
 temp,PawnSingle,PawnDouble,PawnOn7,PawnNon7 : TBitBoard;
 cnt : integer;
begin
  cnt:=beg;
  temp:=Board.Pieses[Knight] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoMoves(from,(KnightAttacksBB(from) and Target),cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Bishop] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoMoves(from,(BishopAttacksBB(from,Board.AllPieses) and Target),cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Rook] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoMoves(from,(RookAttacksBB(from,Board.AllPieses) and Target),cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Queen] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoMoves(from,(QueenAttacksBB(from,Board.AllPieses) and Target),cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  AddPseudoMoves(Board.KingSq[Board.SideToMove],(KingAttacksBB(Board.KingSq[Board.SideToMove]) and Target),cnt,Mlist);
  if Board.SideToMove=White then
   begin
     // Рокировки
     if ((Board.CastleRights and WhiteShortCastleMask)<>0) and ((Board.AllPieses and W00SQ)=0) and ((SquareAttackedBB(f1,Board.AllPieses,Board) and Board.Occupancy[black])=0)  then
       begin
        MList[cnt].move:=(g1 shl 6) or e1;
        inc(cnt);
       end;
     if ((Board.CastleRights and WhiteLongCastleMask)<>0) and ((Board.AllPieses and W000SQ)=0) and ((SquareAttackedBB(d1,Board.AllPieses,Board) and Board.Occupancy[black])=0)  then
       begin
        MList[cnt].move:=(c1 shl 6) or e1;
        inc(cnt);
       end;
     // Пешки
     PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[white] and (not RanksBB[7]);
     // Простые ходы
     PawnSingle:=(PawnNon7 shl 8) and Target;
     AddPawnPseudoMoves(-8,PawnSingle,cnt,Mlist);
     // Двойные ходы
     PawnDouble:=((PawnSingle and RanksBB[3]) shl 8) and Target;
     AddPawnPseudoMoves(-16,PawnDouble,cnt,Mlist);
     //превращения
     PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[white] and RanksBB[7];
     AddPawnPseudoPromos(-8,WeakPromos,((PawnOn7 shl 8) and Target),cnt,Mlist);
   end else
   begin
      // Рокировки
     if ((Board.CastleRights and BlackShortCastleMask)<>0) and ((Board.AllPieses and B00SQ)=0) and ((SquareAttackedBB(f8,Board.AllPieses,Board) and Board.Occupancy[white])=0)  then
       begin
        MList[cnt].move:=(g8 shl 6) or e8;
        inc(cnt);
       end;
     if ((Board.CastleRights and BlackLongCastleMask)<>0) and ((Board.AllPieses and B000SQ)=0) and ((SquareAttackedBB(d8,Board.AllPieses,Board) and Board.Occupancy[white])=0)  then
       begin
        MList[cnt].move:=(c8 shl 6) or e8;
        inc(cnt);
       end;
      // Пешки
     PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[black] and (not RanksBB[2]);
     // Простые ходы
     PawnSingle:=(PawnNon7 shr 8) and Target;
     AddPawnPseudoMoves(8,PawnSingle,cnt,Mlist);
     // Двойные ходы
     PawnDouble:=((PawnSingle and RanksBB[6]) shr 8) and Target;
     AddPawnPseudoMoves(16,PawnDouble,cnt,Mlist);
     //превращения
     PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[black] and RanksBB[2];
     AddPawnPseudoPromos(8,WeakPromos,((PawnOn7 shr 8) and Target),cnt,Mlist);
   end;
 Result:=cnt-beg;
end;

Function GeneratePseudoCaptures(beg:integer;Target:TBitBoard;var Board:TBoard;var MList:TMoveList):integer;
// Генерирует псевдовзятия за сторону чья очередь хода на поля, указанные в Target; Возвращает число записанных в список взятий
var
 from:integer;
 temp,PawnOn7,PawnNon7,PawnCaps : TBitBoard;
 cnt : integer;
begin
  cnt:=beg;
  temp:=Board.Pieses[Knight] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoCaptures(from,(KnightAttacksBB(from) and Target),cnt,Board,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Bishop] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoCaptures(from,(BishopAttacksBB(from,Board.AllPieses) and Target),cnt,Board,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Rook] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoCaptures(from,(RookAttacksBB(from,Board.AllPieses) and Target),cnt,Board,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Queen] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoCaptures(from,(QueenAttacksBB(from,Board.AllPieses) and Target),cnt,Board,Mlist);
    temp:=temp and (temp-1);
   end;
  AddPseudoCaptures(Board.KingSq[Board.SideToMove],(KingAttacksBB(Board.KingSq[Board.SideToMove]) and Target),cnt,Board,Mlist);
  if Board.SideToMove=White then
   begin
      // Взятия пешками без превращения (в том числе на проходе)
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[white] and (not RanksBB[7]);
      PawnCaps:=((PawnNon7 and (not FilesBB[1])) shl 7) and (Target or Only[Board.EnPassSq]);
      AddPawnPseudoCaptures(-7,PawnCaps,cnt,Mlist);
      PawnCaps:=((PawnNon7 and (not FilesBB[8])) shl 9) and (Target or Only[Board.EnPassSq]);
      AddPawnPseudoCaptures(-9,PawnCaps,cnt,Mlist);
      // Превращения со взятием
      PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[white] and RanksBB[7];
      PawnCaps:=((PawnOn7 and (not FilesBB[1])) shl 7) and Target;
      AddPawnPseudoCapPromos(-7,AllPromos,PawnCaps,cnt,MList);
      PawnCaps:=((PawnOn7 and (not FilesBB[8])) shl 9) and Target;
      AddPawnPseudoCapPromos(-9,AllPromos,PawnCaps,cnt,MList);
      // Превращения без взятия
      AddPawnPseudoPromos(-8,StrongPromo,((PawnOn7 shl 8) and (not Board.AllPieses)),cnt,Mlist);
   end else
   begin
      // Взятия пешками без превращения (в том числе на проходе)
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[black] and (not RanksBB[2]);
      PawnCaps:=((PawnNon7 and (not FilesBB[1])) shr 9) and (Target or Only[Board.EnPassSq]);
      AddPawnPseudoCaptures(9,PawnCaps,cnt,Mlist);
      PawnCaps:=((PawnNon7 and (not FilesBB[8])) shr 7) and (Target or Only[Board.EnPassSq]);
      AddPawnPseudoCaptures(7,PawnCaps,cnt,Mlist);
      // Превращения со взятием
      PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[black] and RanksBB[2];
      PawnCaps:=((PawnOn7 and (not FilesBB[1])) shr 9) and Target;
      AddPawnPseudoCapPromos(9,AllPromos,PawnCaps,cnt,MList);
      PawnCaps:=((PawnOn7 and (not FilesBB[8])) shr 7) and Target;
      AddPawnPseudoCapPromos(7,AllPromos,PawnCaps,cnt,MList);
      // Превращения без взятия
      AddPawnPseudoPromos(8,StrongPromo,((PawnOn7 shr 8) and (not Board.AllPieses)),cnt,Mlist);
   end;
 Result:=cnt-beg;
end;

Function GeneratePseudoEscapes(beg:integer;var Board:TBoard;var MList:TMoveList):integer;
// Генерирует псевдозащиты от шаха за сторону чья очередь хода.  в Target поля, где можно закрыться (побить). Возвращает число записанных в список взятий
var
 from,MyColor,EnemyColor,KingSq,CheckSq:integer;
 temp,PawnOn7,PawnNon7,PawnCaps,Sliders,SlidersAttacksBB,Target,PawnSingle,PawnDouble,BB : TBitBoard;
 cnt : integer;
begin
  // Инициализация
  cnt:=beg;
  MyColor:=Board.SideToMove;
  EnemyColor:=MyColor xor 1;
  KingSq:=Board.KingSq[MyColor];
  SlidersAttacksBB:=0;
  Sliders:=Board.CheckersBB and (Board.Pieses[Bishop] or Board.Pieses[Rook] or Board.Pieses[Queen]) and Board.Occupancy[MyColor xor 1];
  // вычисляем всем атакованные дальнобойными шахующими фигурами поля. Мы их исключим потом при определении псевдолегальных полей  ухода короля
  While Sliders<>0 do
    begin
      from:=BitScanForward(Sliders);
      SlidersAttacksBB:=(SlidersAttacksBB or FullLine[KingSq,from]) xor Only[from];
      Sliders:=Sliders and (Sliders-1);
    end;
  // Смотрим сначала уходы короля
  temp:=KingAttacks[KingSq] and (not Board.Occupancy[MyColor]) and (not SlidersAttacksBB);
  AddPseudoAll(KingSq,temp,Board.AllPieses,cnt,MList);
  // Если двойной шах, то больше ничего не генерим
  If (Board.CheckersBB and (Board.CheckersBB-1))<>0 then
    begin
      Result:=cnt-beg;
      exit;
    end;
  // Пробуем теперь закрыться или побить единственную шахующую фигуру
  CheckSq:=BitScanForward(Board.CheckersBB);
  Target:=Intersect[KingSq,CheckSq] or Only[CheckSq];
  temp:=Board.Pieses[Knight] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoAll(from,(KnightAttacksBB(from) and Target),Board.AllPieses,cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Bishop] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoAll(from,(BishopAttacksBB(from,Board.AllPieses) and Target),Board.AllPieses,cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Rook] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoAll(from,(RookAttacksBB(from,Board.AllPieses) and Target),Board.AllPieses,cnt,Mlist);
    temp:=temp and (temp-1);
   end;
  temp:=Board.Pieses[Queen] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    AddPseudoAll(from,(QueenAttacksBB(from,Board.AllPieses) and Target),Board.AllPieses,cnt,Mlist);
    temp:=temp and (temp-1);
   end;

  if Board.SideToMove=White then
   begin
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[white] and (not RanksBB[7]);
      // Простые ходы
      PawnSingle:=(PawnNon7 shl 8) and (not Board.AllPieses);
      AddPawnPseudoMoves(-8,PawnSingle and  Target,cnt,Mlist);
     // Двойные ходы
      PawnDouble:=((PawnSingle and RanksBB[3]) shl 8) and (not Board.AllPieses) and Target;
      AddPawnPseudoMoves(-16,PawnDouble,cnt,Mlist);
      // Взятия пешками без превращения
      PawnCaps:=((PawnNon7 and (not FilesBB[1])) shl 7) and  Board.CheckersBB;
      AddPawnPseudoCaptures(-7,PawnCaps,cnt,Mlist);
      PawnCaps:=((PawnNon7 and (not FilesBB[8])) shl 9) and Board.CheckersBB;
      AddPawnPseudoCaptures(-9,PawnCaps,cnt,Mlist);
      // Взятие на проходе как защита от шаха
      if (Board.EnPassSq<>NonSq) and ((Board.CheckersBB and Only[Board.EnPassSq-8])<>0) then
       begin
        BB:=PawnAttacks[black,Board.EnPassSq] and PawnNon7;
        while BB<>0 do
          begin
            from:=BitScanForward(BB);
            MList[cnt].move:=CaptureFlag or (Board.EnPassSq shl 6) or from;
            inc(cnt);
            BB:=BB and (BB-1);
          end;
       end;
      // Превращения со взятием
      PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[white] and RanksBB[7];
      PawnCaps:=((PawnOn7 and (not FilesBB[1])) shl 7) and (Board.Occupancy[EnemyColor]) and Target;
      AddPawnPseudoCapPromos(-7,AllPromos,PawnCaps,cnt,MList);
      PawnCaps:=((PawnOn7 and (not FilesBB[8])) shl 9) and (Board.Occupancy[EnemyColor]) and Target;
      AddPawnPseudoCapPromos(-9,AllPromos,PawnCaps,cnt,MList);
      // Превращения без взятия
      AddPawnPseudoPromos(-8,AllPromos,((PawnOn7 shl 8) and (not Board.AllPieses)) and Target,cnt,Mlist);
   end else
   begin
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[black] and (not RanksBB[2]);
      // Простые ходы
      PawnSingle:=(PawnNon7 shr 8) and (not Board.AllPieses);
      AddPawnPseudoMoves(8,PawnSingle and  Target,cnt,Mlist);
     // Двойные ходы
      PawnDouble:=((PawnSingle and RanksBB[6]) shr 8) and (not Board.AllPieses) and Target;
      AddPawnPseudoMoves(16,PawnDouble,cnt,Mlist);
      // Взятия пешками без превращения
      PawnCaps:=((PawnNon7 and (not FilesBB[1])) shr 9) and  Board.CheckersBB;
      AddPawnPseudoCaptures(9,PawnCaps,cnt,Mlist);
      PawnCaps:=((PawnNon7 and (not FilesBB[8])) shr 7) and  Board.CheckersBB;
      AddPawnPseudoCaptures(7,PawnCaps,cnt,Mlist);
      // Взятие на проходе как защита от шаха
      if (Board.EnPassSq<>NonSq) and ((Board.CheckersBB and Only[Board.EnPassSq+8])<>0) then
       begin
        BB:=PawnAttacks[white,Board.EnPassSq] and PawnNon7;
        while BB<>0 do
          begin
            from:=BitScanForward(BB);
            MList[cnt].move:=CaptureFlag or (Board.EnPassSq shl 6) or from;
            inc(cnt);
            BB:=BB and (BB-1);
          end;
       end;
      // Превращения со взятием
      PawnOn7:=Board.Pieses[Pawn] and Board.Occupancy[black] and RanksBB[2];
      PawnCaps:=((PawnOn7 and (not FilesBB[1])) shr 9) and (Board.Occupancy[EnemyColor]) and Target;
      AddPawnPseudoCapPromos(9,AllPromos,PawnCaps,cnt,MList);
      PawnCaps:=((PawnOn7 and (not FilesBB[8])) shr 7) and (Board.Occupancy[EnemyColor]) and Target;
      AddPawnPseudoCapPromos(7,AllPromos,PawnCaps,cnt,MList);
      // Превращения без взятия
      AddPawnPseudoPromos(8,AllPromos,((PawnOn7 shr 8) and (not Board.AllPieses)) and Target,cnt,Mlist);
   end;
 Result:=cnt-beg;
end;

Function GeneratePseudoChecks(beg:integer; Target:TBitBoard; var Board:TBoard; var CheckInfo:TCheckInfo; var MList:TmoveList):integer;
// Генерирует тихие (не взятия и не превращения) псевдошахи. Возвращает число записанных в список шахов
var
 from,PieseTyp:integer;
 temp,PawnNon7,PawnSingle,PawnDouble,BB,BB1,CC,CC1 : TBitBoard;
 cnt : integer;
begin
  // Инициализация
  cnt:=beg;
  // Сначала пробуем давать вскрытые шахи
  Temp:=CheckInfo.DiscoverCheckBB;
  while temp<>0 do
    begin
      from:=BitScanForward(temp);
      temp:=temp and (temp-1);
      PieseTyp:=TypOfPiese[Board.Pos[from]];
      If PieseTyp=Pawn then continue; // Будем дальше рассматривать ходы пешек
      BB:=PieseAttacksBB(Board.SideToMove,PieseTyp,from,Board.AllPieses) and (not Board.AllPieses);
      if PieseTyp=King then BB:=BB and (not QueenFullAttacks[CheckInfo.EnemyKingSq]);
      AddPseudoMoves(from,BB,cnt,MList);
    end;
  // Теперь прямые шахи
  temp:=Board.Pieses[Knight] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    temp:=temp and (temp-1);
    if (CheckInfo.DiscoverCheckBB and Only[from])<>0 then continue;
    AddPseudoMoves(from,(KnightAttacksBB(from) and Target and CheckInfo.DirectCheckBB[Knight]),cnt,Mlist);
   end;
  temp:=Board.Pieses[Bishop] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    temp:=temp and (temp-1);
    if (CheckInfo.DiscoverCheckBB and Only[from])<>0 then continue;
    if (BishopFullAttacks[from] and target and CheckInfo.DirectCheckBB[bishop])=0 then continue;
    AddPseudoMoves(from,(BishopAttacksBB(from,Board.AllPieses) and Target and CheckInfo.DirectCheckBB[bishop]),cnt,Mlist);
   end;
  temp:=Board.Pieses[Rook] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    temp:=temp and (temp-1);
    if (CheckInfo.DiscoverCheckBB and Only[from])<>0 then continue;
    if (RookFullAttacks[from] and target and CheckInfo.DirectCheckBB[rook])=0 then continue;
    AddPseudoMoves(from,(RookAttacksBB(from,Board.AllPieses) and Target and CheckInfo.DirectCheckBB[rook]),cnt,Mlist);
   end;
  temp:=Board.Pieses[Queen] and Board.Occupancy[Board.SideToMove];
  while temp<>0 do
   begin
    from:=BitScanForward(temp);
    temp:=temp and (temp-1);
    if (QueenFullAttacks[from] and target and CheckInfo.DirectCheckBB[queen])=0 then continue;
    AddPseudoMoves(from,(QueenAttacksBB(from,Board.AllPieses) and Target and CheckInfo.DirectCheckBB[queen]),cnt,Mlist);
   end;
  if Board.SideToMove=White then
   begin
     // Рокировки
     if ((Board.CastleRights and WhiteShortCastleMask)<>0) and ((Board.AllPieses and W00SQ)=0) and ((SquareAttackedBB(f1,Board.AllPieses,Board) and Board.Occupancy[black])=0)  then
       begin
        if (RookAttacksBB(f1,(Board.AllPieses xor Only[e1])) and Only[CheckInfo.EnemyKingSq])<>0 then
         begin
          MList[cnt].move:=(g1 shl 6) or e1;
          inc(cnt);
         end;
       end;
     if ((Board.CastleRights and WhiteLongCastleMask)<>0) and ((Board.AllPieses and W000SQ)=0) and ((SquareAttackedBB(d1,Board.AllPieses,Board) and Board.Occupancy[black])=0)  then
       begin
        if (RookAttacksBB(d1,(Board.AllPieses xor Only[e1])) and Only[CheckInfo.EnemyKingSq])<>0 then
         begin
          MList[cnt].move:=(c1 shl 6) or e1;
          inc(cnt);
         end;
       end;
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[white] and (not RanksBB[7]);
      // Простые ходы
      PawnSingle:=(PawnNon7 shl 8) and (not Board.AllPieses);
      // Двойные ходы
      PawnDouble:=((PawnSingle and RanksBB[3]) shl 8) and (not Board.AllPieses) and Target;
      BB:=PawnAttacks[Board.SideToMove xor 1,CheckInfo.EnemyKingSq] and PawnSingle;
      BB1:=PawnAttacks[Board.SideToMove xor 1,CheckInfo.EnemyKingSq] and PawnDouble;
      if (PawnNon7 and CheckInfo.DiscoverCheckBB)<>0 then
        begin
          CC:=((PawnNon7 and CheckInfo.DiscoverCheckBB) shl 8) and (not Board.AllPieses) and (not FilesBB[Posx[CheckInfo.EnemyKingSq]]);
          CC1:=((CC and RanksBB[3]) shl 8) and (not Board.AllPieses);
          BB:=BB or CC;
          BB1:=BB1 or CC1;
        end;
      AddPawnPseudoMoves(-8,BB,cnt,Mlist);
      AddPawnPseudoMoves(-16,BB1,cnt,Mlist);
   end else
   begin
      // Рокировки
     if ((Board.CastleRights and BlackShortCastleMask)<>0) and ((Board.AllPieses and B00SQ)=0) and ((SquareAttackedBB(f8,Board.AllPieses,Board) and Board.Occupancy[white])=0)  then
       begin
        if (RookAttacksBB(f8,(Board.AllPieses xor Only[e8])) and Only[CheckInfo.EnemyKingSq])<>0 then
         begin
          MList[cnt].move:=(g8 shl 6) or e8;
          inc(cnt);
         end;
       end;
     if ((Board.CastleRights and BlackLongCastleMask)<>0) and ((Board.AllPieses and B000SQ)=0) and ((SquareAttackedBB(d8,Board.AllPieses,Board) and Board.Occupancy[white])=0)  then
       begin
        if (RookAttacksBB(d8,(Board.AllPieses xor Only[e8])) and Only[CheckInfo.EnemyKingSq])<>0 then
         begin
          MList[cnt].move:=(c8 shl 6) or e8;
          inc(cnt);
         end;
       end;
      PawnNon7:=Board.Pieses[Pawn] and Board.Occupancy[black] and (not RanksBB[2]);
      // Простые ходы
      PawnSingle:=(PawnNon7 shr 8) and (not Board.AllPieses);
      // Двойные ходы
      PawnDouble:=((PawnSingle and RanksBB[6]) shr 8) and (not Board.AllPieses) and Target;
      BB:=PawnAttacks[Board.SideToMove xor 1,CheckInfo.EnemyKingSq] and PawnSingle;
      BB1:=PawnAttacks[Board.SideToMove xor 1,CheckInfo.EnemyKingSq] and PawnDouble;
      if (PawnNon7 and CheckInfo.DiscoverCheckBB)<>0 then
        begin
          CC:=((PawnNon7 and CheckInfo.DiscoverCheckBB) shr 8) and (not Board.AllPieses) and (not FilesBB[Posx[CheckInfo.EnemyKingSq]]);
          CC1:=((CC and RanksBB[6]) shr 8) and (not Board.AllPieses);
          BB:=BB or CC;
          BB1:=BB1 or CC1;
        end;
      AddPawnPseudoMoves(8,BB,cnt,Mlist);
      AddPawnPseudoMoves(16,BB1,cnt,Mlist);
   end;
 Result:=cnt-beg;
end;

Function GenerateLegals(beg:integer;var Board:TBoard;var MList:TMoveList):integer;
// Генерирует легальные ходы. Используется для теста perft
var
  PinnedBB : TBitBoard;
  KingSq,cnt,m,i : integer;
  FullList : TMoveList;
begin
  cnt:=beg;
  KingSq:=Board.KingSq[Board.SideToMove];
  PinnedBB:=FindPinners(Board.SideToMove,Board.SideToMove,Board);
  If Board.CheckersBB<>0
    then m:=GeneratePseudoEscapes(0,Board,FullList)
    else begin
           m:=GeneratePseudoCaptures(0,Board.Occupancy[Board.SideToMove xor 1],Board,FullList);
           m:=m+GeneratePseudoMoves(m,not Board.AllPieses,Board,FullList);
         end;
// Выбираем только легальные ходы из только что сгенерированных
 i:=0;
 while i<m do
   begin
     if ((PinnedBB<>0) or ((FullList[i].move and 63)=KingSq) or (((FullList[i].move and CaptureFlag)<>0) and (Board.Pos[(FullList[i].move shr 6) and 63]=Empty))) then
       begin
        if isLegal(FullList[i].move,PinnedBB,Board) then
           begin
             MList[cnt].move:=FullList[i].move;
             inc(cnt);
           end;
       end else
       begin
        MList[cnt].move:=FullList[i].move;
        inc(cnt);
       end;
     inc(i);
   end;
 Result:=cnt-beg;
end;

Procedure MovePiese(Color:integer;FromSq:integer;DestSq:integer;Piese:integer;PieseTyp:integer;var Board:TBoard);inline;
var
  mask : TBitBoard;
begin
  Board.Pos[FromSq]:=Empty;
  Board.Pos[DestSq]:=Piese;
  mask:=Only[FromSq] or Only[DestSq];
  Board.Occupancy[color]:=Board.Occupancy[color] xor mask;
  Board.AllPieses:=Board.AllPieses xor mask;
  if (Piesetyp<>King)
    then Board.Pieses[PieseTyp] := Board.Pieses[PieseTyp] xor mask
    else Board.KingSq[Color]:=DestSq;
end;

Procedure RemovePiese(Color:integer;CapSq:integer;Capturedtyp:integer;var Board:TBoard);inline;
var
  mask : TBitBoard;
begin
  Board.Pos[CapSq]:=Empty;
  mask:=not Only[CapSq];
  Board.Pieses[Capturedtyp] := Board.Pieses[Capturedtyp] and mask;
  Board.Occupancy[color]:=Board.Occupancy[color] and mask;
  Board.AllPieses:=Board.AllPieses and mask;
end;

Procedure SetPiese(color:integer;DestSq:integer;Piese:integer;PieseTyp:integer;var Board:TBoard);inline;
var
  mask : TBitBoard;
begin
  Board.Pos[DestSq]:=Piese;
  mask:=Only[DestSq];
  Board.Pieses[PieseTyp]:=Board.Pieses[PieseTyp] or mask;
  Board.Occupancy[color]:=Board.Occupancy[color] or mask;
  Board.AllPieses:=Board.AllPieses or mask;
end;
Procedure SetUndo(var Board:TBoard;var Undo:TUndo);inline;
begin
  // Сохраняем данные в структуру Undo.
  Undo.EnPassSq:=Board.EnPassSq;
  Undo.CastleRights:=Board.CastleRights;
  Undo.Rule50:=Board.Rule50;
  Undo.CheckersBB:=Board.CheckersBB;
  Undo.CapturedPiese:=Board.CapturedPiese;
  Undo.Key:=Board.Key;
  Undo.PawnKey:=Board.PawnKey;
  Undo.MatKey:=Board.MatKey;
  Undo.NonPawnMat[white]:=Board.NonPawnMat[white];
  Undo.NonPawnMat[black]:=Board.NonPawnMat[black];
  Undo.PstMid:=Board.PstMid;
  undo.PstEnd:=Board.PstEnd;
  undo.nullcnt:=Board.nullcnt;
end;
Procedure MakeMove(move : integer;var Board:TBoard;var Undo:TUndo;isCheck:boolean);  inline;
// Процедура делает ход на доске
var
  MyColor,EnemyColor,FromSq,DestSq,Piese,PieseTyp,Captured,CapturedTyp,CapSq,RookFromSq,RookDestSq,PromoPiese,PromoPieseTyp,cnt : integer;
  Key : int64;
begin
  // Инициализация
  MyColor:=Board.SideToMove;
  EnemyColor:=MyColor xor 1;
  Undo.isCapture:=(move and CaptureFlag)<>0;
  FromSQ:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[FromSq];
  PieseTyp:=TypOfPiese[Piese];
  Captured:=Board.Pos[DestSq];
  Undo.isEnnPass:=Undo.isCapture and (Captured=Empty);
  Undo.isCastle:=(PieseTyp=King) and ((fromSq-destSq=2) or (DestSq-FromSq=2));
  Key:=Board.Key xor ZColor;
  // Увеличиваем счетчики
  inc(Board.Rule50);
  // Убираем побитую с доски
  if Undo.isCapture then
    begin
      Board.Rule50:=0;
      CapSq:=DestSq;
      if Undo.isEnnPass then
        begin
          CapSq:=DestSq-PawnPush[MyColor];
          Captured:=Board.Pos[CapSq];
        end;
      CapturedTyp:=TypOfPiese[Captured];
      if CapturedTyp=Pawn
        then Board.PawnKey:=Board.PawnKey xor PieseZobr[EnemyColor,pawn,CapSq]
        else Board.NonPawnMat[EnemyColor]:=Board.NonPawnMat[EnemyColor]-PieseTypValue[CapturedTyp];
      RemovePiese(EnemyColor,CapSq,CapturedTyp,Board);
      Key:=Key xor PieseZobr[EnemyColor,CapturedTyp,CapSq];
      cnt:=BitCount(Board.Pieses[CapturedTyp] and Board.Occupancy[EnemyColor]);
      Board.MatKey:=Board.MatKey xor MatZobr[EnemyColor,CapturedTyp,cnt] xor MatZobr[EnemyColor,CapturedTyp,cnt+1];
      Board.PstMid:=Board.PstMid-PiesePSTMid[EnemyColor,CapturedTyp,CapSq];
      Board.PstEnd:=Board.PstEnd-PiesePSTEnd[EnemyColor,CapturedTyp,CapSq];
    end;
  // Сбрасываем метку взятия на проходе
  if Board.EnPassSq<>NonSq then
    begin
     Key:=Key xor EnnPassZobr[Board.EnPassSq];
     Board.EnPassSq:=NonSq;
    end;
  // Обновляем флаг рокировок
  Board.CastleRights:=Board.CastleRights and CastleRightsSq[FromSq] and CastleRightsSq[DestSq];
  if (Undo.CastleRights<>Board.CastleRights) then Key:=Key xor CastleZobr[Undo.CastleRights] xor CastleZobr[Board.CastleRights];
  // Передвигаем фигуру, которая ходит.
  MovePiese(MyColor,FromSq,DestSq,Piese,PieseTyp,Board);
  Key:=Key xor PieseZobr[MyColor,PieseTyp,FromSq] xor PieseZobr[MyColor,PieseTyp,DestSq];
  Board.PstMid:=Board.PstMid-PiesePstMid[MyColor,PieseTyp,FromSq]+PiesePstMid[MyColor,PieseTyp,DestSq];
  Board.PstEnd:=Board.PstEnd-PiesePstEnd[MyColor,PieseTyp,FromSq]+PiesePstEnd[MyColor,PieseTyp,DestSq];
  // Если рокировка - двигаем вторую
  if Undo.isCastle then
    begin
      if DestSq-FromSq=2 then
        begin
         RookFromSq:=DestSq+1;
         RookDestSq:=FromSq+1;
        end else
        begin
         RookFromSq:=DestSq-2;
         RookDestSq:=FromSq-1;
        end;
      MovePiese(MyColor,RookFromSq,RookDestSq,Board.Pos[RookFromSq],Rook,Board);
      Key:=Key xor PieseZobr[MyColor,Rook,RookFromSq] xor PieseZobr[MyColor,Rook,RookDestSq];
      Board.PstMid:=Board.PstMid-PiesePstMid[MyColor,rook,RookFromSq]+PiesePstMid[Mycolor,rook,RookDestSq];
      Board.PstEnd:=Board.PstEnd-PiesePstEnd[MyColor,rook,RookFromSq]+PiesePstEnd[Mycolor,rook,RookDestSq];
    end;
  // Для пешек - дополнительная работа
  if (PieseTyp=Pawn) then
    begin
      Board.Rule50:=0;
      Board.PawnKey:=Board.PawnKey xor PieseZobr[MyColor,pawn,FromSq] xor PieseZobr[MyColor,pawn,DestSq];
      // Устанавливаем метку взятия на проходе в случае двойного хода пешкой
      if (FromSq-DestSq=16) or (FromSq-DestSq=-16) then
        begin
          Board.EnPassSq:=FromSq+PawnPush[MyColor];
          Key:=Key xor EnnPassZobr[Board.EnPassSq];
        end else
      if (move and PromoteFlag)<>0 then
        begin
          RemovePiese(MyColor,DestSq,Piesetyp,Board);
          PromoPieseTyp:=(move shr 12) and 7;
          If MyColor=white
            then PromoPiese:=PromoPieseTyp
            else PromoPiese:=-PromoPieseTyp;
          SetPiese(MyColor,DestSq,PromoPiese,PromoPieseTyp,Board);
          Key:=Key xor PieseZobr[MyColor,Pawn,DestSQ] xor PieseZobr[MyColor,PromoPieseTyp,DestSq];
          Board.PawnKey:=Board.PawnKey xor PieseZobr[MyColor,pawn,DestSq];
          cnt:=BitCount(Board.Pieses[Pawn] and Board.Occupancy[MyColor]);
          Board.MatKey:=Board.MatKey xor MatZobr[MyColor,pawn,cnt] xor MatZobr[MyColor,pawn,cnt+1];
          cnt:=BitCount(Board.Pieses[PromoPieseTyp] and Board.Occupancy[MyColor]);
          Board.MatKey:=Board.MatKey xor MatZobr[MyColor,PromoPieseTyp,cnt] xor MatZobr[MyColor,PromoPieseTyp,cnt-1];
          Board.NonPawnMat[MyColor]:=Board.NonPawnMat[MyColor]+PieseTypValue[PromoPieseTyp];
          Board.PstMid:=Board.PstMid+PiesePstMid[MyColor,PromoPieseTyp,DestSq];
          Board.PstEnd:=Board.PstEnd+PiesePstEnd[MyColor,PromoPieseTyp,DestSq];
        end;
    end;
  // Устанавливаем флажки после хода
  Board.Key:=Key;
  Board.SideToMove:=EnemyColor;
  Board.CapturedPiese:=Captured;
  inc(Board.nullcnt);
  if isCheck
    then Board.CheckersBB:=SquareAttackedBB(Board.KingSq[EnemyColor],Board.AllPieses,Board) and Board.Occupancy[MyColor]
    else Board.CheckersBB:=0;
end;

Procedure UnMakeMove(move : integer;var Board:TBoard; var Undo:TUndo);inline;
// Возвращает ход назад
var
  MyColor,FromSq,DestSq,Piese,PieseTyp,RookFromSq,RookDestSq,CapSq : integer;
begin
  // Инициализация
  Board.SideToMove:=Board.SideToMove xor 1;
  MyColor:=Board.SideToMove;
  FromSQ:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[DestSq];   // Либо ходившая фигура либо превращенная
  PieseTyp:=TypOfPiese[Piese];  // Либо ходившая фигура либо превращенная
    // Откатываем рокировку (ход ладьи)
  if Undo.isCastle then
    begin
      if DestSq-FromSq=2 then
        begin
         RookFromSq:=DestSq+1;
         RookDestSq:=FromSq+1;
        end else
        begin
         RookFromSq:=DestSq-2;
         RookDestSq:=FromSq-1;
        end;
      MovePiese(MyColor,RookDestSq,RookFromSq,Board.Pos[RookDestSq],Rook,Board);
    end;
  // Откатываем превращение
  if (move and PromoteFlag)<>0 then
    begin
      RemovePiese(MyColor,DestSq,PieseTyp,Board);
      PieseTyp:=Pawn;   // ходившая фигура
      if MyColor=White
        then Piese:=PieseTyp
        else Piese:=-PieseTyp;
      SetPiese(MyColor,DestSq,Piese,PieseTyp,Board);
    end;
 
  // откатываем основной ход
  MovePiese(MyColor,DestSq,FromSq,Piese,PieseTyp,Board);
  // Откатываем взятие
  if Undo.isCapture then
    begin
      CapSq:=DestSq;
      if Undo.isEnnPass then CapSq:=DestSq-PawnPush[MyColor];
      SetPiese(MyColor xor 1,CapSq,Board.CapturedPiese,TypOfPiese[Board.CapturedPiese],Board);
    end;
 // Восстанавливаемся из Undo
  Board.EnPassSq:=Undo.EnPassSq;
  Board.CastleRights:=Undo.CastleRights;
  Board.Rule50:=Undo.Rule50;
  Board.CheckersBB:=Undo.CheckersBB;
  Board.CapturedPiese:=Undo.CapturedPiese;
  Board.Key:=Undo.Key;
  Board.PawnKey:=Undo.PawnKey;
  Board.MatKey:=Undo.MatKey;
  Board.NonPawnMat[white]:=Undo.NonPawnMat[white];
  Board.NonPawnMat[black]:=Undo.NonPawnMat[black];
  Board.PstMid:=Undo.PstMid;
  Board.PstEnd:=Undo.PstEnd;
  Board.nullcnt:=Undo.nullcnt;
end;

Procedure MakeNullMove(var Board:TBoard);inline;
begin
  // Сбрасываем метку взятия на проходе
  if Board.EnPassSq<>NonSq then
    begin
     Board.Key:=Board.Key xor EnnPassZobr[Board.EnPassSq];
     Board.EnPassSq:=NonSq;
    end;
  Board.Key:=Board.Key xor Zcolor;
  inc(Board.Rule50);
  Board.nullcnt:=0;
  Board.SideToMove:=Board.SideToMove xor 1;
end;

Procedure UnMakeNullMove(var Board:TBoard;var Undo:TUndo);inline;
begin
  Board.SideToMove:=Board.SideToMove xor 1;
  // Восстанавливаемся из Undo
  Board.EnPassSq:=Undo.EnPassSq;
  Board.CastleRights:=Undo.CastleRights;
  Board.Rule50:=Undo.Rule50;
  Board.CheckersBB:=Undo.CheckersBB;
  Board.CapturedPiese:=Undo.CapturedPiese;
  Board.Key:=Undo.Key;
  Board.PawnKey:=Undo.PawnKey;
  Board.MatKey:=Undo.MatKey;
  Board.NonPawnMat[white]:=Undo.NonPawnMat[white];
  Board.NonPawnMat[black]:=Undo.NonPawnMat[black];
  Board.PstMid:=Undo.PstMid;
  Board.PstEnd:=Undo.PstEnd;
  Board.nullcnt:=Undo.nullcnt;
end;

Function Perft(Root:boolean;t1:TDateTime;var Board:TBoard;depth:integer):int64;
// Тест perft
var
   t2 : TDateTime;
   nodes,cnt,nps: int64;
   Undo : TUndo;
   CheckInfo : TCheckInfo;
   i,n:integer;
   MList:TmoveList;
   isCheck : Boolean;
begin
  if Root then t1:=now;
  nodes:=0;
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  n:=GenerateLegals(0,Board,MList);
  If depth<=1
    then nodes:=n
    else for i:=0 to n-1 do
         begin
            isCheck:=isMoveCheck(MList[i].move,CheckInfo,Board);
            MakeMove(MList[i].move,Board,Undo,isCheck);
           if depth>1
             then cnt:=Perft(false,t1,Board,depth-1)
             else cnt:=1;
           nodes:=nodes+cnt;
           UnMakeMove(MList[i].move,Board,Undo);
         end;
  If Root then
   begin
    t2:=now;
    cnt:=MillisecondsBetween(t1,t2);
    if cnt<>0
      then nps:=(nodes*1000) div cnt
      else nps:=nodes;
    writeln('Perft ',depth,' - ',nodes,' nodes. At ',cnt,' msec.',nps,' nodes per second');
   end;
  Result:=nodes;
end;

Procedure ReflectBoard(var Board:TBoard;var NewBoard:TBoard);
// Переворачивает доску: черные фигуры становятся на место белых и наоборот. Используется для отладки.
var
  i,piese,sq,newsq:integer;
  temp : TBitBoard;
begin
  ClearBoard(NewBoard);
  // Переставляем фигуры
  for i:=a1 to h8 do
    begin
      piese:=Board.Pos[i];
      newsq:=VertReflectSq[i];
      NewBoard.Pos[newsq]:=-piese;
      case piese of
         pawn :    begin
                     NewBoard.Pieses[pawn]:=NewBoard.Pieses[pawn] or Only[newsq];
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
        -pawn :    begin
                     NewBoard.Pieses[pawn]:=NewBoard.Pieses[pawn] or Only[newsq];
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
         knight :  begin
                     NewBoard.Pieses[knight]:=NewBoard.Pieses[knight] or Only[newsq];
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
        -knight :  begin
                     NewBoard.Pieses[knight]:=NewBoard.Pieses[knight] or Only[newsq];
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
         bishop :  begin
                     NewBoard.Pieses[bishop]:=NewBoard.Pieses[bishop] or Only[newsq];
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
        -bishop :  begin
                     NewBoard.Pieses[bishop]:=NewBoard.Pieses[bishop] or Only[newsq];
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
         rook :    begin
                     NewBoard.Pieses[rook]:=NewBoard.Pieses[rook] or Only[newsq];
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
        -rook :    begin
                     NewBoard.Pieses[rook]:=NewBoard.Pieses[rook] or Only[newsq];
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
        queen :    begin
                     NewBoard.Pieses[queen]:=NewBoard.Pieses[queen] or Only[newsq];
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
       -queen :    begin
                     NewBoard.Pieses[queen]:=NewBoard.Pieses[queen] or Only[newsq];
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
         king :    begin
                     NewBoard.KingSq[black]:=newsq;
                     NewBoard.Occupancy[black]:=NewBoard.Occupancy[black] or Only[newSq];
                   end;
        -king :    begin
                     NewBoard.KingSq[white]:=newsq;
                     NewBoard.Occupancy[white]:=NewBoard.Occupancy[white] or Only[newSq];
                   end;
       end;
      NewBoard.AllPieses:=NewBoard.Occupancy[white] or NewBoard.Occupancy[black];
      NewBoard.SideToMove:=Board.SideToMove xor 1;
      NewBoard.CastleRights:=((Board.CastleRights and 3) shl 2) or ((Board.CastleRights shr 2) and 3);
      If Board.EnPassSq<>NonSq
        then NewBoard.EnPassSq:=VertReflectSq[Board.EnPassSq]
        else NewBoard.EnPassSq:=NonSq;
      NewBoard.Rule50:=Board.Rule50;
      NewBoard.MoveNum:=Board.MoveNum;
      temp:=Board.CheckersBB;
      while temp<>0 do
        begin
          sq:=BitScanForward(temp);
          newSq:=VertReflectSq[sq];
          NewBoard.CheckersBB:=NewBoard.CheckersBB or Only[newsq];
          temp:=temp and (temp-1);
        end;
      NewBoard.CapturedPiese:=-Board.CapturedPiese;
      NewBoard.Key:=CalcFullKey(NewBoard);
      NewBoard.PawnKey:=CalcFullPawnKey(NewBoard);
      NewBoard.MatKey:=CalcFullMatKey(NewBoard);
      NewBoard.NonPawnMat[white]:=Board.NonPawnMat[black];
      NewBoard.NonPawnMat[black]:=Board.NonPawnMat[white];
      CalcFullPST(NewBoard.PstMid,NewBoard.PstEnd,NewBoard);
    end;
end;

Procedure CopyBoard (var Board:TBoard; var NewBoard:TBoard );
var
 i:integer;
begin
  NewBoard.SideToMove:=Board.SideToMove;
  NewBoard.AllPieses:=Board.AllPieses;
  NewBoard.EnPassSq:=Board.EnPassSq;
  NewBoard.CastleRights:=Board.CastleRights;
  NewBoard.Rule50:=Board.Rule50;
  NewBoard.MoveNum:=Board.MoveNum;
  NewBoard.CheckersBB:=Board.CheckersBB;
  NewBoard.CapturedPiese:=Board.CapturedPiese;
  NewBoard.Key:=Board.Key;
  NewBoard.PawnKey:=Board.PawnKey;
  NewBoard.MatKey:=Board.MatKey;
  NewBoard.NonPawnMat[white]:=Board.NonPawnMat[white];
  NewBoard.NonPawnMat[black]:=Board.NonPawnMat[black];
  NewBoard.PstMid:=Board.PstMid;
  NewBoard.PstEnd:=Board.PstEnd;
  NewBoard.nullcnt:=Board.nullcnt;
  NewBoard.Nodes:=Board.Nodes;
  NewBoard.remain:=Board.remain;
  For i:=Pawn to Queen do
    NewBoard.Pieses[i]:=Board.Pieses[i];
  for i:=white to black do
    NewBoard.Occupancy[i]:=Board.Occupancy[i];
  for i:=a1 to h8 do
    NewBoard.Pos[i]:=Board.Pos[i];
  for i:=white to black do
    NewBoard.KingSq[i]:=Board.KingSq[i];
end;

Function CompareBoards(var Board:TBoard; var NewBoard:TBoard):boolean;
var
  i:integer;
begin
Result:=false;
 if NewBoard.SideToMove<>Board.SideToMove then exit;
 if NewBoard.AllPieses<>Board.AllPieses then exit;
 if NewBoard.EnPassSq<>Board.EnPassSq then exit;
 if NewBoard.CastleRights<>Board.CastleRights then exit;
 if NewBoard.Rule50<>Board.Rule50 then exit;
 if NewBoard.MoveNum<>Board.MoveNum then exit;
 if NewBoard.CheckersBB<>Board.CheckersBB then exit;
 if NewBoard.CapturedPiese<>Board.CapturedPiese then exit;
 if NewBoard.Key<>Board.Key then exit;
 if NewBoard.PawnKey<>Board.PawnKey then exit;
 if NewBoard.MatKey<>Board.MatKey then exit;
 if NewBoard.NonPawnMat[white]<>Board.NonPawnMat[white] then exit;
 if NewBoard.NonPawnMat[black]<>Board.NonPawnMat[black] then exit;
 if NewBoard.PstMid<>Board.PstMid then exit;
 if NewBoard.PstEnd<>Board.PstEnd then exit;
 if NewBoard.nullcnt<>Board.nullcnt then exit;
 For i:=Pawn to Queen do
    if NewBoard.Pieses[i]<>Board.Pieses[i] then exit;
  for i:=white to black do
    if NewBoard.Occupancy[i]<>Board.Occupancy[i] then exit;
  for i:=a1 to h8 do
    if NewBoard.Pos[i]<>Board.Pos[i] then exit;
  for i:=white to black do
    if NewBoard.KingSq[i]<>Board.KingSq[i] then exit;
Result:=true;
end;


end.
