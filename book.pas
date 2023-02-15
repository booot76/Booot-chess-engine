unit book;

interface
uses SysUtils,Params,bitboards,history;
var
    f:file of byte;
    BookFile:file;
    BookMoves: array of byte; // массив с книжными ходами
    BookCandidat: array [1..256,1..2] of integer; // Массив для хранения ходов-кандидатов из дебютной справочной
    Notation: array[1..800] of integer; // Текст партии
    notc:integer;
    hasbook,usebook: boolean; // флаги использования дебютной книги
    BookSize : integer;

function BookInitialize(i: integer): boolean;
function ProbeBook(pos: integer): integer;
Function CalcMove(mov:integer):integer;
implementation


function BookInitialize(i: integer): boolean;
// Инициализация библиотеки. Загрузка библиотеки в память.
var
  j,filesiz,realread,count: integer;
  buf: array[1..4096] of byte;
begin
  Result := false;
  if FileExists('book.bk') = true then
  begin
    AssignFile(f, 'book.bk');
    reset(f);
    filesiz:=FileSize(f);
    BookSize:=filesiz+MaxPly;
    AssignFile(BookFile, 'book.bk');
    Reset(BookFile,1);
    SetLength(BookMoves,BookSize+1);
     for j:=0 to BookSize do
       BookMoves[j]:=0;
       count:=0;
        repeat
           BlockRead(BookFile,buf,SizeOf(buf),realread);
           for j:=1 to realread do
              begin
                BookMoves[count]:=buf[j];
                inc(count);
              end;
       until realread<>sizeof(buf);

    Result := true;
    Close(BookFile);
  end;

end;

function ProbeBook(pos: integer): integer;
//Запрос в библиотеку. На входе - номер текущего хода. На выходе:
// True или False в зависимосто от того,  есть ли в дебютной библиотеке такой ход.

label
  l1, l2,l3;
var
  i, j,indx,move,l,mov: integer;
begin
  for l:=1 to 256 do
   begin
     BookCandidat[l,1]:=0;
     BookCandidat[l,2]:=0;
   end;

  indx:=0;
  i := 1;
  while i <= BookSize do
  begin
    for j := 1 to pos-1  do
     begin
      move:=(recod[BookMoves[i]] or (recod[BookMoves[i+1]] shl 8));
      i:=i+2;
      if move <> Notation[j] then
      begin
        while (i<BookSize) and (BookMoves[i] <> 0) do
          i := i + 1;
        goto l1;
      end;
     end;

    if (i<BookSize) and (BookMoves[i] <> 0) and (BookMoves[i+1]<>0) then
    begin
      move:=(recod[BookMoves[i]] or (recod[BookMoves[i+1]] shl 8));
        l:=1;
        while BookCandidat[l,1]<>0 do
        begin
         if BookCandidat[l,1]=move then
           begin
             inc(BookCandidat[l,2]);
             inc(indx);
             goto l3;
           end;
        inc(l);
       end;
     mov:=CalcMove(move);
     if isvalidmove(sidetomove,mov,1) then
     begin
     BookCandidat[l,1]:=move;
     BookCandidat[l,2]:=1;
     inc(indx);
     end;
     l3:
    end;
    l2: while (i<BookSize)and (BookMoves[i] <> 0)   do
      i := i + 1;
    l1: i := i + 1;
  end;
Result:=indx;
end;

Function CalcMove(mov:integer):integer;
var
   field1,field2 : integer;
begin
  field1:=(mov and 255);
  field2:=((mov shr 8) and 255);
  mov:=(abs(WhatPiese(field2)) shl 20) or (abs(WhatPiese(field1)) shl 16)or mov;
  if WhatPiese(field2)<>Empty then mov:=mov or Captureflag;
  if (abs(WhatPiese(field1))=king) and (abs(field2-field1)=2)
      then
           mov:=mov or CastleFlag;
  if (abs(WhatPiese(field1))=pawn) and (WhatPiese(field2)=empty) and (abs(field2-field1)in [7,9])
      then mov:=mov or CaptureFlag or EnPassantFlag;
  if (abs(WhatPiese(field1))=pawn) and ((field2>h7) or (field2<a2)) then
                                     mov:=mov or Promoteflag or (queen shl 24);
  result:=mov;
end;

end.
