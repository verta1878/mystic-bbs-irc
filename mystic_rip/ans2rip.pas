// ====================================================================
// This file is part of mystic-bbs-irc and is released under the
// GNU General Public License v3. See COPYING for details.
// ====================================================================
//
program ans2rip;
// ====================================================================
// ans2rip - ANSI to RIPscrip converter
// ====================================================================
//
// Converts .ANS files to .RIP format using correct RIPscrip encoding.
// Based on PabloDraw's RipWriter patterns (credit: PabloDraw, MIT license).
//
// Key features (from PabloDraw reference):
//   - Base-36 mega-number encoding for coordinates
//   - Line wrapping at 70 chars with backslash continuation
//   - CP437 encoding
//   - Each RIP command starts with !| prefix
//
// Usage: ans2rip input.ans output.rip
//
// GPLv3. RIPscrip protocol (c) TeleGrafix Communications, Inc.

{$MODE OBJFPC}{$H+}

Uses SysUtils;

Const
  MAX_LINE = 70;   // PabloDraw wraps at 70 (RIPscrip standard)

Var
  OutF      : Text;
  LinePos   : Integer;  // current position on the output line

// --- RIP Writer (based on PabloDraw RipWriter.cs) ---

Procedure RipFlush;
Begin
  // nothing buffered at text level
End;

Procedure RipNewLine;
Begin
  Write(OutF, #13#10);
  LinePos := 0;
End;

Procedure RipCheckWrap (Needed: Integer);
// If adding Needed chars would exceed MAX_LINE, wrap with backslash
Begin
  If (LinePos + Needed + 1) > MAX_LINE Then Begin
    Write(OutF, '\');
    RipNewLine;
  End;
End;

Procedure RipWriteRaw (Const S: String);
Var I: Integer;
Begin
  For I := 1 to Length(S) Do Begin
    If (Ord(S[I]) >= 32) and (Ord(S[I]) <= 126) Then Begin
      RipCheckWrap(1);
      Write(OutF, S[I]);
      Inc(LinePos);
    End;
  End;
End;

Procedure RipNewCommand (Const Op: String);
// Start a new RIP command: !|<op>
Begin
  RipCheckWrap(Length(Op) + 2);
  Write(OutF, '!|' + Op);
  Inc(LinePos, 2 + Length(Op));
End;

Procedure RipWriteNumber (V: Integer);
// Single base-36 digit (0-35)
Const B36 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Begin
  If V < 0 Then V := 0;
  If V > 35 Then V := 35;
  RipCheckWrap(1);
  Write(OutF, B36[V + 1]);
  Inc(LinePos);
End;

Procedure RipWriteWord (V: Integer);
// Two base-36 digits (mega-number, 0-1295)
Begin
  If V < 0 Then V := 0;
  If V > 1295 Then V := 1295;
  RipWriteNumber(V Div 36);
  RipWriteNumber(V Mod 36);
End;

Procedure RipWriteText (Const S: String);
// Text content (no encoding, just write chars with wrap check)
Var I: Integer;
Begin
  For I := 1 to Length(S) Do Begin
    If (Ord(S[I]) >= 32) and (Ord(S[I]) <= 126) Then Begin
      RipCheckWrap(1);
      Write(OutF, S[I]);
      Inc(LinePos);
    End;
  End;
End;

// --- ANSI Parser ---

Type
  TAnsiState = (asNormal, asEscape, asCSI);

Var
  State    : TAnsiState;
  ParamBuf : String;
  CurFg    : Byte;
  CurBg    : Byte;
  CurBold  : Boolean;
  CurX     : Integer;
  CurY     : Integer;
  FontW    : Integer;
  FontH    : Integer;
  LastColor : Integer;
  TextRun  : String;      // accumulate text for batch output

Procedure EmitColor (C: Integer);
Begin
  If C <> LastColor Then Begin
    RipNewCommand('c');
    RipWriteWord(C);
    LastColor := C;
  End;
End;

Procedure EmitBar (X, Y, W, H, C: Integer);
Begin
  If (X >= 0) and (X < 640) and (Y >= 0) and (Y < 350) Then Begin
    { Set fill style solid + fill color before bar }
    RipNewCommand('S');
    RipWriteWord(1);   { solid fill }
    RipWriteWord(C);
    RipNewCommand('B');
    RipWriteWord(X);
    RipWriteWord(Y);
    RipWriteWord(X + W - 1);
    RipWriteWord(Y + H - 1);
    RipNewLine;
  End;
End;

Procedure FlushTextRun;
Var PX, PY, EffFg: Integer;
Begin
  If TextRun = '' Then Exit;
  EffFg := CurFg;
  If CurBold Then EffFg := EffFg Or 8;

  If EffFg <> LastColor Then Begin
    RipNewCommand('c');
    RipWriteWord(EffFg);
    LastColor := EffFg;
  End;

  PX := (CurX - Length(TextRun)) * FontW;
  PY := (CurY - 1) * FontH;

  If (PX >= 0) and (PX < 640) and (PY >= 0) and (PY < 350) Then Begin
    RipNewCommand('@');
    RipWriteWord(PX);
    RipWriteWord(PY);
    RipWriteText(TextRun);
    RipNewLine;
  End;

  TextRun := '';
End;

Procedure EmitBlockChar (Ch: Byte; Col, Row, Fg, Bg: Integer);
Var PX, PY, EffFg, EffBg: Integer;
Begin
  EffFg := Fg; If CurBold Then EffFg := EffFg Or 8;
  EffBg := Bg;
  PX := Col * FontW;
  PY := Row * FontH;
  Case Ch of
    219: EmitBar(PX, PY, FontW, FontH, EffFg);
    220: EmitBar(PX, PY + FontH Div 2, FontW, FontH Div 2, EffFg);
    223: EmitBar(PX, PY, FontW, FontH Div 2, EffFg);
    221: EmitBar(PX, PY, FontW Div 2, FontH, EffFg);
    222: EmitBar(PX + FontW Div 2, PY, FontW Div 2, FontH, EffFg);
    176: Begin EmitBar(PX, PY, FontW, FontH, EffBg);
           EmitBar(PX, PY, 2, 2, EffFg); EmitBar(PX+4, PY+4, 2, 2, EffFg); End;
    177: Begin EmitBar(PX, PY, FontW, FontH, EffBg);
           EmitBar(PX, PY, FontW Div 2, FontH Div 2, EffFg);
           EmitBar(PX+FontW Div 2, PY+FontH Div 2, FontW Div 2, FontH Div 2, EffFg); End;
    178: Begin EmitBar(PX, PY, FontW, FontH, EffFg);
           EmitBar(PX, PY, 2, 2, EffBg); EmitBar(PX+4, PY+4, 2, 2, EffBg); End;
  Else
    EmitBar(PX, PY, FontW, FontH, EffFg);
  End;
End;

Procedure HandleSGR;
Var
  Params: Array[0..15] of Integer;
  N, I, V, P: Integer;
  S: String;
Begin
  If ParamBuf = '' Then ParamBuf := '0';
  N := 0;
  S := ParamBuf + ';';
  V := 0;
  For P := 1 to Length(S) Do Begin
    If S[P] = ';' Then Begin
      If N <= 15 Then Params[N] := V;
      Inc(N);
      V := 0;
    End
    Else If S[P] In ['0'..'9'] Then
      V := V * 10 + (Ord(S[P]) - Ord('0'));
  End;
  For I := 0 to N - 1 Do Begin
    Case Params[I] of
      0:  Begin CurFg := 7; CurBg := 0; CurBold := False; End;
      1:  CurBold := True;
      22: CurBold := False;
      30..37: CurFg := Params[I] - 30;
      40..47: CurBg := Params[I] - 40;
    End;
  End;
End;

Procedure HandleCSI (FinalChar: Char);
Var
  P1, P2, CI, CV, CPN: Integer;
  S: String;
Begin
  P1 := 1; P2 := 1;
  S := ParamBuf + ';0';
  CV := 0; CPN := 0;
  For CI := 1 to Length(S) Do Begin
    If S[CI] = ';' Then Begin
      If CPN = 0 Then P1 := CV
      Else If CPN = 1 Then P2 := CV;
      Inc(CPN);
      CV := 0;
    End
    Else If S[CI] In ['0'..'9'] Then
      CV := CV * 10 + (Ord(S[CI]) - Ord('0'));
  End;

  Case FinalChar of
    'm': HandleSGR;
    'H', 'f': Begin
                FlushTextRun;
                If P1 = 0 Then P1 := 1;
                If P2 = 0 Then P2 := 1;
                CurY := P1; CurX := P2;
              End;
    'A': Begin FlushTextRun; If P1 = 0 Then P1 := 1; Dec(CurY, P1); If CurY < 1 Then CurY := 1; End;
    'B': Begin FlushTextRun; If P1 = 0 Then P1 := 1; Inc(CurY, P1); End;
    'C': Begin FlushTextRun; If P1 = 0 Then P1 := 1; Inc(CurX, P1); End;
    'D': Begin FlushTextRun; If P1 = 0 Then P1 := 1; Dec(CurX, P1); If CurX < 1 Then CurX := 1; End;
    'J': Begin
           FlushTextRun;
           If P1 = 2 Then Begin
             RipNewCommand('*');
             RipNewLine;
           End;
         End;
    'K': FlushTextRun;
  End;
End;

Procedure ProcessByte (B: Byte);
Var Ch: Char;
Begin
  Ch := Chr(B);
  Case State of
    asNormal:
      Case B of
        27: Begin FlushTextRun; State := asEscape; End;
        13: Begin FlushTextRun; CurX := 1; End;
        10: Begin FlushTextRun; Inc(CurY); End;
        8:  Begin FlushTextRun; If CurX > 1 Then Dec(CurX); End;
        9:  Begin FlushTextRun; CurX := ((CurX - 1) Div 8 + 1) * 8 + 1; End;
      Else
        If B >= 176 Then Begin
          FlushTextRun;
          EmitBlockChar(B, CurX - 1, CurY - 1, CurFg, CurBg);
          Inc(CurX);
          If CurX > 80 Then Begin CurX := 1; Inc(CurY); End;
        End
        Else If B >= 32 Then Begin
          TextRun := TextRun + Ch;
          Inc(CurX);
          If CurX > 80 Then Begin
            FlushTextRun;
            CurX := 1;
            Inc(CurY);
          End;
        End;
      End;
    asEscape:
      Case Ch of
        '[': Begin State := asCSI; ParamBuf := ''; End;
      Else
        State := asNormal;
      End;
    asCSI:
      If Ch In ['0'..'9', ';', '?'] Then
        ParamBuf := ParamBuf + Ch
      Else Begin
        HandleCSI(Ch);
        State := asNormal;
      End;
  End;
End;

// --- Main ---

Var
  InFile    : File;
  InBuf     : Array[0..4095] of Byte;
  InSize    : LongInt;
  I         : Integer;
  InPath    : String;
  OutPath   : String;
Begin
  FontW := 8;
  FontH := 8;

  If (ParamCount < 2) or (ParamStr(1) = '--help') or (ParamStr(1) = '-h') Then Begin
    WriteLn('ans2rip - ANSI to RIPscrip converter');
    WriteLn('Usage: ans2rip input.ans output.rip');
    WriteLn;
    WriteLn('Converts ANSI art to RIPscrip v1.54 format with correct');
    WriteLn('base-36 encoding and line wrapping (PabloDraw compatible).');
    WriteLn;
    WriteLn('GPLv3. RIPscrip (c) TeleGrafix Communications, Inc.');
    WriteLn('RIP writer based on PabloDraw patterns (credit: PabloDraw).');
    Halt(0);
  End;

  InPath := ParamStr(1);
  OutPath := ParamStr(2);

  State := asNormal;
  CurFg := 7; CurBg := 0; CurBold := False;
  CurX := 1; CurY := 1;
  LastColor := -1;
  TextRun := '';
  LinePos := 0;

  Assign(InFile, InPath);
  {$I-} Reset(InFile, 1); {$I+}
  If IOResult <> 0 Then Begin
    WriteLn('Error: cannot open ', InPath);
    Halt(1);
  End;

  Assign(OutF, OutPath);
  Rewrite(OutF);

  // RIP header
  RipNewCommand('*');
  RipNewLine;

  // Process ANSI
  Repeat
    BlockRead(InFile, InBuf, SizeOf(InBuf), InSize);
    For I := 0 to InSize - 1 Do
      ProcessByte(InBuf[I]);
  Until InSize = 0;

  FlushTextRun;

  // RIP footer
  RipNewCommand('#');
  RipNewLine;

  Close(InFile);
  Close(OutF);

  WriteLn('Converted: ', InPath, ' -> ', OutPath);
End.
