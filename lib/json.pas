unit json;

// --------------------------------
interface

uses utils, types, SysUtils;

procedure Json_print(list_ : PList; pretty : boolean);
function Json_parse(json : string) : PList;

// --------------------------------
implementation

const
   LF : char =  #10;

procedure Json_printList(list_ : PList; lv : integer; pretty : boolean); forward;
function Json_parseList(
   json        : string;
   argPos      : integer;
   var argSize : integer
) : PList; forward;

procedure printIndent(lv : integer);
var
   i : integer = 0;
begin
   while i < lv * 2 do
   begin
      write(' ');
      i := i + 1;
   end;
end;

procedure Json_printNode(node : PNode; lv : integer; pretty : boolean);
begin
   case node^.kind of
     NKInt :
          begin
             write(node^.intVal);
          end;
     NKStr :
          begin
             write('"', node^.strVal, '"');
          end;
     NKList :
          begin
             Json_printList(node^.list, lv, pretty);
          end;
     else
          begin
             writeln('invalid kind');
             halt(1);
          end;
   end;
end;

procedure Json_printList(list_ : PList; lv : integer; pretty : boolean);
var
   i    : integer = 1;
   node : PNode;
begin
   write('[');
   if pretty then writeln;

   while i <= list_^.size do
   begin
      node := List_get(list_, i);
      if pretty then printIndent(lv + 1);
      Json_printNode(node, lv + 1, pretty);

      if i < list_^.size then
      begin
         if pretty then
            write(',')
         else
            write(', ');
      end;

      if pretty then writeln;
      i := i + 1;
   end;

   printIndent(lv);
   write(']');
end;

procedure Json_print(list_ : PList; pretty : boolean);
begin
   Json_printList(list_, 0, pretty);
end;

function Json_parseNode(
   json        : string;
   pos         : integer;
   var argSize : integer
) : PNode;
var
   node : PNode;
   c    : char;
   size : integer;
   str  : string;
begin
   c := json[pos];

   if c = '[' then
      begin
         Node_initList(
                       node,
                       Json_parseList(json, pos, size)
                       );
      end
   else if 0 <= matchStr(json, pos) then
      begin
         size := matchStr(json, pos);
         str := substr(json, pos + 1, pos + size + 1);
         Node_initStr(node, str);
         size := size + 2;
      end
   else if 0 < matchInt(json, pos) then
      begin
         size := matchInt(json, pos);
         str := substr(json, pos, pos + size);
         Node_initInt(node, StrToInt(str));
      end
   else
      begin
         writeln(stderr, 'pos (', pos, ')');
         writeln(stderr, 'c (', c, ')');
         write(stderr, 'unexpected pattern');
         writeln(stderr);
         halt(1);
      end;

   argSize := size;
   Json_parseNode := node;
end;

function Json_parseList(
   json        : string;
   argPos      : integer;
   var argSize : integer
) : PList;
var
   list_ : PList;
   c     : char;
   pos   : integer;
   size  : integer;
   node  : PNode;
begin
   List_init(list_);
   pos := argPos + 1;

   while pos <= length(json) do
   begin
      c := json[pos];

      if c = ']' then
         break
      else if (c = ' ') or (c = ',') or (c = LF) then
         begin
            size := 1;
         end
      else
         begin
            node := Json_parseNode(json, pos, size);
            List_add(list_, node);
         end;

      pos := pos + size;
   end;

   argSize := pos - argPos + 1;
   Json_parseList := list_;
end;

function Json_parse(json : string) : PList;
var
   size  : integer;
begin
   Json_parse := Json_parseList(json, 1, size);
end;

end.
