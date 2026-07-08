// ====================================================================
// mystic_mailer : sample FidoNet mailer front-end for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on/sample for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// mlr_miswfc - a MIS-style status screen for the mailer front-end, drawn in
// the spirit of MIS's DrawStatusScreen: a titled panel with labelled fields
// and a bottom hot-key bar.  Plain text for full portability (no dependency
// on Mystic's Console/ANSI engine); a themed ANSI version could replace it.
//
// This renders the MAILER / BinkP side: what the line is doing, which kind of
// caller was detected (EMSI / BinkP / human), the remote node, the session
// mode, and simple mail counters.
// ====================================================================

Unit mlr_MisWfc;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Type
  TMailerWfcStats = Record
    LineState  : String;   // WAITING / RING / CONNECT nnnn / OFFLINE
    CallerKind : String;   // (none) / EMSI / BinkP / human
    Mode       : String;   // ANSWER / handshake / transfer / BBS hand-off
    RemoteAddr : String;   // detected FTN address of the remote node
    RemoteSys  : String;   // remote system name
    Sessions   : LongInt;  // total mail sessions handled
    Humans     : LongInt;  // total human calls routed to the BBS
    LastEvent  : String;   // free-text last event
  End;

Procedure DrawMailerWfc (Const NodeAddr, NodeName: String;
                         Const St: TMailerWfcStats);

Implementation

Uses
  SysUtils;

Const
  W = 62;

Function Pad (Const S: String; Len: LongInt): String;
Begin
  Result := S;
  While Length(Result) < Len Do Result := Result + ' ';
  If Length(Result) > Len Then Result := Copy(Result, 1, Len);
End;

Function Row (Const Label_, Value: String): String;
Begin
  Row := '  | ' + Pad(Label_, 11) + ': ' + Pad(Value, W - 16) + ' |';
End;

Function Bar : String;
Var I : LongInt; S : String;
Begin
  S := '  +';
  For I := 1 to W - 2 Do S := S + '-';
  Bar := S + '+';
End;

Function Centre (Const S: String): String;
Var Pad2 : LongInt;
Begin
  Pad2 := (W - 2 - Length(S)) Div 2;
  If Pad2 < 0 Then Pad2 := 0;
  Centre := '  |' + Pad(StringOfChar(' ', Pad2) + S, W - 2) + '|';
End;

Procedure DrawMailerWfc (Const NodeAddr, NodeName: String;
                         Const St: TMailerWfcStats);
Begin
  WriteLn;
  WriteLn(Bar);
  WriteLn(Centre('M Y S T I C   -   FidoNet Mailer (Waiting For Caller)'));
  WriteLn(Bar);
  WriteLn(Row('This node',  NodeAddr));
  WriteLn(Row('System',     NodeName));
  WriteLn(Bar);
  WriteLn(Row('Line',       St.LineState));
  WriteLn(Row('Caller',     St.CallerKind));
  WriteLn(Row('Mode',       St.Mode));
  WriteLn(Row('Remote',     St.RemoteAddr));
  WriteLn(Row('Remote sys', St.RemoteSys));
  WriteLn(Bar);
  WriteLn(Row('Mail sess',  IntToStr(St.Sessions)));
  WriteLn(Row('Humans',     IntToStr(St.Humans)));
  WriteLn(Row('Last',       St.LastEvent));
  WriteLn(Bar);
  WriteLn('  SPACE/Local   TAB/Switch   ALT-H/Hangup   ESC/Shutdown');
  WriteLn;
End;

End.
