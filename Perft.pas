unit Perft;

interface
 uses params,SysUtils,board,BitBoards,sort;


Procedure Perfomance(var Board:Tboard;depth:integer);
Procedure Perf(var Board:Tboard;depth:integer);

implementation
  uses Movegen,Move,Attacks,hash,material,pawn,evaluation,search,history;

Procedure Perfomance(var Board:Tboard;depth:integer);
// Функция вычисляет перфоманс позиции
var
   StartTimer,StopTimer:TDateTime;
   MyTime,Mynps:real;
begin
   game.NodesTotal:=0;
  // c:=0;tot:=0;
   StartTimer:=now;
   Perf(Board,depth);
   StopTimer:=now;
   Mytime:=trunc((StopTimer-StartTimer)*8640000)/100;
   if MyTime<>0 then Mynps:=game.NodesTotal/(trunc((StopTimer-StartTimer)*86400000))
                else MyNps:=0;
   Writeln('Depth-',depth,'  ',game.NodesTotal,' nodes',MyTime:9:2,' seconds ',MyNPS:9:1,' knps');
 //  writeln ('Total PawnCalc-',tot,' Hits-',c);
end;

Procedure Perf(var Board:Tboard;depth:integer);
// проедура генерит все возможные ходы, производит их на доске и подсчитывает их количество
label l1;
var
 //i:integer;
 color : Tcolor;
 pseudocheck:integer;
 legal,ischeck : boolean;
 Undo : TUndo;
 CheckInfo : TcheckInfo;
 MoveList,BadList : TMoveList;
 sortunit:TsortUnit;
 move:tmove;
{ mlf,mlc,mlt,mlt1 : TmoveList;
 c1,c2,j:integer;
}
{  fzobr:Tkey;
 fpzobr:TpawnKey;
 fmzobr:TmatKey;
}
//temp : TbitBoard;
//tt,zz:cardinal;
begin

   color:=Board.Color;
   SetCheckInfo(color,CheckInfo,Board);
   InitNodeUndo(Board,Undo);
   NodeInitNext(color,depth,Board,CheckInfo,Undo,Movelist,BadList,SortUnit,0,1);
   move:=next(MoveList,BadList,Board,0);
   while move<>movenone do
    begin
     if Board.oncheck then pseudocheck:=moveislegal
                      else pseudocheck:=isPseudoLegal(color,move,CheckInfo,Board);

      if pseudocheck=moveisunlegal then goto l1;
      isCheck:=isMoveCheck(color,move,CheckInfo,Board);
      Makemove(color,move,Board,Undo);
      Board.oncheck:=ischeck;
      if pseudocheck=hardmove
       then legal:= (not isAttackedBy(color xor 1,Board.KingSq[color],Board))
       else legal:=true;
      if legal then
         begin
           if depth=1 then inc(game.NodesTotal)
                      else Perf(Board,depth-1);
         end;
      //Eval(Board);   
      UnmakeMove(color,Board,Undo);
l1:   move:=next(MoveList,BadList,Board,0);
    end;
end;

end.
