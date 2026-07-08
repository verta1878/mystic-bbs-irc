// ====================================================================
// mystic_crypt : optional cryptlib (SSH/TLS) example for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// cl_demo - checks for cryptlib and reports whether secure sessions are
// available, mirroring stock Mystic's "Cryptlib not detected" behaviour.  It
// shows the session-setup path without opening a live network connection (a
// real SSH/TLS handshake needs a socket + host key and is a sysop-side test).
// ====================================================================

Program cl_demo;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Uses
  SysUtils,
  cl_Bind, cl_Session;

Var
  Sess : TCryptSession;
Begin
  WriteLn('Mystic cryptlib (SSH/TLS) example (mystic_crypt)');
  WriteLn('------------------------------------------------');

  Sess := TCryptSession.Create;
  Try
    If Not Sess.Available Then Begin
      WriteLn('Cryptlib not detected; SSL/SSH capabilities disabled.');
      WriteLn('  cryptlib loaded : ', CryptlibLoaded);
      WriteLn('(This is the same message stock Mystic prints with no cl32.dll.');
      WriteLn(' Drop cl32.dll / libcl in place to enable secure sessions.)');
      Halt(0);
    End;

    WriteLn('Cryptlib detected and initialised - secure sessions available.');
    WriteLn;
    WriteLn('A real SSH server would now:');
    WriteLn('  1. accept a TCP connection (as MIS does for telnet today)');
    WriteLn('  2. StartSession(crSSHServer, socketHandle, hostKey)');
    WriteLn('  3. talk to the BBS through the usual TIOBase stream, with');
    WriteLn('     Send()/Recv() doing cryptPushData/cryptPopData underneath.');
    WriteLn;
    WriteLn('TLS on SMTP/POP3 is the same with crTLSServer.');
  Finally
    Sess.Free;
  End;
End.
