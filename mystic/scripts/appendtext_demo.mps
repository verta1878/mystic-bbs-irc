// ====================================================================
// APPENDTEXT_DEMO.MPS : MPL example of AppendText procedure (A60)
// ====================================================================
//
// AppendText(FileName, Text: String)
//   Appends a single line of text to a text file.
//   If the file does not exist, it will be created.
// ====================================================================

Uses CFG, USER;

Var
  UserInput : String;
  LogFile   : String;
Begin
  LogFile := CfgDataPath + 'custom.log';

  WriteLn('|14AppendText Demo|07');
  WriteLn('');

  AppendText(LogFile, DateStr(DateJulian, 1) + ' ' + TimeStr(Timer, False) + ' - ' + UserAlias + ' ran appendtext_demo');

  WriteLn('|11Logged your visit to ' + LogFile);
  WriteLn('');

  Write('|15Enter a message for the guestbook (or blank to skip): |07');
  UserInput := Input(60, 60, 11, '');

  If UserInput <> '' Then Begin
    AppendText(CfgDataPath + 'guestbook.txt', DateStr(DateJulian, 1) + ' ' + UserAlias + ': ' + UserInput);
    WriteLn('');
    WriteLn('|10Your message has been saved!');
  End;

  WriteLn('');
  WriteLn('|08Press any key...');
  ReadKey;
End.
