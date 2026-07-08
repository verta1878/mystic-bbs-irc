// ====================================================================
// mystic_modem : legacy dialup / serial support for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// mdm_miswfc - a MIS-style "Waiting For Caller" status screen for the modem
// subsystem, drawn in the spirit of MIS's DrawStatusScreen (mis_ansiwfc.pas):
// a titled panel with labelled fields and a bottom hot-key bar.  Kept plain
// text so it is fully portable and has no dependency on Mystic's Console/ANSI
// engine; a themed ANSI version could replace DrawModemWfc later.
//
// This renders the MODEM side: device / line state / baud / rings / carrier,
// plus a small call-counter panel mirroring MIS's Connections/Statistics idea.
// ====================================================================

Unit mdm_MisWfc;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  mdm_Config;

Type
  // Live counters shown on the screen, mirroring MIS's stats panel.
  TModemWfcStats = Record
    LineState : String;    // WAITING / RING / CONNECT nnnn / OFFLINE
    ConnBaud  : LongInt;   // negotiated speed of the current/last call
    Carrier   : Boolean;
    Calls     : LongInt;   // total answered
    LastCall  : String;    // free-text note about the last call
  End;

// Draw the full modem WFC status screen for the given config + live stats.
Procedure DrawModemWfc (Const Cfg: TModemConfig; Const St: TModemWfcStats);

Implementation

Uses
  SysUtils;

Const
  W = 62;    // inner width of the status box

Function Pad (Const S: String; Len: LongInt): String;
Begin
  Result := S;
  While Length(Result) < Len Do Result := Result + ' ';
  If Length(Result) > Len Then Result := Copy(Result, 1, Len);
End;

Function Row (Const Label_, Value: String): String;
Begin
  // "| Label      : value...                              |"
  Row := '  | ' + Pad(Label_, 10) + ': ' + Pad(Value, W - 15) + ' |';
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

Procedure DrawModemWfc (Const Cfg: TModemConfig; Const St: TModemWfcStats);
Begin
  WriteLn;
  WriteLn(Bar);
  WriteLn(Centre('M Y S T I C   -   Modem Server (Waiting For Caller)'));
  WriteLn(Bar);
  WriteLn(Row('Device',   Cfg.Device));
  WriteLn(Row('Baud',     IntToStr(Cfg.Baud)));
  WriteLn(Row('Init',     Cfg.InitString));
  WriteLn(Row('Rings',    IntToStr(Cfg.RingsToAns)));
  WriteLn(Row('FOSSIL',   BoolToStr(Cfg.UseFossil, 'yes', 'no')));
  WriteLn(Bar);
  WriteLn(Row('Line',     St.LineState));
  WriteLn(Row('Connect',  IntToStr(St.ConnBaud) + ' bps'));
  WriteLn(Row('Carrier',  BoolToStr(St.Carrier, 'present', 'none')));
  WriteLn(Row('Calls',    IntToStr(St.Calls)));
  WriteLn(Row('Last',     St.LastCall));
  WriteLn(Bar);
  WriteLn('  SPACE/Local   TAB/Switch   ALT-H/Hangup   ESC/Shutdown');
  WriteLn;
End;

End.
