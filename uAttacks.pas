unit uAttacks;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$Define pext}

interface
uses uBitBoards,uMagic,uBoard;

Const
  SeeValues  : array[Empty..King] of integer =(0,100,300,300,500,900,10000);
  PieseColor : array[-King..King] of integer=(black,black,black,black,black,black,white,white,white,white,white,white,white);

Function KnightAttacksBB(sq:integer):TBitBoard;inline;
Function KingAttacksBB(sq:integer):TBitBoard;inline;
Function BishopAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function RookAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function QueenAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function PieseAttacksBB(Color:integer;PieseTyp : integer;SQ:integer;AllPieses:TBitBoard):TBitBoard;inline;
Function SquareAttackedBB(sq:integer;AllPieses:TBitBoard;var Board:Tboard):TBitBoard;
Procedure FillCheckInfo(var CheckInfo:TCheckInfo;var Board:TBoard);
Function FindPinners(color:integer;KingColor:integer;var Board:TBoard):TBitBoard;
Function isMoveCheck(move:integer;var CheckInfo:TCheckInfo;var Board:TBoard):boolean;
Function isLegal(move:integer;Pinned:TBitBoard; var Board:TBoard):boolean;
Function isPseudoCorrect(move:integer;var Board:TBoard):boolean;
Function GoodSee(move:integer;var Board:TBoard;margin:integer):boolean;
implementation
 uses Unn;

Function KnightAttacksBB(sq:integer):TBitBoard;inline;
 begin
   Result:=KnightAttacks[sq];
 end;
Function KingAttacksBB(sq:integer):TBitBoard;inline;
 begin
   Result:=KingAttacks[sq];
 end;
Function BishopAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
 begin
   {$IFDEF pext}
   Result:=BishoppextMM[BishoppextOffset[sq]+ pext(allpieses,BishopMasks[sq])];
   {$ELSE pext}
   Result:=BishopMM[BishopOffset[sq]+(((allpieses and BishopMasks[sq])*BishopMagics[sq]) shr BishopShifts[sq])];
   {$ENDIF pext}
 end;
Function RookAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
 begin
   {$IFDEF pext}
   Result:=RookpextMM[RookpextOffset[sq]+ pext(allpieses,RookMasks[sq])];
   {$ELSE pext}
   Result:=RookMM[RookOffset[sq]+(((allpieses and RookMasks[sq])*RookMagics[sq]) shr RookShifts[sq])];
   {$ENDIF pext}
 end;
Function QueenAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
 begin
   {$IFDEF pext}
   Result:=RookpextMM[RookpextOffset[sq]+ pext(allpieses,RookMasks[sq])] or BishoppextMM[BishoppextOffset[sq]+ pext(allpieses,BishopMasks[sq])];
   {$ELSE pext}
   Result:=RookMM[RookOffset[sq]+(((allpieses and RookMasks[sq])*RookMagics[sq]) shr RookShifts[sq])] or BishopMM[BishopOffset[sq]+(((allpieses and BishopMasks[sq])*BishopMagics[sq]) shr BishopShifts[sq])];
   {$ENDIF pext}
 end;

Function PieseAttacksBB(Color:integer;PieseTyp : integer;SQ:integer;AllPieses:TBitBoard):TBitBoard;inline;
// Функция определяет битборд атак фигуры с поля.
var
   Res:TBitBoard;
begin
  Res:=0;
  case PieseTyp of
         Pawn   : Res:=PawnAttacks[color,sq];
         Knight : Res:=KnightAttacks[sq];
         Bishop : Res:=BishopAttacksBB(sq,AllPieses);
         Rook   : Res:=RookAttacksBB(sq,AllPieses);
         Queen  : Res:=QueenAttacksBB(sq,AlLpieses);
         King   : Res:=KingAttacks[sq];
       end;
  Result:=Res;
end;

Function SquareAttackedBB(sq:integer;AllPieses:TBitBoard;var Board:Tboard):TBitBoard;inline;
// Битборд фигур обоего цевета, атакующих поле sq
 begin
   Result:=((PawnAttacks[black,sq] and Board.Pieses[Pawn] and Board.Occupancy[white]) or
           (PawnAttacks[white,sq] and Board.Pieses[Pawn] and Board.Occupancy[black]) or
           (KnightAttacks[sq] and (Board.Pieses[Knight])) or
           (KingAttacks[sq] and (Only[Board.KingSq[white]] or Only[Board.KingSq[black]])) or
           (BishopAttacksBB(sq,AllPieses) and (Board.Pieses[Bishop] or Board.Pieses[Queen])) or
           (RookAttacksBB(sq,AllPieses) and (Board.Pieses[Rook] or Board.Pieses[Queen]))) and AllPieses;
 end;

Function ColorOf(Piese:integer):integer;inline;
// Возвращает цвет фигуры на поле (должно быть заведомо непустое!)
begin
  if Piese>Empty
   Then Result:=white
   Else Result:=Black;
end;

Function isLegal(move:integer;Pinned:TBitBoard; var Board:TBoard):boolean;
// Проверяет легальность хода (Не остается ли наш король под шахом после него)
var
  FromSq,DestSq,KingSq,CapSq:integer;
  BB : TBitBoard;
begin
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  // Если взятие на проходе - то более сложная проверка
  if ((move and CaptureFlag)<>0) and (Board.Pos[DestSq]=Empty) then
    begin
      KingSq:=Board.KingSq[Board.SideToMove];
      CapSq:=DestSq-PawnPush[Board.SideToMove];
      BB:=(Board.AllPieses xor (Only[FromSq] or Only[CapSq])) or Only[DestSq];
      Result:=((BishopAttacksBB(KingSq,BB) and (Board.Pieses[Bishop] or Board.Pieses[Queen]) and (Board.Occupancy[Board.SideToMove xor 1])) or
              (  RookAttacksBB(KingSq,BB) and (Board.Pieses[Rook]   or Board.Pieses[Queen]) and (Board.Occupancy[Board.SideToMove xor 1])))=0;

      exit;
    end;
  // Если Ходит король (включая рокировку), то проверяем конечное поле
  If (TypOfPiese[Board.Pos[FromSq]]=King)  then
    begin
      Result:=(SquareAttackedBB(DestSq,Board.AllPieses,Board) and Board.Occupancy[Board.SideToMove xor 1])=0;
      exit;
    end;
  //Иначе проверяем не связана ли ходящая фигура
  Result:=(Pinned=0) or ((Pinned and Only[FromSq])=0) or ((InterSect[Board.KingSq[Board.SideToMove],DestSq] and Only[FromSq])<>0) or ((InterSect[Board.KingSq[Board.SideToMove],FromSq] and Only[DestSq])<>0);
end;

Function FindPinners(color:integer;KingColor:integer;var Board:TBoard):TBitBoard;
// Возвращает связанные фигуры (или кандидаты на вскрытый шах) в зависимости от цвета фигур и цвета короля
var
  BB,Temp: TBitBoard;
  Kingsq,Sq :integer;
  Res:TBitBoard;
begin
  Res:=0;
  KingSq:=Board.KingSq[KingColor];
  BB:=((BishopFullAttacks[KingSq] and (Board.Pieses[Bishop] or Board.Pieses[Queen])) or (RookFullAttacks[KingSq] and (Board.Pieses[Rook] or Board.Pieses[Queen]))) and Board.Occupancy[KingColor xor 1];
  While BB<>0 do
    begin
      sq:=BitScanForward(BB);
      temp:=InterSect[KingSq,sq] and Board.AllPieses;
      if (temp and (temp-1))=0 then res:=res or (temp and Board.Occupancy[color]);
      BB:=BB and (BB-1);
    end;
  Result:=res;
end;

Function isMoveCheck(move:integer;var CheckInfo:TCheckInfo;var Board:TBoard):boolean;
// Функция определяет является ли данный псевдоход шахующим
var
  fromSq,DestSq,CapSq,RookFromSq,RookDestSq : integer;
  BB :TBitBoard;
begin
  Result:=false;
  // Инициализация
  FromSq := move and 63;
  DestSq := (move shr 6) and 63;
  // Является ли ход - прямым шахом королю противника?
  If (CheckInfo.DirectCheckBB[TypOfPiese[Board.Pos[FromSq]]] and Only[DestSq])<>0 then
    begin
      Result:=true;
      exit;
    end;
 // Является ли ход - вскрытым шахом?
 if (CheckInfo.DiscoverCheckBB<>0)  and ((CheckInfo.DiscoverCheckBB and Only[fromSq])<>0) and ((InterSect[FromSQ,CheckInfo.EnemyKingSq] and Only[DestSq])=0) and ((InterSect[DestSQ,CheckInfo.EnemyKingSq] and Only[FromSq])=0)  then
   begin
     Result:=true;
     exit;
   end;

 // Превращения
 if (move and PromoteFlag)<>0 then
   begin
     Result:=(PieseAttacksBB(Board.SideToMove,(move shr 12) and 7,DestSq,Board.AllPieses xor Only[FromSq]) and Only[CheckInfo.EnemyKingSq])<>0;
     exit;
   end;
 // Вскрытый шах через побитую пешку при взятии на проходе
  If ((move and CaptureFlag)<>0) and (Board.Pos[destSq]=Empty) then
    begin
      // Переставляем фигуры на AllPieses битборде соответствующие этому взятию
      CapSq:=DestSQ-PawnPush[Board.SideToMove];
      BB:=(Board.AllPieses xor (Only[FromSq] or Only[CapSq])) or Only[DestSq];
      Result:=((BishopAttacksBB(CheckInfo.EnemyKingSq,BB) and ((Board.Pieses[Bishop] or Board.Pieses[Queen]) and Board.Occupancy[Board.SideToMove])) or
               (  RookAttacksBB(CheckInfo.EnemyKingSq,BB) and ((Board.Pieses[Rook]   or Board.Pieses[Queen]) and Board.Occupancy[Board.SideToMove])))<>0;
      exit;
    end;
  // Рокировка
  if (TypOfPiese[Board.Pos[FromSq]]=King) and ((FromSQ-DestSQ=2) or (FromSq-DestSq=-2)) then
    begin
      if (FromSq-DestSq=-2) then // Короткая
        begin
          RookFromSq:=DestSq+1;
          RookDestSq:=FromSq+1;
        end else
        begin
          RookFromSq:=DestSq-2;
          RookDestSq:=FromSq-1;
        end;
      BB:=(Board.AllPieses xor (Only[FromSq] or Only[RookFromSq])) or Only[DestSq] or Only[RookDestSq];
      Result:=((RookFullAttacks[RookDestSq] and Only[CheckInfo.EnemyKingSq])<>0) and ((RookAttacksBB(RookDestSq,BB) and Only[CheckInfo.EnemyKingSq])<>0);
      exit;
    end;
end;

Function SlowCheck(move:integer;var Board:TBoard):boolean;
//  Медленная проверка специфических ходов на корректность
var
  MoveList:TmoveList;
  i,n:integer;
begin
  n:=GenerateLegals(0,Board,MoveList);
  Result:=false;
  for i:=0 to n-1 do
    If MoveList[i].move=move then
      begin
        Result:=true;
        exit;
      end;
end;
Function MoveisSpec(move:integer;from:integer;dest:integer;piesetyp:integer;var Board:TBoard):boolean;
// определение "нестандартных"  ходов : превращения пешки, взятия на проходе и рокировки
begin
  Result:=false;
  If (move and PromoteFlag)<>0 then   // Превращения пешки
    begin
      Result:=true;
      exit;
    end;
  If ((move and CaptureFlag)<>0) and (piesetyp=pawn) and  (Board.Pos[dest]=Empty) and (dest=Board.EnPassSq) then    //  На проходе
    begin
      Result:=true;
      exit;
    end;
  If (piesetyp=King) and (abs(from-dest)=2) then  // рокировка
    begin
      Result:=true;
      exit;
    end;
end;

Function isPseudoCorrect(move:integer;var Board:TBoard):boolean;
//Проверяет псевдоход на возможность в данной позиции.
var
  FromSq,DestSQ,Piese,CapPiese,PieseTyp,MyColor,d,y,CheckSq : integer;
begin
  Result:=false;
  MyColor:=Board.SideToMove;
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  If FromSq=DestSq then exit;
  Piese:=Board.Pos[FromSq];
  PieseTyp:=TypOfPiese[Piese];
  CapPiese:=Board.Pos[Destsq];
  // Если на поле не фигура нашего цвета
  If (Piese=Empty) or (ColorOf(Piese)<>MyColor) then exit;
  // Если конечное поле занято нашей же фигурой
  If ((Only[DestSq] and Board.Occupancy[MyColor])<>0) then exit;
  // легальность "специальных" ходов выясняем отдельной процедурой
  If MoveIsSpec(move,fromsq,destsq,piesetyp,Board) then
    begin
      Result:=SlowCheck(move,Board);
      exit;
    end;
   //Если не совпадают статус "взятия" проверяемого хода и ситуации на доске
  if (((move and CaptureFlag)<>0) xor (CapPiese<>Empty)) then exit;
  // Специфические пешечные случаи
  If (PieseTyp=Pawn) then
    begin
      if MyColor=White then
        begin
         d:=2;
         y:=8;
        end else
        begin
         d:=7;
         y:=1;
        end;
      // Пешка не может пойти на последнюю горизонталь (превращения мы уже рассмотрели в медленной функции)
      If (Only[destSq] and RanksBB[y])<>0 then exit;
      if (move and CaptureFlag)<>0 then
        begin
          if (PawnAttacks[MyColor,fromSq] and Board.Occupancy[MyColor xor 1] and  Only[DestSq])=0 then exit;// не взятие  (нет фигуры противника на любом из возможных полей взятия пешки)
        end else
        begin
          If (not((FromSQ+PawnPush[MyColor]=DestSQ) and (Board.Pos[DestSq]=Empty)))  and // не простой ход
             (not((FromSq+PawnPush[MyColor]+PawnPush[MyColor]=DestSq) and ((Only[FromSQ] and RanksBB[d])<>0) and (Board.Pos[FromSQ+PawnPush[MyColor]]=Empty) and (Board.Pos[DestSq]=Empty)))  // Не двойной ход
             then exit;
        end;
    end else If ((PieseAttacksBB(MyColor,PieseTyp,FromSq,Board.AllPieses) and Only[DestSq])=0) then exit; // Нельзя этой фигурой так пойти
    // Если нам шах, то смотрим еще специфические случаи
    if Board.CheckersBB<>0 then
      begin
        If PieseTyp<>King then
          begin
            // Если двойной шах то нужен только ход королем:
            if (Board.CheckersBB and (Board.CheckersBB-1))<>0 then exit;
            // Должны этим своим ходом закрыться или побить шахующую
            CheckSq:=BitScanForward(Board.CheckersBB);
            If (not((((Intersect[Board.KingSq[MyColor],CheckSq]) or Only[CheckSq]) and Only[DestSq])<>0))  then exit;
          end else
       If (SquareAttackedBB(DestSQ,(Board.AllPieses xor Only[Fromsq]),Board) and Board.Occupancy[MyColor xor 1])<>0 then exit;
      end;
  Result:=true;
end;
Procedure FillCheckInfo(var CheckInfo:TCheckInfo;var Board:TBoard);
// Устанавливаем важную структуру, помогающую быстро определять шахи, как прямые так и вскрытые, а так же  свои связанные фигуры.
var
  MyColor,EnemyColor : integer;
begin
  MyColor:=Board.SideToMove;
  EnemyColor:=Mycolor xor 1;
  CheckInfo.DiscoverCheckBB:=FindPinners(MyColor,EnemyColor,Board);
  CheckInfo.Pinned:=FindPinners(MyColor,MyColor,Board);
  CheckInfo.EnemyKingSq:=Board.KingSq[EnemyColor];
  CheckInfo.DirectCheckBB[Pawn]:=PawnAttacks[EnemyColor,CheckInfo.EnemyKingSq];
  CheckInfo.DirectCheckBB[Knight]:=KnightAttacks[CheckInfo.EnemyKingSq];
  CheckInfo.DirectCheckBB[Bishop]:=BishopAttacksBB(CheckInfo.EnemyKingSq,Board.AllPieses);
  CheckInfo.DirectCheckBB[Rook]:=RookAttacksBB(CheckInfo.EnemyKingSq,Board.AllPieses);
  CheckInfo.DirectCheckBB[Queen]:=CheckInfo.DirectCheckBB[Bishop] or CheckInfo.DirectCheckBB[Rook];
  CheckInfo.DirectCheckBB[King]:=0;
end;
Function GoodSee(move:integer;var Board:TBoard;margin:integer):boolean;
var
  FromSq,DestSq,MyColor,Piese,curr,sq:integer;
  Occupied,Attackers,MyAttackers,DiagBB,LineBB : TBitBoard;
  Swap : integer;
  EnnPass : boolean;
begin
  // Инициализация
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[FromSq];
  EnnPass:=(((move and CaptureFlag)<>0) and (Board.Pos[DestSq]=Empty));
  // Если рокировка , то вываливаемся сразу выдавая результат тихого хода
  If (TypOfPiese[Piese]=King) and ((FromSq-DestSQ=2) or (FromSq-DestSq=-2)) then
    begin
      Result:=(0>=margin);
      exit;
    end;
  // Цена хода (величина побитой фигуры или 0 для тихого хода) с поправкой на желаемый уровень margin
  if EnnPass
   then Swap:=SeeValues[Pawn]-margin
   else Swap:=SeeValues[TypOfPiese[Board.Pos[DestSq]]]-margin;
  // Если мы заведомо не можем достигнуть своим ходом нужный нам уровень - выходим. Ход "плохой"
  if swap<0 then
    begin
      Result:=false;
      exit;
    end;
  // Смотрим теперь худший вариант (ходящую фигуру побьют в ответ бесплатно)
  Swap:=Swap-SeeValues[TypOfPiese[Piese]];
  // Если даже после этого мы достигаем нужный уровень - выходим. Ход "хороший"
  if swap>=0 then
    begin
      Result:=true;
      exit;
    end;
  // Очередь хода за противником
  MyColor:=PieseColor[piese] xor 1;
  // Ставим ход на доске
  Occupied:=(Board.AllPieses xor Only[FromSq]) or (Only[DestSq]);
  If EnnPass then Occupied:=Occupied xor Only[DestSq-PawnPush[MyColor xor 1]];
  // Ищем все возможные взятия на поле "куда"
  Attackers:=SquareAttackedBB(DestSq,Occupied,Board);
  // Константы для поиска рентгенов
  DiagBB:=Board.Pieses[bishop] or Board.Pieses[queen];
  LineBB:=Board.Pieses[rook] or Board.Pieses[queen];
  // Крутим алгоритм поиска минимальных взятий за каждую из сторон по очереди
  While True do
   begin
    // Обновляем битборд фигур, которые атакуют поле "куда" за оба цвета
    Attackers:=Attackers and Occupied;
    // Есть ли среди них фигуры нужного цвета?
    MyAttackers:=Attackers and Board.Occupancy[MyColor];
    // Если нет - сдаемся. Сторона, чья сейчас очередь хода "проиграла"
    If MyAttackers=0 then break;
    // Ищем нашу фигуру самой меньшей ценности , которая сейчас атакует поле "куда"
    curr:=Pawn;
    while curr<King do
     begin
      if ((Board.Pieses[curr] and MyAttackers)<>0) then break;
      curr:=curr+1;
     end;
    // Если только что побили королем, но у противоположной стороны есть еще удары - то мы проиграли - король бить не может а меньших фигур уже нет
    if (curr=king) and ((Attackers and Board.Occupancy[Mycolor xor 1])<>0) then break;
    // Нашли взятие - меняем очередь хода для следующей итерации
    MyColor:=MyColor xor 1;
    // Обновляем текущий материальный баланс, включая в него только что найденную фигуру (предполагаем худший вариант - что ее могут побить следующим ходом бесплатно)
    swap:=-swap-1-SeeValues[curr];
    // Если мы даже  в худшем случае превышаем уровень - выходим. мы выиграли
    If swap>=0 then  break;
    // Убираем только что найденную фигуру с доски
    if curr=king
      then sq:=Board.KingSq[MyColor xor 1]
      else sq:=BitScanForward(MyAttackers and Board.Pieses[curr]);
    Occupied:=Occupied and (not Only[sq]);
    // Теперь добавляем возможные "рентгены" после того как фигура ушла с доски
    if (curr=pawn) or (curr=bishop) or (curr=queen) then Attackers:=Attackers or (BishopAttacksBB(DestSq,occupied) and DiagBB);
    if (curr=rook) or (curr=queen) then Attackers:=Attackers or (RookAttacksBB(DestSQ,occupied) and LineBB);
   end;
  // На выходе из цикла - очередь хода стороны, которая "проиграла"
  Result:=(PieseColor[piese]<>MyColor);
end;
end.
