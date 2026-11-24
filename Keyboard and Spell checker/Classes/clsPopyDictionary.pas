{
  =============================================================================
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  =============================================================================

  Popy Layout - dictionary (auto-correct and suggestions).

  Reads PopyWords.txt from the Avro data folder (UTF-8, one "word<TAB>frequency"
  per line; built from the Bangla dictionary database).  A typed word is compared
  with the list through a "normalisation key" that folds the letters Bangla
  typists confuse (I/II, i-kar/ii-kar, U/UU, u-kar/uu-kar, SHA/SSA/SA, NNA/NA,
  khanda-ta/TA, ZWJ/ZWNJ).  The list is loaded once, in the background.
}

{$INCLUDE ../ProjectDefines.inc}
unit clsPopyDictionary;

interface

type
  TPopyWordArray = array of string;

  { The word the user typed is returned unchanged unless the list has a better
    spelling for it. Text that is not a plain Bangla word is never touched. }
function PopyDictCorrect(const Word: string): string;

{ Same-key words first (most frequent first), then words that start with the typed letters. }
function PopyDictSuggestions(const Word: string; const Limit: Integer): TPopyWordArray;

{ Start loading the list in a background thread (call once, when Popy is created). }
procedure PopyDictPreload;

implementation

uses
  Classes,
  SysUtils,
  StrUtils,
  Generics.Collections,
  Generics.Defaults,
  uFileFolderHandling;

const
  POPY_WORDS_FILE = 'PopyWords.txt';

type
  TWordRec = record
    Key:  string;
    Word: string;
    Freq: Integer;
  end;

var
  Words:    TArray<TWordRec>;     // sorted by Key, then Freq (high first)
  Exact:    TDictionary<string, Integer>;
  Loaded:   Boolean = False;
  LoadLock: TObject;

{ =============================================================================== }

// য়  ড়  ঢ় as single code points (the file may hold either spelling)
function ComposeNukta(const S: string): string;
begin
  Result := StringReplace(S, #$09A1#$09BC, #$09DC, [rfReplaceAll]);
  Result := StringReplace(Result, #$09A2#$09BC, #$09DD, [rfReplaceAll]);
  Result := StringReplace(Result, #$09AF#$09BC, #$09DF, [rfReplaceAll]);
end;

{ =============================================================================== }

function NormKey(const S: string): string;
var
  I, N: Integer;
  C:    Char;
begin
  SetLength(Result, Length(S));
  N := 0;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      #$200C, #$200D: Continue;      // ZWNJ, ZWJ
      #$0988: C := #$0987;           // ঈ -> ই
      #$09C0: C := #$09BF;           // ী -> ি
      #$098A: C := #$0989;           // ঊ -> উ
      #$09C2: C := #$09C1;           // ূ -> ু
      #$09B6, #$09B7: C := #$09B8;   // শ ষ -> স
      #$09A3: C := #$09A8;           // ণ -> ন
      #$09CE: C := #$09A4;           // ৎ -> ত
    end;
    Inc(N);
    Result[N] := C;
  end;
  SetLength(Result, N);
end;

{ =============================================================================== }

// Plain Bangla letters / signs only: no digits, Latin letters or punctuation
function IsBanglaWord(const S: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  Result := Length(S) >= 2;
  if not Result then
    Exit;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (C = #$200C) or (C = #$200D) then
      Continue;
    if (C < #$0980) or (C > #$09FF) or ((C >= #$09E6) and (C <= #$09EF)) or
      (C = #$09F3) or (C = #$09F7) or (C = #$09E4) or (C = #$09E5) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

{ =============================================================================== }

procedure LoadWords;
var
  SL:   TStringList;
  Path: string;
  I, P, Fr: Integer;
  Line, W: string;
  List: TList<TWordRec>;
  R:    TWordRec;
  Old:  Integer;
begin
  TMonitor.Enter(LoadLock);
  try
    if Loaded then
      Exit;
    Exact := TDictionary<string, Integer>.Create;
    Path := GetAvroDataDir + POPY_WORDS_FILE;
    if FileExists(Path) then
    begin
      SL := TStringList.Create;
      List := TList<TWordRec>.Create;
      try
        try
          SL.LoadFromFile(Path, TEncoding.UTF8);
          for I := 0 to SL.Count - 1 do
          begin
            Line := SL[I];
            P := Pos(#9, Line);
            Fr := 1;
            if P > 0 then
            begin
              W := Copy(Line, 1, P - 1);
              Fr := StrToIntDef(Copy(Line, P + 1, MaxInt), 1);
            end
            else
              W := Line;
            W := ComposeNukta(W);
            if W = '' then
              Continue;
            if Exact.TryGetValue(W, Old) then
            begin
              Exact[W] := Old + Fr;      // same word written two ways
              Continue;
            end;
            Exact.Add(W, Fr);
            R.Key := NormKey(W);
            R.Word := W;
            R.Freq := Fr;
            List.Add(R);
          end;
          // frequencies of merged duplicates
          for I := 0 to List.Count - 1 do
          begin
            R := List[I];
            R.Freq := Exact[R.Word];
            List[I] := R;
          end;
          List.Sort(TComparer<TWordRec>.Construct(
            function(const A, B: TWordRec): Integer
            begin
              Result := CompareStr(A.Key, B.Key);
              if Result = 0 then
                Result := B.Freq - A.Freq;
            end));
          Words := List.ToArray;
        except
          // missing / unreadable list: no auto-correct, no suggestions
          SetLength(Words, 0);
        end;
      finally
        List.Free;
        SL.Free;
      end;
    end;
    Loaded := True;
  finally
    TMonitor.Exit(LoadLock);
  end;
end;

{ =============================================================================== }

// first index whose Key >= K
function LowerBound(const K: string): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := Length(Words);
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) shr 1;
    if CompareStr(Words[Mid].Key, K) < 0 then
      Lo := Mid + 1
    else
      Hi := Mid;
  end;
  Result := Lo;
end;

{ =============================================================================== }

function PopyDictCorrect(const Word: string): string;
var
  I: Integer;
begin
  Result := Word;
  if not IsBanglaWord(Word) then
    Exit;
  LoadWords;
  if Exact.ContainsKey(Word) then
    Exit;
  I := LowerBound(NormKey(Word));
  if (I < Length(Words)) and (Words[I].Key = NormKey(Word)) then
    Result := Words[I].Word;
end;

{ =============================================================================== }

function PopyDictSuggestions(const Word: string; const Limit: Integer): TPopyWordArray;
var
  K:        string;
  I, Scan, Cnt: Integer;
  Extra:    TList<TWordRec>;
  R:        TWordRec;
begin
  SetLength(Result, 0);
  if not IsBanglaWord(Word) then
    Exit;
  LoadWords;
  K := NormKey(Word);
  Cnt := 0;
  SetLength(Result, Limit);

  I := LowerBound(K);
  while (I < Length(Words)) and (Words[I].Key = K) and (Cnt < Limit) do
  begin
    Result[Cnt] := Words[I].Word;
    Inc(Cnt);
    Inc(I);
  end;

  if Cnt < Limit then
  begin
    Extra := TList<TWordRec>.Create;
    try
      Scan := 0;
      while (I < Length(Words)) and StartsStr(K, Words[I].Key) and (Scan < 20000) do
      begin
        Extra.Add(Words[I]);
        Inc(I);
        Inc(Scan);
      end;
      Extra.Sort(TComparer<TWordRec>.Construct(
        function(const A, B: TWordRec): Integer
        begin
          Result := B.Freq - A.Freq;
        end));
      for I := 0 to Extra.Count - 1 do
      begin
        if Cnt >= Limit then
          Break;
        R := Extra[I];
        Result[Cnt] := R.Word;
        Inc(Cnt);
      end;
    finally
      Extra.Free;
    end;
  end;
  SetLength(Result, Cnt);
end;

{ =============================================================================== }

procedure PopyDictPreload;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        LoadWords;
      except
      end;
    end).Start;
end;

{ =============================================================================== }

initialization
  LoadLock := TObject.Create;

finalization
  FreeAndNil(Exact);
  FreeAndNil(LoadLock);

end.
