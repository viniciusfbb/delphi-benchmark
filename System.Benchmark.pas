unit System.Benchmark;

interface

uses
  System.Classes, System.Generics.Collections, System.TimeSpan, System.Diagnostics;

type
  TBenchmarkItem = class;

  TBenchmarkPauser = record
  private
    FOwner: TBenchmarkItem;
    constructor Create(AOwner: TBenchmarkItem);
  public
    function Stop: TBenchmarkItem;
  end;

  TBenchmarkItem = class
  private
    FExtraTimeSpan: TTimeSpan;
    FFirst: TTimeSpan;
    FFirstTimeStamp: Int64;
    FLast: TTimeSpan;
    FLastTimeStamp: Int64;
    FMax: TTimeSpan;
    FMin: TTimeSpan;
    FName: string;
    FOnStart: TNotifyEvent;
    FOnStop: TNotifyEvent;
    FRunningCount: Integer;
    FStopwatch: TStopwatch;
    FTimings: Int64;
    function GetElapsed: TTimeSpan;
    procedure Pause;
  protected
    procedure Add(AItem: TBenchmarkItem);
    procedure Reset;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
  public
    constructor Create(const AName: string);
    function Average: TTimeSpan;
    function Start: TBenchmarkPauser;
    property Elapsed: TTimeSpan read GetElapsed;
    property First: TTimeSpan read FFirst;
    property Last: TTimeSpan read FLast;
    property Max: TTimeSpan read FMax;
    property Min: TTimeSpan read FMin;
    property Name: string read FName;
    property Timings: Int64 read FTimings;
  end;

  TBenchmark = class
  private
    FExtraTimeSpan: TTimeSpan;
    FFirst: TTimeSpan;
    FFirstTimeStamp: Int64;
    FItems: TDictionary<string, TBenchmarkItem>;
    FLast: TTimeSpan;
    FLastTimeStamp: Int64;
    FMax: TTimeSpan;
    FMin: TTimeSpan;
    FRunningCount: Integer;
    FStopwatch: TStopwatch;
    FTimings: Int64;
    function GetElapsed: TTimeSpan;
    function GetItem(const AName: string): TBenchmarkItem;
    function GetItems: TArray<TBenchmarkItem>;
  protected
    procedure StopwatchStart(ASender: TObject);
    procedure StopwatchStop(ASender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ABenchmark: TBenchmark);
    function Average: TTimeSpan;
    function Dump: string;
    procedure Reset;
    property Elapsed: TTimeSpan read GetElapsed;
    property First: TTimeSpan read FFirst;
    property Item[const Name: string]: TBenchmarkItem read GetItem; default;
    property Items: TArray<TBenchmarkItem> read GetItems;
    property Last: TTimeSpan read FLast;
    property Max: TTimeSpan read FMax;
    property Min: TTimeSpan read FMin;
    property Timings: Int64 read FTimings;
  end;

var
  GlobalBenchmark: TBenchmark;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Defaults;

{ TBenchmarkPauser }

constructor TBenchmarkPauser.Create(AOwner: TBenchmarkItem);
begin
  FOwner := AOwner;
end;

function TBenchmarkPauser.Stop: TBenchmarkItem;
begin
  Result := FOwner;
  FOwner := nil;
  if Result <> nil then
    Result.Pause;
end;

{ TBenchmarkItem }

procedure TBenchmarkItem.Add(AItem: TBenchmarkItem);
begin
  FExtraTimeSpan := FExtraTimeSpan + AItem.Elapsed;
  Inc(FTimings, AItem.Timings);
  if (AItem.First <> TTimeSpan.Zero) and ((AItem.FFirstTimeStamp < FFirstTimeStamp) or (FFirst = TTimeSpan.Zero)) then
  begin
    FFirst := AItem.First;
    FFirstTimeStamp := AItem.FFirstTimeStamp;
  end;
  if (AItem.Last <> TTimeSpan.Zero) and ((AItem.FLastTimeStamp > FLastTimeStamp) or (FLast = TTimeSpan.Zero)) then
  begin
    FLast := AItem.Last;
    FLastTimeStamp := AItem.FLastTimeStamp;
  end;
  if (AItem.Max <> TTimeSpan.Zero) and ((AItem.Max > FMax) or (FMax = TTimeSpan.Zero)) then
    FMax := AItem.Max;
  if (AItem.Min <> TTimeSpan.Zero) and ((AItem.Min < FMin) or (FMin = TTimeSpan.Zero)) then
    FMin := AItem.Min;
end;

function TBenchmarkItem.Average: TTimeSpan;
begin
  if FTimings = 0 then
    Result := TTimeSpan.Zero
  else
    Result := TTimeSpan.Create(Round(Elapsed.Ticks / FTimings));
end;

constructor TBenchmarkItem.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FStopwatch := TStopwatch.Create;
end;

function TBenchmarkItem.GetElapsed: TTimeSpan;
begin
  Result := FExtraTimeSpan;
  if FStopwatch.IsRunning then
    Result := Result + FStopwatch.Elapsed;
end;

procedure TBenchmarkItem.Pause;
begin
  if FRunningCount = 1 then
  begin
    FStopwatch.Stop;
    FLast := FStopwatch.Elapsed;
    FLastTimeStamp := TStopwatch.GetTimeStamp;
    if FFirst = TTimeSpan.Zero then
    begin
      FFirst := FLast;
      FFirstTimeStamp := FLastTimeStamp;
    end;
    if (FMax = TTimeSpan.Zero) or (FLast > FMax) then
      FMax := FLast;
    if (FMin = TTimeSpan.Zero) or (FLast < FMin) then
      FMin := FLast;
    FExtraTimeSpan := FExtraTimeSpan + FLast;
  end;
  Dec(FRunningCount);
  if Assigned(FOnStop) then
    FOnStop(Self);
end;

procedure TBenchmarkItem.Reset;
begin
  FTimings := 0;
  FExtraTimeSpan := TTimeSpan.Zero;
  FMax := TTimeSpan.Zero;
  FMin := TTimeSpan.Zero;
  if FRunningCount > 0 then
  begin
    Inc(FTimings);
    FStopwatch.Reset;
    FStopwatch.Start;
  end;
end;

function TBenchmarkItem.Start: TBenchmarkPauser;
begin
  if Assigned(FOnStart) then
    FOnStart(Self);
  Result := TBenchmarkPauser.Create(Self);
  Inc(FRunningCount);
  if FRunningCount = 1 then
  begin
    Inc(FTimings);
    FStopwatch.Reset;
    FStopwatch.Start;
  end;
end;

{ TBenchmark }

procedure TBenchmark.Add(ABenchmark: TBenchmark);
begin
  FExtraTimeSpan := ABenchmark.Elapsed;
  Inc(FTimings, ABenchmark.Timings);
  if (ABenchmark.First <> TTimeSpan.Zero) and ((ABenchmark.FFirstTimeStamp < FFirstTimeStamp) or (FFirst = TTimeSpan.Zero)) then
  begin
    FFirst := ABenchmark.First;
    FFirstTimeStamp := ABenchmark.FFirstTimeStamp;
  end;
  if (ABenchmark.Last <> TTimeSpan.Zero) and ((ABenchmark.FLastTimeStamp > FLastTimeStamp) or (FLast = TTimeSpan.Zero)) then
  begin
    FLast := ABenchmark.Last;
    FLastTimeStamp := ABenchmark.FLastTimeStamp;
  end;
  if (ABenchmark.Max <> TTimeSpan.Zero) and ((ABenchmark.Max > FMax) or (FMax = TTimeSpan.Zero)) then
    FMax := ABenchmark.Max;
  if (ABenchmark.Min <> TTimeSpan.Zero) and ((ABenchmark.Min < FMin) or (FMin = TTimeSpan.Zero)) then
    FMin := ABenchmark.Min;
  for var LItem in ABenchmark.Items do
    Item[LItem.Name].Add(LItem);
end;

function TBenchmark.Average: TTimeSpan;
begin
  if FTimings = 0 then
    Result := TTimeSpan.Zero
  else
    Result := TTimeSpan.Create(Round(Elapsed.Ticks / FTimings));
end;

constructor TBenchmark.Create;
begin
  inherited Create;
  FItems := TObjectDictionary<string, TBenchmarkItem>.Create([doOwnsValues]);
  FStopwatch := TStopwatch.Create;
end;

destructor TBenchmark.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TBenchmark.Dump: string;
begin
  Result := Format('Elapsed: %g ms; Timings: %d; Avg: %g ms; Min: %g ms; Max: %g ms; First: %g ms; Last: %g ms',
    [Elapsed.TotalMilliseconds, Timings, Average.TotalMilliseconds, FMin.TotalMilliseconds, FMax.TotalMilliseconds,
    FFirst.TotalMilliseconds, FLast.TotalMilliseconds]) + sLineBreak;
  var LSortedItems := Items;
  TArray.Sort<TBenchmarkItem>(LSortedItems, TComparer<TBenchmarkItem>.Construct(
    function(const ALeft, ARight: TBenchmarkItem): Integer
    begin
      Result := -CompareValue(ALeft.Elapsed.TotalMilliseconds, ARight.Elapsed.TotalMilliseconds);
    end));
  for var LItem in LSortedItems do
  begin
    Result := Result +
      Format('  Name: %s; Elapsed: %g ms; Timings: %d; Avg: %g ms; Min: %g ms; Max: %g ms; First: %g ms; Last: %g ms',
        [LItem.Name, LItem.Elapsed.TotalMilliseconds, LItem.Timings, LItem.Average.TotalMilliseconds,
        LItem.Min.TotalMilliseconds, LItem.Max.TotalMilliseconds, LItem.First.TotalMilliseconds,
        LItem.Last.TotalMilliseconds]) + sLineBreak;
  end;
  Result := Result.TrimRight;
end;

function TBenchmark.GetElapsed: TTimeSpan;
begin
  Result := FExtraTimeSpan;
  if FStopwatch.IsRunning then
    Result := Result + FStopwatch.Elapsed;
end;

function TBenchmark.GetItem(const AName: string): TBenchmarkItem;
begin
  if not FItems.TryGetValue(AName, Result) then
  begin
    Result := TBenchmarkItem.Create(AName);
    Result.OnStart := StopwatchStart;
    Result.OnStop := StopwatchStop;
    FItems.Add(AName, Result);
  end;
end;

function TBenchmark.GetItems: TArray<TBenchmarkItem>;
begin
  SetLength(Result, FItems.Count);
  var LCount := 0;
  for var LItem in FItems.Values do
    if LItem.Timings > 0 then
    begin
      Result[LCount] := LItem;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

procedure TBenchmark.Reset;
begin
  FTimings := 0;
  FExtraTimeSpan := TTimeSpan.Zero;
  FFirst := TTimeSpan.Zero;
  FFirstTimeStamp := 0;
  FLast := TTimeSpan.Zero;
  FLastTimeStamp := 0;
  FMax := TTimeSpan.Zero;
  FMin := TTimeSpan.Zero;
  if FRunningCount > 0 then
  begin
    Inc(FTimings);
    FStopwatch.Reset;
    FStopwatch.Start;
  end;
  for var LItem in FItems.Values do
    LItem.Reset;
end;

procedure TBenchmark.StopwatchStart(ASender: TObject);
begin
  Inc(FRunningCount);
  if FRunningCount = 1 then
  begin
    Inc(FTimings);
    FStopwatch.Reset;
    FStopwatch.Start;
  end;
end;

procedure TBenchmark.StopwatchStop(ASender: TObject);
begin
  Dec(FRunningCount);
  if FRunningCount = 0 then
  begin
    FStopwatch.Stop;
    FLast := FStopwatch.Elapsed;
    FLastTimeStamp := TStopwatch.GetTimeStamp;
    if FFirst = TTimeSpan.Zero then
    begin
      FFirst := FLast;
      FFirstTimeStamp := FLastTimeStamp;
    end;
    if (FMax = TTimeSpan.Zero) or (FLast > FMax) then
      FMax := FLast;
    if (FMin = TTimeSpan.Zero) or (FLast < FMin) then
      FMin := FLast;
    FExtraTimeSpan := FExtraTimeSpan + FLast;
  end;
end;

initialization
  GlobalBenchmark := TBenchmark.Create;
finalization
  FreeAndNil(GlobalBenchmark);
end.
