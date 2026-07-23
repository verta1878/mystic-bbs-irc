{
  This file is part of the Mystic BBS IRC Fork.

  Copyright (C) 2026 Mystic BBS IRC Fork Contributors

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
}
{ utextmouse — cross-platform text-mode mouse support
  Copyright (c) 2026 fpc264irc contributors
  License: GPLv3+

  Provides xterm-compatible mouse reporting for terminal applications.
  Works over telnet/SSH — no direct hardware access needed.

  Platforms:
    UNIX/Linux/FreeBSD : xterm mouse protocol (CSI sequences)
    Windows            : Win32 Console API (ReadConsoleInput)
    DOS (go32v2)       : INT 33h mouse driver
    DOS (i8086-msdos)  : INT 33h mouse driver
    OS/2 (emx)         : MOU API (stub — reports unsupported)

  Usage:
    uses utextmouse;
    if TextMouseInit then begin
      while not done do begin
        if TextMousePoll(ev) then
          case ev.Action of
            mPress:   HandleClick(ev.Button, ev.X, ev.Y);
            mRelease: HandleRelease(ev.Button, ev.X, ev.Y);
            mMove:    HandleMove(ev.X, ev.Y);
          end;
      end;
      TextMouseDone;
    end;
}
unit utextmouse;

interface

type
  TMouseAction = (mNone, mPress, mRelease, mMove);
  TMouseButton = (mbLeft, mbMiddle, mbRight, mbWheelUp, mbWheelDown, mbNone);

  TMouseEvent = record
    Action : TMouseAction;
    Button : TMouseButton;
    X, Y   : integer;       { 1-based column/row }
    Shift  : boolean;
    Ctrl   : boolean;
    Alt    : boolean;
  end;

{ Initialize mouse reporting. Returns True if mouse is available. }
function  TextMouseInit: boolean;

{ Shut down mouse reporting, restore terminal. }
procedure TextMouseDone;

{ Poll for a mouse event. Returns True if event available (non-blocking). }
function  TextMousePoll(var ev: TMouseEvent): boolean;

{ Check if mouse is supported on this platform. }
function  TextMouseSupported: boolean;

{ Show/hide the mouse cursor (where applicable). }
procedure TextMouseShow;
procedure TextMouseHide;

implementation

{$IFDEF UNIX}
uses baseunix;
{$ENDIF}

{$IFDEF WINDOWS}
uses windows;
{$ENDIF}

{$IFDEF GO32V2}
uses dos;
{$ENDIF}

{$IFDEF MSDOS}
uses dos;
{$ENDIF}

var
  MouseActive: boolean = false;

{ ══════════════════════════════════════════════════════════════
  UNIX: xterm mouse protocol (works over telnet/SSH)
  ══════════════════════════════════════════════════════════════ }
{$IFDEF UNIX}

procedure WriteCSI(const s: string);
var i: integer;
begin
  for i := 1 to Length(s) do
    fpWrite(1, s[i], 1);
end;

function TextMouseInit: boolean;
begin
  { Enable xterm mouse tracking:
    1000 = button press/release
    1002 = button + motion while pressed
    1006 = SGR extended mode (supports >223 columns) }
  WriteCSI(#27'[?1000h');   { basic mouse tracking }
  WriteCSI(#27'[?1002h');   { button-event tracking }
  WriteCSI(#27'[?1006h');   { SGR extended coordinates }
  MouseActive := true;
  TextMouseInit := true;
end;

procedure TextMouseDone;
begin
  if MouseActive then begin
    WriteCSI(#27'[?1006l');
    WriteCSI(#27'[?1002l');
    WriteCSI(#27'[?1000l');
    MouseActive := false;
  end;
end;

function ReadByte(timeout_ms: integer): integer;
var
  ch: byte;
  tv: TTimeVal;
  fds: TFDSet;
begin
  fpFD_ZERO(fds);
  fpFD_SET(0, fds);
  tv.tv_sec := timeout_ms div 1000;
  tv.tv_usec := (timeout_ms mod 1000) * 1000;
  if fpSelect(1, @fds, nil, nil, @tv) > 0 then begin
    if fpRead(0, ch, 1) = 1 then
      ReadByte := ch
    else
      ReadByte := -1;
  end else
    ReadByte := -1;
end;

function ParseSGRMouse(var ev: TMouseEvent): boolean;
{ Parse SGR mouse: ESC [ < Cb ; Cx ; Cy M/m }
var
  cb, cx, cy: integer;
  ch: integer;
  val: integer;
  field: integer;
  release: boolean;
begin
  ParseSGRMouse := false;
  cb := 0; cx := 0; cy := 0;
  field := 0; val := 0;
  repeat
    ch := ReadByte(100);
    if ch < 0 then exit;
    if (ch >= ord('0')) and (ch <= ord('9')) then
      val := val * 10 + (ch - ord('0'))
    else if ch = ord(';') then begin
      case field of
        0: cb := val;
        1: cx := val;
      end;
      inc(field);
      val := 0;
    end else if (ch = ord('M')) or (ch = ord('m')) then begin
      case field of
        2: cy := val;
        1: begin cy := val; cx := cb; cb := 0; end; { fallback }
      end;
      release := (ch = ord('m'));
      break;
    end else
      exit; { unexpected char }
  until false;

  ev.X := cx;
  ev.Y := cy;
  ev.Shift := (cb and 4) <> 0;
  ev.Alt   := (cb and 8) <> 0;
  ev.Ctrl  := (cb and 16) <> 0;

  if release then
    ev.Action := mRelease
  else if (cb and 32) <> 0 then
    ev.Action := mMove
  else
    ev.Action := mPress;

  case (cb and 3) of
    0: ev.Button := mbLeft;
    1: ev.Button := mbMiddle;
    2: ev.Button := mbRight;
    3: if release then ev.Button := mbNone else ev.Button := mbLeft;
  end;
  if (cb and 64) <> 0 then begin
    ev.Action := mPress;
    if (cb and 1) = 0 then ev.Button := mbWheelUp
    else ev.Button := mbWheelDown;
  end;
  ParseSGRMouse := true;
end;

function TextMousePoll(var ev: TMouseEvent): boolean;
var ch: integer;
begin
  TextMousePoll := false;
  ev.Action := mNone;
  ev.Button := mbNone;
  if not MouseActive then exit;

  ch := ReadByte(0);
  if ch <> 27 then exit;     { ESC }
  ch := ReadByte(50);
  if ch <> ord('[') then exit; { CSI }
  ch := ReadByte(50);
  if ch = ord('<') then       { SGR mode }
    TextMousePoll := ParseSGRMouse(ev);
end;

function TextMouseSupported: boolean;
begin
  TextMouseSupported := true;
end;

procedure TextMouseShow;
begin
  { xterm handles cursor visibility }
end;

procedure TextMouseHide;
begin
end;

{$ENDIF}

{ ══════════════════════════════════════════════════════════════
  WINDOWS: Console API
  ══════════════════════════════════════════════════════════════ }
{$IFDEF WINDOWS}

const
  ENABLE_QUICK_EDIT_MODE = $0040;
  MOUSE_WHEELED = $0004;
  FROM_LEFT_2ND_BUTTON_PRESSED = $0004;

var
  ConsoleHandle: THandle;
  OldConsoleMode: DWORD;

function TextMouseInit: boolean;
var mode: DWORD;
begin
  ConsoleHandle := GetStdHandle(STD_INPUT_HANDLE);
  GetConsoleMode(ConsoleHandle, OldConsoleMode);
  mode := OldConsoleMode or ENABLE_MOUSE_INPUT;
  mode := mode and (not ENABLE_QUICK_EDIT_MODE);
  SetConsoleMode(ConsoleHandle, mode);
  MouseActive := true;
  TextMouseInit := true;
end;

procedure TextMouseDone;
begin
  if MouseActive then begin
    SetConsoleMode(ConsoleHandle, OldConsoleMode);
    MouseActive := false;
  end;
end;

function TextMousePoll(var ev: TMouseEvent): boolean;
var
  ir: INPUT_RECORD;
  count: DWORD;
begin
  TextMousePoll := false;
  ev.Action := mNone;
  ev.Button := mbNone;
  if not MouseActive then exit;

  if PeekConsoleInput(ConsoleHandle, ir, 1, count) and (count > 0) then begin
    ReadConsoleInput(ConsoleHandle, ir, 1, count);
    if ir.EventType = _MOUSE_EVENT then begin
      ev.X := ir.Event.MouseEvent.dwMousePosition.X + 1;
      ev.Y := ir.Event.MouseEvent.dwMousePosition.Y + 1;
      ev.Shift := (ir.Event.MouseEvent.dwControlKeyState and SHIFT_PRESSED) <> 0;
      ev.Ctrl := (ir.Event.MouseEvent.dwControlKeyState and
                  (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0;
      ev.Alt := (ir.Event.MouseEvent.dwControlKeyState and
                 (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0;

      if ir.Event.MouseEvent.dwEventFlags = 0 then begin
        { button press/release }
        if (ir.Event.MouseEvent.dwButtonState and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then begin
          ev.Action := mPress; ev.Button := mbLeft;
        end else if (ir.Event.MouseEvent.dwButtonState and RIGHTMOST_BUTTON_PRESSED) <> 0 then begin
          ev.Action := mPress; ev.Button := mbRight;
        end else if (ir.Event.MouseEvent.dwButtonState and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then begin
          ev.Action := mPress; ev.Button := mbMiddle;
        end else begin
          ev.Action := mRelease; ev.Button := mbNone;
        end;
        TextMousePoll := true;
      end else if ir.Event.MouseEvent.dwEventFlags = MOUSE_MOVED then begin
        ev.Action := mMove;
        if (ir.Event.MouseEvent.dwButtonState and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then
          ev.Button := mbLeft
        else
          ev.Button := mbNone;
        TextMousePoll := true;
      end else if ir.Event.MouseEvent.dwEventFlags = MOUSE_WHEELED then begin
        ev.Action := mPress;
        if smallint(HiWord(ir.Event.MouseEvent.dwButtonState)) > 0 then
          ev.Button := mbWheelUp
        else
          ev.Button := mbWheelDown;
        TextMousePoll := true;
      end;
    end;
  end;
end;

function TextMouseSupported: boolean;
begin
  TextMouseSupported := true;
end;

procedure TextMouseShow; begin end;
procedure TextMouseHide; begin end;

{$ENDIF}

{ ══════════════════════════════════════════════════════════════
  DOS (go32v2 + i8086): INT 33h mouse driver
  ══════════════════════════════════════════════════════════════ }
{$IFDEF GO32V2}
{$DEFINE DOS_MOUSE}
{$ENDIF}
{$IFDEF MSDOS}
{$DEFINE DOS_MOUSE}
{$ENDIF}

{$IFDEF DOS_MOUSE}
var
  LastButtons: word = 0;

function TextMouseInit: boolean;
var r: registers;
begin
  r.ax := $0000;  { reset mouse }
  Intr($33, r);
  MouseActive := (r.ax = $FFFF);
  if MouseActive then begin
    r.ax := $0001; { show cursor }
    Intr($33, r);
  end;
  TextMouseInit := MouseActive;
end;

procedure TextMouseDone;
var r: registers;
begin
  if MouseActive then begin
    r.ax := $0002; { hide cursor }
    Intr($33, r);
    MouseActive := false;
  end;
end;

function TextMousePoll(var ev: TMouseEvent): boolean;
var
  r: registers;
  buttons: word;
begin
  TextMousePoll := false;
  ev.Action := mNone;
  ev.Button := mbNone;
  ev.Shift := false;
  ev.Ctrl := false;
  ev.Alt := false;
  if not MouseActive then exit;

  r.ax := $0003;  { get position + button status }
  Intr($33, r);
  ev.X := (r.cx div 8) + 1;  { pixel → column }
  ev.Y := (r.dx div 8) + 1;  { pixel → row }
  buttons := r.bx;

  if buttons <> LastButtons then begin
    if (buttons and 1) <> 0 then begin
      ev.Action := mPress; ev.Button := mbLeft;
    end else if (buttons and 2) <> 0 then begin
      ev.Action := mPress; ev.Button := mbRight;
    end else if (buttons and 4) <> 0 then begin
      ev.Action := mPress; ev.Button := mbMiddle;
    end else begin
      ev.Action := mRelease; ev.Button := mbNone;
    end;
    LastButtons := buttons;
    TextMousePoll := true;
  end;
end;

function TextMouseSupported: boolean;
var r: registers;
begin
  r.ax := $0000;
  Intr($33, r);
  TextMouseSupported := (r.ax = $FFFF);
end;

procedure TextMouseShow;
var r: registers;
begin
  r.ax := $0001;
  Intr($33, r);
end;

procedure TextMouseHide;
var r: registers;
begin
  r.ax := $0002;
  Intr($33, r);
end;
{$ENDIF}

{ ══════════════════════════════════════════════════════════════
  STUB: OS/2 + anything else
  ══════════════════════════════════════════════════════════════ }
{$IFNDEF UNIX}
{$IFNDEF WINDOWS}
{$IFNDEF DOS_MOUSE}

function TextMouseInit: boolean;
begin
  TextMouseInit := false;
end;

procedure TextMouseDone;
begin
end;

function TextMousePoll(var ev: TMouseEvent): boolean;
begin
  ev.Action := mNone;
  ev.Button := mbNone;
  TextMousePoll := false;
end;

function TextMouseSupported: boolean;
begin
  TextMouseSupported := false;
end;

procedure TextMouseShow; begin end;
procedure TextMouseHide; begin end;

{$ENDIF}
{$ENDIF}
{$ENDIF}

end.
