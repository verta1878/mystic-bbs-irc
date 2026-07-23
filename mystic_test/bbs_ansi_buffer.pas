Unit BBS_Ansi_Buffer;

// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================
//
// A61: Output buffering wrapper for batch screen operations.
//
// When generating default menus, loading messages in the FS reader,
// drawing the message index list, or filling the LB file list, Mystic
// makes many small I/O calls (OutFull, OutRaw, AnsiColor, etc.) that
// each trigger a BufFlush.  TAnsiBuffer suppresses intermediate flushes
// so the entire screen update is sent as one chunk, reducing visible
// flicker over telnet/SSH and improving throughput.
//
// Usage:
//   Session.io.Buffer.Start;    // begin buffering
//   ... draw page ...
//   Session.io.Buffer.Stop;     // flush everything at once
//
// Nested Start/Stop is safe — only the outermost Stop flushes.
// ====================================================================

{$I M_OPS.PAS}

Interface

Type
  TAnsiBuffer = Class
    Depth    : Integer;  // nesting depth — only flush at depth 0
    Paused   : Boolean;  // TRUE while buffering is active

    Constructor Create;
    Destructor  Destroy; Override;
    Procedure   Start;
    Procedure   Stop;
  End;

Implementation

Constructor TAnsiBuffer.Create;
Begin
  Inherited Create;

  Depth  := 0;
  Paused := False;
End;

Destructor TAnsiBuffer.Destroy;
Begin
  Inherited Destroy;
End;

Procedure TAnsiBuffer.Start;
Begin
  Inc (Depth);
  Paused := True;
End;

Procedure TAnsiBuffer.Stop;
Begin
  If Depth > 0 Then Dec (Depth);

  If Depth = 0 Then
    Paused := False;
End;

End.
