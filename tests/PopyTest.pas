{$MODE OBJFPC}{$H+}
program PopyTest;

{ Console test for the Popy Layout engine (clsPopyPhonetic.pas).

  Usage:  PopyTest <path to typing_cases.tsv>
  Every line of the file is  <typed latin text> TAB <expected bangla text, UTF-8>.
  Exit code 0 = all cases pass.

  Built and run by .github/workflows/build.yml with Free Pascal.
  File reading and UTF-8 decoding are done by hand with explicit string types,
  so the result does not depend on compiler string-mode defaults. }

uses
  SysUtils,
  Classes,
  clsPopyPhonetic;

function Dump(const S: UnicodeString): AnsiString;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    Result := Result + IntToHex(Ord(S[I]), 4) + ' ';
end;

var
  Fail0: Integer;

procedure CheckPreview(const Typed: AnsiString; const Expected: UnicodeString; const ExpectMarker: Boolean);
var
  Got: UnicodeString;
  Marker: Boolean;
begin
  Got := PopyPreview(UnicodeString(Typed), Marker);
  if (Got <> Expected) or (Marker <> ExpectMarker) then
  begin
    Inc(Fail0);
    WriteLn('PREVIEW FAIL  typed=', Typed);
    WriteLn('      got      : ', Dump(Got), ' marker=', Marker);
    WriteLn('      expected : ', Dump(Expected), ' marker=', ExpectMarker);
  end;
end;

var
  Stream: TFileStream;
  Raw, RawLine, RawTyped, RawExpected: RawByteString;
  Pos1, PosTab, Total, Fail: Integer;
  Typed, Expected, Got: UnicodeString;
begin
  if ParamCount < 1 then
  begin
    WriteLn('usage: PopyTest typing_cases.tsv');
    Halt(2);
  end;

  Stream := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Raw, Stream.Size);
    if Stream.Size > 0 then
      Stream.ReadBuffer(Raw[1], Stream.Size);
  finally
    Stream.Free;
  end;

  Total := 0;
  Fail := 0;
  while Length(Raw) > 0 do
  begin
    Pos1 := System.Pos(#10, Raw);
    if Pos1 = 0 then
    begin
      RawLine := Raw;
      Raw := '';
    end
    else
    begin
      RawLine := Copy(Raw, 1, Pos1 - 1);
      Raw := Copy(Raw, Pos1 + 1, Length(Raw));
    end;
    if (Length(RawLine) > 0) and (RawLine[Length(RawLine)] = #13) then
      SetLength(RawLine, Length(RawLine) - 1);

    PosTab := System.Pos(#9, RawLine);
    if PosTab = 0 then
      Continue;
    RawTyped := Copy(RawLine, 1, PosTab - 1);
    RawExpected := Copy(RawLine, PosTab + 1, Length(RawLine));
    // typed text is ASCII; the up-arrow stands for a tapped Shift
    Typed := StringReplace(UTF8Decode(RawTyped), #$21E7, POPY_SHIFT, [rfReplaceAll]);
    Expected := UTF8Decode(RawExpected);
    Inc(Total);

    Got := PopyConvert(Typed);
    if Got <> Expected then
    begin
      Inc(Fail);
      WriteLn('FAIL  typed=', RawTyped);
      WriteLn('      got      : ', Dump(Got));
      WriteLn('      expected : ', Dump(Expected));
    end;
  end;

  // visible o / q markers while typing
  Fail0 := 0;
  CheckPreview('ko', #$0995'o', True);
  CheckPreview('kq', #$0995'q', True);
  CheckPreview('kot', #$0995#$09A4, False);
  CheckPreview('ka', #$0995#$09BE, False);
  CheckPreview('q', 'q', False);
  CheckPreview('k' + POPY_SHIFT, #$0995's', True);   // a tapped Shift shows as s
  CheckPreview('k' + POPY_SHIFT + 'f', #$0995#$09CD#$09AB, False);
  CheckPreview('o', #$0985, False);
  Fail := Fail + Fail0;
  Total := Total + 8;

  WriteLn(Total, ' cases, ', Fail, ' failed');
  if (Fail > 0) or (Total = 0) then
    Halt(1);
end.
