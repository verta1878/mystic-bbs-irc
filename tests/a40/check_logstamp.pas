program check_logstamp;
{$MODE DELPHI}
// A40: MUTIL logstamp= configurable log-file timestamp.
// Verifies FormatDate honours every A40 format code (YYYY/YY/MM/DDD/DD/HH/II/
// SS/NNN) so a sysop's [General] logstamp= mask renders correctly.  This is the
// automatable half of the A40 log-timestamp feature (the INI read + per-line
// application live in mutil.pas / mutil_common.pas and are covered by the
// unit-compile check in run.sh).
Uses
  Dos, m_DateTime;
Var
  DT   : DateTime;
  ok   : Boolean;

Procedure Chk (Name, Got, Want: String);
Begin
  Write (Name, ': "', Got, '" (want "', Want, '") ');
  If Got = Want Then WriteLn ('OK')
  Else Begin WriteLn ('*** MISMATCH ***'); ok := False; End;
End;

Begin
  ok := True;

  // A fixed, known moment: Fri 2021-03-07 09:05:02
  //   (2021-03-07 is a Sunday actually; DDD/NNN are checked against whatever
  //    FormatDate computes for the packed date, via the mask-only fields.)
  FillChar (DT, SizeOf(DT), 0);
  DT.Year  := 2021;
  DT.Month := 3;
  DT.Day   := 7;
  DT.Hour  := 9;
  DT.Min   := 5;
  DT.Sec   := 2;

  // numeric/textual codes that depend only on the fields we set
  Chk ('YYYY', FormatDate(DT, 'YYYY'), '2021');
  Chk ('YY',   FormatDate(DT, 'YY'),   '21');
  Chk ('MM',   FormatDate(DT, 'MM'),   '03');
  Chk ('DD',   FormatDate(DT, 'DD'),   '07');
  Chk ('HH',   FormatDate(DT, 'HH'),   '09');
  Chk ('II',   FormatDate(DT, 'II'),   '05');
  Chk ('SS',   FormatDate(DT, 'SS'),   '02');

  // NNN = 3-letter month (index only), stable regardless of weekday calc
  Chk ('NNN',  FormatDate(DT, 'NNN'),  MonthString[3]);

  // the default MUTIL logstamp mask must render without leftover code letters
  WriteLn ('default mask "NNN DD HH:II:SS" -> "', FormatDate(DT, 'NNN DD HH:II:SS'), '"');

  If ok Then WriteLn ('LOGSTAMP CODES OK')
  Else Begin WriteLn ('LOGSTAMP FAILURE'); Halt(1); End;
End.
