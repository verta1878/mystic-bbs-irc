// ====================================================================
// CHATCHECK_DEMO.MPS : MPL example of CfgChatStart/CfgChatEnd (A60)
// ====================================================================
//
// CfgChatStart : Byte  (read-only, chat start hour 0-23)
// CfgChatEnd   : Byte  (read-only, chat end hour 0-23)
// ====================================================================

Uses CFG, USER;

Var
  ChatAvail : Boolean;
Begin
  WriteLn('|14Chat Availability Check|07');
  WriteLn('');

  WriteLn('|11Chat start   : |15' + Int2Str(CfgChatStart));
  WriteLn('|11Chat end     : |15' + Int2Str(CfgChatEnd));
  WriteLn('');

  If CfgChatStart <= CfgChatEnd Then
    ChatAvail := (TimerMin >= CfgChatStart * 60) And (TimerMin < CfgChatEnd * 60)
  Else
    ChatAvail := (TimerMin >= CfgChatStart * 60) Or (TimerMin < CfgChatEnd * 60);

  If ChatAvail Then Begin
    WriteLn('|10Chat is AVAILABLE.|07');
  End Else Begin
    WriteLn('|12Chat is NOT available.|07');
    WriteLn('|05Chat hours are ' + Int2Str(CfgChatStart) + ':00 to ' + Int2Str(CfgChatEnd) + ':00.');
  End;

  WriteLn('');

  If Not ChatAvail Then
    AppendText(CfgDataPath + 'chatlog.txt',
      DateStr(DateJulian, 1) + ' ' + UserAlias + ' tried to page (chat closed)');

  WriteLn('|08Press any key...');
  ReadKey;
End.
