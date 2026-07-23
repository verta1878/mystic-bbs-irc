//
// This file is part of the Mystic BBS IRC Fork.
//
// Copyright (C) 2026 Mystic BBS IRC Fork Contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
program check_anchors;
{$MODE DELPHI}
uses BBS_Records;
var ok: Boolean;
procedure Chk(Name: String; Got, Want: LongInt);
begin
  Write(Name, ' = ', Got, ' (want ', Want, ') ');
  if Got = Want then WriteLn('OK')
  else begin WriteLn('*** MISMATCH ***'); ok := False; end;
end;
begin
  ok := True;
  Chk('RecEchoMailNode', SizeOf(RecEchoMailNode), 901);
  Chk('RecConfig',       SizeOf(RecConfig),       5282);
  Chk('RecUser',         SizeOf(RecUser),         1536);
  Chk('RecTheme',        SizeOf(RecTheme),        768);
  if ok then WriteLn('ALL ANCHORS OK') else begin WriteLn('ANCHOR FAILURE'); Halt(1); end;
end.
