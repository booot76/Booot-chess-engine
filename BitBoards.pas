unit BitBoards;

interface
uses params;


procedure PrintBitboard(const BB : TBitboard);
function BitScanForward(var BB: TBitBoard): Integer;
function BitScanBackward(var BB: TBitBoard): Integer;
function BitCount(var BB: int64): Integer;inline;
function BitCountAsm(const BB: TBitBoard): Integer;
function BitScanForward2(BB: TBitBoard): Integer;
implementation

procedure PrintBitboard(const BB : TBitboard);
// ��������� ������ �������� �� ����� � ���������� ���� � ���� �����
var
    BitMassiv : array[1..64] of char; // ������ �������� ��� ������ ��������
    i,j: byte;
    mask:TBitboard; // ����� ��� ����������������� ����������� �������� ������� ����
begin
   mask:=0;
   for i:=1 to 64 do
    begin
    if mask=0 then mask:=1
              else mask:=mask*2; // ������������� ��������� ��� � �����
    if (mask and BB) = 0
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

function BitScanForward(var BB: TBitBoard): Integer;
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "������",�.� �� 0 �� 63 ����
//�� �����- �������� (���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
 asm
       bsf eax, dword ptr [BB]
       jnz @@2
  @@0: bsf eax, dword ptr [BB+04h]
       add eax, 20h
  @@2:
  end;

function BitScanBackward(var BB: TBitBoard): Integer;
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "�����",�.� �� 63 �� 1 ����
//�� ����� - ��������(���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
  asm
       bsr eax, dword ptr [BB+04h]
       jz @@0
       add eax, 20h
       jnz @@2
  @@0: bsr eax, dword ptr [BB]
  @@2:
  end;
function BitCount(var BB: int64): Integer;inline;
// ��������� �������� "1"- ����� � ��������.
// �� ����� - ��������, �� ������ - ����� �����, ������������� � "1"
  begin
   Result:=Bitcounttable[BB and 65535]+BitCounttable[(BB shr 16) and 65535]+BitCounttable[(BB shr 32) and 65535]+Bitcounttable[(BB shr 48) and 65535];
  end;

function BitCountAsm(const BB: TBitBoard): Integer;
// ������������ ��������� �������� "1"- ����� � ��������.
// �� ����� - ��������, �� ������ - ����� �����, ������������� � "1"
  asm
       mov ecx, dword ptr BB
       xor eax, eax
       test ecx, ecx
       jz @@1           // ���� ������ 32-��������� �������=0
  @@0: lea edx, [ecx-1]
       inc eax
       and ecx, edx
       jnz @@0
  @@1: mov ecx, dword ptr BB+04h // ��������� ������ �������� ��������
       test ecx, ecx
       jz @@3
  @@2: lea edx, [ecx-1]
       inc eax
       and ecx, edx
       jnz @@2
  @@3:
  end;
function BitScanForward2(BB: TBitBoard): Integer;
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "������",�.� �� 0 �� 63 ����
//�� �����- �������� (���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
 asm
       bsf eax, dword ptr BB
       jnz @@2
  @@0: bsf eax, dword ptr BB+04h
       add eax, 20h
  @@2:
  end;
end.
