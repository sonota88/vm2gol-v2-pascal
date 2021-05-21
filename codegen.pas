program codegen;

uses json, types, utils, SysUtils;

var
   GLabelId : integer = 0;

procedure asmPrologue();
begin
   writeln('  push bp');
   writeln('  cp sp bp');
end;

procedure asmEpilogue();
begin
   writeln('  cp bp sp');
   writeln('  pop bp');
end;

function getNextLabelId() : integer;
begin
   GLabelId := GLabelId + 1;
   getNextLabelId := GLabelId;
end;

function lvarDisp(names : PList; name : string) : integer;
var
   i : integer;
begin
   i := Names_index(names, name);
   lvarDisp := -i;
end;

function fnArgDisp(names : PList; name : string) : integer;
var
   i : integer;
begin
   i := Names_index(names, name);
   fnArgDisp := i + 1;
end;

// --------------------------------

procedure genExpr(fnArgNames : PList; lvarNames : PList; expr : PNode); forward;
procedure genStmts(fnArgNames : PList; lvarNames : PList; stmts : PList); forward;
procedure genStmt(fnArgNames : PList; lvarNames : PList; stmt : PList); forward;
procedure genVmComment(comment : String); forward;

procedure _genExprAdd();
begin
   writeln('  pop reg_b');
   writeln('  pop reg_a');
   writeln('  add_ab');
end;

procedure _genExprMult();
begin
   writeln('  pop reg_b');
   writeln('  pop reg_a');
   writeln('  mult_ab');
end;

procedure _genExprEq();
var
   labelId : integer;
begin
   labelId := getNextLabelId;

   writeln('  pop reg_b');
   writeln('  pop reg_a');

   writeln('  compare');
   writeln('  jump_eq then_', labelId);
   writeln('  cp 0 reg_a');
   writeln('  jump end_eq_', labelId);

   writeln('label then_', labelId);
   writeln('  cp 1 reg_a');

   writeln('label end_eq_', labelId);
end;

procedure _genExprNeq();
var
   labelId : integer;
begin
   labelId := getNextLabelId;

   writeln('  pop reg_b');
   writeln('  pop reg_a');

   writeln('  compare');
   writeln('  jump_eq then_', labelId);
   writeln('  cp 1 reg_a');
   writeln('  jump end_neq_', labelId);

   writeln('label then_', labelId);
   writeln('  cp 0 reg_a');

   writeln('label end_neq_', labelId);
end;

procedure _genExprBinop(fnArgNames : PList; lvarNames : PList; list_ : PList);
var
   opStr : string;
begin
   genExpr(fnArgNames, lvarNames, List_get(list_, 2));
   writeln('  push reg_a');

   genExpr(fnArgNames, lvarNames, List_get(list_, 3));
   writeln('  push reg_a');

   opStr := List_get(list_, 1)^.strVal;

   if      opStr = '+'  then _genExprAdd
   else if opStr = '*'  then _genExprMult
   else if opStr = '==' then _genExprEq
   else if opStr = '!=' then _genExprNeq
   else
      begin
         writeln(stderr, 'unexpected operator');
         halt(1);
      end;
end;

procedure genExpr(fnArgNames : PList; lvarNames : PList; expr : PNode);
var
   disp : integer;
begin
   case expr^.kind of
     NKInt :
          begin
             writeln('  cp ', expr^.intVal, ' reg_a');
          end;
     NKStr :
          begin
             if Names_includes(lvarNames, expr^.strVal) then
                begin
                   disp := lvarDisp(lvarNames, expr^.strVal);
                   writeln('  cp [bp:', disp, '] reg_a');
                end
             else if Names_includes(fnArgNames, expr^.strVal) then
                begin
                   disp := fnArgDisp(fnArgNames, expr^.strVal);
                   writeln('  cp [bp:', disp, '] reg_a');
                end
             else
                begin
                   writeln(stderr, 'must not happen');
                   halt(1);
                end
          end;
     NKList :
          begin
             _genExprBinop(fnArgNames, lvarNames, expr^.list);
          end;
     else
          begin
             writeln(stderr, 'unexpected node kind');
             halt(1);
          end;
   end;
end;

procedure _genCall(fnArgNames : PList; lvarNames : PList; funcall : PList);
var
   fnName : string;
   i      : integer;
   arg    : PNode;
begin
   fnName := List_get(funcall, 1)^.strVal;

   i := List_size(funcall);
   while 2 <= i do
   begin
      arg := List_get(funcall, i);
      genExpr(fnArgNames, lvarNames, arg);
      writeln('  push reg_a');
      i := i - 1;
   end;

   genVmComment('call  ' + fnName);
   writeln('  call ', fnName);
   writeln('  add_sp ', List_size(funcall) - 1);
end;

procedure genCall(fnArgNames : PList; lvarNames : PList; stmt : PList);
var
   funcall : PList;
begin
   printFnName('genCall');
   funcall := List_rest(stmt);
   _genCall(fnArgNames, lvarNames, funcall);
end;

procedure genCallSet(fnArgNames : PList; lvarNames : PList; stmt : PList);
var
   varName : string;
   funcall : PList;
   disp    : integer;
begin
   varName := List_get(stmt, 2)^.strVal;
   funcall := List_get(stmt, 3)^.list;

   _genCall(fnArgNames, lvarNames, funcall);

   if Names_includes(lvarNames, varName) then
      begin
         disp := lvarDisp(lvarNames, varName);
         writeln('  cp reg_a [bp:', disp, ']');
      end
   else
      begin
         writeln(stderr, 'genCallSet: variable not found (', varName, ')');
         halt(1);
      end;
end;

procedure _genSet(fnArgNames : PList; lvarNames : PList; varName : string; expr : PNode);
var
   disp : integer;
begin
   genExpr(fnArgNames, lvarNames, expr);

   if Names_includes(lvarNames, varName) then
      begin
         disp := lvarDisp(lvarNames, varName);
         writeln('  cp reg_a [bp:', disp, ']');
      end
   else
      begin
         Json_print(lvarNames, true);
         writeln(stderr, '_genSet: variable not found (', varName, ')');
         halt(1);
      end;
end;

procedure genSet(fnArgNames : PList; lvarNames : PList; stmt : PList);
begin
   printFnName('genSet');
   _genSet(
           fnArgNames,
           lvarNames,
           List_get(stmt, 2)^.strVal,
           List_get(stmt, 3)
           );
end;

procedure genReturn(fnArgNames : PList; lvarNames : PList; stmt : PList);
begin
   genExpr(fnArgNames, lvarNames, List_get(stmt, 2));
end;

procedure genWhile(fnArgNames : PList; lvarNames : PList; stmt : PList);
var
   labelId    : integer;
   condExpr   : PNode;
   body       : PList;
   labelBegin : string;
   labelEnd   : string;
   labelTrue  : string;
begin
   printFnName('genWhile');

   condExpr := List_get(stmt, 2);
   body := List_get(stmt, 3)^.list;

   labelId := getNextLabelId;

   labelBegin := 'while_' + IntToStr(labelId);
   labelEnd := 'end_while_' + IntToStr(labelId);
   labelTrue := 'true_' + IntToStr(labelId);

   writeln('label ', labelBegin);

   genExpr(fnArgNames, lvarNames, condExpr);

   writeln('  cp 1 reg_b');
   writeln('  compare');
   writeln('  jump_eq ', labelTrue);
   writeln('  jump ', labelEnd);

   writeln('label ', labelTrue);

   genStmts(fnArgNames, lvarNames, body);

   writeln('  jump ', labelBegin);

   writeln('label ', labelEnd);
end;

procedure genCase(fnArgNames : PList; lvarNames : PList; stmt : PList);
var
   labelId          : integer;
   whenIdx          : integer = -1;
   labelEnd         : string;
   labelWhenHead    : string;
   labelEndWhenHead : string;
   i                : integer = 2;
   whenClause       : PList;
begin
   printFnName('genCase');
   labelId := getNextLabelId;

   labelEnd := 'end_case_' + IntToStr(labelId);
   labelWhenHead := 'when_' + IntToStr(labelId);
   labelEndWhenHead := 'end_when_' + IntToStr(labelId);

   while i <= List_size(stmt) do
   begin
      whenIdx := whenIdx + 1;
      whenClause := List_get(stmt, i)^.list;

      genExpr(fnArgNames, lvarNames, List_get(whenClause, 1));

      writeln('  cp 1 reg_b');
      writeln('  compare');
      writeln('  jump_eq ', labelWhenHead, '_', whenIdx);
      writeln('  jump ', labelEndWhenHead, '_', whenIdx);
      writeln('label ', labelWhenHead, '_', whenIdx);

      genStmts(fnArgNames, lvarNames, List_rest(whenClause));

      writeln('  jump ', labelEnd);
      writeln('label ', labelEndWhenHead, '_', whenIdx);

      i := i + 1;
   end;

   writeln('label ', labelEnd);

end;

procedure genVmComment(comment : String);
begin
   write('  _cmt ');
   write(replace(comment, ' ', '~'));
   writeln;
end;

procedure genStmt(fnArgNames : PList; lvarNames : PList; stmt : PList);
var
   headStr : string;
begin
   printFnName('genStmt');
   headStr := List_get(stmt, 1)^.strVal;

   if      headStr = 'set'      then genSet(    fnArgNames, lvarNames, stmt)
   else if headStr = 'call'     then genCall(   fnArgNames, lvarNames, stmt)
   else if headStr = 'call_set' then genCallSet(fnArgNames, lvarNames, stmt)
   else if headStr = 'return'   then genReturn( fnArgNames, lvarNames, stmt)
   else if headStr = 'while'    then genWhile(  fnArgNames, lvarNames, stmt)
   else if headStr = 'case'     then genCase(   fnArgNames, lvarNames, stmt)
   else if headStr = '_cmt'     then genVmComment(List_get(stmt, 2)^.strVal)
   else
      begin
         writeln(stderr, 'genStmt: unexpected statement');
         halt(1);
      end;
end;

procedure genStmts(fnArgNames : PList; lvarNames : PList; stmts : PList);
var
   i : integer = 1;
begin
   while i <= List_size(stmts) do
   begin
      genStmt(fnArgNames, lvarNames, List_get(stmts, i)^.list);
      i := i + 1;
   end;
end;

procedure genVar(fnArgNames : PList; lvarNames : PList; stmt : PList);
begin
   writeln('  sub_sp 1');

   if List_size(stmt) = 3 then
      _genSet(
              fnArgNames,
              lvarNames,
              List_get(stmt, 2)^.strVal,
              List_get(stmt, 3)
              );
end;

procedure genFuncDef(func : PList);
var
   fnName     : string;
   fnArgNames : PList;
   lvarNames  : PList;
   body       : PList;
   i          : integer = 1;
   stmt       : PList;
begin
   printFnName('genFuncDef');

   fnName     := List_get(func, 2)^.strVal;
   fnArgNames := List_get(func, 3)^.list;
   body       := List_get(func, 4)^.list;

   writeln('label ', fnName);
   asmPrologue;

   List_init(lvarNames);

   while i <= List_size(body) do
   begin
      stmt := List_get(body, i)^.list;
      if List_get(stmt, 1)^.strVal = 'var' then
         begin
            List_add(lvarNames, List_get(stmt, 2));
            genVar(fnArgNames, lvarNames, stmt)
         end
      else
         begin
            genStmt(fnArgNames, lvarNames, stmt);
         end;
      i := i + 1;
   end;

   asmEpilogue;
   writeln('  ret');
end;

procedure genTopStmt(topStmt : PList);
begin
   printFnName('genTopStmt');

   if List_get(topStmt, 1)^.strVal = 'func' then
      genFuncDef(topStmt)
   else
      begin
         writeln(stderr, 'unsupported');
         halt(1);
      end;
end;

procedure genTopStmts(topStmts : PList);
var
   i       : integer = 2;
   topStmt : PList;
begin
   printFnName('genTopStmts');

   while i <= List_size(topStmts) do
   begin
      topStmt := List_get(topStmts, i)^.list;
      genTopStmt(topStmt);
      i := i + 1;
   end;
end;

procedure genBuiltinSetVram();
begin
   writeln;
   writeln('label set_vram');
   asmPrologue;
   writeln('  set_vram [bp:2] [bp:3]'); // vram_addr value
   asmEpilogue;
   writeln('  ret');
end;

procedure genBuiltinGetVram();
begin
   writeln;
   writeln('label get_vram');
   asmPrologue;
   writeln('  set_vram [bp:2] reg_a'); // vram_addr dest
   asmEpilogue;
   writeln('  ret');
end;

procedure codegen(ast : PList);
begin
   writeln('  call main');
   writeln('  exit');

   genTopStmts(ast);

   writeln('#>builtins');
   genBuiltinSetVram;
   genBuiltinGetVram;
   writeln('#<builtins');
end;

var
   ast : PList;
begin
   ast := Json_parse(readStdinAll);
   codegen(ast);
end.
