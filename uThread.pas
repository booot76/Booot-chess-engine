unit uThread;

interface
uses Windows,SysUtils,uBoard,uSort,uMaterial,uPawn,uEval;
Const
  MaxThreads=16;
  MaxPV=130;
Type
  TPv = array[0..MaxPV] of smallint;
  TThread  = record
              Id       : integer;   // �������������
              handle   : LongWord;  // ����� ������
              isRun    : boolean;  // ���������� ��� ����� ��������
              idle     : boolean;  // ���������� ������� ������
              haswork  : boolean;  // ���� ������� ������� � ������
              AbortSearch : Boolean;
              FullDepth : integer;
              RootMoves: integer;
              Board    : TBoard;
              Tree     : TTree;
              SortUnit : TSortUnit;
              PVLine   : TPV;
              StablePv : TPV;
              RootList : TMoveList;
              stableMove : integer;
              BestValue  : integer;
              MatTable : array of TMatEntry;
              MatTableMask : int64;
              PawnTable : array of TPawnEntry;
              PawnTableMask : int64;
              EvalTable : array of TEvalEntry;
              EvalTableMask: int64;
            end;

var
   AllThreadsStop : boolean;
   Threads : array [1..MaxThreads] of TThread;
   SMPLock :TRTLCriticalSection;
   IdleEvent : THandle;
Threadvar
    global : ^Integer;

Procedure Init_Threads(n:integer);
Procedure StopThreads;
Function isThreadidle:boolean;
Procedure CopyThread(ThreadId:integer);
implementation
  uses uUci,uSearch,UHash;

Procedure CopyThread(ThreadId:integer);
var
  i: integer;
// �������� ������ �� �������� ������ � ���������������
begin
  Threads[ThreadId].RootMoves:=Threads[1].RootMoves;
    Threads[ThreadId].PVLine[0]:=0;
  for i:=0 to Threads[ThreadId].RootMoves-1 do
    begin
     Threads[ThreadId].RootList[i].move:=Threads[1].RootList[i].move;
     Threads[ThreadId].RootList[i].value:=Threads[1].RootList[i].value;
    end;
  CopyBoard(Threads[1].Board,Threads[ThreadId].Board);
  NewSearch(ThreadId);
  Threads[ThreadId].FullDepth:=0;
  Threads[ThreadId].haswork:=true;
end;


Procedure Idle_loop (threadid : integer);
// ����� ������ ��������
begin
  Threads[threadid].Id:=Threadid;
  Threads[threadid].haswork:=false;
  Threads[threadid].isRun:=true;  // ����� �������� - ���� ������ �������� ��� ��� ��.
 // � ���� ����� ����� �����. ����� �� ����� - �� �����. ����� ����� �����������.
  while true do
   begin
    // �������� ������
    if (AllThreadsStop)  then break;
    // ���� ��� ������ ������ ��� ������ (�������� ����� ����� ������) - �� ����.
    // ����� ��� ��������� ���� ���� ��� ���� ������� !
    if (not Threads[threadid].haswork)  then
     begin
      Threads[threadid].idle:=true;
      WaitForSingleObject(IdleEvent, INFINITE);
      //  ��� ����� ���� ����������� ������ ������������� �������
     end;
    // ��� ����� ��������� � ���� ������ ��� ������� ���������. ������������ �����  � ������ ����� ������ �� haswork true
    if Threads[threadid].haswork then
      begin
        Threads[threadid].idle:=false;
        Iterate(ThreadId);                       ////////////////////////////// ������� ������� ������  � �������
        Threads[threadid].haswork:=false;
        Threads[threadid].idle:=true;
      end;
   end;
// �������� ������
 Threads[threadid].isRun:=false;
end;
Procedure win_init(Par:Pointer);
// ������� ��������� ������ �������. �������� � �������� ��������� ����� ������ � ���������
// ��� ��������� � �����.
var
  i:integer;
begin
  global:=par;
  i:=global^;
  Idle_loop(i);
end;
Procedure Init_Threads(n:integer);
// ������������� �������. ��� ������ ��������� � ������ ��������� � ���� ������
var
  i : integer;
  tr:longword;
begin
   AllThreadsStop:=false;
 // �������� ������
  for i:=2 to n do
      begin
        Threads[i].haswork:=false;
        Threads[i].handle:=BeginThread(nil,0,addr(win_init),addr(i),0,tr);
        // ��� ������ ����� �������� � ��� �������������������� - �� ����� �� ����� ������
        while not Threads[i].isRun do;
      end;
end;
Function isThreadidle:boolean;
// ��������� ��� �� ������ ���������� - ���� ���-�� ��� ������� - ��������� true
var
  i:integer;
begin
  for i:=2 to MaxThreads do
    if (Threads[i].idle=true) then
      begin
        result:=true;
        exit;
      end;
  result:=false;
end;
Function isThreadsrunning:boolean;
// ��������� ���� �� ���� ���� ����� ����������
var
  i:integer;
begin
  for i:=2 to MaxThreads do
    if Threads[i].isRun then
      begin
        result:=true;
        exit;
      end;
  result:=false;
end;
Procedure StopThreads;
// ����� ������
begin
  // ������ ������ ���� ������� ��������� ���� ������
  AllThreadsStop:=true;
  // ���� ����������� ������� ����� ������� �� ������ ������ ������
  SetEvent(IdleEvent);
  // ���� ��������� ������ ���� �������!
  while isThreadsrunning do;
  ResetEvent(IdleEvent);
end;

Initialization
// �������������� ����������� ������
InitializeCriticalSection(SmpLock);
// �������������� ������� ��� ������������� �������
IdleEvent:=CreateEvent(nil,true,false,nil);

end.
