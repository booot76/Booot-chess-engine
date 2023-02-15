unit bitboards;
// ���� �������� �� ��������� � �������, ���������� �� �������� � ����������
interface
uses params;

procedure PrintBitboard(const PrintingBitboard : Bitboard);
function BitCount(const aBoard: BitBoard): Integer;
function BitScanForward(const aBoard: BitBoard): Integer;
function BitScanForward8(const aBoard: Integer): Integer;
function BitScanBackward(const aBoard: BitBoard): Integer;
Procedure SetBitinBitboard(var aBoard:BitBoard;const bitposition:integer);
Function WhatPiese(const BitPosition:integer):integer;
implementation

procedure PrintBitboard(const PrintingBitboard : Bitboard);
// ��������� ������ �������� �� ����� � ���������� ���� � ���� �����
var
BitMassiv : array[1..64] of char; // ������ �������� ��� ������ ��������
                                 // . - "0", �-"1"
i,j: byte;
mask:Bitboard; // ����� ��� ����������������� ����������� �������� ������� ����
  begin
   mask:=0;
   for i:=1 to 64 do
    begin
    if mask=0 then mask:=1
              else mask:=mask*2; // ������������� ��������� ��� � �����
    if (mask and PrintingBitboard) = 0
                        then BitMassiv[i]:='.'
                        else BitMassiv[i]:='X';
    // ��������� ��������� ������ ������� ��������������� ��������
    end;
    // �������� ��������������� ������ � ���� �����
  for j:=7 downto 0 do
    begin
    write(j+1,'  '); // ����������� �����������
    for i:=1 to 8 do
     write(BitMassiv[j*8+i]);
    writeln;
    end;
  //� ����������� ���������
  writeln('   abcdefgh');
  end;

function BitCount(const aBoard: BitBoard): Integer;
// ������������ ��������� �������� "1"- ����� � ��������.
// �� ����� - ��������, �� ������ - ����� �����, ������������� � "1"
  asm
       mov ecx, dword ptr aBoard
       xor eax, eax
       test ecx, ecx
       jz @@1           // ���� ������ 32-��������� �������=0
  @@0: lea edx, [ecx-1]
       inc eax
       and ecx, edx
       jnz @@0
  @@1: mov ecx, dword ptr aBoard+04h // ��������� ������ �������� ��������
       test ecx, ecx
       jz @@3
  @@2: lea edx, [ecx-1]
       inc eax
       and ecx, edx
       jnz @@2
  @@3:
  end;


function BitScanForward(const aBoard: BitBoard): Integer;
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "������",�.� �� 0 �� 63 ����
//�� �����- �������� (���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
  asm
       bsf eax, dword ptr aBoard
       jz @@0
       jnz @@2
  @@0: bsf eax, dword ptr aBoard+04h
       jz @@2
       add eax, 20h
  @@2:
  end;

function BitScanForward8(const aBoard: Integer): Integer;
// ������������ ��������� ������ ���������� ���� � integer
// ����� �������������� "������",�.� �� 0 �� 31 ����
//�� �����- integer (���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� integer - �� ������ 0 (�������� ������!!!)
  asm
       bsf eax, dword ptr aBoard
  end;

function BitScanBackward(const aBoard: BitBoard): Integer;
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "�����",�.� �� 63 �� 1 ����
//�� ����� - ��������(���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
  asm
       bsr eax, dword ptr aBoard+04h
       jz @@0
       add eax, 20h
       jnz @@2
  @@0: bsr eax, dword ptr aBoard
  @@2:
  end;

Procedure SetBitinBitboard(var aBoard:BitBoard;const bitposition:integer);
// ������� ������������� � "1" ��� � ������� bitposition
var
  temp : bitboard;
  begin
    temp:=1;
    aBoard:=aBoard or (temp shl bitposition);
  end;

Function WhatPiese(const BitPosition:integer):integer;
// ������� ��������� ������, ������� �� ���� Bitposition ��� Empty.
  asm
   cmp al,32
   jnc @@1
   // ���������� ������� ��������
   mov ecx,dword ptr AllPieses
   bt ecx,eax
   jnc @em
   mov ecx,dword ptr WhitePawns
   bt ecx,eax
   jc @wp
   mov ecx,dword ptr BlackPawns
   bt ecx,eax
   jc @bp
   mov ecx,dword ptr WhiteKnights
   bt ecx,eax
   jc @wn
   mov ecx,dword ptr WhiteBishops
   bt ecx,eax
   jc @wb
   mov ecx,dword ptr WhiteRooks
   bt ecx,eax
   jc @wr
   mov ecx,dword ptr BlackKnights
   bt ecx,eax
   jc @bn
   mov ecx,dword ptr BlackBishops
   bt ecx,eax
   jc @bb
   mov ecx,dword ptr BlackRooks
   bt ecx,eax
   jc @br
   mov ecx,dword ptr WhiteQueens
   bt ecx,eax
   jc @wq
   mov ecx,dword ptr WhiteKing
   bt ecx,eax
   jc @wk
   mov ecx,dword ptr BlackQueens
   bt ecx,eax
   jc @bq
   mov ecx,dword ptr BlackKing
   bt ecx,eax
   jc @bk
@@1:
   // ������� ��������
   sub al,32
   mov ecx,dword ptr AllPieses+04
   bt ecx,eax
   jnc @em
   mov ecx,dword ptr WhitePawns+04
   bt ecx,eax
   jc @wp
   mov ecx,dword ptr BlackPawns+04
   bt ecx,eax
   jc @bp
   mov ecx,dword ptr WhiteKnights+04
   bt ecx,eax
   jc @wn
   mov ecx,dword ptr WhiteBishops+04
   bt ecx,eax
   jc @wb
   mov ecx,dword ptr WhiteRooks+04
   bt ecx,eax
   jc @wr
   mov ecx,dword ptr BlackKnights+04
   bt ecx,eax
   jc @bn
   mov ecx,dword ptr BlackBishops+04
   bt ecx,eax
   jc @bb
   mov ecx,dword ptr BlackRooks+04
   bt ecx,eax
   jc @br
   mov ecx,dword ptr WhiteQueens+04
   bt ecx,eax
   jc @wq
   mov ecx,dword ptr WhiteKing+04
   bt ecx,eax
   jc @wk
   mov ecx,dword ptr BlackQueens+04
   bt ecx,eax
   jc @bq
   mov ecx,dword ptr BlackKing+04
   bt ecx,eax
   jc @bk
@wp:
    mov eax,Pawn
    jmp @ex
@wn:
    mov eax,Knight
    jmp @ex
@wb:
    mov eax,Bishop
    jmp @ex
@wr:
    mov eax,Rook
    jmp @ex
@wq:
    mov eax,Queen
    jmp @ex
@wk:
    mov eax,King
    jmp @ex
@bp:
    mov eax,-Pawn
    jmp @ex
@bn:
    mov eax,-Knight
    jmp @ex
@bb:
    mov eax,-Bishop
    jmp @ex
@br:
    mov eax,-Rook
    jmp @ex
@bq:
    mov eax,-Queen
    jmp @ex
@bk:
    mov eax,-King
    jmp @ex
@em:
    mov eax,Empty
@ex:
  end;
end.

