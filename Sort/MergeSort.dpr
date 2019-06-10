program MergeSort;
//
// ���������� ���������� �� ��������� ������� Delphi ��������� v3 (2)
//
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  aSort in 'aSort.pas';

Const
  inputFile = 'input.txt' ;    // ��� ����� ������ ��� ����������
  tempFile = 'temp.sort' ;
  outputFile = 'output.sort' ; // ���� � ����������� ����������
  BufferSize = 1024 * 1024 ;   // ����� ��� ����������
  MaxLines = 99999 ;           // ���-�� ����� ��� GenerateTest

Var
  TempFileCount : integer = 1 ;
  FSize : integer ;
  Th : array of SortThread ; // ������ ��� �������� ������ �� ������ ����������

Procedure SplitInputFile ;
//
// ��������� ��������� ������� ����� �� ��������� �����, �.�. ������
// ������ ��� ���������� ���������, ����� � ������� �� ����������.
// ������������ ������� ���������� � ������ ����������, ����������
// ���������� ��������.
// ��� �������� ����� �� ����� ����� ����� ����������� ������,
// �� ��� �������� ������������ ������������� ����� ��� ����������,
// ���-��� ������ �������� ���� �� ����� � �������� BufferSize � ������ �����
// � �������� ������� ���������� ��� ������� �����.
//

Var
  InStr,OutStr : TFileStream ;
  PBuffer : PChar ;
//  PBuffer : PAnsiChar ;  // ��� Delphi 10.3
  BytesRead, j : integer ;
  SeekPosition : longint ;
  OutputFileName : String ;
begin
  SeekPosition := 0 ;
  BytesRead := -1 ;

  if FileExists(inputFile)
   then InStr := TFileStream.Create(inputFile, fmOpenRead)
   else begin
     Writeln('Input file not found (',inputFile,') !' ) ;
     Halt ;
   end ;
  FSize := InStr.Size ;
  repeat
     InStr.Seek(SeekPosition, soFromBeginning) ;
     GetMem(PBuffer, BufferSize) ;
     BytesRead := InStr.Read(PBuffer[0], BufferSize) ;
     try
       // ���� ��������� ������ � ������
       for j := BytesRead downto 1 do
       begin
         if PBuffer[j] = #13  // ���� ANSI, ���� CrLf
           then break ;
       end ;
       // Ok, �����, ��������� ��� �������������� ����� � ����� ������
       OutputFileName := tempFile + IntToStr(TempFileCount) ;
       OutStr := TFileStream.Create(OutputFileName, fmCreate) ;
       OutStr.Write(PBuffer[0], j) ;
       FreeAndNil(OutStr);
       SeekPosition := SeekPosition + j + 2 ;


       // ��������� ���� ����� , ��������� ������� ��� ��� ����������
       SetLength(Th, TempFileCount) ;
       Th[Pred(TempFileCount)] := SortThread.Create(False) ;
       With Th[Pred(TempFileCount)] do
       begin
         FileName := OutputFileName ;
         Priority := tpNormal ;
         Resume ;  // ������ ����������
       end ;

     finally
       FreeMem(PBuffer) ;
       Inc(TempFileCount) ; // � ��� ��������� ��������� ������ ��� ����������
     end ;
  until (BytesRead < BufferSize) ;
  FreeAndNil(InStr);
  Dec(TempFileCount) ;
end ;
//
// ���������� ��������
//
Procedure MergeSortedFiles ;
Var
  i,j : integer ;
  Buffer : array of String ;
  Files : array of TextFile ;
  f : TextFile ;


  // ������� ������ ������� ������������ �������� � ������
  // ��� -1, ���� ��� �������������
  function MinItem : integer ;
  Var
    Min : String ;
    i : integer ;
  begin
     // �������� ������ �������� ������� � ������
     Result := -1 ;
     Min := #0 ;
     for i := 1 to Length(Buffer) do
       if Buffer[Pred(i)] <> #0
         then begin Min := Buffer[Pred(i)] ; break ; end ;
     if Min = #0 then exit ;  // ��� �������� ������ �������, ��������� ����������

     for i := 1 to Length(Buffer) do
     begin
       if Buffer[Pred(i)] = #0
         then continue ;
       if Copy(Buffer[Pred(i)],1,50) <= Min then
       begin
         Min := Copy(Buffer[Pred(i)],1,50) ;
         Result := Pred(i) ;
       end ;
     end ;
  end ;


begin
  SetLength(Buffer, TempFileCount) ;
  SetLength(Files, TempFileCount) ;
{$I-}
  for i := 0 to Pred(Length(Files)) do
  begin
    AssignFile(Files[i], tempFile + IntToStr(Succ(i))) ;
    Reset(Files[i]) ;
    Readln(Files[i], Buffer[i]) ;
  end ;

  AssignFile(f, outputFile) ;
  Rewrite(f) ;

{$I+}
  if IOResult <> 0
    then begin
      Writeln('I/O Error !') ;
      Halt ;
    end ;

    // ������� �����������. ���������� �������� �� ���� ������ �����.
    j := -1 ;
    repeat
      j := MinItem ;
      if j < 0 then break ;
      Writeln(f,Buffer[j]) ;

      if Eof(Files[j]) then
      begin
        Buffer[j] := #0 ;
        CloseFile(Files[j]) ;
        DeleteFile(tempFile + IntToStr(Succ(j))) ;
        Writeln('File ',tempFile + IntToStr(Succ(j)),' processed ... ') ;
        continue ;
      end ;

      Readln(Files[j], Buffer[j]) ;
    until (j < 0) ;
    CloseFile(f) ; // ���������� ��������
    Files := nil ;
    Buffer := nil ;
end ;

//
// ������ ��������� �������� ����
//
Procedure GenerateTest ;
Var
  i,j,k : integer ;
  f : textFile ;
begin
  Write('Make input file ... ') ;
{$I-}
  Assign(f, inputFile) ;
  Rewrite(f) ;
{$I+}
  if IOResult <> 0
  then begin
    Writeln('I/O Error') ;
    Halt ;
  end ;
  Randomize ;
  for i := 1 to MaxLines do
  begin
    for j := 1 to (Random(49)+30) do
    begin
       k := 48 + Random(74) ;
       if k in [58..64] then continue ;
       if k in [91..96] then continue ;
      Write(f, Chr(k)) ;
    end ;
    Writeln(f) ;
  end ;
  Close(f) ;
  Writeln('O''k.') ;
end ;


Var
  i : integer ;
  t : TDateTime;
begin

  // ����� �������� �������� ����
  // ���� ���������� ����, �� ������ ��� ������ ��������� inputFile
  // � ������������ ������
  GenerateTest ;

  t := Now() ;

  // ��������� �������� ���� �� �����, ���� � ������ ����������� ��
  // ����� - ��� ����������.
  // ����� ����� ��������� ������ ��������. ������������.
  SplitInputFile ;

  // ������� ��������� ���� �������� ���������� ...
  for i := 0 to Pred(Length(Th)) do
  begin
     Th[i].WaitFor ;
     FreeAndNil(Th[i]) ;
  end ;
  Th := nil ;

  // �� ������ ������ ����� ���� ������ � ��������������� �������.
  // ��������� ������� ������ � ����.

  MergeSortedFiles ;


  Writeln('EndOfSort. (',FormatDateTime('h.n.s.z',Now() - t),'mc.)') ;
  Writeln('Used buffer : ', BufferSize/1024/1024:0:0, ' M.') ;
  Writeln('Source file : ',FSize/1024/1024:0:2, ' M.') ;
end.




