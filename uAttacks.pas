unit uAttacks;

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
Procedure FillCheckInfo(var CheckInfo:TCheckInfo;var Board:TBoard);inline;
Function FindPinners(color:integer;KingColor:integer;var Board:TBoard):TBitBoard; inline;
Function isMoveCheck(move:integer;var CheckInfo:TCheckInfo;var Board:TBoard):boolean;inline;
Function isLegal(move:integer;Pinned:TBitBoard; var Board:TBoard):boolean; inline;
Function isPseudoCorrect(move:integer;var Board:TBoard):boolean;inline;
Function GoodSee(move:integer;var Board:TBoard;margin:integer):boolean;inline;
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
Function SlowCheck(move:integer;var Board:TBoard):boolean;inline;
//  ��������� �������� ������������� ����� �� ������������
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
Function MoveisSpec(move:integer;from:integer;dest:integer;piese:integer;var Board:TBoard):boolean; inline;
begin
  Result:=false;
  If (move and PromoteFlag)<>0 then   // �����������
    begin
      Result:=true;
      exit;
    end;
  If ((move and CaptureFlag)<>0) and (TypOfPiese[piese]=pawn) and  (Board.Pos[dest]=Empty) and (dest=Board.EnPassSq) then    //  �� �������
    begin
      Result:=true;
      exit;
    end;
  If (TypOfPiese[piese]=King) and (abs(from-dest)=2) then  // ���������
    begin
      Result:=true;
      exit;
    end;
end;

Function isPseudoCorrect(move:integer;var Board:TBoard):boolean;
//��������� ��������� �� ����������� � ������ �������.
var
  FromSq,DestSQ,Piese,PieseTyp,MyColor,d,y,CheckSq : integer;
begin
  Result:=false;
  MyColor:=Board.SideToMove;
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  If FromSq=DestSq then exit;
  Piese:=Board.Pos[FromSq];
  If MoveIsSpec(move,fromsq,destsq,piese,Board) then
    begin
      Result:=SlowCheck(move,Board);
      exit;
    end;
  // ���� �� ���� �� ������ ������ �����
  If (Piese=Empty) or (ColorOf(Piese)<>MyColor) then exit;
  // ���� �������� ���� ������ ����� �� �������
  If ((Only[DestSq] and Board.Occupancy[MyColor])<>0) then exit;
  PieseTyp:=TypOfPiese[Piese];
  // ������������� �������� ������
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
      // ����� �� ����� ����� �� ��������� �����������
      If (Only[destSq] and RanksBB[y])<>0 then exit;
      if (move and CaptureFlag)<>0 then
        begin
          if (PawnAttacks[MyColor,fromSq] and Board.Pieses[MyColor xor 1] and  Only[DestSq])=0 then exit; // �� ������
        end else
        begin
          If (not((FromSQ+PawnPush[MyColor]=DestSQ) and (Board.Pos[DestSq]=Empty)))  and // �� ������� ���
             (not((FromSq+PawnPush[MyColor]+PawnPush[MyColor]=DestSq) and ((Only[FromSQ] and RanksBB[d])<>0) and (Board.Pos[FromSQ+PawnPush[MyColor]]=Empty) and (Board.Pos[DestSq]=Empty)))  // �� ������� ���
             then exit;
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
            If (not((((Intersect[Board.KingSq[MyColor],CheckSq]) or Only[CheckSq]) and Only[DestSq])<>0))  then exit;
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
Function GoodSee(move:integer;var Board:TBoard;margin:integer):boolean;inline;
var
  FromSq,DestSq,MyColor,Piese,curr,sq:integer;
  Occupied,Attackers,MyAttackers,DiagBB,LineBB : TBitBoard;
  Swap : integer;
  EnnPass : boolean;
begin
  // �������������
  FromSq:=move and 63;
  DestSq:=(move shr 6) and 63;
  Piese:=Board.Pos[FromSq];
  EnnPass:=(((move and CaptureFlag)<>0) and (Board.Pos[DestSq]=Empty));
  // ���� ��������� , �� ������������ ����� ������� ��������� ������ ����
  If (TypOfPiese[Piese]=King) and ((FromSq-DestSQ=2) or (FromSq-DestSq=-2)) then
    begin
      Result:=(0>=margin);
      exit;
    end;
  // ���� ���� (�������� ������� ������ ��� 0 ��� ������ ����) � ��������� �� �������� ������� margin
  if EnnPass
   then Swap:=SeeValues[Pawn]-margin
   else Swap:=SeeValues[TypOfPiese[Board.Pos[DestSq]]]-margin;
  // ���� �� �������� �� ����� ���������� ����� ����� ������ ��� ������� - �������. ��� "������"
  if swap<0 then
    begin
      Result:=false;
      exit;
    end;
  // ������� ������ ������ ������� (������� ������ ������ � ����� ���������)
  Swap:=Swap-SeeValues[TypOfPiese[Piese]];
  // ���� ���� ����� ����� �� ��������� ������ ������� - �������. ��� "�������"
  if swap>=0 then
    begin
      Result:=true;
      exit;
    end;
  // ������� ���� �� �����������
  MyColor:=PieseColor[piese] xor 1;
  // ������ ��� �� �����
  Occupied:=(Board.AllPieses xor Only[FromSq]) or (Only[DestSq]);
  If EnnPass then Occupied:=Occupied xor Only[DestSq-PawnPush[MyColor xor 1]];
  // ���� ��� ��������� ������ �� ���� "����"
  Attackers:=SquareAttackedBB(DestSq,Occupied,Board);
  // ��������� ��� ������ ���������
  DiagBB:=Board.Pieses[bishop] or Board.Pieses[queen];
  LineBB:=Board.Pieses[rook] or Board.Pieses[queen];
  // ������ �������� ������ ����������� ������ �� ������ �� ������ �� �������
  While True do
   begin
    // ��������� ������� �����, ������� ������� ���� "����" �� ��� �����
    Attackers:=Attackers and Occupied;
    // ���� �� ����� ��� ������ ������� �����?
    MyAttackers:=Attackers and Board.Occupancy[MyColor];
    // ���� ��� - �������. �������, ��� ������ ������� ���� "���������"
    If MyAttackers=0 then break;
    // ���� ���� ������ ����� ������� �������� , ������� ������ ������� ���� "����"
    curr:=Pawn;
    while curr<King do
     begin
      if ((Board.Pieses[curr] and MyAttackers)<>0) then break;
      curr:=curr+1;
     end;
    // ���� ������ ��� ������ �������, �� � ��������������� ������� ���� ��� ����� - �� �� ��������� - ������ ���� �� ����� � ������� ����� ��� ���
    if (curr=king) and ((Attackers and Board.Occupancy[Mycolor xor 1])<>0) then break;
    // ����� ������ - ������ ������� ���� ��� ��������� ��������
    MyColor:=MyColor xor 1;
    // ��������� ������� ������������ ������, ������� � ���� ������ ��� ��������� ������ (������������ ������ ������� - ��� �� ����� ������ ��������� ����� ���������)
    swap:=-swap-1-SeeValues[curr];
    // ���� �� ����  � ������ ������ ��������� ������� - �������. �� ��������
    If swap>=0 then  break;
    // ������� ������ ��� ��������� ������ � �����
    if curr=king
      then sq:=Board.KingSq[MyColor xor 1]
      else sq:=BitScanForward(MyAttackers and Board.Pieses[curr]);
    Occupied:=Occupied and (not Only[sq]);
    // ������ ��������� ��������� "��������" ����� ���� ��� ������ ���� � �����
    if (curr=pawn) or (curr=bishop) or (curr=queen) then Attackers:=Attackers or (BishopAttacksBB(DestSq,occupied) and DiagBB);
    if (curr=rook) or (curr=queen) then Attackers:=Attackers or (RookAttacksBB(DestSQ,occupied) and LineBB);
   end;
  // �� ������ �� ����� - ������� ���� �������, ������� "���������"
  Result:=(PieseColor[piese]<>MyColor);
end;
end.
