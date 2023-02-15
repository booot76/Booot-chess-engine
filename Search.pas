unit Search;

interface
  uses params,board,Sort,Attacks,move,evaluation,movegen,BitBoards,hash,pawn,material,history,windows,sysutils;
TYPE
    TExtension=array[false..true] of integer;
    T14 = array[0..13] of integer;
    T8=array[0..7] of integer;

CONST
     QSExtraCheckMargin=10;
     Aspiration=20;
     DeltaMargin=120;
     NullMoveMargin=200;
     NullExtraMargin=100;
     NullExtraDepth=5*FullPly;
     NullBetaDepth=4*FullPly;
     RazorDepth=4*FullPly;
     StatixDepth=4*FullPly;
     LMRDepth=7*FullPly;
     StatixMargin  : t8=(90,90,135,135,180,180,225,225);
     RazorMargin   : t8=(200,200,220,240,260,280,300,320);
     SingularMargin=20;
     LMRMovesCount : T14 = (3,3,3,4,4,4,6,6,10,10,10,10,20,20);
     CheckExtension      : TExtension=(1,2);
     OneRepExtension     : TExtension=(2,2);
     Pawnon7Extension    : Textension=(1,1);
     PasserPushExtension : Textension=(0,1);
     EndgameExtension    : TExtension=(2,2);
     ExchangeExtension   : Textension=(0,1);
     LMRMoves            : Textension=(4,10);
     RootLMRMoves        = 12;
     SEDepth             : Textension=(8*FullPly,6*FullPly);
     IIDDepth            : Textension=(8*FullPly,5*FullPly);
     IIDMargin=100;
Function isPasser(var Board:Tboard;move:Tmove):boolean;
Function isDraw(var Board:Tboard):boolean;
Procedure NodeInitNextQS(color:Tcolor;depth:integer;var Board:Tboard;var CheckInfo:TCheckInfo;var Undo:Tundo; var MoveList:TmoveList);
Procedure NodeInitNext(color:Tcolor;depth:integer;var Board:Tboard;var CheckInfo:TCheckInfo;var Undo:Tundo; var MoveList:TmoveList;var BadCapturesList:TmoveList;var SortUnit:TSortUnit;hashmove:Tmove;ply:integer);
Function FV(var Board:TBoard;alpha:integer;beta:integer;depth:integer;ply:integer;var PVLine:TPVLine):integer;
Function SearchFull(var Board:TBoard;var SortUnit:TSortUnit;alpha:integer;beta:integer;depth:integer;ply:integer;var PVLine:TPVLine;doNull:boolean;emove:Tmove):integer;
Procedure Think(var Board:Tboard;var SortUnit:TSortUnit;var PV:TPVLine);
Procedure PrepareRootList(var Board:Tboard;var RootList:TmoveList);
Procedure UpdRootList(var RootList:TmoveList;pvmove:Tmove);
Function ExtendMove(var Board:TBoard;var MoveList:TmoveList;move:Tmove;var dangermove:boolean;isCheck:boolean;pv:boolean;mypieses:integer):integer;
Function isPrune(var Board:Tboard;move:Tmove;threatmove:tmove):boolean;
implementation
   uses uci;
Procedure NodeInitNext(color:Tcolor;depth:integer;var Board:Tboard;var CheckInfo:TCheckInfo;var Undo:Tundo; var MoveList:TmoveList;var BadCapturesList:TmoveList;var SortUnit:TSortUnit;hashmove:Tmove;ply:integer);
begin
  SetCheckInfo(color,CheckInfo,Board);
  NextInit(Board,MoveList,BadCapturesList,CheckInfo,SortUnit,hashmove,ply);
end;

Procedure NodeInitNextQS(color:Tcolor;depth:integer;var Board:Tboard;var CheckInfo:TCheckInfo;var Undo:Tundo; var MoveList:TmoveList);
begin
  SetCheckInfo(color,CheckInfo,Board);
  InitNodeUndo(Board,Undo);
  NextQSInit(Board,MoveList,CheckInfo,depth);
end;
Function SearchRoot(var Board:TBoard;var SortUnit:TsortUnit;alpha:integer;beta:integer;depth:integer;var RootList:TMoveList;var PV:TPVLine;prevvalue:integer):integer;
label l1;
var
   OldNodes:cardinal;
   i,f,value,BestValue,ext,mypieses,newdepth:integer;
   move:Tmove;
   CheckInfo:TcheckInfo;
   Undo:Tundo;
   color:Tcolor;
   isCheck,isDanger,doresearch : boolean;
   Line,oldpv:TPVLINE;
   s:string;
   temp:TBitBoard;
begin
   // Сортируем
  oldpv:=pv;
  PV.count:=0;
  if RootList.count>1 then SortList(RootList);
  color:=Board.Color;
  if color=white
     then temp:=Board.CPieses[white] and (not Board.Pieses[WhitePawn])
     else temp:=Board.CPieses[black] and (not Board.Pieses[BlackPawn]);
  mypieses:=BitCount(temp);
  SetCheckInfo(Color,CheckInfo,Board);
  InitNodeUndo(Board,Undo);
  BestValue:=-Mate;
  value:=-mate;
  for  i:=1 to RootList.count do
    begin
      move:=RootList.Moves[i];
      if (depth>10*FullPly) and (game.time>3000) then
        begin
          s:='info currmovenumber '+inttostr(i)+' info currmove '+MoveToStr(move);
          Lwrite(s);
        end;
      isCheck:=isMoveCheck(color,move,CheckInfo,Board);
      ext:=ExtendMove(Board,RootList,move,isDanger,isCheck,true,mypieses);
      Makemove(color,move,Board,Undo);
      Board.oncheck:=ischeck;
      OldNodes:=game.NodesTotal;
      newdepth:=depth+ext-FullPly;
      if (i=1) then
        begin
          value:=-SearchFull(Board,SortUnit,-beta,-alpha,newdepth,2,Line,true,movenone);
        end else
        begin
          doresearch:=true;
          if (depth>=3*FullPly) and (not isDanger) and (i>RootLMRMoves)  then
            begin
              value:=-SearchFull(Board,SortUnit,-alpha-1,-alpha,newdepth-FullPly,2,Line,true,movenone);
              doresearch:=(value>alpha);
            end;
          if (doresearch)  then
           begin
            value:=-SearchFull(Board,SortUnit,-alpha-1,-alpha,newdepth,2,Line,true,movenone);
            if (value>alpha) and (not game.AbortSearch) then
              begin
                game.time:=game.rezerv;
                Pv.Moves[1]:=move;
                pv.count:=1;
                value:=-SearchFull(Board,SortUnit,-beta,-alpha,newdepth,2,Line,true,movenone);
              end;
           end;
        end;
l1:
       RootList.Values[i]:=game.NodesTotal-OldNodes;
       UnMakeMove(color,Board,Undo);
       if game.AbortSearch then break;
       if value>BestValue then
            begin
              BestValue:=Value;
              if Value>alpha then
                begin
                 Pv.Moves[1]:=move;
                 for f:=1 to line.count do
                   PV.Moves[f+1]:=line.Moves[f];
                 PV.count:=Line.count+1;
                 oldpv:=pv;
                 alpha:=Value;
                end;
              if value>=beta then
                begin
                  Result:=value;
                  exit;
                end; 
            end;
    end;
 PV:=oldpv;
 Result:=BestValue;
end;

Function SearchFull(var Board:TBoard;var SortUnit:TSortUnit;alpha:integer;beta:integer;depth:integer;ply:integer;var PVLine:TPVLine;doNull:boolean;emove:Tmove):integer;
label l1;
var
   pv,isCheck,isLegal,isdanger,doresearch,Matethreat:boolean;
   color:Tcolor;
   hashtyp,hashvalue,hashdepth,mypieses,StaticEval,RefEval,pseudocheck,BestValue,value,f,MovesSearched,OldMovesCount,hashindex,oldalpha,R,ext,newdepth,preddepth,newalpha,newbeta:integer;
   temp:TBitBoard;
   CheckInfo:Tcheckinfo;
   Undo:TUndo;
   Movelist,BadCapturesList,BadmovesList : TmoveList;
   Line : TPVLine;
   move,hashmove:Tmove;
   Piese:Tpiese;
   dest:Tsquare;
   threatmove:Tmove;

begin
 // Если достигли предельной глубины - включаем модель форсированной игры
  if (depth<FullPly) then
    begin
      result:=FV(Board,alpha,beta,0,ply,PVLine);
      exit;
    end;
  pvline.count:=0;
  Pvline.Moves[1]:=MoveNone;
  inc(game.NodesTotal) ;
  dec(game.remain);
  if game.remain<=0 then poll(game.AbortSearch);
 // Ранний выход если ничья
 if (isDraw(Board)) or (ply>=MaxPly-1) or (game.AbortSearch) then
    begin
      Result:=0;
      exit;
    end;
  // Инициализация узла
  pv:=(beta-alpha)>1;
  oldalpha:=alpha;
  color:=Board.Color;
  hashmove:=MoveNone;
  hashvalue:=-mate;
  hashtyp:=-1;
  hashdepth:=-MaxPly;
  threatmove:=MoveNone;
  MovesSearched:=0;
  OldMovesCount:=0;
  BestValue:=-Mate;
  Matethreat:=false;
  if color=white
     then temp:=Board.CPieses[white] and (not Board.Pieses[WhitePawn])
     else temp:=Board.CPieses[black] and (not Board.Pieses[BlackPawn]);
  mypieses:=BitCount(temp);
  // Mate distance prunning
  if -mate+ply>=beta then
    begin
      Result:=beta;
      exit;
    end;
  if mate-ply<=alpha then
   begin
    Result:=alpha;
    exit;
   end;
  
// пробуем воспользоваться хешем
  hashindex:=HashProbe(Board,emove);
  if (hashindex>=0)  then
    begin
      // Как минимум можно взять ход из хеша
      hashmove:=TT[hashindex].data1 and 65535;
      hashdepth:=(TT[hashindex].data2 shr 8) and 255;
      hashvalue:=(TT[hashindex].data1 shr 16) and 65535;
      hashvalue:=ValueFromTT(HashValue-HashValueMax,ply);
      hashtyp:=(TT[hashindex].data2 shr 5) and 7;
      if (not pv) and (depth<=hashdepth) then
        begin
          if (hashtyp=HashExact) or ((hashtyp=HashLower) and (hashvalue>=beta)) or ((hashtyp=HashUpper) and (hashvalue<=alpha)) then
            begin
              PVLine.count:=1;
              PVLine.Moves[1]:=hashmove;
              StaticEval:=(TT[hashindex].data2 shr 16) and 65535;
              StaticEval:=StaticEval-HashValueMax;
              if (StaticEval=-mate) and (not Board.oncheck) then StaticEval:=Eval(Board);
              HashStore(Board,ValueToTT(hashvalue,ply),hashdepth,HashTyp,hashmove,game.Hashage,emove,StaticEval);
              Result:=hashvalue;
              exit;
            end;
        end;
    end;
  InitNodeUndo(Board,Undo);
  StaticEval:=-Mate;
  RefEval:=-mate;
  // Вычисляем статическую оценку
  if  (not Board.oncheck) then
    begin
      if hashindex>=0
        then begin
          StaticEval:=(TT[hashindex].data2 shr 16) and 65535;
          StaticEval:=StaticEval-HashValueMax;
        end else
        begin
         StaticEval:=Eval(Board);
         HashStore(Board,0,0,0,0,game.Hashage,emove,StaticEval);
        end;
      RefEval:=StaticEval;
      if (hashindex>=0) and (depth>=hashdepth) then
        begin
          if (hashtyp in [hashlower,hashexact]) and (hashvalue>RefEval) then RefEval:=hashvalue;
          if (hashtyp in [hashupper,hashexact]) and (hashvalue<RefEval) then RefEval:=hashvalue;
        end;
    end;

  // Razoring
  if (not pv) and (depth<RazorDepth) and (not Board.oncheck) and (beta<(Mate-FullPly*MaxPly)) and (hashmove=MoveNone) and (donull) and (emove=movenone)
    and (RefEval+RazorMargin[depth]<=alpha) and ((Board.Pieses[WhitePawn] and RanksBB[7])=0) and ((Board.Pieses[BlackPawn] and RanksBB[2])=0) then
      begin
        newalpha:=alpha-RazorMargin[depth];
        value:=FV(Board,newalpha,newalpha+1,0,ply,Line);
        if value<=newalpha then
          begin
            Result:=value;
            exit;
          end;
      end;


 if (not pv) and (donull)  and (not Board.oncheck) and (beta<(Mate-FullPly*MaxPly)) and (mypieses>1) and (emove=movenone)  then
    BEGIN
     // Static
      if (depth<StatixDepth)  and (RefEval>=beta+StatixMargin[depth]) and ((Board.Pieses[WhitePawn] and RanksBB[7])=0) and ((Board.Pieses[BlackPawn] and RanksBB[2])=0) then
        begin
          result:=RefEval-StatixMargin[depth];
          exit;
        end;

     // Null Move
      if (depth>FullPly) and (RefEval+NullMoveMargin>=beta) and ((depth>=NullBetaDepth) or (RefEval>=beta)) then
        begin
         R:=3;
         if depth>=NullExtraDepth then R:=R+(depth div 8);
         if RefEval-NullExtraMargin>=beta then R:=R+1;
         MakeNullMove(Board,Undo);
         value:=-SearchFull(Board,SortUnit,-beta,-alpha,depth-R*FullPly,ply+1,Line,false,movenone);
         UnMakeNullMove(Color,Board,Undo);
         if value>=beta then
           begin
            if value>=(mate-ply) then value:=beta;
            if  (((depth<6*FullPly) or  (SearchFull(Board,SortUnit,alpha,beta,depth-5*FullPly,ply,Line,false,movenone)>=beta)))  then
              begin
               HashStore(Board,ValueToTT(value,ply),depth,HashLower,movenone,game.Hashage,emove,StaticEval);
               Result:=value;
               exit;
              end;
           end else
           begin
             if value<(-Mate+FullPly*MaxPly) then Matethreat:=true;
             if Line.count<>0 then threatmove:=Line.Moves[1];
           end;
        end;
    END;
    
 // IID
 if (hashmove=movenone)  and (depth>=IIDDepth[pv]) and (emove=movenone) and (not Board.oncheck) and ( (pv) or (StaticEval>=beta-IIDMargin)) then
   begin
     if pv then newdepth:=depth-2*FullPly
           else newdepth:=depth div 2;
     value:=SearchFull(Board,SortUnit,alpha,beta,newdepth,ply,Line,false,movenone);
     if value>alpha then
       begin
         hashmove:=Line.Moves[1];
         hashdepth:=newdepth;
         if pv
           then hashvalue:=value
           else hashvalue:=beta;
         hashtyp:=hashlower;
       end;
   end;

   value:=-mate;
  // готовимся к перебору
  NodeInitNext(color,depth,Board,Checkinfo,Undo,MoveList,BadCapturesList,SortUnit,hashmove,ply);
  move:=Next(MoveList,BadCapturesList,Board,hashmove);
  while move<>MoveNone do
    begin
      if emove=move then goto l1;
      if Board.oncheck then pseudocheck:=moveislegal
                       else pseudocheck:=isPseudoLegal(color,move,CheckInfo,Board);
      if pseudocheck=moveisunlegal then goto l1;
      Piese:=Board.Pos[move and 63];
      Dest:=(move shr 6) and 63;
      isCheck:=isMoveCheck(color,move,CheckInfo,Board);
      ext:=ExtendMove(Board,MoveList,move,isDanger,isCheck,pv,mypieses);
      //Singular
      if (depth>=SEDepth[pv])  and (emove=movenone) and (move=hashmove) and (ext<FullPly)
          and (hashtyp in [hashlower,hashexact]) and (hashdepth>=(depth-3*FullPly)) and (abs(hashvalue)<(Mate-FullPly*MaxPly)) then
        begin
          newbeta:=hashvalue-SingularMargin;
          newdepth:=depth div 2;
          value:=SearchFull(Board,SortUnit,newbeta-1,newbeta,newdepth,ply,Line,false,hashmove);
          if value<newbeta then
           begin
            ext:=FullPly;
            isDanger:=true;
           end;
        end;
     newdepth:=depth+ext-FullPly;
     inc(MovesSearched);

      // Futility & LMR Prunning
     if  (not pv)   and (not Board.oncheck) and (move<>hashmove)  and (not Matethreat) and (not isDanger) and (move<>SortUnit.Killer[ply,1]) and (move<>SortUnit.Killer[ply,2])   then
       begin
         // LMR Prunning
        if (depth<LMRDepth) and (MovesSearched>LMRMovesCount[depth]) and (bestvalue>-mate+MaxPly*FullPly)  and (isPrune(Board,move,threatmove)) then
          begin
            if pseudocheck=hardmove then
              begin
                Makemove(color,move,Board,Undo);
                islegal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board));
                UnmakeMove(color,Board,Undo);
                if not isLegal then dec(MovesSearched);
              end;
            goto l1;
          end;
       // Futility
        preddepth:=newdepth;
        if (MovesSearched>LMRMoves[pv]) then preddepth:=preddepth-FullPly;
        if preddepth<0 then preddepth:=0;
        
       if (preddepth<StatixDepth)  then
         begin
           value:=StaticEval+RazorMargin[preddepth];
           if value<=alpha then
             begin
               if value>=BestValue then BestValue:=value;
               if pseudocheck=hardmove then
                 begin
                  Makemove(color,move,Board,Undo);
                  islegal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board));
                  UnmakeMove(color,Board,Undo);
                  if not isLegal then dec(MovesSearched);
                 end;
               goto l1;
             end;
         end;
       end;
      inc(OldMovesCount);
      BadmovesList.Moves[OldMovesCount]:=move;
      Makemove(color,move,Board,Undo);
      Board.oncheck:=ischeck;
      if pseudocheck=hardmove
       then islegal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board))
       else islegal:=true;
      if isLegal then
        begin
          if (MovesSearched=1) then
            begin
              value:=-SearchFull(Board,SortUnit,-beta,-alpha,newdepth,ply+1,Line,true,movenone);
            end else
            begin
              doresearch:=true;
              // LMR Reduction
              if (depth>=3*FullPly) and (not Board.oncheck) and (not isDanger) and (not Matethreat) and (MovesSearched>LMRMoves[pv]) and (move<>SortUnit.Killer[ply,1]) and (move<>SortUnit.Killer[ply,2]) then
                begin
                  value:=-SearchFull(Board,SortUnit,-alpha-1,-alpha,newdepth-FullPly,ply+1,Line,true,movenone);
                  doresearch:=(value>alpha);
                end;

              if doresearch then
                begin
                 value:=-SearchFull(Board,SortUnit,-alpha-1,-alpha,newdepth,ply+1,Line,true,movenone);
                 if (pv) and (value>alpha) and (value<beta) then value:=-SearchFull(Board,SortUnit,-beta,-alpha,newdepth,ply+1,Line,true,movenone);
                end;
            end;
          UnmakeMove(color,Board,Undo);
          if game.AbortSearch then break;
          if value>BestValue then
            begin
              BestValue:=Value;
              if Value>alpha then
                begin
                 Pvline.Moves[1]:=move;
                 for f:=1 to line.count do
                   PVline.Moves[f+1]:=line.Moves[f];
                 PVLine.count:=Line.count+1;
                 if value>=beta then
                   begin
                     BadMovesList.count:=OldMovesCount-1;
                     AddHistory(Board,SortUnit,move,ply,depth,piese,dest,BadMovesList);
                     HashStore(Board,ValueToTT(value,ply),depth,HashLower,move,game.Hashage,emove,StaticEval);
                     Result:=value;
                     exit;
                   end;
                 alpha:=Value;
                end;
            end;
        end else
        begin
          UnmakeMove(color,Board,Undo);
          dec(MovesSearched);
          dec(OldMovesCount);
        end;

l1:   move:=Next(MoveList,BadCapturesList,Board,hashmove);
    end;
 if (MovesSearched=0) and (not game.AbortSearch) then
  begin
   if (emove<>movenone) then result:=alpha else
   if Board.oncheck
      then result:=-mate+ply
      else result:=0;
   exit;
  end;
 if oldalpha=alpha then
    begin
     hashtyp:=HashUpper;
     hashmove:=movenone
    end   else
    begin
     hashtyp:=HashExact;
     hashmove:=PVLine.Moves[1];
    end;
 if (not game.AbortSearch)  then HashStore(Board,ValueToTT(Bestvalue,ply),depth,hashtyp,hashmove,game.HashAge,emove,StaticEval);
 Result:=BestValue;
end;

Function FV(var Board:TBoard;alpha:integer;beta:integer;depth:integer;ply:integer;var PVLine:TPVLine):integer;
Label l1;
Var
  MoveList:Tmovelist;
  CheckInfo : TCheckInfo;
  Undo : TUndo;
  pv,ischeck,islegal:boolean;
  color:Tcolor;
  Line:TPVLINE;
  pseudocheck,standpat,value,bestvalue,f,ext,hashindex,hashvalue,hashdepth,hashtyp,oldalpha : integer;
  move,hashmove:Tmove;
  mypieses,deltascore,newdepth:integer;
  temp:TBitBoard;
  target:Tpiese;
begin
 inc(game.NodesTotal) ;
 dec(game.remain);
 if game.remain<=0 then poll(game.AbortSearch);
 pvline.count:=0;
 pvline.Moves[1]:=0;
 oldalpha:=alpha;
 if (isDraw(Board)) or (ply>=MaxPly-1) or (game.AbortSearch) then
    begin
      Result:=0;
      exit;
    end;
  // Инициализация узла
  pv:=(beta-alpha)>1;
  color:=Board.Color;
  ext:=0;
  if color=white
     then temp:=Board.CPieses[white] and (not Board.Pieses[WhitePawn])
     else temp:=Board.CPieses[black] and (not Board.Pieses[BlackPawn]);
    mypieses:=BitCount(temp);
  // пробуем воспользоваться хешем
  hashindex:=HashProbe(Board,movenone);
  if (hashindex>=0)  then
    begin
      // Как минимум можно взять ход из хеша
      hashmove:=TT[hashindex].data1 and 65535;
      hashdepth:=(TT[hashindex].data2 shr 8) and 255;
      hashvalue:=(TT[hashindex].data1 shr 16) and 65535;
      hashvalue:=ValueFromTT(HashValue-HashValueMax,ply);
      hashtyp:=(TT[hashindex].data2 shr 5) and 7;
      if (not pv) and (depth<=hashdepth) then
        begin
          if (hashtyp=HashExact) or ((hashtyp=HashLower) and (hashvalue>=beta)) or ((hashtyp=HashUpper) and (hashvalue<=alpha)) then
            begin
              PVLine.count:=1;
              PVLine.Moves[1]:=hashmove;
              Result:=hashvalue;
              exit;
            end;
        end;
    end;

  // Статическая оценка позиции
  if Board.oncheck then standpat:=-Mate else
  if hashindex>=0 then
    begin
      standpat:=(TT[hashindex].data2 shr 16) and 65535;
      standpat:=standpat-HashValueMax;
    end else standpat:=Eval(Board);
  bestvalue:=standpat;
  if bestvalue>=beta then
    begin
      if hashindex<0 then HashStore(Board,ValueToTT(bestvalue,ply),0,HashLower,movenone,game.Hashage,movenone,standpat);
      Result:=bestvalue;
      exit;
    end;
  if BestValue>alpha then alpha:=BestValue;
  newdepth:=depth;
  if (not Board.oncheck) and (depth=-FullPly) and (standpat>=beta-QSExtraCheckMargin) then newdepth:=0;
  // готовимся к перебору
  NodeInitNextQS(color,newdepth,Board,Checkinfo,Undo,MoveList);
  if (Board.oncheck) and (MoveList.count=0) then
    begin
      Result:=-Mate+ply;
      exit;
    end;
  if (Board.oncheck) and (MoveList.count=1) then ext:=FullPly;
  deltascore:=standpat+DeltaMargin;
  move:=NextQS(MoveList);
  while (move<>MoveNone) and (beta>alpha) do
    begin
      if Board.oncheck then pseudocheck:=moveislegal
                       else pseudocheck:=isPseudoLegal(color,move,CheckInfo,Board);
      if pseudocheck=moveisunlegal then goto l1;
      isCheck:=isMoveCheck(color,move,CheckInfo,Board);
      if (mypieses>2) and (not pv) and (not Board.oncheck) and (not isCheck) and ((move and PromoteFlag)=0) and (not isPasser(Board,move)) then
        begin
          target:=Board.Pos[(move shr 6) and 63];
          value:=deltascore+PiesePrice[target];
          if (target=empty) and ((move and CaptureFlag)<>0) then value:=value+PawnValueEnd;
          if value<=alpha then
            begin
              if value>BestValue then BestValue:=value;
              goto l1;
            end;
        end;
      if (not pv) and (not Board.oncheck) and ((move and PromoteFlag)=0) and (isHanging(Board,move)) then goto l1;
      Makemove(color,move,Board,Undo);
      Board.oncheck:=ischeck;
      if pseudocheck=hardmove
       then islegal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board))
       else islegal:=true;
      if isLegal then
        begin
          value:=-FV(Board,-beta,-alpha,depth+ext-FullPly,ply+1,Line);
          UnmakeMove(color,Board,Undo);
          if value>BestValue then
            begin
              BestValue:=Value;
              if Value>alpha then
                begin
                 alpha:=Value;
                 //PV
                 Pvline.Moves[1]:=move;
                 for f:=1 to line.count do
                   PVline.Moves[f+1]:=line.Moves[f];
                 PVLine.count:=Line.count+1;
                end;
            end;
        end else UnmakeMove(color,Board,Undo);
l1:    move:=NextQS(MoveList);
    end;
  hashdepth:=0;
  if BestValue<=oldalpha then hashtyp:=HashUpper else
  if BestValue>=beta then hashtyp:=HashLower else Hashtyp:=HashExact;
  if (not game.AbortSearch)  then HashStore(Board,ValueToTT(Bestvalue,ply),hashdepth,hashtyp,PvLine.Moves[1],game.HashAge,movenone,Standpat);
  Result:=BestValue;
end;


Function isPasser(var Board:Tboard;move:Tmove):boolean;
var
  piese:Tpiese;
  dest:Tsquare;
  cp:integer;
begin
  piese:=Board.Pos[move and 63];
  dest:=(move shr 6) and 63;
  if Board.color=black then
    begin
      piese:=-piese;
      cp:=1
    end else cp:=-1;
  if (piese=WhitePawn) and ((Board.Pieses[cp*Whitepawn] and PawnPasserMaskBB[Board.Color,dest])=0)
    then result:=true
    else result:=false;
end;

Function isDraw(var Board:Tboard):boolean;
var
i:integer;
res:boolean;
begin
res:=false;
if Board.Rule50>100 then res:=true else
if (Board.Rule50=100) and (not Board.oncheck) then res:=true else
 begin
 i:=4;
 while i<=Board.Rule50 do
   begin
     if Board.Key=Board.Stack[Board.scount-i] then
      begin
       res:=true;
       break;
      end;
     i:=i+2;
   end;
 end;
 Result:=res;
end;

Procedure Think(var Board:Tboard;var SortUnit:TsortUnit;var PV:TPVLine);
label l1;
var
   value,newalpha,newbeta,old:integer;
   TimeEnd,timetot:Cardinal;
   i,iteration,nps:integer;
   s:string;
   RootList:TmoveList;
begin
 game.NodesTotal:=0;
 game.AbortSearch:=false;
 game.remain:=50000;
 ClearHistory(SortUnit);
 NewAge;
 PrepareRootList(Board,RootList);
 game.TimeStart:=GetTickcount;
 newalpha:=-mate;
 newbeta:=mate;
 value:=-mate;
 old:=-mate;
 game.oldtime:=game.time;
 for iteration:=1 to MaxPly do
   begin
   if Abs(old-value)>Aspiration
   then game.time:=game.rezerv
   else game.time:=game.OldTime;
   old:=value;
 l1:
    value:=SearchRoot(Board,SortUnit,newalpha,newbeta,(Iteration-1)*FullPly,RootList,PV,value);
    if game.AbortSearch then break;
    UpdRootList(RootList,pv.Moves[1]);
    TimeEnd:=GetTickcount;
    timetot:=timeend-game.timestart;
    if timetot=0 then nps:=0 else nps:=(game.NodesTotal div timetot)*1000;
    s:='info depth '+inttostr(iteration)+' time '+inttostr(timetot)+' nodes '+inttostr(game.NodesTotal)+' nps '+inttostr(nps);
    if value<-Mate+MaxPly*FullPly then s:=s+' score mate -'+inttostr(((value+mate) div 2)+1) else
    if value>Mate-MaxPly*FullPly  then s:=s+' score mate ' +inttostr((mate-value) div 2) else s:=s+' score cp '+inttostr(value);
    s:=s+' pv ';
    for i:=1 to Pv.count do
      s:=s+MoveToStr(Pv.Moves[i])+' ';
    if (iteration>9) or ((TimeTot>game.time*0.5)) then  Lwrite(s);
    if (TimeTot>game.time*0.6) and (game.time=game.OldTime) then Break;
   end;
  if (iteration>=MaxPly-1) and (game.time=24*3600*1000) and (game.rezerv=24*3600*1000) then WaitPonderhit;
end;

Procedure PrepareRootList(var Board:Tboard;var RootList:TmoveList);
var
   CheckInfo:TcheckInfo;
   i,pseudocheck: integer;
   islegal,isCheck:boolean;
   color:Tcolor;
   move :Tmove;
   t: TMoveList;
   Undo : Tundo;
begin
 RootList.count:=0;
 color:=Board.Color;
// Генерим список
 SetCheckInfo(Color,CheckInfo,Board);
 InitNodeUndo(Board,Undo);
 if Board.oncheck
    then  GenerateEscapes(Board,T,CheckInfo)
    else  GenerateAllPseudo(Board,T);
// Оцениваем
 for i:=1 to T.count do
    begin
      move:=t.Moves[i];
      if Board.oncheck then pseudocheck:=moveislegal
                       else pseudocheck:=isPseudoLegal(color,move,CheckInfo,Board);
      if pseudocheck=moveisunlegal then continue;
      isCheck:=isMoveCheck(color,move,CheckInfo,Board);
      Makemove(color,move,Board,Undo);
      Board.oncheck:=ischeck;
      if pseudocheck=hardmove
       then islegal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board))
       else islegal:=true;
      if isLegal then
        begin
          RootList.count:=RootList.count+1;
          RootList.Moves[RootList.count]:=T.Moves[i];
          RootList.Values[RootList.count]:=Eval(Board);
        end;
      UnMakeMove(color,Board,Undo);
    end;
end;
Procedure UpdRootList(var RootList:TmoveList;pvmove:Tmove);
var
  i:integer;
begin
  for i:=1 to RootList.count do
    if RootList.Moves[i]=pvmove then
      begin
        RootList.Values[i]:=2100000000;
        exit;
      end;
end;

Function ExtendMove(var Board:TBoard;var MoveList:TmoveList;move:Tmove;var dangermove:boolean;isCheck:boolean;pv:boolean;mypieses:integer):integer;
var
   res:integer;
   piese,target:Tpiese;
   dest:Tsquare;
begin
  dangermove:=false;
  res:=0;
  piese:=Board.Pos[move and 63];
  dest:=(move shr 6) and 63;
  target:=Board.Pos[dest];

  if ((move and CapPromoFlag)<>0) or (Board.oncheck) or (isCheck) then dangermove:=true;
  if (isCheck) and (not isHanging(Board,move) ) then res:=res+CheckExtension[pv];
  if (Board.oncheck) and (Movelist.count=1) then res:=res+OneRepExtension[pv];
  if (Piese=WhitePawn) then
    begin
      if Posy[dest]=7 then
       begin
        res:=res+PawnOn7Extension[pv];
        dangermove:=true;
       end;
      if ((PawnPasserMaskBB[white,dest] and Board.Pieses[BlackPawn])=0) then
       begin
        res:=res+PasserPushExtension[pv];
        dangermove:=true;
       end;
    end else
  if (Piese=BlackPawn) then
    begin
      if Posy[dest]=2 then
       begin
        res:=res+PawnOn7Extension[pv];
        dangermove:=true;
       end;
      if ((PawnPasserMaskBB[black,dest] and Board.Pieses[WhitePawn])=0) then
       begin
        res:=res+PasserPushExtension[pv];
        dangermove:=true;
       end;
    end;
  if ((move and CapPromoFlag)<>0)  then
    begin
      if ((move and PromoteFlag)=0) and (target<>WhitePawn) and (Target<>BlackPawn) and (Target<>Empty) and  (mypieses=1) then res:=res+EndgameExtension[pv];
      if (pv)  and ((Target<>Empty) or ((move and PromoteFlag)<>0))  and (target<>WhitePawn) and (Target<>BlackPawn) and (not isHanging(Board,move)) then res:=res+ExchangeExtension[pv];
    end;
  if res>FullPly then res:=FullPly;
  Result:=res; 
end;
Function isPrune(var Board:Tboard;move:Tmove;threatmove:tmove):boolean;
var
   mfrom,mto,tfrom,tto,ttarget,tpiese:Tsquare;
begin
  if (threatmove=movenone) then
    begin
      result:=true;
      exit;
    end;
  mfrom:=move and 63;
  mto:=(move shr 6) and 63;
  tfrom:=threatmove and 63;
  tto:=(threatmove shr 6) and 63;
  tpiese:=Board.Pos[tfrom];
  ttarget:=Board.Pos[tto];
  if (mfrom=tto)  then
    begin
      Result:=false;
      exit;
    end;
  if ((threatmove and CaptureFlag)<>0) and (SeeValues[tpiese]>=SeeValues[ttarget]) and (isMoveAttacks(Board,move,tto)) then
    begin
      Result:=false;
      exit;
    end;
  if ((InterSect[tfrom,tto] and OnlyR00[mto])<>0) and (not isHanging(Board,move)) then
    begin
      Result:=false;
      exit;
    end;
 Result:=true;
end;

end.
