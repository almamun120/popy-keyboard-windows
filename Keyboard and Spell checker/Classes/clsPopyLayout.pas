{
  =============================================================================
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  =============================================================================

  Popy Layout - keyboard handler.

  Keeps the Latin letters typed since the last word break, runs them through
  PopyConvert (clsPopyPhonetic.pas) after every key and replaces the text that
  was already sent with the new result (backspace + resend of the changed tail).
}

{$INCLUDE ../ProjectDefines.inc}
unit clsPopyLayout;

interface

uses
  Classes,
  SysUtils,
  StrUtils,
  clsPopyPhonetic,
  clsPopyDictionary,
  clsUnicodeToBijoy2000;

const
  Popy_MaxBufferLength = 60;

type
  TPopyLayout = class
    private
      Bijoy:       TUnicodeToBijoy2000;
      EnglishT:    string;
      PrevBanglaT: string;
      BlockLast:   Boolean;
      SelIndex:    Integer;   // suggestion chosen with Up/Down (-1 = none)
      ShiftDown:   Boolean;   // a Shift key is held ...
      ShiftTap:    Boolean;   // ... and no other key was pressed meanwhile = a tap
      MarkerShown: Boolean; // a visible 'o' / 'q' marker is at the end of the sent text

      function SuggestionCount: Integer;
      procedure AddStr(const Str: string);
      procedure SendDifference(const NewBanglaText: string);
      procedure ShowCurrentWord;
      procedure CommitWord(const AutoCorrect: Boolean = False);
      procedure DoBackspace(var Block: Boolean);
      function KeyToText(const KeyCode: Integer; const ShiftDown: Boolean): string;
    public
      constructor Create;
      destructor Destroy; override;

      function ProcessVKeyDown(const KeyCode: Integer; var Block: Boolean): string;
      procedure ProcessVKeyUP(const KeyCode: Integer; var Block: Boolean);
      procedure ResetDeadKey;
      // mouse click on a preview-window item: replace the word on screen by Item
      procedure SelectCandidate(const Item: string);
  end;

implementation

uses
  KeyboardFunctions,
  VirtualKeyCode,
  uForm1,
  ufrmPrevW,
  clsLayout,
  uRegistrySettings;

{ TPopyLayout }

{ =============================================================================== }

constructor TPopyLayout.Create;
begin
  inherited;
  Bijoy := TUnicodeToBijoy2000.Create;
  PopyDictPreload;   // load the word list in the background (auto-correct + suggestions)
  EnglishT := '';
  PrevBanglaT := '';
  BlockLast := False;
  SelIndex := -1;
  ShiftDown := False;
  ShiftTap := False;
  MarkerShown := False;
end;

{ =============================================================================== }

destructor TPopyLayout.Destroy;
begin
  FreeAndNil(Bijoy);
  inherited;
end;

{ =============================================================================== }

procedure TPopyLayout.ResetDeadKey;
begin
  if Assigned(frmPrevW) then
    frmPrevW.HidePreview;
  EnglishT := '';
  PrevBanglaT := '';
  BlockLast := False;
  SelIndex := -1;
  MarkerShown := False;
end;

{ =============================================================================== }

// Replace what is already on screen (PrevBanglaT) by NewBanglaText with the
// smallest number of backspaces.
procedure TPopyLayout.SendDifference(const NewBanglaText: string);
var
  OldT, NewT: string;
  I, Matched: Integer;
begin
  if OutputIsBijoy = 'YES' then
  begin
    OldT := Bijoy.Convert(PrevBanglaT);
    NewT := Bijoy.Convert(NewBanglaText);
  end
  else
  begin
    OldT := PrevBanglaT;
    NewT := NewBanglaText;
  end;

  Matched := 0;
  for I := 1 to Length(OldT) do
  begin
    if (I <= Length(NewT)) and (OldT[I] = NewT[I]) then
      Inc(Matched)
    else
      Break;
  end;

  if Length(OldT) - Matched >= 1 then
    Backspace(Length(OldT) - Matched);

  if Length(NewT) > Matched then
    SendKey_Char(Copy(NewT, Matched + 1, Length(NewT) - Matched));

  PrevBanglaT := NewBanglaText;
end;

{ =============================================================================== }

procedure TPopyLayout.AddStr(const Str: string);
begin
  if Length(EnglishT) >= Popy_MaxBufferLength then
    CommitWord;

  EnglishT := EnglishT + Str;
  ShowCurrentWord;
end;

{ =============================================================================== }

// Convert the buffer and show it; a visible 'o' / 'q' marker is appended when
// the last key added nothing to the text (it goes away with the next key).
procedure TPopyLayout.ShowCurrentWord;
var
  Txt, Raw: string;
  Sug:      TPopyWordArray;
  I:        Integer;
begin
  SelIndex := -1;
  Txt := PopyPreview(EnglishT, MarkerShown);

  // "Show preview window": the typed English letters on top. With auto-correct on, the
  // list holds what was typed (first item) and the dictionary suggestions - Popy only.
  if Assigned(frmPrevW) then
  begin
    if ShowPrevWindow = 'YES' then
    begin
      frmPrevW.List.Items.BeginUpdate;
      try
        frmPrevW.List.Items.Clear;
        if PhoneticAutoCorrect = 'YES' then
        begin
          Raw := PopyConvert(EnglishT);
          Sug := PopyDictSuggestions(Raw, 8);
          if Length(Sug) > 0 then
          begin
            frmPrevW.List.Items.Add(Raw);
            for I := 0 to High(Sug) do
              if Sug[I] <> Raw then
                frmPrevW.List.Items.Add(Sug[I]);
          end;
        end;
      finally
        frmPrevW.List.Items.EndUpdate;
      end;
      frmPrevW.UpdateListHeight;
      // a tapped Shift (POPY_SHIFT) is shown as an up-arrow in the English line
      frmPrevW.UpdatePreviewCaption(StringReplace(EnglishT, POPY_SHIFT, #$21E7, [rfReplaceAll]));
    end
    else
      frmPrevW.HidePreview;
  end;

  // ANSI (Bijoy) fonts draw a Latin 'o' as the Bangla DDA-nukta and 'q' as YA-nukta.
  // Look-alike letters that these fonts do not have make the font fall back to a
  // normal font, so the marker is seen as a real 'o' / 'q'.
  if MarkerShown and (OutputIsBijoy = 'YES') and (Txt <> '') then
  begin
    if Txt[Length(Txt)] = 'o' then
      Txt[Length(Txt)] := Char($043E) // Cyrillic small O
    else if Txt[Length(Txt)] = 'q' then
      Txt[Length(Txt)] := Char($051B) // Cyrillic small QA
    else if Txt[Length(Txt)] = 's' then
      Txt[Length(Txt)] := Char($0441); // Cyrillic small ES (the Shift marker)
  end;

  SendDifference(Txt);
end;

{ =============================================================================== }

// The word is finished: remove the visible marker (if any) and start fresh.
// AutoCorrect (Space / Enter / Tab, auto-correct switched on): the word on screen is replaced by
// the dictionary spelling when there is one.
procedure TPopyLayout.CommitWord(const AutoCorrect: Boolean);
var
  Raw, Fixed: string;
begin
  if EnglishT <> '' then
  begin
    Raw := PopyConvert(EnglishT);
    Fixed := Raw;
    if AutoCorrect and (PhoneticAutoCorrect = 'YES') then
      Fixed := PopyDictCorrect(Raw);
    // also removes the visible marker (Raw has none)
    if (Fixed <> PrevBanglaT) then
      SendDifference(Fixed);
    MarkerShown := False;
  end
  else if MarkerShown then
  begin
    Backspace(1);
    MarkerShown := False;
  end;
  ResetDeadKey;
end;

{ =============================================================================== }

// number of suggestions currently shown in the preview window
function TPopyLayout.SuggestionCount: Integer;
begin
  Result := 0;
  if (EnglishT <> '') and (ShowPrevWindow = 'YES') and Assigned(frmPrevW) then
    Result := frmPrevW.List.Items.Count;
end;

{ =============================================================================== }

procedure TPopyLayout.SelectCandidate(const Item: string);
begin
  if EnglishT = '' then
    Exit;
  SendDifference(Item);
  MarkerShown := False;
  ResetDeadKey;
end;

{ =============================================================================== }

procedure TPopyLayout.DoBackspace(var Block: Boolean);
begin
  if Length(EnglishT) <= 1 then
  begin
    // only one typed key is left: let the real Backspace remove the last character
    if OutputIsBijoy = 'YES' then
    begin
      if Length(Bijoy.Convert(PrevBanglaT)) - 1 >= 1 then
        Backspace(Length(Bijoy.Convert(PrevBanglaT)) - 1);
    end
    else
    begin
      if Length(PrevBanglaT) - 1 >= 1 then
        Backspace(Length(PrevBanglaT) - 1);
    end;
    ResetDeadKey;
    Block := False;
  end
  else
  begin
    Block := True;
    EnglishT := LeftStr(EnglishT, Length(EnglishT) - 1);
    ShowCurrentWord;
  end;
end;

{ =============================================================================== }

// Text produced by a key (Latin buffer text). '' = key is not handled here.
function TPopyLayout.KeyToText(const KeyCode: Integer; const ShiftDown: Boolean): string;
begin
  Result := '';

  // letters: always lower case, Shift has no effect on Bangla output
  if (KeyCode >= A_Key) and (KeyCode <= Z_Key) then
  begin
    Result := Char(Ord('a') + (KeyCode - A_Key));
    Exit;
  end;

  // number pad
  if (KeyCode >= VK_NUMPAD0) and (KeyCode <= VK_NUMPAD9) then
  begin
    Result := Char(Ord('0') + (KeyCode - VK_NUMPAD0));
    Exit;
  end;

  case KeyCode of
    VK_DECIMAL:
      Result := '.';
    VK_DIVIDE:
      Result := '/';
    VK_MULTIPLY:
      Result := '*';
    VK_SUBTRACT:
      Result := '-';
    VK_ADD:
      Result := '+';

    VK_0:
      if ShiftDown then Result := ')' else Result := '0';
    VK_1:
      if ShiftDown then Result := '!' else Result := '1';
    VK_2:
      if ShiftDown then Result := '@' else Result := '2';
    VK_3:
      if ShiftDown then Result := '#' else Result := '3';
    VK_4:
      if ShiftDown then Result := '$' else Result := '4';
    VK_5:
      if ShiftDown then Result := '%' else Result := '5';
    VK_6:
      if ShiftDown then Result := '^' else Result := '6';
    VK_7:
      if ShiftDown then Result := '&' else Result := '7';
    VK_8:
      if ShiftDown then Result := '*' else Result := '8';
    VK_9:
      if ShiftDown then Result := '(' else Result := '9';

    VK_OEM_1:
      if ShiftDown then Result := ':' else Result := ';';
    VK_OEM_2:
      if ShiftDown then Result := '?' else Result := '/';
    VK_OEM_3:
      if ShiftDown then Result := '~' else Result := '`';
    VK_OEM_4:
      if ShiftDown then Result := '{' else Result := '[';
    VK_OEM_5:
      if ShiftDown then Result := '|' else Result := '\';
    VK_OEM_6:
      if ShiftDown then Result := '}' else Result := ']';
    VK_OEM_7:
      if ShiftDown then Result := '"' else Result := #39;
    VK_OEM_COMMA:
      if ShiftDown then Result := '<' else Result := ',';
    VK_OEM_MINUS:
      if ShiftDown then Result := '_' else Result := '-';
    VK_OEM_PERIOD:
      if ShiftDown then Result := '>' else Result := '.';
    VK_OEM_PLUS:
      if ShiftDown then Result := '+' else Result := '=';
  end;
end;

{ =============================================================================== }

function TPopyLayout.ProcessVKeyDown(const KeyCode: Integer; var Block: Boolean): string;
var
  Txt: string;
begin
  Result := '';
  Block := False;

  // Shift: remember a possible tap (Shift pressed and released on its own). The key itself is
  // never blocked, and key repeat of a held Shift changes nothing.
  if (KeyCode = VK_SHIFT) or (KeyCode = VK_LSHIFT) or (KeyCode = VK_RSHIFT) then
  begin
    if (not ShiftDown) and (not IsControl) and (not IsAlter) and (not IsWinKey) then
      ShiftTap := True;
    ShiftDown := True;
    BlockLast := False;
    Exit;
  end;
  ShiftTap := False;   // any other key press (Ctrl, Alt, a letter ...) cancels the tap

  if (IsControl = True) or (IsAlter = True) or (IsWinKey = True) then
  begin
    // shortcuts (Ctrl+V etc.) change the text behind our back
    ResetDeadKey;
    BlockLast := False;
    Exit;
  end;

  if IsIgnorableModifierKey(KeyCode) then
  begin
    BlockLast := False;
    Exit;
  end;

  if AvroMainForm1.GetMyCurrentKeyboardMode = SysDefault then
  begin
    BlockLast := False;
    Exit;
  end;

  // ---- Bangla mode ----
  case KeyCode of
    // Down / Up move through the suggestions shown in the preview window
    VK_DOWN:
      if SuggestionCount > 0 then
      begin
        if SelIndex < SuggestionCount - 1 then
          Inc(SelIndex);
        frmPrevW.List.ItemIndex := SelIndex;
        Block := True;
        BlockLast := True;
        Exit;
      end;
    VK_UP:
      if (SuggestionCount > 0) and (SelIndex >= 0) then
      begin
        Dec(SelIndex);
        frmPrevW.List.ItemIndex := SelIndex;
        Block := True;
        BlockLast := True;
        Exit;
      end;
  end;

  case KeyCode of
    VK_SPACE, VK_RETURN, VK_TAB:
      begin
        if (SelIndex >= 0) and (SelIndex < SuggestionCount) then
          SelectCandidate(frmPrevW.List.Items[SelIndex])   // the highlighted suggestion
        else
          CommitWord(True);   // dictionary auto-correct (when on)
        Exit;
      end;
    VK_ESCAPE, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT, VK_DELETE:
      begin
        CommitWord;         // keep the word exactly as typed
        Exit;
      end;
    VK_BACK:
      begin
        DoBackspace(Block);
        BlockLast := Block;
        Exit;
      end;
  end;

  Txt := KeyToText(KeyCode, IsTrueShift);
  if Txt <> '' then
  begin
    AddStr(Txt);
    Block := True;
    BlockLast := True;
  end
  else
    BlockLast := False;
end;

{ =============================================================================== }

procedure TPopyLayout.ProcessVKeyUP(const KeyCode: Integer; var Block: Boolean);
begin
  // a Shift tap: add the "do not merge" token once (before a consonant it joins, before a vowel it
  // makes the vowel independent). The Shift key-up itself always passes through.
  if (KeyCode = VK_SHIFT) or (KeyCode = VK_LSHIFT) or (KeyCode = VK_RSHIFT) then
  begin
    Block := False;
    BlockLast := False;
    if ShiftTap and (not IsControl) and (not IsAlter) and (not IsWinKey) and
      (AvroMainForm1.GetMyCurrentKeyboardMode <> SysDefault) and
      (EnglishT <> '') and (EnglishT[Length(EnglishT)] <> POPY_SHIFT) then
      AddStr(POPY_SHIFT);
    ShiftTap := False;
    ShiftDown := False;
    Exit;
  end;

  if IsIgnorableModifierKey(KeyCode) then
  begin
    Block := False;
    BlockLast := False;
    Exit;
  end;

  if AvroMainForm1.GetMyCurrentKeyboardMode = SysDefault then
  begin
    Block := False;
    BlockLast := False;
  end
  else if BlockLast = True then
    Block := True;
end;

{ =============================================================================== }

end.
