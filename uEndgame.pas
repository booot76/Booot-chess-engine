unit uEndgame;

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
F_KPsKW=5;
F_KPsKB=6;
F_KBPsKW=7;
F_KBPsKB=8;
F_KPK=9;
F_KRKP=10;
F_KQKP=11;
F_KQKRP=12;

Function KXK(score:integer;var Board:TBoard):integer;inline;
Function KNNK:integer;inline;
Function KBNK(score:integer;var Board:TBoard):integer;inline;
Function KQKR(score:integer;var Board:TBoard):integer;inline;
Procedure KPSKw(var WScale:integer;var Board:TBoard);inline;
Procedure KPSKb(var BScale:integer;var Board:TBoard);inline;
Procedure KBPSKw(var WScale:integer;var Board:TBoard);inline;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);inline;
Procedure OppositeBishops(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;inline;
Procedure GetSpecialScales(scalenum:integer;var WScale:integer;var BScale:integer;var Board:TBoard);inline;
Function KPK(var Board:TBoard):integer;inline;
Function KRKP(var Board:TBoard):integer;inline;
Function KQKP(var Board:TBoard):integer;inline;
Procedure KQKRP(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
implementation
 uses uMaterial,uKPK;

Function EvaluateSpecialEndgame(funcnum:integer;score:integer;var Board :TBoard):integer;inline;
// ������� �������
begin
  result:=0;
  if FuncNum=F_KXK then result:=KXK(score,Board) else
  if FuncNum=F_KNNK then result:=KNNK else
  if FuncNum=F_KBNK then result:=KBNK(score,Board) else
  if Funcnum=f_KPK then result:=KPK(Board) else
  if FuncNum=F_KQKR then result:=KQKR(score,Board) else
  if FuncNum=F_KRKP then result:=KRKP(Board) else
  if FuncNum=F_KQKP then result:=KQKP(Board) else
  writeln('Unknown Endgame Function Number -',funcnum);
end;
Procedure GetSpecialScales(scalenum:integer;var WScale:integer;var BScale:integer;var Board:TBoard);inline;
// ���������� ���������� ������������ ��� ������������� ���������
begin
  if scalenum=F_KPsKW then KPSKw(WScale,Board) else
  if scalenum=F_KPsKB then KPSKb(BScale,Board) else
  if scalenum=F_KBPsKW then KBPSKw(WScale,Board) else
  if scalenum=F_KBPsKB then KBPSKb(BScale,Board) else
  if scalenum=F_KQKRP then KQKRP(WScale,BScale,Board) else
  writeln('Unknown Scale Function Number- ',scalenum);
end;
Function KPK(var Board:TBoard):integer;inline;
var
  wk,bk,paw,color,res:integer;
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
// ��� ��������� ������ ���� � ��������������� ������� ������� ����� ������������. �� ����� - ����������� ������������ ������ ������� ��������������
// ������ ���������� ������� ������������� ���� ��������� ������ � ���� � ����� �������� ����������� ����������.
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // ����� ������ ���
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // ������ ������ ���
  if Board.SideToMove=black then result:=-result;
end;

Function KNNK:integer;inline;
// ������ ���������� �������� ������. ������ ���� ������������� � ���������� �������
begin
  result:=0;
end;

Function KBNK(score:integer;var Board:TBoard):integer;inline;
// ��� ������ � ����� ������������ ����������� ��������� ������� �������������� � ����� ���� ���� ����� ��������� ������
begin
  if (Board.NonPawnMat[black]=0)  then    // ����� ������ ���
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score+BN_Dark[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // ������������ ����
        else result:=score+BN_Light[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // ����������� ����
    end                           else   // ������ ������ ���
    begin
      if (Board.Pieses[bishop] and DarkSquaresBB)<>0
        then result:=score-BN_Dark[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // ������������ ����
        else result:=score-BN_Light[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]  // ����������� ����
    end;
  if Board.SideToMove=black then result:=-result;
end;

Function KQKR(score:integer;var Board:TBoard):integer;inline;
// ����� ������ ����� ���������� ������� ������ ��� � ��������� ��������� ������
begin
  if (Board.NonPawnMat[black]=0)
   then result:=score+WeakKingMate[Board.KingSq[black]]+KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]]    // ����� ������ ���
   else result:=score-WeakKingMate[Board.KingSq[white]]-KingDistBonus[SquareDist[Board.KingSq[white],Board.KingSq[black]]];  // ������ ������ ���
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
      if (Posy[Ksq]>Posy[Sq]) and ((SquareDIst[Sq+8,KSq]<=1) or (SquareDist[a8,Ksq]<=1)) then Wscale:=0;
    end else
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) then
    begin
      SQ:=BitScanBackWard(PawnsBB and FilesBB[8]);
      if (Posy[Ksq]>Posy[Sq]) and ((SquareDIst[Sq+8,KSq]<=1) or (SquareDist[h8,Ksq]<=1)) then Wscale:=0;
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
      if (Posy[Ksq]<Posy[Sq]) and ((SquareDIst[Sq-8,KSq]<=1) or (SquareDist[a1,Ksq]<=1)) then Bscale:=0;
    end else
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) then
    begin
      SQ:=BitScanForWard(PawnsBB and FilesBB[8]);
      if (Posy[Ksq]<Posy[Sq]) and ((SquareDIst[Sq-8,KSq]<=1) or (SquareDist[h1,Ksq]<=1)) then Bscale:=0;
    end;
end;

Procedure KBPSKw(var WScale:integer;var Board:TBoard);inline;
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[black];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[white];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a8,Ksq]<=1)  then Wscale:=0;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h8,Ksq]<=1)  then Wscale:=0;
end;
Procedure KBPSKb(var BScale:integer;var Board:TBoard);inline;
var
   PawnsBB : TBitBoard;
   KSq : integer;
begin
  KSq:=Board.KingSq[white];
  PawnsBB:=Board.Pieses[pawn] and Board.Occupancy[black];
  if ((PawnsBB and FilesBB[1])<>0) and ((PawnsBB and (not FilesBB[1]))=0) and (SquareDist[a1,Ksq]<=1)  then Bscale:=0;
  if ((PawnsBB and FilesBB[8])<>0) and ((PawnsBB and (not FilesBB[8]))=0) and (SquareDist[h1,Ksq]<=1)  then Bscale:=0;
end;

Procedure OppositeBishops(var WScale:integer;var BScale:integer; var Board:TBoard);inline;
var
  WBB,BBB : TBitBoard;
begin
  WBB:=Board.Pieses[bishop] and Board.Occupancy[white];
  BBB:=Board.Pieses[bishop] and Board.Occupancy[black];
  if (((WBB and DarkSquaresBB)<>0) and ((BBB and LightSquaresBB)<>0)) or (((WBB and LightSquaresBB)<>0) and ((BBB and DarkSquaresBB)<>0))  then
    begin
      if (Board.NonPawnMat[white]=PieseTypValue[bishop]) and (Board.NonPawnMat[black]=PieseTypValue[bishop]) then
        begin
          // ������ ������������ �����
          if (Board.Pieses[pawn] and (Board.Pieses[pawn] -1))=0 then
            begin
              If WScale>ScaleHardWin then WScale:=ScaleHardWin;
              If BScale>ScaleHardWin then BScale:=ScaleHardWin;
            end else
            begin
              If WScale>ScaleOpposit then WScale:=ScaleOpposit;
              If BScale>ScaleOpposit then BScale:=ScaleOpposit;
            end;
        end else
        begin
          WScale:=(WScale*ScaleOnePawn) div ScaleNormal;
          BScale:=(BScale*ScaleOnePawn) div ScaleNormal;
        end;
    end;
end;

Function KRKP(var Board:TBoard):integer;inline;
var
   StrongKing,WeakKing,Rk,pn,QSquare,pawndist,rookdist : integer;
begin
  rk:=BitScanForward(Board.Pieses[rook]);
  pn:=BitScanForward(Board.Pieses[pawn]);
  If (Board.Pieses[pawn] and Board.Occupancy[black])<>0 then
    begin
      // ����� - ���������� �������
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      QSquare:=Posx[pn]-1;
      // ���� ������ ���������� ������� ����� ������ ����� ������ - ��� ������
      If (StrongKing<pn) and (Posx[StrongKing]=Posx[pn]) then
        begin
          Result:=RookValueEnd-SquareDist[StrongKing,Pn];
        end else
        begin
         // ���� ��������� ������ ������ �� ����� � �� ����� ������� - �� �������
         PawnDist:=SquareDist[Pn,WeakKing];
         RookDist:=SquareDist[Rk,WeakKing];
         IF Board.SideToMove=black then dec(PawnDist);
         If (PawnDist>=3) and (RookDist>=3) then
           begin
             Result:=RookValueEnd-SquareDist[StrongKing,Pn];
           end else
           begin
            // ���� ����� ������ ���������� � ���������� ������ ������ - �����
            PawnDist:=SquareDist[StrongKing,Pn];
            If Board.SideToMove=white then dec(PawnDist);
            If (Posy[WeakKing]<=3) and (Posy[StrongKing]>=4) and (SquareDist[Pn,WeakKing]=1) and (PawnDist>2)
              then Result:=32-4*PawnDist
              else Result:=80-4*(SquareDist[StrongKing,Pn-8]-SquareDist[WeakKing,Pn-8]-SquareDist[Pn,QSquare]);
           end;
        end;
    end else
    begin
      // ������ - ���������� �������
      StrongKing:=Board.KingSq[black];
      WeakKing:=Board.KingSq[white];
      QSquare:=56+(Posx[pn]-1);
      // ���� ������ ���������� ������� ����� ������ ����� ������ - ��� ������
      If (StrongKing>pn) and (Posx[StrongKing]=Posx[pn]) then
        begin
          Result:=RookValueEnd-SquareDist[StrongKing,Pn];
        end else
        begin
         // ���� ��������� ������ ������ �� ����� � �� ����� ������� - �� �������
         PawnDist:=SquareDist[Pn,WeakKing];
         RookDist:=SquareDist[Rk,WeakKing];
         IF Board.SideToMove=white then dec(PawnDist);
         If (PawnDist>=3) and (RookDist>=3) then
           begin
             Result:=RookValueEnd-SquareDist[StrongKing,Pn];
           end else
           begin
            // ���� ����� ������ ���������� � ���������� ������ ������ - �����
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
      // ����� - ���������� �������
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      Result:=KingDistBonus[SquareDist[StrongKing,WeakKing]];
      If (Posy[Pn]<>2) or (SquareDist[pn,WeakKing]<>1) or (Posx[pn] in [2,4,5,7]) then Result:=Result+QueenValueEnd-PawnValueEnd;
    end else
    begin
      // ������ - ���������� �������
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
      // ����� - ���������� �������
      StrongKing:=Board.KingSq[white];
      WeakKing:=Board.KingSq[black];
      If (posy[WeakKing]>=7) and (Posy[StrongKing]<=5) and (posy[rook]=6) and ((Board.Pieses[pawn] and KingAttacks[weakKing] and PawnAttacks[white,Rk])<>0)  then WScale:=ScaleDraw;
    end else
    begin
      // ������ - ���������� �������
      StrongKing:=Board.KingSq[black];
      WeakKing:=Board.KingSq[white];
      If (posy[WeakKing]<=2) and (Posy[StrongKing]>=4) and (posy[rook]=3) and ((Board.Pieses[pawn] and KingAttacks[weakKing] and PawnAttacks[black,Rk])<>0)  then BScale:=ScaleDraw;
    end;
end;
end.