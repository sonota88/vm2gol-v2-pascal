unit utils;

// --------------------------------
interface

function readStdinAll() : string;
function charIndex(str : string; c : char; startPos : integer) : integer;
function matchInt(rest : string; pos : integer) : integer;
function matchStr(rest : string; pos : integer) : integer;
function matchIdent(rest : string; pos : integer) : integer;
function substr(str : string; startPos : integer; endPos : integer) : string;
function replace(str : string; pattern : string; replace_ : string) : string;
procedure printFnName(fnName : string);

// --------------------------------
implementation

function readStdinAll() : string;
var
   i     : integer = 1;
   c     : char;
   input : string = '';
begin
   while not eof do
   begin
      read(c);
      input := input + c;
      i := i + 1;
   end;

   readStdinAll := input;
end;

function charIndex(str : string; c : char; startPos : integer) : integer;
var
   pos   : integer;
   found : boolean = false;
begin
   pos := startPos;
   while pos <= length(str) do
   begin
      if str[pos] = c then
         begin
            found := true;
            break;
         end;
      pos := pos + 1;
   end;

   if found then
      charIndex := pos
   else
      charIndex := -1;
end;

function isDigitChar(c : char) : boolean;
var
   ordC : integer;
begin
   ordC := ord(c);

   if (ord('0') <= ordC) and (ordC <= ord('9')) then
      isDigitChar := true
   else
      isDigitChar := false
      ;
end;

function isIdentChar(c : char) : boolean;
var
   ordC : integer;
begin
   ordC := ord(c);

   isIdentChar := (
                   (ord('a') <= ordC) and (ordC <= ord('z'))
                   or isDigitChar(c)
                   or (c = '_')
                   );
end;

function nonDigitIndex(str : string; startPos : integer) : integer;
var
   pos : integer;
begin
   pos := startPos;
   while isDigitChar(str[pos]) do
   begin
      pos := pos + 1;
   end;

   nonDigitIndex := pos;
end;

function matchInt(rest : string; pos : integer) : integer;
begin
   if isDigitChar(rest[pos]) then
      begin
         matchInt := nonDigitIndex(rest, pos) - pos;
      end
   else if rest[pos] = '-' then
      begin
         matchInt := nonDigitIndex(rest, pos + 1) - pos;
      end
   else
      matchInt := 0;
end;

function matchStr(rest : string; pos : integer) : integer;
var
   endPos : integer;
begin
   if rest[pos] <> '"' then
      matchStr := -1
   else
      begin
         endPos := charIndex(rest, '"', pos + 1);
         matchStr := endPos - pos - 1;
      end;
end;

function nonIdentIndex(str : string; startPos : integer) : integer;
var
   pos   : integer;
   found : boolean;
begin
   pos := startPos;
   while pos <= length(str) do
   begin
      if not isIdentChar(str[pos]) then
         begin
            found := true;
            break;
         end;
      pos := pos + 1;
   end;

   if found then
      nonIdentIndex := pos
   else
      nonIdentIndex := 0;
end;

function matchIdent(rest : string; pos : integer) : integer;
var
   endPos : integer;
begin
   if not isIdentChar(rest[pos]) then
      matchIdent := 0
   else
      begin
         endPos := nonIdentIndex(rest, pos);
         matchIdent := endPos - pos;
      end;
end;

function substr(str : string; startPos : integer; endPos : integer) : string;
var
   s    : string = '';
   pos_ : integer;
begin
   pos_ := startPos;
   while pos_ < endPos do
   begin
      s := s + str[pos_];
      pos_ := pos_ + 1;
   end;

   substr := s;
end;

function replace(str : string; pattern : string; replace_ : string) : string;
var
   s : string = '';
   i : integer = 1;
begin
   while i <= length(str) do
      begin
         if str[i] = pattern then
            s := s + replace_
         else
            s := s + str[i];
   
         i := i + 1;
      end;
   replace := s;
end;

// print for debug
procedure printFnName(fnName : string);
begin
   // writeln(stderr, '    |-->> ', fnName);
end;

end.
