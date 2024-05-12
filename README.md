# Basic usage

```pascal
procedure ProcA;
begin
  var T := GlobalBenchmark['ProcA'].Start;
  ...
  T.Stop;
end;

procedure ProcB;
begin
  var T := GlobalBenchmark['ProcB'].Start;
  ...
  T.Stop;
end;

procedure ShowBenchmark;
begin
  ShowMessage(GlobalBenchmark.Dump);
end;
```

Example of results:

```
Elapsed: 13.9413 ms; Timings: 92; Avg: 0.1515 ms; Min: 0.025 ms; Max: 4.2468 ms; First: 0.0463 ms; Last: 0.1318 ms
  Name: ProcA; Elapsed: 3.3347 ms; Timings: 46; Avg: 0.0725 ms; Min: 0.0247 ms; Max: 0.2645 ms; First: 0.0419 ms; Last: 0.0949 ms
  Name: ProcB; Elapsed: 10.5203 ms; Timings: 46; Avg: 0.2287 ms; Min: 0.0302 ms; Max: 4.2461 ms; First: 4.2461 ms; Last: 0.1315 ms
```