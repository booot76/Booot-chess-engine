program booot6;
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
  uKPK in 'uKPK.pas';

begin
  writeln(GetFullVersionName);
  MainLoop;
end.
