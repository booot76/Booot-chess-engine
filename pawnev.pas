unit pawnev;

interface
uses params,eval,bitboards,hash;
Const
WPSQ : Tsq =
     (
         0,  0,  0,  0,  0,  0,  0,  0,
        -10, -5,  0,  5,  5,  0, -5, -10,
        -10, -5,  0, 15, 15,  0, -5, -10,
        -10, -5,  0, 25, 25,  0, -5, -10,
        -10, -5,  0, 15, 15,  0, -5, -10,
        -10, -5,  0,  5,  5,  0, -5, -10,
        -10, -5,  0,  5,  5,  0, -5, -10,
         0,  0,  0,  0,  0,  0,  0,  0
      );

IsoMid=10;
IsoEnd=20;
DoubledMid=8;
DoubledEnd=16;
WeakMid=8;
WeakEnd=12;
OnOpen=12;
PasserBegin=20;
PasserDelta=80;
NotBlocked1=40;
NotBlocked2=10;
PasserMid:t8=(0,0,10,10,18,30,50,75,0);
PasserMul:t8=(0,0,0,0,10,30,45,64,0);
FreePasser=50;
Candidat:t8=(0,0,5,5,10,20,35,55,0);
CandidatEnd:t8=(0,0,10,10,20,40,70,110,0);
AttDist=10;
DefDist=30;
Unstoppable = 600;

Procedure PawnEval(ply:integer;var pscore:integer;var pend:integer;dir:integer);
Procedure PassPawnEval(color:integer;ply:integer);
implementation
uses safety,attacks;

Procedure PawnEval(ply:integer;var pscore:integer;var pend:integer;dir:integer);
label l1,l2;
const
    only32 :t8=(0,1,2,4,8,16,32,64,128);
var
   i,sq,x,y,att,def,indx: integer;
   tdata:smallint;
   Twdef,Tbdef:integer;
   temp: bitboard;
   backward,cand,pass :boolean;
begin
  // Пробуем взять инфу из хеша:
  indx:=tree[dir].PHash and PHashMask;
  if PTable[indx].key=tree[dir].PHash then
     begin
       pscore:=PTable[indx].pscore;
       pend:=PTable[indx].pend;
       wpassvector:=PTable[indx].wpassvector;
       bpassvector:=PTable[indx].bpassvector;
       twdef:=Ptable[indx].wdef;
       tbdef:=Ptable[indx].bdef;
       wdefk:=twdef and 255;
       wdefq:=(twdef shr 8) and 255;
       wdefe:=(twdef shr 16) and 255;
       wdefd:=(twdef shr 24) and 255;
       bdefk:=tbdef and 255;
       bdefq:=(tbdef shr 8) and 255;
       bdefe:=(tbdef shr 16) and 255;
       bdefd:=(tbdef shr 24) and 255;
       exit;
     end;

  pscore:=0;pend:=0;wpassvector:=0;bpassvector:=0;
 // Оцениваем пешки
  temp:=WhitePawns;
  while temp<>0 do
    begin
      pass:=false;
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
     // Централизацию пешек считаем только для миттельшпиля.
      pscore:=pscore+WPSQ[sq];
      // Ищем проходные:
      if ((WPassMask[sq] and BlackPawns)=0) then
        begin
          wpassvector:=wpassvector or Only32[x];
          pass:=true;
        end;
      if (IsoMask[sq] and WhitePawns)=0 then
         begin
          // Изолированная пешка
            pscore:=pscore-IsoMid;
            if (Wstopper[sq] and all)=0 then pscore:=pscore-OnOpen;
            pend:=pend-IsoEnd;
         end
            else
        begin
        // Проверяем пешку на отсталость
        if ((Wback[sq] and WhitePawns)=0)  then
           begin
           backward:=true;
           if ((Only[sq+8] and all)=0) then
            begin
             if ((Wback[sq+8] and WhitePawns)<>0) and ((WPAttacks[sq] and BlackPawns)=0) and ((WPAttacks[sq+8] and BlackPawns)=0) then backward:=false;
             if (y=2) and ((Only[sq+16] and all)=0) and((Wback[sq+16] and WhitePawns)<>0) and ((WPAttacks[sq] and BlackPawns)=0) and ((WPAttacks[sq+8] and BlackPawns)=0)and ((WPAttacks[sq+16] and BlackPawns)=0) then backward:=false;
            end;
           if (backward) then
              begin
                pscore:=pscore-WeakMid;
                if (Wstopper[sq] and all)=0 then pscore:=pscore-OnOpen;
                pend:=pend-WeakEnd;
              end;
           end;
       end;
      // Наказываем сдвоенные пешки:
      if ((wstopper[sq] and WhitePawns)<>0) then
        begin
          pscore:=pscore-DoubledMid;
          pend:=pend-DoubledEnd;
        end;

       if (not pass) and ((Wstopper[sq] and all)=0) then
        begin
          // Кандидат в проходные
         cand:=false;
         def:=BitCount(Bback[sq+8] and BlackPawns);
         att:=BitCount(Wback[sq] and WhitePawns);
         if att>=def then
           begin
             def:=BitCount(WPAttacks[sq] and BlackPawns);
             att:=BitCount(BPAttacks[sq] and WhitePawns);
             if att>=def then cand:=true;
           end;
         if cand then
          begin
           inc(pscore,Candidat[y]);
           inc(pend,CandidatEnd[y]);
          end;
        end;
      temp:=temp and NotOnly[sq];
    end;

 // Черные пешки

 temp:=BlackPawns;
  while temp<>0 do
    begin
      pass:=false;
      sq:=BitScanForward(temp);
      x:=Posx[sq];y:=posy[sq];
      pscore:=pscore-WPSQ[63-sq];
      // Ищем проходные:
      if ((BPassMask[sq] and WhitePawns)=0) then
        begin
          bpassvector:=bpassvector or Only32[x];
          pass:=true;
        end;
      if (IsoMask[sq] and BlackPawns)=0 then
         begin
          // Изолированная пешка
           pscore:=pscore+IsoMid;
           if (bstopper[sq] and all)=0 then pscore:=pscore+OnOpen;
           pend:=pend+IsoEnd;
         end
            else
        begin
        // Проверяем пешку на отсталость
        if ((Bback[sq] and BlackPawns)=0)  then
           begin
           backward:=true;
           if ((Only[sq-8] and all)=0) then
            begin
             if ((Bback[sq-8] and BlackPawns)<>0) and ((BPAttacks[sq] and WhitePawns)=0) and ((BPAttacks[sq-8] and WhitePawns)=0) then backward:=false;
             if (y=7) and ((Only[sq-16] and all)=0) and((Bback[sq-16] and BlackPawns)<>0) and ((BPAttacks[sq] and WhitePawns)=0) and ((BPAttacks[sq-8] and WhitePawns)=0)and ((BPAttacks[sq-16] and WhitePawns)=0) then backward:=false;
            end;
           if (backward)  then
              begin
                pscore:=pscore+WeakMid;
                if (Bstopper[sq] and all)=0 then pscore:=pscore+OnOpen;
                pend:=pend+WeakEnd;
              end;
           end;
      end;
      // Наказываем сдвоенные пешки:
      if ((Bstopper[sq] and BlackPawns)<>0)  then
        begin
           pscore:=pscore+DoubledMid;
           pend:=pend+DoubledEnd;
        end;
       if (not pass) and ((Bstopper[sq] and all)=0 )then
        begin
          // Кандидат в проходные
         cand:=false;
         def:=BitCount(Wback[sq-8] and WhitePawns);
         att:=BitCount(Bback[sq] and BlackPawns);
         if att>=def then
           begin
             def:=BitCount(BPAttacks[sq] and WhitePawns);
             att:=BitCount(WPAttacks[sq] and BlackPawns);
             if att>=def then cand:=true;
           end;
         if cand then
          begin
           dec(pscore,Candidat[9-y]);
           dec(pend,CandidatEnd[9-y]);
          end;
        end;
      temp:=temp and NotOnly[sq];
    end;
   wdefk:=WkingShelter(7,true)+WkingShelter(6,false)+WkingShelter(8,false);
   if wdefk>255 then wdefk:=255;
   wdefq:=WkingShelter(2,true)+WkingShelter(1,false)+WkingShelter(3,false);
   if wdefq>255 then wdefq:=255;
   wdefe:=WkingShelter(5,true)+WkingShelter(4,false)+WkingShelter(6,false);
   if wdefe>255 then wdefe:=255;
   wdefd:=WkingShelter(4,true)+WkingShelter(3,false)+WkingShelter(5,false);
   if wdefd>255 then wdefd:=255;
   bdefk:=BkingShelter(7,true)+BkingShelter(6,false)+BkingShelter(8,false);
   if bdefk>255 then bdefk:=255;
   bdefq:=BkingShelter(2,true)+BkingShelter(1,false)+BkingShelter(3,false);
   if bdefq>255 then bdefq:=255;
   bdefe:=BkingShelter(5,true)+BkingShelter(4,false)+BkingShelter(6,false);
   if bdefe>255 then bdefe:=255;
   bdefd:=BkingShelter(4,true)+BkingShelter(3,false)+BkingShelter(5,false);
   if bdefd>255 then bdefd:=255;
   // Записываем в хеш
   twdef:=wdefk or (wdefq shl 8) or (wdefe shl 16) or (wdefd shl 24);
   tbdef:=bdefk or (bdefq shl 8) or (bdefe shl 16) or (bdefd shl 24);
   PTable[indx].key:=tree[dir].PHash;
   Ptable[indx].wdef:=Twdef;
   Ptable[indx].bdef:=Tbdef;
   PTable[indx].wpassvector:=wpassvector;
   PTable[indx].bpassvector:=bpassvector;
   PTable[indx].pend:=pend;
   PTable[indx].pscore:=pscore;
end;

Procedure PassPawnEval(color:integer;ply:integer);
// Оценка проходных пешек
label l1,l2;
const
  mask : T8=(0,1,2,4,8,16,32,64,128);
var
  temp,sq1,sq,bonus,y,delta : integer;
begin
  temp:=wpassvector;
  while temp<>0 do
     begin
       sq1:=BitScanForward8(temp)+1;
       sq:=BitScanBackWard(WhitePawns and Files[sq1]);
       if (posy[sq]<2) or (posy[sq]>7) then goto l1;
       y:=posy[sq];
     // Оценка проходной для миттельшпиля:
       bonus:=PasserMid[y];
       inc(score,bonus);
    // Оценка проходной для эндшпиля:
       bonus:=PasserBegin;
       delta:=PasserDelta;
       if (wstopper[sq] and BlackPieses)=0 then delta:=delta+NotBlocked1;
       if (wstopper[sq] and WhitePieses)=0 then delta:=delta+NotBlocked2;
    // Если пешка вне квадрата одинокого короля противника
       if ((Wstopper[sq] and AllPieses)=0) and (not wKvadrat(color,sq,bking)) and (tree[ply].Bmat=0) then  delta:=delta+UnStoppable;
    // Если пешка свободно может двигаться дальше
       if (not ispasserBlocked(sq,white)) then delta:=delta+FreePasser;
       delta:=delta-AttDist*Dist[wking,sq+8];
       delta:=delta+DefDist*Dist[bking,sq+8];
    // В зависимости от продвинутости пешки вычисляем ее итоговую оценку.
       if delta>0 then bonus:=bonus+((delta*PasserMul[y]+32) div 64);
       scoreend:=scoreend+bonus;
l1:    temp:=temp and (not Mask[sq1]);
     end;
  temp:=bpassvector;
  while temp<>0 do
     begin
       sq1:=BitScanForward8(temp)+1;
       sq:=BitScanForWard(BlackPawns and Files[sq1]);
       if (posy[sq]<2) or (posy[sq]>7) then goto l2;
       y:=posy[sq];
       // Оценка проходной для миттельшпиля:
       bonus:=PasserMid[9-y];
       dec(score,bonus);
       // Оценка проходной для эндшпиля:
       bonus:=PasserBegin;
       delta:=PasserDelta;
       if (bstopper[sq] and WhitePieses)=0 then delta:=delta+NotBlocked1;
       if (bstopper[sq] and BlackPieses)=0 then delta:=delta+NotBlocked2;
       // Если пешка вне квадрата одинокого короля противника
       if ((Bstopper[sq] and AllPieses)=0) and (not bKvadrat(color,sq,wking)) and (tree[ply].Wmat=0) then  delta:=delta+UnStoppable;
       // Если пешка свободно может двигаться дальше
       if (not ispasserBlocked(sq,black)) then delta:=delta+FreePasser;
       
       delta:=delta-AttDist*Dist[bking,sq-8];
       delta:=delta+DefDist*Dist[wking,sq-8];
    // В зависимотси от продвинутости пешки вычисляем ее итоговую оценку.
       if delta>0 then bonus:=bonus+((delta*PasserMul[9-y]+32) div 64);
       scoreend:=scoreend-bonus;
 l2:   temp:=temp and (not Mask[sq1]);
     end;
end;

end.
