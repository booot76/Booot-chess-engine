unit search;

interface
uses params,eval,next,make,attacks,history,hash,fors,root,bitboards,egtb,SysUtils,See;

Function MainSearch(color : integer;alpha:integer;beta:integer;ply:integer;depth:integer;cannull:boolean;pv:boolean):integer;
Function RootSearch(color : integer;depth:integer):integer;
Procedure CollectPV(ply:integer;move:integer);
Function TimeExpired:boolean;
Function Repetition(ply : integer):boolean;
Function isDrawrep:boolean;
Function isdanger(color:integer;piese:integer;dest:integer):boolean;
Function isPrune(move:integer;depth:integer):boolean;
implementation
uses think;
Function RootSearch(color : integer;depth:integer):integer;
label l1,l2;
const
    point=128;
var
    pvfound:boolean;
    opking,i,eval,egt,ext,alpha,beta,piese,dest: integer;
    oldnodes:int64;
begin
   pvfound:=false;
   if color=white then  opking:=tree[1].Bking
                  else  opking:=tree[1].Wking;
   alpha:=-Mate;
   beta:=Mate;
    oldnodes:=nodes;
    tree[1].bmove:=0;
    pvlen[1]:=1;
    For i:=point+1 to point+Moves[point] do
      begin
        piese:=(Moves[i] shr 16) and 15;
        dest:=(Moves[i] shr 8) and 255;
        ext:=0;
        if (piese=pawn) and ((Only[dest] and PawnExt)<>0) and (StaticEE(color,Moves[i])>=0) then ext:=1;
        MakeMove(color,Moves[i],1);
        if (UCImode) and (RootDepth>10) then LPrint('info currmove '+Decode[(Moves[i] and 255)]+Decode[(Moves[i] shr 8) and 255]+' currmovenumber '+inttostr(i-point));
        tree[2].onCheck:=isAttack(color,opking);
        if tree[2].onCheck then ext:=1;
        tree[1].cmove:=Moves[i];
        // Если на доске 4 фигуры и меньше, то пробуем воспользоваться эндшпильными таблицами:
         if (BitCount(AllPieses)<=4) and (canuseeg) then
           begin
             // Небольшая проверка: если KPKP эндшпиль и сейчас возможно взятие на проходе то не используем пробинг
           // связано с тем, что я построил этот эндшпиль без учета взятия на проходе и возможны ошибки при игре движка
             If (WhitePawns<>0) and (blackPawns<>0) and (tree[2].ennpass<>0) then
                begin
                  if (color=white) and ((WPattacks[tree[2].ennpass] and BlackPawns)<>0) then  goto l1;
                  if (color=black) and ((BPattacks[tree[2].ennpass] and WhitePawns)<>0) then  goto l1;
                end;
             inc(tbhits);
             egt:=EGTBProbe(color xor 1);
             // Если позиция нелегальная (в смысле нет такого эндшпиля в базе - оцениваем обычным образом)
             if egt=Illegal then goto l1;
             if (Moves[i] and captureflag)=0 then rootegtb:=true;
             // Проигранная  для нас позиция или ничья:
             if egt>Draw then
                 begin
                   eval:=-Mate+(egt shl 1);
                  // useegtb:=true;
                   goto l2;
                 end
                     else
              if egt=Draw then
                 begin
                  eval:=0;
                  goto l2;
                 end
                 else
             // Выигранная для нас позиция
                begin
                  useegtb:=true;
                  if egt=-EGTBMate
                    then eval:=Mate-1
                    else eval:=Mate+(egt*2-1);
                 goto l2;
                end;

           end;

 l1:
        if pvfound then
                       begin
                         eval:=-MainSearch(color xor 1,-alpha-1,-alpha,2,depth+ext-1,true,false);
                         if (eval>alpha) and (not AbortSearch) then
                            begin
                              // Изменился лучший ход. Устанавливаем флажок,запрещающий ранний выход из перебора на этой итерации
                              RootChanged:=true;
                              EasyExit:=false;
                              // надо добавить время чтобы закончить перебор изменившегося хода
                              if (canadd) and (not added) then
                                begin
                                  oldenginetime:=EngineTime;
                                  EngineTime:=rezerv;
                                  added:=true;
                                end;
                              eval:=-MainSearch(color xor 1,-beta,-alpha,2,depth+ext-1,true,true);
                            end;
                        end
                             else
                            begin
                             eval:=-MainSearch(color xor 1,-beta,-alpha,2,depth+ext-1,true,true);
                             if  (eval<RootEval-Aspiration) and (not AbortSearch) then
                               begin
                                 // Оценка в начале новой итерации рухнула. Надо добавить время, чтобы попытаться закончить итерацию и выбрать лучший ход из корня.
                               FailLowNow:=True;
                               EasyExit:=false;
                               if (canadd) and (not added) then
                                begin
                                  oldenginetime:=EngineTime;
                                  EngineTime:=rezerv;
                                  added:=true;
                                end;
                               end;
                            end;
 l2:
        UnMakeMove(color,Moves[i],1);
        pvfound:=true;
        Mtakes[i]:=nodes-oldnodes;
        oldnodes:=nodes;
        if (eval>alpha) and (not AbortSearch) then
            begin
              tree[1].bmove:=moves[i];
              pv[1,1]:=moves[i];
              CollectPV(1,moves[i]);
              alpha:=eval;
              if (depth>5) then PrintThinking(Rootdepth,eval,'e',false);
            end;
      end;
Result:=alpha;
end;

Function MainSearch(color : integer;alpha:integer;beta:integer;ply:integer;depth:integer;cannull:boolean;pv:boolean):integer;
// Основная функция перебора.
label l2,l1,m1;
var
   move,opking,legal,eval,hflag,extension,mymat,dest,piese,newdepth,bestvalue,mateval,threatsq:integer;
begin
   if depth<=0 then
    begin
      Result:=FV(color,alpha,beta,ply,true,-mate);
      exit;
    end;
   // Проверяем, не исчерпано ли наше время
 if (Remain<=0)
    then
           if TimeExpired then
                               AbortSearch:=true;
  if (ply>MaxPly-1) or (AbortSearch) then
     begin
       Result:=beta;
       exit;
     end;
  
  if Rule50[ply]>100 then
     begin
       Result:=0;
       exit;
     end
        else HashGame[rep+ply-1]:=tree[ply].HashKey;
  if Repetition(ply) then
     begin
       Result:=0;
       exit;
     end;
  if alpha>Mate-ply then
     begin
       Result:=alpha;
       exit;
     end;
  bestvalue:=-Mate;
  hflag:=UPPER;
  legal:=0;
  tree[ply].bmove:=0;
  if color=white then
      begin
        opking:=tree[ply].Bking;
        mymat:=tree[ply].Wmat;
      end
          else
      begin
        opking:=tree[ply].wking;
        mymat:=tree[ply].Bmat;
      end;
 tree[ply].Hashmove:=0;
 tree[ply].Hflag:=-1;
 Pvlen[ply]:=ply-1;
 eval:=HashProbe(color,depth,ply,alpha,beta);
 if   (not pv) and (eval<>HashNoFound)  then
   begin
     Result:=eval;
     exit;
   end;
 
   // EGTB Probing
   if canuseeg and (BitCount(AllPieses)<=4) then
     begin
       eval:=EGTBBitbaseProbe(color,ply);
       if eval<>BadIndex then
          begin
           inc(tbhits);
           if color=black then
                              eval:=-eval;
           Result:=eval;
           exit;
          end;
     end;
  mateval:=Evaluate(color,ply,alpha,beta,ply);
  threatsq:=-1;
// Null Move
  if (not tree[ply].onCheck) and (mymat>0)  and (not pv)
      and (CanNull) and (depth>1) and (mateval>=beta)
   then
     begin
           tree[ply+1].bmove:=0;
           MakeNullMove(ply);
           eval:=-MainSearch(color xor 1, -beta,-alpha,ply+1,depth-NullR-1,false,pv);
           if (eval>=beta)  then
            begin
              if (mymat<10) and (depth>5) then
               begin
                eval:=MainSearch(color,alpha,beta,ply,depth-5,false,pv);
                if eval>=beta then
                  begin
                   HashNullStore(color,depth,ply,eval);
                   Result:=eval;
                   exit;
                  end;
               end else
            begin
              if NullR+1>depth then depth:=NullR+1;
              HashNullStore(color,depth,ply,eval);
              Result:=eval;
              exit;
            end;  
            end;
          if (tree[ply+1].bmove and CaptureFlag)<>0 then threatsq:=(tree[ply+1].bmove shr 8) and 255;

   end else
   if (not pv) and (not tree[ply].onCheck) and (depth<4) and (mateval<=alpha) and (mymat>9)
       and ((WhitePawns and (Ranks[6] or Ranks[7]))=0) and ((BlackPawns and (Ranks[3] or Ranks[2]))=0) then
     begin
       if (depth<=1) and (mateval+Razor1<=alpha) then
         begin
           eval:=FV(color,alpha,beta,ply,true,mateval);
           if eval<=alpha then
            begin
             Result:=eval;
             exit;
            end;
         end;
       if (depth>1) and (mateval+Razor2<=alpha) then
         begin
           eval:=FV(color,alpha,beta,ply,true,mateval);
           if eval<=alpha then
             begin
               Result:=eval;
               exit;
             end;
         end;
     end;

  if (pv) and (tree[ply].Hashmove=0) and (depth>2) then
     begin
       if (depth-2)<=(depth div 2)
         then newdepth:=depth-2
         else newdepth:=depth div 2;
       eval:=MainSearch(color,alpha,beta,ply,newdepth,true,pv);
       if eval<=alpha then MainSearch(color,-Mate,beta,ply,newdepth,true,pv);
       tree[ply].Hashmove:=tree[ply].bmove;
     end;
  PVlen[ply+1]:=ply;
  tree[ply].bmove:=0;
  tree[ply].status:=Init;
  if depth>1  then inc(mateval,ExFutility)
              else inc(mateval,Futility);
// Генерируем первый ход

  if tree[ply].onCheck
     then
           begin
           move:=NextEscape(color,ply);
           if Takes[ply shl 7]=0 then begin
                                       dec(PVlen[ply+1]);
                                       Result:=-Mate+ply-1;
                                       exit;
                                      end;
           end
     else
           move:=NextMoveAll(color,ply);

 // Последовательно просматриваем ходы
  while move<>0 do
    begin
      extension:=0;
      dest:=(move shr 8) and 255;
      piese:=(move shr 16) and 15;
     if (pv) and (piese=pawn) and  ((Only[dest] and Pawnext)<>0) and (StaticEE(color,move)>=0) then extension:=1 else
     if (pv) and ((move and CaptureFlag)<>0) and ((tree[ply-1].cmove and CaptureFlag)<>0)  and (dest=((tree[ply-1].cmove shr 8) and 255))  and (StaticEE(color,move)>0) then extension:=1;
    if Makemove(color,move,ply) then
       begin
         inc(legal);
         tree[ply].cmove:=move;
         tree[ply+1].onCheck:=isAttack(color,opking);
         // Удлинняемся
         //1. Шах
         if (tree[ply+1].onCheck) then extension:=1 else
         //Единственный ход
         if (tree[ply].onCheck) and (takes[ply shl 7]=1) then extension:=1;
         newdepth:=depth-1+extension;
         if (extension=0)   and (not tree[ply].onCheck) and (not tree[ply+1].oncheck)
            and ((move and CapPromoFlag)=0)  and (not isdanger(color,piese,dest))
             then
                begin
                 if (not pv) and (depth<7) and ((move and 255)<>threatsq) and (legal>2+depth) and (isPrune(move,depth)) then
                   begin
                     eval:=bestvalue;
                     goto l2;
                   end;
                 if (not pv) and (depth<5)  then
                   begin
                       if  (mateval<=alpha) then
                          begin
                            eval:=mateval;
                            if eval>bestvalue then bestvalue:=eval;
                            goto l2;
                          end;
                   end;
                 if (extension=0)  and (depth>2) and (legal>4)  and (move<>killer[ply,1]) and (move<>killer[ply,2]) then
                   begin
                    if (not pv) then dec(newdepth) else
                    if (legal>10) then dec(newdepth);
                   end;
                end;


 m1:
                   if (not pv) or (legal=1) then
                          begin
                           eval:=-MainSearch(color xor 1,-beta,-alpha,ply+1,newdepth,true,pv);
                           if (newdepth+2=depth) and  (eval>alpha) then  eval:=-MainSearch(color xor 1,-beta,-alpha,ply+1,depth-1,true,pv);
                          end  else
                          begin
                            eval:=-MainSearch(color xor 1,-alpha-1,-alpha,ply+1,newdepth,true,false);
                            if (eval>alpha)  then
                             begin
                              if (newdepth+2=depth) then inc(newdepth);
                              eval:=-MainSearch(color xor 1,-beta,-alpha,ply+1,newdepth,true,true);
                             end;
                          end;


l2:      UnMakeMove(color,move,ply);
         if eval>bestvalue then
          begin
           bestvalue:=eval;
           tree[ply].bmove:=move;
          end;
         if eval>alpha then
            begin
              if eval>=beta then
                  begin
                    HashBetaStore(color,depth,ply,eval,move);
                    AddToHistory(color,move,ply,depth);
                    Result:=eval;
                    exit;
                  end;
              alpha:=eval;
              CollectPV(ply,move);
              hflag:=Exact;
            end;

         if tree[ply].onCheck
           then move:=NextEscape(color,ply)
           else move:=NextMoveAll(color,ply);

       end
          else
       begin
        UnMakeMove(color,move,ply);
        if tree[ply].onCheck
           then move:=NextEscape(color,ply)
           else move:=NextMoveAll(color,ply);
       end;
 end;
   if legal=0 then
                  begin
                    result:=0;
                    exit;
                  end;
if hflag=Exact
  then HashPVStore(color,depth,ply,bestvalue,tree[ply].bmove)
  else HashAlphaStore(color,depth,ply,bestvalue);

Result:=bestvalue;
end;

Procedure CollectPV(ply:integer;move:integer);
// Функция обновляет текущий основной вариант
var
   j:integer;
begin
pv[ply,ply]:=move;
for j := ply + 1 to pvlen[ply + 1] do
PV[ply, j] := PV[ply + 1, j];
pvlen[ply] := pvlen[ply + 1];
end;

Function TimeExpired:boolean;
// Проверяем: не закончилось ли у нас время?
var
   res:boolean;
begin
CurrTime:=now;
If (CurrTime-StartTime)*8640000>=EngineTime
   then res:=true
   else res:=false;
Remain:=RemainNodes;
Result:=res;
end;

Function Repetition(ply : integer):boolean;
var
  i,start:integer;
begin
  start:=rep+ply-1-Rule50[ply];
  i:=rep+ply-3;
  while i>=start do
    begin
     if tree[ply].HashKey=HashGame[i]
      then begin
            Result:=true;
            exit;
           end;
    i:=i-2;
    end;
Result:=false;
end;

Function isDrawrep:boolean;
var
   i,count: integer;
   res:boolean;
begin
  res:=false;
  count:=0;
  for i:=0 to Rule50[1]-1 do
   if tree[1].HashKey=HashGame[i] then inc(count);
   if count>=2 then res:=true;
Result:=res;
end;

Function isdanger(color:integer;piese:integer;dest:integer):boolean;
var
   res:boolean;
begin
res:=false;
if color=white then
  begin
   if (piese=pawn) and ((Wpassmask[dest] and BlackPawns)=0) then res:=true;
  end else
  begin
    if (piese=pawn) and ((Bpassmask[dest] and WhitePawns)=0) then res:=true;
  end;

Result:=res;
end;

Function isPrune(move:integer;depth:integer):boolean;
var
  piese,dest : integer;
  res : boolean;
begin
  res:=false;
  piese:=(move shr 16) and 15;
  dest:=(move shr 8) and 255;
  if depth*mGood[piese,dest]<mTotal[piese,dest]
    then res:=true;
  Result:=res;
end;
end.



