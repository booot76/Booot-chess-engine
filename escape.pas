unit escape;
// Юнит отвечает за генерирование защит от шаха. Заполняет массив ходов легальными защитами.

interface
uses params,bitboards,attacks;
Function GetEscapes(color : integer;ply: integer):integer;
Function Pinned(color:integer;king:integer;piesesq:integer):boolean;
Function isMatednow(color : integer;ply: integer):boolean;
implementation
Function GetEscapes(color : integer;ply: integer):integer;
//Процедура находит легальные защиты от шаха.Возвращает количество легальных взятий (для модели форсированной игры)
var
   checksfrom,temp,mask,mask1,Legalmoves,pad: bitboard;
   kingSq,Chkcount,newsq,shablon,point,count,piese,chkpiese,dest : integer;
   res : integer;
  begin
    res:=0;
    // Вычисляем индекс в массиве ходов
    point:=ply shl 7;
    count:=point;
    if color=white then
      begin
        // Находим количество шахующих фигур
        kingsq:=tree[ply].Wking;
        checksfrom:=AttackedFrom(kingsq) and BlackPieses;
        chkcount:=BitCount(checksfrom);
            // Уходим королем изпод шаха (в том числе и со взятиями)
            AllPieses:=AllPieses and NotOnly[kingsq];
            AllR90:=AllR90 and NotOnlyR90[kingsq];
            AllDh1:=AllDh1 and NotOnlyDh1[kingsq];
            AllDa1:=AllDa1 and NotOnlyDa1[kingsq];
            shablon:=(king shl 16) or kingsq;
            temp:=KingsMove[kingsq] and (not WhitePieses);
            while temp<>0 do
              begin
                newsq:=BitScanForward(temp);
                if not isBlackAttacks(newsq) then
                    begin
                      inc(count);
                      piese:=-WhatPiese(newsq);
                      if piese<>0 then
                                       begin
                                       takes[count]:=CaptureFlag or (piese shl 20) or (newsq shl 8) or shablon;
                                       inc(res);
                                       end
                                  else
                                       takes[count]:=(newsq shl 8) or shablon;

                    end;
                temp:=temp and NotOnly[newsq];
              end;
            AllPieses:=AllPieses or Only[kingsq];
            AllR90:=AllR90 or OnlyR90[kingsq];
            AllDh1:=AllDh1 or OnlyDh1[kingsq];
            AllDa1:=AllDa1 or OnlyDa1[kingsq];

        if (chkcount = 1)  then
          begin
          // Если шахующая фигура одна , то пробуем побить ее (кроме как королем) или закрыться (если она не пешка и не конь)
          chkpiese:=BitScanForward(checksfrom);
          if -WhatPiese(chkpiese) in [bishop,rook,queen]
            then
                mask:=InterSect[kingsq,chkpiese] or Only[chkpiese]
            else
                mask:=Only[chkpiese];
           temp:=WhiteKnights;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=KnightsMove[newsq] and mask;
                        shablon:=(knight shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=-WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteBishops;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=BishopsMove(newsq) and mask;
                        shablon:=(bishop shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=-WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteRooks;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=RooksMove(newsq) and mask;
                        shablon:=(rook shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=-WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteQueens;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=(BishopsMove(newsq) or RooksMove(newsq)) and mask;
                        shablon:=(queen shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=-WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          
            mask1:=(BlackPieses or Only[tree[ply].EnnPass]) and mask;
            if (BlackPawns and mask and (Only[tree[ply].EnnPass] shr 8))<>0
              then mask1:=mask1 or Only[tree[ply].EnnPass];
            temp:=((WhitePawns and NoaFile) shl 7) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(white,kingsq,dest-7) then
                   begin
                     inc(count);
                     inc(res);
                     piese:=-WhatPiese(dest);
                     if piese=0
                        then
                            takes[count]:=CaptureFlag or EnPassantFlag  or (pawn shl 16) or (dest shl 8) or (dest-7)
                        else
                            begin
                            if dest<a8 then
                                            takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7)
                                       else
                                            begin
                                              takes[count]:=CaptureFlag or PromoteFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-7);
                                            end;
                            end;
                   end;
                temp:=temp and NotOnly[dest];
              end;
            temp:=((WhitePawns and NohFile) shl 9) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(white,kingsq,dest-9) then
                   begin
                     inc(count);
                     inc(res);
                     piese:=-WhatPiese(dest);
                     if piese=0
                        then
                            takes[count]:=CaptureFlag or EnPassantFlag  or (pawn shl 16) or (dest shl 8) or (dest-9)
                        else
                            begin
                            if dest<a8 then
                                            takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9)
                                       else
                                            begin
                                              takes[count]:=CaptureFlag or PromoteFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
                                              inc(count);
                                              takes[count]:=CaptureFlag or PromoteFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest-9);
                                            end;
                            end;
                   end;
                temp:=temp and NotOnly[dest];
              end;
             mask1:=(not AllPieses) and mask;
             temp:=(WhitePawns shl 8) and mask1;
             while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(white,kingsq,dest-8) then
                   begin
                     if dest<a8 then
                        begin
                         inc(count);
                         takes[count]:=(pawn shl 16) or (dest shl 8) or (dest-8);
                        end
                                else
                        begin
                          inc(count);
                          takes[count]:=PromoteFlag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                          inc(count);
                          takes[count]:=PromoteFlag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                          inc(count);
                          takes[count]:=PromoteFlag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                          inc(count);
                          takes[count]:=PromoteFlag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest-8);
                        end;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
            pad:=(WhitePawns shl 8) and (not AllPieses);
            temp:=((pad and Ranks[3]) shl 8) and mask1;
          //  temp:= ( ( (WhitePawns shl 8) and (not AllPieses) and Ranks[3] ) shl 8 ) and mask1;
            while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(white,kingsq,dest-16) then
                   begin
                    inc(count);
                    takes[count]:=(pawn shl 16) or (dest shl 8) or (dest-16);
                   end;
                 temp:=temp and NotOnly[dest];
               end;
          end;
      end
else  begin
         // Находим количество шахующих фигур
        kingsq:=tree[ply].Bking;
        checksfrom:=AttackedFrom(kingsq) and WhitePieses;
        chkcount:=BitCount(checksfrom);
            // Уходим королем изпод шаха (в том числе и со взятиями)
            AllPieses:=AllPieses and NotOnly[kingsq];
            AllR90:=AllR90 and NotOnlyR90[kingsq];
            AllDh1:=AllDh1 and NotOnlyDh1[kingsq];
            AllDa1:=AllDa1 and NotOnlyDa1[kingsq];
            shablon:=(king shl 16) or kingsq;
            temp:=KingsMove[kingsq] and (not BlackPieses);
            while temp<>0 do
              begin
                newsq:=BitScanForward(temp);
                if not isWhiteAttacks(newsq) then
                    begin
                      inc(count);
                      piese:=WhatPiese(newsq);
                      if piese<>0 then
                                       begin
                                       takes[count]:=CaptureFlag or (piese shl 20) or (newsq shl 8) or shablon;
                                       inc(res);
                                       end
                                  else
                                       takes[count]:=(newsq shl 8) or shablon;

                    end;
                temp:=temp and NotOnly[newsq];
              end;
            AllPieses:=AllPieses or Only[kingsq];
            AllR90:=AllR90 or OnlyR90[kingsq];
            AllDh1:=AllDh1 or OnlyDh1[kingsq];
            AllDa1:=AllDa1 or OnlyDa1[kingsq];

        if (chkcount = 1)  then
          begin
          // Если шахующая фигура одна , то пробуем побить ее (кроме как королем) или закрыться (если она не пешка и не конь)
          chkpiese:=BitScanForward(checksfrom);
          if WhatPiese(chkpiese) in [bishop,rook,queen]
            then
                mask:=InterSect[kingsq,chkpiese] or Only[chkpiese]
            else
                mask:=Only[chkpiese];
           temp:=BlackKnights;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=KnightsMove[newsq] and mask;
                        shablon:=(knight shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackBishops;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=BishopsMove(newsq) and mask;
                        shablon:=(bishop shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackRooks;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=RooksMove(newsq) and mask;
                        shablon:=(rook shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackQueens;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=(BishopsMove(newsq) or RooksMove(newsq)) and mask;
                        shablon:=(queen shl 16) or newsq;
                        while LegalMoves<>0 do
                          begin
                            dest:=BitScanForward(LegalMoves);
                            piese:=WhatPiese(dest);
                            inc(count);
                            if piese<>0 then
                                           begin
                                            takes[count]:=CaptureFlag or (piese shl 20) or (dest shl 8) or shablon;
                                            inc(res);
                                           end
                                        else takes[count]:=(dest shl 8) or shablon;
                            LegalMoves:=LegalMoves and NotOnly[dest];
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
            mask1:=(WhitePieses or Only[tree[ply].EnnPass]) and mask;
            if (WhitePawns and mask and (Only[tree[ply].EnnPass] shl 8))<>0
              then mask1:=mask1 or Only[tree[ply].EnnPass];
              
            temp:=((BlackPawns and NoaFile) shr 9) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(black,kingsq,dest+9) then
                   begin
                     inc(count);
                     inc(res);
                     piese:=WhatPiese(dest);
                     if piese=empty
                        then
                            takes[count]:=CaptureFlag or EnPassantFlag  or (pawn shl 16) or (dest shl 8) or (dest+9)
                        else
                            begin
                            if dest>h1 then
                                           takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9)
                                       else
                                           begin
                                            takes[count]:=CaptureFlag or PromoteFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+9);
                                           end;


                            end;

                   end;
                temp:=temp and NotOnly[dest];
              end;
            temp:=((BlackPawns and NohFile) shr 7) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(black,kingsq,dest+7) then
                   begin
                     inc(count);
                     inc(res);
                     piese:=WhatPiese(dest);
                     if piese=empty
                        then
                            takes[count]:=CaptureFlag or EnPassantFlag  or (pawn shl 16) or (dest shl 8) or (dest+7)
                        else
                            begin
                            if dest>h1 then
                                           takes[count]:=CaptureFlag or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7)
                                       else
                                           begin
                                            takes[count]:=CaptureFlag or PromoteFlag or (queen shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (knight shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (rook shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
                                            inc(count);
                                            takes[count]:=CaptureFlag or PromoteFlag or (bishop shl 24) or (piese shl 20) or (pawn shl 16) or (dest shl 8) or (dest+7);
                                           end;

                            end;
                   end;
                temp:=temp and NotOnly[dest];
              end;
             mask1:=(not AllPieses) and mask;
             temp:=(BlackPawns shr 8) and mask1;
             while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(black,kingsq,dest+8) then
                   begin
                     if dest>h1 then
                        begin
                         inc(count);
                         takes[count]:=(pawn shl 16) or (dest shl 8) or (dest+8);
                        end
                                else
                        begin
                          inc(count);
                          takes[count]:=PromoteFlag or (queen shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                          inc(count);
                          takes[count]:=PromoteFlag or (knight shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                          inc(count);
                          takes[count]:=PromoteFlag or (rook shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                          inc(count);
                          takes[count]:=PromoteFlag or (bishop shl 24) or (pawn shl 16) or (dest shl 8) or (dest+8);
                        end;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
            pad:=(BlackPawns shr 8) and (not AllPieses);
            temp:=((pad and Ranks[6]) shr 8) and mask1;
            while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(black,kingsq,dest+16) then
                   begin
                    inc(count);
                    takes[count]:=(pawn shl 16) or (dest shl 8) or (dest+16);
                   end;
                 temp:=temp and NotOnly[dest];
               end;
          end;
      end;
// Напоследок обновляем счетчик ходов
takes[point]:=count-point;
Result:=res;
  end;

Function Pinned(color:integer;king:integer;piesesq:integer):boolean;
// Функция возвращает true если фигура на поле piesesq связана дальнобойной фигурой
// проивоположного цвета
var
   dir:integer;
begin
  if color=white then
    begin
      dir:=direction[king,piesesq];
      if dir=0 then begin
                      Result:=false;
                      exit;
                    end;
     case abs(dir) of
       1: begin
            if (RooksFileMove(piesesq) and WhiteKing)<>0
               then begin
                      if (RooksFileMove(piesesq) and BQR)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       10: begin
            if (RooksRankMove(piesesq) and WhiteKing)<>0
               then begin
                      if (RooksRankMove(piesesq) and BQR)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       11: begin
            if (Bishopsa1Move(piesesq) and WhiteKing)<>0
               then begin
                      if (Bishopsa1Move(piesesq) and BQB)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       9: begin
            if (Bishopsh1Move(piesesq) and WhiteKing)<>0
               then begin
                      if (Bishopsh1Move(piesesq) and BQB)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       end;

    end
else
    begin
      dir:=direction[king,piesesq];
      if dir=0 then begin
                      Result:=false;
                      exit;
                    end;
     case abs(dir) of
       1: begin
            if (RooksFileMove(piesesq) and BlackKing)<>0
               then begin
                      if (RooksFileMove(piesesq) and WQR)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       10: begin
            if (RooksRankMove(piesesq) and BlackKing)<>0
               then begin
                      if (RooksRankMove(piesesq) and WQR)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       11: begin
            if (Bishopsa1Move(piesesq) and BlackKing)<>0
               then begin
                      if (Bishopsa1Move(piesesq) and WQB)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       9: begin
            if (Bishopsh1Move(piesesq) and BlackKing)<>0
               then begin
                      if (Bishopsh1Move(piesesq) and WQB)<>0
                         then Result:=true
                         else Result:=false;
                    end
               else Result:=false;
             exit;
          end;
       end;
    end;
 Result:=false;
end;

Function isMatednow(color : integer;ply: integer):boolean;
//Процедура возвращает true если сторона чья очередь хода получила мат (мат на доске)
var
   checksfrom,temp,mask,mask1,Legalmoves,pad: bitboard;
   kingSq,Chkcount,newsq,chkpiese,dest : integer;
   res : boolean;
  begin
    res:=true;
    if color=white then
      begin
        // Находим количество шахующих фигур
        kingsq:=tree[ply].Wking;
        checksfrom:=AttackedFrom(kingsq) and BlackPieses;
        chkcount:=BitCount(checksfrom);
            // Уходим королем изпод шаха (в том числе и со взятиями)
            AllPieses:=AllPieses and NotOnly[kingsq];
            AllR90:=AllR90 and NotOnlyR90[kingsq];
            AllDh1:=AllDh1 and NotOnlyDh1[kingsq];
            AllDa1:=AllDa1 and NotOnlyDa1[kingsq];
            temp:=KingsMove[kingsq] and (not WhitePieses);
            while temp<>0 do
              begin
                newsq:=BitScanForward(temp);
                if not isBlackAttacks(newsq) then
                    begin
                      Result:=false;
                      AllPieses:=AllPieses or Only[kingsq];
                      AllR90:=AllR90 or OnlyR90[kingsq];
                      AllDh1:=AllDh1 or OnlyDh1[kingsq];
                      AllDa1:=AllDa1 or OnlyDa1[kingsq];
                      exit;
                    end;
                temp:=temp and NotOnly[newsq];
              end;
            AllPieses:=AllPieses or Only[kingsq];
            AllR90:=AllR90 or OnlyR90[kingsq];
            AllDh1:=AllDh1 or OnlyDh1[kingsq];
            AllDa1:=AllDa1 or OnlyDa1[kingsq];

        if (chkcount = 1)  then
          begin
          // Если шахующая фигура одна , то пробуем побить ее (кроме как королем) или закрыться (если она не пешка и не конь)
          chkpiese:=BitScanForward(checksfrom);
          if -WhatPiese(chkpiese) in [bishop,rook,queen]
            then
                mask:=InterSect[kingsq,chkpiese] or Only[chkpiese]
            else
                mask:=Only[chkpiese];
           temp:=WhiteKnights;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=KnightsMove[newsq] and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteBishops;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=BishopsMove(newsq) and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteRooks;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=RooksMove(newsq) and mask;
                        if LegalMoves<>0 then
                          begin
                             Result:=false;
                             exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=WhiteQueens;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(white,kingsq,newsq)
                  then begin
                        LegalMoves:=(BishopsMove(newsq) or RooksMove(newsq)) and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          
            mask1:=(BlackPieses or Only[tree[ply].EnnPass]) and mask;
            if (BlackPawns and mask and (Only[tree[ply].EnnPass] shr 8))<>0
              then mask1:=mask1 or Only[tree[ply].EnnPass];
            temp:=((WhitePawns and NoaFile) shl 7) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(white,kingsq,dest-7) then
                   begin
                     Result:=false;
                     exit;
                   end;
                temp:=temp and NotOnly[dest];
              end;
            temp:=((WhitePawns and NohFile) shl 9) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(white,kingsq,dest-9) then
                   begin
                     Result:=false;
                     exit;
                   end;
                temp:=temp and NotOnly[dest];
              end;
             mask1:=(not AllPieses) and mask;
             temp:=(WhitePawns shl 8) and mask1;
             while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(white,kingsq,dest-8) then
                   begin
                     Result:=false;
                     exit;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
            pad:=(WhitePawns shl 8) and (not AllPieses);
            temp:=((pad and Ranks[3]) shl 8) and mask1;
            while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(white,kingsq,dest-16) then
                   begin
                    Result:=false;
                    exit;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
          end;
      end
else  begin
         // Находим количество шахующих фигур
        kingsq:=tree[ply].Bking;
        checksfrom:=AttackedFrom(kingsq) and WhitePieses;
        chkcount:=BitCount(checksfrom);
            // Уходим королем изпод шаха (в том числе и со взятиями)
            AllPieses:=AllPieses and NotOnly[kingsq];
            AllR90:=AllR90 and NotOnlyR90[kingsq];
            AllDh1:=AllDh1 and NotOnlyDh1[kingsq];
            AllDa1:=AllDa1 and NotOnlyDa1[kingsq];
            temp:=KingsMove[kingsq] and (not BlackPieses);
            while temp<>0 do
              begin
                newsq:=BitScanForward(temp);
                if not isWhiteAttacks(newsq) then
                    begin
                      Result:=false;
                      AllPieses:=AllPieses or Only[kingsq];
                      AllR90:=AllR90 or OnlyR90[kingsq];
                      AllDh1:=AllDh1 or OnlyDh1[kingsq];
                      AllDa1:=AllDa1 or OnlyDa1[kingsq];
                      exit;
                    end;
                temp:=temp and NotOnly[newsq];
              end;
            AllPieses:=AllPieses or Only[kingsq];
            AllR90:=AllR90 or OnlyR90[kingsq];
            AllDh1:=AllDh1 or OnlyDh1[kingsq];
            AllDa1:=AllDa1 or OnlyDa1[kingsq];

        if (chkcount = 1)  then
          begin
          // Если шахующая фигура одна , то пробуем побить ее (кроме как королем) или закрыться (если она не пешка и не конь)
          chkpiese:=BitScanForward(checksfrom);
          if WhatPiese(chkpiese) in [bishop,rook,queen]
            then
                mask:=InterSect[kingsq,chkpiese] or Only[chkpiese]
            else
                mask:=Only[chkpiese];
           temp:=BlackKnights;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=KnightsMove[newsq] and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackBishops;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=BishopsMove(newsq) and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackRooks;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=RooksMove(newsq) and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
          temp:=BlackQueens;
           while temp<>0 do
             begin
               newsq:=BitScanForward(temp);
               if not Pinned(black,kingsq,newsq)
                  then begin
                        LegalMoves:=(BishopsMove(newsq) or RooksMove(newsq)) and mask;
                        if LegalMoves<>0 then
                          begin
                            Result:=false;
                            exit;
                          end;
                       end;
               temp:=temp and NotOnly[newsq];
             end;
            mask1:=(WhitePieses or Only[tree[ply].EnnPass]) and mask;
            if (WhitePawns and mask and (Only[tree[ply].EnnPass] shl 8))<>0
              then mask1:=mask1 or Only[tree[ply].EnnPass];
              
            temp:=((BlackPawns and NoaFile) shr 9) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(black,kingsq,dest+9) then
                   begin
                     Result:=false;
                     exit;
                   end;
                temp:=temp and NotOnly[dest];
              end;
            temp:=((BlackPawns and NohFile) shr 7) and mask1;
            while temp<>0 do
              begin
                dest:=BitScanForward(temp);
                if not Pinned(black,kingsq,dest+7) then
                   begin
                     Result:=false;
                     exit;
                   end;
                temp:=temp and NotOnly[dest];
              end;
             mask1:=(not AllPieses) and mask;
             temp:=(BlackPawns shr 8) and mask1;
             while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(black,kingsq,dest+8) then
                   begin
                     Result:=false;
                     exit;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
            pad:=(BlackPawns shr 8) and (not AllPieses);
            temp:=((pad and Ranks[6]) shr 8) and mask1;
            while temp<>0 do
               begin
                 dest:=BitScanForward(temp);
                 if not Pinned(black,kingsq,dest+16) then
                   begin
                    Result:=false;
                    exit;
                   end;
                 temp:=temp and NotOnly[dest];
               end;
          end;
      end;
Result:=res;
  end;
  
end.




