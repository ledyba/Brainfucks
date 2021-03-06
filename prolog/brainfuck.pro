% メモリを自動で拡張する機能搭載。
/**
	ポインタをインクリメントする。ポインタをptrとすると、C言語の「ptr++;」に相当する。
**/
bf_func('>',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	length(Mem,MemLength),Ptr < MemLength - 1,
	NPtr is Ptr + 1,
	NProgram = Program,
	NMem = Mem,
	NStack = Stack,
	NPC is PC + 1.

bf_func('>',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	NPtr is Ptr + 1,
	NProgram = Program,
	append(Mem,[0],NMem),
	NStack = Stack,
	NPC is PC + 1.

/**
	ポインタをデクリメントする。C言語の「ptr--;」に相当。
**/

bf_func('<',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	Ptr > 0,
	NMem = Mem,
	NProgram = Program,
	NPtr is Ptr - 1,
	NStack = Stack,
	NPC is PC + 1.

bf_func('<',Program,Mem,_,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	NMem = [0|Mem],
	NProgram = Program,
	NPtr is 0,
	NStack = Stack,
	NPC is PC + 1.

/**
	リスト操作用関数
**/
insert_at(0, X, Ls, [X | Ls]).
insert_at(N, X, [Y | Ls], [Y | Zs]) :-
	N > 0, N1 is N - 1, insert_at(N1, X, Ls, Zs).
remove_at(0, [_ | Ls], Ls).
remove_at(N, [X | Ls], [X | Zs]) :-
	N > 0, N1 is N - 1, remove_at(N1, Ls, Zs).
replace_at(N,X,List,NewList) :- 
	remove_at(N,List,AList),
	insert_at(N,X,AList,NewList).


/**
	ポインタが指す値をインクリメントする。C言語の「(*ptr)++;」に相当。
**/
bf_func('+',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Num),
	NewNum is (Num+257) mod 256,
	replace_at(Ptr,NewNum,Mem,NMem),
	NProgram = Program,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.

/**
	ポインタが指す値をデクリメントする。C言語の「(*ptr)--;」に相当。
**/
bf_func('-',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Num),
	NewNum is (Num+255) mod 256,
	replace_at(Ptr,NewNum,Mem,NMem),
	NProgram = Program,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.

% ポインタが指す値を出力する。C言語の「putchar(*ptr);」に相当。
bf_func('.',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Num),
	put(Num),
	NProgram = Program,
	NMem = Mem,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.

% 1バイトを入力してポインタが指す値に代入する。C言語の「*ptr=getchar();」に相当。
bf_func(',',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	get_byte(NewNum),
	replace_at(Ptr,NewNum,Mem,NMem),
	NProgram = Program,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.

% ポインタが指す値が0なら、対応する ] の直後までジャンプする。C言語の「while(*ptr){」に相当
bf_func('[',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Val),
	Val \== 0,
	NProgram = Program,
	NMem = Mem,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.
loop_search_next(Program,PC,Depth,NProgram,NPC,NDepth) :-
	Depth < 0,
	NProgram = Program,
	NPC = PC,
	NDepth = Depth.
loop_search_next_cnt(Str,Depth,NDepth) :- 
	Str == ']',
	NDepth is Depth -1.
loop_search_next_cnt(Str,Depth,NDepth) :- 
	Str == '[',
	NDepth is Depth +1.
loop_search_next_cnt(_,Depth,NDepth) :- 
	NDepth is Depth.
loop_search_next(Program,PC,Depth,NProgram,NPC,NDepth) :-
	nth0(PC,Program,Str),
	loop_search_next_cnt(Str,Depth,NNDepth),
	NNProgram = Program,
	NNPC is PC + 1,
	loop_search_next(NNProgram,NNPC,NNDepth,NProgram,NPC,NDepth).

bf_func('[',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Val),
	Val == 0,
	NNProgram = Program,
	NMem = Mem,
	NPtr = Ptr,
	NStack = Stack,
	NNPC is PC + 1,
	loop_search_next(NNProgram,NNPC,0,NProgram,NPC,_).

% ポインタが指す値が0でないなら、対応する [ にジャンプする。C言語の「}」に相当。
bf_func(']',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Val),
	Val == 0,
	NProgram = Program,
	NMem = Mem,
	NPtr = Ptr,
	NStack = Stack,
	NPC is PC + 1.

loop_search_before(Program,PC,Depth,NProgram,NPC,NDepth) :-
	Depth < 0,
	NProgram = Program,
	NPC is PC + 2,
	NDepth = Depth.
loop_search_before_cnt(Str,Depth,NDepth) :- 
	Str == '[',
	NDepth is Depth - 1.
loop_search_before_cnt(Str,Depth,NDepth) :- 
	Str == ']',
	NDepth is Depth + 1.
loop_search_before_cnt(_,Depth,NDepth) :- 
	NDepth is Depth.
loop_search_before(Program,PC,Depth,NProgram,NPC,NDepth) :-
	nth0(PC,Program,Str),
	loop_search_before_cnt(Str,Depth,NNDepth),
	NNProgram = Program,
	NNPC is PC - 1,
	loop_search_before(NNProgram,NNPC,NNDepth,NProgram,NPC,NDepth).

bf_func(']',Program,Mem,Ptr,Stack,PC,NProgram,NMem,NPtr,NStack,NPC) :-
	nth0(Ptr,Mem,Val),
	Val \== 0,
	NNProgram = Program,
	NMem = Mem,
	NPtr = Ptr,
	NStack = Stack,
	NNPC is PC - 1,
	loop_search_before(NNProgram,NNPC,0,NProgram,NPC,_).

/*
	これはスタック消費量がハンパないのでは？？
	でも末尾再帰効いてるから大丈夫？
 */
bf_repeat(Program,Mem,Ptr,Stack,PC,NMem) :-
	% 終了判定
	length(Program,StrListLen),(PC >= StrListLen),
	NMem = Mem.
bf_repeat(Program,Mem,Ptr,Stack,PC,NMem) :-
	nth0(PC,Program,Str),	% PCの文字を取得
%	print(PC),
%	print(Str),
%	print('\n'),
	%実行
	bf_func(Str,Program,Mem,Ptr,Stack,PC,NProgram,NNMem,NPtr,NStack,NPC),
	bf_repeat(NProgram,NNMem,NPtr,NStack,NPC,NMem). %末尾再帰。

brainfuckLst(Str,Mem) :- bf_repeat(Str,[0],0,[0],0,Mem).
brainfuck(Str,Mem) :- atom_chars(Str,StrList),bf_repeat(StrList,[0],0,[0],0,Mem).
testh(Mem) :- brainfuck('+++++++++[>++++++++>+++++++++++>+++++<<<-]>.>++.+++++++..+++.>-.------------.<++++++++.--------.+++.------.--------.>+.',Mem).
