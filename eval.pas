unit eval;

interface
uses params,bitboards,attacks,escape,egtb,see,sysutils;
type
    Tsq = array[0..63] of integer;
    tsq1=array[0..127] of integer;
    T4 = array[0..4] of integer;
    T8 = array[0..8] of integer;
    t16 = array[0..16] of integer;
    T31 = array[0..50] of integer;
Const
    WNSQ : Tsq =
     (
      -50,-40,-30,-25,-25,-30,-40,-50,
      -35,-25,-15, -5, -5,-15,-25,-35,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -10,  0, 10, 15, 15, 10,  0,-10,
       -5,  5, 15, 20, 20, 15,  5, -5,
       -5,  5, 15, 20, 20, 15,  5, -5,
      -20,-10,  0,  5,  5,  0,-10,-20,
     -120,-25,-15,-10,-10,-15,-25,-120
     );
     WNESQ : Tsq =
     (
      -40,-30,-20,-15,-15,-20,-30,-40,
      -30,-20,-10, -5, -5,-10,-20,-30,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -15, -5,  5, 10, 10,  5, -5,-15,
      -15, -5,  5, 10, 10,  5, -5,-15,
      -20,-10,  0,  5,  5,  0,-10,-20,
      -30,-20,-10, -5, -5,-10,-20,-30,
      -40,-30,-20,-15,-15,-20,-30,-40
     );

     WBSQ : Tsq =
     (
        -15,-15,-12,-10,-10,-12,-15,-15,
        -10,  0, -2,  0,  0, -2,  0,-10,
         -8, -2,  4,  2,  2,  4, -2, -8,
         -4,  0,  2,  8,  8,  2,  0, -4,
         -4,  0,  2,  8,  8,  2,  0, -4,
         -8, -2,  4,  2,  2,  4, -2, -8,
        -10,  0, -2,  0,  0, -2,  0,-10,
         -8, -8, -6, -5, -5, -6, -8, -8
     );
    WBESQ : Tsq =
     (
        -18,-12, -9, -6, -6, -9,-12,-18,
        -12, -6, -3,  0,  0, -3, -6,-12,
         -9, -3,  0,  3,  3,  0, -3, -9,
         -6,  0,  3,  6,  6,  3,  0, -6,
         -6,  0,  3,  6,  6,  3,  0, -6,
         -9, -3,  0,  3,  3,  0, -3, -9,
        -12, -6, -3,  0,  0, -3, -6,-12,
        -18,-12, -9, -6, -6, -9,-12,-18
     );
     WRSQ : Tsq =
     (
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6,
       -6,-3, 0, 3, 3, 0,-3,-6
     );

     WQSQ : Tsq =
     (
       -7,-5,-5,-5,-5,-5,-5,-7,
       -5, 0, 0, 0, 0, 0, 0,-5,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
     );
     WQESQ : Tsq =
     (
        -24,-16,-12, -8, -8,-12,-16,-24,
        -16, -8, -4,  0,  0, -4, -8,-16,
        -12, -4,  0,  4,  4,  0, -4,-12,
         -8,  0,  4,  8,  8,  4,  0, -8,
         -8,  0,  4,  8,  8,  4,  0, -8,
        -12, -4,  0,  4,  4,  0, -4,-12,
        -16, -8, -4,  0,  0, -4, -8,-16,
        -24,-16,-12, -8, -8,-12,-16,-24
     );

    BN_light:TSQ=
             (  20, 30, 40, 50, 60, 70, 80,100,   //1
                30, 20, 30, 40, 50, 60, 70, 80,   //2
                40, 30, 20, 30, 40, 50, 60, 70,   //3
                50, 40, 30, 20, 30, 40, 50, 60,   //4
                60, 50, 40, 30, 20, 30, 40, 50,   //5
                70, 60, 50, 40, 30, 20, 30, 40,   //6
                80, 70, 60, 50, 40, 30, 20, 30,   //7
               100, 80, 70, 60, 50, 40, 30, 20);  //8
    BN_dark:TSQ=
             ( 100, 80, 70, 60, 50, 40, 30, 20,   //1
                80, 70, 60, 50, 40, 30, 20, 30,   //2
                70, 60, 50, 40, 30, 20, 30, 40,   //3
                60, 50, 40, 30, 20, 30, 40, 50,   //4
                50, 40, 30, 20, 30, 40, 50, 60,   //5
                40, 30, 20, 30, 40, 50, 60, 70,   //6
                30, 20, 30, 40, 50, 60, 70, 80,   //7
                20, 30, 40, 50, 60, 70, 80,100);  //8
    KMATE:TSQ=
              (
                0,5,10,15,15,10,5,0,
                5,10,15,20,20,15,10,5,
                10,15,20,25,25,20,15,10,
                15,20,25,30,30,25,20,15,
                15,20,25,30,30,25,20,15,
                10,15,20,25,25,20,15,10,
                5,10,15,20,20,15,10,5,
                0,5,10,15,15,10,5,0
              );
    WOUTPOST:TSQ=
              (
                0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,
                0,0,4, 8, 8,4,0,0,
                0,0,8,16,16,8,0,0,
                0,0,8,16,16,8,0,0,
                0,0,0, 0, 0,0,0,0,
                0,0,0,0,0,0,0,0
              );
    BlockedCentralPawn=35;
    WinKPK=450;
    KingKing=10;
    BishopTrap=175;
    RookTrap=65;
    QueenEarly=25;
    BishopPairMid=35;
    BishopPairEnd=50;
    BadBishopMid=2;
    BadBishopEnd=5;
    OpenLine=20;
    HalfLine=10;
    RookOpenKing=20;
    RookHalfKing=10;
    RookOn7Mid=20;
    RookOn7End=40;
    QueenOn7Mid=15;
    QueenOn7End=30;
    WeakBackRank=8;
    Nmob=4;
    Bmob=5;
    Rmob=2; Rmobend=4;
    Qmob=1; Qmobend=1;
    BadKnight=20;
var
   score,scoreend,wking,bking,wmul,bmul : integer;
   wpassvector,bpassvector:integer;
   wendgame,bendgame: boolean;
   drawres:integer;
   all,wkingzone,bkingzone : int64;
   wdefk,wdefq,wdefe,wdefd,bdefk,bdefq,bdefe,bdefd:integer;
Function Evaluate(color : integer;ply:integer;alpha:integer;beta:integer;dir : integer):integer;
Function WKvadrat(color:integer;pawn :integer;king:integer):boolean;
Function BKvadrat(color:integer;pawn :integer;king:integer):boolean;
Procedure CheckDraw(color : integer;ply:integer);
Procedure EvalMate(color:integer;ply:integer);
Function ispasserBlocked(pawnsq:integer;color:integer):boolean;
Function IsDrawKPKR(color:integer):boolean;
Function IsDrawKRKP(color:integer):boolean;
implementation
uses pawnev,safety;

Function Evaluate(color : integer;ply:integer;alpha:integer;beta:integer;dir : integer):integer;
var
sq:integer;
temp : int64;
pawn,pscore,pend: integer;
indx,ind,wpawns,bpawns,wt,bt,wp,bp,mul,sceval : integer;
line,wbish,mul1,mul2,bbish:integer;
bish,WPA,BPA : int64;

begin
  // Перед оценкой позиции проверяем: нет ли на доске уже битой ничьей?
  wmul:=64;
  bmul:=64;
  wt:=0;
  bt:=0;
  wp:=0;
  bp:=0;
  wking:=tree[ply].Wking;
  bking:=tree[ply].Bking;
  all:=WhitePawns or BlackPawns;
  wpawns:=BitCount(WhitePawns);
  bpawns:=BitCount(BlackPawns);
  score:=tree[ply].MatEval;
  scoreend:=tree[ply].MatEval;
  if color=white
     then begin
            inc(scoreend,10);
            inc(score,20)
          end
     else begin
            dec(scoreend,10);
            dec(score,20);
          end;
  if (tree[ply].Wmat<13) or (tree[ply].Bmat<13) then CheckDraw(color,ply);
  // После оценки материала нужно выяснить : оценивать позицию позиционно или (если на доске нет пешек) - до мата.
  if (WhitePawns or BlackPawns)=0 then
     begin
       EvalMate(color,ply);
       if color=black then score:=-score;
       Result:=score;
       exit;
     end;
  // Здесь мы начинаем оценивать позиционную оценку
  // В начале оцениваем пешки

  PawnEval(ply,pscore,pend,dir);
  inc(scoreend,pend);
  inc(score,pscore);
   EvaluateKings(ply);
  if (wpassvector or bpassvector)<>0 then  PassPawnEval(color,ply);
  if (tree[ply].Wmat=0) and (tree[ply].Bmat=0) then scoreend:=scoreend*2;

 // Проверяем: не заперт ли слон на h7?
    if (WhiteBishops and wbishtrap)<>0 then
       begin
         if ((WhiteBishops and Only[a7])<>0) and ((BlackPawns and Only[b6])<>0) then
          begin
           score:=score-BishopTrap;
           scoreend:=scoreend-BishopTrap;
          end;
         if ((WhiteBishops and Only[b8])<>0) and ((BlackPawns and Only[c7])<>0) then
          begin
           score:=score-BishopTrap;
           scoreend:=scoreend-BishopTrap;
          end;
         if ((WhiteBishops and Only[h7])<>0) and ((BlackPawns and Only[g6])<>0) then
           begin
             score:=score-BishopTrap;
             scoreend:=scoreend-BishopTrap;
           end;
         if ((WhiteBishops and Only[g8])<>0) and ((BlackPawns and Only[f7])<>0) then
           begin
             score:=score-BishopTrap;
             scoreend:=scoreend-BishopTrap;
           end;
       end;
    if (BlackBishops and bbishtrap)<>0 then
       begin
         if ((BlackBishops and Only[a2])<>0) and ((WhitePawns and Only[b3])<>0) then
           begin
             score:=score+BishopTrap;
             scoreend:=scoreend+BishopTrap;
           end;
         if ((BlackBishops and Only[b1])<>0) and ((WhitePawns and Only[c2])<>0) then
           begin
             score:=score+BishopTrap;
             scoreend:=scoreend+BishopTrap;
           end;
         if ((BlackBishops and Only[h2])<>0) and ((WhitePawns and Only[g3])<>0) then
           begin
             score:=score+BishopTrap;
             scoreend:=scoreend+BishopTrap;
           end;
         if ((BlackBishops and Only[g1])<>0) and ((WhitePawns and Only[f2])<>0) then
           begin
             score:=score+BishopTrap;
             scoreend:=scoreend+BishopTrap;
           end;
       end;

 // Если блокированы пешки e2 d2
  if ((Only[e2] and WhitePawns)<>0) and ((Only[e3] and AllPieses)<>0) and ((Only[f1] and WhiteBishops)<>0) then score:=score-BlockedCentralPawn;
  if ((Only[d2] and WhitePawns)<>0) and ((Only[d3] and AllPieses)<>0) and ((Only[c1] and WhiteBishops)<>0) then score:=score-BlockedCentralPawn;
  // Если блокированы пешки e7 d7
  if ((Only[e7] and BlackPawns)<>0) and ((Only[e6] and AllPieses)<>0) and ((Only[f8] and BlackBishops)<>0) then score:=score+BlockedCentralPawn;
  if ((Only[d7] and BlackPawns)<>0) and ((Only[d6] and AllPieses)<>0) and ((Only[c8] and BlackBishops)<>0)then score:=score+BlockedCentralPawn;
  mul:=BitCount(WhiteQueens or BlackQueens)*4+BitCount(WhiteRooks or BlackRooks)*2+BitCount(WhiteKnights or WhiteBishops or BlackKnights or BlackBishops);
   if mul>24 then mul:=24;
   sceval:=((scoreend*(24-mul))+(score*mul)) div 24;
   // Пробуем воспользоваться LazyExit
 if (beta-alpha=1) and (tree[ply].Wmat>12) and (tree[ply].Bmat>12) then
 begin
 if color=white then
    begin
      if ((sceval+LazyExit<=alpha) or (sceval-LazyExit>=beta))
        then begin
               Result:=sceval;
               exit;
             end;
    end
       else
    begin
    if ((-sceval+LazyExit<=alpha) or (-sceval-LazyExit>=beta))
        then begin
               Result:=-sceval;
               exit;
             end;
    end;
 end;

  wpa:=((WhitePawns and noafile) shl 7) or ((WhitePawns and nohfile) shl 9);
  bpa:=((BlackPawns and noafile) shr 9) or ((BlackPawns and nohfile) shr 7);

  // Оценка коней включает оценку форпостов, централизованность и угрозу неприятельскому королю
  temp:=WhiteKnights;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score+WNSQ[sq];
      scoreend:=scoreend+WNESQ[sq];
      bish:=KnightsMove[sq] and (not WhitePawns);
      ind:=BitCount(bish and (not bpa));
      score:=score+Nmob*ind;
      scoreend:=scoreend+Nmob*ind;
      if ((bish and bkingzone)<>0) or (dist[sq,bking]<4) then
        begin
          wt:=wt+1;
          inc(wp);
        end;
      if ((bpassvector and 7)<>0) and ((bpassvector and 224)<>0) then scoreend:=scoreend-BadKnight;
    if (BPAttacks[sq] and WhitePawns)<>0 then score:=score+Woutpost[sq]*BitCount(BPAttacks[sq] and WhitePawns);
      temp:=temp and NotOnly[sq];
    end;
  temp:=BlackKnights;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score-WNSQ[63-sq];
      scoreend:=scoreend-WNESQ[63-sq];
      bish:=KnightsMove[sq] and (not BlackPawns);
      ind:=BitCount(bish and (not wpa));
      score:=score-Nmob*ind;
      scoreend:=scoreend-Nmob*ind;
      if ((bish and wkingzone)<>0) or (dist[sq,wking]<4) then
        begin
          bt:=bt+1;
          inc(bp);
        end;
      if ((wpassvector and 7)<>0) and ((wpassvector and 224)<>0) then scoreend:=scoreend+BadKnight;
    if (WPAttacks[sq] and BlackPawns)<>0 then score:=score-Woutpost[63-sq]*BitCount(WPAttacks[sq] and BlackPawns);
      temp:=temp and NotOnly[sq];
    end;
 // Оценка слонов включает в себя подвижность,угрозу неприятельскому королю,наличие двух слонов,
 // наличие собственных пешек на полях цвета слона, а так же наличие фианкеттированного слона перед королем.
   wbish:=0;
  temp:=WhiteBishops;
  while temp<>0 do
    begin
      inc(wbish);
      sq:=BitScanForward(temp);
      score:=score+WBSQ[sq];
      scoreend:=scoreend+WBESQ[sq];
      bish:=BishopsMove(sq) and (not WhitePawns);
      ind:=BitCount(bish);
      score:=score+Bmob*ind;
      scoreend:=scoreend+Bmob*ind;
      if ((bish and bkingzone)<>0) or (dist[sq,bking]<4) then
        begin
          wt:=wt+1;
          inc(wp);
        end;
      temp:=temp and NotOnly[sq];
    end;

   bbish:=0;
  temp:=BlackBishops;
  while temp<>0 do
    begin
      inc(bbish);
      sq:=BitScanForward(temp);
      score:=score-WBSQ[63-sq];
      scoreend:=scoreend-WBESQ[63-sq];
      bish:=BishopsMove(sq) and (not BlackPawns);
      ind:=BitCount(bish);
      score:=score-Bmob*ind;
      scoreend:=scoreend-Bmob*ind;
      if ((bish and wkingzone)<>0) or (dist[sq,wking]<4) then
        begin
          bt:=bt+1;
          inc(bp);
        end;
      temp:=temp and NotOnly[sq];
    end;

  if (wbish=2)   then
                     begin
                      score:=score+BishopPairMid;
                      scoreend:=scoreend+BishopPairEnd;
                     end
                 else
  if (wbish=1)   then
     begin
       if ((WhiteBishops and dark)<>0)
         then
           begin
             scoreend:=scoreend-BitCount(WhitePawns and dark)*BadBishopEnd;
             score:=score-BitCount(WhitePawns and dark)*BadBishopMid
           end
         else
           begin
             scoreend:=scoreend-BitCount(WhitePawns and light)*BadBishopEnd;
             score:=score-BitCount(WhitePawns and light)*BadBishopMid
           end;
     end;

  if (bbish=2)   then
                   begin
                    score:=score-BishopPairMid;
                    scoreend:=scoreend-BishopPairEnd;
                   end
                 else
  if (bbish=1)   then
     begin
       if ((BlackBishops and dark)<>0)
         then
          begin
             scoreend:=scoreend+BitCount(BlackPawns and dark)*BadBishopEnd;
             score:=score+BitCount(BlackPawns and dark)*BadBishopMid;
          end
         else
         begin
             scoreend:=scoreend+BitCount(BlackPawns and light)*BadBishopEnd ;
             score:=score+BitCount(BlackPawns and light)*BadBishopMid
         end ;
     end;


  temp:=WhiteRooks;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score+WRSQ[sq];
      line:=posx[sq];
      bish:=RooksMove(sq) and (not (WhitePawns or WhiteKnights or WhiteBishops));
      ind:=BitCount(bish);
      score:=score+Rmob*ind;
      scoreEnd:=scoreEnd+RmobEnd*ind;
      if ((bish and bkingzone)<>0) or (dist[sq,bking]<4) then
        begin
          wt:=wt+2;
          inc(wp);
        end;
      if (not bendgame) and ((wstopper[sq] and WhitePawns)=0) and ((wstopper[sq] and bkingzone)<>0) then
        begin
          score:=score+RookHalfKing;
          if (posx[bking]=line) then score:=score+RookOpenKing;
        end;
      if (Files[line] and all)=0 then
              begin
                score:=score+OpenLine;
                scoreend:=scoreend+OpenLine;
              end
             else
          if (Files[line] and whitePawns)=0 then
              begin
                score:=score+HalfLine;
                scoreend:=scoreend+HalfLine;
              end;
      if (Posy[sq]>=7) and ((bking>h7) or ((BlackPawns and Ranks[posy[sq]])<>0)) then
       begin
        score:=score+RookOn7Mid;
        scoreend:=scoreend+RookOn7End;
       end;
      temp:=temp and NotOnly[sq];
    end;

  temp:=BlackRooks;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score-WRSQ[63-sq];
      line:=posx[sq];
      bish:=RooksMove(sq) and (not (BlackPawns or BlackKnights or BlackBishops));
      ind:=BitCount(bish);
      score:=score-Rmob*ind;
      scoreend:=scoreend-RmobEnd*ind;
      if ((bish and wkingzone)<>0) or (dist[sq,wking]<4) then
        begin
          bt:=bt+2;
          inc(bp);
        end;
      if (not wendgame) and ((bstopper[sq] and BlackPawns)=0) and ((bstopper[sq] and wkingzone)<>0) then
        begin
          score:=score-RookHalfKing;
          if (posx[wking]=line) then score:=score-RookOpenKing;
        end;
       if (Files[line] and all)=0 then
              begin
                score:=score-OpenLine;
                scoreend:=scoreend-OpenLine;
              end
             else
       if (Files[line] and blackPawns)=0 then
              begin
                 score:=score-HalfLine;
                 scoreend:=scoreend-HalfLine;
              end;
      if (Posy[sq]<=2) and ((wking<a2) or ((WhitePawns and Ranks[posy[sq]])<>0))  then
       begin
        score:=score-RookOn7Mid;
        scoreend:=scoreend-RookOn7End
       end;
      temp:=temp and NotOnly[sq];
    end;

  temp:=WhiteQueens;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score+WQSQ[sq];
      scoreend:=scoreend+WQESQ[sq];
      bish:=(RooksMove(sq) or BishopsMove(sq)) and (not whitepieses);
      ind:=BitCount(bish);
      score:=score+Qmob*ind;
      scoreend:=scoreend+QmobEnd*ind;
      if ((bish and bkingzone)<>0) or (dist[sq,bking]<4) then
        begin
          wt:=wt+4;
          inc(wp);
        end;
      if (tree[ply].Castle and 3)<>0 then
         if Posy[sq]>2 then dec(score,QueenEarly);
      if (Posy[sq]>=7) and (bking>h7) and ((Ranks[posy[sq]] and WhiteRooks)<>0) then
       begin
        score:=score+QueenOn7Mid;
        scoreend:=scoreend+QueenOn7End;
       end;
      temp:=temp and NotOnly[sq];
    end;


  temp:=BlackQueens;
  while temp<>0 do
    begin
      sq:=BitScanForward(temp);
      score:=score-WQSQ[63-sq];
      scoreend:=scoreend-WQESQ[63-sq];
      bish:=(RooksMove(sq) or BishopsMove(sq)) and (not blackpieses);
      ind:=BitCount(bish);
      score:=score-Qmob*ind;
      scoreend:=scoreend-QmobEnd*ind;
      if ((bish and wkingzone)<>0) or (dist[sq,wking]<4) then
        begin
          bt:=bt+4;
          inc(bp);
        end;
      if (tree[ply].Castle and 12)<>0 then
         if Posy[sq]<7 then inc(score,QueenEarly);
      if (Posy[sq]<=2) and (wking<a2) and ((Ranks[posy[sq]] and BlackRooks)<>0) then
       begin
        score:=score-QueenOn7mid;
        scoreend:=scoreend-QueenOn7End;
       end;
      temp:=temp and NotOnly[sq];
    end;
     if (not bendgame) then mul1:=(wt*Ktropism*Ksafety[wp]) div 256 else mul1:=0;
     if (not wendgame) then mul2:=(bt*Ktropism*Ksafety[bp]) div 256 else mul2:=0;
     score:=score+mul1-mul2;

    score:=((scoreend*(24-mul))+(score*mul)) div 24;
    // Разнопольные слоны в эндшпиле
   if (tree[ply].Wmat=3) and (tree[ply].Bmat=3) and (whitebishops<>0) and (blackbishops<>0)   then
     begin
       if (((WhiteBishops and dark)<>0) and ((BlackBishops and light)<>0)) or
          (((WhiteBishops and light)<>0) and ((BlackBishops and dark)<>0)) then
             begin
              if (abs(wpawns-bpawns)<=2) or ((wpawns<3) and (bpawns<3)) then
               score:=score div 2;
             end;
     end;

if (score>0) and (wmul<>64) then score:=((score*wmul) div 64) else
  if (score<0) and (bmul<>64) then score:=((score*bmul) div 64);
if color=black then score:=-score;
Result:=score;
end;



Function WKvadrat(color:integer;pawn :integer;king:integer):boolean;
var
   ptemp,ktemp : integer;
   res : boolean;
begin
  ptemp:=8-posy[pawn];
  ktemp:=Dist[king,h7+Posx[pawn]];
  if color=white
     then dec(ptemp);
  if ptemp+1<ktemp
      then res:=false
      else res:=true;
  result:=res;
end;
Function BKvadrat(color:integer;pawn :integer;king:integer):boolean;
var
   ptemp,ktemp : integer;
   res : boolean;
begin
  ptemp:=posy[pawn]-1;
  ktemp:=Dist[king,Posx[pawn]-1];
  if color=black
     then dec(ptemp);
  if ptemp+1<ktemp
      then res:=false
      else res:=true;
  result:=res;
end;

Procedure CheckDraw(color : integer;ply:integer);
var
   pawn,wr,br,prom,wp1,wp2: integer;
   wn,wb,bn,bb,wrook,wminor,wqueens,brook,bminor,bqueens,wpawns,bpawns,wtotal,btotal:integer;
   bp1,bp2 : boolean;
begin
 // Инициализация
  wpawns:=BitCount(WhitePawns);
  bpawns:=BitCount(BlackPawns);
  wminor:=BitCount(WhiteKnights or WhiteBishops);
  bminor:=BitCount(BlackKnights or BlackBishops);
  wn:=BitCount(WhiteKnights);
  bn:=BitCount(BlackKnights);
  wb:=BitCount(WhiteBishops);
  bb:=BitCount(BlackBishops);
  wrook:=BitCount(WhiteRooks);
  brook:=BitCount(BlackRooks);
  wqueens:=BitCount(WhiteQueens);
  bqueens:=BitCount(BlackQueens);
  wtotal:=wpawns+wminor+wrook+wqueens;
  btotal:=bpawns+bminor+brook+bqueens;
// Недостаточный для выигрыша материал
  if wpawns=0 then
    begin
      if wtotal=0 then wmul:=0 else // голый король
        if wtotal=1 then
          begin
            if wqueens=1 then
              begin
                if (bqueens>0) or (brook>1) or ((brook=1) and (bminor>0)) or (bminor>2) then wmul:=8;
              end else
             if wrook=1 then
              begin
                if (bqueens>0) or (brook>0) or (bminor>0) then wmul:=8;
              end else wmul:=0;
          end else
         if wtotal=2 then
           begin
             if (wqueens=1) and (wminor=1) then
                begin
                  if (bqueens>0) or (brook>1) then wmul:=16;
                end else
              if (wrook=2) then
                 begin
                   if (bqueens>0) or (brook>1) or ((brook=1) and (bminor>0)) or (bminor>2) then wmul:=16;
                 end else
              if (wrook=1) and (wminor=1) then
                 begin
                   if (bqueens>0) or (brook>0) or (bminor>1) then wmul:=8;
                 end else
              if (wb=2) then
                 begin
                   if (bqueens>0) or (brook>0) or (bb>0) or (bminor>1) then wmul:=8;
                 end else
              if (wn=2) then
                 begin
                   if (btotal=0) or (btotal>bpawns) then wmul:=8;
                 end else
              if (wminor=2) then
                 begin
                   if (bqueens>0) or (brook>0) or (bminor>0) then wmul:=8;
                 end;
           end;
    end;
if bpawns=0 then
    begin
      if btotal=0 then bmul:=0 else // голый король
        if btotal=1 then
          begin
            if bqueens=1 then
              begin
                if (wqueens>0) or (wrook>1) or ((wrook=1) and (wminor>0)) or (wminor>2) then bmul:=8;
              end else
             if brook=1 then
              begin
                if (wqueens>0) or (wrook>0) or (wminor>0) then bmul:=8;
              end else bmul:=0;
          end else
         if btotal=2 then
           begin
             if (bqueens=1) and (bminor=1) then
                begin
                  if (wqueens>0) or (wrook>1) then bmul:=16;
                end else
              if (brook=2) then
                 begin
                   if (wqueens>0) or (wrook>1) or ((wrook=1) and (wminor>0)) or (wminor>2) then bmul:=16;
                 end else
              if (brook=1) and (bminor=1) then
                 begin
                   if (wqueens>0) or (wrook>0) or (wminor>1) then bmul:=8;
                 end else
              if (bb=2) then
                 begin
                   if (wqueens>0) or (wrook>0) or (wb>0) or (wminor>1) then bmul:=8;
                 end else
              if (bn=2) then
                 begin
                   if (wtotal=0) or (wtotal>wpawns) then bmul:=8;
                 end else
              if (bminor=2) then
                 begin
                   if (wqueens>0) or (wrook>0) or (wminor>0) then bmul:=8;
                 end;
           end;
    end;
// Теперь более сложные случаи ничейных позиций:

    // Окончание типа С+пешка h(a)
    if (tree[ply].Wmat=3) and (tree[ply].Bmat=0) and (wb=1) then
       begin
        if ((WhitePawns and Files[1])<>0) and (WhitePawns and (not Files[1])=0)
             and ((WhiteBishops and dark)<>0) and (Dist[bking,a8]<=1) then wmul:=0;
        if ((WhitePawns and Files[8])<>0) and (WhitePawns and (not Files[8])=0)
             and ((WhiteBishops and light)<>0) and (Dist[bking,h8]<=1) then wmul:=0;
       end;
     if (tree[ply].Bmat=3) and (tree[ply].Wmat=0) and (bb=1) then
       begin
         if ((BlackPawns and Files[1])<>0) and (BlackPawns and (not Files[1])=0)
             and ((BlackBishops and light)<>0) and (Dist[wking,a1]<=1) then bmul:=0;
        if ((BlackPawns and Files[8])<>0) and (BlackPawns and (not Files[8])=0)
             and ((BlackBishops and dark)<>0) and (Dist[wking,h1]<=1) then bmul:=0;
       end;

 //  Крайние пешки в пешечном эндшпиле, если король слабейшей стороны успевает в угол:
    if (tree[ply].Wmat=0) and (tree[ply].Bmat=0) then
       begin
         if ((WhitePawns and Files[1])<>0) and ((WhitePawns and (not Files[1]))=0) and (Dist[bking,a8]<=1) then wmul:=0;
         if ((WhitePawns and Files[8])<>0) and ((WhitePawns and (not Files[8]))=0) and (Dist[bking,h8]<=1) then wmul:=0;
         if ((BlackPawns and Files[1])<>0) and ((BlackPawns and (not Files[1]))=0) and (Dist[wking,a1]<=1) then bmul:=0;
         if ((BlackPawns and Files[8])<>0) and ((BlackPawns and (not Files[8]))=0) and (Dist[wking,h1]<=1) then bmul:=0;
       end;
 // Окончание K(B)P -K* где все пешки на 1 вертикали:
 if (tree[ply].Wmat<=3) and (wn=0) and (wpawns<>0) and (tree[ply].Bmat>0) then
    begin
       pawn:=BitScanForward(Whitepawns);
       if ((whitepawns and (not Files[posx[pawn]]))=0) and (posx[bking]=posx[pawn]) and (bking>pawn) then
         if (((Only[bking] and dark)<>0) and ((whitebishops and dark)=0)) or
            (((Only[bking] and light)<>0) and ((whitebishops and light)=0)) then wmul:=8;
    end;
 if (tree[ply].Bmat<=3) and (bn=0) and (bpawns<>0) and (tree[ply].Wmat>0)  then
    begin
       pawn:=BitScanForward(Blackpawns);
       if ((Blackpawns and (not Files[posx[pawn]]))=0) and (posx[wking]=posx[pawn]) and (wking<pawn) then
         if (((Only[wking] and dark)<>0) and ((blackbishops and dark)=0)) or
            (((Only[wking] and light)<>0) and ((blackbishops and light)=0)) then bmul:=8;
    end;
 // KNPK*
 if (tree[ply].Wmat=3) and (tree[ply].Bmat>0) and (wb=0) and (wpawns=1) then
    begin
       pawn:=BitScanForward(Whitepawns);
       if (posx[bking]=posx[pawn]) and (bking>pawn) and (posy[pawn]<7) then wmul:=8;
    end;
 if (tree[ply].Bmat=3) and (tree[ply].Wmat>0) and (bb=0) and (bpawns=1) then
    begin
       pawn:=BitScanForward(Blackpawns);
       if (posx[wking]=posx[pawn]) and (wking<pawn) and (posy[pawn]>2) then bmul:=8;
    end;
 // KNPK
 if (tree[ply].Wmat=3) and (wb=0) and (wpawns=1) and (btotal=0) then
    begin
      if ((Only[a7] and WhitePawns)<>0) and (Dist[bking,a8]<=1) then wmul:=4;
      if ((Only[h7] and WhitePawns)<>0) and (Dist[bking,h8]<=1) then wmul:=4;
    end;
 if (tree[ply].Bmat=3) and (bb=0) and (bpawns=1) and (wtotal=0) then
    begin
      if ((Only[a2] and BlackPawns)<>0) and (Dist[wking,a1]<=1) then bmul:=4;
      if ((Only[h2] and BlackPawns)<>0) and (Dist[wking,h1]<=1) then bmul:=4;
    end;
// KRKP(P)
if (tree[ply].Bmat=5) and (btotal=1) and (tree[ply].Wmat=0) and (wpawns=1) and (isDrawKPKR(color)) then bmul:=4;

if (tree[ply].Wmat=5) and (wtotal=1) and (tree[ply].Bmat=0) and (bpawns=1) and (isDrawKRKP(color)) then wmul:=4;

// KRPKR
if (wtotal=2) and (wpawns=1) and (wrook=1) and (btotal=1) and (brook=1) then
   begin
     pawn:=BitScanForward(WhitePawns);
     prom:=h7+posx[pawn];
     wr:=BitScanForward(WhiteRooks);
     br:=BitScanForward(BlackRooks);
     if bking=prom then
        begin
          if (posx[pawn]<5) and (posx[br]-2>posx[pawn]) then wmul:=8 else
            if (posx[pawn]>4) and (posx[br]+2<posx[pawn]) then wmul:=8;
        end else
      if (posx[bking]=posx[pawn]) and (bking>pawn) then wmul:=8 else
      if (posx[pawn]=7) and (pawn+8=wr) and (posx[pawn]=posx[br]) then
         begin
           if ((posx[pawn]<5) and (bking in [g7,h7])) or ((posx[pawn]>4) and (bking in [a7,b7])) then
              begin
                if (Posy[br]<4) and (Dist[wking,pawn]>1) then wmul:=8 else
                if (Posy[br]>3) and (Dist[wking,pawn]>2) then wmul:=8;
              end;
         end;
   end;
if (btotal=2) and (bpawns=1) and (brook=1) and (wtotal=1) and (wrook=1) then
   begin
     pawn:=BitScanForward(BlackPawns);
     prom:=posx[pawn]-1;
     wr:=BitScanForward(WhiteRooks);
     br:=BitScanForward(BlackRooks);
     if wking=prom then
        begin
          if (posx[pawn]<5) and (posx[wr]-2>posx[pawn]) then bmul:=8 else
            if (posx[pawn]>4) and (posx[wr]+2<posx[pawn]) then bmul:=8;
        end else
      if (posx[wking]=posx[pawn]) and (wking<pawn) then bmul:=8 else
      if (posx[pawn]=2) and (pawn-8=br) and (posx[pawn]=posx[wr]) then
         begin
           if ((posx[pawn]<5) and (wking in [g2,h2])) or ((posx[pawn]>4) and (wking in [a2,b2])) then
              begin
                if (Posy[wr]>5) and (Dist[bking,pawn]>1) then bmul:=8 else
                if (Posy[br]<6) and (Dist[bking,pawn]>2) then bmul:=8;
              end;
         end;
   end;

   
end;


Procedure EvalMate(color:integer;ply:integer);
// Процедура оценивает позиции, где нет пешек, но есть достаточный для мата материал
label l1;
var
   rang : integer;
begin
// Оцениваем эндшпиля с помощью bitbase
if canuseeg then
  begin
   rang:=EGTBBitbaseProbe(color,ply);
   if rang=BadIndex then goto l1;
   score:=rang;
   exit;
  end;
l1:
// Если эндшпиль вида: конь+слон против короля, то оцениваем спец. образом
   if ((WQR or BQR)=0)
     then begin
           if (tree[ply].Wmat=6) and (tree[ply].Bmat=0) and (WhiteKnights<>0) and (WhiteBishops<>0)
               then begin
                    // У белых конь+слон
                     if WhiteBishops and Light<>0
                        then score:=score+(BN_light[bking]shl 1)-Dist[wking,bking]*KingKing
                        else score:=score+(BN_dark[bking] shl 1)-Dist[wking,bking]*KingKing ;
                       exit;
                    end;
          if (tree[ply].Wmat=0) and (tree[ply].Bmat=6) and (BlackKnights<>0) and (BlackBishops<>0)
               then begin
                    // У черных конь+слон
                     if BlackBishops and Light<>0
                        then score:=score-(BN_light[wking]shl 1)+Dist[wking,bking]*KingKing
                        else score:=score-(BN_dark[bking] shl 1)+Dist[wking,bking]*KingKing ;
                       exit;
                    end;
          end;
  // В общем случае загоняем слабейшего короля в угол при максимальном приближении к нему сильнейшего
  // короля (в этом случае больше шансов досчитаться до мата).
  if (score>0) and (wmul<>64) then score:=((score*wmul) div 64) else
  if (score<0) and (bmul<>64) then score:=((score*bmul) div 64);
  if score>0
    then
        begin
        score:=score -(KMATE[bking]) - Dist[wking,bking]*3;
        if (tree[ply].Bmat=3) and (BlackKnights<>0) then score:=score+Dist[BitScanForWard(BlackKnights),bking]*3;
        if score<0 then score:=1;
        end
    else
   if score<0 then
       begin
       score:=score+(KMATE[wking]) + (Dist[wking,bking]*3);
       if (tree[ply].wmat=3) and (WhiteKnights<>0) then score:=score-Dist[BitScanForWard(WhiteKnights),wking]*3;
       if score>0 then score:=-1;
       end;
  
end;

Function ispasserBlocked(pawnsq:integer;color:integer):boolean;
var
   res:boolean;
   move : integer;
begin
  res:=false;
  if color=white then
     begin
       if (Only[pawnsq+8] and Allpieses)<>0 then res:=true else
         begin
           move:=pawnsq or ((pawnsq+8) shl 8) or (pawn shl 16);
           if staticEE(white,move)<0 then res:=true;
         end;
     end else
     begin
       if (Only[pawnsq-8] and Allpieses)<>0 then res:=true else
         begin
           move:=pawnsq or ((pawnsq-8) shl 8) or (pawn shl 16);
           if staticEE(black,move)<0 then res:=true;
         end;
     end;
Result:=res;
end;

Function IsDrawKPKR(color:integer):boolean;
var
   wp,br,wkx,wpx,brx,bry,dis:integer;
   res:boolean;
begin
  wp:=BitScanForward(WhitePawns);
  if Dist[wking,wp]>2 then
     begin
       result:=false;
       exit;
     end;
  res:=false;
  br:=BitScanForward(BlackRooks);
  wkx:=Posx[wking];
  wpx:=Posx[wp];
  brx:=Posx[br];
  bry:=Posy[br];
  dis:=dist[wking,h7+wpx]+dist[wp,h7+wpx];
  if wking=h7+wpx then inc(dis);
  if wking=wp+8 then
     begin
       if wkx in [1,8] then
          begin
            result:=false;
            exit;
          end;
       inc(dis);
     end;
   if (brx<>wpx) or (bry<>8) then dec(dis);
   if color=white then dec(dis);
   if Dist[bking,h7+wpx]>=dis then res:=true;
  Result:=res;
end;
Function IsDrawKRKP(color:integer):boolean;
var
   wp,br,wkx,wpx,brx,bry,dis:integer;
   res:boolean;
begin
   wp:=BitScanForward(BlackPawns);
   if Dist[bking,wp]>2 then
     begin
       result:=false;
       exit;
     end;
  res:=false;
  br:=BitScanForward(WhiteRooks);
  wkx:=Posx[bking];
  wpx:=Posx[wp];
  brx:=Posx[br];
  bry:=Posy[br];
  dis:=dist[bking,wpx-1]+dist[wp,wpx-1];
  if bking=wpx-1 then inc(dis);
  if bking=wp-8 then
     begin
       if wkx in [1,8] then
          begin
            result:=false;
            exit;
          end;
       inc(dis);
     end;
   if (brx<>wpx) or (bry<>1) then dec(dis);
   if color=black then dec(dis);
   if Dist[wking,wpx-1]>=dis then res:=true;
  Result:=res;
end;

end.







