unit init;
// Юнит хранит процедуры и функции, которые вызываются 1 раз при инициализации программы
interface
uses params;
const
     legal=1;
Procedure Fill_Work_Arrays;
Procedure Do_BitBoards;
Function Do_BitLine(col:integer;line:integer;len:integer):integer;
Procedure FillEvalData;
implementation
uses bitboards;

Procedure Fill_Work_Arrays;
// Процедура заполняет служебные массивы и флаги
 var i:integer;
     temp:bitboard;
  begin
   For i:=0 to 63 do
    begin
      temp:=0;
      SetBitInBitBoard(temp,i);
      Only[i]:=temp;
      NotOnly[i]:=not temp;
      OnlyR90[R90[i]]:=temp;
      NotOnlyR90[R90[i]]:=not temp;
      OnlyDa1[Da1[i]]:=temp;
      NotOnlyDa1[Da1[i]]:=not temp;
      OnlyDh1[Dh1[i]]:=temp;
      NotOnlyDh1[Dh1[i]]:=not temp;
    end;
   Captureflag:= 1 shl 28;
   Promoteflag:= 1 shl 29;
   Castleflag:= 1 shl 30;
   Enpassantflag:= 1 shl 31;
   HMateThreatflag:=1 shl 15;
   znakflag:=1 shl 23;
   znakmask:=65535 shl 16;
   CapPromoFlag:=CaptureFlag or PromoteFlag;
   wshortmask:=Only[f1] or Only[g1];
   wlongmask:=Only[d1] or Only[c1] or Only[b1];
   bshortmask:=Only[f8] or Only[g8];
   blongmask:=Only[d8] or Only[c8] or Only[b8];
   wshort:=Castleflag or (king shl 16) or (g1 shl 8) or (e1);
   wlong:=Castleflag or (king shl 16) or (c1 shl 8) or (e1);
   bshort:=Castleflag or (king shl 16) or (g8 shl 8) or (e8);
   blong:=Castleflag or (king shl 16) or (c8 shl 8) or (e8);

  end;
Procedure Do_BitBoards;
// Процедура инициализирует служебные массивы с битбордами
var
   i,j,count,attack,lin,col,dcol,mlin,count1:integer;
   knight,king,aBoard,cBoard: bitboard;
   kmove,nmove : array[1..8] of integer;
   wrong : array[11..88,11..88] of byte;
   qmove : array [1..8] of integer;
  begin
    // 1.Создаем проверочную доску.
    for i:=-10 to 109 do
    For j:=1 to 2 do // Обнулили проверочную доску
     Board[i,j]:=0;
    count:=0;
    for i:=1 to 8 do
    for j:=1 to 8 do
      begin
        Board[j*10+i,1]:=1; // Признак легальности поля на шахматной доске.
        Board[j*10+i,2]:=count; //Номер бита в битбоарде
        Recod[j*10+i]:=count;
        deboard[count]:=j*10+i;
        Posx[count]:=j;
        Posxx[count]:=j-1;
        Posy[count]:=i;
        Posyy[count]:=i-1;
        inc(count);
      end;
    for i:=1 to 8 do
       begin
        cBoard:=0;aBoard:=0;
        For j:=1 to 8 do
          begin
          SetBitInBitboard(cBoard,Board[i+j*10,2]);
          SetBitInBitboard(aBoard,Board[i*10+j,2]);
          end;
       Ranks[i]:=cBoard;
       Files[i]:=aBoard;
       end;
    noafile:=Files[2] or Files[3] or Files[4] or Files[5] or Files[6] or Files[7] or Files[8];
    nohfile:=Files[1] or Files[2] or Files[3] or Files[4] or Files[5] or Files[6] or Files[7];
    for i:=0 to 63 do
        RookFull[i]:=files[posx[i]] or ranks[posy[i]];
    for i:=11 to 88 do
      if Board[i,1]=1 then
        begin
          aboard:=0;
          j:=i;
          while board[j+9,1]=1 do
          begin
           aboard:=aboard or Only[Board[j+9,2]];
           j:=j+9;
          end;
          j:=i;
          while board[j-9,1]=1 do
          begin
           aboard:=aboard or Only[Board[j-9,2]];
           j:=j-9;
          end;
          j:=i;
          while board[j+11,1]=1 do
          begin
           aboard:=aboard or Only[Board[j+11,2]];
           j:=j+11;
          end;
          j:=i;
          while board[j-11,1]=1 do
          begin
           aboard:=aboard or Only[Board[j-11,2]];
           j:=j-11;
          end;
          BishopFull[board[i,2]]:=aboard;
        end;

 // Заполняем массивы вращающихся битбордов
 // Горизонтальные
    For j:=0 to 63 do
     begin
       for lin:=0 to 255 do
         begin
           RB[j,lin]:=0;
           MobRB[j,lin]:=0;
           mlin:=0;
           for i:=1 to 8 do
            if (lin and (1 shl i))<>0 then mlin:=mlin or (1 shl (7-i));
           attack:=Do_BitLine(Posx[j],mlin,8);
           while attack<>0 do
             begin
               col:=BitScanForward8(attack);
               RB[j,lin]:=RB[j,lin] or Only[(Posy[j]-1)*8+7-col];
               attack:=attack and (not (1 shl col ));
             end;
            MobRB[j,lin]:=BitCount(RB[j,lin]);
         end;
     end;
  // Вертикальные
    For j:=0 to 63 do
     begin
       for lin:=0 to 255 do
         begin
           RBR90[j,lin]:=0;
           MobRBR90[j,lin]:=0;
           attack:=Do_BitLine(9-Posy[j],lin,8);
           while attack<>0 do
             begin
               col:=BitScanForward8(attack);
               RBR90[j,lin]:=RBR90[j,lin] or Only[col*8+Posxx[j]];
               attack:=attack and (not (1 shl col ));
             end;
            MobRBR90[j,lin]:=BitCount(RBR90[j,lin]);
         end;
     end;
 // Диагональ a8-h1
     For j:=0 to 63 do
     begin
       MaskDh1[j]:=(1 shl DiagLenh1[j])-1;
       for lin:=0 to 255 do
         begin
           RBDh1[j,lin]:=0;
           MobRBDh1[j,lin]:=0;
           attack:=Do_BitLine(sqh1[j],lin,DiagLenh1[j]);
           while attack<>0 do
             begin
               col:=BitScanForward8(attack);
               dcol:=DiagLenh1[j]-sqh1[j];
               if dcol<col
                  then
                       RBDh1[j,lin]:=RBDh1[j,lin] or Only[j-7*(col-dcol)]
                  else
               if dcol>col
                  then
                      RBDh1[j,lin]:=RBDh1[j,lin] or Only[j+7*(dcol-col)];

               attack:=attack and (not (1 shl col ));
             end;
            MobRBDh1[j,lin]:=BitCount(RBDh1[j,lin]);
         end;
     end;
// Диагональ a1-h8
    For j:=0 to 63 do
     begin
       MaskDa1[j]:=(1 shl DiagLena1[j])-1;
       for lin:=0 to 255 do
         begin
           RBDa1[j,lin]:=0;
           MobRBDa1[j,lin]:=0;
           attack:=Do_BitLine(sqa1[j],lin,DiagLena1[j]);
           while attack<>0 do
             begin
               col:=BitScanForward8(attack);
               dcol:=DiagLena1[j]-sqa1[j];
               if dcol<col
                  then
                       RBDa1[j,lin]:=RBDa1[j,lin] or Only[j+9*(col-dcol)]
                  else
               if dcol>col
                  then
                      RBDa1[j,lin]:=RBDa1[j,lin] or Only[j-9*(dcol-col)];

               attack:=attack and (not (1 shl col ));
             end;
            MobRBDa1[j,lin]:=BitCount(RBDa1[j,lin]);
         end;
     end;
   // Заполняем битборды атак коня и короля
    kmove[1]:=1;kmove[2]:=-1;kmove[3]:=10;kmove[4]:=-10;
    kmove[5]:=9;kmove[6]:=-9;kmove[7]:=11;kmove[8]:=-11;
    nmove[1]:=21;nmove[2]:=-19;nmove[3]:=12;nmove[4]:=-8;
    nmove[5]:=8;nmove[6]:=-21;nmove[7]:=-12;nmove[8]:=19;
     For i:=11 to 88 do
      if Board[i,1]=1 then
       begin
         king:=0;
         knight:=0;
         for j:=1 to 8 do
           begin
             if Board[kmove[j]+i,1]=1
                 then king:= king or Only[Board[kmove[j]+i,2]];
             if Board[nmove[j]+i,1]=1
                 then knight:= knight or Only[Board[nmove[j]+i,2]];
           end;
         KingsMove[Board[i,2]]:=king;
         KnightsMove[Board[i,2]]:=knight;
       end;
     For i:=11 to 88 do
      if Board[i,1]=1 then
       begin
         king:=0;
         knight:=0;
         for j:=1 to 4 do
           begin
             if Board[kmove[j]+i,1]=1
                 then king:= king or Only[Board[nmove[j]+i,2]];
             if Board[nmove[j+4]+i,1]=1
                 then knight:= knight or Only[Board[nmove[j+4]+i,2]];
           end;
         NHALFW[Board[i,2]]:=king;
         NHALFB[Board[i,2]]:=knight;
       end;
   // Заполняем битборды пешечных атак
     For i:=11 to 88 do
         if Board[i,1]=1 then
           begin
             aBoard:=0;cBoard:=0;
             if (Board[i-9,1]=1) then SetBitInBitBoard(aBoard,Board[i-9,2]);
             if (Board[i+11,1]=1) then SetBitInBitBoard(aBoard,Board[i+11,2]);
             if (Board[i+9,1]=1) then SetBitInBitBoard(cBoard,Board[i+9,2]);
             if (Board[i-11,1]=1) then SetBitInBitBoard(cBoard,Board[i-11,2]);
             WPattacks[Board[i,2]]:=aBoard;
             BPattacks[Board[i,2]]:=cBoard;
           end;
   // Заполняем таблицу направлений
   for i:=11 to 88 do
    if Board[i,1]=1 then
      begin
       aBoard:=0;
       j:=i;
       while Board[j-10,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j-10,2]];
           j:=j-10;
         end;
       LDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j+10,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j+10,2]];
           j:=j+10;
         end;
       RDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j-1,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j-1,2]];
           j:=j-1;
         end;
       DDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j+1,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j+1,2]];
           j:=j+1;
         end;
       UDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j-9,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j-9,2]];
           j:=j-9;
         end;
       ULDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j+11,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j+11,2]];
           j:=j+11;
         end;
       URDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j-11,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j-11,2]];
           j:=j-11;
         end;
       DLDir[Board[i,2]]:=aBoard;
       aBoard:=0;
       j:=i;
       while Board[j+9,1]=1 do
         begin
           aBoard:=aBoard or Only[Board[j+9,2]];
           j:=j+9;
         end;
       DRDir[Board[i,2]]:=aBoard;
      end;




   // Заполняем таблицу перекрытий от шаха
    for i:=0 to 63 do
      for j:=0 to 63 do
        begin
        if (LDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=Ldir[i] and (not (LDir[i] xor Rdir[j]));
             direction[i,j]:=-10;
             end
              else
        if (RDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=Rdir[i] and (not (RDir[i] xor Ldir[j]));
             direction[i,j]:=10;
             end
              else
        if (UDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=Udir[i] and (not (UDir[i] xor Ddir[j]));
             direction[i,j]:=1;
             end
              else
        if (DDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=Ddir[i] and (not (DDir[i] xor Udir[j]));
             direction[i,j]:=-1;
             end
              else
        if (ULDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=ULdir[i] and (not (ULDir[i] xor DRdir[j]));
             direction[i,j]:=-9;
             end
              else
        if (URDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=URdir[i] and (not (URDir[i] xor DLdir[j]));
             direction[i,j]:=11;
             end
              else
        if (DLDir[i] and Only[j])<>0
           then
              begin
              InterSect[i,j]:=DLdir[i] and (not (DLDir[i] xor URdir[j]));
              direction[i,j]:=-11;
              end
               else
        if (DRDir[i] and Only[j])<>0
           then
             begin
             InterSect[i,j]:=DRdir[i] and (not (DRDir[i] xor ULdir[j]));
             direction[i,j]:=9;
             end
              else
                begin
                InterSect[i,j]:=0;
                direction[i,j]:=0;
                end;
        end;
    Hmovemask:=Ranks[1] or Ranks[2] or Ranks[3] or Ranks[4];
    Rank27:=Ranks[2] or Ranks[7];
    abc:=Files[1] or Files[2] or Files[3];
    fgh:=Files[6] or Files[7] or Files[8];
    a3b3c2:=Only[a3] or Only[b3] or Only[c2];
    a6b6c7:=Only[a6] or Only[b6] or Only[c7];
    f2g3h3:=Only[f2] or Only[g3] or Only[h3];
    f7g6h6:=Only[f7] or Only[g6] or Only[h6];
    a3b2c3:=Only[a3] or Only[b2] or Only[c3];
    a6b7c6:=Only[a6] or Only[b7] or Only[c6];
    f3g2h3:=Only[f3] or Only[g2] or Only[h3];
    f6g7h6:=Only[f6] or Only[g7] or Only[h6];
    g1h1:=Only[g1] or Only[h1];
    a1b1:=Only[a1] or Only[b1];
    g8h8:=Only[g8] or Only[h8];
    a8b8:=Only[a8] or Only[b8];
    h2h3:= Only[h2] or Only[h3];
    a2a3:=Only[a2]  or Only[a3];
    h7h6:= Only[h7] or Only[h6];
    a7a6:=Only[a7]  or Only[a6];
    f2g3h2:=Only[f2] or Only[g3] or Only[h2];
    a2b3c2:=Only[a2] or Only[b3] or Only[c2];
    f7g6h7:=Only[f7] or Only[g6] or Only[h7];
    a7b6c7:=Only[a7] or Only[b6] or Only[c7];
    Pawnext:=Ranks[2] or Ranks[7];
    wqflang:=(Files[1] or Files[2] or Files[3]) and ( not ( Ranks[5] or Ranks[6] or Ranks[7] or Ranks[8]));
    wkflang:=( Files[6] or Files[7] or Files[8]) and ( not (Ranks[5] or Ranks[6] or Ranks[7] or Ranks[8]));
    bqflang:=(Files[1] or Files[2] or Files[3]) and (not (Ranks[1] or Ranks[2] or Ranks[3] or Ranks[4]));
    bkflang:= (Files[6] or Files[7] or Files[8]) and (not (Ranks[1] or Ranks[2] or Ranks[3]or Ranks[4]));
    wbishtrap:=Only[a7] or Only[b8] or Only[h7] or Only[g8];
    bbishtrap:=Only[a2] or Only[b1] or Only[h2] or Only[g1];
    wrooktrap[-3]:=Only[a1] or Only[a2] or Only[b2];
    wrooktrap[-2]:=Only[a1] or Only[b1] or  Only[a2] or Only[b2];
    wrooktrap[-1]:=Only[a1] or Only[b1] or Only[c1] or  Only[a2] or Only[b2];
    wrooktrap[1]:=Only[h1] or Only[g1]  or  Only[h2] or Only[g2];
    wrooktrap[2]:=Only[h1] or Only[h2];
    wrooktrap[0]:=Only[f1] or Only[g1] or Only[h1] or Only[h2] or Only[g2] or Only[f2];
    wrooktrap[-4]:=0;
    wrooktrap[3]:=0;
    brooktrap[-3]:=Only[a8] or Only[a7] or Only[b7];
    brooktrap[-2]:=Only[a8] or Only[b8] or  Only[a7] or Only[b7];
    brooktrap[-1]:=Only[a8] or Only[b8] or Only[c8] or  Only[a7] or Only[b7];
    brooktrap[1]:=Only[h8] or Only[g8]  or  Only[h7] or Only[g7];
    brooktrap[2]:=Only[h8] or Only[h7];
    brooktrap[0]:=Only[f8] or Only[g8] or Only[h8] or Only[h7] or Only[g7] or Only[f7];
    brooktrap[-4]:=0;
    brooktrap[3]:=0;
    wfianq:=Only[b2] or Only[a1] or Only[c1] or Only[a3] or Only[c3];
    wfiank:=Only[g2] or Only[h1] or Only[f1] or Only[h3] or Only[f3];
    bfianq:=Only[b7] or Only[a8] or Only[c8] or Only[a6] or Only[c6];
    bfiank:=Only[g7] or Only[h8] or Only[f8] or Only[h6] or Only[f6];
    centerw:= Only[d4] or Only[e4] or only[f4] or only[c4] or Only[d5] or Only[e5] or Only[c5] or Only[f5] or Only[d6] or Only[e6] or only[c6] or only[f6] ;
    centerb:= Only[d4] or Only[e4] or Only[f4] or Only[c4] or Only[d5] or Only[e5] or only[c5] or only[f5] or Only[d3] or Only[e3] or only[c3] or only[f3];
    a1h1h8:=Only[a1] or Only[b1] or Only[c1] or Only[d1] or Only[e1] or Only[f1] or
            Only[g1] or Only[h1] or Only[b2] or Only[c2] or Only[d2] or Only[e2] or
            Only[f2] or Only[g2] or Only[h2] or Only[c3] or Only[d3] or Only[e3] or
            Only[f3] or Only[g3] or Only[h3] or Only[d4] or Only[e4] or Only[f4] or
            Only[g4] or Only[h4] or Only[e5] or Only[f5] or Only[g5] or Only[h5] or
            Only[f6] or Only[g6] or Only[h6] or Only[g7] or Only[h7] or Only[h8];
    a1d1d4:=Only[a1] or Only[b1] or Only[c1] or Only[d1] or Only[b2] or Only[c2] or
            Only[d2] or Only[c3] or Only[d3] or Only[d4];
    a1h8:=  Only[a1] or Only[b2] or Only[c3] or Only[d4] or Only[e5] or Only[f6] or
            Only[g7] or Only[h8];
    pkikw:=only[e4] or Only[d4] or Only[e3] or Only[d3];
    pkikb:=only[e5] or Only[d5] or Only[e6] or Only[d6];
    For i:=0 to 63 do
    For j:=0 to 63 do
      begin
        FileDist[i,j]:=abs(Posx[i]-Posx[j]);
        RankDist[i,j]:=abs(Posy[i]-Posy[j]);
        if FileDist[i,j]>RankDist[i,j]
           then Dist[i,j]:=FileDist[i,j]
           else Dist[i,j]:=RankDist[i,j];
      end;
    for i:=0 to 63 do
     begin
      zoneslide[i]:=0;
      for j:=0 to 63 do
       if Dist[i,j]<3 then zoneslide[i]:=zoneslide[i] or Only[j];
     end;
    light:=0;
    dark:=0;
    for i:=0 to 63 do
       begin
         if trunc((i+Posy[i])/2)*2<>i+Posy[i]
            then dark:=dark or Only[i]
            else light:=light or Only[i];
       end;
   For i:=0 to 63 do
     wkingconv[i]:=BadIndex;
   wkingconv[a1]:=0;wkingconv[b1]:=1;wkingconv[c1]:=2;wkingconv[d1]:=3;wkingconv[b2]:=4;
   wkingconv[c2]:=5;wkingconv[d2]:=6;wkingconv[c3]:=7;wkingconv[d3]:=8;wkingconv[d4]:=9;

   qmove[1]:=1;qmove[2]:=-1;qmove[3]:=10;qmove[4]:=-10;
   qmove[5]:=11;qmove[6]:=-11;qmove[7]:=9;qmove[8]:=-9;
 // Wrong - двумерный массив расположения королей.
// содержит "1"- если короли на доске стоят легально (не угрожают друг другу)
for i:=11 to 88 do
  For j:=11 to 88 do
    wrong[i,j]:=legal;
for i:=11 to 88 do
 if Board[i,1]=legal then
    begin
      for j:=1 to 8 do
      if Board[i+qmove[j],1]=legal then
              Wrong[i,i+qmove[j]]:=0;
      wrong[i,i]:=0;
    end;
 // Заполнение двумерных массивов нумерации легальных расположений королей.
// массив k_k_pawnless[0..9,0..63] содержит нумерацию (от 1 до 462) комбинаций королей,
// использующихся для индексации безпешечных эндшпилей.k_k_wpawns[0..63,0..63] содержит
// нумерацию (1..3612) легальных положений двух королей на всей доске. Используется для
// индексации эндшпилей с пешками.
 For i:=0 to 63 do
 For j:=0 to 63 do
  begin
    k_k_wpawns[i,j]:=BadIndex;
    if i<10 then
      k_k_pawnless[i,j]:=BadIndex;
  end;
  count:=0;count1:=0;
  for i:=0 to 63 do
   For j:=0 to 63 do
    if (wrong[deboard[i],deboard[j]]=legal) then
      begin
        if (Only[i] and a1d1d4)<>0 then
          begin
            if (only[i] and a1h8)<>0
              then begin
                    if (only[j] and a1h1h8)<>0 then
                      begin
                        inc(count);
                        k_k_pawnless[wkingconv[i],j]:=count;
                      end;
                   end
               else
                   begin
                    inc(count);
                    k_k_pawnless[wkingconv[i],j]:=count;
                   end;

         end ;
       inc(count1);
       k_k_wpawns[i,j]:=count1;
      end;
  end;

Function Do_BitLine(col:integer;line:integer;len:integer):integer;
// Функция получает на вход "индексную" линию битов длиной len и возвращает линию битов,
// отвечающих за возможные ходы фигуры при заданной "индексной" линии.
var
   temp,mask : integer;
  begin
    temp:=0;
    // Движемся влево
    if col>1 then
      begin
        mask:=1 shl (len-col+1);
        while mask<256 do
          begin
            temp:=temp or mask;
            if ((line and mask)<>0) then break;
            mask:=mask shl 1;
          end;
      end;
     // Движемся вправо
    if col<8 then
      begin
        mask:=1 shl (len-col-1);
        while mask>0 do
          begin
            temp:=temp or mask;
            if ((line and mask)<>0) then break;
            mask:=mask shr 1;
          end;
      end;
    Result:=temp and ((1 shl len)-1);
  end;
Procedure FillEvalData;
var
   i,j: integer;
   aBoard,cBoard,bBoard,dBoard,eBoard,fBoard,gBoard :bitboard;
begin

  for i:=0 to 63 do
   begin
   aBoard:=0;cBoard:=0;bBoard:=0;
   if Posx[i]>1 then aBoard:=aBoard or Files[Posx[i]-1];
   if Posx[i]<8 then aBoard:=aBoard or Files[Posx[i]+1];
    j:=i; fBoard:=aBoard;gBoard:=aBoard;
    while j+8<=h8 do
      begin
        cBoard:=CBoard or Only[j+8];
        fBoard:=fboard and (not Ranks[Posy[j]]);
        j:=j+8;
        fBoard:=fboard and (not Ranks[Posy[j]]);
      end;
     j:=i;
    while j-8>=a1 do
      begin
        bBoard:=bBoard or Only[j-8];
        gBoard:=gboard and (not Ranks[Posy[j]]);
        j:=j-8;
        gBoard:=gboard and (not Ranks[Posy[j]]);
      end;
   IsoMask[i]:=aBoard;
   WStopper[i]:=cBoard;
   BStopper[i]:=bBoard;

   dBoard:=IsoMask[i] or WStopper[i];
   For j:=Posy[i] downto 1 do
    dBoard:=dBoard and (not Ranks[j]);
   eBoard:=IsoMask[i] or BStopper[i];
   For j:=Posy[i] to 8 do
    eBoard:=eBoard and (not Ranks[j]);
   WPassMask[i]:=dBoard and (not WPAttacks[i]) ;
   BPassMask[i]:=eBoard and (not BPAttacks[i]);
   if posx[i]>1 then
     begin
       fboard:=fboard or Only[i-1];
       gboard:=gboard or Only[i-1];
     end;
   if posx[i]<8 then
     begin
       fboard:=fboard or Only[i+1];
       gboard:=gboard or Only[i+1];
     end;
   WBack[i]:=fBoard;
   BBack[i]:=gBoard;
   end;
  
end;

end.





