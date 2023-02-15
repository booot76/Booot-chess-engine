unit attacks;
// Юнит отвечает за определения атакованных полей на доске.
interface
uses params,bitboards;

Function AttackedFrom(square: integer) : bitboard;
Function IsAttack (color: integer; square : integer) :boolean;
Function BishopsMove(from: integer) : bitboard;
Function Bishopsh1Move(from: integer) : bitboard;
Function Bishopsa1Move(from: integer) : bitboard;
Function RooksMove(from: integer) : bitboard;
Function RooksRankMove(from: integer) : bitboard;
Function RooksFileMove(from: integer) : bitboard;
Function IsWhiteAttacks(square : integer):boolean;
Function IsBlackAttacks(square : integer):boolean;
Function IsWhiteAttacksLight(square : integer):boolean;
Function IsBlackAttacksLight(square : integer):boolean;
implementation

Function AttackedFrom(square: integer) : bitboard;
// функция возвращает битборд фигур (обоих фигур), непосредственно атакующих поле square
  begin
    Result:=(WPattacks[square] and BlackPawns) or
            (BPattacks[square] and WhitePawns) or
            (KnightsMove[square] and (WhiteKnights or BlackKnights)) or
            (BishopsMove(square) and (WQB or BQB)) or
            (RooksMove(square) and (WQR or BQR)) or
            (KingsMove[square] and (WhiteKing or BlackKing));

  end;
Function IsAttack (color: integer; square : integer) :boolean;
Var
   res:boolean;
// Функция возвращает true если поле square атаковано  фигурами цвета color
  begin
    if color=white then
      Begin
        if (BishopFull[square] and WQB)<>0 then
           if (BishopsMove(square) and WQB)<>0 then begin
                                                     Result:=true;
                                                     exit;
                                                    end;

        if (RookFull[square] and WQR)<>0 then
          if (RooksMove(square) and WQR)<>0 then begin
                                                  Result:=true;
                                                  exit;
                                                 end;

        if (BPattacks[square] and WhitePawns)<>0 then res:=true else
        if (KnightsMove[square] and WhiteKnights)<>0 then res:=true else
        if (KingsMove[square] and WhiteKing)<>0 then res:=true else
          res:=false;
      End          else
      Begin
        if (BishopFull[square] and BQB)<>0 then
           if (BishopsMove(square) and BQB)<>0 then begin
                                                     Result:=true;
                                                     exit;
                                                   end;

        if (RookFull[square] and BQR)<>0 then
           if (RooksMove(square) and BQR)<>0 then begin
                                                    Result:=true;
                                                    exit;
                                                  end;

        if (WPattacks[square] and BlackPawns)<>0 then res:=true else
        if (KnightsMove[square] and BlackKnights)<>0 then res:=true else
        if (KingsMove[square] and BlackKing)<>0 then res:=true else
          res:=false;
      End;
    Result:=res;
  end;

Function IsWhiteAttacks(square : integer):boolean;
// Функция возвращает true если поле square атаковано белыми фигурами
var
   res:boolean;
  begin

    if (BishopFull[square] and WQB)<>0 then
       if (BishopsMove(square) and WQB)<>0 then  begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (RookFull[square] and WQR)<>0 then
      if (RooksMove(square) and WQR)<>0 then begin
                                               Result:=true;
                                               exit;
                                             end;

    if (BPattacks[square] and WhitePawns)<>0 then res:=true else
    if (KnightsMove[square] and WhiteKnights)<>0 then res:=true
    else
    if (KingsMove[square] and WhiteKing)<>0 then res:=true else
        res:=false;
    Result:=res;
  end;
Function IsWhiteAttacksLight(square : integer):boolean;
// Функция возвращает true если поле square атаковано белыми фигурами
var
   res:boolean;
  begin

    if (BishopFull[square] and WQB)<>0 then
       if (BishopsMove(square) and WQB)<>0 then  begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (RookFull[square] and WQR)<>0 then
      if (RooksMove(square) and WQR)<>0 then begin
                                               Result:=true;
                                               exit;
                                             end;

    if (BPattacks[square] and WhitePawns)<>0 then res:=true else
    if (KnightsMove[square] and WhiteKnights)<>0 then res:=true
    else
        res:=false;
    Result:=res;
  end;
Function IsBlackAttacks(square : integer):boolean;
// Функция возвращает true если поле square атаковано черными фигурами
var
   res:boolean;
  begin

    if (BishopFull[square] and BQB)<>0 then
       if (BishopsMove(square) and BQB)<>0 then begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (RookFull[square] and BQR)<>0 then
       if (RooksMove(square) and BQR)<>0 then begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (WPattacks[square] and BlackPawns)<>0 then res:=true else
    if (KnightsMove[square] and BlackKnights)<>0 then res:=true else
    if (KingsMove[square] and BlackKing)<>0 then res:=true else
        res:=false;
    Result:=res;
  end;
Function IsBlackAttacksLight(square : integer):boolean;
// Функция возвращает true если поле square атаковано черными фигурами
var
   res:boolean;
  begin

    if (BishopFull[square] and BQB)<>0 then
       if (BishopsMove(square) and BQB)<>0 then begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (RookFull[square] and BQR)<>0 then
       if (RooksMove(square) and BQR)<>0 then begin
                                                  Result:=true;
                                                  exit;
                                                 end;

    if (WPattacks[square] and BlackPawns)<>0 then res:=true else
    if (KnightsMove[square] and BlackKnights)<>0 then res:=true else
        res:=false;
    Result:=res;
  end;
Function BishopsMove(from: integer) : bitboard;
// Функция возвращает все возможные ходы слона  (включая взятия) с поля from
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
     temp:=RBDh1[from,indx];
    indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
    temp:=temp or RBDa1[from,indx];
    Result:=temp;
  end;
Function Bishopsh1Move(from: integer) : bitboard;
// Функция возвращает все возможные ходы слона  (включая взятия) с поля from в направлении h1-a8
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
    temp:=RBDh1[from,indx];
    Result:=temp;
  end;
Function Bishopsa1Move(from: integer) : bitboard;
// Функция возвращает все возможные ходы слона  (включая взятия) с поля from в направлении a1-h8
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
    temp:=RBDa1[from,indx];
    Result:=temp;
  end;

Function RooksMove(from: integer) : bitboard;
// Функция возвращает все возможные ходы ладьи (включая взятия) с поля from
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
    temp:=RB[from,indx];
    indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
    temp:=(temp or RBR90[from,indx]);
    Result:=temp;
  end;
Function RooksRankMove(from: integer) : bitboard;
// Функция возвращает все возможные ходы ладьи (включая взятия) с поля from по горизонтали
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
    temp:=RB[from,indx];
    Result:=temp;
  end;
Function RooksFileMove(from: integer) : bitboard;
// Функция возвращает все возможные ходы ладьи (включая взятия) с поля from  по вертикали
var
    indx : integer;
    temp :bitboard;
  begin
    indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
    temp:=RBR90[from,indx];
    Result:=temp;
  end;


end.

