program booot7;
//{$APPTYPE CONSOLE}
uses
  uBitBoards in 'uBitBoards.pas',
  SysUtils,
  DateUtils,
  uMagic in 'uMagic.pas',
  uAttacks in 'uAttacks.pas',
  uBoard in 'uBoard.pas',
  uHash in 'uHash.pas',
  uMaterial in 'uMaterial.pas',
  uEndgame in 'uEndgame.pas',
  uPawn in 'uPawn.pas',
  uEval in 'uEval.pas',
  uSearch in 'uSearch.pas',
  uThread in 'uThread.pas',
  uSort in 'uSort.pas',
  uUci in 'uUci.pas',
  uKPK in 'uKPK.pas',
  Unn in 'Unn.pas';

begin
  // грузим нейросеть
  If LoadNet('booot.nn') then
    begin
      writeln('NN is loaded');
    end else
    begin
      writeln('Can not load the file booot.nn. Wrong version or file is missing.');
      sleep(500);
      exit;
    end;
  writeln(GetFullVersionName(Net.model));
 // FenGenerator(8,285,20,'book.fen','8_GOODNNUE_',8*1024,1024);
 // test;
  SetupChanels;
  MainLoop;
end.
