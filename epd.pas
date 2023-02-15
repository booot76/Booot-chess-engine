unit epd;
 // Юнит отвечает за проведение тестов для движка. На вход движок получает
 // epd файл и время на обдумывание, на выходе - статистику решения всех позиций теста.
interface
uses
     Params,bitBoards,x,think,SysUtils;
Procedure EpdTest(epdfilename:string;testtime:integer);



implementation
Procedure EpdTest(epdfilename:string;testtime:integer);
var
   f:textfile;
   inputstring,FEN:string;
   i,j:integer;
   BestMoves : array[0..3] of byte; //0-число лучших ходов
   Pieses: array[0..3] of smallint; // Фигуры, которые ходят 0-количество
   movecount:byte;
   Piese:smallint;
   stmove:string[2];
   Field:smallint;
   TotalTime,Solved,Missed:integer;
   TotalNodes:int64;
   MyBestMove:integer;
   MyField,MyFrom:byte;
   isSolved:boolean;
begin
  assign(f,epdfilename);
  if not(FileExists(epdfilename)) then
                                      begin
                                       Lprint('File not found!');
                                       exit;
                                      end;

  TotalNodes:=0;EngineTime:=testtime*100; TotalTime:=0;Solved:=0;Missed:=0;
  reset(f);
  while not eof(f) do
    begin
    readln(f,inputstring);
    // Разделяем строку на FEN и лучший ход:
    i:=pos('bm',inputstring);
    if i=0 then break;
     FEN:='';
    // Заполняем FEN для тестовой позиции
     for j:=1 to i-1 do
       FEN:=FEN+inputstring[j];
    // Теперь распознаем и сохраняем лучшие ходы из позиции

    if length(inputstring)<=i+2
    then
    break;
      i:=i+2; movecount:=0;Piese:=Pawn;BestMoves[0]:=0;
      while inputstring[i]<>';' do
       begin
        if inputstring[i]<>' '
          then begin
                if inputstring[i]='N' then Piese:=Knight
          else  if inputstring[i]='B' then Piese:=Bishop
          else  if inputstring[i]='R' then Piese:=Rook
          else  if inputstring[i]='Q' then Piese:=Queen
          else  if inputstring[i]='K' then Piese:=King
          else  if inputstring[i]='x' then
          else  if inputstring[i]='+' then
          else if (inputstring[i] in ['1','2','3','4','5','6','7','8']) then
          else if inputstring[i] in ['a','b','c','d','e','f','g','h']
                then begin
                      if inputstring[i+1]='x' then i:=i+2
                else if inputstring[i+1] in ['a','b','c','d','e','f','g','h']
                      then i:=i+1;
                      stmove:=inputstring[i]+inputstring[i+1];
                      field:=StrToField(stmove);
                      if field=64 then exit;
                      // Сохраняем полученный лучший ход в списке и ищем следующий
                      inc(movecount);
                      BestMoves[0]:=moveCount;
                      BestMoves[moveCount]:=Field;
                      Pieses[0]:=movecount;
                      Pieses[movecount]:=Piese;
                      Piese:=Pawn; // пешка - фигура по умолчанию!
                      inc(i);
                     end
                else begin
                      Lprint('Error in BestMove tag!');
                      exit;
                     end;
               end;

        inc(i);
       end;
    // Здесь запускаем перебор в очередной позиции
     if BestMoves[0]=0 then begin
                            Lprint('Not found any Bm tag!');
                            exit;
                            end;
    // Нашли лучший ход с точки зрения движка
    SetBoard(FEN);
    MyBestmove:=iterate;
    //Обновляем статистику
    TotalNodes:=TotalNodes+Nodes;
    TotalTime:=TotalTime+round((CurrTime-StartTime)*86400);
    //Теперь сравниваем найденный ход с одним из лучших:
    isSolved:=false;
    for i:=1 to BestMoves[0] do
     begin
       MyFrom:=MyBestMove and 255;
       MyField:=(MyBestMove shr 8) and 255;
     if (abs(WhatPiese(MyFrom))=Pieses[i]) and
         (MyField=BestMoves[i]) then
         isSolved:=true;
     end;
    if isSolved then
                      begin
                       inc(Solved);
                       Lprint('Solved!');
                      end
                else
                      begin
                      inc(Missed);
                      Lprint('Not Solved!');
                      end;
    Lprint('Solved '+inttostr(Solved)+' from '+inttostr(Solved+Missed));
    end;
 // И в завершении печатаем подвал отчета:
  Lprint('Tested '+inttostr(Solved+Missed)+
  ' positions. Solved '+inttostr(Solved)+' positions. Searched '+inttostr(TotalNodes)+
  ' nodes on '+inttostr(TotalTime)+' seconds. Search speed- '+inttostr(trunc(TotalNodes/TotalTime))+' nps');
  close(f);
end;

end.


