unit make;
// ёнит отвечает за производство ходов на доске
interface
uses params,bitboards,attacks;

Function Makemove(color : integer;currmove :move;ply:integer):boolean;
Procedure UnMakemove(color : integer;currmove :move;ply:integer);
Procedure MakeNullMove(ply : integer);
implementation

Function Makemove(color : integer;currmove :move;ply:integer):boolean;
// ѕроизводит ход на доске возвращете true если этот ход - легальный
// ќбновл€ет инкрементальные переменные, св€занные с материалом на доске, а
// так же инкрементально обновл€ет хеш ключи.
var
    Piese,From,Dest,capture,promote,captured,Mat,Wmat,Bmat : integer;
    ClearSet,ClearSet90,ClearSeth1,ClearSeta1,Key : bitboard;
    res : boolean;
    Pkey:cardinal;
begin
    inc(nodes);
    dec(remain);
    Rule50[ply+1]:=Rule50[ply]+1;
    Key:=tree[ply].HashKey;
    Pkey:=tree[ply].PHash;
    if tree[ply].EnnPass<>0
       then key:=key xor EnPassZobr[tree[ply].EnnPass];
       
    tree[ply+1].EnnPass:=0;
    tree[ply+1].Wking:=tree[ply].Wking;
    tree[ply+1].Bking:=tree[ply].Bking;
    Piese:=(currmove shr 16) and 15;
    From:=currmove and 255;
    Dest:=(currmove shr 8) and 255;
    capture:=(currmove and Captureflag);
    tree[ply+1].Castle:=tree[ply].Castle and CastleMask[from];

    Mat:=tree[ply].MatEval;
    Wmat:=tree[ply].Wmat;
    Bmat:=tree[ply].Bmat;

    clearset:=Only[from] or Only[Dest];
    clearset90:=OnlyR90[from] or OnlyR90[dest];
    clearseth1:=OnlyDh1[from] or OnlyDh1[dest];
    clearseta1:=OnlyDa1[from] or OnlyDa1[dest];
    if (color=white) then
       begin
        // ѕереставл€ем ходившую фигуру с пол€ "откуда" на поле "куда"
        WhitePieses:=WhitePieses xor ClearSet;
        AllPieses:=AllPieses xor ClearSet;
        AllR90:=AllR90 xor ClearSet90;
        AllDh1:=AllDh1 xor ClearSeth1;
        AllDa1:=AllDa1 xor ClearSeta1;

        if piese=pawn then
                   begin
                    Rule50[ply+1]:=0;
                    WhitePawns :=WhitePawns and NotOnly[from];
                    key:=key xor WPZobr[from];
                    pkey:=pkey xor WPZobr32[from];
                    if capture<>0
                       then begin
                              if (currmove and EnPassantflag)<>0  then
                                 begin
                                   // ≈сли было вз€тие на проходе - убираем с доски черную пешку
                                   BlackPawns :=BlackPawns and NotOnly[dest-8];
                                   BlackPieses :=BlackPieses and NotOnly[dest-8];
                                   AllPieses:=AllPieses and NotOnly[dest-8];
                                   AllR90:=AllR90 and NotOnlyR90[dest-8];
                                   AllDh1:=AllDh1 and NotOnlyDh1[dest-8];
                                   AllDa1:=AllDa1 and NotOnlyDa1[dest-8];
                                   key:=key xor BPZobr[dest-8];
                                   pkey:=pkey xor BPZobr32[dest-8];
                                   capture:=0;
                                   Mat:=Mat+PawnValue;
                                 end
                            end;
                   if (currmove and Promoteflag)<>0 then
                      begin
                        promote:=(currmove shr 24) and 15;
                        Mat:=Mat-PawnValue;
                        case promote of
                            knight : begin
                                       WhiteKnights:=WhiteKnights or Only[dest];
                                       key:=key xor WNZobr[dest];
                                       Mat:=Mat+KnightValue;
                                       Wmat:=Wmat+minorshort;
                                     end;
                            bishop : begin
                                       WhiteBishops:=WhiteBishops or Only[dest];
                                       key:=key xor WBZobr[dest];
                                       WQB:=WQB or Only[dest];
                                       Mat:=Mat+BishopValue;
                                       Wmat:=Wmat+minorshort;
                                     end;
                            rook   : begin
                                       WhiteRooks:=WhiteRooks or Only[dest];
                                       key:=key xor WRZobr[dest];
                                       WQR:=WQR or Only[dest];
                                       Mat:=Mat+RookValue;
                                       Wmat:=Wmat+rookshort;
                                     end;
                            queen  : begin
                                       WhiteQueens:=WhiteQueens or Only[dest];
                                       key:=key xor WQZobr[dest];
                                       WQB:=WQB or Only[dest];
                                       WQR:=WQR or Only[dest];
                                       Mat:=Mat+QueenValue;
                                       Wmat:=Wmat+queenshort;
                                     end;
                          end;

                      end
                          else
                               begin
                               WhitePawns:=WhitePawns or Only[dest];
                               key:=key xor WPZobr[dest];
                               pkey:=pkey xor WPZobr32[dest];
                               end;
                    // ≈сли был двойной ход пешкой - устанавливаем флажок вз€ти€ на проходе
                    if dest-from=16 then
                                       begin
                                         tree[ply+1].EnnPass:=dest-8;
                                         key:=key xor EnPassZobr[dest-8];
                                       end;
                  end
        else if piese=knight then
                     begin
                       WhiteKnights:=WhiteKnights xor ClearSet;
                       key:=key xor WNZobr[from] xor WNZobr[dest];
                     end     else
             if piese=bishop then
                    begin
                       WhiteBishops:=WhiteBishops xor ClearSet;
                       key:=key xor WBZobr[from] xor WBZobr[dest];
                       WQB:=WQB xor ClearSet;
                     end     else
             if piese=rook then
                     begin
                       WhiteRooks:=WhiteRooks xor clearset;
                       key:=key xor WRZobr[from] xor WRZobr[dest];
                       WQR:=WQR xor clearset;
                     end   else
            if  piese=queen then
                     begin
                       WhiteQueens:=WhiteQueens xor clearset;
                       key:=key xor WQZobr[from]xor WQZobr[dest];
                       WQB:=WQB xor clearset;
                       WQR:=WQR xor clearset;
                     end   else
            if  piese=king then
                       begin
                       WhiteKing:=WhiteKing xor clearset;
                       key:=key xor WKZobr[from]xor WKZobr[dest];
                       tree[ply+1].Wking:=dest;
                       if (currmove and castleflag)<>0 then
                          begin
                            WCastleDid:=true;
                            if (Dest-From=2) then
                               begin
                                 WhiteRooks:=WhiteRooks and NotOnly[h1]or Only[f1];
                                 WQR:=WQR and NotOnly[h1]or Only[f1];
                                 WhitePieses:=WhitePieses and NotOnly[h1]or Only[f1];
                                 AllPieses:=AllPieses and NotOnly[h1] or Only[f1];
                                 AllR90:=AllR90 and NotOnlyR90[h1]or OnlyR90[f1];
                                 AllDh1:=AllDh1 and NotOnlyDh1[h1]or OnlyDh1[f1];
                                 AllDa1:=AllDa1 and NotOnlyDa1[h1]or OnlyDa1[f1];
                                 key:=key xor WRZobr[h1]xor WRZobr[f1];
                               end;
                            if (Dest-From=-2) then
                               begin
                                 WhiteRooks:=WhiteRooks and NotOnly[a1]or Only[d1];
                                 WQR:=WQR and NotOnly[a1]or Only[d1];
                                 WhitePieses:=WhitePieses and NotOnly[a1]or Only[d1];
                                 AllPieses:=AllPieses and NotOnly[a1]or Only[d1];
                                 AllR90:=AllR90 and NotOnlyR90[a1]or OnlyR90[d1];
                                 AllDh1:=AllDh1 and NotOnlyDh1[a1]or OnlyDh1[d1];
                                 AllDa1:=AllDa1 and NotOnlyDa1[a1]or OnlyDa1[d1];
                                 key:=key xor WRZobr[a1]xor WRZobr[d1];
                               end;

                          end;

                      end;
        // ≈сли ход - вз€тие, то ”бираем побитую фигуру с доски
        if capture<>0 then
          begin
            Rule50[ply+1]:=0;
            BlackPieses:=BlackPieses and NotOnly[dest];
            AllPieses:=AllPieses or Only[dest];
            AllR90:=AllR90 or OnlyR90[dest];
            AllDh1:=AllDh1 or OnlyDh1[dest];
            AllDa1:=AllDa1 or OnlyDa1[dest];
            captured:=(currmove shr 20) and 15;
            if captured=pawn then
                                  begin
                                  BlackPawns:=BlackPawns and NotOnly[dest];
                                  key:=key xor BPZobr[dest];
                                  pkey:=pkey xor BPZobr32[dest];
                                  Mat:=Mat+PawnValue;
                                  end
                             else
            if captured=knight then
                                  begin
                                  Blackknights:=Blackknights and NotOnly[dest];
                                  key:=key xor BNZobr[dest];
                                  Mat:=Mat+KnightValue;
                                  Bmat:=Bmat-minorshort;
                                  end
                             else
            if captured=bishop then
                                   begin
                                   Blackbishops:=Blackbishops and NotOnly[dest];
                                   key:=key xor BBZobr[dest];
                                   Mat:=Mat+BishopValue;
                                   Bmat:=Bmat-minorshort;
                                   BQB:=BQB and NotOnly[dest];
                                   end
                             else
            if captured=rook then
                                   begin
                                   Blackrooks:=Blackrooks and NotOnly[dest];
                                   key:=key xor BRZobr[dest];
                                   Mat:=Mat+RookValue;
                                   Bmat:=Bmat-rookshort;
                                   BQR:=BQR and NotOnly[dest];
                                   end
                             else
                                   begin
                                   Blackqueens:=Blackqueens and NotOnly[dest];
                                   key:=key xor BQZobr[dest];
                                   Mat:=Mat+QueenValue;
                                   Bmat:=Bmat-queenshort;
                                   BQB:=BQB and NotOnly[dest];
                                   BQR:=BQR and NotOnly[dest];
                                   end;

          end;
          res:=not isBlackAttacks(tree[ply+1].wking)


       end
else begin
       // ѕереставл€ем ходившую фигуру с пол€ "откуда" на поле "куда"
        BlackPieses:=BlackPieses xor clearset;
        AllPieses:=AllPieses xor ClearSet;
        AllR90:=AllR90 xor ClearSet90;
        AllDh1:=AllDh1 xor ClearSeth1;
        AllDa1:=AllDa1 xor ClearSeta1;
        if piese=pawn then
                begin
                    Rule50[ply+1]:=0;
                    BlackPawns :=BlackPawns and NotOnly[from];
                    key:=key xor BPZobr[from];
                    pkey:=pkey xor BPZobr32[from];
                    if capture<>0
                       then begin
                              if (currmove and EnPassantflag)<>0  then
                                 begin
                                   // ≈сли было вз€тие на проходе - убираем с доски белую пешку
                                   WhitePawns :=WhitePawns and NotOnly[dest+8];
                                   WhitePieses :=WhitePieses and NotOnly[dest+8];
                                   key:=key xor WPZobr[dest+8];
                                   pkey:=pkey xor WPZobr32[dest+8];
                                   AllPieses:=AllPieses and NotOnly[dest+8];
                                   AllR90:=AllR90 and NotOnlyR90[dest+8];
                                   AllDh1:=AllDh1 and NotOnlyDh1[dest+8];
                                   AllDa1:=AllDa1 and NotOnlyDa1[dest+8];
                                   capture:=0;
                                   Mat:=Mat-PawnValue;
                                 end
                            end;
                   if (currmove and Promoteflag)<>0 then
                      begin
                        Mat:=Mat+PawnValue;
                        promote:=(currmove shr 24) and 15;
                        case promote of
                            knight : begin
                                       BlackKnights:=BlackKnights or Only[dest];
                                       key:=key xor BNZobr[dest];
                                       Mat:=Mat-KnightValue;
                                       Bmat:=Bmat+minorshort;
                                     end;
                            bishop : begin
                                       BlackBishops:=BlackBishops or Only[dest];
                                       key:=key xor BBZobr[dest];
                                       Mat:=Mat-BishopValue;
                                       Bmat:=Bmat+minorshort;
                                       BQB:=BQB or Only[dest];
                                     end;
                            rook   : begin
                                       BlackRooks:=BlackRooks or Only[dest];
                                       key:=key xor BRZobr[dest];
                                       Mat:=Mat-RookValue;
                                       Bmat:=Bmat+rookshort;
                                       BQR:=BQR or Only[dest];
                                     end;
                            queen  : begin
                                       BlackQueens:=BlackQueens or Only[dest];
                                       key:=key xor BQZobr[dest];
                                       Mat:=Mat-QueenValue;
                                       Bmat:=Bmat+queenshort;
                                       BQB:=BQB or Only[dest];
                                       BQR:=BQR or Only[dest];
                                     end;
                          end;

                      end
                          else
                               begin
                                 BlackPawns:=BlackPawns or Only[dest];
                                 key:=key xor BPZobr[dest];
                                 pkey:=pkey xor BPZobr32[dest];
                               end;
                    // ≈сли был двойной ход пешкой - устанавливаем флажок вз€ти€ на проходе
                    if from-dest=16 then
                                        begin
                                         tree[ply+1].EnnPass:=dest+8;
                                         key:=key xor EnPassZobr[dest+8];
                                        end;
                  end
      else  if piese=knight then
                     begin
                       BlackKnights:=BlackKnights xor clearset;
                       key:=key xor BNZobr[from]xor BNZobr[dest];
                     end
      else  if piese=bishop then
                     begin
                       BlackBishops:=BlackBishops xor clearset;
                       key:=key xor BBZobr[from] xor BBZobr[dest];
                       BQB:=BQB xor clearset;
                     end
      else  if piese=rook then
                     begin
                       //writeln(from);
                       BlackRooks:=BlackRooks xor clearset;
                       key:=key xor BRZobr[from] xor BRZobr[dest];
                       BQR:=BQR xor clearset;
                     end
      else  if piese=queen then
                     begin
                       BlackQueens:=BlackQueens xor clearset;
                       key:=key xor BQZobr[from] xor BQZobr[dest];
                       BQB:=BQB xor clearset;
                       BQR:=BQR xor clearset;
                     end

      else  if piese=king then
                    begin
                       BlackKing:=BlackKing xor clearset;
                       key:=key xor BKZobr[from] xor BKZobr[dest];
                       tree[ply+1].Bking:=dest;
                       if (currmove and castleflag)<>0 then
                          begin
                            BCastleDid:=true;
                            if (Dest-From=2) then
                               begin
                                 BlackRooks:=BlackRooks and NotOnly[h8]or Only[f8];
                                 BQR:=BQR and NotOnly[h8]or Only[f8];
                                 BlackPieses:=BlackPieses and NotOnly[h8]or Only[f8];
                                 AllPieses:=AllPieses and NotOnly[h8]or Only[f8];
                                 AllR90:=AllR90 and NotOnlyR90[h8]or OnlyR90[f8];
                                 AllDh1:=AllDh1 and NotOnlyDh1[h8]or OnlyDh1[f8];
                                 AllDa1:=AllDa1 and NotOnlyDa1[h8]or OnlyDa1[f8];
                                 key:=key xor BRZobr[h8]xor BRZobr[f8];
                               end;
                            if (Dest-From=-2) then
                               begin
                                 BlackRooks:=BlackRooks and NotOnly[a8]or Only[d8];
                                 key:=key xor BRZobr[a8] xor BRZobr[d8];
                                 BQR:=BQR and NotOnly[a8]or Only[d8];
                                 BlackPieses:=BlackPieses and NotOnly[a8]or Only[d8];
                                 AllPieses:=AllPieses and NotOnly[a8]or Only[d8];
                                 AllR90:=AllR90 and NotOnlyR90[a8]or OnlyR90[d8];
                                 AllDh1:=AllDh1 and NotOnlyDh1[a8]or OnlyDh1[d8];
                                 AllDa1:=AllDa1 and NotOnlyDa1[a8]or OnlyDa1[d8];
                               end;

                          end;
                     end;

        // ≈сли ход - вз€тие, то ”бираем побитую фигуру с доски
        if capture<>0 then
          begin
            Rule50[ply+1]:=0;
            WhitePieses:=WhitePieses and NotOnly[dest];
            AllPieses:=AllPieses or Only[dest];
            AllR90:=AllR90 or OnlyR90[dest];
            AllDh1:=AllDh1 or OnlyDh1[dest];
            AllDa1:=AllDa1 or OnlyDa1[dest];
            captured:=(currmove shr 20) and 15;
            if captured=pawn then
                                  begin
                                  WhitePawns:=WhitePawns and NotOnly[dest];
                                  key:=key xor WPZobr[dest];
                                  pkey:=pkey xor WPZobr32[dest];
                                  Mat:=Mat-PawnValue;
                                  end
                             else
            if captured=knight then
                                  begin
                                  Whiteknights:=Whiteknights and NotOnly[dest];
                                  key:=key xor WNZobr[dest];
                                  Mat:=Mat-KnightValue;
                                  Wmat:=Wmat-minorshort;
                                  end
                             else
            if captured=bishop then
                                   begin
                                   Whitebishops:=Whitebishops and NotOnly[dest];
                                   key:=key xor WBZobr[dest];
                                   Mat:=Mat-BishopValue;
                                   Wmat:=Wmat-minorshort;
                                   WQB:=WQB and NotOnly[dest];
                                   end
                             else
            if captured=rook then
                                   begin
                                   Whiterooks:=Whiterooks and NotOnly[dest];
                                   key:=key xor WRZobr[dest];
                                   Mat:=Mat-RookValue;
                                   Wmat:=Wmat-rookshort;
                                   WQR:=WQR and NotOnly[dest];
                                   end
                             else
                                   begin
                                   Whitequeens:=Whitequeens and NotOnly[dest];
                                   key:=key xor WQZobr[dest];
                                   Mat:=Mat-QueenValue;
                                   Wmat:=Wmat-queenshort;
                                   WQB:=WQB and NotOnly[dest];
                                   WQR:=WQR and NotOnly[dest];
                                   end;

          end;
        res:=not isWhiteAttacks(tree[ply+1].bking)
     end;
  tree[ply+1].MatEval:=Mat;
  tree[ply+1].Wmat:=Wmat;
  tree[ply+1].Bmat:=Bmat;
  tree[ply+1].PHash:=pkey;
  tree[ply+1].HashKey:=key xor ZColor;   
  Result:=res;
end;

Procedure UnMakemove(color : integer;currmove :move;ply:integer);
// ѕроцедура делает "ход назад" на доске.

var
    Piese,From,Dest,capture,promote,captured : integer;
    ClearSet,ClearSet90,ClearSeth1,ClearSeta1 : bitboard;
begin
    Piese:=(currmove shr 16) and 15;
    From:=currmove and 255;
    Dest:=(currmove shr 8) and 255;
    capture:=(currmove and Captureflag);
    clearset:=Only[from] or Only[Dest];
    clearset90:=OnlyR90[from] or OnlyR90[dest];
    clearseth1:=OnlyDh1[from] or OnlyDh1[dest];
    clearseta1:=OnlyDa1[from] or OnlyDa1[dest];
    if (color=white) then
       begin
        // ѕереставл€ем ходившую фигуру с пол€ "куда" на поле "откуда"
        WhitePieses:=WhitePieses xor ClearSet;
        AllPieses:=AllPieses xor ClearSet;
        AllR90:=AllR90 xor ClearSet90;
        AllDh1:=AllDh1 xor ClearSeth1;
        AllDa1:=AllDa1 xor ClearSeta1;

        if piese=pawn then
                   begin
                    WhitePawns :=WhitePawns or Only[from];
                    if capture<>0
                       then begin
                              if (currmove and EnPassantflag)<>0  then
                                 begin
                                   // ≈сли было вз€тие на проходе - ставим на доску черную пешку
                                   BlackPawns :=BlackPawns or Only[dest-8];
                                   BlackPieses :=BlackPieses or Only[dest-8];
                                   AllPieses:=AllPieses or Only[dest-8];
                                   AllR90:=AllR90 or OnlyR90[dest-8];
                                   AllDh1:=AllDh1 or OnlyDh1[dest-8];
                                   AllDa1:=AllDa1 or OnlyDa1[dest-8];
                                   capture:=0;
                                 end
                            end;
                   if (currmove and Promoteflag)<>0 then
                      begin
                        promote:=(currmove shr 24) and 15;
                        case promote of
                            knight : begin
                                       WhiteKnights:=WhiteKnights and NotOnly[dest];
                                     end;
                            bishop : begin
                                       WhiteBishops:=WhiteBishops and NotOnly[dest];
                                       WQB:=WQB and NotOnly[dest];
                                     end;
                            rook   : begin
                                       WhiteRooks:=WhiteRooks and NotOnly[dest];
                                       WQR:=WQR and NotOnly[dest];
                                     end;
                            queen  : begin
                                       WhiteQueens:=WhiteQueens and NotOnly[dest];
                                       WQB:=WQB and NotOnly[dest];
                                       WQR:=WQR and NotOnly[dest];
                                     end;
                          end;

                      end
                          else WhitePawns:=WhitePawns and NotOnly[dest];
                  end
        else if piese=knight then
                     begin
                       WhiteKnights:=WhiteKnights xor ClearSet;
                     end     else
             if piese=bishop then
                    begin
                       WhiteBishops:=WhiteBishops xor ClearSet;
                       WQB:=WQB xor ClearSet;
                     end     else
             if piese=rook then
                     begin
                       WhiteRooks:=WhiteRooks xor ClearSet;
                       WQR:=WQR xor ClearSet;
                     end   else
            if  piese=queen then
                     begin
                       WhiteQueens:=WhiteQueens xor ClearSet;
                       WQB:=WQB xor ClearSet;
                       WQR:=WQR xor ClearSet;
                     end   else
            if  piese=king then
                       begin
                       WhiteKing:=WhiteKing xor ClearSet;
                       if (currmove and castleflag)<>0 then
                          begin
                            WCastleDid:=false;
                            if (Dest-From=2) then
                               begin
                                 WhiteRooks:=WhiteRooks and NotOnly[f1]or Only[h1];
                                 WQR:=WQR and NotOnly[f1]or Only[h1];
                                 WhitePieses:=WhitePieses and NotOnly[f1]or Only[h1];
                                 AllPieses:=AllPieses and NotOnly[f1]or Only[h1];
                                 AllR90:=AllR90 and NotOnlyR90[f1]or OnlyR90[h1];
                                 AllDh1:=AllDh1 and NotOnlyDh1[f1]or OnlyDh1[h1];
                                 AllDa1:=AllDa1 and NotOnlyDa1[f1]or OnlyDa1[h1];

                               end;
                            if (Dest-From=-2) then
                               begin
                                 WhiteRooks:=WhiteRooks and NotOnly[d1]or Only[a1];
                                 WQR:=WQR and NotOnly[d1]or Only[a1];
                                 WhitePieses:=WhitePieses and NotOnly[d1]or Only[a1];
                                 AllPieses:=AllPieses and NotOnly[d1]or Only[a1];
                                 AllR90:=AllR90 and NotOnlyR90[d1]or OnlyR90[a1];
                                 AllDh1:=AllDh1 and NotOnlyDh1[d1]or OnlyDh1[a1];
                                 AllDa1:=AllDa1 and NotOnlyDa1[d1]or OnlyDa1[a1];
                               end;

                          end;
                    
                      end;
        // ≈сли ход - вз€тие, то ставим побитую фигуру на доску
        if capture<>0 then
          begin
            BlackPieses:=BlackPieses or Only[dest];
            AllPieses:=AllPieses or Only[dest];
            AllR90:=AllR90 or OnlyR90[dest];
            AllDh1:=AllDh1 or OnlyDh1[dest];
            AllDa1:=AllDa1 or OnlyDa1[dest];
            captured:=(currmove shr 20) and 15;
            if captured=pawn then
                                  BlackPawns:=BlackPawns or Only[dest]
                             else
            if captured=knight then
                                  Blackknights:=Blackknights or Only[dest]
                             else
            if captured=bishop then
                                   begin
                                   Blackbishops:=Blackbishops or Only[dest];
                                   BQB:=BQB or Only[dest];
                                   end
                             else
            if captured=rook then
                                   begin
                                   Blackrooks:=Blackrooks or Only[dest];
                                   BQR:=BQR or Only[dest];
                                   end

                             else
                                   begin
                                   Blackqueens:=Blackqueens or Only[dest];
                                   BQB:=BQB or Only[dest];
                                   BQR:=BQR or Only[dest];
                                   end;

          end;

       end
else begin
       // ѕереставл€ем ходившую фигуру с пол€ "откуда" на поле "куда"
        BlackPieses:=BlackPieses and NotOnly[dest] or Only[from];
        AllPieses:=AllPieses xor ClearSet;
        AllR90:=AllR90 xor ClearSet90;
        AllDh1:=AllDh1 xor ClearSeth1;
        AllDa1:=AllDa1 xor ClearSeta1;
        if piese=pawn then
                begin
                    BlackPawns :=BlackPawns or Only[from];
                    if capture<>0
                       then begin
                              if (currmove and EnPassantflag)<>0  then
                                 begin
                                   // ≈сли было вз€тие на проходе - убираем с доски белую пешку
                                   WhitePawns :=WhitePawns or Only[dest+8];
                                   WhitePieses :=WhitePieses or Only[dest+8];
                                   AllPieses:=AllPieses or Only[dest+8];
                                   AllR90:=AllR90 or OnlyR90[dest+8];
                                   AllDh1:=AllDh1 or OnlyDh1[dest+8];
                                   AllDa1:=AllDa1 or OnlyDa1[dest+8];
                                   capture:=0;
                                 end
                            end;
                   if (currmove and Promoteflag)<>0 then
                      begin
                        promote:=(currmove shr 24) and 15;
                        case promote of
                            knight : begin
                                       BlackKnights:=BlackKnights and NotOnly[dest];
                                     end;
                            bishop : begin
                                       BlackBishops:=BlackBishops and NotOnly[dest];
                                       BQB:=BQB and NotOnly[dest];
                                     end;
                            rook   : begin
                                       BlackRooks:=BlackRooks and NotOnly[dest];
                                       BQR:=BQR and NotOnly[dest];
                                     end;
                            queen  : begin
                                       BlackQueens:=BlackQueens and NotOnly[dest];
                                       BQB:=BQB and NotOnly[dest];
                                       BQR:=BQR and NotOnly[dest];
                                     end;
                          end;

                      end
                          else BlackPawns:=BlackPawns and NotOnly[dest];
                  end
      else  if piese=knight then
                     begin
                       BlackKnights:=BlackKnights xor ClearSet;
                     end
      else  if piese=bishop then
                     begin
                       BlackBishops:=BlackBishops xor ClearSet;
                       BQB:=BQB xor ClearSet;
                     end
      else  if piese=rook then
                     begin
                       BlackRooks:=BlackRooks xor ClearSet;
                       BQR:=BQR xor ClearSet;
                     end
      else  if piese=queen then
                     begin
                       BlackQueens:=BlackQueens xor ClearSet;
                       BQB:=BQB xor ClearSet;
                       BQR:=BQR xor ClearSet;
                     end
                          else
             if  piese=king then
                    begin
                       BlackKing:=BlackKing xor ClearSet;
                       if (currmove and castleflag)<>0 then
                          begin
                            BCastleDid:=false;
                            if (Dest-From=2) then
                               begin
                                 BlackRooks:=BlackRooks and NotOnly[f8]or Only[h8];
                                 BQR:=BQR and NotOnly[f8]or Only[h8];
                                 BlackPieses:=BlackPieses and NotOnly[f8]or Only[h8];
                                 AllPieses:=AllPieses and NotOnly[f8]or Only[h8];
                                 AllR90:=AllR90 and NotOnlyR90[f8]or OnlyR90[h8];
                                 AllDh1:=AllDh1 and NotOnlyDh1[f8]or OnlyDh1[h8];
                                 AllDa1:=AllDa1 and NotOnlyDa1[f8]or OnlyDa1[h8];
                               end;
                            if (Dest-From=-2) then
                               begin
                                 BlackRooks:=BlackRooks and NotOnly[d8]or Only[a8];
                                 BQR:=BQR and NotOnly[d8]or Only[a8];
                                 BlackPieses:=BlackPieses and NotOnly[d8]or Only[a8];
                                 AllPieses:=AllPieses and NotOnly[d8]or Only[a8];
                                 AllR90:=AllR90 and NotOnlyR90[d8]or OnlyR90[a8];
                                 AllDh1:=AllDh1 and NotOnlyDh1[d8]or OnlyDh1[a8];
                                 AllDa1:=AllDa1 and NotOnlyDa1[d8]or OnlyDa1[a8];
                               end;

                          end;
                     end;

        // ≈сли ход - вз€тие, то ставим побитую фигуру на доску
        if capture<>0 then
          begin
            WhitePieses:=WhitePieses or Only[dest];
            AllPieses:=AllPieses or Only[dest];
            AllR90:=AllR90 or OnlyR90[dest];
            AllDh1:=AllDh1 or OnlyDh1[dest];
            AllDa1:=AllDa1 or OnlyDa1[dest];
            captured:=(currmove shr 20) and 15;
            if captured=pawn then
                                  WhitePawns:=WhitePawns or Only[dest]
                             else
            if captured=knight then
                                  Whiteknights:=Whiteknights or Only[dest]
                             else
            if captured=bishop then
                                   begin
                                   Whitebishops:=Whitebishops or Only[dest];
                                   WQB:=WQB or Only[dest];
                                   end
                             else
            if captured=rook then
                                   begin
                                   Whiterooks:=Whiterooks or Only[dest];
                                   WQR:=WQR or Only[dest];
                                   end
             else
                                   begin
                                   Whitequeens:=Whitequeens or Only[dest];
                                   WQB:=WQB or Only[dest];
                                   WQR:=WQR or Only[dest];
                                   end;
          end;
     end;
end;
Procedure MakeNullMove(ply : integer);
begin
inc(nodes);
dec(remain);
tree[ply+1]:=tree[ply];
tree[ply+1].EnnPass:=0;
tree[ply+1].HashKey:=tree[ply+1].Hashkey xor ZColor;
if tree[ply].EnnPass<>0 then tree[ply+1].HashKey:=tree[ply+1].Hashkey xor EnPassZobr[tree[ply].EnnPass];
Rule50[ply+1]:=Rule50[ply]+1;
end;

end.





