unit perft;
 //Юнит содержит функцию вычисления перфоманса позиции
interface
var
   PerfNodes:int64;
Procedure Perfomance(color:integer;depth:integer);
Procedure Perf(color:integer;depth:integer;ply:integer);
implementation
 uses
     bitBoards,params,genmoves,captures,make,preeval,hash,escape,attacks,SysUtils;


Procedure Perfomance(color:integer;depth:integer);
// Функция вычисляет перфоманс позиции
var
   StartTimer,StopTimer:TDateTime;
   MyTime,Mynps:real;
begin
   PerfNodes:=0;
   StartTimer:=now;
   Perf(color,depth,1);
   StopTimer:=now;
   Mytime:=trunc((StopTimer-StartTimer)*8640000)/100;
   if MyTime<>0 then Mynps:=PerfNodes/(trunc((StopTimer-StartTimer)*86400000))
                else MyNps:=0;
   Writeln('Depth-',depth,'  ',PerfNodes,' nodes',MyTime:9:2,
   ' seconds ',MyNPS:9:1,' knps');
end;

Procedure Perf(color:integer;depth:integer;ply:integer);
// Зкщцедура генерит все возможные ходы, производит их на доске и подсчитывает их количество
var j,movescount,pointer:integer;
currmove:move;
begin
   GetMovesAll(color,ply);
   pointer:=ply shl 7;
   movescount:=Moves[pointer];
   For j:=1 to movescount do
    begin
      currmove:=Moves[pointer+1];
      inc(pointer);
      if makemove(color,currmove,ply)
        then begin
               if depth=1 then
                              inc(PerfNodes)
                          else
                              Perf(color xor 1,depth-1,ply+1);
              UnmakeMove(color,currmove,ply);
             end
      else
        begin
        UnmakeMove(color,currmove,ply);
        end;


    end;
end;


end.
