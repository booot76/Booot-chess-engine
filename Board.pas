unit Board;

interface
uses params,bitboards,SysUtils;

CONST
    Empty=0;
    Pawn=1;
    Knight=2;
    Bishop=3;
    Rook=4;
    Queen=5;
    King=6;
    WhitePawn=Pawn;
    WhiteKnight=Knight;
    WhiteBishop=Bishop;
    WhiteRook=Rook;
    WhiteQueen=Queen;
    WhiteKing=King;
    BlackPawn=-Pawn;
    BlackKnight=-Knight;
    BlackBishop=-Bishop;
    BlackRook=-Rook;
    BlackQueen=-Queen;
    BlackKing=-King;
    StartPositionFEN ='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    OnlyR00 : TBBLine =
($0000000000000001,$0000000000000002,$0000000000000004,$0000000000000008,$0000000000000010,$0000000000000020,$0000000000000040,$0000000000000080,
$0000000000000100,$0000000000000200,$0000000000000400,$0000000000000800,$0000000000001000,$0000000000002000,$0000000000004000,$0000000000008000,
$0000000000010000,$0000000000020000,$0000000000040000,$0000000000080000,$0000000000100000,$0000000000200000,$0000000000400000,$0000000000800000,
$0000000001000000,$0000000002000000,$0000000004000000,$0000000008000000,$0000000010000000,$0000000020000000,$0000000040000000,$0000000080000000,
$0000000100000000,$0000000200000000,$0000000400000000,$0000000800000000,$0000001000000000,$0000002000000000,$0000004000000000,$0000008000000000,
$0000010000000000,$0000020000000000,$0000040000000000,$0000080000000000,$0000100000000000,$0000200000000000,$0000400000000000,$0000800000000000,
$0001000000000000,$0002000000000000,$0004000000000000,$0008000000000000,$0010000000000000,$0020000000000000,$0040000000000000,$0080000000000000,
$0100000000000000,$0200000000000000,$0400000000000000,$0800000000000000,$1000000000000000,$2000000000000000,$4000000000000000,$8000000000000000);

    NotOnlyR00 : TBBLine =
($FFFFFFFFFFFFFFFE,$FFFFFFFFFFFFFFFD,$FFFFFFFFFFFFFFFB,$FFFFFFFFFFFFFFF7,$FFFFFFFFFFFFFFEF,$FFFFFFFFFFFFFFDF,$FFFFFFFFFFFFFFBF,$FFFFFFFFFFFFFF7F,
$FFFFFFFFFFFFFEFF,$FFFFFFFFFFFFFDFF,$FFFFFFFFFFFFFBFF,$FFFFFFFFFFFFF7FF,$FFFFFFFFFFFFEFFF,$FFFFFFFFFFFFDFFF,$FFFFFFFFFFFFBFFF,$FFFFFFFFFFFF7FFF,
$FFFFFFFFFFFEFFFF,$FFFFFFFFFFFDFFFF,$FFFFFFFFFFFBFFFF,$FFFFFFFFFFF7FFFF,$FFFFFFFFFFEFFFFF,$FFFFFFFFFFDFFFFF,$FFFFFFFFFFBFFFFF,$FFFFFFFFFF7FFFFF,
$FFFFFFFFFEFFFFFF,$FFFFFFFFFDFFFFFF,$FFFFFFFFFBFFFFFF,$FFFFFFFFF7FFFFFF,$FFFFFFFFEFFFFFFF,$FFFFFFFFDFFFFFFF,$FFFFFFFFBFFFFFFF,$FFFFFFFF7FFFFFFF,
$FFFFFFFEFFFFFFFF,$FFFFFFFDFFFFFFFF,$FFFFFFFBFFFFFFFF,$FFFFFFF7FFFFFFFF,$FFFFFFEFFFFFFFFF,$FFFFFFDFFFFFFFFF,$FFFFFFBFFFFFFFFF,$FFFFFF7FFFFFFFFF,
$FFFFFEFFFFFFFFFF,$FFFFFDFFFFFFFFFF,$FFFFFBFFFFFFFFFF,$FFFFF7FFFFFFFFFF,$FFFFEFFFFFFFFFFF,$FFFFDFFFFFFFFFFF,$FFFFBFFFFFFFFFFF,$FFFF7FFFFFFFFFFF,
$FFFEFFFFFFFFFFFF,$FFFDFFFFFFFFFFFF,$FFFBFFFFFFFFFFFF,$FFF7FFFFFFFFFFFF,$FFEFFFFFFFFFFFFF,$FFDFFFFFFFFFFFFF,$FFBFFFFFFFFFFFFF,$FF7FFFFFFFFFFFFF,
$FEFFFFFFFFFFFFFF,$FDFFFFFFFFFFFFFF,$FBFFFFFFFFFFFFFF,$F7FFFFFFFFFFFFFF,$EFFFFFFFFFFFFFFF,$DFFFFFFFFFFFFFFF,$BFFFFFFFFFFFFFFF,$7FFFFFFFFFFFFFFF);

    NotOnlyR90 : TBBLine =
($FFFFFFFFFFFFFFFE,$FFFFFFFFFFFFFEFF,$FFFFFFFFFFFEFFFF,$FFFFFFFFFEFFFFFF,$FFFFFFFEFFFFFFFF,$FFFFFEFFFFFFFFFF,$FFFEFFFFFFFFFFFF,$FEFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFFD,$FFFFFFFFFFFFFDFF,$FFFFFFFFFFFDFFFF,$FFFFFFFFFDFFFFFF,$FFFFFFFDFFFFFFFF,$FFFFFDFFFFFFFFFF,$FFFDFFFFFFFFFFFF,$FDFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFFB,$FFFFFFFFFFFFFBFF,$FFFFFFFFFFFBFFFF,$FFFFFFFFFBFFFFFF,$FFFFFFFBFFFFFFFF,$FFFFFBFFFFFFFFFF,$FFFBFFFFFFFFFFFF,$FBFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFF7,$FFFFFFFFFFFFF7FF,$FFFFFFFFFFF7FFFF,$FFFFFFFFF7FFFFFF,$FFFFFFF7FFFFFFFF,$FFFFF7FFFFFFFFFF,$FFF7FFFFFFFFFFFF,$F7FFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFEF,$FFFFFFFFFFFFEFFF,$FFFFFFFFFFEFFFFF,$FFFFFFFFEFFFFFFF,$FFFFFFEFFFFFFFFF,$FFFFEFFFFFFFFFFF,$FFEFFFFFFFFFFFFF,$EFFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFDF,$FFFFFFFFFFFFDFFF,$FFFFFFFFFFDFFFFF,$FFFFFFFFDFFFFFFF,$FFFFFFDFFFFFFFFF,$FFFFDFFFFFFFFFFF,$FFDFFFFFFFFFFFFF,$DFFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFBF,$FFFFFFFFFFFFBFFF,$FFFFFFFFFFBFFFFF,$FFFFFFFFBFFFFFFF,$FFFFFFBFFFFFFFFF,$FFFFBFFFFFFFFFFF,$FFBFFFFFFFFFFFFF,$BFFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFF7F,$FFFFFFFFFFFF7FFF,$FFFFFFFFFF7FFFFF,$FFFFFFFF7FFFFFFF,$FFFFFF7FFFFFFFFF,$FFFF7FFFFFFFFFFF,$FF7FFFFFFFFFFFFF,$7FFFFFFFFFFFFFFF);

    NotOnlyBh1 : TBBLine =
($7FFFFFFFFFFFFFFF,$BFFFFFFFFFFFFFFF,$EFFFFFFFFFFFFFFF,$FDFFFFFFFFFFFFFF,$FFDFFFFFFFFFFFFF,$FFFEFFFFFFFFFFFF,$FFFFFBFFFFFFFFFF,$FFFFFFF7FFFFFFFF,
$DFFFFFFFFFFFFFFF,$F7FFFFFFFFFFFFFF,$FEFFFFFFFFFFFFFF,$FFEFFFFFFFFFFFFF,$FFFF7FFFFFFFFFFF,$FFFFFDFFFFFFFFFF,$FFFFFFFBFFFFFFFF,$FFFFFFFFF7FFFFFF,
$FBFFFFFFFFFFFFFF,$FF7FFFFFFFFFFFFF,$FFF7FFFFFFFFFFFF,$FFFFBFFFFFFFFFFF,$FFFFFEFFFFFFFFFF,$FFFFFFFDFFFFFFFF,$FFFFFFFFFBFFFFFF,$FFFFFFFFFFEFFFFF,
$FFBFFFFFFFFFFFFF,$FFFBFFFFFFFFFFFF,$FFFFDFFFFFFFFFFF,$FFFFFF7FFFFFFFFF,$FFFFFFFEFFFFFFFF,$FFFFFFFFFDFFFFFF,$FFFFFFFFFFF7FFFF,$FFFFFFFFFFFFBFFF,
$FFFDFFFFFFFFFFFF,$FFFFEFFFFFFFFFFF,$FFFFFFBFFFFFFFFF,$FFFFFFFF7FFFFFFF,$FFFFFFFFFEFFFFFF,$FFFFFFFFFFFBFFFF,$FFFFFFFFFFFFDFFF,$FFFFFFFFFFFFFDFF,
$FFFFF7FFFFFFFFFF,$FFFFFFDFFFFFFFFF,$FFFFFFFFBFFFFFFF,$FFFFFFFFFF7FFFFF,$FFFFFFFFFFFDFFFF,$FFFFFFFFFFFFEFFF,$FFFFFFFFFFFFFEFF,$FFFFFFFFFFFFFFDF,
$FFFFFFEFFFFFFFFF,$FFFFFFFFDFFFFFFF,$FFFFFFFFFFBFFFFF,$FFFFFFFFFFFEFFFF,$FFFFFFFFFFFFF7FF,$FFFFFFFFFFFFFF7F,$FFFFFFFFFFFFFFEF,$FFFFFFFFFFFFFFFB,
$FFFFFFFFEFFFFFFF,$FFFFFFFFFFDFFFFF,$FFFFFFFFFFFF7FFF,$FFFFFFFFFFFFFBFF,$FFFFFFFFFFFFFFBF,$FFFFFFFFFFFFFFF7,$FFFFFFFFFFFFFFFD,$FFFFFFFFFFFFFFFE);

    NotOnlyBa1 : TBBLine =
($FFFFFFFFEFFFFFFF,$FFFFFFEFFFFFFFFF,$FFFFF7FFFFFFFFFF,$FFFDFFFFFFFFFFFF,$FFBFFFFFFFFFFFFF,$FBFFFFFFFFFFFFFF,$DFFFFFFFFFFFFFFF,$7FFFFFFFFFFFFFFF,
$FFFFFFFFFFDFFFFF,$FFFFFFFFDFFFFFFF,$FFFFFFDFFFFFFFFF,$FFFFEFFFFFFFFFFF,$FFFBFFFFFFFFFFFF,$FF7FFFFFFFFFFFFF,$F7FFFFFFFFFFFFFF,$BFFFFFFFFFFFFFFF,
$FFFFFFFFFFFF7FFF,$FFFFFFFFFFBFFFFF,$FFFFFFFFBFFFFFFF,$FFFFFFBFFFFFFFFF,$FFFFDFFFFFFFFFFF,$FFF7FFFFFFFFFFFF,$FEFFFFFFFFFFFFFF,$EFFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFBFF,$FFFFFFFFFFFEFFFF,$FFFFFFFFFF7FFFFF,$FFFFFFFF7FFFFFFF,$FFFFFF7FFFFFFFFF,$FFFFBFFFFFFFFFFF,$FFEFFFFFFFFFFFFF,$FDFFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFBF,$FFFFFFFFFFFFF7FF,$FFFFFFFFFFFDFFFF,$FFFFFFFFFEFFFFFF,$FFFFFFFEFFFFFFFF,$FFFFFEFFFFFFFFFF,$FFFF7FFFFFFFFFFF,$FFDFFFFFFFFFFFFF,
$FFFFFFFFFFFFFFF7,$FFFFFFFFFFFFFF7F,$FFFFFFFFFFFFEFFF,$FFFFFFFFFFFBFFFF,$FFFFFFFFFDFFFFFF,$FFFFFFFDFFFFFFFF,$FFFFFDFFFFFFFFFF,$FFFEFFFFFFFFFFFF,
$FFFFFFFFFFFFFFFD,$FFFFFFFFFFFFFFEF,$FFFFFFFFFFFFFEFF,$FFFFFFFFFFFFDFFF,$FFFFFFFFFFF7FFFF,$FFFFFFFFFBFFFFFF,$FFFFFFFBFFFFFFFF,$FFFFFBFFFFFFFFFF,
$FFFFFFFFFFFFFFFE,$FFFFFFFFFFFFFFFB,$FFFFFFFFFFFFFFDF,$FFFFFFFFFFFFFDFF,$FFFFFFFFFFFFBFFF,$FFFFFFFFFFEFFFFF,$FFFFFFFFF7FFFFFF,$FFFFFFF7FFFFFFFF);

    OnlyR90 : TBBLIne =
($0000000000000001,$0000000000000100,$0000000000010000,$0000000001000000,$0000000100000000,$0000010000000000,$0001000000000000,$0100000000000000,
$0000000000000002,$0000000000000200,$0000000000020000,$0000000002000000,$0000000200000000,$0000020000000000,$0002000000000000,$0200000000000000,
$0000000000000004,$0000000000000400,$0000000000040000,$0000000004000000,$0000000400000000,$0000040000000000,$0004000000000000,$0400000000000000,
$0000000000000008,$0000000000000800,$0000000000080000,$0000000008000000,$0000000800000000,$0000080000000000,$0008000000000000,$0800000000000000,
$0000000000000010,$0000000000001000,$0000000000100000,$0000000010000000,$0000001000000000,$0000100000000000,$0010000000000000,$1000000000000000,
$0000000000000020,$0000000000002000,$0000000000200000,$0000000020000000,$0000002000000000,$0000200000000000,$0020000000000000,$2000000000000000,
$0000000000000040,$0000000000004000,$0000000000400000,$0000000040000000,$0000004000000000,$0000400000000000,$0040000000000000,$4000000000000000,
$0000000000000080,$0000000000008000,$0000000000800000,$0000000080000000,$0000008000000000,$0000800000000000,$0080000000000000,$8000000000000000);

    OnlyBh1 : TBBLine =
($8000000000000000,$4000000000000000,$1000000000000000,$0200000000000000,$0020000000000000,$0001000000000000,$0000040000000000,$0000000800000000,
$2000000000000000,$0800000000000000,$0100000000000000,$0010000000000000,$0000800000000000,$0000020000000000,$0000000400000000,$0000000008000000,
$0400000000000000,$0080000000000000,$0008000000000000,$0000400000000000,$0000010000000000,$0000000200000000,$0000000004000000,$0000000000100000,
$0040000000000000,$0004000000000000,$0000200000000000,$0000008000000000,$0000000100000000,$0000000002000000,$0000000000080000,$0000000000004000,
$0002000000000000,$0000100000000000,$0000004000000000,$0000000080000000,$0000000001000000,$0000000000040000,$0000000000002000,$0000000000000200,
$0000080000000000,$0000002000000000,$0000000040000000,$0000000000800000,$0000000000020000,$0000000000001000,$0000000000000100,$0000000000000020,
$0000001000000000,$0000000020000000,$0000000000400000,$0000000000010000,$0000000000000800,$0000000000000080,$0000000000000010,$0000000000000004,
$0000000010000000,$0000000000200000,$0000000000008000,$0000000000000400,$0000000000000040,$0000000000000008,$0000000000000002,$0000000000000001);

    OnlyBa1 : TBBLine =
($0000000010000000,$0000001000000000,$0000080000000000,$0002000000000000,$0040000000000000,$0400000000000000,$2000000000000000,$8000000000000000,
$0000000000200000,$0000000020000000,$0000002000000000,$0000100000000000,$0004000000000000,$0080000000000000,$0800000000000000,$4000000000000000,
$0000000000008000,$0000000000400000,$0000000040000000,$0000004000000000,$0000200000000000,$0008000000000000,$0100000000000000,$1000000000000000,
$0000000000000400,$0000000000010000,$0000000000800000,$0000000080000000,$0000008000000000,$0000400000000000,$0010000000000000,$0200000000000000,
$0000000000000040,$0000000000000800,$0000000000020000,$0000000001000000,$0000000100000000,$0000010000000000,$0000800000000000,$0020000000000000,
$0000000000000008,$0000000000000080,$0000000000001000,$0000000000040000,$0000000002000000,$0000000200000000,$0000020000000000,$0001000000000000,
$0000000000000002,$0000000000000010,$0000000000000100,$0000000000002000,$0000000000080000,$0000000004000000,$0000000400000000,$0000040000000000,
$0000000000000001,$0000000000000004,$0000000000000020,$0000000000000200,$0000000000004000,$0000000000100000,$0000000008000000,$0000000800000000);

    RanksBB : TBBFile = ($00000000000000FF,$000000000000FF00,$0000000000FF0000,$00000000FF000000,$000000FF00000000,$0000FF0000000000,$00FF000000000000,$FF00000000000000);
    FilesBB : TBBFile = ($0101010101010101,$0202020202020202,$0404040404040404,$0808080808080808,$1010101010101010,$2020202020202020,$4040404040404040,$8080808080808080);

    Decode : TStringLine =
('a1','b1','c1','d1','e1','f1','g1','h1',
 'a2','b2','c2','d2','e2','f2','g2','h2',
 'a3','b3','c3','d3','e3','f3','g3','h3',
 'a4','b4','c4','d4','e4','f4','g4','h4',
 'a5','b5','c5','d5','e5','f5','g5','h5',
 'a6','b6','c6','d6','e6','f6','g6','h6',
 'a7','b7','c7','d7','e7','f7','g7','h7',
 'a8','b8','c8','d8','e8','f8','g8','h8');

TYPE
    TPieseList = array[BlackQueen..Whitequeen] of TBitBoard;
    TBoard = record
               Color   : TColor;
               Pieses  : TPieseList;
               KingSq  : Array[White..Black] of integer;
               Pos     : TBytesArray;
               CPieses : array [white .. Black] of TBitBoard;
               AllPieses : TBitBoard;
               AllR90  : TBitBoard;
               AllBh1  : TBitBoard;
               AllBa1  : TBitBoard;
               Rule50  : integer;
               Stack   : array[0..4096] of TKey;
               scount  : integer;
               Castle  : integer;
               EnnPassSQ : integer;
               oncheck : Boolean;
               Key     : Tkey;
               Pawnkey : TPawnKey;
               MatKey  : TMatKey;
               PieseCount : array [white..black] of integer;
             end;
    TUndo = record
              Piese : Tpiese;
              From  : Tsquare;
              Dest  : TSquare;
              Capsq : Tsquare;
              Promo : Tpiese;
              Captured : Tpiese;
              Rule50 : integer;
              Castle : integer;
              EnnPassSq : Tsquare;
              oncheck : boolean;
              isCastle: boolean;
              Key     : Tkey;
              Pawnkey : TPawnKey;
              MatKey  : TMatKey;
            end;
     
Procedure ClearBoard (var board:Tboard);
Procedure SetBoard(FEN:string;var Board:Tboard);
Procedure SetPieseOnBoard(color:Tcolor;Piese:TPiese;Square:Tsquare;var Board:Tboard);
Procedure CompareBoards(var Board:Tboard;var Oldy:Tboard);
Procedure PrintBoardASCII(var Board:Tboard);
implementation
  uses attacks,hash;
Procedure ClearBoard (var board:Tboard);
 var i:integer;
 begin
   with Board do
     begin
       color:=-1;
       kingsq[white]:=-1;
       kingSq[black]:=-1;
       for i:=BlackQueen to WhiteQueen do
         Pieses[i]:=0;
       Cpieses[white]:=0;
       CPieses[black]:=0;
       AllPieses:=0;
       AllR90:=0;
       AllBh1:=0;
       AllBa1:=0;
       for i:=a1 to h8 do
         pos[i]:=0;
       Rule50:=0;
       scount:=0;
       for i:=0 to 1024 do
         stack[i]:=0;
       Castle:=0;
       EnnPassSq:=-1;
       oncheck:=false;
       key:=0;
       PawnKey:=0;
       MatKey:=0;
       PieseCount[white]:=0;
       PieseCount[black]:=0;
     end;
 end;
Procedure SetPieseOnBoard(color:Tcolor;Piese:TPiese;Square:Tsquare;var Board:Tboard);
 begin
   if piese=WhiteKing then Board.KingSq[white]:=Square else
   if piese=BlackKing then Board.KingSq[black]:=Square else
      Board.Pieses[piese]:=(Board.Pieses[piese] or OnlyR00[square]);
   Board.CPieses[color]:=Board.CPieses[color] or OnlyR00[square];
   Board.AllPieses:=Board.AllPieses or OnlyR00[square];
   Board.AllR90:=Board.AllR90 or OnlyR90[square];
   Board.AllBh1:=Board.AllBh1 or OnlyBh1[square];
   Board.AllBa1:=Board.AllBa1 or OnlyBa1[square];
   board.Pos[square]:=piese;
 end;
 Procedure CompareBoards(var Board:Tboard;var Oldy:Tboard);
var
  i:integer;
begin
  if (Oldy.Color<>Board.Color) then writeln('Wrong Color');
 for i:=BlackQueen to WhiteQueen do
   if (Oldy.Pieses[i]<>Board.Pieses[i]) then writeln('WrongPieses');
 for i:=a1 to h8 do
   if (Oldy.Pos[i]<>Board.Pos[i]) then writeln('WrongPos');
 if (Oldy.KingSq[white]<>Board.KingSq[white]) then writeln('Wrong Wkingsq');
 if (Oldy.KingSq[black]<>Board.KingSq[black]) then writeln('Wrong BkingSq');
 if (Oldy.Cpieses[white]<>Board.Cpieses[white]) then writeln('Wrong Wpieses');
 if (Oldy.Cpieses[black]<>Board.Cpieses[black]) then writeln('Wrong BPieses');
 if (Oldy.AllPieses<>Board.AllPieses) then writeln('Wrong AllPieses');
 if (Oldy.AllR90<>Board.AllR90) then writeln('Wrong AllR90');
 if (Oldy.AllBh1<>Board.AllBh1) then writeln('Wrong Allbh1');
 if (Oldy.AllBa1<>Board.AllBa1) then writeln('Wrong Ba1');
 if (Oldy.Rule50<>Board.Rule50) then writeln('Wrong Rule50');
 if (Oldy.Castle<>Board.Castle) then writeln('Wrong Castle');
 if (Oldy.EnnPassSQ<>Board.EnnPassSQ) then writeln('Wrong EnnPass');
 if (Oldy.oncheck<>Board.oncheck) then writeln('Wrong oncheck');
 if (Oldy.scount<>Board.scount) then writeln('Wrong scount');
 if (Oldy.key<>Board.key) then writeln('Wrong key');
 if (Oldy.pawnkey<>Board.pawnkey) then writeln('Wrong pawnkey');
 if (Oldy.matkey<>Board.matkey) then writeln('Wrong matkey');
 if (Oldy.piesecount[white]<>Board.piesecount[white]) then writeln('Wrong piesecount white');
 if (Oldy.piesecount[black]<>Board.piesecount[black]) then writeln('Wrong piesecount black');
end;

Procedure SetBoard(FEN:string;var Board:Tboard);
// Устанавливает позицию на доске с помощью FEN строки
label l1;
type Tsq=array[1..8] of integer;
Const Point : Tsq =(a1,a2,a3,a4,a5,a6,a7,a8);
var
   i,j,k,CurrRank:Integer;
   CurrSquare:Tsquare;
   temp : TBitBoard;
begin
  if Length(FEN)<10 then FEN:=StartPositionFEN;
  ClearBoard(Board);
  CurrRank:=8;
  CurrSquare:=Point[CurrRank];
  Board.Color:=White;
 // Устанавливаем положение на доске
  For i:=1 to Length(FEN) do
   begin
    if CurrRank=0 then break;
    if FEN[i]<>' '
     then begin
           if (FEN[i]>='1') and (FEN[i]<='8')
              then begin
                   // Пропускаем пустые поля на доске
                   CurrSquare:=CurrSquare+StrToInt(FEN[i]);
                   end
              else
           case FEN[i] of
           '/' : begin
                 dec(CurrRank);
                 CurrSquare:=Point[CurrRank];
                 end;
           'P' : begin
                 SetPieseOnBoard(white,whitepawn,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'N' : begin
                 SetPieseOnBoard(white,whiteknight,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'B' : begin
                 SetPieseOnBoard(white,whitebishop,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'R' : begin
                 SetPieseOnBoard(white,whiterook,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'Q' : begin
                 SetPieseOnBoard(white,whitequeen,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'K' : begin
                 SetPieseOnBoard(white,whiteking,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'p' : begin
                 SetPieseOnBoard(black,blackpawn,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'n' : begin
                 SetPieseOnBoard(black,blackknight,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'b' : begin
                 SetPieseOnBoard(black,blackbishop,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'r' : begin
                 SetPieseOnBoard(black,blackrook,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'q' : begin
                 SetPieseOnBoard(black,blackqueen,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           'k' : begin
                 SetPieseOnBoard(black,blackking,CurrSquare,Board);
                 inc(CurrSquare);
                 end;
           end;
           if (CurrSquare>=8) and (CurrRank=1) then break;
          end;
   end;
//   writeln(FEN[i]);
   // Очередь хода
   if  (FEN[i+2]='w') then
      begin
      Board.Color:=white;
      inc(i,2);
      end else
   if  (FEN[i+2]='b')   then
       begin
       Board.Color:=black;
       inc(i,2);
       end  else goto l1;
// Доп инфа (иногда может отсутствовать в строке)
   for j:=i+1 to Length(FEN) do
    begin
     if (FEN[j] in ['0','1','2','3','4','5','6','7','8','9'])  then
       begin
         // Счетчик полуходов для правила 50
         if (j=length(FEN)) or (FEN[j+1]=' ')
            then k:=StrToInt(FEN[j]) else
              begin
                if (j+1=length(FEN)) or (FEN[j+2]=' ') 
                  then k:=STRtoINT(FEN[j]+FEN[j+1])
                  else k:=STRtoINT(FEN[j]+FEN[j+1]+FEN[j+2]);
              end;
         Board.Rule50:=k;
         break;
       end;
     if FEN[j]='K' then Board.Castle:=Board.Castle or 1;
     if FEN[j]='Q' then Board.Castle:=Board.Castle or 2;
     if FEN[j]='k' then Board.Castle:=Board.Castle or 4;
     if FEN[j]='q' then Board.Castle:=Board.Castle or 8;
     if FEN[j] in ['a','b','c','d','e','f','g','h'] then
        for k:=a1 to h8 do
         if Decode[k]=FEN[j]+FEN[j+1] then Board.EnnPassSQ:=k;
    end;

l1: 
 Board.oncheck:=isAttackedBy(Board.Color xor 1,board.KingSq[board.Color],Board);
 Board.Key:=CalcKeyFull(Board);
 Board.scount:=0;
 Board.Stack[0]:=Board.Key;
 Board.PawnKey:=CalcPawnKeyFull(Board);
 Board.MatKey:=CalcMatKeyFull(Board);
 temp :=Board.Pieses[WhiteKnight] or Board.Pieses[WhiteBishop] or Board.Pieses[WhiteRook] or Board.Pieses[WhiteQueen];
 Board.PieseCount[white]:=BitCount(temp);
 temp :=Board.Pieses[BlackKnight] or Board.Pieses[BlackBishop] or Board.Pieses[BlackRook] or Board.Pieses[BlackQueen];
 Board.PieseCount[black]:=BitCount(temp);
end;
Procedure PrintBoardASCII(var Board:Tboard);
type
    TPieseChar = array[BlackKing..WhiteKing] of char;
const PieseChar:TpieseChar=('k','q','r','b','n','p','.','P','N','B','R','Q','K');
var
   i,j : integer;
   piese:Tpiese;
begin
  for j:=7 downto 0 do
    begin
    write(j+1,'  '); // Подписываем горизонтали
    for i:=0 to 7 do
     begin
      piese:= Board.Pos[j*8+i];
      write(PieseChar[piese]);
     end;
    writeln;
    end;
  //подписываем вертикали
  writeln('   abcdefgh');
end;
end.
