// ====================================================================
// mystic_rip : optional RIPscrip graphics example for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//

Unit rip_Term;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

// ====================================================================
// rip_term - TTermRip: a RIPscrip 1.x terminal interpreter.
//
// The direct parallel of TTermAnsi (m_term_ansi.pas): same public
// shape (Create / Process / ProcessBuf / SetReplyClient), same stream-
// interpreter role, hooked the same way (bbs_io / mis / nodespy_term
// feed it a character at a time).  The ONE difference: TTermAnsi
// renders to the text-cell TOutput; TTermRip renders to the graphics
// seam TRipCanvas (m_rip_canvas.pas), because RIP is vector graphics,
// not text cells.  See docs/RIP-INTEGRATION.md.
//
// Parser core derived from ripterm_client_v0 (RipParser.pas), the
// maintainer's clean-room RIP client engine - built once, used twice:
// the standalone client and this class share one engine.
//
// RIPscrip framing (level-1 subset):
//   Commands are introduced by '!' '|', then optional level digits,
//   then a command letter, then fixed-width numeric fields.  Numbers
//   are "mega numbers": 2 base-36 chars each (0-9, A-Z) = 0..1295.
//   Lines end at CR; a trailing '\' joins the next line (so a logical
//   line can exceed 255 chars - line buffers are AnsiString on
//   purpose; do not "simplify" them to ShortString).  Non-command
//   text is written to the canvas as text.
//
// Implemented commands (Phase 1, core drawing/menus subset):
//   c W = m X L R B C O o F @ T M K e E
// Unknown commands are ignored (extensible; Phase 2 adds fills/fonts/
// buttons per docs/RIP-INTEGRATION.md).
// ====================================================================

Interface

Uses
  rip_Canvas;

Type
  // reply channel: RIP query commands answer the host by "typing" a
  // string at it.  In-core this is TIOBase; the example keeps it an
  // FPC-native callback so the module has no mdl dependency.
  TRipReplyProc = Procedure (Const S: AnsiString) of Object;

  TTermRip = Class
    Screen   : TRipCanvas;      // render target (graphics seam)
    WasValid : Boolean;
  Private
    Client   : TRipReplyProc;   // reply channel (future query responses)
    LineBuf  : AnsiString;      // current logical line (CR-terminated)
    CurX     : Integer;         // current pen position (RIP 'm')
    CurY     : Integer;

    Function    MegaNum (Const S: AnsiString; Var Idx: Integer) : Integer;
    Procedure   HandleCommand (Cmd: Char; Const Args: AnsiString);
    Procedure   ParseLine (Const Line: AnsiString);
  Public
    Constructor Create (Var Con: TRipCanvas);
    Destructor  Destroy; Override;
    Procedure   Process (Ch: Char);
    Procedure   ProcessBuf (Var Buf; BufLen: Word);
    Procedure   SetReplyClient (Cli: TRipReplyProc);
  End;

Implementation

Constructor TTermRip.Create (Var Con: TRipCanvas);
Begin
  Inherited Create;

  Screen   := Con;
  Client   := Nil;
  LineBuf  := '';
  CurX     := 0;
  CurY     := 0;
  WasValid := False;
End;

Destructor TTermRip.Destroy;
Begin
  Inherited Destroy;
End;

Procedure TTermRip.SetReplyClient (Cli: TRipReplyProc);
Begin
  Client := Cli;
End;

// mega-number decode: 2 base-36 chars -> integer 0..1295
Function TTermRip.MegaNum (Const S: AnsiString; Var Idx: Integer) : Integer;

  Function Base36 (C: Char) : Integer;
  Begin
    Case C of
      '0'..'9' : Base36 := Ord(C) - Ord('0');
      'A'..'Z' : Base36 := Ord(C) - Ord('A') + 10;
      'a'..'z' : Base36 := Ord(C) - Ord('a') + 10;  // tolerate lowercase
    Else
      Base36 := 0;
    End;
  End;

Begin
  Result := 0;

  If Idx + 1 <= Length(S) Then Begin
    Result := Base36(S[Idx]) * 36 + Base36(S[Idx + 1]);
    Inc (Idx, 2);
  End;
End;

Procedure TTermRip.HandleCommand (Cmd: Char; Const Args: AnsiString);
Var
  I   : Integer;
  X0  : Integer;
  Y0  : Integer;
  X1  : Integer;
  Y1  : Integer;
  R   : Integer;
  XR  : Integer;
  YR  : Integer;
  Col : Integer;
  Reg : TRipMouseRegion;
  S   : AnsiString;
Begin
  I := 1;

  Case Cmd of
    'c' : Begin  // RIP_COLOR: set draw color (1 field)
            Col := MegaNum(Args, I);
            Screen.SetDrawColor (Col And 15);
          End;
    'W' : Begin  // RIP_WRITE_MODE (1 field): 0=copy 1=xor
            Screen.SetWriteMode (MegaNum(Args, I));
          End;
    '=' : Begin  // RIP_LINE_STYLE: style, user pattern (thickness: Phase 2)
            X0 := MegaNum(Args, I);
            MegaNum (Args, I);  // user pattern field: skip (Phase 2)
            Screen.SetLineStyle (X0, 1);
          End;
    'm' : Begin  // RIP_MOVE: x, y
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);

            CurX := X0;
            CurY := Y0;

            Screen.MoveTo (X0, Y0);
          End;
    'X' : Begin  // RIP_PIXEL: x, y (draws in current color)
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);

            Screen.Pixel (X0, Y0, 15);
          End;
    'L' : Begin  // RIP_LINE: x0, y0, x1, y1
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            X1 := MegaNum(Args, I);
            Y1 := MegaNum(Args, I);

            Screen.Line (X0, Y0, X1, Y1);
          End;
    'R' : Begin  // RIP_RECTANGLE (outline): x0, y0, x1, y1
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            X1 := MegaNum(Args, I);
            Y1 := MegaNum(Args, I);

            Screen.Rectangle (X0, Y0, X1, Y1);
          End;
    'B' : Begin  // RIP_BAR (filled): x0, y0, x1, y1
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            X1 := MegaNum(Args, I);
            Y1 := MegaNum(Args, I);

            Screen.Bar (X0, Y0, X1, Y1);
          End;
    'C' : Begin  // RIP_CIRCLE: x, y, radius
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            R  := MegaNum(Args, I);

            Screen.Circle (X0, Y0, R);
          End;
    'O' : Begin  // RIP_OVAL (outline): x, y, xrad, yrad
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            XR := MegaNum(Args, I);
            YR := MegaNum(Args, I);

            Screen.Oval (X0, Y0, XR, YR);
          End;
    'o' : Begin  // RIP_FILLED_OVAL: x, y, xrad, yrad
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            XR := MegaNum(Args, I);
            YR := MegaNum(Args, I);

            Screen.FilledOval (X0, Y0, XR, YR);
          End;
    'F' : Begin  // RIP_FILL: x, y, border
            X0  := MegaNum(Args, I);
            Y0  := MegaNum(Args, I);
            Col := MegaNum(Args, I);

            Screen.FloodFill (X0, Y0, Col And 15);
          End;
    '@' : Begin  // RIP_TEXT_XY: x, y, <text>
            X0 := MegaNum(Args, I);
            Y0 := MegaNum(Args, I);
            S  := Copy(Args, I, Length(Args));

            Screen.WriteText (X0, Y0, S);
          End;
    'T' : Begin  // RIP_TEXT: <text> at current position
            S := Copy(Args, I, Length(Args));

            Screen.WriteText (CurX, CurY, S);
          End;
    'M' : Begin  // RIP_MOUSE: num, x0, y0, x1, y1, clk, clr, res(5), <text>
            MegaNum (Args, I);  // num (host button id): skip

            Reg.X0 := MegaNum(Args, I);
            Reg.Y0 := MegaNum(Args, I);
            Reg.X1 := MegaNum(Args, I);
            Reg.Y1 := MegaNum(Args, I);

            // clk + clr are single base-36 chars in the field layout
            If I <= Length(Args) Then Begin
              Reg.Invert := Args[I] = '1';
              Inc (I);
            End Else
              Reg.Invert := False;

            If I <= Length(Args) Then Begin
              Reg.ResetAfter := Args[I] = '1';
              Inc (I);
            End Else
              Reg.ResetAfter := False;

            Inc (I, 5);  // res: 5 reserved chars

            Reg.Text := Copy(Args, I, Length(Args));

            Screen.AddMouseRegion (Reg);
          End;
    'K' : Screen.KillMouseRegions;  // RIP_KILL_MOUSE_FIELDS
    'e' : Screen.Clear;             // RIP_ERASE_WINDOW (simplified)
    'E' : Screen.Clear;             // RIP_ERASE_VIEW (simplified)
  Else
    ;  // unimplemented command: ignore (Phase 2 extends here)
  End;
End;

Procedure TTermRip.ParseLine (Const Line: AnsiString);
Var
  P    : Integer;
  J    : Integer;
  Cmd  : Char;
  Args : AnsiString;
  Text : AnsiString;
Begin
  If Line = '' Then Exit;

  P := 1;

  While P <= Length(Line) Do Begin
    If (P < Length(Line)) And (Line[P] = '!') And (Line[P + 1] = '|') Then Begin
      Inc (P, 2);

      // optional level digit(s) before the command letter
      While (P <= Length(Line)) And (Line[P] In ['0'..'9']) Do
        Inc (P);

      If P > Length(Line) Then Exit;

      Cmd := Line[P];
      Inc (P);

      // args run until the next '!|' or end of line
      J := P;

      While (J <= Length(Line)) And
            Not ((J < Length(Line)) And (Line[J] = '!') And (Line[J + 1] = '|')) Do
        Inc (J);

      Args := Copy(Line, P, J - P);

      HandleCommand (Cmd, Args);

      WasValid := True;

      P := J;
    End Else Begin
      // plain text: accumulate until a command starts
      Text := '';

      While (P <= Length(Line)) And
            Not ((P < Length(Line)) And (Line[P] = '!') And (Line[P + 1] = '|')) Do Begin
        Text := Text + Line[P];
        Inc (P);
      End;

      If Text <> '' Then
        Screen.WriteText (CurX, CurY, Text);
    End;
  End;
End;

Procedure TTermRip.Process (Ch: Char);
Begin
  Case Ch of
    #13 : Begin
            // RIP line continuation: trailing '\' joins the next line
            If (Length(LineBuf) > 0) And (LineBuf[Length(LineBuf)] = '\') Then
              Delete (LineBuf, Length(LineBuf), 1)  // keep accumulating
            Else Begin
              ParseLine (LineBuf);
              LineBuf := '';
            End;
          End;
    #10 : ;  // LF ignored (lines are CR-framed)
  Else
    LineBuf := LineBuf + Ch;
  End;
End;

Procedure TTermRip.ProcessBuf (Var Buf; BufLen: Word);
Var
  Count : Word;
  Data  : Array[1..16384] of Char Absolute Buf;
Begin
  For Count := 1 to BufLen Do
    Process (Data[Count]);
End;

End.
