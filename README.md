# Basic usage

```pascal
procedure ProcA;
begin
  var T := GlobalBenchmark['ProcA'].Start;
  ...
  T.Stop;
end;

procedure ShowBenchmark;
begin
  ShowMessage(GlobalBenchmark.Dump);
end;
```