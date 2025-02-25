unit uEval;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses uBoard,uNN;



Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer;
implementation
   uses uThread,uBitBoards,uEndgame,usearch,uhash;



Function Evaluate(var Board:TBoard;ThreadID:integer;ply:integer):integer;
var
   evalfun,score,sf : integer;
   //Np: TForwardPass;
   //score1:integer;
begin

  // Быстро оцениваем специальные эндшпили на доске
  evalfun:=SpecialCases(Board);
  If  (evalfun=f_kbnk) or (evalfun=f_kpk) or (evalfun=f_pawnless) or (evalfun=F_MatDraw) then
    begin
      Result:=EvaluateSpecialEndgame(EvalFun,Board);
      exit;
    end;
  // NN
  score:=NetResigma(PassThread[ThreadID-1][ply].Net,ForwardPass(Board.SideToMove,PassThread[ThreadID-1][ply]));

  {FillWhiteAcc16(Globalmodel,Board,NP);
  FillBlackAcc16(Globalmodel,Board,NP);
  score1:=ForwardPass(Board.SideToMove,NP);
  if score<>score1 then
    begin
      writeln(score,' ',score1);
    end;
  }
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

  if score>WinScore then score:=WinScore;
  if score<-WinScore then score:=-WinScore;
  Result:=score;
end;

end.
