%%%% -*- Mode: Prolog -*-

%%%% Rota Lorenzo 887451
%%%% Karzal Youness 879430


/*
 * jsonparse(+JSONA : atom, ?Obj : compound)
 * jsonparse(+JSONA : atom, ?Array : compound)
 *
 * Succeeds if JSONA is reconized as a JSON object or array.
 * An object is a set of name-value pairs, it begins with '{' and ends
 * with '}', each name is followed by ':' and the pairs are separated by
 * a comma ','.
 * An array begins with '[' and ends with ']', values are separated by a
 * comma ','.
 *
 * @param JSONA Atom to parse.
 * @param Obj Parsed object.
 * @param Array Parsed array.
 * @see https://www.json.org/json-en.html
 */

jsonparse(JSONA, Obj) :-
    catch(term_string(JSONT, JSONA), _, fail),
    nonvar(JSONT),
    object_check(JSONT, Obj),
    !.

jsonparse(JSONA, Array) :-
    catch(term_string(JSONT, JSONA), _, fail),
    nonvar(JSONT),
    array_check(JSONT, Array),
    !.


/*
 * object_check(+ObjCont : atom, ?ParsedObject : compound)
 *
 * Succeeds if the JSON atom can be parsed as a json object.
 *
 * @param ObjCont Content of the JSON Object.
 * @param ParsedObject Parsed object.
 */
object_check({}, jsonobj([])) :- !.

object_check({ObjCont}, jsonobj(ParsedObject)) :-
    jsonobj([ObjCont], ParsedObject),
    !.


/*
 * jsonobj(+Member : compound, ?ParsedMember : compound)
 * jsonobj(+Object : list, ?ParsedMembers : list)
 *
 * Given a Member it parses it and gives it back parsed.
 * Given a list of Members, it parses each one and gives back the parsed
 * list of members.
 *
 * @param Member Single member that needs to be parsed.
 * @param ParsedMember Single member that has been parsed.
 * @param Object List of members that need to be parsed.
 * @param ParsedMembers List of members that have been parsed.
 */
jsonobj([Member], [ParsedMember]) :-
    nonvar(Member),
    member_decompose(Member, Attribute, ParsedValue),
    ParsedMember =.. [',', Attribute, ParsedValue],
    !.

jsonobj([Object], [ParsedMember | ParsedMembers]) :-
    Object =.. [',', Member | MoreMembers],
    member_decompose(Member, Attribute, ParsedValue),
    ParsedMember =.. [',', Attribute, ParsedValue],
    jsonobj(MoreMembers, ParsedMembers),
    !.


/*
 * member_decompose(+Member : atom, ?Name : string, ?ParsedValue :
 * compound)
 *
 * Given a member, returns the pair name/value as [name : value].
 *
 * @param Member Member to be parsed
 * @param Name First part of the member before ':'.
 * @param ParsedValue Second part of the member after ':'.
 */
member_decompose(Member, Name, ParsedValue) :-
    Member =.. [':', Name, Value],
    stringCheck(Name),
    valueParse(Value, ParsedValue).


/*
 * array_check(+Array : list, ?ParsedArray : list)
 *
 * Succeeds if the JSON atom can be parsed as a json array.
 *
 * @param Array Valid json array.
 * @param ParsedArray Parsed array.
 */
array_check([], jsonarray([])) :- !.
array_check(Array, jsonarray(ParsedArray)) :-
    jsonarray(Array, ParsedArray),
    !.


/*
 * jsonarray(+Value, ?ParsedValue)
 * jsonarray(+Value, +Value2, ?ParsedValue, ?ParsedValue2)
 * jsonarray(+Value : list, +ValueRest, ?ParsedValue : list,
 * ?ParsedRest)
 *
 * Given a json array, parses the values inside of ParsedValue,
 * ParsedValue2 and/or ParsedRest, based on whether there is 1, 2 or N
 * values to parse.
 *
 * @param Value First value to parse.
 * @param Value2 Second value to parse.
 * @param ValueRest Rest of the values to parse.
 * @param ParsedValue First parsed value.
 * @param ParsedValue2 Second parsed value.
 * @param ParsedRest Rest of the parsed values.
 */
jsonarray([Value], [ParsedValue]) :-
    valueParse(Value, ParsedValue),
    !.

jsonarray([Value, Value2], [ParsedValue, ParsedValue2]) :-
    valueParse(Value, ParsedValue),
    valueParse(Value2, ParsedValue2),
    !.

jsonarray([Value | ValueRest], [ParsedValue | ParsedRest]) :-
    valueParse(Value, ParsedValue),
    jsonarray(ValueRest, ParsedRest),
    !.


/*
 * stringCheck(+String : list)
 *
 * Checks if the string has the right format:
 *     a string is a sequence of zero or more unicode characters
 *     wrapped in double quotes.
 *
 * @param String
 */
stringCheck(StringT) :-
    term_to_atom(StringT, StringA),
    atom_chars(StringA, StringL),
    stringCorrectStart(StringL).

stringCorrectStart(['"' | St]) :-
    stringCorrectRest(St).

stringCorrectRest(['"']) :- !.
stringCorrectRest([X | Lt]) :-
    X \= '"',
    stringCorrectRest(Lt).


/*
 * valueparse(+ValueT : atom, +ValueT : atom)
 * valueparse(+ValueT : atom, +ParsedValue : atom)
 *
 * Succeeds when Value is either a string, a number, true, false,
 * null, an object or an array. In case the value is an object or an
 * array, it parses them following the standard. If not, it converts the
 * value into a list of characters and checks if they follow the
 * standard without changing its values.
 *
 * @param ValueT Value that needs to be parsed.
 * @param ParsedValue Value that is parsed if either an array or an
 * object.
 */
valueParse(ValueT, ValueT) :-
    nonvar(ValueT),
    term_to_atom(ValueT, ValueA),
    atom_chars(ValueA, ValueL),
    valueCorrect(ValueL),
    !.

valueParse(ValueT, ParsedValue) :-
    nonvar(ValueT),
    objarr_parser(ValueT, ParsedValue),
    !.


/*
 * valueCorrect(+ValueL : List)
 *
 * Succeeds when Value is recognized as a valid value:
 *     -string
 *     -number
 *     -true
 *     -false
 *     -null
 *
 * @param ValueL List of characters of the value.
 */
valueCorrect(ValueL) :-
    stringCorrectStart(ValueL),
    !.

valueCorrect(ValueL) :-
    numberCorrect(ValueL),
    !.

valueCorrect(['t', 'r', 'u', 'e']) :- !.

valueCorrect(['f', 'a', 'l', 's', 'e']) :- !.

valueCorrect(['n', 'u', 'l', 'l']) :- !.


/*
 * objarr_parser(+Value, -ParsedObject)
 * objarr_parser(+Value, -ParsedArray)
 *
 * Proceeds with the parsing when Value is recognized as a valid:
 *     -object
 *     -array
 *
 * @param Value Value that contains either an object or an array.
 * @param ParsedObject Parsed object.
 * @param ParsedArray Parsed array.
 */
objarr_parser(Value, ParsedObject) :-
    object_check(Value, ParsedObject),
    !.

objarr_parser(Value, ParsedArray) :-
    array_check(Value, ParsedArray),
    !.


/*
 * numberCorrect(+Number : list)
 *
 * Succedes when the number is parsed correctly.
 *     A number can start with a '-', has N digits, if N>1 the number
 *     cant start with 0, it can be a fraction or contain an exponent.
 *
 * The check for a 0 at the start of the number works here, but since
 * the term_string predicate removes the 0 at the start of the number,
 * it is never used (inside of the parsing process).
 *
 * @param Number Number that needs to be parsed.
 */
numberCorrect(['-' | Lt]) :-
    num_zero(Lt).

numberCorrect(['-' | Lt]) :-
    num_digit(Lt).

numberCorrect(Lt) :-
    num_zero(Lt).

numberCorrect(Lt) :-
    num_digit(Lt).


/*
 * num_zero(+Number: list)
 *
 * If number starts with 0 checks for fraction and exponent.
 *
 * @param Number
 */
num_zero(['0' | Lt]) :-
    fraction(Lt, After),
    exponent(After).


/*
 * num_digit(+Number: list)
 *
 * If number does not start with 0 checks for the rest of the
 * number, then fraction and exponent.
 *
 * @param Number
 */
num_digit([Lh | Lt]) :-
    not_zero_digit(Lh),
    endable_digit_num(Lt, After),
    fraction(After, After2),
    exponent(After2).


/*
 * endable_digit_num(+Number: list, -After: List)
 *
 * Checks the number digits, allowing it to finish and passing back the
 * rest of the list.
 *
 * @param Number Number ciphers.
 * @param After Everything that comes after the ciphers.
 */
endable_digit_num([], []).
endable_digit_num([Lh | Lt], After) :-
    digit(Lh),
    endable_digit_num(Lt, After).
endable_digit_num(After, After) :-
    After = [Lh | _],
    not(digit(Lh)).


/*
 * not_endable_digit_num(+Number: list, -After: List)
 *
 * Checks the number digits, failing if it finishes. This allows to
 * check if the number has at least one cipher in it.
 * This is needed for example after a fraction point '.' when there must
 * be at least one cipher for the number to be correct.
 *
 * @param Number Number ciphers.
 * @param After Everything that comes after the ciphers.
 */
not_endable_digit_num([Lh | Lt], After) :-
    digit(Lh),
    endable_digit_num(Lt, After).


/*
 * fraction(+FractionPart: list, -After: List)
 *
 * Checks if the number has a fraction part or not, if not it stops and
 * proceeds with the other checks, if it contains one it checks for its
 * validity.
 *
 * @param FractionPart Everything that is part of the fraction.
 * @param After Everything that comes after the fraction.
 */
fraction([], []).
fraction(['.' | Lt], After) :-
    not_endable_digit_num(Lt, After).
fraction(After, After) :-
    After = [Lh | _],
    Lh \= '.'.


/*
 * exponent(+ExponentPart: list)
 *
 * Checks if the number has an exponent part or not, if not and the
 * list is not finished it fails. If it has one, it checks its validity
 * and once finished it unifies only if the rest of the list is empty.
 *
 * @param ExponentPart Everything that is part of the exponent.
 */
exponent([]).
exponent([Exp, Sign | Lt]) :-
    exponent_symbol(Exp),
    sign_symbol(Sign),
    not_endable_digit_num(Lt, []).
exponent([Exp | Lt]) :-
    exponent_symbol(Exp),
    not_endable_digit_num(Lt, []).


/*
 * digit(+digit)
 * not_zero_digit(+not_zero_digit)
 * exponent_symbol(+exponent)
 * sign_symbol(+sign)
 *
 * Predicates that help with the number parsing.
 */
digit('0').
digit(X) :-
    not_zero_digit(X).
not_zero_digit('1').
not_zero_digit('2').
not_zero_digit('3').
not_zero_digit('4').
not_zero_digit('5').
not_zero_digit('6').
not_zero_digit('7').
not_zero_digit('8').
not_zero_digit('9').
exponent_symbol('E').
exponent_symbol('e').
sign_symbol('-').
sign_symbol('+').


/*
 * jsonaccess(+Jsonobj, +Field, ?Result)
 *
 * Searches recursively for the specified Field inside of the Jsonobj,
 * if it finds it, it returns it inside of Result, if not it fails.
 * It can also look for a specified index inside of an array.
 *
 * @param Jsonobj Object or array that had been parsed where
 *                the field will be accessed.
 * @param Field Name of the field that needs to be accessed in the
 *              jsonobj in order to find a result.
 * @param Result Final result found inside of the Jsonobj at
 *               specified field.
 */
jsonaccess(Jsonobj, Field, Result) :-
    obj_access(Jsonobj, Field, Result).


/*
 * obj_access(+Elements, +Field, ?Result)
 *
 * Unifies if we are inside of a Jsonobj.
 *
 * @param Elements list of the elements of the object
 * @param Field
 * @param Result
 */
obj_access(jsonobj(Elements), Field, Result) :-
    elements_access(Elements, Field, Result).


/*
 * elements_access(+ElementH, +Field, -Result)
 * elements_access(+ElementT, +Field, -Result)
 *
 * Unpacks the elements inside of the passed List and calls
 * element_access recursively.
 *
 * @param ElementH First element of the list.
 * @param ElementT Rest of the elements of the list.
 * @param Field Field we are looking for inside of the element.
 * @param Result Result paired to the Field inside of the element.
 */
elements_access([ElementH | _], Field, Result) :-
    element_access(ElementH, Field, Result),
    !.

elements_access([_ | ElementT], Field, Result) :-
    elements_access(ElementT, Field, Result).


/*
 * element_access(+Element, +Field, -Result)
 * element_access(+Element, +Field, +Position, -Result)
 * element_access(+Element, +Field, +Position | +FieldRest, -Result)
 * element_access(+Element, +FieldHead | +FieldRest, -Result)
 *
 * Checks if Field unifies inside of the given Element and returns the
 * Result, also allows a Position to be passed as the index that needs
 * to be accessed inside of the resulting array. Allows the Field to
 * have multiple parameters that will be used to call jsonaccess
 * recursively.
 *
 * @param Element Element that needs to be accessed.
 * @param Field Field we are looking for inside of the element.
 * @param Result Result paired to the Field inside of the element.
 * @param Position Position we need to access inside of the array.
 * @param FieldHead First parameter we get the result of.
 * @param FieldRest List of parameters we need to get the results of
 *                  recursively.
 */
element_access(Element, [Field], Result) :-
    Element =.. [',', Field, Result],
    !.

element_access(Element, Field, Result) :-
    Element =.. [',', Field, Result],
    !.

element_access(Element, [Field, Position], Result) :-
    Element =.. [',', Field, jsonarray(Value)],
    number(Position),
    array_access(Value, Result, Position, 0),
    !.

element_access(Element, [Field, Position | FieldRest], Result) :-
    Element =.. [',', Field, jsonarray(Value)],
    number(Position),
    array_access(Value, Element2, Position, 0),
    jsonaccess(Element2, FieldRest, Result),
    !.

element_access(Element, [FieldHead | FieldRest], Result) :-
    element_access(Element, FieldHead, Element2),
    jsonaccess(Element2, FieldRest, Result),
    !.


/*
 * array_access(+Result, +Result, +Position, +Position)
 * array_access(+Rest, +Result, -Position, -OldPosition)
 *
 * Looks for an element inside of an array at given Position, if the
 * position is not correct it increments it until it reaches the right
 * Position, once reached it unifies only if the Result is at the
 * correct position.
 *
 * @param Result Element we need to access.
 * @param Position Position we need to access inside of the array.
 * @param Rest Rest of the list of elements we need to check into.
 * @param OldPosition Old position that will be increased and passed
 *                    recursively.
 */
array_access([Result | _], Result, Position, Position) :- !.
array_access([_ | Rest], Result, Position, OldPosition) :-
    NewPosition is OldPosition + 1,
    array_access(Rest, Result, Position, NewPosition).


/*
 * jsonread(+FileName : atom, -JSONObj : compound)
 *
 * Given the name of the file, it opens it and does the parsing
 * of its content.
 *
 * @param FileName The name of the file to open.
 * @param JSONObj The result of the parsing of the file.
 */
jsonread(FileName, JSONObj) :-
    read_file_to_string(FileName, JSONString, []),
    jsonparse(JSONString, JSONObj).


/*
 * jsondump(+JSON : compound, +FileName : atom)
 *
 * Given the name of a file to save to, saves the JSON standard result
 * inside of it, parsing it linearly. In case the file doesn't exists,
 * it creates it; if it already exists, it overwrites it.
 *
 * @param JSON The yet not JSON standard parsed result that needs to be
 *             parsed back into JSON standard and saved in the file.
 * @param FileName The name of the file where the JSON standard
 *                 result will be written.
 */
jsondump(JSON, FileName) :-
    open(FileName, write, Stream),
    json_stream(JSON, Stream, 1),
    close(Stream).


json_stream(jsonobj(JSON), Stream, NumTab) :-
    write(Stream, '{'),
    obj_stream(JSON, Stream, NumTab),
    write(Stream, '\n'),
    NumTabNew is NumTab - 1,
    tabs_stream(Stream, NumTabNew),
    write(Stream, '}'),
    !.

json_stream(jsonarray(JSON), Stream, NumTab) :-
    write(Stream, '['),
    arr_stream(JSON, Stream, NumTab),
    write(Stream, '\n'),
    NumTabNew is NumTab - 1,
    tabs_stream(Stream, NumTabNew),
    write(Stream, ']'),
    !.

obj_stream([], _, _) :- !.

obj_stream([Head], Stream, NumTab) :-
    Head =.. [',', String, Value],
    write(Stream, '\n'),
    tabs_stream(Stream, NumTab),
    writeq(Stream, String),
    write(Stream, ': '),
    value_stream(Value, Stream, NumTab),
    !.

obj_stream([Head | Tail], Stream, NumTab) :-
    obj_stream([Head], Stream, NumTab),
    write(Stream, ','),
    obj_stream(Tail, Stream, NumTab),
    !.

arr_stream([], _, _) :- !.

arr_stream([Value], Stream, NumTab) :-
    write(Stream, '\n'),
    tabs_stream(Stream, NumTab),
    value_stream(Value, Stream, NumTab),
    !.

arr_stream([Head | Tail], Stream, NumTab) :-
    arr_stream([Head], Stream, NumTab),
    write(Stream, ','),
    arr_stream(Tail, Stream, NumTab),
    !.

value_stream(Value, Stream, NumTab) :-
    NumTabNew is NumTab + 1,
    json_stream(Value, Stream, NumTabNew),
    !.

value_stream(Value, Stream, _) :-
    writeq(Stream, Value),
    !.

tabs_stream(_, 0) :- !.

tabs_stream(Stream, NumTab):-
    write(Stream, '\t'),
    NumTabNew is NumTab - 1,
    tabs_stream(Stream, NumTabNew),
    !.


%%%% end of file -- jsonparse.pl
