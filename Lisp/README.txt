Rota Lorenzo 887451
Karzal Youness 879430


-----------------------------------------------------------------------
jsonparse: Transforms the string into a list of characters,
subsequently removes the whitespaces and verify that the list is either 
a jsonlist or a jsonarray

-----------------------------------------------------------------------
json-obj: Verifies that the first character is a open 
bracket, delivers its content (cdr list) to the json-member function,
expects the first returned character to be a close bracket

-----------------------------------------------------------------------
json-array: Verifies that the first character is a open
square, delivers its contents (cdr list) to the json-element function,
expects the first return character to be a close square

-----------------------------------------------------------------------
json-element: Through the json-element I verify that the head of the list
is a valid value, if the returned list head is a comma it means that
I need to read another element, I then recursively call json-element

-----------------------------------------------------------------------
json-member: Through the json-member I verify that there is an pair of
attribute-value, if the head of the return list is a comma it means
that I need to read another member, I then recursively call json-member

-----------------------------------------------------------------------
json-pair: The function checks that the list contains an attribute,
a colon followed and a value, the function returns the pair and the rest
of the list not yet read

-----------------------------------------------------------------------
json-attribute: Given a list of characters in inupt, the function checks
that the head has a string in the format $" $content $".
It returns the rest of the unread list

-----------------------------------------------------------------------
json-value: The function checks if the head of the list is a valid value
according to the json format:
    -Json array (reads the character [)
    -Json object (reads the character {)
    -Number (the head of the list is a number)
    -String (reads the character ")
    -true, false or null

-----------------------------------------------------------------------
json-number: Given a list of characters as input, checks that the head
is a number with the following steps:
    -checks that for the number's sign  (negative or positive).
    -calls the json-integerNumbers function on the unsigned number.
    -the function then puts back the sign of the number

-----------------------------------------------------------------------
json-integerNumbers: the function starts constructing an integer number
by concatenating the individual digits, if it runs into a dot it means
that the number is a float, it then passes the decimal part to the function
json-floatnumbers

-----------------------------------------------------------------------
json-floatnumbers: handles the decimal and exponent part of 
a number with a comma

-----------------------------------------------------------------------
json-removeWhiteSpaces: the function takes a list of characters as input,
cleans it by removing all whitespace characters defined by json.org.
when it comes across a " skips all whitespace characters by passing the
control to the function json-removeWhiteSpaces-skip

-----------------------------------------------------------------------
json-removeWhiteSpaces-skip: the function rebuilds the list keeping it
unchanged until it encounters the "

-----------------------------------------------------------------------
jsonaccess: the jsonaccess function accepts a JSON object produced by the
jsonparse function and a set of "fields," retrieves the corresponding object.
If the head of the list is a JSONOBJ I will pass control to the 
jsonaccess-obj function

-----------------------------------------------------------------------
jsonaccess-obj: checks that the field is contained in the list elements.
A recursive check is performed on the head of each list element

-----------------------------------------------------------------------
jsonaccess-array: checks that the field is a number, if not returns an error.
If the field is a number, checks that the length of the list is longer than the number's length,
if so returns the nth element of the list (N defined by the input field)

-----------------------------------------------------------------------
jsondump: the function writes the JSON object inside of a specified file
in a properly formatted JSON syntax. If there is no file with the specified
filename, it creates a new file. Ff it does exist, it gets overwritten

-----------------------------------------------------------------------
jsonwrite-obj: the function reads the fields of a JSON object and transforms them into a 
properly formatted string in the form: { + members + } 

-----------------------------------------------------------------------
jsonwrite-members: the function reads the attribute and value fields of the JSON
and formats them into a string in the following form -> "attribute" : value
in case there are multiple members, it concatenates them by adding the character ","
between them

-----------------------------------------------------------------------
jsonwrite-array: the function reads the elements of an JSON array (values) 
and formats them into a list by adding the character "," between them

-----------------------------------------------------------------------
jsonread: the jsonread function opens a file and returns a JSON object.
To perform this operation the functiopn reads all characters from the input stream,
then provides this list of characters to the jsonparse function and expects
a correctly formatted JSON object.
