unit uAttacks;

interface
uses uBitBoards,uMagic,uBoard;

Const
  SeeValues  : array[Pawn..King] of integer =(100,300,300,500,900,0);
  PieseColor : array[-King..King] of integer=(black,black,black,black,black,black,white,white,white,white,white,white,white);
  PositiveSee=10000;

Function KnightAttacksBB(sq:integer):TBitBoard;inline;
Function KingAttacksBB(sq:integer):TBitBoard;inline;
Function BishopAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function RookAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function QueenAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
Function PieseAttacksBB(Color:integer;PieseTyp : integer;SQ:integer;AllPieses:TBitBoard):TBitBoard;inline;
Function SquareAttackedBB(sq:integer;AllPieses:TBitBoard;var Board:Tboard):TBitBoard;
Procedure FillCheckInfo(var CheckInfo:TCheckInfo;var Board:TBoard);inline;
Function FindPinners(color:integer;KingColor:integer;var Board:TBoard):TBitBoard; inline;
Function isMoveCheck(move:integer;var CheckInfo:TCheckInfo;var Board:TBoard):boolean;inline;
Function isLegal(move:integer;Pinned:TBitBoard; var Board:TBoard):boolean; inline;
Function isPseudoCorrect(move:integer;var Board:TBoard):boolean;inline;
Function See(move:integer;var Board:TBoard):integer; inline;
Function QuickSee(move:integer;var Board:TBoard):integer;inline;

implementation

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
   Result:=BishopMM[BishopOffset[sq]+(((allpieses and BishopMasks[sq])*BishopMagics[sq]) shr BishopShifts[sq])];
 end;
Function RookAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
 begin
   Result:=RookMM[RookOffset[sq]+(((allpieses and RookMasks[sq])*RookMagics[sq]) shr RookShifts[sq])];
 end;
Function QueenAttacksBB(sq:integer;allpieses:TBitBoard):TBitBoard;inline;
 begin
   Result:=RookMM[RookOffset[sq]+(((allpieses and RookMasks[sq])*RookMagics[sq]) shr RookShifts[sq])] or BishopMM[BishopOffset[sq]+(((allpieses and BishopMasks[sq])*BishopMagics[sq]) shr BishopShifts[sq])];
 end;

Function PieseAttacksBB(Color:integer;PieseTyp : integer;SQ:integer;AllPieses:TBitBoard):TBitBoard;inline;
// ������� ���������� ������� ���� ������ � ����.
var
   Res:TBitBoard;
begin
  Res:=0;
  case PieseTyp of
         Pawn : Res:=PawnAttacks[color,sq];
         Knight : Res:=KnightAttacks[sq];
         Bishop : Res:=BishopAttacksBB(sq,AllPieses);
         Rook   : Res:=RookAttacksBB(sq,AllPieses);
         Queen  : Res:=QueenAttacksBB(sq,AlLpieses);
         King   : Res:=KingAttacks[sq];
       end;
  Result:=Res;
end;

Function SquareAttackedBB(sq:integer;AllPieses:TBitBoard;var Board:Tboard):TBitBoard;inline;
// ������� ����� ������ ������, ��������� ���� sq
 begin
   Result:=((PawnAttacks[black,sq] and Board.Pieses[Pawn] and Board.Occupancy[white]) or
           (PawnAttacks[white,sq] and Board.Pieses[Pawn] and Board.Occupancy[black]) or
           (KnightAttacks[sq] and (Board.Pieses[Knight])) or
           (KingAttacks[sq] and (Only[Board.KingSq[white]] or Only[Board.KingSq[black]])) or
           (BishopAttacksBB(sq,AllPieses) and (Board.Pieses[Bishop] or Board.Pieses[Queen])) or
           (RookAttacksBB(sq,AllPieses) and (Board.Pieses[Rook] or Board.Pieses[Queen]))) and AllPieses;
 end;

Function isLegal(move:integer;Pinned:TBitBoard; var Board:TBoard):boolean;inline;
// ��������� ����������� ���� (�� �������� �� ��� ������ ��� ����� ����� ����)
var
  FromSq,DestSq,KingSq,CapSq:integer;
  BB : TBitBoard;
begin
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  // ���� ������ �� ������� - �� ����� ������� ��������
  if ((move and CaptureFlag)<>0) and (Board.Pos[DestSq]=Empty) then
    begin
      KingSq:=Board.KingSq[Board.SideToMove];
      CapSq:=DestSq-PawnPush[Board.SideToMove];
      BB:=(Board.AllPieses xor (Only[FromSq] or Only[CapSq])) or Only[DestSq];
      Result:=((BishopAttacksBB(KingSq,BB) and (Board.Pieses[Bishop] or Board.Pieses[Queen]) and (Board.Occupancy[Board.SideToMove xor 1])) or
              (  RookAttacksBB(KingSq,BB) and (Board.Pieses[Rook]   or Board.Pieses[Queen]) and (Board.Occupancy[Board.SideToMove xor 1])))=0;

      exit;
    end;
  // ���� ����� ������ (������� ���������), �� ��������� �������� ����
  If (TypOfPiese[Board.Pos[FromSq]]=King)  then
    begin
      Result:=(SquareAttackedBB(DestSq,Board.AllPieses,Board) and Board.Occupancy[Board.SideToMove xor 1])=0;
      exit;
    end;
  //����� ��������� �� ������� �� ������� ������
  Result:=(Pinned=0) or ((Pinned and Only[FromSq])=0) or ((InterSect[Board.KingSq[Board.SideToMove],DestSq] and Only[FromSq])<>0) or ((InterSect[Board.KingSq[Board.SideToMove],FromSq] and Only[DestSq])<>0);
end;

Function FindPinners(color:integer;KingColor:integer;var Board:TBoard):TBitBoard; inline;
// ���������� ��������� ������ (��� ��������� �� �������� ���) � ����������� �� ����� ����� � ����� ������
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

Function isMoveCheck(move:integer;var CheckInfo:TCheckInfo;var Board:TBoard):boolean; inline;
// ������� ���������� �������� �� ������ ��������� ��������
var
  fromSq,DestSq,CapSq,RookFromSq,RookDestSq : integer;
  BB :TBitBoard;
begin
  Result:=false;
  // �������������
  FromSq := move and 63;
  DestSq := (move shr 6) and 63;
  // �������� �� ��� - ������ ����� ������ ����������?
  If (CheckInfo.DirectCheckBB[TypOfPiese[Board.Pos[FromSq]]] and Only[DestSq])<>0 then
    begin
      Result:=true;
      exit;
    end;
 // �������� �� ��� - �������� �����?
 if (CheckInfo.DiscoverCheckBB<>0)  and ((CheckInfo.DiscoverCheckBB and Only[fromSq])<>0) and ((InterSect[FromSQ,CheckInfo.EnemyKingSq] and Only[DestSq])=0) and ((InterSect[DestSQ,CheckInfo.EnemyKingSq] and Only[FromSq])=0)  then
   begin
     Result:=true;
     exit;
   end;

 // �����������
 if (move and PromoteFlag)<>0 then
   begin
     Result:=(PieseAttacksBB(Board.SideToMove,(move shr 12) and 7,DestSq,Board.AllPieses xor Only[FromSq]) and Only[CheckInfo.EnemyKingSq])<>0;
     exit;
   end;
 // �������� ��� ����� ������� ����� ��� ������ �� �������
  If ((move and CaptureFlag)<>0) and (Board.Pos[destSq]=Empty) then
    begin
      // ������������ ������ �� AllPieses �������� ��������������� ����� ������
      CapSq:=DestSQ-PawnPush[Board.SideToMove];
      BB:=(Board.AllPieses xor (Only[FromSq] or Only[CapSq])) or Only[DestSq];
      Result:=((BishopAttacksBB(CheckInfo.EnemyKingSq,BB) and ((Board.Pieses[Bishop] or Board.Pieses[Queen]) and Board.Occupancy[Board.SideToMove])) or
               (  RookAttacksBB(CheckInfo.EnemyKingSq,BB) and ((Board.Pieses[Rook]   or Board.Pieses[Queen]) and Board.Occupancy[Board.SideToMove])))<>0;
      exit;
    end;
  // ���������
  if (TypOfPiese[Board.Pos[FromSq]]=King) and ((FromSQ-DestSQ=2) or (FromSq-DestSq=-2)) then
    begin
      if (FromSq-DestSq=-2) then // ��������
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
Function ColorOf(Piese:integer):integer;inline;
// ���������� ���� ������ �� ���� (������ ���� �������� ��������!)
begin
  if Piese>Empty
   Then Result:=white
   Else Result:=Black;
end;

Function isPseudoCorrect(move:integer;var Board:TBoard):boolean; inline;
//��������� ��������� �� ����������� � ������ �������.
var
  FromSq,DestSQ,Piese,PieseTyp,MyColor,d,y,CheckSq : integer;
begin
  Result:=false;
  MyColor:=Board.SideToMove;
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[FromSq];
  // ���� �� ���� �� ������ ������ �����
  If (Piese=Empty) or (ColorOf(Piese)<>MyColor) then exit;
  // ���� �������� ���� ������ ����� �� �������
  If ((Only[DestSq] and Board.Occupancy[MyColor])<>0) then exit;
  PieseTyp:=TypOfPiese[Piese];
  // ������������� ������
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
      if (move and CaptureFlag)<>0 then
        begin
          if (PawnAttacks[MyColor,fromSq] and Only[DestSq])=0 then exit; // �� ������
          IF ((Board.Occupancy[MyColor xor 1] and Only[DestSQ])=0) and (Board.EnPassSq<>DestSq) then exit; // ������ ������  � �� �� �������!
        end else
        begin
          If (not((FromSQ+PawnPush[MyColor]=DestSQ) and (Board.Pos[DestSq]=Empty)))  and // �� ������� ���
             (not((FromSq+PawnPush[MyColor]+PawnPush[MyColor]=DestSq) and ((Only[FromSQ] and RanksBB[d])<>0) and (Board.Pos[FromSQ+PawnPush[MyColor]]=Empty) and (Board.Pos[DestSq]=Empty)))  // �� ������� ���
             then exit;
        end;
       if ((move and PromoteFlag)<>0) and ((RanksBB[y] and Only[DestSQ])=0) then exit; // �� �����������
    end else
  if (PieseTyp=King) and ((FromSq-DestSq=2) or (FromSq-DestSq=-2)) then
    begin
      if MyColor=White then
        begin
          if (not((FromSq-DestSq=-2) and ((Board.CastleRights and WhiteShortCastleMask)<>0) and ((Board.AllPieses and W00SQ)=0) and ((SquareAttackedBB(f1,Board.AllPieses,Board) and Board.Occupancy[black])=0))) and    // �� ��������
             (not(( FromSq-DestSq=2) and ((Board.CastleRights and WhiteLongCastleMask)<>0) and ((Board.AllPieses and W000SQ)=0) and ((SquareAttackedBB(d1,Board.AllPieses,Board) and Board.Occupancy[black])=0)))  then exit;  // �� �������
        end else
        begin
          if (not((FromSq-DestSq=-2) and ((Board.CastleRights and BlackShortCastleMask)<>0) and ((Board.AllPieses and B00SQ)=0) and ((SquareAttackedBB(f8,Board.AllPieses,Board) and Board.Occupancy[white])=0))) and    // �� ��������
             (not(( FromSq-DestSq=2) and ((Board.CastleRights and BlackLongCastleMask)<>0) and ((Board.AllPieses and B000SQ)=0) and ((SquareAttackedBB(d8,Board.AllPieses,Board) and Board.Occupancy[white])=0)))  then exit;  // �� �������
        end;
    end else If ((PieseAttacksBB(MyColor,PieseTyp,FromSq,Board.AllPieses) and Only[DestSq])=0) then exit; // ������ ���� ������� ��� �����
    // ���� ��� ���, �� ������� ��� ������������� ������
    if Board.CheckersBB<>0 then
      begin
        If PieseTyp<>King then
          begin
            // ���� ������� ��� �� ����� ������ ��� �������:
            if (Board.CheckersBB and (Board.CheckersBB-1))<>0 then exit;
            // ������ ���� ����� ����� ��������� ��� ������ �������� (������� �� �������!)
            CheckSq:=BitScanForward(Board.CheckersBB);
            If (not((((Intersect[Board.KingSq[MyColor],CheckSq]) or Only[CheckSq]) and Only[DestSq])<>0)) and
               (not(((CheckSq+PawnPush[MyColor]=DestSq) and (Board.EnPassSq=DestSq) and (PieseTyp=Pawn) and ((move and CaptureFlag)<>0)))) then exit;
          end else
       If (SquareAttackedBB(DestSQ,(Board.AllPieses xor Only[Fromsq]),Board) and Board.Occupancy[MyColor xor 1])<>0 then exit;
      end;
  Result:=true;
end;
Procedure FillCheckInfo(var CheckInfo:TCheckInfo;var Board:TBoard);
// ������������� ������ ���������, ���������� ������ ���������� ����, ��� ������ ��� � ��������, � ��� ��  ���� ��������� ������.
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
Function FindMinAttacker(Square:integer;MyAttackers:TBitBoard;var Occupied:TBitBoard;var Attackers:TBitBoard;var Board:TBoard):integer;inline;
// ���� ����� ���������� ������ ��������� ���� � ����� �� ��� ��������
var
  Temp : TBitBoard;
  sq,piese : integer;
begin
  if (Board.Pieses[Pawn]   and MyAttackers)<>0 then
    begin
      temp:=Board.Pieses[Pawn] and MyAttackers;
      Piese:=Pawn;
    end else
  if (Board.Pieses[knight] and MyAttackers)<>0 then
    begin
      temp:=Board.Pieses[knight] and MyAttackers;
      Piese:=Knight;
    end else
  if (Board.Pieses[bishop] and MyAttackers)<>0 then
    begin
      temp:=Board.Pieses[bishop] and MyAttackers;
      Piese:=bishop;
    end else
  if (Board.Pieses[rook]   and MyAttackers)<>0 then
    begin
      temp:=Board.Pieses[rook]   and MyAttackers;
      Piese:=rook;
    end else
  if (Board.Pieses[queen]  and MyAttackers)<>0 then
    begin
      temp:=Board.Pieses[queen]  and MyAttackers;
      piese:=queen;
    end else
    begin
      Result:=king;
      exit;
    end;
  sq:=BitScanForward(Temp);
  Occupied:=Occupied xor Only[sq];
  if (piese=pawn) or (piese=bishop) or (piese=queen) then Attackers:=Attackers or (BishopAttacksBB(square,occupied) and (Board.Pieses[bishop] or Board.Pieses[queen]));
  if (piese=rook) or (piese=queen) then Attackers:=Attackers or (RookAttacksBB(square,occupied) and (Board.Pieses[rook] or Board.Pieses[queen]));
  Attackers:=Attackers and Occupied;
  Result:=Piese;
end;
Function See(move:integer;var Board:TBoard):integer;inline;
var
  FromSq,DestSq,captured,MyColor,Piese,index:integer;
  Occupied,Attackers,MyAttackers : TBitBoard;
  Swap : array[0..31] of integer;
begin
  // �������������
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[FromSq];
  // ���� ��������� , �� ������������ �����
  If (TypOfPiese[Piese]=King) and ((FromSq-DestSQ=2) or (FromSq-DestSq=-2)) then
    begin
      Result:=0;
      exit;
    end;
  MyColor:=PieseColor[Piese];
  Swap[0]:=SeeValues[TypOfPiese[Board.Pos[DestSq]]];
  Occupied:=Board.AllPieses and (not  Only[FromSq]);
  // ���� ������ �� �������, �� ������ ��������� ���������
  if ((move and CaptureFlag)<>0) and (Board.Pos[DestSq]=Empty) then
    begin
      Occupied:=Occupied xor Only[DestSq-PawnPush[MyColor]];
      Swap[0]:=SeeValues[pawn];
    end;
  // ���� ��� ��������� ������
  Attackers:=SquareAttackedBB(DestSq,Occupied,Board);
  // ���� � ���������� ��� ������ �� �������
  MyColor:=MyColor xor 1;
  MyAttackers:=Attackers and Board.Occupancy[MyColor];
  if MyAttackers=0 then
    begin
      Result:=Swap[0];
      exit;
    end;
  captured:=TypOfPiese[Board.Pos[FromSq]];
  index:=0;
  // ������ �������� ������ ����������� ������ � ������ �������
  Repeat
    inc(index);
    Swap[index]:=-Swap[index-1]+SeeValues[captured];
   // writeln(index,' ',swap[index]);
    captured:=FindMinAttacker(DestSq,MyAttackers,Occupied,Attackers,Board);
    MyColor:=MyColor xor 1;
    MyAttackers:=Attackers and Board.Occupancy[MyColor];
  Until (MyAttackers=0) or (captured=king);
  if (captured=king) and (MyAttackers<>0) then dec(index);
  while index>0 do
    begin
      if -Swap[index]<Swap[index-1]
        then Swap[index-1]:=-Swap[index];
      //writeln(swap[index-1]);
      dec(index);
    end;
  Result:=Swap[0];
end;
Function QuickSee(move:integer;var Board:TBoard):integer;inline;
begin
  if (SeeValues[TypOfPiese[Board.Pos[(move and 63)]]]<=SeeValues[TypOfPiese[Board.Pos[(move shr 6) and 63]]]) then
    begin
      Result:=PositiveSee;
      exit;
    end;
  Result:=See(move,Board);
end;
end.
