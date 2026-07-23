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
Unit MIS_Events;

{$I M_OPS.PAS}

Interface

Uses
  {$IFDEF WINDOWS}
    Windows,
  {$ENDIF}
  {$IFDEF UNIX}
    BaseUnix,
    Unix,
  {$ENDIF}
  {$IFDEF OS2}
    SysUtils,   // ExecuteProcess / GetEnvironmentVariable for ShellExec
  {$ENDIF}
  {$IFDEF GO32V2}
    SysUtils,   // DOS: ExecuteProcess / GetEnvironmentVariable for ShellExec
  {$ENDIF}
//  m_Threads,
  Classes,
  m_Strings,
  m_FileIO,
  m_DateTime,
  BBS_Records;

Type
  TEventEngine = Class(TThread)
    InEvent    : Boolean;
    Event      : RecEvent;
    EventFile  : File of RecEvent;
    NextEvent  : RecEvent;
    NextMins   : LongInt;
    NextPos    : LongInt;
    bbsConfig  : RecConfig;
    EventList  : TStringList;
    StatusList : TStringList;
    Updated    : Boolean;

    Constructor Create (Cfg: RecConfig);
    Destructor  Destroy; Override;
    Procedure   Execute; Override;
    Procedure   BuildEventStatus (First: Boolean);
    Procedure   Status (Str: String);
    Function    EventExecTime (WhichEvent: RecEvent) : LongInt;
    Function    ExecuteEvents : Boolean;
    Function    ShellExec (PPath, PCmd: String; PFlags: LongInt) : LongInt;
  End;

Implementation

Function Min2Day (Mins: LongInt) : String;
Var
  Days    : LongInt;
  Hours   : LongInt;
  Minutes : LongInt;
Begin
  If Mins = 0 Then
    Result := 'Now'
  Else Begin
    Days    := Mins DIV 1440;
    Hours   := (Mins DIV 60) MOD 24;
    Minutes := Mins MOD 60;
    Result  := strI2S(Days) + 'd ' + strI2S(Hours) + 'h ' + strI2S(Minutes) + 'm';
  End;

  Result := strPadL(Result, 10, ' ');
End;

Constructor TEventEngine.Create (Cfg: RecConfig);
Begin
  Inherited Create(False);

  bbsConfig  := Cfg;
  InEvent    := False;
  EventList  := TStringList.Create;
  StatusList := TStringList.Create;
End;

Destructor TEventEngine.Destroy;
Begin
  EventList.Free;
  StatusList.Free;

  Inherited Destroy;
End;

{$IFDEF WINDOWS}
Function TEventEngine.ShellExec (PPath, PCmd: String; PFlags: LongInt) : LongInt;
Var
  SI  : TStartupInfo;
  PI  : TProcessInformation;
Begin
  If PPath <> '' Then
    DirChange (PPath);

  PCmd := PCmd + #0;

  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);

  SI.CB          := SizeOf(TStartupInfo);
  SI.wShowWindow := SW_SHOWMINNOACTIVE;
  SI.dwFlags     := SI.dwFlags or STARTF_USESHOWWINDOW;

  If CreateProcess(NIL, @PCmd[1],
    NIL,
    NIL,
    True,
    Create_New_Console,
    NIL,
    NIL,
    SI,
    PI) Then
      WaitForSingleObject (PI.hProcess, INFINITE);

  GetExitCodeProcess(PI.hProcess, @Result);

  DirChange (bbsConfig.SystemPath);
End;
{$ENDIF}
{$IFDEF UNIX}
Function TEventEngine.ShellExec (PPath, PCmd: String; PFlags: LongInt) : LongInt;
Begin
  If PPath <> '' Then
    DirChange (PPath);

  Result := wExitStatus(fpSystem(PCmd));

  DirChange (bbsConfig.SystemPath);
End;
{$ENDIF}
{$IFDEF OS2}
// OS/2: run the command through the RTL's ExecuteProcess (via the command
// interpreter, so redirection / built-ins work as in the shell paths above).
Function TEventEngine.ShellExec (PPath, PCmd: String; PFlags: LongInt) : LongInt;
Begin
  If PPath <> '' Then
    DirChange (PPath);

  Result := ExecuteProcess (GetEnvironmentVariable('COMSPEC'), '/C ' + PCmd);

  DirChange (bbsConfig.SystemPath);
End;
{$ENDIF}

{$IFDEF GO32V2}
// DOS: run the command through COMMAND.COM (COMSPEC) with /C, same model as
// OS/2. Single-tasking, so this blocks until the child exits - which is the
// correct behaviour for a DOS event shell-out.
Function TEventEngine.ShellExec (PPath, PCmd: String; PFlags: LongInt) : LongInt;
Begin
  If PPath <> '' Then
    DirChange (PPath);

  Result := ExecuteProcess (GetEnvironmentVariable('COMSPEC'), '/C ' + PCmd);

  DirChange (bbsConfig.SystemPath);
End;
{$ENDIF}

Procedure TEventEngine.Status (Str: String);
Var
  T : Text;
Begin
  If StatusList.Count = 8 Then
    StatusList.Delete(0);

  Str := FormatDate(CurDateDT, 'NNN DD HH:II') + ' ' + Str;

  StatusList.Add(Str);

  If bbsConfig.iNetLogging Then
    AppendText (bbsConfig.LogsPath + 'server_events.log', Str);

  Updated := True;
End;

Function TEventEngine.ExecuteEvents : Boolean;
Var
  SemFile : String;
  Count   : Byte;
Begin
  Result := False;

  Assign  (EventFile, bbsConfig.DataPath + 'event.dat');
  {$I-} ioReset (EventFile, SizeOf(RecEvent), fmRWDN); {$I+}

  // A41: if the config editor has event.dat open, skip this cycle gracefully
  // instead of creating a new empty file (which destroyed all events) or
  // proceeding on a never-opened file handle (which could hang the thread).
  If IoResult <> 0 Then Exit;

  While Not Eof(EventFile) And Not Result Do Begin
    ioRead (EventFile, Event);

    If Not Event.Active Then Continue;

    Case Event.ExecType of
      0 : Continue;
      1 : Begin
            For Count := 1 to strWordCount(Event.SemaFile, '|') Do Begin
              SemFile := strWordGet(Count, Event.SemaFile, '|');

              If Pos(PathChar, SemFile) = 0 Then
                SemFile := bbsConfig.SemaPath + SemFile;

              If FileExist(SemFile) Then Begin
                Result := True;

                Break;
              End;
            End;
          End;
      2 : If (EventExecTime(Event) <= 0)  and (EventExecTime(Event) <> -1000000) and (DateDos2Str(Event.LastRan, 1) <> DateDos2Str(CurDateDos, 1)) Then Begin
            Result := True;

            Break;
          End;
      // A61: Hourly event — execute when the current minute matches
      // the event's minute and it hasn't already run this hour.
      // ExecTime stores hour*60+min from config, so use MOD 60.
      // LastRan stores the hour (TimerMinutes DIV 60) of last execution.
      3 : If (TimerMinutes MOD 60 = Event.ExecTime MOD 60) and (Event.LastRan <> TimerMinutes DIV 60) Then Begin
            Result := True;

            Break;
          End;
    End;
  End;

  If Result Then Begin
    If Event.ExecType = 3 Then
      Event.LastRan := TimerMinutes DIV 60  // A61: store current hour
    Else
      Event.LastRan := CurDateDos;

    ioSeek  (EventFile, FilePos(EventFile) - 1);
    ioWrite (EventFile, Event);
  End;

  Close (EventFile);

  If Result Then Begin
    Status ('Executing "' + Event.Name + '"');

    Case Event.ExecType of
      1 : Begin
            Status ('Detected semaphore: ' + SemFile);

            For Count := 1 to strWordCount(Event.SemaFile, '|') Do Begin
              SemFile := strWordGet(Count, Event.SemaFile, '|');

              If Pos(PathChar, SemFile) = 0 Then
                SemFile := bbsConfig.SemaPath + SemFile;

              FileErase(SemFile);
            End;
          End;
    End;

    For Count := 1 to strWordCount(Event.Shell, '|') Do Begin
      SemFile := strWordGet(Count, Event.Shell, '|');

      Status ('Command line: ' + SemFile);

      InEvent := True;
      Status ('Process result ' + strI2S(ShellExec('', SemFile, 0)));
      InEvent := False;
    End;
  End;
End;

Procedure TEventEngine.BuildEventStatus;
Var
  Temp : LongInt;
Begin
  EventList.Clear;

  NextEvent.Active := False;
  NextEvent.Name   := 'None';
  NextMins         := -1;
  NextPos          := -1;

  Assign  (EventFile, bbsConfig.DataPath + 'event.dat');
  {$I-} ioReset (EventFile, SizeOf(RecEvent), fmRWDN); {$I+}

  // A41: if the config editor has event.dat open, keep the old event list and
  // try again next cycle.
  If IoResult <> 0 Then Exit;

  While Not Eof(EventFile) Do Begin
    ioRead (EventFile, Event);

    If Not Event.Active Then Continue;

    If Event.ExecType = 1 Then Begin
      EventList.Add (' ' + strPadR(Event.Name, 32, ' ') + ' File     Waiting');

      Continue;
    End;

    // A41: re-initialize type-3 (interval) events when their LastRan doesn't
    // make sense as a timer value — this happens when the sysop changes an
    // event's type from 2 (shell/daily, LastRan is a DOS date) to 3 (interval,
    // LastRan should be TimerMinutes).  Without this, a stale DOS-date LastRan
    // causes the interval calculation to misfire.  Also initialize on first run.
    If (Event.ExecType = 3) and (First or (Event.LastRan > 1440)) Then Begin
      Event.LastRan := TimerMinutes;

      ioSeek  (EventFile, FilePos(EventFile) - 1);
      ioWrite (EventFile, Event);
    End;

    Temp := EventExecTime(Event);

    If Temp = -1000000 Then Continue;

    Case Event.ExecType of
      0 : EventList.Add(' ' + strPadR(Event.Name, 31, ' ') + '   BBS  ' + Min2Day(Temp));
      2 : EventList.Add(' ' + strPadR(Event.Name, 31, ' ') + ' Shell  ' + Min2Day(Temp));
      3 : EventList.Add(' ' + strPadR(EVent.Name, 31, ' ') + ' Inter  ' + Min2Day(Temp));
    End;

    If Event.ExecType > 1 Then
      If (NextMins = -1) or ((NextMins <> -1) and (Temp < NextMins)) Then Begin

        NextMins  := EventExecTime(Event);
        NextEvent := Event;
        NextPos   := EventList.Count;
      End;
  End;

  Close (EventFile);

  Updated := True;
End;

Function TEventEngine.EventExecTime (WhichEvent: RecEvent) : LongInt;
Var
  Today : Byte;
  Found : Boolean;
  Temp  : LongInt;
Begin
//  Result := 0;
  Result := -1000000;

  Case WhichEvent.ExecType of
    // A61: Hourly event type. ExecTime stores hour*60+min from config.
    // Only the minute part matters. Executes once per hour at that minute.
    3 : Begin
          Result := 0;
          Temp := TimerMinutes MOD 60;

          If Temp <= (WhichEvent.ExecTime MOD 60) Then
            Result := (WhichEvent.ExecTime MOD 60) - Temp
          Else
            Result := 60 - Temp + (WhichEvent.ExecTime MOD 60);
        End;
  Else
    Temp := WhichEvent.ExecTime;

    For Today := 0 to 6 Do Begin
      Found := WhichEvent.ExecDays[Today];

      If Found Then Break;
    End;

    If Not Found Then Exit;

    Today  := DayOfWeek(CurDateDos);
    Result := 0;

    If WhichEvent.ExecDays[Today] and (TimerMinutes > Temp) Then Begin
      Inc (Result, 1440);

      If Today = 6 Then Today := 0 Else Inc (Today);
    End;

    While Not WhichEvent.ExecDays[Today] Do Begin
      Inc (Result, 1440);
      Inc (Today);

      If Today > 6 Then Today := 0;
    End;
  End;

  If Temp > TimerMinutes Then
    Result := Result + Temp - TimerMinutes
  Else
  If Temp < TimerMinutes Then
    Result := Result - TimerMinutes + Temp
  Else
    Result := 0;
End;

Procedure TEventEngine.Execute;
Var
  WaitCount : LongInt;
//  Res       : Boolean;
Begin
  BuildEventStatus(True);

  WaitCount := 1;
//  Res       := True;

  Status ('Event system started');

  While Not Terminated Do Begin
    Dec    (WaitCount);
    WaitMS (500);

(*
    If Res Then Begin
      If NextEvent.Name = 'None' Then
        Status ('There are no scheduled events')
      Else
       Status ('Next event is "' + NextEvent.Name + '" in ' + strComma(NextMins) + ' minutes');

      Res := False;
    End;
*)
    If Terminated Then Exit;

    If WaitCount <= 0 Then Begin
//      Res := ExecuteEvents;
      ExecuteEvents;
      BuildEventStatus(False);

      WaitCount := 120;
    End;
  End;
End;

End.
