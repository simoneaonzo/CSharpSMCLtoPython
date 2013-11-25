﻿%namespace CSharpSMCLtoPython.ASTbuilder

%union {
	internal int intValue;
	internal string identifier;
	internal List<Client> clients;
	internal Client client;
	internal List<Tunnel> tunnels;
	internal Tunnel tunnel;
	internal Server server;
	internal List<Group> groups;
	internal Group group;
	internal Typed typed;
	internal SmclType type;
	internal List<Function> functions;
	internal Function function;
	internal List<Typed> paramts;
	internal List<Stmt> stmts;
	internal Stmt stmt;
	internal Exp exp;
	internal List<Exp> args;
	internal List<Id> ids;
}

%token <intValue> NUM
%token <identifier> ID IDDOT SSTRING
%token AND BOOL CLIENT DECLARE DISPLAY ELSE EQUAL FALSE FOR FUNCTION GEQ GET GREATER_THAN GROUPOF ID IDDOT IF IN INT LESS_THAN LEQ NAME NEWLINE NOT OPEN OR PUT READINT RETURN SCLIENT SERVER SBOOL SINT TAKE TRUE TUNNELOF VOID WHILE

%left OR
%left AND
%left EQUAL 
%left LESS_THAN LEQ GEQ GREATER_THAN
%left '+' '-'
%left '*' '/' '%'

%type <args> args
%type <args> nargs
%type <clients> clients
%type <client> client
%type <exp> exp
%type <functions> functions
%type <function> function
%type <group> group
%type <groups> groups
%type <ids> ids
%type <paramts> paramts
%type <paramts> nparamts
%type <server> server
%type <stmts> stmts
%type <stmt> stmt
%type <tunnel> tunnel
%type <tunnels> tunnels
%type <typed> typed
%type <type> type
%type <void> prog

%{
	internal Prog Prog;
%}
%%

prog: clients server { this.Prog = new Prog($1, $2); }
	;

clients: { $$ = new List<Client>(); }
	| clients client { $1.Add($2); $$=$1; }
	;
	
client: DECLARE CLIENT ID ':' tunnels functions { $$ = new Client($3, $5, $6); }
	;

server: DECLARE SERVER ID ':' groups functions { $$ = new Server($3, $5, $6); }
	;

groups: { $$ = new List<Group>(); }
	| groups group { $1.Add($2); $$ = $1; }
	;

group: GROUPOF ID ID ';' { $$ = new Group($2, new Id($3)); }
	;

tunnels: { $$ = new List<Tunnel>(); }
	| tunnels tunnel { $1.Add($2); $$ = $1; }
	;

tunnel: TUNNELOF typed ';' { $$ = new Tunnel($2); }
	;

typed: type ID { $$ = new Typed($1, new Id($2)); }
	;

type: INT	 { $$ = new IntType(); }
	| SINT	 { $$ = new SintType(); }
	| BOOL	 { $$ = new BoolType(); }
	| SBOOL  { $$ = new SboolType(); }
	| VOID   { $$ = new VoidType(); }
	| CLIENT { $$ = new ClientType(); }
	| SCLIENT { $$ = new SclientType(); }
	;


functions: { $$ = new List<Function>(); }
	| functions function { $1.Add($2); $$ = $1; }
	;

function: FUNCTION type ID '(' paramts ')' '{' stmts '}' { $$ = new Function($2, $3, $5, $8); }
	;

paramts: { $$ = new List<Typed>(); }
	| nparamts { $$ = $1; }
	;

nparamts: typed { $$ = new List<Typed>(); $$.Add($1); }
	| nparamts ',' typed { $1.Add($3); $$ = $1; }
	;

stmts: { $$ = new List<Stmt>(); }
	| stmts stmt { $1.Add($2); $$ = $1; }
	;

stmt: type ID '=' exp ';' { $$ = new Declaration(new Typed($1, new Id($2)), new Assignment( new Id($2), $4));}
	| ID '=' exp ';'  { $$ = new Assignment( new Id($1), $3);}
	| '{' stmts '}' { $$ = new Block($2); }
	| IF '(' exp ')' stmt { $$ = new If($3, $5 ?? new Block(new List<Stmt>())); }
	| ELSE stmt { $$ = new Else($2 ?? new Block(new List<Stmt>())); }
	| WHILE '(' exp ')' stmt {$$ = new While($3, $5 ?? new Block(new List<Stmt>()));}
	| FOR '(' typed IN ID ')' stmt {$$ = new For($3, new Id($5), $7 ?? new Block(new List<Stmt>()));}
	| typed ';' { $$ = new Declaration($1);}
	| DISPLAY'('exp')' ';' { $$ = new Display($3); }
	| exp ';' { $$ = new ExpStmt($1);}
	| RETURN exp  ';' { $$ = new Return($2); }
	| RETURN ';' { $$ = new Return(null); }
	;


exp: NUM  { $$ = new IntLiteral($1); }
	| exp AND exp { $$ = new And($1, $3); }
	| exp OR exp { $$ = new Or($1, $3); }
	| exp EQUAL exp { $$ = new Equal($1, $3); }
	| exp LESS_THAN exp { $$ = new LessThan($1, $3); }
	| exp GREATER_THAN exp { $$ = new GreaterThan($1, $3); }
	| TRUE { $$ = new BoolLiteral(true); }
	| FALSE { $$ = new BoolLiteral(false); }
	| exp '+' exp { $$ = new Sum($1, $3); }
	| exp '-' exp { $$ = new Subtraction($1, $3); }
	| exp '*' exp { $$ = new Product($1, $3); }
	| exp '/' exp { $$ = new Division($1, $3); }
	| exp '%' exp { $$ = new Module($1, $3); }
	| NOT exp { $$ = new Not($2); }
	| IDDOT PUT '('exp')' { $$ = new Put(new Id($1), $4); }
	| IDDOT GET '('exp')' { $$ = new Get(new Id($1), $4); }
	| IDDOT TAKE '('exp')' { $$ = new Take(new Id($1), $4); }
	| IDDOT ID '(' args ')' { $$ = new MethodInvocation(new Id($1), new FunctionCall($2, $4)); }
	| ID '(' args ')' { $$ = new FunctionCall($1, $3); }
	| ID { $$ = new Id($1); }
	| SSTRING { $$ = new SString($1); }
	| READINT { $$ = new ReadInt(); }
	| OPEN '(' exp '|' ids ')' { $$ = new Open($3, $5); }
	;

ids: ID { $$ = new List<Id>(); $$.Add(new Id($1)); }
	| ids ',' ID { $1.Add(new Id($3)); $$ = $1; }
	;

args: /* empty */ { $$ = new List<Exp>(); }
	| nargs { $$ = $1; }
	;

nargs: exp { $$ = new List<Exp>(); $$.Add($1); }
	| nargs ',' exp { $1.Add($3); $$ = $1; }
	;

%%
	public Parser(Scanner s) : base(s) {}
