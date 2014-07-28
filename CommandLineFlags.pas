unit ConsoleFlags;

interface

uses System.Classes, System.SysUtils, Generics.Collections;

type
  TConsoleFlags = class
  type
    TConsoleFlagType = (cftString, cftBoolean, cftInteger);
    TConsoleFlag = class
    private
      fType: TConsoleFlagType;
      fRequired: boolean;
      fKeyName: string;
      fShortName: string;
      fLongName: string;
      fHasLongName: boolean;
      fHelpText: string;
      fStringValue: string;
      fBooleanValue: boolean;
      fIntegerValue: integer;
      fHasDefaultValue: boolean;
      fPosition: integer;
    public
      property FlagType: TConsoleFlagType read fType;
      property Required: boolean read fRequired;
      property KeyName: string read fKeyName;
      property ShortName: string read fShortName;
      property LongName: string read fLongName;
      property HelpText: string read fHelpText;
      property HasLongName: Boolean read fHasLongName;
      property HasDefaultValue: boolean read fHasDefaultValue;
      property Position: integer read fPosition;
      function IsPositional: boolean;
      function GetStringValue: string;
      function GetBooleanValue: boolean;
      function GetIntegerValue: integer;
      procedure SetTrue;
      procedure SetStringValue(Value: string);
      procedure SetIntegerValue(Value: integer);
      constructor Create(KeyName: string; ShortName: string; LongName: string; DefaultValue: string; HelpText: string; Required: boolean; Position: integer); overload;
      constructor Create(KeyName: string; ShortName: string; LongName: string; DefaultValue: boolean; HelpText: string; Required: boolean; Position: integer); overload;
      constructor Create(KeyName: string; ShortName: string; LongName: string; DefaultValue: integer; HelpText: string; Required: boolean; Position: integer); overload;
    end;
  private
    fNextPosition: Integer;
    fFlags: TObjectList<TConsoleFlag>;
    fExamples: TList<string>;
    function TryGetValue(Key: string; var Flag: TConsoleFlag): boolean;
    function GetStringValue(Key: string): string;
    function GetBooleanValue(Key: string): boolean;
    function GetIntegerValue(Key: string): integer;
  public
    property StringValue[Key: string]: string read GetStringValue;
    property BooleanValue[Key: string]: boolean read GetBooleanValue;
    property IntegerValue[Key: string]: integer read GetIntegerValue;
    procedure AddExample(Example: string);
    procedure AddStringFlag(KeyName: string; ShortName: string; DefaultValue: string; HelpText: string; Required: Boolean = false); overload;
    procedure AddStringFlag(KeyName: string; ShortName: string; LongName: string; DefaultValue: string; HelpText: string; Required: Boolean = false); overload;
    procedure AddBooleanFlag(KeyName: string; ShortName: string; DefaultValue: boolean; HelpText: string; Required: Boolean = false); overload;
    procedure AddBooleanFlag(KeyName: string; ShortName: string; LongName: string; DefaultValue: boolean; HelpText: string; Required: Boolean = false); overload;
    procedure AddIntegerFlag(KeyName: string; ShortName: string; DefaultValue: integer; HelpText: string; Required: Boolean = false); overload;
    procedure AddIntegerFlag(KeyName: string; ShortName: string; LongName: string; DefaultValue: integer; HelpText: string; Required: Boolean = false); overload;

    constructor Create;
    function Parse: boolean;
    procedure Help(Msg: string = '');
    destructor Destroy; override;
  end;

implementation

{ TConsoleFlags }

procedure TConsoleFlags.AddExample(Example: string);
begin
  fExamples.Add(Example);
end;

procedure TConsoleFlags.AddBooleanFlag(KeyName, ShortName, LongName: string;
  DefaultValue: boolean; HelpText: string; Required: Boolean = false);
begin                      
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName, DefaultValue, HelpText, Required, -1));
end;

procedure TConsoleFlags.AddBooleanFlag(KeyName, ShortName: string; DefaultValue: boolean;
  HelpText: string; Required: Boolean = false);
var
  Positional: Integer;
begin
  Positional := -1;
  if ShortName = '' then begin
    Positional := fNextPosition;
    Inc(fNextPosition);
  end;
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, '', DefaultValue, HelpText, Required, Positional));
end;

procedure TConsoleFlags.AddIntegerFlag(KeyName, ShortName, LongName: string;
  DefaultValue: integer; HelpText: string; Required: Boolean = false);
begin
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName, DefaultValue, HelpText, Required, -1));
end;

procedure TConsoleFlags.AddIntegerFlag(KeyName, ShortName: string; DefaultValue: integer;
  HelpText: string; Required: Boolean = false);
var
  Positional: Integer;
begin
  Positional := -1;
  if ShortName = '' then begin
    Positional := fNextPosition;
    Inc(fNextPosition);
  end;
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, '', DefaultValue, HelpText, Required, Positional));
end;

procedure TConsoleFlags.AddStringFlag(KeyName, ShortName, LongName, DefaultValue,
  HelpText: string; Required: Boolean = false);
begin
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName, DefaultValue, HelpText, Required, -1));
end;

procedure TConsoleFlags.AddStringFlag(KeyName, ShortName, DefaultValue, HelpText: string; Required: Boolean = false);
var
  Positional: Integer;
begin
  Positional := -1;
  if ShortName = '' then begin
    Positional := fNextPosition;
    Inc(fNextPosition);
  end;
  fFlags.Add(TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, '', DefaultValue, HelpText, Required, Positional));
end;

constructor TConsoleFlags.Create;
begin
  fFlags := TObjectList<TConsoleFlag>.Create(true);
  fExamples := TList<string>.Create;
  fNextPosition := 0;
  AddBooleanFlag('help', 'h', 'help', False, 'Show this help');
end;

destructor TConsoleFlags.Destroy;
begin
  fFlags.Free;
  fExamples.Free;
  inherited;
end;

function TConsoleFlags.TryGetValue(Key: string; var Flag: TConsoleFlag): boolean;
var
  TmpFlag: TConsoleFlag;
begin
  for TmpFlag in fFlags do begin
    if TmpFlag.KeyName = Key then begin
      Result := true;
      Flag := TmpFlag;
      exit;
    end;
  end;
  Result := false;
  Flag := nil;
end;

function TConsoleFlags.GetBooleanValue(Key: string): boolean;
var
  Flag: TConsoleFlag;
begin
  Result := false;
  if TryGetValue(Key, Flag) then
    Result := Flag.GetBooleanValue    
  else
    // Should raise exception?
end;

function TConsoleFlags.GetIntegerValue(Key: string): integer;
var
  Flag: TConsoleFlag;
begin
  Result := 0;
  if TryGetValue(Key, Flag) then
    Result := Flag.GetIntegerValue
  else
    // Should raise exception?
end;

function TConsoleFlags.GetStringValue(Key: string): string;
var
  Flag: TConsoleFlag;
begin
  if TryGetValue(Key, Flag) then
    Result := Flag.GetStringValue    
  else
    // Should raise exception?
end;

procedure TConsoleFlags.Help(Msg: string = '');
const
  LeftWidth: Integer = 25;
  ConsoleWidth: Integer = 80;
var
  Flag: TConsoleFlag;
  Line, Line2: string;
  ProgName: string;
  TmpHelp: string;
  Positionals: Integer;
  Example: string;
begin
  if Msg <> '' then begin
    Writeln(msg);
    Writeln('');
  end;
  ProgName := ParamStr(0);
  while Pos('\', ProgName) > 0 do
    ProgName := Copy(ProgName, Pos('\', ProgName)+1, Length(ProgName)-Pos('\', ProgName));
  Writeln('Usage: ');
  Write(ProgName);
  for Flag in fFlags do begin
    if Flag.IsPositional then
      continue;

    Write(' ');
    if not Flag.Required then
      Write('[');

    if Flag.FlagType <> cftBoolean then begin
      if Flag.HasLongName then
        Write('--', Flag.LongName, '=', Flag.KeyName)
      else
        Write('-', Flag.ShortName, ' ', Flag.KeyName);
    end else begin
      if Flag.HasLongName then
        Write('--', Flag.LongName)
      else
        Write('-', Flag.ShortName);
    end;

    if not Flag.Required then
      Write(']');
  end;

  for Flag in fFlags do begin
    if not Flag.IsPositional then
      continue;

    Write(' ');
    if Flag.Required then
      Write('<')
    else
      Write('[');

    Write(Flag.KeyName);

    if Flag.Required then
      Write('>')
    else
      Write(']');
  end;

  Writeln('');

  Positionals := 0;

  for Flag in fFlags do begin
    if Flag.IsPositional then begin
      Inc(Positionals);
      continue;
    end;

    Writeln('');
    if Flag.HasLongName then begin
      TmpHelp := Flag.HelpText;
      if Flag.FlagType = cftBoolean then begin
        Line := Format(' -%s, --%s', [Flag.ShortName, Flag.LongName]);
        Write(Line);
      end else begin
        Line := Format(' -%s %s', [Flag.ShortName, Flag.KeyName]);
        Line2 := Format(' --%s=%s', [Flag.LongName, Flag.KeyName]);
        if (Length(Line) > LeftWidth) or (Length(Line2) > LeftWidth) then begin
          Writeln(Line);
          Line := Line2;
          Line2 := '';
        end;
        if Length(Line) > LeftWidth then begin
          Writeln(Line);
          Line := '';
        end;
        Writeln(Line,
          StringOfChar(' ', LeftWidth-Length(Line)),
          Copy(TmpHelp, 1, ConsoleWidth-LeftWidth-1));
        if Length(TmpHelp) > ConsoleWidth-LeftWidth then begin
          TmpHelp := Copy(TmpHelp, ConsoleWidth-LeftWidth, Length(TmpHelp));
        end else
          TmpHelp := '';
        Line := Line2;
        Write(Line);
      end;
      while TmpHelp <> '' do begin
        Write(StringOfChar(' ', LeftWidth-Length(Line)));
        Writeln(Copy(TmpHelp, 1, ConsoleWidth-LeftWidth-1));
        TmpHelp := Copy(TmpHelp, ConsoleWidth-LeftWidth, Length(TmpHelp));
        Line := '';
      end;
      if (Flag.FlagType <> cftBoolean) and (Flag.HasDefaultValue) then begin
        Writeln(StringOfChar(' ', LeftWidth-Length(Line)), 'Default: ', Flag.GetStringValue);
      end;
      if (Flag.FlagType <> cftBoolean) and (Length(Line) > 0) then
        Writeln('');
    end else begin
      if Flag.FlagType = cftBoolean then begin
        Line := Format(' -%s ', [Flag.ShortName]);
      end else begin
        Line := Format(' -%s %s ', [Flag.ShortName, Flag.KeyName]);
      end;
      Write(Line);
      if Length(Flag.HelpText) > ConsoleWidth-LeftWidth then begin
        TmpHelp := Flag.HelpText;
        while TmpHelp <> '' do begin
          Write(StringOfChar(' ', LeftWidth-Length(Line)));
          Writeln(Copy(TmpHelp, 1, ConsoleWidth-LeftWidth-1));
          TmpHelp := Copy(TmpHelp, ConsoleWidth-LeftWidth, Length(TmpHelp)-ConsoleWidth-LeftWidth);
          Line := '';
        end;
      end else begin
        Write(StringOfChar(' ', LeftWidth-Length(Line)));
        Writeln(Flag.HelpText);
      end;
      if (Flag.FlagType <> cftBoolean) and (Flag.HasDefaultValue) then begin
        Writeln(StringOfChar(' ', LeftWidth), 'Default: ', Flag.GetStringValue);
      end;
    end;
  end;

  if Positionals > 0 then begin
    Writeln('');
    Writeln('Positional arguments:');
    for Flag in fFlags do begin
      if not Flag.IsPositional then
        continue;

      Writeln('');
      Line := Format(' %s', [Flag.KeyName]);
      Write(Line);
      if Length(Flag.HelpText) > ConsoleWidth-LeftWidth then begin
        TmpHelp := Flag.HelpText;
        while TmpHelp <> '' do begin
          Write(StringOfChar(' ', LeftWidth-Length(Line)));
          Writeln(Copy(TmpHelp, 1, ConsoleWidth-LeftWidth-1));
          TmpHelp := Copy(TmpHelp, ConsoleWidth-LeftWidth, Length(TmpHelp)-ConsoleWidth-LeftWidth);
          Line := '';
        end;
      end else begin
        Write(StringOfChar(' ', LeftWidth-Length(Line)));
        Writeln(Flag.HelpText);
      end;
      if Flag.HasDefaultValue then begin
        Writeln(StringOfChar(' ', LeftWidth), 'Default: ', Flag.GetStringValue);
      end;
    end;
  end;

  if fExamples.Count > 0 then begin
    Writeln('');
    if fExamples.Count = 1 then
      Writeln('Example:')
    else
      Writeln('Examples:');
    for Example in fExamples.List do
      Writeln(Example);
  end;
end;

function TConsoleFlags.Parse: boolean;
var
  I: Integer;
  PS, Value: string;
  Flag, TmpFlag: TConsoleFlag;
  RequiredFlags: TStringList;
  NextPosition: integer;
begin
  RequiredFlags := TStringList.Create;
  NextPosition := 0;
  try
    for Flag in fFlags do begin
      if Flag.Required then begin
        RequiredFlags.Add(Flag.KeyName);
      end;
    end;
    if RequiredFlags.Count = 0 then
      Result := true;
    Flag := nil;
    for I := 1 to ParamCount do begin
      PS := ParamStr(I);
      if Pos('-', PS) = 1 then begin
        if Pos('--', PS) = 1 then begin
          PS := Copy(PS, 3, Length(PS)-2);
          if Pos('=', PS) > 1 then begin
            Value := Copy(PS, Pos('=', PS)+1, Length(PS)-Pos('=', PS));
            PS := Copy(PS, 1, Pos('=', PS)-1);
          end;
          for Flag in fFlags do begin
            if PS = Flag.LongName then
              break;
          end;
          if PS <> Flag.LongName then
            Flag := nil;
          if Flag <> nil then begin
            case Flag.FlagType of
              cftString:  Flag.SetStringValue(Value);
              cftBoolean: Flag.SetTrue;
              cftInteger: Flag.SetIntegerValue(StrToIntDef(Value, Flag.GetIntegerValue));
            end;
            if RequiredFlags.IndexOf(Flag.KeyName) <> -1 then
              RequiredFlags.Delete(RequiredFlags.IndexOf(Flag.KeyName));
          end;
        end else if Pos('-', PS) = 1 then begin
          PS := Copy(PS, 2, Length(PS)-1);
          for Flag in fFlags do begin
            if PS = Flag.ShortName then
              break;
          end;
          if PS <> Flag.ShortName then
            Flag := nil;
          if Flag <> nil then begin
            if Flag.FlagType = cftBoolean then
              Flag.SetTrue;
            if RequiredFlags.IndexOf(Flag.KeyName) <> -1 then
              RequiredFlags.Delete(RequiredFlags.IndexOf(Flag.KeyName));
          end;
        end;
      end else begin
        for TmpFlag in fFlags do begin
          if TmpFlag.IsPositional and (TmpFlag.Position = NextPosition) then begin
            Flag := TmpFlag;
            Inc(NextPosition);
            if RequiredFlags.IndexOf(Flag.KeyName) <> -1 then
              RequiredFlags.Delete(RequiredFlags.IndexOf(Flag.KeyName));
          end;
        end;

        if Flag = nil then
          continue;

        case Flag.FlagType of
          cftString:  Flag.SetStringValue(ParamStr(I));
          cftInteger: Flag.SetIntegerValue(StrToIntDef(ParamStr(I), Flag.GetIntegerValue));
        end;
      end;
    end;
    Result := RequiredFlags.Count = 0;
    if GetBooleanValue('help') or not Result then begin
      Result := false;
      Help;
    end;
  finally
    RequiredFlags.Free;
  end;
end;

{ TConsoleFlags.TConsoleFlag }

constructor TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName, DefaultValue,
  HelpText: string; Required: boolean; Position: integer);
begin
  fType               := cftString;
  fKeyName            := KeyName;
  fShortName          := ShortName;
  fLongName           := LongName;
  fHasLongName        := LongName <> '';
  fStringValue        := DefaultValue;
  fHasDefaultValue    := DefaultValue <> '';
  fRequired           := Required;
  fHelpText           := HelpText;
  fPosition           := Position;
end;

constructor TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName: string;
  DefaultValue: boolean; HelpText: string; Required: boolean; Position: integer);
begin
  fType                := cftBoolean;
  fKeyName             := KeyName;
  fShortName           := ShortName;
  fLongName            := LongName;
  fHasLongName         := LongName <> '';
  fBooleanValue        := DefaultValue;
  fHasDefaultValue     := true;
  fRequired            := Required;
  fHelpText            := HelpText;
  fPosition            := Position;
end;

constructor TConsoleFlags.TConsoleFlag.Create(KeyName, ShortName, LongName: string;
  DefaultValue: integer; HelpText: string; Required: boolean; Position: integer);
begin
  fType                := cftInteger;
  fKeyName             := KeyName;
  fShortName           := ShortName;
  fLongName            := LongName;
  fHasLongName         := LongName <> '';
  fIntegerValue        := DefaultValue;
  fHasDefaultValue     := false;
  fRequired            := Required;
  fHelpText            := HelpText;
  fPosition            := Position;
end;

function TConsoleFlags.TConsoleFlag.IsPositional: boolean;
begin
  Result := fPosition <> -1;
end;

function TConsoleFlags.TConsoleFlag.GetBooleanValue: boolean;
begin
  Result := false;
  if fType = cftBoolean then
    Result := fBooleanValue;  
end;

function TConsoleFlags.TConsoleFlag.GetIntegerValue: integer;
begin
  Result := 0;
  if fType = cftInteger then
    Result := fIntegerValue;
end;

function TConsoleFlags.TConsoleFlag.GetStringValue: string;
begin
  case fType of
    cftString:  Result := fStringValue;
    cftBoolean: if fBooleanValue then Result := 'true' else Result := 'false';
    cftInteger: Result := IntToStr(fIntegerValue);
  end;
end;

procedure TConsoleFlags.TConsoleFlag.SetIntegerValue(Value: integer);
begin
  if fType = cftInteger then
    fIntegerValue := Value;
end;

procedure TConsoleFlags.TConsoleFlag.SetStringValue(Value: string);
begin
  if fType = cftString then
    fStringValue := Value;
end;

procedure TConsoleFlags.TConsoleFlag.SetTrue;
begin
  if fType = cftBoolean then
    fBooleanValue := true;
end;

end.
