;;;; -*- Mode: Lisp -*-

;;;;Rota Lorenzo 887451
;;;;Karzal Youness 879430


;;;jsonparse: accepts a string as input and produces a JSON object
(defun jsonparse (JSONString)
  (let ((JSONList (json-removeWhiteSpaces (coerce JSONString 'list))))
    (or (json-array JSONList)
        (json-object JSONList)
        (error "Error: syntax error")))) ;non riconosce la stringa

;;;json-obj: accepts a list as input, checks that the head of the
;;;list is a JSON object, after reading the object returns
;;;the parsed object and the rest of the list of characters
(defun json-object (jsonObject)
  (cond ((eql (car jsonObject) #\{) ;first character must be {
         (if (eql (car (cdr jsonObject)) #\})
             (values (cons 'JSONOBJ '()) (cdr (cdr jsonObject)))
             (multiple-value-bind (jsonMember rest)
		 (json-member (cdr jsonObject)) ;reads the members
               (cond ((eql (car rest) #\}) ;returned value must be }
                      (values (cons 'JSONOBJ jsonMember) (cdr rest)))
                     (t (error "ERROR: syntax error"))))))))

;;;json-array: accepts a list as input, checks that the head
;;;of the list is a JSON array, after reading the returns
;;;the parsed array and the rest of the list of characters
(defun json-array (jsonArray)
  (cond ((eql (car jsonArray) #\[) ;first character must be [
         (if (eql (car (cdr jsonArray)) #\]) 
             (values (cons 'JSONARRAY '()) (cdr (cdr jsonArray)))
             (multiple-value-bind (jsonElement rest)
		 (json-element (cdr jsonArray)) ;reads the elements
               (cond ((eql (car rest) #\]);returned value must be ]
                      (values (cons 'JSONARRAY jsonElement) (cdr rest)))
                     (t (error "ERROR: syntax error"))))))))

;;;json-elment: verifies that the input list consists of a
;;;sequence of elements. After reading a single element
;;;checks if the returnd list head is ",". If so it
;;;has to read another one recursively
(defun json-element (input)
  (multiple-value-bind (element moreElements)
      (json-value input)
    (cond ((eql (car moreElements) #\,) ;checks for next elements
           (multiple-value-bind (nextElement nextMoreElements)
               (json-element (cdr moreElements))
             (values (cons element NextElement) nextMoreElements)))
          (t (values (list element) moreElements)))))

;;;json-member: verifies that the head of the list consists of
;;;a json-member. If the head of the returned list is ","
;;;the function has to read another one recursively
(defun json-member (input)
  (multiple-value-bind (pair morepairs)
      (json-pair input)
    (cond ((eql (car morepairs) #\,) ;checks for more pairs
           (multiple-value-bind (nextpair nextMorepairs)
               (json-member (cdr morepairs))
             (values (cons pair nextpair)  nextMorePairs)))
          (t (values (list pair)  morepairs)))))

;;;json-pair: reads a json pair in the head of the list. A pair
;;;is correctly recognized if: attribute + ":" + value
(defun json-pair (input)
  (multiple-value-bind (jsonAttribute valueAndRest)
      (json-attribute input) ;verifes the attribute
    (if (eql (car valueAndRest) #\:) ;recognizes :
        (multiple-value-bind (jsonValue rest)
            (json-value (cdr valueAndRest)) ;verifies the value
          (values (list jsonAttribute jsonValue) rest))
	(error "Error: missing colon"))))


;;;json-attribute: check that the head of the list is a JSON attribute        
(defun json-attribute (input)
  (if (not (eql (car input) #\")) ;attribute must be a string
      (error "ERROR: syntax error")
      (multiple-value-bind (attributeString rest)
          (json-string (cdr input)) ;cheks the attribute
	(values (coerce attributeString 'string)  rest))))                             


;;;check for values of true false and null
(defun json-istrue (input)
  (and (eql (car input) #\t) (eql (cadr input) #\r)
       (eql (caddr input) #\u) (eql (cadddr input) #\e)))

(defun json-isfalse (input)
  (and (eql (car input) #\f) (eql (cadr input) #\a)
       (eql (caddr input) #\l) (eql (cadddr input) #\s)
       (eql (car (cddddr input)) #\e)))

(defun json-isnull (input)
  (and (eql (car input) #\n) (eql (cadr input) #\u)
       (eql (caddr input) #\l) (eql (cadddr input) #\l)))

;;;json-value: checks that the head of the list contains a JSON value:
;;;JSON-OBJ, JSON-ARRAY, number, string, true, false, or null
(defun json-value (input)
  (cond ((eql (car input) #\[) ;checks for JSON-ARRAY
         (multiple-value-bind (jsonarray rest)
             (json-array input)
           (values jsonarray rest)))
        ((eql (car input) #\") ;checks for la stringa
         (multiple-value-bind (jsonstring rest)
             (json-string (cdr input))
           (values (coerce jsonstring 'string) rest)))
        ((eql (car input) #\{) ;checks for JSON-OBJ
         (multiple-value-bind (jsonobject rest)
             (json-object input)
           (values jsonobject rest)))
        ((or (eql (car input) #\+) ;checks for i numeri
             (eql (car input) #\-)
             (digit-char-p (car input)))
         (multiple-value-bind (jsonnumber rest)
             (json-number input)
           (values jsonnumber rest)))
        ((json-istrue input) ;checks for true
         (values 'true (cddddr input)))
        ((json-isnull input) ;checks for null 
         (values 'null (cddddr input)))
        ((json-isfalse input) ;checks for false
         (values 'false (cdr (cddddr input))))))


;;;json-string: returns a string located at the beginning of a list.
;;;;A string ends when the function runs into a
;;;double quote not preceded by a backslash. Returns the string and the rest
(defun json-string (input)
  (cond ((null input) (error "ERROR: syntax error"))
        ((and (eql (car input) #\\) (eql (cadr input) #\")) ;backslash + "
         (multiple-value-bind (l1 l2) ;ignores the double quote
             (json-string (cddr input)) ;and call json-string again
           (values (cons (car input) (cons (cadr input) l1)) l2)))
	((eql (car input) #\") (values nil (cdr input))) ;;finishes concatenating
        ((null input) (values nil input))
        (t (multiple-value-bind (l1 l2)
               (json-string (cdr input))
             (values (cons (car input) l1)  l2)))))


;;;json-number:recognizes a number at the beginning of the list,
;;;returns the number and the rest of the list
(defun json-number (input)
  (cond ((and (eql (car input) #\0)
              (digit-char-p (cadr input)))
         (error "ERROR: syntax error"))
        ((or (eql (car input) #\-) ;;recognizes a negative number
             (eql (car input) #\+))
         (multiple-value-bind (numbers rest)
             (json-integerNumbers (cdr input))
           (values (with-input-from-string 
                       (in (coerce
                            (cons (car input) numbers)
                            'string)) 
                     (read in)) rest))) ;converts the string in a value
        (t (multiple-value-bind (numbers rest)
               (json-integerNumbers input) ;reads the number as integer
             (values (with-input-from-string 
                         (in (coerce  numbers 'string)) 
                       (read in)) rest)))))

;;;json-integerNumbers: checks that the number is an integer
;;;if during reading the number it encounters a . passes the control
;;;of the number to json-floatnumbers
(defun json-integerNumbers (input)
  (cond ((null input) (error "Error: syntax error"))
        ((eql (car input) #\.) ;verifies that the number is a float
         (if (not (digit-char-p (cadr input))) 
             (error "ERROR: syntax error")
             (multiple-value-bind (decimalPart rest)
		 (json-floatnumber (cdr input))
               (values (cons (car input) decimalPart) rest))))
        ((digit-char-p (car input)) ;to a number
         (multiple-value-bind (nextNumber rest)
             (json-integerNumbers (cdr input))
           (values (cons (car input) nextNumber) rest)))
        ((eql (car input) #\e)
         (multiple-value-bind (exponent rest)
             (json-exponent (cdr input))
           (values (cons #\e exponent) rest)))
        (t (values nil input))))

;;;json-floatnumber: handles the deciamal part of a number
(defun json-floatnumber (input)
  (cond ((null input) (error "Error: syntax error"))
        ((digit-char-p (car input))
         (multiple-value-bind (nextFloat rest)
             (json-floatnumber (cdr input))
           (values (cons (car input) nextFloat) rest)))
        ((eql (car input) #\e) ;checks for exponent
         (multiple-value-bind (exponent rest)
             (json-exponent (cdr input))
           (values (cons (car input) exponent) rest)))
        (t (values nil input))))

(defun json-exponent (input)
  (cond ((null input) (error "Error: syntax error"))
        ((or (eql (car input) #\+)
             (eql (car input) #\-))
         (if (not (digit-char-p (cadr input)))
             (error "ERROR: syntax error")
             (multiple-value-bind (nextExponent rest)
		 (json-exponentunsigned (cdr input))
               (values (cons (car input) nextExponent) rest))))
        ((digit-char-p  (car input)) 
         (multiple-value-bind (nextExponent rest)
             (json-exponentunsigned input)
           (values nextExponent rest)))
        (t (error "ERROR: syntax error"))))

(defun json-exponentunsigned (input)   
  (cond ((null input) (error "Error: syntax error"))
        ((digit-char-p (car input))
         (multiple-value-bind (nextExponent rest)
             (json-exponentunsigned (cdr input))
           (values (cons (car input) nextExponent) rest)))
        (t (values nil input))))


;;;json-removeWhiteSpaces: given a list of characters removes all
;;;the escape characters defined in the JSON whitespaces
(defun json-removeWhiteSpaces (input)
  (cond ((null input) input)
        ((or (eql (car input) #\Space)
             (eql (car input) #\NewLine)
             (eql (car input) #\Tab)
             (eql (car input) #\Backspace)
             (eql (car input) #\Linefeed))
         (json-removeWhiteSpaces (cdr input)))
        ((eql (car input) #\")
         (cons (car input) (json-removeWhiteSpaces-skip (cdr input))))
        (t (cons (car input) (json-removeWhiteSpaces (cdr input))))))

(defun json-removeWhiteSpaces-skip (input)
  (cond ((null input) (error "Error: syntax error"))
        ((and (eql (car input) #\\) (eql (car (cdr input)) #\"));checks for \"
         (cons (car input) ;ignores the " keeps the recursion
               (cons (cadr input) 
		     (json-removeWhiteSpaces-skip (cddr input)))))
	((eql (car input) #\") 
	 (cons (car input) 
               (json-removeWhiteSpaces (cdr input))))
	(t (cons (car input) 
		 (json-removeWhiteSpaces-skip (cdr input))))))

;--------------------------------------------------------------------------  

;;;jsonaccess: accepts a JSON object and a set of fields and
;;;retrieves the corresponding object
(defun jsonaccess (json &rest fields)
  (if (null fields) json
      (cond ((or (numberp json)
		 (stringp json))
             (error "ERROR: cannot access a non list"))
            ((equal (car json) 'JSONOBJ) ;checks if the list is an obj.
             (jsonaccess-obj (cdr json) (flatten fields)))
            ((equal (car json) 'JSONARRAY) ;checks if the list is an array.
             (jsonaccess-array (cdr json) (flatten fields)))
            (t (error "ERROR: syntax error")))))

;;;jsonaccess-obj: given a JSON object, retrieves the value of the attribute
;;;matching it with fields
(defun jsonaccess-obj (json fields)
  (cond ((null json) (error "ERROR: field not found"))
        ((not (stringp (car fields))) 
         (error "ERROR: field must be a string"))
        ((equal (car (car json)) (car fields)) 
         (if (null (cdr fields)) 
             (nth 0 (cdr (car json))) ;if it still have fields
             (jsonaccess (car (cdr (car json))) (cdr fields))));calls jsonaccess
        (t (jsonaccess-obj (cdr json) fields))))

;;;jsonaccess-array: given a JSON array I return the nth element
(defun jsonaccess-array (json fields)
  (cond ((null json) (error "ERROR: field not found"))
        ((not (numberp (car fields)));if the field is not a number gives error
         (error "ERROR: index must be a number"))
        ((>= (car fields) (length json)) ;number is longer than the array.
         (error "ERROR: index out of bounds"))
        (t (if (null (cdr fields)) (nth (car fields) json)
               (jsonaccess (nth (car fields) json) (cdr fields))))))

(defun flatten (lista)
  (cond ((null lista) lista)
        ((atom lista) (list lista))
        (t (append (flatten (first lista))
                   (flatten (rest lista))))))

;----------------------------------------------------------

;;;jsondump: the function writes the JSON object inside a file.
;;;If the file does not exist it creates it, if it exists it overwrites it
(defun jsondump (JSON filename)
  (cond ((or (null filename) (null JSON))
         (error "ERROR: cannot write"))
        (t (with-open-file (out filename
                                :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create)
             (mapcar (lambda (e)
                       (if (numberp e) (format out "~d" e)
                           (format out "~c" e)))
                     (cond ((equal (car JSON) 'JSONOBJ)
                            (flatten (jsonwrite-obj (cdr JSON) 1)))
                           ((equal (car JSON) 'JSONARRAY)
                            (flatten (jsonwrite-array (cdr JSON) 1)))
                           (t (error "ERROR: invalid JSON")))))))
  filename) ;returns the file's filename

;;;jsonwrite-obj: the function reads the fields of a JSON object
;;;formats and returns them
(defun jsonwrite-obj (JSON depth)
  (cond ((null json) (list #\{ #\}))
        (t (list #\{ #\NewLine
                 (jsonwrite-members JSON depth) 
                 #\NewLine
                 (jsonwrite-tabs (- depth 1)) #\}))))

;;;jsonwrite-members: reads the attribute, value and format them
(defun jsonwrite-members (JSON depth)
  (cond ((not (null (cdr JSON))) ;checks moreMembers
         (list (jsonwrite-tabs depth)
               (jsonwrite-string (car (car json))) ;reads the attribute
               #\: #\Space ;adds the :
               (jsonwrite-value (car (cdr (car JSON))) depth) ;value
               #\, #\NewLine
               (jsonwrite-members (cdr JSON) depth))) ;
        (t (list (jsonwrite-tabs depth) 
                 ( jsonwrite-string (car (car json))) 
                 #\: #\Space 
                 (jsonwrite-value (car (cdr (car JSON))) depth)))))

;;;jsonwrite-string: formats a string by adding double quotes
(defun jsonwrite-string (input)
  (list #\" (coerce input 'list) #\"))


;;;jsonwrite-value: reads a value, recognizes it, and formats it 
;;;so it can be written in the file
(defun jsonwrite-value (input depth)
  (cond ((stringp input) (jsonwrite-string input))     ;string
        ((numberp input) input)                        ;number
        ((eql 'TRUE input) (list #\t #\r #\u #\e))    
        ((eql 'FALSE input) (list #\f #\a #\l #\s #\e))
        ((eql 'NULL input) (list #\n #\u #\l #\l)) 
        ((eql (car input) 'JSONOBJ)                    ;json-obj
         (jsonwrite-obj (cdr input) (+ depth 1)))
        ((eql (car input) 'JSONARRAY)                  ;json-array
         (jsonwrite-array (cdr input) (+ depth 1)))
        (t (error "ERROR: value not valid"))))

;;;jsonwrite-tabs: adds the right amount of
;;;tabs within the .json file
(defun jsonwrite-tabs (n)
  (cond ((<= n 0) nil)
        (t (cons #\Tab (jsonwrite-tabs (- n 1))))))

;;;jsonwrite-array: reads the elements of an array and format them
;;;inside square brackets
(defun jsonwrite-array (JSON depth)
  (cond ((null JSON) (list #\[ #\]))
        (t (list #\[ #\NewLine
                 (jsonwrite-element JSON depth)
                 (jsonwrite-tabs (- depth 1)) #\]))))

;;;jsonwrite-element: formats the elements of an array by separating them
;;;with a comma
(defun jsonwrite-element (JSON depth)
  (cond ((not (null (cdr JSON))) ;checks for more elements
         (list (jsonwrite-tabs depth)
               (jsonwrite-value (car JSON) depth) #\,
               #\NewLine
               (jsonwrite-element (cdr JSON) depth)))
        (t (list (jsonwrite-tabs depth) 
                 (jsonwrite-value (car JSON) depth)
                 #\NewLine))))

;;;jsonread: opens a the file and returns a JSON object
(defun jsonread (filename)
  (with-open-file (s filename
                     :if-does-not-exist :error
                     :direction :input)
    (jsonparse (readchar s)))) ;reads and parses


;;;readchar: reads a input-stream of chars from a file until it ends
(defun readchar (input-stream)
  (let ((c (read-char input-stream nil nil)))
    (cond ((null c) c)
          (t (cons c (readchar input-stream))))))

;;;; end of file -- jsonparse.lisp --
