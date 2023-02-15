unit uMagic;

interface
   uses uBitboards,SysUtils,DateUtils;
Type
  T16  = array[0..15] of integer;  // ��� ������� ������� �������� ����� ��������� ������ (����� ��� �����)

  TTempMagic = record
                 AttackSet:TBitBoard;
                 age : cardinal;
               end;
Const
  RookMagic=true;
  BishopMagic=false;
  BestMagic=true;
  NormalMagic=false;
  LowRandom=0;
  HiRandom=1;
  MiddleRandom=2;
  BruteForce=3;
  SingleProbe=4;

  BishopMagics:array[a1..h8] of int64 =
  (-1011764711519436801,-7042934952165518,1127008041959424,1130300100837376,299342040662016,143006304829440,-5427352771232297,-4612092979530891289,
   -5790208656570224666,-2473098283212153863,4402375163904,4415234768896,1169304846336,558618378240,-1367084408557404209,4976367305885089688,
   -5962651506599931918,2693179129366636533,281483600331264,140771881664512,140754678710272,35188675985408,2624477685092106174,7905511789398114252,
   571746315931648,285873157965824,35734195078144,70643689259520,145135543263232,70643655708672,141287261212672,70643630606336,
   285941744803840,142970872401920,17884244346880,2201171263616,70644696088832,141291539267840,282578783438848,141289391719424,
   -6165505174389309273,-6877001899937849325,8935813681152,137724168192,8800392184832,282578800083456,-414396091809786879,-8079486789333094909,
   -7183243620024733470,-7357757210572278046,139654594560,545783808,68753162240,4415360729088,9151220914588706811,-3044527198171015909,
   -1604410069881916089,4775671564421779946,545525760,2131968,268567040,17247502848,4419860047949615700,2269802898943333742);

  BishopShifts:array[a1..h8] of byte =
  (59,60,59,59,59,59,60,59,
   60,60,59,59,59,59,60,60,
   60,60,57,57,57,57,60,60,
   59,59,57,55,55,57,59,59,
   59,59,57,55,55,57,59,59,
   60,60,57,57,57,57,60,60,
   60,60,59,59,59,59,60,60,
   59,60,59,59,59,59,60,59);

   RookMagics:array[a1..h8] of int64 =
   (36028866279506048,18014467231055936,36037661833560192,36033229426262144,36031013222613120,36029905120788608,36029346791555584,36028935540048128,
    140738029420672,70369281069056,140806209929344,140771849142400,140754668748928,140746078552192,140741783453824,140738570486016,
    35734132097152,70643624185856,141287512612864,141287378391040,141287311280128,141287277724672,1103806726148,2199027482884,
    35736275402752,35185445851136,17594335625344,8798241554560,4400194519168,2201171001472,1101667500544,140739635855616,
    35459258384512,35185450029056,17594341924864,8798248898560,4400202385408,2201179128832,2199040098308,140738570486016,
    35459258417152,35185445863552,17592722948224,8796361490560,4398180761728,2199090397312,1099545215104,277042298884,
    4035224570325521920,-216173606759150336,-5080061041109904896,-180391863808,7975874776861488640,-8651415476893391360,140741783453824,5841168673586058912,
    -1451722637394,-551864334618,-2449959408489225290,-162129915691794442,-576460898334681610,281483633756161,1125827562356340,-3288375714);

   RookShifts:array[a1..h8] of byte =
    (52,53,53,53,53,53,53,52,
     53,54,54,54,54,54,54,53,
     53,54,54,54,54,54,54,53,
     53,54,54,54,54,54,54,53,
     53,54,54,54,54,54,54,53,
     53,54,54,54,54,54,54,53,
     54,55,55,55,55,55,54,54,
     53,54,54,54,54,53,54,53);
var
    BishopMasks,RookMasks   : array[a1..h8] of TBitBoard;
    BishopMM                : array[0..4799] of TBitBoard;
    RookMM                  : array[0..88575] of TBitBoard;
    BishopOffset,RookOffset : array[a1..h8] of integer;

  Procedure FindMagicForSquare(sq:integer;isRook:boolean;mode:integer;initbits:integer;best:boolean);
  Procedure MagicsInit;
  Function GetRandom64:int64;
  Function GetRandom32:integer;
implementation

Function CalcSochetFun(n:integer;k:integer):int64;
// ������� ��������� ��������� �� n ��������� �� k
  var
     res:int64;
     i:integer;
   begin
     res:=0;
     if (n>=k) and (n>=0) then
       begin
         res:=1;
         for i:=1 to k do
          begin
           res:=res*N;
           res:=res div i;
           N:=N-1;
          end;
       end;
     Result:=res;
   end;

Function PboardBishopMovesBB(Occupied:TBitBoard;sq:integer):TBitBoard;
  // ��������� ���� ����� �� ���� sq �� ����� ������� �������� �� �������� occupied  � ������� ����������� �����
  const
   movearray : array[1..4] of integer =(11,-11,9,-9) ;
  var
   i,dir:integer;
   res:TBitBoard;
   begin
     res:=0;
     for dir:=1 to 4 do
      begin
       i:=sq+movearray[dir];
       while pboard[i]>=0 do
        begin
         res:=(res or Only[pboard[i]]);
         if (Occupied and Only[pboard[i]])<>0 then break;
         i:=i+movearray[dir];
        end;
      end;
    Result:=res;
   end;

 Function PboardRookMovesBB(Occupied:TBitBoard;sq:integer):TBitBoard;
  // ��������� ���� ����� �� ���� sq �� ����� ������� �������� �� �������� occupied  � ������� ����������� �����
  const
   movearray : array[1..4] of integer =(1,-1,10,-10) ;
  var
   i,dir:integer;
   res:TBitBoard;
   begin
     res:=0;
     for dir:=1 to 4 do
      begin
       i:=sq+movearray[dir];
       while pboard[i]>=0 do
        begin
         res:=(res or Only[pboard[i]]);
         if (Occupied and Only[pboard[i]])<>0 then break;
         i:=i+movearray[dir];
        end;
      end;
    Result:=res;
   end;

 Function GetRandom64:int64;
 // ������� 64 ������ ��������� �����
  var
  sl1,sl2,sl3,sl4:int64;
  begin
    sl1:=Random(65536);
    sl2:=Random(65536);
    sl3:=Random(65536);
    sl4:=Random(65536);
    Result:=sl1 or (sl2 shl 16) or (sl3 shl 32) or (sl4 shl 48);
  end;

 Function GetRandom32:integer;
 // ������� 32 ������ ��������� �����
  var
  sl1,sl2:int64;
  begin
    sl1:=Random(65536);
    sl2:=Random(65536);
    Result:=sl1 or (sl2 shl 16);
  end;
 
 Function Snoob(BB:TBitBoard):TbitBoard;
// ���� ��������� �� �������� ����� � ����� �� ����������� ��������� �����, ��� � ���������. ��� ���������
 var
   smallest,riple,ones : TBitBoard;
   n : integer;
 begin
   smallest:=BB and (-BB);
   riple:=BB+smallest;
   ones:=BB xor riple;
   n:=BitScanForward(smallest);
   ones:=(ones shr 2) shr n;
   result:=riple or ones;
 end;

 Function LowBitRandom:int64;
 // ������ ��������� 64-������ ����� � ����� ������ ��������� �����
  begin
    result:=GetRandom64 and GetRandom64 and GetRandom64;
  end;
Function HiBitRandom:int64;
 // ������ ��������� 64-������ ����� � ������� ������ ��������� �����
  begin
    result:=GetRandom64 or GetRandom64;
  end;

 Procedure FillBBArray(Occupied:TBitBoard;var A :T16);
  // ��������� ������������� ������ �������� ������������� � 1 ����� �������� Occupied.  ������� �������� ���� ����� ��� ����� ��� ��� ���� ������ ������� - 16 � ������
  var
   i : integer;
  begin
    i:=0;
    while Occupied<>0 do
      begin
        A[i]:=BitScanForward(Occupied);
        i:=i+1;
        Occupied:=Occupied and (Occupied-1);
      end;
  end;



 Function SetOccupancy(Kol:integer;Num:integer;var A:T16):TBitBoard;
 // ������������� ������� ������� ����� ����������� kol �� ��� ������ num ��������� ����� ����������� ������ ���� ������������ ����� ��� ���� Occupancy
 var
   res:TBitBoard;
   i:integer;

 begin
   res:=0;
   for i:=0 to kol-1 do
    // ���� � ������ occupancy ���������� ���, �� �������������� ��� ��� � �������� ���� ��������.
    if (Num and (1 shl i))<>0 then res:=res or Only[A[i]];
   Result:=res;
 end;

 Procedure ClearEdgeSquares(sq:integer;var OccupancyMask:TBitBoard);
 // ������� �� ����� ���� ���� �����
 var
   x,y : integer;
 begin
   x:=(sq div 10);
   y:=(sq mod 10);
   if (x<8) then OccupancyMask:=OccupancyMask and (not FilesBB[8]);
   if (x>1) then OccupancyMask:=OccupancyMask and (not FilesBB[1]);
   if (y<8) then OccupancyMask:=OccupancyMask and (not RanksBB[8]);
   if (y>1) then OccupancyMask:=OccupancyMask and (not RanksBB[1]);
 end;

 Function FindBruteForceMagic(sq:integer;n:integer;kol:integer;isRook:boolean;mode : integer; initbits:int64; best:boolean; var A:T16):int64;
 // ������� ������ magic ������
  var
   MullBB,AttackBB,Occupancy,ii,maxii,nodes : int64;
   i,index,shift,bit,collisions,mincol,shiftsize,useful,j:integer;
   s:string;
   AttackSets,OccupancySets: array of TBitBoard;
   Temp : array of TTempMagic;
   t1,t2 : TDateTime;
   round:cardinal;
  begin
    t1:=now;
    nodes:=0;
   // ������� �����
    shift:=(64-kol);
   // ���� ���� ��������� magic �� ����������� shift
    if best then inc(shift);
    shiftsize:= 1 shl (64-shift);
   // ������������� ����������� ���������� �������� � �������� ������� ����� - ������������ ��� ����������
    mincol:=n+1;
   // �������� ������
   Setlength(AttackSets,n);
   Setlength(OccupancySets,n);
   Setlength(temp,shiftsize);
    // ������������� ��������������� ���� ��� ������ ���������� Occupancy ��� ���� ������ ����
    For i:=0 to n-1 do
      begin
        // ��� ������ ���������� Occupancy ������� ������� ��������� ����� ��� ���
        Occupancy:=SetOccupancy(kol,i,A);
        if isRook
          then AttackBB:=PboardRookMovesBB(Occupancy,sq)
          else AttackBB:=PboardBishopMovesBB(Occupancy,sq);
        AttackSets[i]:=AttackBB;
        OccupancySets[i]:=Occupancy;
      end;
   // ��� ��������� ������ ���� ���������� ��������� �����  - ������ ����. ��� ��������� ����� ��� ������ ������ ����������� ����� ����
    for bit:=initbits to 64 do
    begin
      MullBB:=(Only[bit]-1);
     // ��������� ���������� ���������� ��� ������� ���������� ����� � 64-������ ��������
     if bit>32
       then maxii:=CalcSochetFun(64,64-bit)
       else maxii:=CalcSochetFun(64,bit);
     // ��� ��������� �������� ���������� ������ ��������� �������� ������ ���������� ��������� �����
     if mode=BruteForce then
      begin
       t2:=now;
       writeln('Brute force ',bit,' bits ',nodes,' nodes at ',MillisecondsBetween(t1,t2) div 1000,' sec');
      end;
     ii:=0; round:=4294967295;

     // ������ �������� ���� ������ magic
     while ii<maxii do
      begin
       //  �������  ��������� ������ ���������� Occupancy
        if round=4294967295 then
         begin
          // ������� ������ ����� ����� �� ����� ��������
           round:=0;
           for i:=0 to shiftsize-1 do
             Temp[i].age:=4294967295;
         end;
       // ����� ��������� �����-��������   � ����������� �� ���� ��� ���������
        case mode of
          LowRandom    : MullBB:=LowBitRandom;
          HiRandom     : MullBB:=HiBitRandom;
          MiddleRandom : MullBB:=GetRandom64;
          BruteForce   : MullBB:=Snoob(MullBB);
          SingleProbe  : begin
                           if isRook
                            then MullBB:=RookMagics[pboard[sq]]
                            else MullBB:=BishopMagics[pboard[sq]];
                         end;
        end;
        collisions:=0; useful:=0;
        for i:=0 to n-1 do
          begin
            // ��������� ������ ����
            index:=((MullBB *OccupancySets[i]) shr shift);
            // ���� � ���� ������� ��� ���� ������� � �� ������ - �������� +1 ���� ��� - ���������� ������� �� ������� � ������� ��������� ����������
            if (Temp[index].age=round) and (Temp[index].AttackSet<>AttackSets[i]) then
              begin
                inc(collisions);
                if collisions>=mincol then break;
              end else
              begin
                if (Temp[index].AttackSet<>AttackSets[i]) or (Temp[index].age<>round) then
                 begin
                  inc(useful);
                  Temp[index].AttackSet:=AttackSets[i];
                  Temp[index].age:=round;
                 end;
              end;
          end;
       // ��� ���������� ����������� - �������� ���. ��� � ���� ������� Magic
        if collisions=0 then
         begin
          t2:=now;
          s:='FOUND! '+inttostr(shift)+' shift('+inttostr(shiftsize)+') '+inttostr(useful)+' useful collisions,magic: '+inttostr(MullBB)+', with '+inttostr(bitcount(MullBB))+' bits, '+inttostr(nodes)+' nodes at '+inttostr(MillisecondsBetween(t1,t2) div 1000)+' sec';
          if mode<>SingleProbe then Writeln(s);
          if mode=SingleProbe then
           begin
            if isRook then
              begin
                i:=RookOffset[pboard[sq]];
                for j:=0 to shiftsize-1 do
                  RookMM[i+j]:=Temp[j].AttackSet;
                if sq<>88 then RookOffset[pboard[sq]+1]:=RookOffset[pboard[sq]]+shiftsize;
              end else
              begin
                i:=BishopOffset[pboard[sq]];
                for j:=0 to shiftsize-1 do
                  BishopMM[i+j]:=Temp[j].AttackSet;
                if sq<>88 then BishopOffset[pboard[sq]+1]:=BishopOffset[pboard[sq]]+shiftsize;
              end;
           end;
          Setlength(AttackSets,0);
          Setlength(OccupancySets,0);
          Setlength(temp,0);
          Result:=MullBB;
          exit;
         end;
       // ��������� ���������� ����������� �������� ���� ����
        if collisions<mincol then
         begin
          t2:=now;
          writeln(collisions,' from ',n,' ',useful,' useful from ',shiftsize,' ',MullBB,' ',BitCount(MullBB),' ',nodes,' nodes at ',MillisecondsBetween(t1,t2) div 1000,' sec');
          mincol:=collisions;
         end;
       inc(ii);
       inc(round);
       inc(nodes);
      end;
    end;
   Result:=0;
  end;

 Procedure FindMagicForSquare(sq:integer;isRook:boolean;mode:integer;initbits:integer;best:boolean);
  // ���� magicnumbers  ��� ������ ������ sq , �������������� � ����������� ����� a1=11 h8=88 c ���������� �������� ������������� ��������� � ���������� ������ ���������� ��������� ����� � ��������
  label l1;
  var
    OccupancyMask: TBitBoard;
    kol,n:integer;
    A:T16;
  begin
    if mode<>SingleProbe then Writeln('Searching magics for square ',sq);
    // ���� �� ������ ����� ������� ����� ������ � ���� ������
    if isRook
      then
       begin
        OccupancyMask:=PboardRookMovesBB(0,sq);
        ClearEdgeSquares(sq,OccupancyMask);
        RookMasks[pboard[sq]]:=OccupancyMask;
        if mode=SingleProbe then
          if 64-RookShifts[pboard[sq]]=BitCount(OccupancyMask)
            then best:=false
            else best:=true;
       end
      else
       begin
        OccupancyMask:=PboardBishopMovesBB(0,sq);
        ClearEdgeSquares(sq,OccupancyMask);
        BishopMasks[pboard[sq]]:=OccupancyMask;
        if mode=SingleProbe then
          if 64-BishopShifts[pboard[sq]]=BitCount(OccupancyMask)
            then best:=false
            else best:=true;
       end;
   // ���������� ����� � �����
    kol:=BitCount(OccupancyMask);
   // ��������� ������ �������� ���������
    FillBBArray(OccupancyMask,A);
   //��������� ���������� ���������� occupancy
    n:=(1 shl kol);
   FindBruteForceMagic(sq,n,kol,isRook,mode,initbits,best,A);
  end;
Procedure MagicsInit;
// ������������� magic ��������
 var
  i,j : integer;
 begin
   BishopOffset[a1]:=0;RookOffset[a1]:=0;
   for i:=1 to 8 do
   for j:=1 to 8 do
    begin
     FindMagicForSquare(i+j*10,true,SingleProbe,1,true);
     FindMagicForSquare(i+j*10,false,SingleProbe,1,true);
    end;
  
 end;


end.
