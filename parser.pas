program parser;

uses types, json, utils, SysUtils;

const
   LF : char = #10;
var
   tokens : array [1..1000] of PToken;
   ti     : integer = 0; // token index
   pos    : integer = 1;

// increment position
procedure incPos();
begin
   pos := pos + 1;
end;

function peek(offset : integer) : PToken;
begin
   peek := tokens[pos + offset];
end;

procedure consume(s : string);
begin
   if peek(0)^.value = s then
      incPos
   else
      begin
         writeln(stderr, 'line (', peek(0)^.lineno, ')');
         writeln(stderr, 'unexpected token: expected: (', s, '), got: (', peek(0)^.value, ')');
         halt(1);
      end
         ;
end;

function isEnd() : boolean;
begin
   isEnd := (ti < pos);
end;

// --------------------------------

function parseExpr() : PNode; forward;
function parseStmts() : PList; forward;

function _parseArg() : PNode;
var
   t    : PToken;
   node : PNode;
begin
   t := peek(0);

   if t^.kind = 'ident' then
      begin
         incPos;
         Node_initStr(node, t^.value);
         _parseArg := node;
      end
   else if t^.kind = 'int' then
      begin
         incPos;
         Node_initInt(node, StrToInt(t^.value));
         _parseArg := node;
      end
   else
      begin
         writeln(stderr, 'unexpected token kind');
         halt(1);
      end;
end;

function _parseArgs() : PList;
var
   t    : PToken;
   args : PList;
begin
   t := peek(0);

   List_init(args);

   if t^.value <> ')' then
      List_add(args, _parseArg);

   while peek(0)^.value = ',' do
   begin
      consume(',');
      List_add(args, _parseArg);
   end;

   _parseArgs := args
end;

function _parseExprFactor() : PNode;
var
   expr : PNode;
   t    : PToken;
begin
   t := peek(0);

   if t^.kind = 'int' then
      begin
         Node_initInt(expr, StrToInt(t^.value));
         incPos;
         _parseExprFactor := expr;
      end
   else if t^.kind = 'ident' then
      begin
         Node_initStr(expr, t^.value);
         incPos;
         _parseExprFactor := expr;
      end
   else if t^.kind = 'sym' then
      begin
         consume('(');
         _parseExprFactor := parseExpr;
         consume(')');
      end
   else
      begin
         writeln(stderr, '_parseExprFactor: unexpected token kind');
         halt(1);
      end;
end;

function _isBinOp(op : string) : boolean;
begin
   _isBinOp := (
                (op = '+')
                or (op = '*')
                or (op = '==')
                or (op = '!=')
                );
end;

function parseExpr() : PNode;
var
   expr      : PNode;
   rhs       : PNode;
   op        : string;
   tempList  : PList;
   tempNode  : PNode;
begin
   printFnName('parseExpr');
   expr := _parseExprFactor;

   while _isBinOp(peek(0)^.value) do
   begin
      op := peek(0)^.value;
      incPos;
      rhs := _parseExprFactor;

      List_init(tempList);
      List_addStr(tempList, op);
      List_add(tempList, expr);
      List_add(tempList, rhs);

      Node_initList(tempNode, tempList);

      expr := tempNode;
   end
   ;

   parseExpr := expr
end;

function parseSet() : PList;
var
   stmt    : PList;
   varName : string;
   expr    : PNode;
begin
   printFnName('parseSet');
   consume('set');

   varName := peek(0)^.value;
   incPos;

   consume('=');

   expr := parseExpr;

   consume(';');

   List_init(stmt);
   List_addStr(stmt, 'set');
   List_addStr(stmt, varName);
   List_add(stmt, expr);

   parseSet := stmt;
end;

function _parseFuncall() : PList;
var
   funcall : PList;
   fnName  : String;
   args    : PList;
begin
   fnName := peek(0)^.value;
   incPos;

   consume('(');
   args := _parseArgs;
   consume(')');
   consume(';');

   List_init(funcall);
   List_addStr(funcall, fnName);
   List_addAll(funcall, args);
   _parseFuncall := funcall;
end;

function parseCall() : PList;
var
   stmt    : PList;
   funcall : PList;
begin
   consume('call');

   funcall := _parseFuncall;

   List_init(stmt);
   List_addStr(stmt, 'call');
   List_addAll(stmt, funcall);

   parseCall := stmt;
end;

function parseCallSet() : PList;
var
   varName : string;
   funcall : PList;
   stmt    : PList;
begin
   List_init(funcall);
   List_init(stmt);

   consume('call_set');

   varName := peek(0)^.value;
   incPos;

   consume('=');

   funcall := _parseFuncall;

   List_addStr(stmt, 'call_set');
   List_addStr(stmt, varName);
   List_addList(stmt, funcall);

   parseCallSet := stmt;
end;

function parseReturn() : PList;
var
   expr : PNode;
   stmt : PList;
begin
   consume('return');
   expr := parseExpr;
   consume(';');

   List_init(stmt);
   List_addStr(stmt, 'return');
   List_add(stmt, expr);

   parseReturn := stmt;
end;

function parseWhile() : PList;
var
   stmt       : PList;
   condExpr   : PNode;
   innerStmts : PList;
begin
   List_init(stmt);

   consume('while');

   consume('(');
   condExpr := parseExpr;
   consume(')');

   consume('{');
   innerStmts := parseStmts;
   consume('}');

   List_addStr(stmt, 'while');
   List_add(stmt, condExpr);
   List_addList(stmt, innerStmts);

   parseWhile := stmt;
end;

function _parseWhenClause() : PList;
var
   whenClause : PList;
   condExpr   : PNode;
   stmts      : PList;
begin
   List_init(whenClause);

   consume('when');
   consume('(');
   condExpr := parseExpr;
   consume(')');

   consume('{');
   stmts := parseStmts;
   consume('}');

   List_add(whenClause, condExpr);
   List_addAll(whenClause, stmts);

   _parseWhenClause := whenClause;
end;

function parseCase() : PList;
var
   stmt : PList;
begin
   List_init(stmt);
   List_addStr(stmt, 'case');

   consume('case');

   while peek(0)^.value = 'when' do
      List_addList(stmt, _parseWhenClause);

   parseCase := stmt;
end;

function parseVmComment() : PList;
var
   stmt    : PList;
   comment : string;
begin
   printFnName('parseVmComment');

   consume('_cmt');
   consume('(');

   comment := peek(0)^.value;
   incPos;

   consume(')');
   consume(';');

   List_init(stmt);
   List_addStr(stmt, '_cmt');
   List_addStr(stmt, comment);
   parseVmComment := stmt;
end;

function parseStmt() : PList;
var
   t    : PToken;
   stmt : PList;
begin
   List_init(stmt);
   t := peek(0);

   if      t^.value = 'set'      then parseStmt := parseSet
   else if t^.value = 'call'     then parseStmt := parseCall
   else if t^.value = 'call_set' then parseStmt := parseCallSet
   else if t^.value = 'return'   then parseStmt := parseReturn
   else if t^.value = 'while'    then parseStmt := parseWhile
   else if t^.value = 'case'     then parseStmt := parseCase
   else if t^.value = '_cmt'     then parseStmt := parseVmComment
   else
      begin
         writeln(stderr, 'parseStmt: unexpected token (', t^.value, ') lineno (', t^.lineno, ')');
         halt(1);
      end;   
end;

function parseStmts() : PList;
var
   stmts : PList;
begin
   printFnName('parseStmts');
   List_init(stmts);

   while peek(0)^.value <> '}' do
      List_addList(stmts, parseStmt);

   parseStmts := stmts;
end;

function _parseVarDeclare() : PList;
var
   stmt    : PList;
   varName : string;
begin
   varName := peek(0)^.value;
   incPos;

   consume(';');

   List_init(stmt);
   List_addStr(stmt, 'var');
   List_addStr(stmt, varName);

   _parseVarDeclare := stmt;
end;

function _parseVarInit() : PList;
var
   stmt    : PList;
   varName : string;
   expr    : PNode;
begin
   varName := peek(0)^.value;
   incPos;

   consume('=');
   expr := parseExpr;
   consume(';');

   List_init(stmt);
   List_addStr(stmt, 'var');
   List_addStr(stmt, varName);
   List_add(stmt, expr);

   _parseVarInit := stmt;
end;

function parseVar : PList;
begin
   printFnName('parseVar');
   consume('var');

   if peek(1)^.value = '=' then
      parseVar := _parseVarInit
   else if peek(1)^.value = ';' then
      parseVar := _parseVarDeclare
   else
      begin
         writeln(stderr, 'parseVar: unexpected token');
         halt(1);
      end;
end;

function parseFuncDef() : PList;
var
   funcDef : PList;
   fnName  : string;
   args    : PList;
   body    : PList;
begin
   List_init(funcDef);

   consume('func');
   List_addStr(funcDef, 'func');

   fnName := peek(0)^.value;
   incPos;
   List_addStr(funcDef, fnName);

   consume('(');
   args := _parseArgs;
   consume(')');

   List_addList(funcDef, args);
   List_init(body);

   consume('{');

   while peek(0)^.value <> '}' do
   begin
      if peek(0)^.value = 'var' then
         List_addList(body, parseVar)
      else
         List_addList(body, parseStmt);
   end;

   List_addList(funcDef, body);

   consume('}');

   parseFuncDef := funcDef;
end;

function parse() : PList;
var
   topStmts : PList;
begin
   List_init(topStmts);
   List_addStr(topStmts, 'top_stmts');

   while not isEnd do
   begin
      List_addList(topStmts, parseFuncDef());
   end;

   parse := topStmts;
end;

var
   c    : char;
   line : string = '';
   ast  : PList;
begin

   while not eof do
   begin
      read(c);
      if c = LF then
         begin
            ti := ti + 1;
            tokens[ti] := Token_fromList(Json_parse(line));
            line := '';
         end
      else
         line := line + c;
   end;

   ast := parse;

   Json_print(ast, true);
end.
