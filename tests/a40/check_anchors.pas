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
