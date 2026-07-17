// ====================================================================
// This file is part of mystic-bbs-irc and is released under the
// GNU General Public License v3. See COPYING for details.
// ====================================================================
//
Unit bbs_Ansi_Console;

// ====================================================================
// TAnsiConsole — abstract console interface for ANSI terminal rendering
// ====================================================================
//
// Replaces TOutput (MDL) dependency for ANSI terminal processing.
// Implements console output using FPC's CRT unit and ANSI escape codes.
// No MDL dependency — pure FPC.
//
// Used by: the cfg ANSI editor, and any future code that needs to
// render ANSI terminal output without MDL.
//
// GPLv3.

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  SysUtils;

Type
  // Abstract console — the 8 methods TTermAnsi needs
  TAbstractConsole = Class
  Public
    TextAttr : Byte;

    Procedure CursorXY (X, Y: Integer); Virtual; Abstract;
    Function  CursorX : Integer; Virtual; Abstract;
    Function  CursorY : Integer; Virtual; Abstract;
    Procedure WriteChar (Ch: Char); Virtual; Abstract;
    Procedure ClearScreen; Virtual; Abstract;
    Procedure ClearEOL; Virtual; Abstract;
    Procedure BufFlush; Virtual; Abstract;
  End;

  // FPC implementation using ANSI escape codes (no CRT dependency)
  TAnsiEscConsole = Class(TAbstractConsole)
  Private
    FCurX : Integer;
    FCurY : Integer;
    FBuf  : AnsiString;
  Public
    Constructor Create;
    Destructor  Destroy; Override;

    Procedure CursorXY (X, Y: Integer); Override;
    Function  CursorX : Integer; Override;
    Function  CursorY : Integer; Override;
    Procedure WriteChar (Ch: Char); Override;
    Procedure ClearScreen; Override;
    Procedure ClearEOL; Override;
    Procedure BufFlush; Override;
  End;

Implementation

// ====================================================================
// TAnsiEscConsole — renders via ANSI escape sequences to stdout
// ====================================================================

Constructor TAnsiEscConsole.Create;
Begin
  Inherited Create;
  TextAttr := 7;
  FCurX := 1;
  FCurY := 1;
  FBuf  := '';
End;

Destructor TAnsiEscConsole.Destroy;
Begin
  BufFlush;
  Inherited Destroy;
End;

Procedure TAnsiEscConsole.BufFlush;
Begin
  If FBuf <> '' Then Begin
    System.Write(FBuf);
    FBuf := '';
  End;
End;

Procedure TAnsiEscConsole.CursorXY (X, Y: Integer);
Begin
  FCurX := X;
  FCurY := Y;
  FBuf := FBuf + #27 + '[' + IntToStr(Y) + ';' + IntToStr(X) + 'H';
End;

Function TAnsiEscConsole.CursorX : Integer;
Begin
  Result := FCurX;
End;

Function TAnsiEscConsole.CursorY : Integer;
Begin
  Result := FCurY;
End;

Procedure TAnsiEscConsole.WriteChar (Ch: Char);
Begin
  Case Ch of
    #13 : Begin FCurX := 1; FBuf := FBuf + #13; End;
    #10 : Begin Inc(FCurY); FBuf := FBuf + #10; End;
  Else
    FBuf := FBuf + Ch;
    Inc(FCurX);
    If FCurX > 80 Then Begin
      FCurX := 1;
      Inc(FCurY);
    End;
  End;
End;

Procedure TAnsiEscConsole.ClearScreen;
Begin
  FBuf := FBuf + #27 + '[2J' + #27 + '[H';
  FCurX := 1;
  FCurY := 1;
End;

Procedure TAnsiEscConsole.ClearEOL;
Begin
  FBuf := FBuf + #27 + '[K';
End;

End.
