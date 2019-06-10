unit aSort;

interface

uses
  Classes;

type
  SortThread = class(TThread)
    FileName : string ;
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure SortThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ SortThread }

Uses SysUtils ;

function SortFirst50bytes(List : TStringList; Index1, Index2 : Integer) : Integer ;
begin
  if Copy(List[Index1],1,50) < Copy(List[Index2],1,50)
    then Result := -1
    else if Copy(List[Index1],1,50) > Copy(List[Index2],1,50)
      then Result := 1
        else Result := 0 ;
end ;

//
// Простая сортировка в памяти. Используется стандартный метод Sort
// TStringList.
//
procedure SortThread.Execute;
Var
  sf : TStringList ;
  IOError : boolean ;
begin
  IOError := False ;
  Writeln('Start soft, file : ' + FileName) ;
  try
    sf := TStringList.Create;
{$I-}
    if FileExists(FileName)
      then sf.LoadFromFile(FileName)
      else IOError := True ;
{$I+}
    if IOError then
    begin
      Writeln('File not exists - ' + FileName + '!') ;
      Exit ;
    end ;
    sf.CustomSort(SortFirst50bytes);
    sf.SaveToFile(FileName);
   finally
     sf.Free;
   end ;
   Writeln('Stop sort, file : ' + FileName) ;
end;

end.
