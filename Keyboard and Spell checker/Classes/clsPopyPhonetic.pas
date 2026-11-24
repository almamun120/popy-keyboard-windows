{
  =============================================================================
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  =============================================================================

  Popy Layout - phonetic typing engine (Latin letters -> Bangla).

  This unit is intentionally free of any VCL / Windows dependency so that it can
  be compiled and unit-tested on its own (see tests/PopyTest.pas, which is run
  by the GitHub workflow with Free Pascal).

  The whole source file is plain ASCII: every Bangla character is written as a
  code point (#$09XX), so file encoding can never corrupt it.

  Rules (all letters are treated as lower case; Shift never changes the output):
    vowels      o a i ii u uu rrr e oi oo ou
    consonants  k kh g gh nng c ch j jh nnn tt tth dd ddh nn t th d dh n p f ph
                b bh v m y z r l s ss sss h x rr rrh
    signs       ng = ANUSVARA, qw = VISARGA, qq = CHANDRABINDU, qt = KHANDA TA,
                qk = TAKA, '.' = DARI, 0-9 = Bangla digits, ',,' = HASANTA+ZWNJ
    w           ba-phala after a consonant, otherwise the vowel O
    b           always an independent BA (never joins)
    Shift tap   (the POPY_SHIFT token, #1) = "do not merge automatically": before a consonant it
                forces the join (t, SHIFT, t = TA-hasanta-TA; k, SHIFT, f = KA-hasanta-PHA), before a
                vowel it gives the independent vowel (b, o, SHIFT, i = BOI). Shows as an "s" marker.
    q           special letters and signs only: qq qw qt qk qh qz qs qx qn qr q. q,
                (any other q is only a neutral separator; see docs/PopyLayout.md)
}

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
{$ENDIF}
unit clsPopyPhonetic;

interface

const
  POPY_LAYOUT_NAME = 'popy*';
  { A tapped Shift is stored in the Latin buffer as this character. }
  POPY_SHIFT = #1;

var
  { Greedy mode (default on): the listed conjunct pairs join by themselves. Off: NOTHING joins by
    itself (also reph, ra-phala, ya-phala and qn need a Shift tap); r and z are independent letters
    and 'o' has no role after a consonant. }
  PopyGreedyMode: Boolean = True;

  { Latin buffer -> Bangla text (final text, no markers). }
function PopyConvert(const Input: string): string;

{ Text to show while typing: like PopyConvert, but when the last key is a
  consonant followed by 'o' (or a break 'q') that adds nothing to the text, the
  letter is appended so the user can see it. It disappears with the next key or
  when the word ends. HasMarker tells whether such a letter was appended. }
function PopyPreview(const Input: string; out HasMarker: Boolean): string;

{ True when the layout identifier means the built-in Popy layout. }
function IsPopyLayoutName(const LayoutName: string): Boolean;

implementation

uses
  SysUtils;

const
  HASANTA = #$09CD;
  ZWNJ    = #$200C;
  ZWJ     = #$200D;
  NUKTA   = #$09BC;

  BN_RA = #$09B0;
  BN_BA = #$09AC;
  BN_YA = #$09AF; // YA (the one used for ya-phala)
  BN_NA = #$09A8;
  BN_NNA = #$09A3;
  BN_VISARGA = #$0983;
  BN_ANUSVARA = #$0982;
  BN_CANDRABINDU = #$0981;
  BN_KHANDA_TA = #$09CE;
  BN_TAKA = #$09F3;
  BN_DARI = #$0964;
  BN_VOWEL_O = #$0993;

  { The 163 consonant pairs that join by themselves (hasanta between them), as hex code points
    first+second. Every other pair stays separate; a tapped Shift forces a join. Source: conjunct_list_v2 sections 1+2. }
  PAIRS_HEX = ','
    + '09950995,0995099F,099509A4,099509A6,099509A8,099509AE,099509AF,099509B0,099509B2,'
    + '099509B7,099509B8,099609AF,099609B0,09970997,099709A7,099709A8,099709AE,099709AF,'
    + '099709B0,099709B2,099809A8,099809AF,099809B0,09990995,09990996,09990997,09990998,'
    + '099909AE,099909AF,099909B0,099A099A,099A099B,099A099E,099A09AF,099B09AF,099B09B0,'
    + '099C099C,099C099D,099C099E,099C09AF,099C09B0,099D09AF,099E099A,099E099B,099E099C,'
    + '099E099D,099F099F,099F09AE,099F09AF,099F09B0,09A009AF,09A109A1,09A109AE,09A109AF,'
    + '09A109B0,09A209AF,09A209B0,09A3099F,09A309A0,09A309A1,09A309A2,09A309AE,09A309AF,'
    + '09A409A8,09A409AE,09A409AF,09A409B0,09A509AF,09A509B0,09A60997,09A60998,09A609AD,'
    + '09A609AE,09A609AF,09A609B0,09A709A8,09A709AE,09A709AF,09A709B0,09A8099F,09A809A0,'
    + '09A809A1,09A809A4,09A809A5,09A809A6,09A809A7,09A809AE,09A809AF,09A809B8,09AA099F,'
    + '09AA09A4,09AA09A5,09AA09A8,09AA09AA,09AA09AF,09AA09B0,09AA09B2,09AA09B8,09AB099F,'
    + '09AB09AF,09AB09B0,09AB09B2,09AC099C,09AC09A6,09AC09A7,09AC09AF,09AC09B0,09AC09B2,'
    + '09AD09AF,09AD09B0,09AD09B2,09AE09A8,09AE09AA,09AE09AB,09AE09AD,09AE09AE,09AE09AF,'
    + '09AE09B0,09AE09B2,09AF09AF,09B20995,09B20997,09B2099F,09B209A1,09B209AA,09B209AB,'
    + '09B209AE,09B209AF,09B209B2,09B6099A,09B6099B,09B609A4,09B609A8,09B609AE,09B609AF,'
    + '09B609B0,09B609B2,09B70995,09B7099F,09B709A0,09B709A3,09B709AA,09B709AB,09B709AE,'
    + '09B709AF,09B80995,09B80996,09B8099F,09B809A4,09B809A5,09B809A8,09B809AA,09B809AB,'
    + '09B809AE,09B809AF,09B809B0,09B809B2,09B909A3,09B909A8,09B909AE,09B909AF,09B909B0,'
    + '09B909B2,';

type
  TConsEntry = record
    Tok: string;
    Bn:  string;
  end;

  TVowelEntry = record
    Tok:   string;
    Indep: string;
    Kar:   string;
  end;

const
  ConsCount = 38;
  Consonants: array [0 .. ConsCount - 1] of TConsEntry = (
    (Tok: 'k'; Bn: #$0995),
    (Tok: 'kh'; Bn: #$0996),
    (Tok: 'g'; Bn: #$0997),
    (Tok: 'gh'; Bn: #$0998),
    (Tok: 'nng'; Bn: #$0999),
    (Tok: 'c'; Bn: #$099A),
    (Tok: 'ch'; Bn: #$099B),
    (Tok: 'j'; Bn: #$099C),
    (Tok: 'jh'; Bn: #$099D),
    (Tok: 'nnn'; Bn: #$099E),
    (Tok: 'tt'; Bn: #$099F),
    (Tok: 'tth'; Bn: #$09A0),
    (Tok: 'dd'; Bn: #$09A1),
    (Tok: 'ddh'; Bn: #$09A2),
    (Tok: 'nn'; Bn: #$09A3),
    (Tok: 't'; Bn: #$09A4),
    (Tok: 'th'; Bn: #$09A5),
    (Tok: 'd'; Bn: #$09A6),
    (Tok: 'dh'; Bn: #$09A7),
    (Tok: 'n'; Bn: #$09A8),
    (Tok: 'p'; Bn: #$09AA),
    (Tok: 'f'; Bn: #$09AB),
    (Tok: 'ph'; Bn: #$09AB),
    (Tok: 'b'; Bn: #$09AC),
    (Tok: 'bh'; Bn: #$09AD),
    (Tok: 'v'; Bn: #$09AD),
    (Tok: 'm'; Bn: #$09AE),
    (Tok: 'y'; Bn: #$09AF#$09BC),
    (Tok: 'z'; Bn: #$09AF),
    (Tok: 'r'; Bn: #$09B0),
    (Tok: 'l'; Bn: #$09B2),
    (Tok: 's'; Bn: #$09B8),
    (Tok: 'ss'; Bn: #$09B6),
    (Tok: 'sss'; Bn: #$09B7),
    (Tok: 'h'; Bn: #$09B9),
    (Tok: 'x'; Bn: #$0995#$09CD#$09B7),
    (Tok: 'rr'; Bn: #$09A1#$09BC),
    (Tok: 'rrh'; Bn: #$09A2#$09BC)
    );

  VowelCount = 11;
  Vowels: array [0 .. VowelCount - 1] of TVowelEntry = (
    (Tok: 'o'; Indep: #$0985; Kar: ''),
    (Tok: 'a'; Indep: #$0986; Kar: #$09BE),
    (Tok: 'i'; Indep: #$0987; Kar: #$09BF),
    (Tok: 'ii'; Indep: #$0988; Kar: #$09C0),
    (Tok: 'u'; Indep: #$0989; Kar: #$09C1),
    (Tok: 'uu'; Indep: #$098A; Kar: #$09C2),
    (Tok: 'rrr'; Indep: #$098B; Kar: #$09C3),
    (Tok: 'e'; Indep: #$098F; Kar: #$09C7),
    (Tok: 'oi'; Indep: #$0990; Kar: #$09C8),
    (Tok: 'oo'; Indep: #$0993; Kar: #$09CB),
    (Tok: 'ou'; Indep: #$0994; Kar: #$09CC)
    );

  BanglaDigits: array [0 .. 9] of Char = (#$09E6, #$09E7, #$09E8, #$09E9, #$09EA, #$09EB, #$09EC, #$09ED, #$09EE, #$09EF);

  { =============================================================================== }

function IsPopyLayoutName(const LayoutName: string): Boolean;
begin
  Result := LowerCase(LayoutName) = POPY_LAYOUT_NAME;
end;

{ =============================================================================== }

function FindConsonant(const Tok: string; out BnText: string): Boolean;
var
  K: Integer;
begin
  Result := False;
  for K := 0 to ConsCount - 1 do
    if Consonants[K].Tok = Tok then
    begin
      BnText := Consonants[K].Bn;
      Result := True;
      Exit;
    end;
end;

{ =============================================================================== }

function FindVowel(const Tok: string; out Indep, Kar: string): Boolean;
var
  K: Integer;
begin
  Result := False;
  for K := 0 to VowelCount - 1 do
    if Vowels[K].Tok = Tok then
    begin
      Indep := Vowels[K].Indep;
      Kar := Vowels[K].Kar;
      Result := True;
      Exit;
    end;
end;

{ =============================================================================== }

function StartsAt(const S, Sub: string; const At: Integer): Boolean;
begin
  Result := Copy(S, At, Length(Sub)) = Sub;
end;

{ =============================================================================== }

function IsLowerLatin(const C: Char): Boolean;
begin
  Result := (C >= 'a') and (C <= 'z');
end;

{ =============================================================================== }

// last output char is a plain RA (not already the second half of a conjunct)
function EndsWithPlainRa(const S: string): Boolean;
var
  L: Integer;
begin
  L := Length(S);
  Result := (L >= 1) and (S[L] = BN_RA) and ((L < 2) or (S[L - 1] <> HASANTA));
end;

{ Does consonant A + hasanta + B form a conjunct that joins automatically?
  RA (reph) joins every consonant. }
function JoinablePair(const A, B: Char): Boolean;
begin
  Result := (A = BN_RA) or (Pos(',' + IntToHex(Ord(A), 4) + IntToHex(Ord(B), 4) + ',', ',' + PAIRS_HEX) > 0);
end;

function IsConsLetter(const Ch: Char): Boolean;
begin
  Result := ((Ch >= #$0995) and (Ch <= #$09B9)) or (Ch = #$09DC) or (Ch = #$09DD) or (Ch = #$09DF) or (Ch = #$09CE) or
    (Ch = #$09BC);   // nukta: YYA (y) = U+09AF U+09BC ends in a nukta
end;

{ =============================================================================== }

function PopyRun(const Input: string; out Pending: Char): string;
var
  Src, Res, Tok, CV, VIndep, VKar, LastConsTok: string;
  I, N, Len, J, L:                 Integer;
  C, Nx, Aft:                      Char;
  ConsAfter, WordStart:            Boolean;
  RaInitial, WasRaInitial:         Boolean;
  QBreak, WasQBreak:               Boolean;
  Shift, WasShift:                 Boolean;  // Shift tapped: the next consonant joins / the next vowel is independent
  LastLetter:                      Char;
  Phala, WasPhala, Joined:         Boolean;  // last consonant is a ra-/ya-phala: no automatic join after it
  Matched, StartsWord:             Boolean;
  // Non-greedy mode: Shift is a POSTFIX - it joins the consonant just typed to the one before it (km, Shift = KMA).
  LStart:                          Integer;  // index in Res where that last consonant begins (0 = n/a)
  LRa:                             Boolean;  // it was a ya-phala after a word-initial ra
  LTok:                            string;
  PrevC:                           Char;
  LVowSt:                          Integer;  // non-greedy: where a vowel sign just typed after a consonant begins (0 = n/a)
  LVowInd:                         string;   // ... and its independent form
begin
  LVowSt := 0;
  LVowInd := '';
  // only A-Z are lower-cased (length is unchanged)
  Src := Input;
  for J := 1 to Length(Src) do
    if (Src[J] >= 'A') and (Src[J] <= 'Z') then
      Src[J] := Char(Ord(Src[J]) + 32);

  Pending := ' ';
  Res := '';
  ConsAfter := False;
  WordStart := True;
  RaInitial := False;
  QBreak := False;
  Shift := False;
  Phala := False;
  LStart := 0;
  LRa := False;
  LTok := '';
  LastLetter := #0;
  LastConsTok := '';
  N := Length(Src);
  I := 1;

  while I <= N do
  begin
    C := Src[I];

    // non-greedy: a tapped Shift joins the last consonant to the one before it
    if (C = POPY_SHIFT) and (not PopyGreedyMode) then
    begin
      // ... or it turns the vowel sign just typed into an independent vowel (ka, Shift = KA + independent A)
      if LVowSt > 0 then
      begin
        Res := Copy(Res, 1, LVowSt - 1) + LVowInd;
        LVowSt := 0;
      end;
      if LStart > 1 then
      begin
        PrevC := Res[LStart - 1];
        if IsConsLetter(PrevC) or ((LTok = 'z') and (PrevC >= #$0985) and (PrevC <= #$0994)) then
        begin
          if LRa then
            Insert(ZWJ + HASANTA, Res, LStart)
          else
            Insert(HASANTA, Res, LStart);
        end;
      end;
      LStart := 0;
      Inc(I);
      Pending := ' ';
      Continue;
    end;

    // a tapped Shift: shown as "s" until the next key uses it (neighbouring state is untouched)
    if C = POPY_SHIFT then
    begin
      Shift := True;
      Inc(I);
      if I > N then
        Pending := 's'
      else
        Pending := ' ';
      Continue;
    end;

    LStart := 0;
    LVowSt := 0;
    WasRaInitial := RaInitial;
    RaInitial := False;
    WasQBreak := QBreak;
    QBreak := False;
    WasShift := Shift;
    Shift := False;
    Pending := ' ';

    // HASANTA + ZWNJ  ( ,, )
    if (C = ',') and StartsAt(Src, ',,', I) then
    begin
      Res := Res + HASANTA + ZWNJ;
      ConsAfter := False;
      WordStart := False;
      Inc(I, 2);
      Continue;
    end;

    if C = 'q' then
    begin
      Nx := #0;
      if I < N then
        Nx := Src[I + 1];

      // qw = VISARGA
      if Nx = 'w' then
      begin
        Res := Res + BN_VISARGA;
        ConsAfter := False;
        WordStart := False;
        Inc(I, 2);
        Continue;
      end;

      // q. = ?   q, = !
      if (Nx = '.') or (Nx = ',') then
      begin
        if Nx = '.' then
          Res := Res + '?'
        else
          Res := Res + '!';
        ConsAfter := False;
        WordStart := True;
        Inc(I, 2);
        Continue;
      end;

      // qq = CHANDRABINDU (also after a consonant)
      if Nx = 'q' then
      begin
        Res := Res + BN_CANDRABINDU;
        ConsAfter := False;
        WordStart := False;
        Inc(I, 2);
        Continue;
      end;

      // independent letters that never join: qh = HA, qz = YA, qx = KA+HASANTA+SA
      if Nx = 'h' then
      begin
        LStart := Length(Res) + 1; LTok := 'h'; LRa := False;
        Res := Res + #$09B9;
        LastLetter := #$09B9;
        ConsAfter := True;
        WordStart := False;
        LastConsTok := 'h';
        Inc(I, 2);
        Continue;
      end;
      if (Nx = 'z') and (not (ConsAfter and EndsWithPlainRa(Res))) then
      begin
        LStart := Length(Res) + 1; LTok := 'z'; LRa := False;
        Res := Res + BN_YA;
        LastLetter := BN_YA;
        ConsAfter := True;
        WordStart := False;
        LastConsTok := 'z';
        Inc(I, 2);
        Continue;
      end;
      // qs = SSA (independent); after s the q stays a break marker (sqs, hisqsa)
      if (Nx = 's') and (not (ConsAfter and (LastConsTok = 's'))) then
      begin
        if ConsAfter and WasShift then
          Res := Res + HASANTA;       // k, Shift, qs = conjunct KSSA
        LStart := Length(Res) + 1; LTok := 'sss'; LRa := False;
        Res := Res + #$09B7;
        LastLetter := #$09B7;
        ConsAfter := True;
        WordStart := False;
        LastConsTok := 'sss';
        Inc(I, 2);
        Continue;
      end;
      if Nx = 'x' then
      begin
        Res := Res + #$0995 + HASANTA + #$09B8;
        LastLetter := #$09B8;
        ConsAfter := True;
        WordStart := False;
        LastConsTok := 'x';
        Inc(I, 2);
        Continue;
      end;

      // qn = NYA (joins like nnn); after NA / NNA the q is a break marker (nqn)
      if (Nx = 'n') and (not (ConsAfter and ((LastConsTok = 'n') or (LastConsTok = 'nn')))) then
      begin
        // NYA follows the list too (joins by itself only where the pair is listed); Shift forces it
        if ConsAfter and (WasShift or (PopyGreedyMode and JoinablePair(LastLetter, #$099E))) then
          Res := Res + HASANTA;
        LStart := Length(Res) + 1; LTok := 'nnn'; LRa := False;
        Res := Res + #$099E;
        LastLetter := #$099E;
        ConsAfter := True;
        WordStart := False;
        LastConsTok := 'nnn';
        Inc(I, 2);
        Continue;
      end;

      // qr = RI (word start / after a vowel) or RI-KAR (after a consonant);
      // after RA the q stays a neutral separator (r, Shift, r = RA + hasanta + RA)
      if (Nx = 'r') and (not (ConsAfter and (LastConsTok = 'r'))) then
      begin
        if ConsAfter then
          Res := Res + #$09C3
        else
          Res := Res + #$098B;
        ConsAfter := False;
        WordStart := False;
        Inc(I, 2);
        Continue;
      end;

      if ConsAfter then
      begin
        // rqz = RA + ZWJ + HASANTA + YA
        if (Nx = 'z') and EndsWithPlainRa(Res) then
        begin
          Res := Res + ZWJ + HASANTA + BN_YA;
          LastLetter := BN_YA;
          ConsAfter := True;
          WordStart := False;
          LastConsTok := 'z';
          Inc(I, 2);
          Continue;
        end;
        // qt = KHANDA TA after a consonant (jogqt); not directly after t / tt,
        // and not for th / tt (tqth, ttqtt)
        Aft := #0;
        if I + 2 <= N then
          Aft := Src[I + 2];
        if StartsAt(Src, 'qt', I) and (Aft <> 'h') and (Aft <> 't') and
          (LastConsTok <> 't') and (LastConsTok <> 'tt') then
        begin
          Res := Res + BN_KHANDA_TA;
          ConsAfter := False;
          WordStart := False;
          Inc(I, 2);
          Continue;
        end;
        // any other q after a consonant: nothing, it only separates the neighbouring letters (tqt = TA TA)
        QBreak := True;
        Inc(I);
        if I > N then
          Pending := 'q';
        Continue;
      end;

      // after a vowel / at the start: special signs
      if StartsAt(Src, 'qt', I) then
      begin
        Res := Res + BN_KHANDA_TA;
        WordStart := False;
        Inc(I, 2);
        Continue;
      end;
      if StartsAt(Src, 'qk', I) then
      begin
        Res := Res + BN_TAKA;
        WordStart := False;
        Inc(I, 2);
        Continue;
      end;

      // q + any other letter: the q just goes away (it only separates the neighbours)
      if (I < N) and IsLowerLatin(Src[I + 1]) then
      begin
        QBreak := True;
        Inc(I);
        Continue;
      end;

      // a lone q stays q
      Res := Res + 'q';
      ConsAfter := False;
      WordStart := False;
      Inc(I);
      if I > N then
        Pending := 'Q';
      Continue;
    end;

    // longest token first (3 -> 2 -> 1)
    Matched := False;
    Len := N - I + 1;
    if Len > 3 then
      Len := 3;
    while Len >= 1 do
    begin
      Tok := Copy(Src, I, Len);

      // w: ba-phala after a consonant, otherwise the vowel O
      if Tok = 'w' then
      begin
        if ConsAfter then
        begin
          Res := Res + HASANTA + BN_BA;
          LastLetter := BN_BA;
          ConsAfter := True;
          LastConsTok := 'w';
        end
        else
        begin
          Res := Res + BN_VOWEL_O;
          ConsAfter := False;
        end;
        WordStart := False;
        Inc(I);
        Matched := True;
        Break;
      end;

      // ng = ANUSVARA
      if Tok = 'ng' then
      begin
        Res := Res + BN_ANUSVARA;
        ConsAfter := False;
        WordStart := False;
        Inc(I, 2);
        Matched := True;
        Break;
      end;

      if FindConsonant(Tok, CV) then
      begin
        StartsWord := WordStart and (not ConsAfter);
        L := Length(Res);
        WasPhala := Phala;
        Phala := False;
        if (Tok = 'z') and (not ConsAfter) and (not WasQBreak) and (L >= 1) and (Res[L] >= #$0985) and (Res[L] <= #$0994) and (PopyGreedyMode or WasShift) then
        begin
          // ya-phala on an independent vowel: oza = a-with-ya-phala
          Res := Res + HASANTA + CV;
          Phala := True;
        end
        else if (Tok = 'z') and ConsAfter and WasRaInitial and (PopyGreedyMode or WasShift) then
        begin
          // word-initial RA + ya-phala
          Res := Res + ZWJ + HASANTA + CV;
          Phala := True;
        end
        else
        begin
          // Greedy part: hasanta only for the listed conjunct pairs; b and y never join by themselves;
          // nothing joins after a ra-phala / ya-phala (a ya-phala may follow a ra-phala: brzan, and
          // YYA: y-hasanta-ya). A tapped Shift forces the join (YYA is never a phala).
          Joined := False;
          if ConsAfter and (Tok <> 'y') and
            (WasShift or
             (PopyGreedyMode and (Tok <> 'b') and
              (((Tok = 'z') and (LastConsTok = 'y')) or
               ((not WasPhala or ((Tok = 'z') and (LastLetter = BN_RA))) and JoinablePair(LastLetter, CV[1]))))) then
          begin
            Res := Res + HASANTA;
            Joined := True;
          end;
          if not Joined then
          begin
            LStart := Length(Res) + 1;
            LTok := Tok;
            LRa := (Tok = 'z') and WasRaInitial;
          end;
          Res := Res + CV;
          Phala := Joined and ((CV[1] = BN_RA) or (CV[1] = BN_YA));
        end;
        LastLetter := CV[Length(CV)];
        RaInitial := (Tok = 'r') and StartsWord;
        LastConsTok := Tok;
        ConsAfter := True;
        WordStart := False;
        Inc(I, Len);
        Matched := True;
        Break;
      end;

      if FindVowel(Tok, VIndep, VKar) then
      begin
        if ConsAfter and (not WasShift) then
        begin
          LVowSt := Length(Res) + 1;
          LVowInd := VIndep;
          Res := Res + VKar;
        end
        else
          Res := Res + VIndep;   // independent: word start, after a vowel, or after a tapped Shift
        // lone 'o' after a consonant adds nothing: remember it if it is the last key
        if (Tok = 'o') and ConsAfter and (I + Len > N) then
          Pending := 'o';
        ConsAfter := False;
        WordStart := False;
        Inc(I, Len);
        Matched := True;
        Break;
      end;

      Dec(Len);
    end;
    if Matched then
      Continue;

    // digits, dari and every other character
    if (C >= '0') and (C <= '9') then
      Res := Res + BanglaDigits[Ord(C) - Ord('0')]
    else if C = '.' then
      Res := Res + BN_DARI
    else
      Res := Res + Input[I];
    ConsAfter := False;
    WordStart := True;
    Inc(I);
  end;

  Result := Res;
end;

{ =============================================================================== }

function PopyConvert(const Input: string): string;
var
  P: Char;
begin
  Result := PopyRun(Input, P);
end;

{ =============================================================================== }

function PopyPreview(const Input: string; out HasMarker: Boolean): string;
var
  P: Char;
begin
  Result := PopyRun(Input, P);
  HasMarker := (P = 'o') or (P = 'q') or (P = 's');
  if HasMarker then
    Result := Result + P;
end;

end.
