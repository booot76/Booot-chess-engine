unit uEval;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBoard,Unn;


Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer;
implementation
   uses uThread,uBitBoards,uEndgame;



Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer;
var
   evalfun,score,sf : integer;
begin
  // Быстро оцениваем специальные эндшпили на доске
  evalfun:=SpecialCases(Board);
  If  (evalfun=f_kbnk) or (evalfun=f_kpk) or (evalfun=f_pawnless) or (evalfun=F_MatDraw) then
    begin
      Result:=EvaluateSpecialEndgame(EvalFun,Board);
      exit;
    end;
  score:=ForwardPass(Board.SideToMove,PassThread[ThreadID-1][ply]);
  If evalfun=f_kbpskw then
    begin
      sf:=64;
      KBPSKw(sf,Board);
      if sf<>64 then
        begin
          if ((Board.SideToMove=white) and (score>0)) or ((Board.SideToMove=black) and (score<0)) then score:=(score*sf) div 64;
        end;
    end;
  If evalfun=f_kbpskb then
    begin
      sf:=64;
      KBPSKb(sf,Board);
       if sf<>64 then
        begin
          if ((Board.SideToMove=black) and (score>0)) or ((Board.SideToMove=white) and (score<0)) then score:=(score*sf) div 64;
        end;
    end;
  Result:=score;
end;
end.
