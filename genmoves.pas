unit genmoves;
// ���� �������� �� ������������� "�������" ����� �� �����
interface
uses params,bitboards,attacks;

Procedure GetMoves(color:integer;ply:integer);
Procedure GetMovesAll(color:integer;ply:integer);
implementation

Procedure GetMoves(color:integer;ply:integer);
// ������� ���������� ��������������� "������� ���� �� �����":
// 1. ��� ����-�� ������ ����� � �����.
// 2. ������ �������� ����������� (����������� � ����� ������� ������� GetCaptures)
// 3. ������ �������� ����������� �� ������� (����������� � ����� �� ������� ������� ������� GetCaptures)
// 4. ��������� (���� ��� ��������)
var
   temp,attack,space,pawnm,doublem:bitboard;
   from,dest,count,point,indx,piese : integer;
   shablon,shablon1 : move;
  begin
    // ��������� ������ � ������� �����
    point:=ply shl 7;
    count:=point;
    // ������������� ������ ��������� ����
    space:=not AllPieses;
if color=white then
 Begin
    // ���� �����
    temp:=WhiteKnights;
    shablon:=(knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

   // ���� ������
    temp:=WhiteBishops;
    shablon:=(bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ������ �������
    temp:=WhiteRooks;
    shablon:=(rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   // ������ �������
    temp:=WhiteQueens;
    shablon:=(queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ��� �������
        from:=tree[ply].wking;
        attack:=KingsMove[from] and space;
        shablon1:=(king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;

     // �������� ����
     // ������� � ������� ����
     pawnm:=(WhitePawns shl 8) and space;
     doublem:=((pawnm and Ranks[3]) shl 8) and space;
     // �������
     while pawnm<>0 do
       begin
         dest:=BitScanForward(pawnm);
         inc(count);
         if dest<a8
             then
                  moves[count]:=(pawn shl 16) or (dest shl 8) or (dest-8)
             else begin
                  // ���������� ������ ����������� (������� ���� ������������� �����)
                  moves[count]:=Promoteflag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  inc(count);
                  moves[count]:=Promoteflag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  inc(count);
                  moves[count]:=Promoteflag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  end;
         pawnm:=pawnm and NotOnly[dest];
       end;


     // ... � ������� ����
     while doublem<>0 do
       begin
         dest:=BitScanForward(doublem);
         inc(count);
         moves[count]:=(pawn shl 16) or (dest shl 8) or (dest-16);
         doublem:=doublem and NotOnly[dest];
       end;
    // ���������� �������� ������ �� ������� ������������� ( ������ � �������� ������������� ���� ������������� �����)
    space:=BlackPieses and Ranks[8];
    // ������ �����
    temp:=((WhitePawns and noafile) shl 7) and space;
    while temp<>0 do
      begin
        dest:=BitScanForward(temp);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag  or (knight shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag  or (rook shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag  or (bishop shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
        temp:=temp and NotOnly[dest];
      end;
    // ������ ������
    temp:=((WhitePawns and nohfile) shl 9) and space;
    while temp<>0 do
      begin
        dest:=BitScanForward(temp);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag  or (knight shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (rook shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (bishop shl 24) or ((-WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
        temp:=temp and NotOnly[dest];
      end;
    // ���������� ���������
    if (tree[ply].Castle and 3)<>0 then
        begin
          if ((tree[ply].Castle and 1)<>0) and ((AllPieses and wshortmask)=0)
              and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[h1])<>0)
              and (not IsBlackAttacks(f1))
              then
            begin
              inc(count);
              moves[count]:=wshort;
            end;
          if ((tree[ply].Castle and 2)<>0) and ((AllPieses and wlongmask)=0)
              and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[a1])<>0)
              and (not IsBlackAttacks(d1))
              then
            begin
              inc(count);
              moves[count]:=wlong;
            end;
        end;
   
 end
          else
 Begin
   // ���� �����
    temp:=BlackKnights;
    shablon:=(knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

   // ���� ������
    temp:=BlackBishops;
    shablon:=(bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ������ �������
    temp:=BlackRooks;
    shablon:=(rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   // ������ �������
    temp:=BlackQueens;
    shablon:=(queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ��� �������
        from:=tree[ply].Bking;
        attack:=KingsMove[from] and space;
        shablon1:=(king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            moves[count]:=shablon1 or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;

     // �������� ����
     // ������� � ������� ����
     pawnm:=(BlackPawns shr 8) and space;
     doublem:=((pawnm and Ranks[6]) shr 8) and space;
     // �������
     while pawnm<>0 do
       begin
         dest:=BitScanForward(pawnm);
         inc(count);
         if dest>h1
             then
                  moves[count]:=(pawn shl 16) or (dest shl 8) or (dest+8)
             else begin
                  // ���������� ������ ����������� (������� ���� ������������� �����)
                  moves[count]:=Promoteflag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  inc(count);
                  moves[count]:=Promoteflag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  inc(count);
                  moves[count]:=Promoteflag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  end;
         pawnm:=pawnm and NotOnly[dest];
       end;
     // ... � ������� ����
     while doublem<>0 do
       begin
         dest:=BitScanForward(doublem);
         inc(count);
         moves[count]:=(pawn shl 16) or (dest shl 8) or (dest+16);
         doublem:=doublem and NotOnly[dest];
       end;
    // ���������� �������� ������ �� ������� ������������� ( ������ � �������� ������������� ���� ������������� �����)
    space:=WhitePieses and Ranks[1];
    // ������ �����
    temp:=((BlackPawns and noafile) shr 9) and space;
    while temp<>0 do
      begin
        dest:=BitScanForward(temp);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (knight shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (rook shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (bishop shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
        temp:=temp and NotOnly[dest];
      end;
    // ������ ������
    temp:=((BlackPawns and nohfile) shr 7) and space;
    while temp<>0 do
      begin
        dest:=BitScanForward(temp);

        inc(count);
        moves[count]:=Promoteflag or  CaptureFlag or (knight shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (rook shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
        inc(count);
        moves[count]:=Promoteflag or CaptureFlag or (bishop shl 24) or ((WhatPiese(dest)) shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
        temp:=temp and NotOnly[dest];
      end;
    // ���������� ���������
    if (tree[ply].Castle and 12)<>0 then
        begin
          if ((tree[ply].Castle and 4)<>0) and ((AllPieses and bshortmask)=0)
              and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[h8])<>0)
              and (not IsWhiteAttacks(f8)) //and (not IsWhiteAttacks(g8))
               then
            begin
              inc(count);
              moves[count]:=bshort;
            end;
          if ((tree[ply].Castle and 8)<>0) and ((AllPieses and blongmask)=0)
              and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[a8])<>0)
              and (not IsWhiteAttacks(d8)) //and (not IsWhiteAttacks(c8))
              then
            begin
              inc(count);
              moves[count]:=blong;
            end;

        end;

 end;
   // ���������� ��������� ������� �����
   moves[point]:=count-point;

end;
Procedure GetMovesAll(color:integer;ply:integer);
// ������� ���������� ��� ��������������� ����:
var
   temp,attack,space,pawnm,doublem,clearf:bitboard;
   from,dest,count,point,indx,piese : integer;
   shablon,shablon1 : move;
  begin
    // ��������� ������ � ������� �����
    point:=ply shl 7;
    count:=point;
    clearf:=not AllPieses;
if color=white then
 Begin
    // ������������� ������ ��������� ������ �������� ����
    space:=not WhitePieses;
    // ���� �����
    temp:=WhiteKnights;
    shablon:=(knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and BlackPieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or ((-WhatPiese(dest)) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

   // ���� ������
    temp:=WhiteBishops;
    shablon:=(bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and BlackPieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or ((-WhatPiese(dest)) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // �������
    temp:=WhiteRooks;
    shablon:=(rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and BlackPieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or ((-WhatPiese(dest)) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   //  �������
    temp:=WhiteQueens;
    shablon:=(queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and BlackPieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or ((-WhatPiese(dest)) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // �������
        from:=tree[ply].wking;
        attack:=KingsMove[from] and space;
        shablon1:=(king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and BlackPieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or ((-WhatPiese(dest)) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;

     // �������� ����
     // ������� � ������� ����
     pawnm:=(WhitePawns shl 8) and clearf;
     doublem:=((pawnm and Ranks[3]) shl 8) and clearf;
     // �������
     while pawnm<>0 do
       begin
         dest:=BitScanForward(pawnm);
         inc(count);
         if dest<a8
             then
                  moves[count]:=(pawn shl 16) or (dest shl 8) or (dest-8)
             else begin
                  // ����������  �����������
                  moves[count]:=Promoteflag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  inc(count);
                  moves[count]:=Promoteflag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  inc(count);
                  moves[count]:=Promoteflag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  inc(count);
                  moves[count]:=Promoteflag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                  end;
         pawnm:=pawnm and NotOnly[dest];
       end;
     // ... � ������� ����
     while doublem<>0 do
       begin
         dest:=BitScanForward(doublem);
         inc(count);
         moves[count]:=(pawn shl 16) or (dest shl 8) or (dest-16);
         doublem:=doublem and NotOnly[dest];
       end;
    // ���������� �������� ������
    if tree[ply].EnnPass<>0
       then
           space:=BlackPieses or Only[tree[ply].EnnPass]
       else
           space:=BlackPieses;
    //������ ����� "�����"
     temp :=((WhitePawns and noafile) shl 7) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest<a8) then
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 moves[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest-7)
                              else
                 moves[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
             end
                      else
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
             end;
         temp:=temp and NotOnly[dest];
       end;
    //������ ����� "������"
     temp :=((WhitePawns and nohfile) shl 9) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest<a8) then
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 moves[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest-9)
                              else
                 moves[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
             end
                      else
             begin
               piese:=-WhatPiese(dest);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
             end;
         temp:=temp and NotOnly[dest];
       end;
    // ���������� ���������
    if (tree[ply].Castle and 3)<>0 then
        begin
          if ((tree[ply].Castle and 1)<>0) and ((AllPieses and wshortmask)=0)
              and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[h1])<>0)
              and (not IsBlackAttacks(f1))
              then
            begin
              inc(count);
              moves[count]:=wshort;
            end;
          if ((tree[ply].Castle and 2)<>0) and ((AllPieses and wlongmask)=0)
              and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[a1])<>0)
              and (not IsBlackAttacks(d1))
              then
            begin
              inc(count);
              moves[count]:=wlong;
            end;
        end;
   
 end
          else
 Begin
   // ������������� ������ ��������� ������ �������� ����
    space:=not BlackPieses;
   // ���� �����
    temp:=BlackKnights;
    shablon:=(knight shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        attack:=KnightsMove[from] and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and WhitePieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or (WhatPiese(dest) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;

   // ���� ������
    temp:=BlackBishops;
    shablon:=(bishop shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and WhitePieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or (WhatPiese(dest) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ������ �������
    temp:=BlackRooks;
    shablon:=(rook shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=(attack or RBR90[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and WhitePieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or (WhatPiese(dest) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
   // ������ �������
    temp:=BlackQueens;
    shablon:=(queen shl 16);
    while temp<>0 do
      begin
        from:=BitScanForward(temp);
        indx:=(AllPieses shr (Posyy[from] shl 3)) and 255;
        attack:=RB[from,indx];
        indx:=(AllR90 shr (Posxx[from] shl 3)) and 255;
        attack:=attack or RBR90[from,indx];
        indx:=(AllDh1 shr Dsh1[from]) and MaskDh1[from];
        attack:=attack or RBDh1[from,indx];
        indx:=(AllDa1 shr Dsa1[from]) and MaskDa1[from];
        attack:=(attack or RBDa1[from,indx]) and space;
        shablon1:=shablon or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
           if (Only[dest] and WhitePieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or (WhatPiese(dest) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;
        temp:=temp and NotOnly[from];
      end;
    // ��� �������
        from:=tree[ply].Bking;
        attack:=KingsMove[from] and space;
        shablon1:=(king shl 16) or from;
        while attack<>0 do
          begin
            dest:=BitScanForward(attack);
            inc(count);
            if (Only[dest] and WhitePieses)=0
              then moves[count]:=shablon1 or (dest shl 8)
              else moves[count]:=shablon1 or CaptureFlag or (WhatPiese(dest) shl 20) or (dest shl 8);
            attack:=attack and NotOnly[dest];
          end;

     // �������� ����
     // ������� � ������� ����
     pawnm:=(BlackPawns shr 8) and clearf;
     doublem:=((pawnm and Ranks[6]) shr 8) and clearf;
     // �������
     while pawnm<>0 do
       begin
         dest:=BitScanForward(pawnm);
         inc(count);
         if dest>h1
             then
                  moves[count]:=(pawn shl 16) or (dest shl 8) or (dest+8)
             else begin
                  // ���������� �����������
                  moves[count]:=Promoteflag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  inc(count);
                  moves[count]:=Promoteflag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  inc(count);
                  moves[count]:=Promoteflag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  inc(count);
                  moves[count]:=Promoteflag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                  end;
         pawnm:=pawnm and NotOnly[dest];
       end;
     // ... � ������� ����
     while doublem<>0 do
       begin
         dest:=BitScanForward(doublem);
         inc(count);
         moves[count]:=(pawn shl 16) or (dest shl 8) or (dest+16);
         doublem:=doublem and NotOnly[dest];
       end;
    // ���������� �������� ������
    if tree[ply].EnnPass<>0 then
                              space:=WhitePieses or Only[tree[ply].EnnPass]
                            else
                              space:=WhitePieses;
     //������ ����� "�����"
     temp :=((BlackPawns and noafile) shr 9) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest>h1) then
             begin
               piese:=WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 moves[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest+9)
                              else
                 moves[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
             end
                      else
             begin
               piese:=WhatPiese(dest);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
             end;
         temp:=temp and NotOnly[dest];
       end;
    // ������ ������
    temp :=((BlackPawns and nohfile) shr 7) and space;
     while temp<>0 do
       begin
         dest:=BitScanForward(temp);
         if (dest>h1) then
             begin
               piese:=WhatPiese(dest);
               inc(count);
               if piese=Empty then
                 moves[count]:=EnPassantflag or CaptureFlag or (pawn shl 20) or (pawn shl 16) or (dest shl 8) or (Dest+7)
                              else
                 moves[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
             end
                      else
             begin
               piese:=WhatPiese(dest);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
               inc(count);
               moves[count]:=PromoteFlag or CaptureFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
             end;
         temp:=temp and NotOnly[dest];
       end;
    // ���������� ���������
    if (tree[ply].Castle and 12)<>0 then
        begin
          if ((tree[ply].Castle and 4)<>0) and ((AllPieses and bshortmask)=0)
              and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[h8])<>0)
              and (not IsWhiteAttacks(f8))
               then
            begin
              inc(count);
              moves[count]:=bshort;
            end;
          if ((tree[ply].Castle and 8)<>0) and ((AllPieses and blongmask)=0)
              and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[a8])<>0)
              and (not IsWhiteAttacks(d8))
              then
            begin
              inc(count);
              moves[count]:=blong;
            end;

        end;

 end;
   // ���������� ��������� ������� �����
   moves[point]:=count-point;
end;

end.


