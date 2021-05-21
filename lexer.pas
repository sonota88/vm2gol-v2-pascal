program lexer;

uses types, json, utils;

const
   LF : char = #10;

function isKw(s : string) : boolean;
begin
   isKw := (
            (s = 'func')
            or (s = 'var')
            or (s = 'set')
            or (s = 'call')
            or (s = 'call_set')
            or (s = 'return')
            or (s = 'while')
            or (s = 'case')
            or (s = '_cmt')
            );
end;

function matchSym(str : string; pos : integer) : integer;
var
   c1 : char;
   c2 : char;
begin
   c1 := str[pos];
   c2 := str[pos + 1];

   if (
       ((c1 = '=') and (c2 = '='))
       or ((c1 = '!') and (c2 = '='))
       )
      then
      matchSym := 2
   else if (
       (c1 = '(')
       or (c1 = ')')
       or (c1 = '{')
       or (c1 = '}')
       or (c1 = ';')
       or (c1 = '=')
       or (c1 = ',')
       or (c1 = '+')
       or (c1 = '*')
       )
      then
      matchSym := 1
   else
      matchSym := 0;
end;

function matchComment(str : string; pos : integer) : integer;
var
   c1 : char;
   c2 : char;
begin
   c1 := str[pos];
   c2 := str[pos + 1];

   if (c1 = '/') and (c2 = '/') then
      begin
         matchComment := charIndex(str, LF, pos) - pos;
      end
   else
      matchComment := 0
   ;
end;

procedure printToken(kind : string; value : string; lineno : integer);
var
   token : PToken;
begin
   Token_init(token, lineno, kind, value);
   Json_print(Token_toList(token), false);
   writeln;
end;

var
   input  : string;
   pos    : integer = 1;
   size   : integer;
   str    : string;
   lineno : integer = 1;
begin
   input := readStdinAll;

   while pos <= length(input) do
   begin
      if (input[pos] = ' ') then
         pos := pos + 1

      else if (input[pos] = LF) then
         begin
            lineno := lineno + 1;
            pos := pos + 1;
         end

      else if 0 < matchSym(input, pos) then
         begin
            size := matchSym(input, pos);
            str := substr(input, pos, pos + size);
            printToken('sym', str, lineno);
            pos := pos + size;
         end

      else if 0 < matchComment(input, pos) then
         begin
            size := matchComment(input, pos);
            pos := pos + size;
         end

      else if 0 <= matchStr(input, pos) then
         begin
            size := matchStr(input, pos);
            str := substr(input, pos + 1, pos + size + 1);
            printToken('str', str, lineno);
            pos := pos + size + 2;
         end

      else if 0 < matchInt(input, pos) then
         begin
            size := matchInt(input, pos);
            str := substr(input, pos, pos + size);
            printToken('int', str, lineno);
            pos := pos + size;
         end

      else if 0 < matchIdent(input, pos) then
         begin
            size := matchIdent(input, pos);
            str := substr(input, pos, pos + size);

            if isKw(str) then
               printToken('kw', str, lineno)
            else
               printToken('ident', str, lineno);
   
            pos := pos + size;
         end

      else
         begin
            writeln(stderr, 'pos (', pos, ')');
            writeln(stderr, 'lineno (', lineno, ')');
            writeln(stderr, 'rest (', substr(input, pos, length(input) + 1), ')');
            writeln(stderr, 'unexpected pattern');
            halt(1);
         end;
end;

end.
