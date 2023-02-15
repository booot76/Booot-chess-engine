unit x;
// Юнит содержит функции, осуществляющие связь с Xboard протоколом.
interface
uses params,bitboards,preeval,hash,attacks,perft,make,search,book,egtb,eval,SysUtils;

Procedure SetBoard(FEN:string);
Procedure Recognize(var inp:AnsiString);
Procedure NewGame;
Procedure ReadConfig;
Function parse(var inp:AnsiString;pos:integer):string;
Procedure backundo(color:integer);
Procedure getundo(N:integer);
implementation
uses epd,history;
Procedure SetBoard(FEN:string);
// Устанавливает позицию на доске с помощью FEN строки
label l1,l2;
var
   i,j,CurrRank,CurrSquare:byte;
   Point : array[1..8] of byte;
   d:bitboard;

begin
  WhitePawns:=0;WhiteKnights:=0;WhiteBishops:=0;WhiteRooks:=0;WhiteQueens:=0;WhiteKing:=0;
  BlackPawns:=0;BlackKnights:=0;BlackBishops:=0;BlackRooks:=0;BlackQueens:=0;BlackKing:=0;
  AllPieses:=0;AllR90:=0;AllDh1:=0;AllDa1:=0;WQB:=0;BQB:=0;WQR:=0;BQR:=0;
  tree[1].Castle:=0;
  tree[1].EnnPass:=0;
  Point[8]:=56;Point[7]:=48;Point[6]:=40;Point[5]:=32;
  Point[4]:=24;Point[3]:=16;Point[2]:=8;Point[1]:=0;
  CurrRank:=8;
  CurrSquare:=Point[CurrRank];
  SideToMove:=White;
 // Устанавливаем положение на доске
  For i:=1 to Length(FEN) do
   begin
    if CurrRank=0 then break;
    if FEN[i]<>' '
     then begin
           if (FEN[i]>='1') and (FEN[i]<='8')
              then begin
                   // Пропускаем пустые поля на доске
                   CurrSquare:=CurrSquare+StrToInt(FEN[i]);
                   if CurrSquare=8 then
                   goto l2;
                   end
              else
           case FEN[i] of
           '/' : begin
                 dec(CurrRank);
                 CurrSquare:=Point[CurrRank];
                 end;
           'P' : begin
                 SetBitInBitBoard(WhitePawns,CurrSquare);
                 inc(CurrSquare);
                 end;
           'N' : begin
                 SetBitInBitBoard(WhiteKnights,CurrSquare);
                 inc(CurrSquare);
                 end;
           'B' : begin
                 SetBitInBitBoard(WhiteBishops,CurrSquare);
                 inc(CurrSquare);
                 end;
           'R' : begin
                 SetBitInBitBoard(WhiteRooks,CurrSquare);
                 inc(CurrSquare);
                 end;
           'Q' : begin
                 SetBitInBitBoard(WhiteQueens,CurrSquare);
                 inc(CurrSquare);
                 end;
           'K' : begin
                 SetBitInBitBoard(WhiteKing,CurrSquare);
                 tree[1].Wking:=CurrSquare;
                 inc(CurrSquare);
                 end;
           'p' : begin
                 SetBitInBitBoard(BlackPawns,CurrSquare);
                 inc(CurrSquare);
                 end;
           'n' : begin
                 SetBitInBitBoard(BlackKnights,CurrSquare);
                 inc(CurrSquare);
                 end;
           'b' : begin
                 SetBitInBitBoard(BlackBishops,CurrSquare);
                 inc(CurrSquare);
                 end;
           'r' : begin
                 SetBitInBitBoard(BlackRooks,CurrSquare);
                 inc(CurrSquare);
                 end;
           'q' : begin
                 SetBitInBitBoard(BlackQueens,CurrSquare);
                 inc(CurrSquare);
                 end;
           'k' : begin
                 SetBitInBitBoard(BlackKing,CurrSquare);
                 tree[1].Bking:=CurrSquare;
                 inc(CurrSquare);
                 end;
           end;
           if (CurrSquare=8) and (CurrRank=1) then
                           goto l2;
          end;
   end;
   // Очередь хода
l2:
   if  (FEN[i]='w') then SideToMove:=white else
   if  (FEN[i+1]='w') then
      begin
      SideToMove:=white;
      inc(i);
      end
      else
   if  (FEN[i+2]='w') then
      begin
      SideToMove:=white;
      i:=i+2;
      end
      else
   if  (FEN[i]='b')   then SideToMove:=black else
   if  (FEN[i+1]='b')   then
       begin
       SideToMove:=black;
       inc(i);
       end
       else
   if  (FEN[i+2]='b')   then
      begin
      SideToMove:=black;
      i:=i+2;
      end
      else goto l1;

   for j:=i+1 to Length(FEN) do
    begin
     if FEN[j]='K' then tree[1].Castle:=tree[1].Castle or 1;
     if FEN[j]='Q' then tree[1].Castle:=tree[1].Castle or 2;
     if FEN[j]='k' then tree[1].Castle:=tree[1].Castle or 4;
     if FEN[j]='q' then tree[1].Castle:=tree[1].Castle or 8;
     if FEN[j] in ['a','b','c','d','e','f','g','h'] then
        tree[1].EnnPass:=StrToField(FEN[j]+FEN[j+1]);
    end;
l1:
WhitePieses:=Whitepawns or WhiteKnights or WhiteBishops or WhiteRooks or WhiteQueens or Whiteking;
WQR:=WhiteQueens or WhiteRooks;
WQB:=WhiteQueens or WhiteBishops;
BQB:=BlackQueens or BlackBishops;
BQR:=BlackQueens or BlackRooks;
BlackPieses:=Blackpawns or BlackKnights or BlackBishops or BlackRooks or BlackQueens or Blackking;
AllPieses:=WhitePieses or BlackPieses;
tree[1].Wmat:=CalcMatShort(white);
tree[1].Bmat:=CalcMatShort(black);
tree[1].MatEval:=CalcMat;
tree[1].HashKey:=GetHashKey(SideToMove,0);
tree[1].PHash:=GetPawnKey;
Rule50[1]:=0;
HashGame[0]:=tree[1].HashKey;
d:=AllPieses;
while d<>0 do
 begin
   i:=BitScanForward(d);
   AllR90:=AllR90 or OnlyR90[i];
   AllDh1:=AllDh1 or OnlyDh1[i];
   AllDa1:=AllDa1 or OnlyDa1[i];
   d:=d and NotOnly[i];
 end;
if SideToMove = white
   then
       tree[1].onCheck:=isBlackAttacks(tree[1].wking)
   else
       tree[1].onCheck:=isWhiteAttacks(tree[1].bking);
MovesToControl:=timer.NumberMoves;
usebook:=false;
undocount:=-1;
backundo(SideToMove);
ClearMemory;
end;

Procedure Recognize(var inp:AnsiString);
// Процедура распознает введенную команду и принимает решение, что с ней делать
var
   command,first,second,third,min,sek,stmove:string;
   last : string[100];
   i,probel,limit,color:integer;
   field1,field2:byte;
   move,Promo:integer;
   d:int64;
begin
  Promo:=QueenValue;
  if inp<>''
     then begin
           MoveNow:=false;
           command:='';
           probel:=pos(' ',inp);
           if probel=0
             // Команда - сплошная (go,force, и т.д)
             then command:=inp
             else
                 for i:=1 to probel-1 do
                  command:=command+inp[i];
   // Распознаем введенную команду:
             if (command='epdtest') and (not XBoardMode)                         //epdtest
                  then
                    begin
                    // Запускаем тест
                    first:='';second:='';
                   i:=probel+1;
                    while inp[i]<>' ' do
                     begin
                      first:=first+inp[i];
                      inc(i);
                     end;
                    inc(i);
                    while (inp[i]<>' ') and (length(inp)>=i) do
                     begin
                      second:=second+inp[i];
                      inc(i);
                     end;
                    EpdTest(first,strtoint(second));
                    end
else
          if (command='eval')  then
            begin
             LPrint('Evaluation  '+IntToStr(Evaluate(white,1,-Mate,Mate,1)));                                                                   // eval
            end
               else
             if (command='help') and (not XBoardMode)                           //help
                  then
                    begin
                    // Печатаем короткий хелп
                    LPrint('          help                                  - this screen');
                    LPrint('          xboard                                - xboard mode');
                    LPrint('          setboard <FEN>                        - set pieses on board');
                    LPrint('          perft <N>                             - calculate perfomance');
                    LPrint('          epdtest <filename.epd> <time on move> - Run test suite');
                    end


else
              if (command='setboard')                                           //setboard
                  then
                    begin
                    //Устанавливаем позицию
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                    SetBoard(last);
                    usebook:=false;
                    end
else
             if (command='perft') and (not XBoardMode)                          //perft
                  then
                    begin
                    // Запускаем перфоманс тест
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                    Perfomance(sidetomove,strtoint(last));
                    end
else
             if (command='xboard') and (not XBoardMode)                         //xboard
                  then
                    begin
                    // Переводим движок в режим xboard.
                    XBoardMode:=true;
                    LPrint(' ');
                    end
else        if (command='uci') or (command='Uci') or (command='UCI')
                 then
                   begin
                     UCImode:=true;
                     XboardMode:=false;
                     LPrint('id name Booot 4.15.1');
                     LPrint('id author Alex Morozov');
                     LPrint('option name Hash type spin default  32 min 1 max 256');
                     LPrint('option name Phash type spin default 4 min 1 max 8');
                     LPrint('option name boootegtbpath type string default \');
                     SetLength(WhiteTable,0);
                     SetLength(BlackTable,0);
                     SetLength(WhiteTable,131073);
                     SetLength(BlackTable,131073);
                     SetLength(PTable,0);
                     SetLength(PTable,262145);
                     HashSize:=131072;
                     PHashSize:=262144;
                     HashMask:=131071;
                     PHashMask:=262143;
                     egtbpath:='\';
                     LPrint('uciok');
                   end
else
             if (command='isready') and (UCImode)                                 //isready
                  then
                    begin
                    LPrint('readyok');
                    end
else
             if (command='setoption') and (UCImode)                                 //setoption
                  then
                    begin
                      first:=parse(inp,probel+1);
                      probel:=probel+length(first)+1;
                      if (first='name') then
                        begin
                         first:=parse(inp,probel+1);
                         probel:=probel+length(first)+1;
                         if (first='Hash') or (first='hash') then
                           begin
                             first:=parse(inp,probel+1);
                             probel:=probel+length(first)+1;
                             if first='value' then
                                begin
                                  first:=parse(inp,probel+1);
                                  HashSize:=strtoint(first)*4096;
                                  SetLength(WhiteTable,0);
                                  SetLength(BlackTable,0);
                                  SetLength(WhiteTable,HashSize+1);
                                  SetLength(BlackTable,HashSize+1);
                                  HashMask:=HashSize-1;
                                end;
                           end else
                         if (first='Phash') or (first='PHash') then
                           begin
                             first:=parse(inp,probel+1);
                             probel:=probel+length(first)+1;
                             if first='value' then
                                begin
                                  first:=parse(inp,probel+1);
                                  PHashSize:=strtoint(first)*65536;
                                  SetLength(PTable,0);
                                  SetLength(PTable,PHashSize+1);
                                  PHashMask:=PHashSize-1;
                                end;
                           end else
                         if first='boootegtbpath' then
                           begin
                             first:=parse(inp,probel+1);
                             probel:=probel+length(first)+1;
                             if first='value' then
                                begin
                                  first:=parse(inp,probel+1);
                                  egtbpath:=first;
                                end;
                           end;
                        end;
                    end
else
             if (command='position') and (UCImode)                                 //position
                  then
                    begin
                     first:=parse(inp,probel+1);
                     probel:=probel+length(first)+1;
                     if first='startpos' then NewGame
                        else begin
                              // иначе там слово 'fen'
                              limit:=pos('moves',inp);
                              if limit=0 then limit:=length(inp)
                                          else limit:=limit-2;
                              first:='';
                              for i:=probel+1 to limit do
                                first:=first+inp[i];
                              NewGame;
                              usebook:=false;
                              SetBoard(first);
                             end;
                    // Теперь производим требуемые  ходы из позиции
                     limit:=pos('moves',inp);
                     if limit>0 then
                        begin
                          probel:=limit+5;
                          command:=parse(inp,probel+1);
                          probel:=probel+length(command)+1;
                          while (length(command)>0) do
                           begin
                          if (length(command)<=5)
                              then
                           begin
                            if  (command[1] in ['a','b','c','d','e','f','g','h'])
                            and (command[2] in ['1','2','3','4','5','6','7','8']) then
                               begin
                                stmove:=command[1]+command[2];
                                field1:=StrToField(stmove);
                                stmove:=command[3]+command[4];
                                field2:=StrToField(stmove);
                                move:=(abs(WhatPiese(field2)) shl 20) or (abs(WhatPiese(field1)) shl 16)or (field2 shl 8) or field1;
                                if WhatPiese(field2)<>Empty then move:=move or Captureflag;
                                if (abs(WhatPiese(field1))=king) and (abs(field2-field1)=2)
                                    then
                                         move:=move or CastleFlag;
                                if (abs(WhatPiese(field1))=pawn) and (WhatPiese(field2)=empty) and (abs(field2-field1)in [7,9])
                                   then move:=move or CaptureFlag or EnPassantFlag;
                                if length(command)=4
                                      then Promo:=Queen
                                      else begin
                                   case command[5] of
                                     'Q'  :  Promo:=Queen;
                                     'q'  :  Promo:=Queen;
                                     'R'  :  Promo:=Rook;
                                     'r'  :  Promo:=Rook;
                                     'N'  :  Promo:=Knight;
                                     'n'  :  Promo:=Knight;
                                     'B'  :  Promo:=Bishop;
                                     'b'  :  Promo:=Bishop;
                                  end;
                                          end;
                     if (abs(WhatPiese(field1))=pawn) and ((field2>h7) or (field2<a2)) then
                       move:=move or Promoteflag or (promo shl 24);
                    MakeMove(sidetomove,move,1);
                    Notation[notc]:=move and 16383;
                    inc(notc);
                    tree[1]:=tree[2];
                    Rule50[1]:=Rule50[2];
                    HashGame[Rule50[1]]:=tree[1].HashKey;
                    SideToMove:=SideToMove xor 1;
                    if SideToMove = white
                               then
                                   tree[1].onCheck:=isBlackAttacks(tree[1].wking)
                               else
                                   tree[1].onCheck:=isWhiteAttacks(tree[1].bking);

                   end;
                   end;
                   command:=parse(inp,probel+1);
                   probel:=probel+length(command)+1;
                   end;
                   end;
                    end
else        if (command='protover') and (XBoardMode)                            //protover
                  then
                    begin
                    //Даем список поддерживаемых фич протокола 2
                    LPrint('feature setboard=1');
                    LPrint('feature ping=1');
                    LPrint('feature myname="Booot 4.15.1"');
                    LPrint('feature done=1');
                    end
else        if (command='ping') and (XBoardMode)                                //ping
                  then
                    begin
                    //Даем отклик
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                    LPrint('pong '+last);
                    end
else        if (command='new') and (XBoardMode)                                 //new
                  then
                    begin
                    //Расставляем фигуры на доске
                    NewGame;
                    end
else        if (command='edit') and (XBoardMode)                                //edit
                  then
                    begin
                    //Переходим в режим ввода позиции
                    EditMode:=true;
                    EditColor:=white;
                    usebook:=false;
                    end
else        if (command='undo')
                 then
                   begin
                     if undocount>=0 then
                       begin
                         getundo(1);
                       end;
                   end
else        if (command='remove')
                 then
                   begin
                     if undocount>=1 then
                       begin
                         getundo(2);
                       end;
                   end
else        if (command='quit')                                                 //quit
                  then
                    begin
                    //Подготавливаем флаг немедленного выхода из программы
                    MoveNow:=true;ForceMode:=false;
                    ExitNow:=true;
                    end
else        if (command='random') or (command='otim') or (command='?')          //игнорируемые команды
               or (command='draw') or (command='result')or (command='accepted')
               or (command='easy') or (command='hard') or (command='stop')
                  then
                    //Просто игнорим команду
else        if (command='force')and (XBoardMode)                                 //force
                  then
                   begin
                    //Режим force
                    ForceMode:=true;
                    MoveNow:=false;

                   end
else        if (command='go')                                   //go
                  then
                   begin
                    if XboardMode then
                       begin
                       //Режим go- выход из режима force
                       ForceMode:=false;
                       MoveNow:=true;
                       end;
                   if UciMode then
                      begin
                        timer.Increment:=0;
                        timer.TimeMode:=increment;
                        timer.BaseTime:=0;
                        command:=parse(inp,probel+1);
                        probel:=probel+length(command)+1;
                        while length(command)>0 do
                          begin
                           if (command='wtime')   then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                if (sidetomove=white) then EngineClock:=trunc(strtoint(first)/10);
                              end  else
                           if (command='btime')  then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                if (sidetomove=black) then EngineClock:=trunc(strtoint(first)/10);
                              end  else
                           if (command='winc')   then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                if (sidetomove=white) then timer.Increment:=trunc(strtoint(first)/1000);
                              end  else
                           if (command='binc')   then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                if (sidetomove=black) then timer.Increment:=trunc(strtoint(first)/1000);
                              end  else
                           if (command='movestogo')   then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                timer.TimeMode:=convection;
                                timer.NumberMoves:=strtoint(first);
                                MovesToControl:=strtoint(first);
                              end  else
                           if (command='movetime')   then
                              begin
                                first:=parse(inp,probel+1);
                                probel:=probel+length(first)+1;
                                timer.TimeMode:=exacttime;
                                timer.BaseTime:=trunc(strtoint(first)/1000);
                              end else
                           if (command='depth') then
                             begin
                               first:=parse(inp,probel+1) ;
                               probel:=probel+length(first)+1;
                               MaxDepth:=strtoint(first);
                               DepthLimit:=true;
                             end;
                           command:=parse(inp,probel+1);
                           probel:=probel+length(command)+1;
                          end;
                        MoveNow:=true;  
                      end;
                   end
else        if (command='white') and (XBoardMode)                               //white
                  then
                   begin
                    //Ход белых
                   SideToMove:=white;
                   end
else        if (command='black') and (XBoardMode)                               //black
                  then
                   begin
                    //Ход белых
                   SideToMove:=black;
                   end
else        if (command='level')and (XBoardMode)                                //level
                  then
                   begin
                    //Устанавливаем контроль времени на партию
                   //выделяем из входной строки 3 слога:
                   depthlimit:=false;
                     first:='';second:='';third:='';
                   i:=probel+1;
                    while inp[i]<>' ' do
                     begin
                      first:=first+inp[i];
                      inc(i);
                     end;
                    inc(i);
                    while inp[i]<>' ' do
                     begin
                      second:=second+inp[i];
                      inc(i);
                     end;
                    inc(i);
                    while (i<=length(inp)) and (inp[i]<>' ')   do
                     begin
                      third:=third+inp[i];
                      inc(i);
                     end;
                    //Теперь расбрасываем полученные данные:
                    // Тут у нас количество ходов в контроле (0-если до конца партии)
                    timer.NumberMoves:=strtoint(first);
                    if timer.NumberMoves=0
                       then timer.TimeMode:=Increment
                       else timer.TimeMode:=Convection;

                    // Второй слог - хитрожопый
                   limit:=pos(':',second);
                   if limit=0
                      then
                          //Если : нет, то во втором слоге целое число минут
                          begin
                          timer.BaseTime:=strtoint(second)*60;// секунд;
                           EngineClock:=strtoint(second)*60*100;
                          end

                      else
                          begin
                            // Иначе - формат мин:сек
                          min:='';sek:='';
                          for i:=1 to limit-1 do
                           min:=min+second[i];
                          for i:=limit+1 to length(second) do
                           sek:=sek+second[i];
                           timer.BaseTime:=strtoint(min)*60+strtoint(sek);
                           EngineClock:=(strtoint(min)*60+strtoint(sek))*100;
                          end;
                   // Третий слог - инкремент в секундах:
                   timer.Increment:=strtoint(third);
                   MovesToControl:=timer.NumberMoves;
                   end
else        if (command='st')and (XBoardMode)                                   //st
                  then
                   begin
                    //Устанавливаем контроль: "точное время на ход"
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                   timer.TimeMode:=ExactTime;
                   timer.NumberMoves:=0;
                   timer.BaseTime:=strtoint(last);
                   timer.Increment:=0;
                   depthlimit:=false;
                   end
else        if (command='sd')and (XBoardMode)                                   //sd
                  then
                   begin
                    //Устанавливаем ограничение по глубине перебора
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                   MaxDepth:=strtoint(last);
                   DepthLimit:=true;
                   end
else        if (command='time')and (XBoardMode)                                 //time
                  then
                   begin
                    //Устанавливаем врмя на часах движка
                    last:='';
                    for i:=probel+1 to length(inp) do
                      last:=last+inp[i];
                   EngineClock:=strtoint(last);
                   end
else        if (command='post')and (XBoardMode)                                 //post
                  then
                   begin
                    //Устанавливаем режим вывода на экран
                   PostMode:=true;
                   end
else        if (command='nopost')and (XBoardMode)                               //nopost
                  then
                   begin
                    //Сбрасываем режим вывода на экран
                   PostMode:=false;
                   end
else        if (command='c') and (EditMode)                                     //Edit command : c
                  then
                    begin
                    //Меняем цвет на доске
                    EditColor:=EditColor xor 1;
                    end
else        if (command='#') and (EditMode)                                     //Edit command : #
                  then
                    begin
                    //Очищаем доску
                    WhitePawns:=0;
                    WhiteKnights:=0;
                    WhiteBishops:=0;
                    WhiteRooks:=0;
                    WhiteQueens:=0;
                    WhiteKing:=0;
                    BlackPawns:=0;
                    BlackKnights:=0;
                    BlackBishops:=0;
                    BlackRooks:=0;
                    BlackQueens:=0;
                    BlackKing:=0;
                    WhitePieses:=0;
                    BlackPieses:=0;
                    AllPieses:=0;
                    AllR90:=0;
                    AllDh1:=0;
                    AllDa1:=0;
                    Wqb:=0;
                    WQR:=0;
                    BQB:=0;
                    BQR:=0;

                    end
else        if (command='.') and (EditMode)                                     //Edit command : .
                  then
                    begin
                    //Выходим из режима редактирования
                    SideToMove:=EditColor;
                    EditMode:=false;
                    Rule50[1]:=0;
                    MovesToControl:=timer.NumberMoves;
                    tree[1].EnnPass:=0;
                    tree[1].Castle:=0;
                    // Устанавливаем флажки рокировок
                    if (WhatPiese(e1)=king)
                       then begin
                             if WhatPiese(7)=rook then tree[1].Castle:=tree[1].Castle or 1;
                             if WhatPiese(0)=rook then tree[1].Castle:=tree[1].Castle or 2;
                            end;
                    if (WhatPiese(60)=-king)
                       then begin
                             if WhatPiese(63)=-rook then tree[1].Castle:=tree[1].Castle or 4;
                             if WhatPiese(56)=-rook then tree[1].Castle:=tree[1].Castle or 8;
                            end;
                     WQR:=WhiteQueens or WhiteRooks;
                     WQB:=WhiteQueens or WhiteBishops;
                     BQB:=BlackQueens or BlackBishops;
                     BQR:=BlackQueens or BlackRooks;
                     tree[1].Wmat:=CalcMatShort(white);
                     tree[1].Bmat:=CalcMatShort(black);
                     tree[1].MatEval:=CalcMat;
                     tree[1].HashKey:=GetHashKey(SideToMove,0);
                     HashGame[0]:=tree[1].HashKey;
                     tree[1].PHash:=GetPawnKey;
                     tree[1].Wking:=BitScanForward(WhiteKing);
                     tree[1].Bking:=BitScanForward(BlackKing);
                     d:=AllPieses;
                     while d<>0 do
                          begin
                           i:=BitScanForward(d);
                           AllR90:=AllR90 or OnlyR90[i];
                           AllDh1:=AllDh1 or OnlyDh1[i];
                           AllDa1:=AllDa1 or OnlyDa1[i];
                           d:=d and NotOnly[i];
                          end;
                    if SideToMove = white
                        then
                            tree[1].onCheck:=isBlackAttacks(tree[1].wking)
                        else
                            tree[1].onCheck:=isWhiteAttacks(tree[1].bking);
                    end
           else
           //Думаем, что это - введенный ход или фигура в режиме EditBoard
            begin
             if (EditMode)
                then begin
                     // Типа введена фигура в режиме EditMode. Лишних проверок не делаем.
                       stmove:=command[2]+command[3];
                       field1:=StrToField(stmove);
                       case command[1] of
                        'P'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhitePawns,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackPawns,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;
                        'N'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhiteKnights,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackKnights,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;
                        'B'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhiteBishops,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackBishops,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;
                        'R'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhiteRooks,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackRooks,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;
                        'Q'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhiteQueens,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackQueens,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;
                        'K'   :  begin
                                  if EditColor=white
                                    then begin
                                          SetBitInBitBoard(WhiteKing,field1);
                                          SetBitInBitBoard(WhitePieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end
                                    else begin
                                          SetBitInBitBoard(BlackKing,field1);
                                          SetBitInBitBoard(BlackPieses,field1);
                                          SetBitInBitBoard(AllPieses,field1);
                                         end;

                                 end;

                        end;
                      exit;
                     end;

            if (length(command)<=5) and (XBoardMode)
               then
             if  (command[1] in ['a','b','c','d','e','f','g','h'])
             and (command[2] in ['1','2','3','4','5','6','7','8']) then
                    begin
                     stmove:=command[1]+command[2];
                     field1:=StrToField(stmove);
                    // if field1=64 then break;
                     stmove:=command[3]+command[4];
                     field2:=StrToField(stmove);
                    // if field2=64 then break;
                      move:=(abs(WhatPiese(field2)) shl 20) or (abs(WhatPiese(field1)) shl 16)or (field2 shl 8) or field1;
                      if WhatPiese(field2)<>Empty then move:=move or Captureflag;
                      if (abs(WhatPiese(field1))=king) and (abs(field2-field1)=2)
                      then
                      move:=move or CastleFlag;
                      if (abs(WhatPiese(field1))=pawn) and (WhatPiese(field2)=empty) and (abs(field2-field1)in [7,9])
                        then move:=move or CaptureFlag or EnPassantFlag;
                    if length(command)=4
                       then Promo:=Queen
                       else begin
                             case command[5] of
                               'Q'  :  Promo:=Queen;
                               'q'  :  Promo:=Queen;
                               'R'  :  Promo:=Rook;
                               'r'  :  Promo:=Rook;
                               'N'  :  Promo:=Knight;
                               'n'  :  Promo:=Knight;
                               'B'  :  Promo:=Bishop;
                               'b'  :  Promo:=Bishop;
                               end;
                            end;
                     if (abs(WhatPiese(field1))=pawn) and ((field2>h7) or (field2<a2)) then
                       move:=move or Promoteflag or (promo shl 24);


                    // Производим принятый ход на доске:

                    MakeMove(sidetomove,move,1);
                    Notation[notc]:=move and 16383;
                    inc(notc);
                    tree[1]:=tree[2];
                    Rule50[1]:=Rule50[2];
                    HashGame[Rule50[1]]:=tree[1].HashKey;
                    SideToMove:=SideToMove xor 1;
                    if SideToMove = white
                               then
                                   tree[1].onCheck:=isBlackAttacks(tree[1].wking)
                               else
                                   tree[1].onCheck:=isWhiteAttacks(tree[1].bking);

                    backundo(sidetomove);
                    // Если сработало правило 50 ходов - печатаем результат
                    if Rule50[1]>=100 then Lprint('1/2-1/2 {50 Moves Rule}');

                    if isDrawRep then LPrint('1/2-1/2 {Repetition}');
                    if isInsuff(1) then LPrint('1/2-1/2 {Insufficient Material}');


                    if (not ForceMode) then MoveNow:=true else
                      begin
                        if (sidetomove xor 1)=white
                          then inc(wforce)
                          else inc(bforce);
                      end;
                  //  Clearhash;
                    // Отваливаем
                    exit;
                    end;
             // Здесь печатаем ошибку ввода:
              Lprint('Unknown command,'+command);
              exit;
            end;

          end;

end;
Procedure NewGame;
begin
SetBoard('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -');
Postmode:=true;
Rule50[1]:=0;
forcemode:=false;
MovesToControl:=timer.NumberMoves;
usebook:=hasbook;
notc:=1;
ClearHash;
ClearHistory;
resCount:=0;
wforce:=0;bforce:=0;
//SetBoard('6k1/4B1p1/p5P1/1p5P/1Prb4/5K2/3R4/8 b - - 0 50  ' );

end;

Procedure ReadConfig;
label l1,l2;
var
   f:text;
   g:file of byte;
   s,param,p:string;
   i,j:integer;
   totalp,siz:integer;
begin
l1:  TotalHash:=1; isResign:=false; totalp:=1;
 if FileExists('booot.cfg')
     then begin
          assign (g,'booot.cfg');
          reset(g);
          siz:=filesize(g);
          close(g);
          if siz<=110 then goto l2;
          assign (f,'booot.cfg');
          reset(f);
           while not eof(f) do
            begin
             readln(f,s);
             j:=pos('=',s);
             if j<>0 then begin
                             param:='';p:='';
                             for i:=1 to j-1 do
                              param:=param+s[i];
                             for i:= j+1 to length(s) do
                               p:=p+s[i];
                             if param='HashSize'
                                then
                                    TotalHash:=strtoint(p)
                                     else
                             if param='PSize'
                                then
                                    TotalP:=strtoint(p)
                             else
                              if param='Resign'
                                then
                                    begin
                                      if strtoint(p)<>0
                                        then begin
                                               Resign:=strtoint(p);
                                               isResign:=true;
                                             end
                                       else isResign:=false;      

                                    end
                             else
                             if param='EGTB_path' then
                                                     begin
                                                     egtbpath:=p;
                                                     if egtbpath[length(egtbpath)]<>'\'
                                                        then egtbpath:=egtbpath+'\';
                                                     end;

                             if TotalHash<=0 then TotalHash:=1;

                            end;

            end;
          close(f);  
          PHashSize:=Totalp;
          PHashMask:=PHashSize-1;
          HashSize:=TotalHash div 8;
          HashMask:=HashSize-1;
          if PHashSize=0 then PHashSize:=1;
          SetLength(WhiteTable,HashSize+1);
          SetLength(BlackTable,HashSize+1);
          SetLength(PTable,PHashSize+1);
          end
     else begin
       l2:    assign (f,'booot.cfg');
           rewrite (f);
           s:='HashSize=1048576';
           writeln(f,s);
           s:=';1 unit=32 bytes. Default=32M';
           writeln(f,s);
           s:='PSize=262144';
           writeln(f,s);
           s:=';1 unit=16 bytes. Default=4M';
           writeln(f,s);
           s:='Resign=750';
           writeln(f,s);
           s:='EGTB_path=\';
           writeln(f,s);
           s:='; Default  (\) - in engine folder';
           writeln(f,s);
           close(f);
           goto l1;
          end;
end;
Function parse(var inp:AnsiString;pos:integer):string;
var
   res:string;
begin
res:='';
while (length(inp)>=pos) and (inp[pos]<>' ')   do
  begin
   res:=res+inp[pos];
   inc(pos);
  end;
Result:=res;
end;

Procedure backundo(color:integer);
begin
if undocount>=512 then exit;
inc(undocount);
undo[undocount].color:=color;
undo[undocount].WP:=WhitePawns;
undo[undocount].BP:=BlackPawns;
undo[undocount].WN:=WhiteKnights;
undo[undocount].BN:=BlackKnights;
undo[undocount].WB:=WhiteBishops;
undo[undocount].BB:=BlackBishops;
undo[undocount].WR:=WhiteRooks;
undo[undocount].BR:=BlackRooks;
undo[undocount].WQ:=WhiteQueens;
undo[undocount].BQ:=BlackQueens;
undo[undocount].WK:=WhiteKing;
undo[undocount].BK:=BlackKing;
undo[undocount].EnnPass:=tree[1].EnnPass;
undo[undocount].castle:=tree[1].Castle;
undo[undocount].r50:=Rule50[1];
undo[undocount].rep:=rep;
undo[undocount].mtc:=MovesToControl;
end;

Procedure getundo(N:integer);
var
   d:int64;
   i:integer;
begin
dec(undocount,N);
if undocount>=512 then exit;
WhitePawns:=undo[undocount].WP;
BlackPawns:=undo[undocount].BP;
WhiteKnights:=undo[undocount].WN;
BlackKnights:=undo[undocount].BN;
WhiteBishops:=undo[undocount].WB;
BlackBishops:=undo[undocount].BB;
WhiteRooks:=undo[undocount].WR;
BlackRooks:=undo[undocount].BR;
WhiteQueens:=undo[undocount].WQ;
BlackQueens:=undo[undocount].BQ;
WhiteKing:=undo[undocount].WK;
BlackKing:=undo[undocount].BK;
tree[1].EnnPass:=undo[undocount].EnnPass;
tree[1].Castle:=undo[undocount].castle;
WhitePieses:=Whitepawns or WhiteKnights or WhiteBishops or WhiteRooks or WhiteQueens or Whiteking;
WQR:=WhiteQueens or WhiteRooks;
WQB:=WhiteQueens or WhiteBishops;
BQB:=BlackQueens or BlackBishops;
BQR:=BlackQueens or BlackRooks;
BlackPieses:=Blackpawns or BlackKnights or BlackBishops or BlackRooks or BlackQueens or Blackking;
AllPieses:=WhitePieses or BlackPieses;
tree[1].Wmat:=CalcMatShort(white);
tree[1].Bmat:=CalcMatShort(black);
tree[1].MatEval:=CalcMat;
tree[1].HashKey:=GetHashKey(undo[undocount].color,undo[undocount].EnnPass);
tree[1].PHash:=GetPawnKey;
Rule50[1]:=0;
rep:=0;
d:=AllPieses;
while d<>0 do
 begin
   i:=BitScanForward(d);
   AllR90:=AllR90 or OnlyR90[i];
   AllDh1:=AllDh1 or OnlyDh1[i];
   AllDa1:=AllDa1 or OnlyDa1[i];
   d:=d and NotOnly[i];
 end;
if undo[undocount].color = white
   then
       tree[1].onCheck:=isBlackAttacks(tree[1].wking)
   else
       tree[1].onCheck:=isWhiteAttacks(tree[1].bking);
rep:=0;
SideToMove:=undo[undocount].color;
MovesToControl:=undo[undocount].mtc;
ClearMemory;
end;

end.







