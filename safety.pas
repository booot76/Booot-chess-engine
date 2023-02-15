unit safety;

interface
uses params,eval,bitboards;

Const
WKBSQ : Tsq =
     (
         -10,  0,-20,-35,-35,-20,  0,-10,
         -15,-10,-30,-40,-40,-30,-10,-15,
         -30,-30,-40,-60,-60,-40,-30,-30,
         -70,-70,-70,-70,-70,-70,-70,-70,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80,
         -80,-80,-80,-80,-80,-80,-80,-80
     );

  WKESQ : Tsq =
     (
        -60,-40,-30,-20,-20,-30,-40,-60,
        -40,-20,-10,  0,  0,-10,-20,-40,
        -30,-10,  0, 10, 10,  0,-10,-30,
        -20,  0, 10, 20, 20, 10,  0,-20,
        -20,  0, 10, 20, 20, 10,  0,-20,
        -30,-10,  0, 10, 10,  0,-10,-30,
        -40,-20,-10,  0,  0,-10,-20,-40,
        -60,-40,-30,-20,-20,-30,-40,-60
     );
  WKKSQ : Tsq =
     (
        -60,-40,-20,-20,-20,-20,-20,-20,
        -60,-40,-20,  0,  0,  0,  0,  0,
        -60,-40,-20, 20, 20, 20, 20, 20,
        -60,-40,-20, 20, 40, 40, 40, 30,
        -60,-40,-20, 20, 60, 60, 60, 30,
        -60,-40,-20, 20, 60, 60, 60, 30,
        -60,-40,-20, 20, 40, 40, 40, 30,
        -60,-40,-20,-20,-20,-20,-20,-20
     );
  WKQSQ : Tsq =
     (
        -20,-20,-20,-20,-20,-20,-40,-60,
          0,  0,  0,  0,  0,-20,-40,-60,
         20, 20, 20, 20, 20,-20,-40,-60,
         30, 40, 40, 40, 20,-20,-40,-60,
         30, 60, 60, 60, 20,-20,-40,-60,
         30, 60, 60, 60, 20,-20,-40,-60,
         30, 40, 40, 40, 20,-20,-40,-60,
        -20,-20,-20,-20,-20,-20,-40,-60
     );

KSafety :T16=(0,0,128,192,224,240,248,252,254,255,256,256,256,256,256,256,256);
Ktropism=20;
Storm:t8=(0,0,0,0,8,20,30,25,0);
OpenKing=40;
Shelter:t8=(0,0,0,10,22,28,34,38,0);
Procedure EvaluateKings(ply:integer);
Procedure WKingSafety(ply:integer);
Procedure BKingSafety(ply:integer);
Function WKingShelter(x : integer;dub:boolean):integer;
Function BKingShelter(x : integer;dub:boolean):integer;
implementation


Procedure EvaluateKings(ply:integer);
//  оцениваем королей
begin
  wendgame:=true;
  bendgame:=true;

  if (BlackQueens<>0) and (tree[ply].Bmat>9) then wendgame:=false;
  if (WhiteQueens<>0) and (tree[ply].wmat>9) then bendgame:=false;

  if ((all and abc)=0) and ((all and fgh)<>0) then
     begin
       scoreend:=scoreend+WKKSQ[wking];
       scoreend:=scoreend-WKQSQ[63-bking];
     end else
  if ((all and abc)<>0) and ((all and fgh)=0) then
     begin
       scoreend:=scoreend+WKQSQ[wking];
       scoreend:=scoreend-WKKSQ[63-bking];
     end else
     begin
       scoreend:=scoreend+WKESQ[wking];
       scoreend:=scoreend-WKESQ[63-bking];
     end;
   score:=score+WKBSQ[wking]-WKBSQ[63-bking];    
   // Если не эндшпиль то запускаем определение безопасности короля
   wkingzone:=kingsMove[wking] or Only[wking];
   bkingzone:=kingsMove[bking] or Only[bking];
   if (not wendgame) then WKingSafety(ply);
   if (not bendgame) then BKingSafety(ply);
 // Оцениваем позицию, если король потерял рокировку и запер свою ладью:
   if (wking<a2) and (wking<>e1) and (wking<>d1) then
        if (wrooktrap[wking-e1] and WhiteRooks)<>0 then score:=score-RookTrap;
   if (bking>h7) and (bking<>e8) and (bking<>d8) then
        if (brooktrap[bking-e8] and BlackRooks)<>0 then score:=score+RookTrap;
 // Слабость последней горизонтали
 if (WQR<>0) and (posy[bking]=8)  and
      ((KingsMove[bking] and BlackPawns and Ranks[7])=(KingsMove[bking] and Ranks[7]))
        then score:=score+WeakBackRank;
 if (BQR<>0) and (posy[wking]=1)  and
      ((KingsMove[wking] and WhitePawns and Ranks[2])=(KingsMove[wking] and Ranks[2]))
        then score:=score-WeakBackRank;
 
end;

Procedure WKingSafety(ply:integer);
var
  x,min,now,will,penalty:integer;
begin
 x:=Posx[wking];
 if (x>5) then penalty:=wdefk else
 if (x<4) then penalty:=wdefq else
 if (x=4) then penalty:=wdefd else
   begin
     now:=wdefe;
     min:=now;
     if (tree[ply].Castle and 1)<>0 then
      begin
        will:=wdefk;
        if will<min then min:=will;
      end;
     if (tree[ply].Castle and 2)<>0 then
      begin
        will:=wdefq;
        if will<min then min:=will;
      end;
     penalty:=(now+min) div 2;
   end;
  score:=score-penalty;
end;

Procedure BKingSafety(ply:integer);
var
  x,min,now,penalty,will:integer;
begin
 x:=Posx[bking];
 if (x>5) then penalty:=bdefk else
 if (x<4) then penalty:=bdefq else
 if (x=4) then penalty:=bdefd else
   begin
     now:=bdefe;
     min:=now;
     if (tree[ply].Castle and 4)<>0 then
      begin
        will:=bdefk;
        if will<min then min:=will;
      end;
     if (tree[ply].Castle and 8)<>0 then
      begin
        will:=bdefq;
        if will<min then min:=will;
      end;
     penalty:=(now+min) div 2;
   end;
  score:=score+penalty;
end;

Function WKingShelter(x : integer;dub:boolean):integer;
var
   res,y:integer;
begin
res:=0;
if (Files[x] and WhitePawns)=0 then inc(res,Openking) else
 begin
   y:=Posy[BitScanForward(WhitePawns and Files[x])];
   inc(res,shelter[y]);
 end;
if dub then res:=res+res;
if  ((Files[x] and BlackPawns)<>0) then
   begin
     y:=Posy[BitScanForWard(Files[x] and BlackPawns)];
     inc(res,Storm[9-y]);
   end;
Result:=res;
end;

Function BKingShelter(x : integer;dub:boolean):integer;
var
   res,y:integer;
begin
res:=0;
if (Files[x] and BlackPawns)=0 then inc(res,Openking) else
 begin
   y:=Posy[BitScanBackward(BlackPawns and Files[x])];
   inc(res,shelter[9-y]);
 end;
if dub then res:=res+res;
if  ((Files[x] and WhitePawns)<>0) then 
   begin
     y:=Posy[BitScanBackWard(Files[x] and WhitePawns)];
     inc(res,storm[y]);
   end;
Result:=res;
end;
end.
