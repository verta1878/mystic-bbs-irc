// ====================================================================
// mystic_mailer : sample FidoNet mailer front-end for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on/sample for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// mailer - a sample FrontDoor-style front-end.  It owns the modem, answers
// the phone, and CLASSIFIES the caller into one of three kinds:
//
//     EMSI mailer  -> run the EMSI handshake (mlr_emsi), then [stub] Zmodem
//     BinkP mailer -> [seam] hand the line to Mystic's BinkP engine via
//                     TIOSerial (mlr_binkp documents the hand-off)
//     human        -> [stub] spawn Mystic bound to the serial line
//
// This is a SAMPLE: the EMSI handshake is real; the mail-bundle transfer,
// the BinkP-over-serial run, and the Mystic spawn are marked stubs/seams
// because each depends on a heavier piece (Zmodem-over-serial, the shared
// TIOSerial class).  It builds on the mystic_modem module and changes
// NOTHING in the Mystic source tree.
// ====================================================================

Program mailer;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Uses
  SysUtils,
  mdm_Serial,
  mdm_Modem,
  mdm_Config,
  mlr_Emsi,
  mlr_Binkp,
  mlr_MisWfc;

Type
  TCallerKind = (ckUnknown, ckEmsi, ckBinkp, ckHuman);

// Our own node identity for the EMSI_DAT we present.  A real build reads
// these from config; hard-coded here for the sample.
Const
  MY_ADDR   = '1:1/0';
  MY_SYS    = 'Mystic Sample Node';
  MY_SYSOP  = 'Sysop';
  MY_LOC    = 'Somewhere';
  MY_PWD    = '';                 // session password (empty = none)

// Listen briefly after CONNECT and classify who called.
Function ClassifyCaller (Ser: TModemSerial; Out Sniff: String): TCallerKind;
Var
  Elapsed : LongInt;
  Chunk   : String;
  BD      : TBinkpDetect;
Begin
  Result  := ckUnknown;
  Sniff   := '';
  Elapsed := 0;

  // Give the caller ~4 seconds to announce itself.  Mailers speak first
  // (EMSI_INQ or a BinkP frame); a human usually just sits or hits a key.
  While Elapsed < 4000 Do Begin
    Chunk := Ser.ReadAvail;
    If Chunk <> '' Then Begin
      Sniff := Sniff + Chunk;

      If TEmsi.LooksLikeEmsi(Sniff) Then Begin
        Result := ckEmsi; Exit;
      End;

      If TBinkpSeam.LooksLikeBinkp(Sniff, BD) Then Begin
        Result := ckBinkp; Exit;
      End;

      // Printable input that isn't a mailer marker -> treat as a human.
      If (Length(Sniff) >= 1) Then Begin
        Result := ckHuman; Exit;
      End;
    End;
    Sleep(100);
    Inc(Elapsed, 100);
  End;

  // Silence for the whole window: assume a human who hasn't typed yet.
  Result := ckHuman;
End;

// --- the three branches ------------------------------------------------

Procedure HandleEmsi (Ser: TModemSerial);
Var
  Emsi : TEmsi;
  Sess : TEmsiSession;
Begin
  WriteLn('  [emsi] EMSI mailer detected - running handshake');
  Emsi := TEmsi.Create(Ser);
  Try
    Emsi.SendInq;
    Emsi.SendDat(MY_ADDR, MY_SYS, MY_SYSOP, MY_LOC, MY_PWD);

    If Emsi.RecvDat(Sess) Then Begin
      WriteLn('  [emsi] handshake OK');
      WriteLn('  [emsi]   remote addr : ', Sess.Addresses);
      WriteLn('  [emsi]   remote sys  : ', Sess.SysName);
      WriteLn('  [emsi]   protocols   : ', Sess.Protocols);
      WriteLn('  [emsi] STUB: would now Zmodem the mail bundles, then the');
      WriteLn('  [emsi]       existing tosser (mutil_echocore) processes them.');
    End Else
      WriteLn('  [emsi] handshake failed (no/!bad EMSI_DAT)');
  Finally
    Emsi.Free;
  End;
End;

Procedure HandleBinkp (Ser: TModemSerial; Const Sniff: String);
Var
  Seam : TBinkpSeam;
Begin
  Seam := TBinkpSeam.Create(Ser);
  Try
    Seam.RunSessionStub('opening frame len=' + IntToStr(Length(Sniff)));
  Finally
    Seam.Free;
  End;
End;

Procedure HandleHuman (Ser: TModemSerial);
Begin
  WriteLn('  [human] no mailer handshake - treating as a human caller');
  Ser.WriteStr(#13#10'Connected to Mystic (sample front-end).'#13#10);
  WriteLn('  [human] SEAM: would spawn Mystic bound to this serial line via');
  WriteLn('  [human]       TIOSerial (Client := TIOSerial over the modem line).');
End;

// --- main --------------------------------------------------------------

Var
  Cfg   : TModemConfig;
  Ser   : TModemSerial;
  Mdm   : TModem;
  Sniff : String;
  Kind  : TCallerKind;
  IniPath : String;
  WfcStats : TMailerWfcStats;
Begin
  WriteLn('Mystic sample mailer front-end (mystic_mailer)');
  WriteLn('----------------------------------------------');

  IniPath := 'modem.ini';
  If ParamCount >= 1 Then IniPath := ParamStr(1);
  Cfg := LoadModemConfig(IniPath);

  Ser := TModemSerial.Create;
  Mdm := TModem.Create(Ser);
  Try
    If Cfg.LocalMode Then Begin
      WriteLn('Local mode: no modem - front-end has nothing to answer.');
      Halt(0);
    End;

    If Not Ser.Open(Cfg.Device, Cfg.Baud, Cfg.HardwareFlow) Then Begin
      WriteLn('ERROR: cannot open ', Cfg.Device);
      Halt(1);
    End;

    If Not Mdm.Initialise(Cfg.InitString) Then Begin
      WriteLn('ERROR: modem did not respond on ', Cfg.Device);
      Halt(1);
    End;

    WriteLn('Waiting for a call on ', Cfg.Device, ' (', Cfg.Baud, ' bps)...');

    // Show the MIS-style mailer WFC status screen.
    WfcStats.LineState  := 'WAITING';
    WfcStats.CallerKind := '(none)';
    WfcStats.Mode       := 'answer';
    WfcStats.RemoteAddr := '';
    WfcStats.RemoteSys  := '';
    WfcStats.Sessions   := 0;
    WfcStats.Humans     := 0;
    WfcStats.LastEvent  := '(none yet)';
    DrawMailerWfc(MY_ADDR, MY_SYS, WfcStats);

    // Simplified answer loop: wait for ring, answer, classify, route.
    While True Do Begin
      If Mdm.IsRinging Then Begin
        WriteLn('RING - answering');
        If Mdm.Answer Then Begin
          WriteLn('CONNECT ', Mdm.ConnBaud, ' - classifying caller');
          Kind := ClassifyCaller(Ser, Sniff);

          Case Kind of
            ckEmsi  : HandleEmsi(Ser);
            ckBinkp : HandleBinkp(Ser, Sniff);
            ckHuman : HandleHuman(Ser);
          Else
            WriteLn('  [?] could not classify caller');
          End;

          Mdm.HangUp;
          WriteLn('Call ended - waiting for next.');
        End;
      End;
      Sleep(200);
    End;

  Finally
    Mdm.Free;
    Ser.Free;
  End;
End.
