unit think;

interface
uses params,search,history,hash,root,SysUtils,bitboards;

Function Iterate:integer;
Procedure PrintThinking (Depth:byte;Value:integer;arg:string;kibitz:boolean);
implementation
Function Iterate:integer;
var
   depth,eval: integer;

begin
  GenerateRoot(SideToMove);
  if Moves[128]=0 then
      begin
        if tree[1].onCheck then
           begin
            if SideToMove=white
                   then LPrint('0-1 {Black Mates}')
                   else LPrint('1-0 {White Mates}');

           end
               else
           begin
             LPrint('1/2-1/2 {StaleMate}');
           end;
        Result:=0;
        exit;
      end;
  ClearHistory;
  StartTime:=now;
  nodes:=0;tbhits:=0;
  remain:=RemainNodes;
  AbortSearch:=false;
  MateInOne:=false;
  RootEval:=0;
  if Moves[128]=1
    then begin
           Result:=Moves[129];
           exit;
         end;
  rep:=Rule50[1];
  pvmove:=Moves[129];
  pv[1,1]:=pvmove;
  useegtb:=false;
  rootegtb:=false;
  FailLowPrev:=false;
  if not depthlimit then MaxDepth:=MaxPly;
  for depth:=3 to MaxDepth do
    begin
       if useegtb then  break;
       RootDepth:=depth;
       FailLowNow:=false;
       RootChanged:=false;
       eval:=RootSearch(SideToMove,depth);
       // Запоминаем лучший ход
       if tree[1].bmove<>0 then
        begin
         pvmove:=tree[1].bmove;
         RootEval:=eval;
        end;
       // Если фатально исчерпали время - выходим сразу
       If AbortSearch then break;
       
       if Eval=Mate-1 then
                           MateinOne:=true;
       // Если мат - выходим раньше
       if (depth>4) and (Abs(eval)>Mate-100) then break;
       FailLowPrev:=FailLowNow;
       FailLowNow:=false;
       // Снимаем флажок дополнительного расхода времени если оценка в этой итерации устаканилась (В предыдущей она рухнула и мы добавили время).
       if (not FailLowPrev) and (canadd) and (added) then
              begin
                added:=false;
                enginetime:=oldenginetime;
              end;

       PrintThinking(Rootdepth,eval,'e',false);
     // Для участия в ССТ пришлось добавить вывод информации для обдумывания.
 //    if (rootdepth>8) or ((now-StartTime)*8640000>EngineTime*0.5) then PrintThinking(Rootdepth,eval,'e',true);
       PutOnTop(pvmove);
     //  PvFill(Sidetomove,1);

       // Ранний выход из перебора
       if (depth>4) and (EasyExit) and ((now-StartTime)*8640000>(EngineTime div 6)) and (timer.TimeMode<>Exacttime) then break;
       if (depth>4) and (not FailLowPrev) and (not RootChanged) and ((now-StartTime)*8640000>(EngineTime div 2)) and (timer.TimeMode<>Exacttime) then break;
       if (rootegtb) and (depth>4) then break;
    end;
  Result:=pvmove;
  OldRootDepth:=rootdepth;
  PredictedMove:=pv[1,2];
end;
Procedure PrintThinking (Depth:byte;Value:integer;arg:string;kibitz:boolean);
// Процедура печатает текущую статистику по перебору
var
   msgs:string;
   i:byte;
   tim,mat:integer;
begin
if Postmode then
  begin
  CurrTime:=now;
  if value>Mate-100 then value:=value+67;
  if value<-Mate+100 then value:=value-67;
  tim:=trunc((CurrTime-StartTime)*8640000);
  if (tim<0) or (tim>1000000) then tim:=0;
 if XboardMode then
    begin
    msgs:=IntToStr(depth)+' '; // Глубина
    msgs:=msgs+inttostr(Value)+' ';// Оценка
    msgs:=msgs+inttostr(tim)+' '; // время
    msgs:=msgs+inttostr(nodes)+' ';// количество рассмотренных вариантов
    end
       else
    begin
     msgs:='info depth '+inttostr(depth)+' ';
     msgs:=msgs+'time '+inttostr(tim*10)+' ';
     msgs:=msgs+'nodes '+inttostr(nodes)+' ';
     if tim>25 then msgs:=msgs+'nps '+inttostr(trunc(nodes*100/tim))+' ';
     if (abs(value)>32000) then
        begin
          if value>0 then mat:=trunc(((32767-value)+1)/2)
                     else mat:=-trunc((value+32767)/2);
         msgs:=msgs+'score mate '+inttostr(mat)+' ';            
        end
           else
               begin
               msgs:=msgs+'score cp '+inttostr(value)+' ';
               if arg='l' then msgs:=msgs+'upperbound ' else
               if arg='h' then msgs:=msgs+'lowerbound ';
               end;
     if tbhits>0 then
     msgs:=msgs+'tbhits '+inttostr(tbhits)+' ';
     msgs:=msgs+'pv ';
    end;

    for i:=1 to pvlen[1] do
     begin
       msgs:=msgs+Decode[(pv[1,i] and 255)]+Decode[(pv[1,i] shr 8) and 255]; // PV
       if ((pv[1,i] shr 24) and 15) <>0 then
          begin
            case ((pv[1,i] shr 24) and 15) of
              queen : msgs:=msgs+'q ';
              knight : msgs:=msgs+'n ';
              rook : msgs:=msgs+'r ';
              bishop : msgs:=msgs+'b ';
              end;
          end
             else msgs:=msgs+' ';
         end;
     end;
    LPrint(msgs);
    if kibitz then Lprint ('tellics kibitz '+msgs);

end;


end.




