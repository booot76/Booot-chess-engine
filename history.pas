unit history;
// ���� �������� �������, �������� �� ��������� ���������� �����.
interface
uses params,bitboards,attacks;
Procedure AddToHistory(color : integer;move:integer;ply:integer;depth : integer);
Function isValidMove(color:integer;move:integer;ply:integer):boolean;
Procedure ClearHistory;
Procedure CountBadMoves(ply:integer);
implementation
const
 MaxHistory=1400000000;
Procedure AddToHistory(color : integer;move:integer;ply:integer;depth : integer);
// ����������� �������� History ���������, � ������� ������� ��� � ������ ������ �����
// ��������� ���������� �� �������� ������ �������� � ������ ���������� �� ����
var
  piese,dest,i,j : integer;
begin
   // ������������� ������ ������� ���� (������ � ����������� �� �� ������ ������������� �� ����, ��� �������� ������� ������ ��� ������� ����)
  if (move and CapPromoFlag)<>0 then exit;
  piese:=(move shr 16) and 15;
  dest:=(move shr 8) and 255;
  Hist[piese,dest]:=Hist[piese,dest]+depth*depth;
  if hist[piese,dest]>=MaxHistory then
    For i:=1 to 6 do
      For j:=0 to 63 do
        Hist[i,j]:=Hist[i,j] div 2;
  // ��������� ������ ���  � ������ ���������������� ������
  if (killer[ply,1]<>move) then
      begin
        killer[ply,2]:=killer[ply,1];
        killer[ply,1]:=move;
      end;
 // ����������� ������� "�������" � "������ "�����
   mGood[piese,dest]:=mGood[piese,dest]+1;
   CountBadMoves(ply);
end;
Procedure CountBadMoves(ply:integer);
 var
 cpoint,piese,dest,i,count :integer;
begin
  cpoint:=ply shl 7;
  count:=OldMoves[cpoint];
  for i:=cpoint+1 to cpoint+count-1 do
   if (OldMoves[i] and CapPromoFlag)=0 then
    begin
      piese:=(OldMoves[i] shr 16) and 15;
      dest:=(OldMoves[i] shr 8) and 255;
      mTotal[piese,dest]:=mTotal[piese,dest]+1;
    end;

  
end;

Procedure ClearHistory;
var
   i,j:integer;
begin
  for i:=0 to MaxPly do
    begin
     Killer[i,1]:=0;
     Killer[i,2]:=0;
     tree[i].Hashmove:=0;
    end;
  For i:=0 to 63 do
    For j:=1 to 6 do
     begin
       Hist[j,i]:=0;
       mGood[j,i]:=0;
       mTotal[j,i]:=0;
     end;
end;

Function isValidMove(color:integer;move:integer;ply:integer):boolean;
// ������� ��������� ����������� ���� �� �����. ������������ ��� �������� ������ �����
// � �����, ���������� �� ��� �������� �� ����������� � ������ ���������� �������
var
  From,Dest,PieseFrom,PieseDest : integer;
begin
  from:=move and 255;
  piesefrom:=(move shr 16) and 15;
  if color=white
    then begin
          if WhatPiese(from)<>piesefrom then
             begin
               Result:=false;
               exit;
             end;
          dest:=(move shr 8) and 255;
          piesedest:=(move shr 20) and 15;

          case piesefrom of
            empty : begin
                      Result:=false;
                      exit;
                    end;
            pawn : begin
                     // ��������� ������� �������� ���
                     if (dest-from)=8 then
                         // ���� ����� ������ ������ ���� ������ (������ ����������� ��� �� ����� � ���� ������ ������)
                         if WhatPiese(dest)=Empty then begin
                                                         Result:=true;
                                                         exit;
                                                       end
                                                  else begin
                                                         Result:=false;
                                                         exit;
                                                       end;
                     // ��������� ������� ��� ������. ��� ��� ���� ����� ������ ������ ���� ����������.
                     if (dest-from)=16 then
                          If (WhatPiese(dest)=Empty) and (WhatPiese(dest-8)=Empty)then
                                                        begin
                                                         Result:=true;
                                                         exit;
                                                       end
                                                  else begin
                                                         Result:=false;
                                                         exit;
                                                       end;
                   // ��������� ������ ������ (� ��� ����� � �� �������).
                   if piesedest=empty then begin
                                        // �� �������
                                        if (WhatPiese(dest)=Empty) and (WhatPiese(dest-8)=-pawn)
                                        and (tree[ply].EnnPass=dest) then
                                               begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                                        end
                                  else begin
                                       // ������
                                       if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                                       end;


                   end;
            knight : begin
                      if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                     end;
            bishop: begin
                      if (BishopsMove(from) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                    end;
            rook: begin
                    if (RooksMove(from) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                  end;
            queen : begin
                      if ((RooksMove(from) or BishopsMove(from)) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                    end;
            king : begin
                     // ��������� ���������
                     if abs(dest-from) =2 then
                       if (tree[ply].Castle and 3)>0 then
                         begin
                           if dest=g1 then
                              begin
                               if ((tree[ply].Castle and 1)<>0) and ((AllPieses and wshortmask)=0)
                               and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[h1])<>0)
                               and (not IsBlackAttacks(f1)) and (not IsBlackAttacks(g1))then
                                   begin
                                     Result:=true;
                                     exit;
                                   end
                              else begin
                                     Result:=false;
                                     exit;
                                   end;
                              end     else

                              begin
                               if ((tree[ply].Castle and 2)<>0) and ((AllPieses and wlongmask)=0)
                               and (not IsBlackAttacks(e1)) and ((WhiteRooks and Only[a1])<>0)
                               and (not IsBlackAttacks(d1)) and (not IsBlackAttacks(c1))then
                                   begin
                                     Result:=true;
                                     exit;
                                   end
                              else begin
                                     Result:=false;
                                     exit;
                                   end;
                              end;


                         end
                              else
                         begin
                           Result:=false;
                           exit;
                         end;
                     // ��������� ������� ��� �������.
                     if (piesedest=-WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                   end;
            end;
         end
 else    begin
           if WhatPiese(from)<>-piesefrom then
             begin
               Result:=false;
               exit;
             end;
          dest:=(move shr 8) and 255;
          piesedest:=(move shr 20) and 15;
          case piesefrom of
            empty : begin
                      Result:=false;
                      exit;
                    end;
            pawn : begin
                     // ��������� ������� �������� ���
                     if (from-dest)=8 then
                         // ���� ����� ������ ������ ���� ������ (������ ����������� ��� �� ����� � ���� ������ ������)
                         if WhatPiese(dest)=Empty then begin
                                                         Result:=true;
                                                         exit;
                                                       end
                                                  else begin
                                                         Result:=false;
                                                         exit;
                                                       end;
                     // ��������� ������� ��� ������. ��� ��� ���� ����� ������ ������ ���� ����������.
                     if (from-dest)=16 then
                          If (WhatPiese(dest)=Empty) and (WhatPiese(dest+8)=Empty)then
                                                        begin
                                                         Result:=true;
                                                         exit;
                                                       end
                                                  else begin
                                                         Result:=false;
                                                         exit;
                                                       end;
                   // ��������� ������ ������ (� ��� ����� � �� �������).
                   if piesedest=empty then begin
                                        // �� �������
                                        if (WhatPiese(dest)=Empty) and (WhatPiese(dest+8)=pawn)
                                        and (tree[ply].EnnPass=dest) then
                                               begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                                        end
                                  else begin
                                       // ������
                                       if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                                       end;


                   end;
            knight : begin
                      if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                     end;
            bishop: begin
                      if (BishopsMove(from) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                    end;
            rook: begin
                    if (RooksMove(from) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                  end;
            queen : begin
                      if ((RooksMove(from) or BishopsMove(from)) and Only[dest])=0
                           then begin
                                 Result:=false;
                                 exit;
                                end;
                      if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                    end;
            king : begin
                     // ��������� ���������
                     if abs(dest-from) =2 then
                       if (tree[ply].Castle and 12)>0 then
                         begin
                           if dest=g8 then
                              begin
                               if ((tree[ply].Castle and 4)<>0) and ((AllPieses and bshortmask)=0)
                               and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[h8])<>0)
                               and (not IsWhiteAttacks(f8)) and (not IsWhiteAttacks(g8))then
                                   begin
                                     Result:=true;
                                     exit;
                                   end
                              else begin
                                     Result:=false;
                                     exit;
                                   end;
                              end     else

                              begin
                               if ((tree[ply].Castle and 8)<>0) and ((AllPieses and blongmask)=0)
                               and (not IsWhiteAttacks(e8)) and ((BlackRooks and Only[a8])<>0)
                               and (not IsWhiteAttacks(d8)) and (not IsWhiteAttacks(c8))then
                                   begin
                                     Result:=true;
                                     exit;
                                   end
                              else begin
                                     Result:=false;
                                     exit;
                                   end;
                              end;


                         end
                              else
                         begin
                           Result:=false;
                           exit;
                         end;
                     // ��������� ������� ��� �������.
                     if (piesedest=WhatPiese(dest)) then
                                           begin
                                                Result:=true;
                                                exit;
                                               end
                                         else begin
                                                Result:=false;
                                                exit;
                                              end;
                   end;
            end;
         end;

 Result:=false;
end;

end.

