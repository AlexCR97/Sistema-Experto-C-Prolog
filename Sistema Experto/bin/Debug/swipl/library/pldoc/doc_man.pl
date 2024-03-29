/*  Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2013, University of Amsterdam
			      VU University Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(pldoc_man,
	  [ clean_man_index/0,		%
	    index_man_directory/2,	% +DirSpec, +Options
	    index_man_file/2,		% +Class, +FileSpec
					% HTML generation
	    man_page//2,		% +Obj, +Options
	    man_overview//1,		% +Options

	    man_content_tree/2,		% +Dir, -Tree
	    man_packages_tree/1		% -Tree
	  ]).
:- use_module(library(sgml)).
:- use_module(library(occurs)).
:- use_module(library(lists)).
:- use_module(library(uri)).
:- use_module(library(apply)).
:- use_module(library(option)).
:- use_module(library(filesex)).
:- use_module(library(xpath)).
:- use_module(doc_wiki).
:- use_module(doc_html).
:- use_module(doc_search).
:- use_module(doc_process).
:- use_module(library(http/html_write)).
:- use_module(library(http/html_head)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_path)).
:- include(hooks).

/** <module> Process SWI-Prolog HTML manuals

*/

:- predicate_options(index_man_directory/2, 2,
		     [ class(oneof([manual,packages,misc])),
		       pass_to(system:absolute_file_name/3, 3)
		     ]).
:- predicate_options(man_page//2, 2,
		     [ for(atom),
		       links(boolean),
		       footer(boolean),
		       no_manual(oneof([fail,error])),
		       search_in(oneof([all, app, man])),
		       search_match(oneof([name, summary])),
		       search_options(boolean)
		     ]).


:- dynamic
	man_index/5.		% Object, Summary, File, Class, Offset

%%	clean_man_index is det.
%
%	Clean already loaded manual index.

clean_man_index :-
	retractall(man_index(_,_,_,_,_)).


%%	manual_directory(-Class, -Dir)// is nondet.
%
%	True if Dir is a directory holding manual files. Class is an
%	identifier used by doc_object_summary/4.

manual_directory(manual,   swi('doc/Manual')).
manual_directory(packages, swi('doc/packages')).


		 /*******************************
		 *	    PARSE MANUAL	*
		 *******************************/

%%	index_manual is det.
%
%	Load the manual index if not already done.

index_manual :-
	man_index(_,_,_,_,_), !.
index_manual :-
	with_mutex(pldoc_man,
		   locked_index_manual).

locked_index_manual :-
	(   manual_directory(Class, Dir),
	    index_man_directory(Dir,
				[ class(Class),
				  file_errors(fail)
				]),
	    fail ; true
	).

check_dubplicate_ids :-
	findall(Id, man_index(section(_,_,Id,_),_,_,_,_), Ids),
	msort(Ids, Sorted),
	duplicate_ids(Sorted, Duplicates),
	(   Duplicates == []
	->  true
	;   print_message(warning, pldoc(duplicate_ids(Duplicates)))
	).

duplicate_ids([], []).
duplicate_ids([H,H|T0], [H|D]) :- !,
	take_prefix(H,T0,T),
	duplicate_ids(T, D).
duplicate_ids([_|T], D) :-
	duplicate_ids(T, D).

take_prefix(H, [H|T0], T) :- !,
	take_prefix(H, T0, T).
take_prefix(_, L, L).


%%	index_man_directory(Dir, +Options) is det
%
%	Index  the  HTML  directory   Dir.    Options are:
%
%		* class(Class)
%		Define category of the found objects.
%
%	Remaining Options are passed to absolute_file_name/3.

index_man_directory(Spec, Options) :-
	select_option(class(Class), Options, Options1, misc),
	absolute_file_name(Spec, Dir,
			   [ file_type(directory),
			     access(read)
			   | Options1
			   ]),
	atom_concat(Dir, '/*.html', Pattern),
	expand_file_name(Pattern, Files),
	maplist(index_man_file(Class), Files).


%%	index_man_file(+Class, +File)
%
%	Collect the documented objects from the SWI-Prolog manual file
%	File.

index_man_file(Class, File) :-
	absolute_file_name(File, Path,
			   [ access(read)
			   ]),
	open(Path, read, In, [type(binary)]),
	dtd(html, DTD),
        new_sgml_parser(Parser, [dtd(DTD)]),
        set_sgml_parser(Parser, file(File)),
        set_sgml_parser(Parser, dialect(sgml)),
	set_sgml_parser(Parser, shorttag(false)),
	nb_setval(pldoc_man_index, []),
	nb_setval(pldoc_index_class, Class),
	call_cleanup(sgml_parse(Parser,
				[ source(In),
				  call(begin, index_on_begin)
				]),
		     (	 free_sgml_parser(Parser),
			 close(In),
			 nb_delete(pldoc_man_index)
		     )).


%%	index_on_begin(+Element, +Attributes, +Parser) is semidet.
%
%	Called from sgml_parse/2 in  index_man_file/2.   Element  is the
%	name of the element, Attributes the  list of Name=Value pairs of
%	the open attributes. Parser is the parser objects.

index_on_begin(dt, Attributes, Parser) :-
	\+ nb_getval(pldoc_man_index, dd(_,_,_)), !,
	memberchk(class=pubdef, Attributes),
        get_sgml_parser(Parser, charpos(Offset)),
        get_sgml_parser(Parser, file(File)),
	sgml_parse(Parser,
		   [ document(DT),
		     parse(content)
		   ]),
	(   sub_term(element(a, AA, _), DT),
	    member(Attr, ['data-obj', id, name]),
	    memberchk(Attr=Id, AA),
	    name_to_object(Id, PI)
	->  true
	),
	nb_setval(pldoc_man_index, dd(PI, File, Offset)).
index_on_begin(dd, _, Parser) :- !,
	nb_getval(pldoc_man_index, dd(Object, File, Offset)),
	nb_setval(pldoc_man_index, []),
	sgml_parse(Parser,
		   [ document(DD),
		     parse(content)
		   ]),
	summary(DD, Summary),
	nb_getval(pldoc_index_class, Class),
        assert(man_index(Object, Summary, File, Class, Offset)).
index_on_begin(div, Attributes, Parser) :- !,
	memberchk(class=title, Attributes),
	get_sgml_parser(Parser, charpos(Offset)),
        get_sgml_parser(Parser, file(File)),
	sgml_parse(Parser,
		   [ document(DOM),
		     parse(content)
		   ]),
	dom_to_text(DOM, Title),
	nb_getval(pldoc_index_class, Class),
	swi_local_path(File, Local),
	assert(man_index(section(0, '0', Local, File),
			 Title, File, Class, Offset)).
index_on_begin(H, Attributes, Parser) :- % TBD: add class for document title.
	heading(H, Level),
	get_sgml_parser(Parser, charpos(Offset)),
        get_sgml_parser(Parser, file(File)),
	sgml_parse(Parser,
		   [ document(Doc),
		     parse(content)
		   ]),
	dom_section(Doc, Nr, Title),
	nb_getval(pldoc_index_class, Class),
	section_id(Attributes, Title, File, ID),
	assert(man_index(section(Level, Nr, ID, File),
			 Title, File, Class, Offset)).

section_id(Attributes, _Title, _, ID) :-
	memberchk(id=ID, Attributes), !.
section_id(_Attributes, Title, File, ID) :-
	atomic_list_concat(Words, ' ', Title),
	atomic_list_concat(Words, '_', ID0),
	atom_concat('sec:', ID0, ID),
	print_message(warning, pldoc(no_section_id(File, Title))).

%%	dom_section(+HeaderDOM, -NR, -Title) is semidet.
%
%	NR is the section number (e.g. 1.1, 1.23) and Title is the title
%	from a section header. The  first   clauses  processes the style
%	information from latex2html, emitting sections as:
%
%	==
%	<HN> <A name="sec:nr"><span class='sec-nr'>NR</span>|_|
%			      <span class='sec-title'>Title</span>
%	==

dom_section(DOM, Nr, Title) :-
	sub_term([ element(span, A1, [Nr]) | Rest ], DOM),
	append(_Sep, [element(span, A2, TitleDOM)], Rest),
	memberchk(class='sec-nr', A1),
	memberchk(class='sec-title', A2), !,
	dom_to_text(TitleDOM, Title).
dom_section(DOM, Nr, Title) :-
	dom_to_text(DOM, Title),
	section_number(Title, Nr, Title).

section_number(Title, Nr, PlainTitle) :-
	sub_atom(Title, 0, 1, _, Start),
	(   char_type(Start, digit)
	->  true
	;   char_type(Start, upper),
	    sub_atom(Title, 1, 1, _, '.')	% A., etc: Appendices
	),
	sub_atom(Title, B, _, A, ' '), !,
	sub_atom(Title, 0, B, _, Nr),
	sub_string(Title, _, A, 0, PlainTitle).

heading(h1, 1).
heading(h2, 2).
heading(h3, 3).
heading(h4, 4).


%%	summary(+DOM, -Summary:string) is det.
%
%	Summary is the first sentence of DOM.

summary(DOM, Summary) :-
	phrase(summary(DOM, _), SummaryCodes0),
	phrase(normalise_white_space(SummaryCodes), SummaryCodes0),
	string_codes(Summary, SummaryCodes).

summary([], _) --> !,
	[].
summary(_, Done) -->
	{ Done == true }, !,
	[].
summary([element(_,_,Content)|T], Done) --> !,
	summary(Content, Done),
	summary(T, Done).
summary([CDATA|T], Done) -->
	{ atom_codes(CDATA, Codes)
	},
	(   { Codes = [Period|Rest],
	      code_type(Period, period),
	      space(Rest)
	    }
	->  [ Period ],
	    { Done = true }
	;   { append(Sentence, [C, Period|Rest], Codes),
	      code_type(Period, period),
	      \+ code_type(C, period),
	      space(Rest)
	    }
	->  string(Sentence),
	    [C, Period],
	    { Done = true }
	;   string(Codes),
	    summary(T, Done)
	).

string([]) -->
	[].
string([H|T]) -->
	[H],
	string(T).

space([C|_]) :- code_type(C, space), !.
space([]).

%%	dom_to_text(+DOM, -Text)
%
%	Extract the text of a parsed HTML term.  White-space in the
%	result is normalised.  See normalise_white_space//1.

dom_to_text(Dom, Text) :-
	phrase(cdata_list(Dom), CDATA),
	with_output_to(codes(Codes0),
		       forall(member(T, CDATA),
			      write(T))),
	phrase(normalise_white_space(Codes), Codes0),
	string_codes(Text, Codes).

cdata_list([]) -->
	[].
cdata_list([H|T]) -->
	cdata(H),
	cdata_list(T).

cdata(element(_, _, Content)) --> !,
	cdata_list(Content).
cdata(CDATA) -->
	{ atom(CDATA) }, !,
	[CDATA].
cdata(_) -->
	[].


		 /*******************************
		 *	     HIERARCHY		*
		 *******************************/

%%	man_content_tree(+Dir, -Tree) is det.
%
%	Compute the content tree for a   multi-file HTML document. We do
%	this by processing =Contents.html= for  making the toplevel tree
%	that   links   to   the   individual    files.   Then   we   use
%	html_content_tree/2 to materialize the trees for the files.

man_content_tree(Spec, node(manual, Chapters)) :-
	absolute_file_name(Spec, Dir,
			   [ file_type(directory),
			     access(read)
			   ]),
	directory_file_path(Dir, 'Contents.html', ContentsFile),
	load_html_file(ContentsFile, DOM),
	findall(Level-Path,
		( xpath(DOM, //div(@class=Class), DIV),
		  class_level(Class, Level),
		  xpath(DIV, a(@class=sec,@href=File), _),
		  \+ sub_atom(File, _, _, _, #),
		  directory_file_path(Dir, File, Path)
		),
		Pairs),
	index_chapters(Pairs, Chapters).

class_level('toc-h1', 1).
class_level('toc-h2', 2).
class_level('toc-h3', 3).
class_level('toc-h4', 4).

index_chapters([], []).
index_chapters([Level-File|T0], [node(Chapter, Children)|T]) :-
	html_content_tree(File, Node),
	Node = node(Chapter, Children0),
	append(Children0, Sections, Children),
	index_sections(T0, Level, Sections, T1),
	index_chapters(T1, T).

index_sections([], _, [], []) :- !.
index_sections([SLevel-File|T0], Level, [Node|T], Rest) :-
	SLevel > Level, !,
	html_content_tree(File, Node),
	index_sections(T0, Level, T, Rest).
index_sections(Rest, _, [], Rest).


%%	man_packages_tree(-Tree) is det.
%
%	Tree is the content tree of all packages

man_packages_tree(node(packages, Packages)) :-
	index_manual,
	Section = section(0, _, _, _),
	findall(File,
		man_index(Section, _Title, File, packages, _),
		Files),
	maplist(package_node, Files, Packages).

package_node(File, Tree) :-
	html_content_tree(File, Tree).

%%	html_content_tree(+ManualFile, -Tree) is det.
%
%	True when Tree represents the  hierarchical structure of objects
%	documented in the HTML file ManualFile. Tree  is a term where of
%	the form below. Object is a   documentation  object (typically a
%	section  or  predicate  indicator)  that    may   be  handed  to
%	object_link//1  and  similar  predicates  to  make  a  table  of
%	contents.
%
%	    node(Object, ListOfTree).

html_content_tree(File, Tree) :-
	index_manual,
	findall(Offset-Obj,
		man_index(Obj, _Summary, File, _Class, Offset),
		Pairs),
	keysort(Pairs, Sorted),
	pairs_values(Sorted, Objects),
	make_tree(Objects, Trees),
	assertion(Trees = [_]),
	Trees = [Tree].

make_tree([], []).
make_tree([Obj|T0], [node(Obj, Children)|T]) :-
	children(T0, Obj, Children, T1),
	make_tree(T1, T).

children([], _, [], []) :- !.
children([Obj|T0], Root, [Node|T], Rest) :-
	section_level(Obj, ObjLevel),
	section_level(Root, Level),
	ObjLevel > Level, !,
	Node = node(Obj, Children),
	children(T0, Obj, Children, T1),
	children(T1, Root, T, Rest).
children([Obj|T0], Root, [Obj|T], Rest) :-
	\+ section_level(Obj, _), !,
	children(T0, Root, T, Rest).
children(Rest, _, [], Rest).

section_level(section(Level, _Nr, _Id, _File), Level).


		 /*******************************
		 *	      RETRIEVE		*
		 *******************************/

%%	load_man_object(+Obj, -Parent, -Path, -DOM) is nondet.
%
%	load the desription of the  object   matching  Obj from the HTML
%	sources and return the DT/DD pair in DOM.
%
%	@tbd	Nondet?

load_man_object(Obj, ParentSection, Path, DOM) :-
	resolve_section(Obj, For),
	For = section(_,SN,_ID,Path),
	parent_section(For, ParentSection),
	findall(Nr-Pos, section_start(Path, Nr, Pos), Pairs),
	(   (   Pairs = [SN-_|_]
	    ;	Pairs == []
	    )
	->  !,
	    load_html_file(Path, DOM)		% Load whole file
	;   append(_, [SN-Start|Rest], Pairs)
	->  !,
	    (	member(N-End, Rest),
		\+ sub_atom(N, 0, _, _, SN),
		Len is End - Start,
		Options = [content_length(Len)]
	    ->	true
	    ;	Options = []
	    ),
	    open(Path, read, In, [type(binary)]),
	    seek(In, Start, bof, _),
	    dtd(html, DTD),
	    new_sgml_parser(Parser,
			    [ dtd(DTD)
			    ]),
	    set_sgml_parser(Parser, file(Path)),
	    set_sgml_parser(Parser, dialect(sgml)),
	    set_sgml_parser(Parser, shorttag(false)),
	    set_sgml_parser(Parser, defaults(false)),
	    call_cleanup(sgml_parse(Parser,
				    [ document(DOM),
				      source(In),
				      syntax_errors(quiet)
				    | Options
				    ]),
			 ( free_sgml_parser(Parser),
			   close(In)
			 ))
	).
load_man_object(For, Parent, Path, DOM) :-
	index_manual,
	object_spec(For, Obj),
	man_index(Obj, _, Path, _, Position),
	(   object_section(Path, Position, Parent)
	->  true
	;   Parent = Path
	),
	open(Path, read, In, [type(binary)]),
	seek(In, Position, bof, _),
	dtd(html, DTD),
	new_sgml_parser(Parser,
			[ dtd(DTD)
			]),
	set_sgml_parser(Parser, file(Path)),
        set_sgml_parser(Parser, dialect(sgml)),
	set_sgml_parser(Parser, shorttag(false)),
	set_sgml_parser(Parser, defaults(false)),
	call_cleanup(parse_dts_upto_dd(Parser, In, DOM),
		     ( free_sgml_parser(Parser),
		       close(In)
		     )).

parse_dts_upto_dd(Parser, In, [DOM|More]) :-
	sgml_parse(Parser,
		   [ document(DOM),
		     source(In),
		     parse(element)
		   ]),
	(   DOM = [element(dt, _, _)]
	->  parse_dts_upto_dd(Parser, In, More)
	;   More = []
	).

section_start(Path, Nr, Pos) :-
	index_manual,
	man_index(section(_,Nr,_,_), _, Path, _, Pos).

%%	resolve_section(+SecIn, -SecOut) is det.
%
%	Resolve symbolic path reference and fill   in  level and section
%	number if this information is missing.   The latter allows us to
%	refer to files of the manual.

resolve_section(section(Level, No, Spec), Section) :- !,
	resolve_section(section(Level, No, _, Spec), Section).
resolve_section(section(Level, No, ID, Path),
		section(Level, No, ID, Path)) :-
	nonvar(ID),
	index_manual,
	man_index(section(Level,No,ID,Path), _, _, _, _), !.
resolve_section(section(Level, No, ID, Spec),
		section(Level, No, ID, Path)) :-
	ground(Spec),
	absolute_file_name(Spec, Path,
			   [ access(read)
			   ]),
	(   index_manual,
	    man_index(section(Level, No, ID, Path), _, _, _, _)
	->  true
	;   path_allowed(Path)
	->  true
	;   permission_error(read, manual_file, Spec)
	).


path_allowed(Path) :-			% allow all files from swi/doc
	absolute_file_name(swi(doc), Parent,
			   [ access(read),
			     file_type(directory)
			   ]),
	sub_atom(Path, 0, _, _, Parent).


%%	parent_section(+Section, -Parent) is det.
%
%	Parent is the parent-section  of   Section.  First  computes the
%	section number and than finds the   required  number in the same
%	file or same directory.

parent_section(section(Level, Nr, _ID, File), Parent) :-
	integer(Level),
	Parent = section(PL, PNr, _PID, _PFile),
	PL is Level - 1,
	findall(B, sub_atom(Nr, B, _, _, '.'), BL),
	last(BL, Before),
	sub_atom(Nr, 0, Before, _, PNr),
	(   man_index(Parent, _, File, _, _)
	->  true
	;   man_index(Parent, _, ParentFile, _, _),
	    same_dir(File, ParentFile)
	->  true
	;   man_index(Parent, _, _, _, _)
	), !.
parent_section(section(_, _, _, File), File).

%%	object_section(+Path, +Position, -Section) is semidet.
%
%	Section is the section in which object appears.  This is the
%	last section object before position.

object_section(Path, Pos, Section) :-
	Section	= section(_,_,_,_),
	findall(Section,
	       (man_index(Section, _, Path, _, SecPos), SecPos =< Pos),
		List),
	last(List, Section).

same_dir(File1, File2) :-
	file_directory_name(File1, Dir),
	file_directory_name(File2, Dir).

%%	object_spec(+Atom, -SpecTerm)
%
%	Tranform the Name/Arity, etc strings as   received from the HTTP
%	into a term.  Must return unique results.

object_spec(Spec, Spec).
object_spec(Atom, Spec) :-
	catch(atom_to_term(Atom, Spec, _), _, fail), !,
	Atom \== Spec.
object_spec(Atom, PI) :-
	name_to_object(Atom, PI).


		 /*******************************
		 *	      EMIT		*
		 *******************************/

%%	man_page(+Obj, +Options)// is semidet.
%
%	Produce a Prolog manual page for  Obj.   The  page consists of a
%	link to the section-file and  a   search  field, followed by the
%	predicate description.  Obj is one of:
%
%	    * Name/Arity
%	    Predicate indicator: display documentation of the predicate
%
%	    * f(Name/Arity)
%	    display documentation of an arithmetic function
%
%	    * c(Function)
%	    display documentation of a C API function
%
%	    * section(Level, Number, Id, File)
%	    Display a section of the manual
%
%	    * sec(DocFile#Id)
%	    Display a section of the manual (from short form)
%
%	Options:
%
%		* no_manual(Action)
%		If Action = =fail=, fail instead of displaying a
%		not-found message.
%
%		* links(Bool)
%		If =true= (default), include links to the parent object;
%		if =false=, just emit the manual material.

man_page(Obj0, Options) -->			% sections
	{ full_page(Obj0, Obj),
          findall((Parent+Path)-(Obj+DOM),
		  load_man_object(Obj, Parent, Path, DOM),
		  Matches),
	  Matches = [_|_], !,
	  pairs_keys(Matches, ParentPaths),
	  Matches = [Parent+Path-_|_]
	},
	html_requires(pldoc),
	man_links(ParentPaths, Options),
	man_matches(Matches, Obj, Options).
man_page(Obj, Options) -->			% predicates, etc.
	{ full_object(Obj, Full),
	  findall(Full-File,
		  ( doc_comment(Full, File:_, _, _),
		    \+ private(Full, Options)
		  ),
		  Pairs),
	  Pairs \== [],
	  pairs_keys(Pairs, Objs)
	}, !,
	html_requires(pldoc),
	(   { Pairs = [_-File] }
	->  object_page_header(File, Options)
	;   object_page_header(-, Options)
	),
	objects(Objs, [synopsis(true)|Options]).
man_page(Obj, Options) -->			% failure
	{ \+ option(no_manual(fail), Options)
	},
	html_requires(pldoc),
	man_links([], Options),
	html(p(class(noman),
	       [ 'Sorry, No manual entry for ',
		 b('~w'-[Obj])
	       ])).

full_page(Obj, _) :-
	var(Obj), !, fail.
full_page(Obj, Obj) :-
	Obj = section(_,_,_,_), !.
full_page(section(ID), section(_,_,ID,_)) :- !.
full_page(Obj, Obj) :-
	ground(Obj).


full_object(M:N/A, M:N/A) :- !.
full_object(M:N//A, M:N/A2) :-
	integer(A2), !,
	A2 is A+2.
full_object(Name/Arity, _:Name/Arity) :- !.
full_object(Name//Arity, _:Name/Arity2) :-
	integer(Arity),
	Arity2 is Arity+1.


%%	man_synopsis(+Text, Parent)
%
%	Give synopsis details for a fully specified predicate indicator.
%	The tricky part is that there   are cases where multiple modules
%	export the same predicate. We must find   from  the title of the
%	manual section which library is documented.

:- public
	man_synopsis//2.		% called from man_match//2

man_synopsis(Text, Parent) -->
	{ atom_pi(Text, PI) },
	man_synopsis_2(PI, Parent).
man_synopsis(Object, Parent) -->
	man_synopsis_2(Object, Parent).

man_synopsis_2(Name/Arity, Parent) -->
	{ object_module(Parent, Module),
	  object_href(Parent, HREF)
	},
	object_synopsis(Module:Name/Arity, [href(HREF)]).
man_synopsis_2(Object, _) -->
	object_synopsis(Object, []).

%%	object_module(+Section, -Module) is semidet.
%
%	Find the module documented by Section.
%
%	@tbd This requires that the documented file is loaded. If
%	not, should we use the title of the section?

object_module(Section, Module) :-
	man_index(Section, Title, _File, _Class, _Offset),
	(   once(sub_atom(Title, B, _, _, :)),
	    sub_atom(Title, 0, B, _, Atom),
	    catch(term_to_atom(Term, Atom), _, fail),
	    Term = library(_)
	->  absolute_file_name(Term, PlFile,
			       [ file_type(prolog),
				 access(read),
				 file_errors(fail)
			       ]),
	    module_property(Module, file(PlFile))
	).

atom_pi(Text, Name/Arity) :-
	atom(Text),
	sub_atom(Text, Pre, _, Post, /),
	sub_atom(Text, _, Post, 0, AA),
	atom_number(AA, Arity),
	integer(Arity),
	Arity >= 0, !,
	sub_atom(Text, 0, Pre, _, Name).

man_matches([Match], Object, Options) -->
	{ option(footer(true), Options, true) }, !,
	man_match(Match, Object),
	object_page_footer(Object, []).
man_matches(Matches, Object, _) -->
	man_matches_list(Matches, Object).

man_matches_list([], _) --> [].
man_matches_list([H|T], Obj) --> man_match(H, Obj), man_matches_list(T, Obj).

%%	man_match(+Term, +Object)//
%
%	If  possible,  insert  the  synopsis  into   the  title  of  the
%	description.

man_match((Parent+Path)-(Obj+[element(dt,A,C),DD]), Obj) -->
	dom_list([ element(dt,[],[\man_synopsis(Obj, Parent)]),
		   element(dt,A,C),
		   DD
		 ], Path).
man_match((_Parent+Path)-(Obj+DOM), Obj) -->
	dom_list(DOM, Path).

:- html_meta
	dom_list(html, +, ?, ?).

dom_list(_:[], _) --> !,
	[].
dom_list(M:[H|T], Path) -->
	dom(H, Path),
	dom_list(M:T, Path).

dom(element(E, Atts, Content), Path) --> !,
	dom_element(E, Atts, Content, Path).
dom(CDATA, _) -->
	html(CDATA).

dom_element(a, _, [], _) --> !,			% Useless back-references
	[].
dom_element(a, Att, Content, Path) -->
	{ memberchk(href=HREF, Att),
	  (   memberchk(class=Class, Att)
	  ->  true
	  ;   Class = unknown
	  ),
	  rewrite_ref(Class, HREF, Path, Myref)
	}, !,
	html(a(href(Myref), \dom_list(Content, Path))).
dom_element(span, Att, [CDATA], _) -->
	{ memberchk(class='pred-ext', Att),
	  atom_pi(CDATA, PI),
	  documented(PI),
	  http_link_to_id(pldoc_man, [predicate=CDATA], HREF)
	}, !,
	html(a(href(HREF), CDATA)).
dom_element(img, Att0, [], Path) -->
	{ selectchk(src=Src, Att0, Att1),
	  current_prolog_flag(home, SWI),
	  sub_atom(Path, 0, Len, _, SWI),
	  (   sub_atom(Path, Len, _, _, '/doc/Manual/')
	  ->  Handler = manual_file
	  ;   sub_atom(Path, Len, _, _, '/doc/packages/')
	  ->  Handler = pldoc_package
	  ), !,
	  http_link_to_id(Handler, [], ManRef),
	  atomic_list_concat([ManRef, /, Src], NewPath),
	  Begin =.. [img, src(NewPath) | Att1]
	}, !,
	html_begin(Begin),
	html_end(img).
dom_element(div, Att, _, _) -->
	{ memberchk(class=navigate, Att) }, !.
dom_element(html, _, Content, Path) --> !,	% do not emit a html for the second time
	dom_list(Content, Path).
dom_element(head, _, Content, Path) --> !,	% do not emit a head for the second time
	dom_list(Content, Path).
dom_element(title, _, _, _) --> !.
dom_element(link, _, _, _) --> !.
dom_element(body, _, Content, Path) --> !,	% do not emit a body for the second time
	dom_list(Content, Path).
dom_element(Name, Attrs, Content, Path) -->
	{ Begin =.. [Name|Attrs] },
	html_begin(Begin),
	dom_list(Content, Path),
	html_end(Name).

%%	documented(+PI) is semidet.
%
%	True if we have documentation about PI

documented(PI) :-
	index_manual,
	man_index(PI, _, _, _, _), !.
documented(PI) :-
	full_object(PI, Obj),
	doc_comment(Obj, _, _, _), !.


%%	rewrite_ref(+Class, +Ref0, +Path, -ManRef) is semidet.
%
%	Rewrite Ref0 from the HTML reference manual format to the server
%	format. Reformatted:
%
%	    $ File#Name/Arity :
%	    Local reference using the manual presentation
%	    =|/man?predicate=PI|=.
%
%	    $ File#sec:NR :
%	    Rewrite to =|section(Level, NT, ID, FilePath)|=
%
%	    $ File#flag:Name :
%	    Rewrite to =|section(Level, NT, ID, FilePath)#flag:Name|=
%
%	    $ File#Name()
%	    Rewrite to /man/CAPI=Name
%
%	@param Class	Class of the <A>.  Supported classes are
%
%		| sec  | Link to a section     |
%		| pred | Link to a predicate   |
%		| flag | link to a Prolog flag |
%
%	@param Ref0	Initial reference from the =a= element
%	@param Path	Currently loaded file
%	@param ManRef	PlDoc server reference

rewrite_ref(pred, Ref0, _, Ref) :-		% Predicate reference
	sub_atom(Ref0, _, _, A, '#'), !,
	sub_atom(Ref0, _, A, 0, Fragment),
	name_to_object(Fragment, PI),
	man_index(PI, _, _, _, _),
	uri_encoded(query_value, Fragment, Enc),
	http_location_by_id(pldoc_man, ManHandler),
	format(string(Ref), '~w?predicate=~w', [ManHandler, Enc]).
rewrite_ref(function, Ref0, _, Ref) :-		% Arithmetic function reference
	sub_atom(Ref0, _, _, A, '#'), !,
	sub_atom(Ref0, _, A, 0, Fragment),
	name_to_object(Fragment, PI),
	man_index(PI, _, _, _, _),
	PI=f(Name/Arity),
	format(atom(PIName), '~w/~w', [Name,Arity]),
	uri_encoded(query_value, PIName, Enc),
	http_location_by_id(pldoc_man, ManHandler),
	format(string(Ref), '~w?function=~w', [ManHandler, Enc]).
rewrite_ref(func, Ref0, _, Ref) :-		% C-API reference
	sub_atom(Ref0, _, _, A, '#'), !,
	sub_atom(Ref0, _, A, 0, Fragment),
	name_to_object(Fragment, Obj),
	man_index(Obj, _, _, _, _),
	Obj = c(Function),
	uri_encoded(query_value, Function, Enc),
	http_location_by_id(pldoc_man, ManHandler),
	format(string(Ref), '~w?CAPI=~w', [ManHandler, Enc]).
rewrite_ref(sec, Ref0, Path, Ref) :-		% Section inside a file
	sub_atom(Ref0, B, _, A, '#'), !,
	sub_atom(Ref0, _, A, 0, Fragment),
	sub_atom(Ref0, 0, B, _, File),
	referenced_section(Fragment, File, Path, Section),
	object_href(Section, Ref).
rewrite_ref(sec, File, Path, Ref) :-		% Section is a file
	file_directory_name(Path, Dir),
	atomic_list_concat([Dir, /, File], SecPath),
	Obj = section(_, _, _, SecPath),
	man_index(Obj, _, _, _, _), !,
	object_href(Obj, Ref).
rewrite_ref(cite, Ref0, Path, Ref) :-		% Citation (bit hard-wired)
	debug(pldoc(cite), 'Cite ref ~q ~q', [Ref0, Path]),
	sub_atom(Ref0, _, _, A, '#'), !,
	sub_atom(Ref0, _, A, 0, Fragment),
	uri_encoded(query_value, Fragment, Enc),
	http_location_by_id(pldoc_man, ManHandler),
	format(string(Ref), '~w?section=Bibliography#~w', [ManHandler, Enc]).
rewrite_ref(flag, Ref0, Path, Ref) :-
	sub_atom(Ref0, B, _, A, '#'), !,
	sub_atom(Ref0, 0, B, _, File),
	sub_atom(Ref0, _, A, 0, Fragment),
	file_directory_name(Path, Dir),
	atomic_list_concat([Dir, /, File], SecPath),
	Obj = section(_, _, _, SecPath),
	man_index(Obj, _, _, _, _), !,
	object_href(Obj, Ref1),
	format(string(Ref), '~w#~w', [Ref1, Fragment]).

%%	name_to_object(+Atom, -PredicateIndicator) is semidet.
%
%	If Atom is `Name/Arity', decompose to Name and Arity. No errors.

name_to_object(Atom, Object) :-
	atom_pi(Atom, Name/Arity),
	(   atom_concat('f-', FuncName, Name)
	->  Object = f(FuncName/Arity)
	;   Object = Name/Arity
	).
name_to_object(Atom, c(Function)) :-
	atom(Atom),
	sub_atom(Atom, 0, _, _, 'PL_'),
	sub_atom(Atom, B, _, _, '('), !,
	sub_atom(Atom, 0, B, _, Function).


%%	referenced_section(+Fragment, +File, +Path, -Section)

referenced_section(Fragment, File, Path, section(Level, Nr, ID, SecPath)) :-
	atom_concat('sec:', Nr, Fragment),
	(   File == ''
	->  SecPath = Path
	;   file_directory_name(Path, Dir),
	    atomic_list_concat([Dir, /, File], SecPath)
	),
	man_index(section(Level, Nr, ID, SecPath), _, _, _, _).


%%	man_links(+ParentPaths, +Options)// is det.
%
%	Create top link structure for manual pages.

man_links(ParentPaths, Options) -->
	{ option(links(true), Options, true) }, !,
	html([ div(class(navhdr),
		   [ div(class(jump), \man_parent(ParentPaths)),
		     div(class(search), \search_form(Options)),
		     br(clear(right))
		   ]),
	       p([])
	     ]).
man_links(_, _) -->
	[].

man_parent(ParentPaths) -->
	{ maplist(parent_to_section, ParentPaths, [Section|MoreSections]),
	  maplist(=(Section), MoreSections)
	}, !,
	object_ref(Section, [secref_style(number_title)]).
man_parent(_) --> [].

parent_to_section(X+_, X) :-
	X = section(_,_,_,_), !.
parent_to_section(File+_, Section) :-
	atom(File),
	man_index(Section, _Title, File, _Class, _Offset), !.

%%	section_link(+Obj, +Options)// is det.
%
%	Create link to a section.  Options recognised:
%
%		* secref_style(+Style)
%		One of =number=, =title= or =number_title=.

section_link(Section, Options) -->
	{ option(secref_style(Style), Options, number)
	},
	section_link(Style, Section, Options).

section_link(number, section(_, Number, _, _), _Options) --> !,
	(   {Number == '0'}		% Title.  Package?
	->  []
	;   html(['Sec. ', Number])
	).
section_link(title, Obj, _Options) --> !,
	{ man_index(Obj, Title, _File, _Class, _Offset)
	},
	html(Title).
section_link(_, Obj, _Options) --> !,
	{ Obj = section(_, Number, _, _),
	  man_index(Obj, Title, _File, _Class, _Offset)
	},
	(   { Number == '0' }
	->  html(Title)
	;   html([Number, ' ', Title])
	).

%%	function_link(+Function, +Options) is det.
%
%	Create a link to a C-function

function_link(Function, _) -->
	html([Function, '()']).


		 /*******************************
		 *	 INDICES & OVERVIEW	*
		 *******************************/

%%	man_overview(+Options)// is det.
%
%	Provide a toplevel overview on the  manual: the reference manual
%	and the available packages.

man_overview(Options) -->
	{ http_absolute_location(pldoc_man(.), RefMan, [])
	},
	html([ blockquote(class(refman_link),
			  a(href(RefMan),
			    'SWI-Prolog reference manual')),
	       h2(class(package_doc_title),
		  'SWI-Prolog package documentation'),
	       blockquote(class(package_overview),
			  \packages(Options))
	     ]).

packages(Options) -->
	{ findall(Pkg, current_package(Pkg), Pkgs)
	},
	packages(Pkgs, Options).

packages([], _) -->
	[].
packages([Pkg|T], Options) -->
	package(Pkg, Options),
	packages(T, Options).

package(pkg(Title, HREF, HavePackage), Options) -->
	{ package_class(HavePackage, Class, Options)
	},
	html(div(class(Class),
		 a([href(HREF)], Title))).

package_class(true,  pkg_link, _).
package_class(false, no_pkg_link, _).

current_package(pkg(Title, HREF, HavePackage)) :-
	man_index(section(0, _, _, _), Title, File, packages, _),
	file_base_name(File, FileNoDir),
	file_name_extension(Base, _, FileNoDir),
	(   exists_source(library(Base))
	->  HavePackage = true
	;   HavePackage = false
	),
	http_absolute_location(pldoc_pkg(FileNoDir), HREF, []).


:- http_handler(pldoc_pkg(.), pldoc_package, [prefix]).
:- http_handler(pldoc_man(.), pldoc_refman, [prefix]).

%%	pldoc_package(+Request)
%
%	HTTP handler for PlDoc package documentation.  Accepts
%	/pldoc/package/<package>.{html,gif}.

pldoc_package(Request) :-
	memberchk(path_info(Img), Request),
	file_name_extension(_, gif, Img), !,
	atom_concat('doc/packages/', Img, Path),
	http_reply_file(swi(Path), [], Request).
pldoc_package(Request) :-
	(   memberchk(path_info(PkgDoc), Request),
	    \+ sub_atom(PkgDoc, _, _, _, /),
	    Obj = section(0,_,_,_),
	    index_manual,
	    man_index(Obj, Title, File, packages, _),
	    file_base_name(File, PkgDoc)
	->  reply_html_page(pldoc(package),
			    title(Title),
			    \object_page(Obj, []))
	;   memberchk(path(Path), Request),
	    existence_error(http_location, Path)
	).

%%	pldoc_refman(+Request)
%
%	HTTP handler for PlDoc Reference Manual access.  Accepts
%	/refman/[<package>.html.]

pldoc_refman(Request) :-
	memberchk(path_info(Section), Request),
	\+ sub_atom(Section, _, _, _, /),
	Obj = section(0,_,_,_),
	index_manual,
	man_index(Obj, Title, File, manual, _),
	file_base_name(File, Section), !,
	reply_html_page(pldoc(man),
			title(Title),
			\object_page(Obj, [])).
pldoc_refman(Request) :-		% server Contents.html
	\+ memberchk(path_info(_), Request), !,
	Section = section(_, _, _, swi('doc/Manual/Contents.html')),
	reply_html_page(pldoc(refman),
			title('SWI-Prolog manual'),
			\man_page(Section, [])).
pldoc_refman(Request) :-
	memberchk(path(Path), Request),
	existence_error(http_location, Path).


		 /*******************************
		 *	    HOOK SEARCH		*
		 *******************************/

prolog:doc_object_summary(Obj, Class, File, Summary) :-
	index_manual,
	man_index(Obj, Summary, File, Class, _Offset).

prolog:doc_object_page(Obj, Options) -->
	man_page(Obj, [no_manual(fail),footer(false)|Options]).

prolog:doc_object_link(Obj, Options) -->
	{ Obj = section(_,_,_,_) }, !,
	section_link(Obj, Options).
prolog:doc_object_link(Obj0, Options) -->
	{ Obj0 = section(ID),
	  Obj = section(_Level, _No, ID, _Path),
	  man_index(Obj, _, _, _, _)
	}, !,
	section_link(Obj, Options).
prolog:doc_object_link(Obj, Options) -->
	{ Obj = c(Function) }, !,
	function_link(Function, Options).

prolog:doc_category(manual,   30, 'SWI-Prolog Reference Manual').
prolog:doc_category(packages, 40, 'Package documentation').

prolog:doc_file_index_header(File, Options) -->
	{ Section = section(_Level, _No, _ID, File),
	  man_index(Section, _Summary, File, _Cat, _Offset)
	}, !,
	html(tr(th([colspan(3), class(section)],
		   [ \object_ref(Section,
				 [ secref_style(number_title)
				 | Options
				 ])
		   ]))).

prolog:doc_object_title(Obj, Title) :-
	Obj = section(_,_,_,_),
	man_index(Obj, Title, _, _, _), !.

prolog:doc_canonical_object(section(_Level, _No, ID, _Path),
			    section(ID)).

swi_local_path(Path, Local) :-
	atom(Path),
	is_absolute_file_name(Path),
	absolute_file_name(swi(doc), SWI,
			   [ file_type(directory),
			     solutions(all)
			   ]),
	directory_file_path(SWI, Local, Path), !.

%%	prolog:doc_object_href(+Object, -HREF) is semidet.
%
%	Produce a HREF for section objects.

prolog:doc_object_href(section(_Level, _No, ID, _Path), HREF) :-
	atom_concat('sec:', Sec, ID),
	http_link_to_id(pldoc_man, [section(Sec)], HREF).


		 /*******************************
		 *	     MESSAGES		*
		 *******************************/

:- multifile prolog:message//1.

prolog:message(pldoc(no_section_id(File, Title))) -->
	[ 'PlDoc: ~w: no id for section "~w"'-[File, Title] ].
prolog:message(pldoc(duplicate_ids(L))) -->
	[ 'PlDoc: duplicate manual section IDs:'-[], nl
	],
	duplicate_ids(L).

duplicate_ids([]) --> [].
duplicate_ids([H|T]) --> duplicate_id(H), duplicate_ids(T).

duplicate_id(Id) -->
	{ findall(File, man_index(section(_,_,Id,File),_,_,_,_), Files) },
	[ '    ~w: ~p'-[Id, Files], nl ].

