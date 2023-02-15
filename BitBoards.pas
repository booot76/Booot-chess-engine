unit BitBoards;

interface
uses params;

Const
 Bcount :T256 =
 (0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,
 1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
 1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
 1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
 2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
 3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
 3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
 4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8);



procedure PrintBitboard(const BB : TBitboard);
function BitScanForward(var BB: TBitBoard): Integer;
function BitScanBackward(var BB: TBitBoard): Integer;
function BitCountInit(const BB: TBitBoard): Integer;
function BitCount(var BB: int64): Integer;
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


function BitCount(var BB: int64): Integer;
// ��������� �������� "1"- ����� � ��������.
// �� ����� - ��������, �� ������ - ����� �����, ������������� � "1"
 // asm
// popcnt rax, qword ptr [bb]
 begin
   Result:=Bitcounttable[BB and 65535]+BitCounttable[(BB shr 16) and 65535]+BitCounttable[(BB shr 32) and 65535]+Bitcounttable[(BB shr 48) and 65535];
  end;


function BitCountInit(const BB: TBitBoard): Integer;
// ��������� �������� "1"- ����� � ��������.
// �� ����� - ��������, �� ������ - ����� �����, ������������� � "1"
begin
  result:=Bcount[bb and 255]+Bcount[(bb shr 8) and 255]+Bcount[(bb shr 16) and 255]+Bcount[(bb shr 24) and 255]
         +Bcount[(bb shr 32) and 255]+Bcount[(bb shr 40) and 255]+Bcount[(bb shr 48) and 255]+Bcount[(bb shr 56) and 255];
end;




function BitScanForward(var BB: TBitBoard): Integer;     // for 32
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "������",�.� �� 0 �� 63 ����
//�� �����- �������� (���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
 asm
 //  bsf rax,qword ptr [bb]  {64}
       bsf eax, dword ptr [BB]
       jnz @@2
  @@0: bsf eax, dword ptr [BB+04h]
       add eax, 20h
  @@2:

  end;



function BitScanBackward(var BB: TBitBoard): Integer;   // for 32
// ������������ ��������� ������ ���������� ���� � ��������
// ����� �������������� "�����",�.� �� 63 �� 1 ����
//�� ����� - ��������(���������!), �� ������ - ����� ������� ��������� "1"-����.
// ���� ������ ������� �������� - �� ������ 0 (�������� ������!!!)
  asm
//   bsr rax,qword ptr[bb] {64}
     bsr eax, dword ptr [BB+04h]
       jz @@0
       add eax, 20h
       jnz @@2
  @@0: bsr eax, dword ptr [BB]
  @@2:

  end;



end.
