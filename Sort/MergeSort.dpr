program MergeSort;
//
// Реализация сортировки по тестовому заданию Delphi системное v3 (2)
//
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  aSort in 'aSort.pas';

Const
  inputFile = 'input.txt' ;    // Имя файла данных для сортировки
  tempFile = 'temp.sort' ;
  outputFile = 'output.sort' ; // Файл с результатом сортировки
  BufferSize = 1024 * 1024 ;   // Буфер для сортировки
  MaxLines = 99999 ;           // Кол-во строк для GenerateTest

Var
  TempFileCount : integer = 1 ;
  FSize : integer ;
  Th : array of SortThread ; // Массив для хранения ссылок на потоки сортировки

Procedure SplitInputFile ;
//
// Процедура разбивает входной поток на отдельные файлы, т.к. размер
// буфера для сортировки небольшой, задан в задании на разработку.
// Использовать простую сортировку в памяти невозможно, используем
// сортировку слиянием.
// При разбивке файла на части можно сразу сортировать данные,
// но мне хотелось использовать многопоточный метод для сортировки,
// так-что просто разобъем файл на части в пределах BufferSize с учетом строк
// и запустим процесс сортировки для каждого файла.
//

Var
  InStr,OutStr : TFileStream ;
  PBuffer : PChar ;
//  PBuffer : PAnsiChar ;  // Для Delphi 10.3
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
       // Ищем окончание строки в буфере
       for j := BytesRead downto 1 do
       begin
         if PBuffer[j] = #13  // Файл ANSI, ищем CrLf
           then break ;
       end ;
       // Ok, нашли, формируем имя промежуточного файла и пишем данные
       OutputFileName := tempFile + IntToStr(TempFileCount) ;
       OutStr := TFileStream.Create(OutputFileName, fmCreate) ;
       OutStr.Write(PBuffer[0], j) ;
       FreeAndNil(OutStr);
       SeekPosition := SeekPosition + j + 2 ;


       // Временный файл готов , запускаем процесс для его сортировки
       SetLength(Th, TempFileCount) ;
       Th[Pred(TempFileCount)] := SortThread.Create(False) ;
       With Th[Pred(TempFileCount)] do
       begin
         FileName := OutputFileName ;
         Priority := tpNormal ;
         Resume ;  // Запуск сортировки
       end ;

     finally
       FreeMem(PBuffer) ;
       Inc(TempFileCount) ; // У нас несколько временных файлов для сортировки
     end ;
  until (BytesRead < BufferSize) ;
  FreeAndNil(InStr);
  Dec(TempFileCount) ;
end ;
//
// Сортировка слиянием
//
Procedure MergeSortedFiles ;
Var
  i,j : integer ;
  Buffer : array of String ;
  Files : array of TextFile ;
  f : TextFile ;


  // Функция выдает позицию минимального элемента в буфере
  // или -1, если все отсортировали
  function MinItem : integer ;
  Var
    Min : String ;
    i : integer ;
  begin
     // Выбираем первый непустой элемент в масиве
     Result := -1 ;
     Min := #0 ;
     for i := 1 to Length(Buffer) do
       if Buffer[Pred(i)] <> #0
         then begin Min := Buffer[Pred(i)] ; break ; end ;
     if Min = #0 then exit ;  // Все элементы буфера выбраны, завершаем сортировку

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

    // Поехали сортировать. Сортировка слиянием из всех файлов сразу.
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
    CloseFile(f) ; // Сортировка окончена
    Files := nil ;
    Buffer := nil ;
end ;

//
// Просто формируем тестовый файл
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

  // Умеем генерить тестовый файл
  // Если используем свой, то кладем под именем константы inputFile
  // и комментируем строку
  GenerateTest ;

  t := Now() ;

  // Разбиваем исходный файл на части, весь в памяти сортировать не
  // можем - ОЗУ ограничено.
  // Части файла сортируем каждую отдельно. Многопоточно.
  SplitInputFile ;

  // Ожидаем окончания всех процесов сортировки ...
  for i := 0 to Pred(Length(Th)) do
  begin
     Th[i].WaitFor ;
     FreeAndNil(Th[i]) ;
  end ;
  Th := nil ;

  // На данный момент имеем кучу файлов с отсортированным текстом.
  // Запускаем слияние файлов в один.

  MergeSortedFiles ;


  Writeln('EndOfSort. (',FormatDateTime('h.n.s.z',Now() - t),'mc.)') ;
  Writeln('Used buffer : ', BufferSize/1024/1024:0:0, ' M.') ;
  Writeln('Source file : ',FSize/1024/1024:0:2, ' M.') ;
end.




