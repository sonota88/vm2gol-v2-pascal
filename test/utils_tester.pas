program JsonTester;

uses utils, types;

procedure test_char_index();
begin
   writeln('# char index');
   writeln(charIndex('fdsa', 's', 2));
   writeln;
end;

procedure test_substr();
begin
   writeln('# substr');
   writeln(substr('fdsa', 2, 4));
   writeln;
end;

procedure test_matchInt();
begin
   writeln('# matchInt');
   writeln(matchInt('x = 42;', 4)); //=> 0
   writeln(matchInt('x = 42;', 5)); //=> 2
   writeln(matchInt('x = -42;', 5)); //=> 3
   writeln;
end;

procedure test_matchIdent();
begin
   writeln('# matchIdent');
   writeln(matchIdent('func main()', 5));
   writeln(matchIdent('func main()', 6));
   writeln;
end;

procedure test_replace();
begin
   writeln('# replace');
   writeln(replace('a b  c', ' ', '~'));
   writeln;
end;

begin
   test_char_index;
   test_substr;
   test_matchInt;
   test_matchIdent;
   test_replace;
end.
