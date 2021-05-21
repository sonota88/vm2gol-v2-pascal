program JsonTester;

uses utils, json, types;

procedure test_01();
var
   list_ : PList;
begin
   List_init(list_);

   Json_print(list_, true);
end;

procedure test_02();
var
   list_ : PList;
begin
   List_init(list_);
   List_addInt(list_, 1);

   Json_print(list_, true);
end;

procedure test_03();
var
   list_ : PList;
begin
   List_init(list_);
   List_addStr(list_, 'fdsa');

   Json_print(list_, true);
end;

procedure test_04();
var
   list_ : PList;
begin
   List_init(list_);
   List_addInt(list_, -123);
   List_addStr(list_, 'fdsa');

   Json_print(list_, true);
end;

procedure test_05();
var
   list_ : PList;
   childList : PList;
begin
   List_init(list_);
   List_init(childList);

   List_addList(list_, childList);

   Json_print(list_, true);
end;

procedure test_06();
var
   list_ : PList;
   childList : PList;
begin
   List_init(list_);
   List_init(childList);

   List_addInt(list_, 1);
   List_addStr(list_, 'a');

   List_addInt(childList, 2);
   List_addStr(childList, 'b');
   List_addList(list_, childList);

   List_addInt(list_, 3);
   List_addStr(list_, 'c');

   Json_print(list_, true);
end;

procedure test_07();
var
   list_ : PList;
begin
   List_init(list_);

   List_addStr(list_, '漢字');

   Json_print(list_, true);
end;

var
   input : string;
   list_ : PList;
begin
   // test_01;
   // test_02;
   // test_03;
   // test_04;
   // test_05;
   // test_06;
   // test_07;

   input := readStdinAll;

   list_ := Json_parse(input);
   Json_print(list_, true);

   writeln(stderr);
end.
