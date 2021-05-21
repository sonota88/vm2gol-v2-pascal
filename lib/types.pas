unit types;

// --------------------------------
interface

type
   NodeKind = (
               NKInt,
               NKStr,
               NKList
               );

type
   PList = ^List;
   Node = record
             kind   : NodeKind;
             intVal : integer;
             strVal : String;
             list   : PList;
          end;
   
   PNode = ^Node;
   List = record
             size  : integer;
             items : array [1..100] of PNode;
           end;

type
   PToken = ^Token;
   Token  = record
               lineno : integer;
               kind   : string;
               value  : string;
            end;     

procedure List_init(var self : PList);
function List_size(self : PList) : integer;
procedure List_add(self : PList; node: PNode);
procedure List_addInt(var self : PList; n : integer);
procedure List_addStr(var self : PList; s : string);
procedure List_addList(var self : PList; childList : PList);
procedure List_addAll(self : PList; other : PList);
function List_get(self : PList; i : integer): PNode;
function List_rest(self : PList): PList;
function Names_index(self : PList; s : string): integer;
function Names_includes(self : PList; s : string): boolean;

procedure Node_initInt(var self : PNode; n : integer);
procedure Node_initStr(var self : PNode; s : string);
procedure Node_initList(var self : PNode; list_ : PList);

procedure Token_init(var self : PToken; lineno : integer; kind : string; value : string);
function Token_toList(self : PToken) : PList;
function Token_fromList(list_ : PList) : PToken;

// --------------------------------
implementation

uses json;

procedure List_init(var self : PList);
begin
   new(self);
   self^.size := 0;
end;

function List_size(self : PList) : integer;
begin
   List_size := self^.size;
end;

procedure List_add(self : PList; node: PNode);
begin
   self^.size := self^.size + 1;
   self^.items[self^.size] := node;
end;

procedure List_addInt(var self : PList; n: integer);
var
   node : PNode;
begin
   Node_initInt(node, n);
   List_add(self, node);
end;

procedure List_addStr(var self : PList; s : string);
var
   node : PNode;
begin
   Node_initStr(node, s);
   List_add(self, node);
end;

procedure List_addList(var self : PList; childList : PList);
var
   node : PNode;
begin
   Node_initList(node, childList);
   List_add(self, node);
end;

procedure List_addAll(self : PList; other : PList);
var
   i : integer = 1;
begin
   while i <= List_size(other) do
      begin
         List_add(self, List_get(other, i));
         i := i + 1;
      end;
end;

function List_get(self : PList; i : integer): PNode;
begin
   List_get := self^.items[i];
end;

function List_rest(self : PList): PList;
var
   newlist : PList;
   i       : integer = 2;
begin
   List_init(newlist);

   while i <= List_size(self) do
   begin
      List_add(newlist, List_get(self, i));
      i := i + 1;
   end;

   List_rest := newlist;
end;

function Names_index(self : PList; s : string): integer;
var
   i     : integer = 1;
begin
   Names_index := 0;

   while i <= List_size(self) do
   begin
      if List_get(self, i)^.strVal = s then
      begin
         Names_index := i;
         break;
      end;
      i := i + 1;
   end;
end;

function Names_includes(self : PList; s : string): boolean;
begin
   Names_includes := 1 <= Names_index(self, s);
end;

// --------------------------------

procedure Node_initInt(var self : PNode; n : integer);
begin
   new(self);
   self^.kind := NKInt;
   self^.intVal := n;
end;

procedure Node_initStr(var self : PNode; s : string);
begin
   new(self);
   self^.kind := NKStr;
   self^.strVal := s;
end;

procedure Node_initList(var self : PNode; list_ : PList);
begin
   new(self);
   self^.kind := NKList;
   self^.list := list_;
end;

// --------------------------------

procedure Token_init(         
                     var self : PToken;
                     lineno   : integer;
                     kind     : string;
                     value    : string
                     );     
begin
   new(self);
   self^.lineno := lineno;
   self^.kind := kind;
   self^.value := value;
end;

function Token_toList(self : PToken) : PList;
var
   list_ : PList;
begin
   List_init(list_);
   List_addInt(list_, self^.lineno);
   List_addStr(list_, self^.kind);
   List_addStr(list_, self^.value);

   Token_toList := list_;
end;

function Token_fromList(list_ : PList) : PToken;
var
   token  : PToken;
   lineno : integer;
   kind   : string;
   value  : string;
begin
   lineno := List_get(list_, 1)^.intVal;
   kind   := List_get(list_, 2)^.strVal;
   value  := List_get(list_, 3)^.strVal;

   Token_init(token, lineno, kind, value);

   Token_fromList := token;
end;

end.
