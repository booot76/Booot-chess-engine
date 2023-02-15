unit uSearch;

interface
uses uBitBoards,uBoard,uThread,uEval,uSort,uMaterial,uEndgame,uPawn,uAttacks,uMagic,uHash,SysUtils,Windows;
Type
  Tgame = record
              TimeStart : Cardinal;
              time  : Cardinal;
              rezerv:Cardinal;
              pondertime  : Cardinal;
              ponderrezerv : Cardinal;
              oldtime:cardinal;
              HashAge : integer;
              NodesTotal : cardinal;
              remain:integer;
              uciPonder : boolean;
              hashsize : integer;
              Threads : integer;
              RootDepth : integer;
            end;

Const
  MaxPly=127;
  Mate=32700;
  Inf=Mate+1;
  Draw=0;
  Stalemate=Draw;

  FullInfo=0;
  OnlyDepth=1;
  TimeStat=2;
  LowerStat=3;

  DeltaMargin=50;
  PieseFutilityValue : array[-Queen..Queen] of integer =(QueenValueEnd,RookValueEnd,BishopValueEnd,KnightValueEnd,PawnValueEnd,0,PawnValueEnd,KnightValueEnd,BishopValueEnd,RookValueEnd,QueenValueEnd);

  RazorMargin=200;
  RazorInc=25;
  RazorDepth=4;

  StatixMargin=80;
  StatixDepth=5;

  ProbCutDepth=5;
  ProbCutRed=4;
  ProbCutMargin=80;

  CountMoveDepth=16;

  FutilityDepth=5;
  FutilityMargin=100;

  SeeDepth=4;

  SingularDepth=8;

  HistoryDepth=2;

  IIDDepth : array[false..true] of integer = (8,6);


var
  game:TGame;
  RazoringValue,StatixValue : array[1..16] of integer;
  PrunningCount : array[1..16] of integer;
  LMRREd : array[false..true,false..True,1..MaxPly,1..Maxmoves] of integer;

Procedure Think;
Procedure Iterate(ThreadId:integer);
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
Function Search(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;SkipPrunning:boolean;emove:integer;prevmove:integer;cut:boolean):integer;
Function FV(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV;prevmove:integer):integer;

implementation
uses uUci;
Function MakePvString(var PV:TPV):ansistring;
var
  i : integer;
  s:ansistring;
begin
  s:='';
  For i:=1 to Pv[0] do
    s:=s+' '+StringMove(Pv[i]);
  Result:=s;
end;
Procedure PrintFullSearchInfo(iteration : integer;value:integer;pv:TPV;TimeEnd:Cardinal;typ:integer);
var
 timetot:Cardinal;
 nps,i : integer;
 s:ansistring;
 FullNodes : int64;
begin
  If game.Threads=1
    then FullNodes:=Threads[1].Board.Nodes
    else begin
           FullNodes:=0;
           for i:=1 to game.Threads do
             FullNodes:=FullNodes+Threads[i].Board.Nodes;
         end;
  timetot:=timeend-game.timestart;
  // ���� ���������� � ��������� ���������, ����� �� ����������� �������� ������� � �� ������ �����
  if TimeTot<250 then exit;
  // ��� ������ ������ ���������� � ��������. ����� ��������� ������ ���.
  if (typ=FullInfo) then
    begin
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
     if value<-Mate+MaxPly then s:=s+' score mate -'+inttostr(((value+mate) div 2)+1) else
     if value>Mate-MaxPly  then s:=s+' score mate ' +inttostr((mate-value) div 2) else
     s:=s+' score cp '+inttostr(value);
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
     s:=s+' pv '+MakePvString(PV);
     LWrite(s);
    end else
// ������ ������ ���������� � ���������� ����� ��������
  if (typ=OnlyDepth)  then
    begin
      s:='info depth '+inttostr(iteration);
      Lwrite(s);
    end else
// ������ ���������� �� ������ ��� ������������� ��������
  if (typ=TimeStat) then
    begin
      if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
      s:='info depth '+inttostr(iteration);
      s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
      Lwrite(s);
    end else
  if (typ=LowerStat) then
    begin
     if value<-Mate+MaxPly then exit;
     if value>Mate-MaxPly  then exit;
     if timetot=0 then nps:=0 else nps:=((FullNodes*1000) div timetot);
     s:='info depth '+inttostr(iteration);
     s:=s+' score cp '+inttostr(value);
     s:=s+' lowerbound';
     s:=s+' time '+inttostr(timetot)+' nodes '+inttostr(FullNodes)+' nps '+inttostr(nps);
     s:=s+' pv '+MakePVString(pv);
     LWrite(s);
    end
end;
Function isDraw(var Board:TBoard;var Tree:TTree;ply:integer):boolean;inline;
var
  MList:TMoveList;
  stop,i : integer;
begin
  // ���� �������� ������� 50 �����:
  if (Board.Rule50>=100) and ((Board.CheckersBB=0) or (GenerateLegals(0,Board,MList)>0)) then
    begin
      Result:=true;
      exit;
    end;
  // ���� �� ����� ��������� ���������� (� ��� ����� � �������� ��������)
  if Board.nullcnt<Board.Rule50
    then stop:=ply-Board.nullcnt
    else stop:=ply-Board.Rule50;
  i:=ply-2;
  while i>=stop do
    begin
      if i<-1 then break;
      if tree[i].Key=tree[ply].Key then
        begin
          Result:=true;
          exit;
        end;
      i:=i-2;
    end;
  Result:=false;
end;

Function isDangerPawn(move:integer;var Board:TBoard):boolean;inline;
begin
  if Board.SideToMove=white
   then result:=(Board.Pos[move and 63]=Pawn) and (posy[(move shr 6) and 63]>4)
   else result:=(Board.Pos[move and 63]=-Pawn) and (posy[(move shr 6) and 63]<5);
end;

Function LMRReduction(pv:boolean;imp:boolean;depth:integer;searched:integer):integer;
 var
  r :real;
begin
  r:=ln(depth)*ln(searched)/2;
  If r<0.8 then result:=0 else
    begin
      result:=round(r);
      If pv then
        begin
          Result:=result-1;
          if result<0 then result:=0;
        end;
      if (not pv) and (not imp) and (result>1) then inc(result);
    end;
end;
Procedure AddPV(move:integer;var PVLine:TPV;var Line:TPV);
var
  i : integer;
begin
  If (Line[0]>MaxPly) or (Line[0]<0)
    then Line[0]:=0;
  PVLine[1]:=move;
  for i:=1 to Line[0] do
    PVLine[i+1]:=Line[i];
  PVLine[0]:=Line[0]+1;
end;

Procedure Iterate(ThreadId:integer);
Const
  SMPLength : array[2..MaxThreads] of integer=(2,2, 4,4,4,4, 6, 6, 6,6, 6, 6,  8,  8, 8);
  SMPMask   : array[2..MaxThreads] of integer=(2,1,12,6,3,9,56,28,14,7,35,49,240,120,60);
  Step2     : array[1..8] of integer = (1,2,4,8,16,32,64,128);
// ������ ���� �������� (�� ������ ������)
var
  RootAlpha,RootBeta,BestMove,BestValue,Delta,RootDepth,cnt : integer;
  TimeEnd : Cardinal;
begin
  BestValue:=-Inf;
  RootAlpha:=-Inf;
  RootBeta:=Inf;
  Delta:=25;
  Threads[ThreadId].StableMove:=0;
  Threads[ThreadId].BestValue:=-Inf;
  RootDepth:=0;BestMove:=0;cnt:=0;
  // ��������� ���� ��������
  While RootDepth<=MaxPly do
    begin
     // ������� ����� ������ ����������� ������� �� 1
     inc(RootDepth);
     If threadID<>1 then
       begin
         // ��������������� ������ ����� ��������� ������� �������� ��������� ������ ������� �������
         inc(cnt);
         If cnt>SMPLength[ThreadId] then cnt:=1;
         If (RootDepth and Step2[cnt])=0 then Continue;
       end;
     if RootDepth>5 then
       begin
         Delta:=25;
         RootAlpha:=BestValue-Delta;
         If RootAlpha<-Inf then RootAlpha:=-Inf;
         RootBeta:=BestValue+Delta;
         if RootBeta>Inf then RootBeta:=Inf;
       end;
     While true do
      begin
       BestValue:=RootSearch(ThreadId,RootAlpha,RootBeta,RootDepth,Threads[ThreadId].Board,Threads[ThreadId].Tree,Threads[ThreadId].Sortunit,Threads[ThreadId].RootList,Threads[ThreadID].RootMoves,Threads[ThreadId].PVLine,BestMove);
       if Threads[ThreadId].AbortSearch then break;
       if BestMove<>0 then
        begin
          Threads[ThreadId].StableMove:=BestMove;
          // ��������� ������� ����� � ������ ����� �� ����� (������ ��� ���� �� ������ ����� � ������)
          UpdateList(BestMove,0,Threads[ThreadId].RootMoves-1,Threads[ThreadID].RootList);
          Threads[ThreadId].BestValue:=BestValue;
          AddPv(Bestmove,Threads[ThreadId].StablePv,Threads[ThreadId].Pvline);
        end;
       if BestValue<=RootAlpha then
        begin
          RootBeta:=(RootAlpha+RootBeta) div 2;
          RootAlpha:=BestValue-Delta;
          if RootAlpha<-Inf then RootAlpha:=-Inf;
          // ���� ������ �������, �� ��������� ����� �� �����������
          If (ThreadId=1) and  (game.time<>game.rezerv) then game.time:=game.rezerv;
        end else
       if BestValue>=RootBeta then
        begin
          If (ThreadID=1) then PrintFullSearchInfo(RootDepth,BestValue,Threads[ThreadId].PVLine,GetTickCount,LowerStat);
          RootAlpha:=(RootAlpha+RootBeta) div 2;
          RootBeta:=BestValue+Delta;
          if RootBeta>Inf then RootBeta:=Inf;
        end else break;
       Delta:=Delta+Delta;
      end;
      if Threads[ThreadId].AbortSearch then break;
      Threads[ThreadId].FullDepth:=RootDepth;
      Threads[ThreadId].BestValue:=BestValue;
      AddPv(Bestmove,Threads[ThreadId].StablePv,Threads[ThreadId].Pvline);
     // ��������� �������� - ��������� ���������� �������� (����������� ���� � �����)
     If ThreadID=1 then
      begin
       TimeEnd:=GetTickCount;
       PrintFullSearchInfo(RootDepth,0,Threads[ThreadId].StablePv,TimeEnd,TimeStat);
       // ����� ������������� �������� ���������� ���������� ���������� �������
       game.time:=game.oldtime;
        // ���� �������� �� ��� ����� ������� - ������� �� ������� ����� ��������
       If (game.time<>game.rezerv) and ((TimeEnd-game.TimeStart)>(0.6*game.time)) then break;
      end;

    end;
end;
Procedure Think;
// �������� ������� , �������������� �������. ����������� ����� �������� �������� ������� go � ������ �������� ������ ��� � ������ ����������.
var
  n,j : integer;
  s : ansistring;
  TimeEnd : Cardinal;
  Pondermove,BestID: integer;
begin
  NewSearch(1);
  Threads[1].PVLine[0]:=0;
  // ���������� ������ ����� �� ����� �������
  n:=GenerateLegals(0,Threads[1].Board,Threads[1].RootList);
  Threads[1].RootMoves:=n;
  game.RootDepth:=0;
 // ���� ������� ���������� (��� ��� ���) �� ������ �� ���� ��������� �������� � ������
  if n=0 then
    begin
      s:='info depth 0 score ';
      if Threads[1].Board.CheckersBB<>0
        then s:=s+inttostr(-mate)
        else s:=s+'0';
      LWrite(s);
      exit;
    end;
 // ��������� �������� ���� �� ����

  // ��������� ��������������� ������
  IF game.Threads>1 then
    begin
       // ��������� ��������� � ������� ��� ������������� ��������
      For j:=2 to game.Threads do
        CopyThread(j);
      SetEvent(IdleEvent);
    end;
  // ��������� �������� ����� � ���� ��� ���������� �� �������� ��� �������������
  Iterate(1);
  BestID:=1;
  If game.Threads>1 then
   begin
     // ������������� ���������� ������
    For j:=2 to game.Threads do
     Threads[j].AbortSearch:=true;
    ResetEvent(IdleEvent);
    While not isThreadIdle do;
    // �������: ��� �� ����� ��������������� ������� ����, ��� �������� �� ������� ������� ��� ����� ������ ������:
    For j:=2 to game.Threads do
     If (Threads[j].FullDepth>Threads[BestID].FullDepth) or ((Threads[j].FullDepth=Threads[BestID].FullDepth) and (Threads[j].BestValue>Threads[BestId].BestValue)) then BestId:=j;
   end;
  TimeEnd:=GetTickCount;
  // ���� �������� ������� ������ �� �������, �� �������� ���� �����-�� ���������� ��� �����������:
  If (TimeEnd-game.TimeStart)<250 then
    begin
      TimeEnd:=game.TimeStart+250;
      PrintFullSearchInfo(Threads[BestId].FullDepth,Threads[BestId].BestValue,Threads[BestId].PVLine,TimeEnd,FullInfo);
    end else
  // ���� ������ ��������� ��������� �� ��������������� ������ - ������� ���������� �� ����
  If BestID<>1 then PrintFullSearchInfo(Threads[BestId].FullDepth,Threads[BestId].BestValue,Threads[BestId].StablePV,TimeEnd,FullInfo);
  // ���� � ������������ �������� ��������� �� ������� - ������ "��������" � ���� �� �������� ������� �� ����� �� ������������
  if (Threads[BestId].FullDepth>=MaxPly-1) and (game.time>=48*3600*1000) and (game.rezerv>=48*3600*1000) and (game.uciPonder) then WaitPonderhit;
  // �������� �������� ������ ���, ���������� � �������� �������� ( � ��������� ���� ��������� � ��������������� ������)
  if Threads[BestId].StableMove=0 then Threads[BestId].StableMove:=Threads[BestId].RootList[0].move;
  // ������� �������� PonderMove  ���� ��� ��������:
  If game.uciPonder
    then Pondermove:=FindPonder(Threads[BestId].StableMove,Threads[1].Board)
    else Pondermove:=0;
  s:=StringMove(Threads[BestId].Stablemove);
  if (pondermove<>0) and (game.uciPonder)
        then s := s + ' ponder ' + StringMove(pondermove);
  LWrite('bestmove '+s);
end;
Function RootSearch(ThreadID:integer;alpha:integer;beta:integer;depth:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var RootList:TMoveList;n:integer;var PVLine:TPV;var BestMove:integer):integer;
var
   CheckInfo : TCheckInfo;
   Undo : TUndo;
   BestValue,j,extension,newdepth,value,R,D:integer;
   TimeEnd:Cardinal;
   isCheck,doresearch:boolean;
   Line:TPV;
begin
  PVLine[0]:=0;
  line[0]:=0;
  TimeEnd:=0;
  // �������������
  tree[1].Key:=Board.Key;
   // ��������� � ��������
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  // �������� ������� �������
  If (threadId=1) then
    begin
     TimeEnd:=GetTickCount;
     PrintFullSearchInfo(depth,0,PVLine,TimeEnd,OnlyDepth);
    end;
  BestValue:=-Inf;
  BestMove:=0;
  Tree[-1].StatEval:=-Inf;
  Tree[0].StatEval:=-Inf;
  if Board.CheckersBB=0
    then Tree[1].StatEval:=Evaluate(Board,1)
    else Tree[1].StatEval:=-Inf;
  // killers
  If (n>0) and (RootList[1].move<>0) and ((RootList[1].move and CapPromoFlag)=0) then SortUnit.Killers[1,0]:=RootList[1].move;
  If (RootList[0].move<>0) and ((RootList[0].move and CapPromoFlag)=0) then
    begin
     SortUnit.Killers[1,1]:=SortUnit.Killers[1,0];
     SortUnit.Killers[1,0]:=RootList[0].move;
    end;
  // ������ ���� ����� �� �����
  for j:=0 to n-1 do
       begin
         // ���������� � ������� ������������ ����
         if (ThreadID=1) and ((TimeEnd-game.TimeStart)>2000) then   Lwrite('info currmovenumber '+inttostr(j+1)+' info currmove '+StringMove(RootList[j].move));
         isCheck:=isMoveCheck(RootList[j].move,CheckInfo,Board);
         extension:=0;
         if (isCheck) and (quickSee(RootList[j].move,Board)>=0) then extension:=1;
         newdepth:=depth+extension-1;
         MakeMove(RootList[j].move,Board,Undo,isCheck);
         value:=-Inf;
         if (j=0) then value:=-Search(ThreadId,true,-Beta,-Alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,false) else
           begin
            doresearch:=true;
             // LMR Reduction
             if (extension=0) and (depth>=3) and (j>0)  and (not isCheck) and ((RootList[j].move and CapPromoFlag)=0) then
               begin
                R:=LMRRED[true,true,depth,j+1];
                if R>0 then
                  begin
                   D:=newdepth-R;
                   if D<1 then D:=1;
                   value:=-Search(ThreadId,false,-alpha-1,-alpha,D,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,true);
                   doresearch:=(value>alpha);
                  end;
               end;
             if (doresearch) then value:=-Search(ThreadId,false,-alpha-1,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,true);
             if (value>alpha)   then
              begin
               // ���� ��� �� ����� �������� - ���� �������������� ����� ����� ��������� ��� ������
               If (ThreadId=1) and (game.time<>game.rezerv) then game.time:=game.rezerv;
               value:=-Search(ThreadId,true,-beta,-alpha,newdepth,2,Board,Tree,SortUnit,Line,false,0,RootList[j].move,false);
              end;
           end;
         UnMakeMove(RootList[j].move,Board,Undo);
         if Threads[ThreadId].AbortSearch then break;
         if value>BestValue then
          begin
           BestValue:=value;
           if value>alpha then
            begin
             // �������� ������ ��� �� ����� - �������� ������ ����������
             BestMove:=RootList[j].move;
             // �������� ����������� �������� �������
             AddPv(Bestmove,PVLine,Line);
             if value>=beta then break;
             If (ThreadId=1) then PrintFullSearchInfo(Depth,BestValue,PVLine,GetTickCount,FullInfo);
             alpha:=value;
            end;
          end;
       end;
  Result:=BestValue;
end;

Function Search(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var Tree:Ttree;var SortUnit:TSortUnit;var PVLine:TPV;SkipPrunning:boolean;emove:integer;prevmove:integer;cut:boolean):integer;
label l1;
var
  Undo : TUndo;
  CheckInfo : TCheckInfo;
  MList,OldMoves:TMoveList;
  value,hashmove,hashvalue,hashdepth,hashtyp,move,searched,qsearched,extension,newalpha,newbeta,newdepth,StaticEval,Eval,R,NullValue,D,BestValue,preddepth,BestMove,HistValue,piese,from,dest,rmove,Rhist: integer;
  killer1,killer2,counter1,counter2,oldstat,hashm,ProbMar : integer;
  isCheck,doresearch,SingularNode,imp,lmp: boolean;
  Line : TPV;
  HashIndex,Key : int64;
begin
  // ������
  if depth<=0 then
    begin
      Result:=FV(ThreadId,pv,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
      exit;
    end;
  // ���������� � ��������
  inc(Board.Nodes);
  dec(Board.remain);
  tree[ply].Key:=Board.Key;
  if (ThreadID=1) and (Board.remain<=0) then
    begin
      Board.remain:=game.remain;
      poll(Board);
    end;
  If (Threads[ThreadId].AbortSearch) or (ply>=MaxPly-1) or (isDraw(Board,tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board,ThreadID)
       else result:=0;
     exit;
    end;
  // Mate Prunning
  if alpha<-Mate+ply then alpha:=-Mate+ply;
  if beta>Mate-ply then beta:=Mate-ply;
  if alpha>=beta then
    begin
      Result:=alpha;
      exit;
    end;
  Key:=Board.Key;
  if emove<>0 then Key:=Key xor Zexclude;
  // Hash
  HashIndex:=HashProbe(Board,Key);
  if HashIndex>=0 then
    begin
      Hashmove:=TT[HashIndex].move;
      HashValue:=ValueFromTT(TT[HashIndex].value,ply);
      Hashtyp:=TT[HashIndex].typage and 3;
      HashDepth:=TT[HashIndex].depth;
      if (not pv) then
        begin
         if (hashdepth>=depth) and (HashValue<>-Inf) then
          begin
            if (((hashtyp and HashLower)<>0) and (hashvalue>=beta)) or (((hashtyp and HashUpper)<>0) and (hashvalue<=alpha))  then
              begin
                Result:=HashValue;
                if (hashvalue>=beta) and (hashmove<>0) and ((hashmove and CapPromoFlag)=0) then AddToHistory(Hashmove,prevmove,depth,ply,0,OldMoves,SortUnit,Board);
                exit;
              end;
          end;
        end;
    end else
    begin
      HashMove:=0;
      HashValue:=-Inf;
      HashTyp:=0;
      Hashdepth:=-Maxply;
    end;
    SetUndo(Board,Undo);
    FillCheckInfo(CheckInfo,Board);
  // ����������� ������
  if (Board.CheckersBB=0) then
    begin
     if (prevmove=0) then StaticEval:=-tree[ply-1].StatEval+2*Tempo else
       if (tree[ply].StatKey=Board.Key)
         then StaticEval:=tree[ply].StatEval
         else StaticEval:=Evaluate(Board,ThreadID);
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
     Eval:=StaticEval;
     // �������� ������ �����
     if (HashIndex>=0) and (HashValue<>-Inf) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<Eval) then Eval:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>Eval) then Eval:=HashValue;
       end;
     if (not SkipPrunning) then
       begin
         // ���� �� �� ��� ����� - �������� �������������� ���������
         // Razoring
         if (not pv) and (depth<RazorDepth) and (HashMove=0) and (Eval+RazoringValue[depth]<=alpha) then
           begin
             if (depth<=1) then
               begin
                 Result:=FV(ThreadId,false,alpha,beta,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
                 exit;
               end;
             newalpha:=alpha-RazoringValue[depth];
             value:=FV(ThreadID,false,newalpha,newalpha+1,0,ply,Board,SortUnit,Tree,PVLine,prevmove);
             if value<=newalpha then
               begin
                 Result:=value;
                 exit;
               end;
           end;
         // Statix
         if (not pv) and (depth<StatixDepth) and (Eval-StatixValue[depth]>=beta) and (Board.NonPawnMat[Board.SideToMove]>0) then
           begin
             Result:=Eval-StatixValue[depth];
             exit;
           end;

         // NullMove
        If (not pv) and (Eval>=beta) and ((StaticEval>=beta) or (depth>=12)) and (Board.NonPawnMat[Board.SideToMove]>PieseTypValue[bishop]) then
           begin
             R:=3+(depth div 4);
             extension:=(Eval-beta) div PawnValueMid;
             if extension>2 then extension:=2;
             R:=R+extension;
             MakeNullMove(Board);
             newdepth:=depth-R;
             If newdepth>0
               then NullValue:=-Search(ThreadId,false,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,PVLine,true,0,0,(not cut))
               else NullValue:=-FV(ThreadId,false,-beta,-alpha,0,ply+1,Board,SortUnit,Tree,PVLine,0);
             UnMakeNullMove(Board,Undo);
             If NullValue>=beta then
               begin
                if NullValue>Mate-MaxPly then NullValue:=beta;
                If (depth<12) then
                  begin
                    Result:=NullValue;
                    exit;
                  end;
                If newdepth>0
                  then value:=Search(ThreadId,false,alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,0,prevmove,false)
                  else value:=FV(ThreadId,false,alpha,beta,0,ply,Board,Sortunit,Tree,PVLine,prevmove);
                If value>=beta then
                  begin
                    Result:=NullValue;
                    exit;
                  end;
               end;
           end;
        // ProbCut
        If (not pv) and (depth>=ProbCutDepth) and (Abs(beta)<Mate-MaxPly) then
          begin
            newbeta:=beta+ProbCutMargin;
            If newbeta>Mate then newbeta:=Mate;
            newdepth:=depth-ProbCutRed;
            tree[ply].Status:=TryHashMove;
            hashm:=hashmove;
            ProbMar:=PieseFutilityValue[Board.CapturedPiese];
            move:=NextProbCut(MList,Board,Tree,hashm,ply,ProbMar);
            While move<>0 do
              begin
                if islegal(move,CheckInfo.Pinned,Board) then
                  begin
                    isCheck:=isMoveCheck(move,CheckInfo,Board);
                    MakeMove(move,Board,Undo,isCheck);
                    value:=-Search(ThreadId,false,-newbeta,-newbeta+1,newdepth,ply+1,Board,Tree,SortUnit,PVLine,true,0,move,(not cut));
                    UnMakeMove(move,Board,Undo);
                    If value>=newbeta then
                      begin
                        Result:=value;
                        exit;
                      end;
                  end;
                move:=NextProbCut(MList,Board,Tree,hashm,ply,ProbMar);
              end;
          end;

         // IID
        if (depth>=IIDDepth[pv]) and (hashmove=0) and ((pv) or (StaticEval+StatixMargin>=beta)) then
          begin
            newdepth:=depth-2;
            if (not pv) then newdepth:=newdepth - (depth div 4);
            value:=search(ThreadId,pv,alpha,beta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,0,prevmove,Cut);
            If value<>-Inf then
              begin
               HashIndex:=HashProbe(Board,Board.Key);
               if HashIndex>=0 then
                begin
                 Hashmove:=TT[HashIndex].move;
                 HashValue:=ValueFromTT(TT[HashIndex].value,ply);
                 Hashtyp:=TT[HashIndex].typage and 3;
                 HashDepth:=TT[HashIndex].depth;
                end else
                begin
                 HashMove:=0;
                 HashValue:=-Inf;
                 HashTyp:=0;
                 Hashdepth:=-Maxply;
                end;
              end;
          end;
       end;
    end else
    begin
     StaticEval:=-Inf;
     tree[ply].StatEval:=StaticEval;
     tree[ply].StatKey:=Board.Key;
    end;
  pvline[0]:=0;
  line[0]:=0;
  tree[ply].Status:=TryHashMove;
  BestMove:=0;
  searched:=0;qsearched:=0;
  BestValue:=-Inf;
  SingularNode:=(Depth>=SingularDepth) and (Hashmove<>0) and (abs(HashValue)<Mate-Maxply)  and (emove=0) and ((HashTyp and HashLower)<>0) and (HashDepth>=depth-3);
  imp:=(Tree[ply].StatEval>=tree[ply-2].StatEval) or (tree[ply].StatEval=-Inf) or (tree[ply-2].StatEval=-Inf);
  Killer1:=SortUnit.Killers[ply,0];
  Killer2:=SortUnit.Killers[ply,1];
  If prevmove<>0 then
    begin
      dest:=(prevmove shr 6) and 63;
      piese:=Board.Pos[dest];
      counter1:=SortUnit.CounterMoves[piese,dest];
    end else counter1:=0;
  If (ply>=3)
    then counter2:=SortUnit.Killers[ply-2,0]
    else counter2:=0;
  // �������
  move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,counter1,counter2,ply,prevmove,depth);
  While move<>0 do
    begin
     if move=emove then goto l1;
     if islegal(move,CheckInfo.Pinned,Board) then
       begin
        inc(searched);
        lmp:=((not pv) and (depth<CountMoveDepth) and (searched>=PrunningCount[depth]));
        isCheck:=isMoveCheck(move,CheckInfo,Board);
        extension:=0;
        if (not lmp) and (isCheck) and (quickSee(move,Board)>=0) then extension:=1;
        // Singular
        if (extension=0) and (SingularNode) and (move=hashmove) then
          begin
            newbeta:=hashvalue-2*depth;
            newdepth:=depth div 2;
            oldstat:=tree[ply].Status;
            value:=Search(ThreadId,false,newbeta-1,newbeta,newdepth,ply,Board,Tree,SortUnit,PVLine,true,move,prevmove,cut);
            tree[ply].Status:=oldstat;
            if value<newbeta then extension:=1;
          end;
        newdepth:=depth+extension-1;
        from:=move and 63;
        dest:=(move shr 6) and 63;
        piese:=Board.Pos[from]; //  ��� ��� �� ����� �� ������
        HistValue:=SortUnit.History[piese,dest];
        // ���� ��������������
        if (not pv) and  (extension=0) and (Board.CheckersBB=0) and (not isCheck) and ((move and CapPromoFlag)=0) and (bestvalue>-Mate+Maxply) and (not isDangerPawn(move,Board))  and (Board.NonPawnMat[Board.SideToMove]>0)  then
          begin
            // CountMovePrunning
            if lmp then goto l1;
              // FutilityPrunning
            preddepth:=newdepth-LMRRED[pv,imp,depth,searched];
            if preddepth<0 then preddepth:=0;
            if preddepth<FutilityDepth then
              begin
                value:=StaticEval+StatixValue[preddepth]+FutilityMargin;
                if value<=alpha then
                  begin
                    if value>bestvalue then bestvalue:=value;
                    goto l1;
                  end;
              end;
            // See LowDepth Prunning
            if (preddepth<SeeDepth) and (QuickSee(move,Board)<0) then goto l1;
          end;
        MakeMove(move,Board,Undo,isCheck);
        value:=-Inf;
        if (pv) and (searched=1) then value:=-Search(ThreadId,true,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,false) else
        begin
          doresearch:=true;
          // LMR Reduction
          if (depth>=3) and (searched>1) and (((move and CapPromoFlag)=0) or (lmp)) and (tree[ply].Status>=GenerateOthers)and (extension=0) and (not isCheck)  then
            begin
              R:=LMRRED[pv,imp,depth,searched];
              If ((move and CapPromoFlag)<>0) then
                begin
                  If R>0 then dec(R);
                end else
                begin
                 if (cut) then inc(R,2);
                 If (TypOfPiese[piese]<>Pawn) and (TypOfPiese[piese]<>King) then
                  begin
                   rmove:=dest or (from shl 6);
                   If (See(rmove,Board)<0) then dec(R,2);
                  end;
                 Rhist:=(HistValue-5000) div 10000;
                 If Rhist<-2 then Rhist:=-2 else
                 If Rhist>2 then RHist:=2;
                 R:=R-Rhist;
                end;
              if R>0 then
                begin
                 D:=newdepth-R;
                 if D<1 then D:=1;
                 value:=-Search(ThreadId,false,-alpha-1,-alpha,D,ply+1,Board,Tree,SortUnit,Line,false,0,move,true);
                 doresearch:=(value>alpha);
                end;
            end;
          if doresearch then value:=-Search(ThreadId,false,-alpha-1,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,(not cut));
          if (pv) and (value>alpha) and (value<beta) then value:=-Search(ThreadId,true,-beta,-alpha,newdepth,ply+1,Board,Tree,SortUnit,Line,false,0,move,false);
        end;
        UnMakeMove(move,Board,Undo);
        if Threads[ThreadId].AbortSearch then break;
        if value>bestvalue then
         begin
          bestvalue:=value;
          if value>alpha then
           begin
            BestMove:=move;
            AddPv(Bestmove,PVLine,Line);
            if value>=beta then break;
            alpha:=value;
           end;
         end;
       // �����  ���� ��������� ��������
         if  ((move and CapPromoFlag)=0) and (move<>Bestmove) then
           begin
            inc(qsearched);
            OldMoves[qsearched].move:=move;
           end;
       end;
    l1:
       move:=Next(MList,Board,SortUnit,tree,hashmove,killer1,killer2,counter1,counter2,ply,prevmove,depth);
    end;
  if not Threads[ThreadId].AbortSearch then
    begin
     // ���� ����� � ������� ���, �� ���� ��� ��� ���� ���
     if (searched=0)  then
       begin
        if emove<>0 then BestValue:=alpha else
        if Board.CheckersBB<>0
          then BestValue:=-Mate+ply
          else BestValue:=0;
       end else
      // ��������� �������
     if (BestMove<>0) and ((BestMove and CapPromoFlag)=0) then AddToHistory(Bestmove,prevmove,depth,ply,qsearched,OldMoves,SortUnit,Board);
      // ��������� ���
     if BestValue>=beta then HashStore(Key,Board,ValueToTT(Bestvalue,ply),depth,HashLower,Bestmove) else
     if (pv) and (BestMove<>0)
      then HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashExact,BestMove)
      else HashStore(Key,Board,valueToTT(bestvalue,ply),depth,HashUpper,0);
    end else bestvalue:=0;
  Result:=bestvalue;
end;
Function FV(ThreadID:integer;pv:boolean;alpha:integer;beta:integer;depth:integer;ply:integer;var Board:TBoard;var SortUnit:TSortUnit;var Tree:Ttree;var PVLine:TPV;prevmove:integer ):integer;
label l1;
var
  value,move,bestvalue,futility,qDepth,hashmove,hashvalue,hashdepth,hashtyp,oldalpha,bestmove,cappiese: integer;
  HashIndex :int64;
  CheckInfo:TCheckInfo;
  MList : TMoveList;
  Undo:TUndo;
  isCheck,isPrune : boolean;
  Line:TPV;
begin
  inc(Board.Nodes);
  dec(Board.remain);
  tree[ply].Key:=Board.Key;
  oldalpha:=alpha;
  // ����� ������ ���� ����� ��� ������� ����������
  If (Threads[ThreadId].AbortSearch) or (ply>=MaxPly-1) or (isDraw(Board,Tree,ply)) then
    begin
     if (ply>=MaxPly-1) and (Board.CheckersBB=0)
       then Result:=Evaluate(Board,ThreadId)
       else result:=0;
     exit;
    end;
  if (Board.CheckersBB<>0) or (depth>=0)
    then qDepth:=0
    else qDepth:=-1;
  // Hash
  HashIndex:=HashProbe(Board,Board.Key);
  if HashIndex>=0 then
    begin
      Hashmove:=TT[HashIndex].move;
      HashValue:=ValueFromTT(TT[HashIndex].value,ply);
      Hashtyp:=TT[HashIndex].typage and 3;
      HashDepth:=TT[HashIndex].depth;
      if (not pv) then
        begin
         if (hashdepth>=qDepth) and (HashValue<>-Inf) then
          begin
            if (((hashtyp and HashLower)<>0) and (hashvalue>=beta)) or (((hashtyp and HashUpper)<>0) and (hashvalue<=alpha))  then
              begin
                Result:=HashValue;
                exit;
              end;
          end;
        end;
    end else
    begin
      HashMove:=0;
      HashValue:=-Inf;
      HashTyp:=0;
    end;
  // ����������� ������ � ����� ���� ��� ��� ����������
  if Board.CheckersBB=0 then
    begin
      if (prevmove=0) then bestvalue:=-tree[ply-1].StatEval+2*Tempo else
        if tree[ply].StatKey=Board.Key
        then bestValue:=tree[ply].StatEval
        else bestvalue:=Evaluate(Board,ThreadId);
      tree[ply].StatEval:=bestvalue;
      tree[ply].StatKey:=Board.Key;
      // �������� ������ �����
     if (Hashindex>=0) and (HashValue<>-Inf) then
       begin
         if ((hashtyp and HashUpper)<>0) and (HashValue<bestvalue) then bestvalue:=HashValue;
         if ((hashtyp and HashLower)<>0) and (HashValue>bestvalue) then bestvalue:=HashValue;
       end;
      if bestvalue>alpha then
       begin
        if bestvalue>=beta then
         begin
          Result:=bestvalue;
          exit;
         end;
        alpha:=bestvalue;
       end;
      futility:=bestvalue+DeltaMargin;
    end else
    begin
      bestvalue:=-Inf;
      futility:=-Inf;
      tree[ply].StatEval:=bestvalue;
      tree[ply].StatKey:=Board.Key;
    end;
  // ���������� � ��������
  pvline[0]:=0;
  line[0]:=0;
  Bestmove:=0;
  FillCheckInfo(CheckInfo,Board);
  SetUndo(Board,Undo);
  tree[ply].Status:=TryHashMove;
  move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,prevmove);
  while move<>0 do
   begin
    isCheck:=isMoveCheck(move,CheckInfo,Board);
    // Futility
    if (not pv) and (Board.CheckersBB=0) and (not isCheck) and (futility>-Mate+MaxPly) and (not isDangerPawn(move,Board)) and (Board.NonPawnMat[Board.SideToMove]>0) then
           begin
             cappiese:=Board.Pos[(move shr 6) and 63];
             value:=Futility+PieseFutilityValue[cappiese];
             If (cappiese=0) and ((move and CaptureFlag)<>0) then value:=value+PieseFutilityValue[pawn];
             if value<=alpha then
               begin
                 if value>bestvalue then bestvalue:=value;
                 goto l1;
               end;
             if (futility<=alpha) and (See(move,Board)<=0) then
               begin
                 if futility>bestvalue then bestvalue:=futility;
                 goto l1;
               end;
           end;
    isPrune:=(Board.CheckersBB<>0) and ((move and CaptureFlag)=0) and (bestvalue>-Mate+MaxPly);
    if ((Board.CheckersBB=0) or (isPrune)) and ((move and PromoteFlag)=0) and (QuickSee(move,Board)<0) then goto l1;
    if (isLegal(move,CheckInfo.Pinned,Board))  then
      begin
        MakeMove(move,Board,Undo,isCheck);
        value:=-FV(ThreadId,pv,-beta,-alpha,depth-1,ply+1,Board,SortUnit,Tree,Line,move);
        UnMakeMove(move,Board,Undo);
        if value>bestvalue then
          begin
           bestvalue:=value;
           if value>alpha then
             begin
              Bestmove:=move;
              AddPv(Bestmove,PVLine,Line);
              if value>=beta then
                begin
                 HashStore(Board.Key,Board,ValueToTT(value,ply),qDepth,HashLower,move);
                 Result:=value;
                 exit;
                end;
              alpha:=value;
             end;
          end;
      end;
  l1:
     move:=NextFV(MList,Board,SortUnit,tree,CheckInfo,hashmove,ply,depth,prevmove);
   end;
 // ����������� ���
  if not Threads[ThreadId].AbortSearch then
   begin
    if (Board.CheckersBB<>0) and (bestvalue=-Inf)  then
     begin
      result:=-Mate+ply;
      exit;
     end;
    if (pv) and (bestvalue>oldalpha)
      then HashStore(Board.Key,Board,valueToTT(bestvalue,ply),qDepth,HashExact,BestMove)
      else HashStore(Board.Key,Board,valueToTT(bestvalue,ply),qDepth,HashUpper,BestMove);
   end else bestvalue:=0;
  Result:=bestvalue;
end;

Procedure SearchInit;
var
  i,j:integer;
  imp : boolean;
begin
  for i:=1 to 16 do
    begin
      RazoringValue[i]:=RazorMargin+RazorInc*(i-1);
      StatixValue[i]:=StatixMargin*i;
      PrunningCount[i]:=3+((i*i) div 2);
    end;
  for i:=1 to Maxply do
  for j:=1 to MaxMoves do
  for imp:=false to true do
    begin
      LMRRED[true,imp,i,j]:=LMRReduction(true,imp,i,j);
      LMRRED[false,imp,i,j]:=LMRReduction(false,imp,i,j);
    end;
end;

initialization
SearchInit;
end.
