import os, strutils, sequtils, math

###################
#                 #
#    T Y P E S    #
#                 #
###################

#[  AVL tree adapted from Julienne Walker's presentation at
    http://eternallyconfuzzled.com/tuts/datastructures/jsw_tut_avl.aspx.

    Uses bounded recursive versions for insertion and deletion.
    Taken from Rosetta Code
]#

type
    # Direction used to select a child.
    Direction = enum Left, Right

    # Description of the tree node.
    Line = ref object
        index   : int                    # value to compare for balance(and keep order of lines of text)
        text    : string
        balance : range[-2..2]           # Balance factor (bounded).
        links   : array[Direction, Line] # Children.

    # This type constitutes a text file in memory.
    Document = ref object
        name          : string
        path          : string
        extension     : string
        modified      : bool
        body          : Line
        lowest_index  : int
        highest_index : int

func opp(dir: Direction): Direction {.inline.} =
    ## Return the opposite of a direction.
    Direction(1 - ord(dir))

##############
#    Line    #
##############

func single(root: Line; dir: Direction): Line =
    ## Single rotation.

    result = root.links[opp(dir)]
    root.links[opp(dir)] = result.links[dir]
    result.links[dir] = root


func double(root: Line; dir: Direction): Line =
    ## Double rotation.

    let save = root.links[opp(dir)].links[dir]

    root.links[opp(dir)].links[dir] = save.links[opp(dir)]
    save.links[opp(dir)] = root.links[opp(dir)]
    root.links[opp(dir)] = save

    result = root.links[opp(dir)]
    root.links[opp(dir)] = result.links[dir]
    result.links[dir] = root


func adjustBalance(root: Line; dir: Direction; balance: int) =
    ## Adjust balance factors after double rotation.

    let node1 = root.links[dir]
    let node2 = node1.links[opp(dir)]

    if node2.balance == 0:
        root.balance = 0
        node1.balance = 0

    elif node2.balance == balance:
        root.balance = -balance
        node1.balance = 0

    else:
        root.balance = 0
        node1.balance = balance

    node2.balance = 0


func insertBalance(root: Line; dir: Direction): Line =
    ## Rebalancing after an insertion.

    let node = root.links[dir]
    let balance = 2 * ord(dir) - 1

    if node.balance == balance:
        root.balance = 0
        node.balance = 0
        result = root.single(opp(dir))

    else:
        root.adjustBalance(dir, balance)
        result = root.double(opp(dir))


func insertR(root: Line; new_line: Line): tuple[node: Line, done: bool] =
    ## Insert data (recursive way).

    if root.isNil:
        return (new_line, false)

    if root.index == new_line.index:
        root.text = new_line.text
        return (root, false)

    let dir = if root.index < new_line.index: Right else: Left
    var done: bool
    (root.links[dir], done) = root.links[dir].insertR(new_line)
    if done:
        return (root, true)

    inc root.balance, 2 * ord(dir) - 1
    result = case root.balance
        of 0: (root, true)
        of -1, 1: (root, false)
        else: (root.insertBalance(dir), true)


func removeBalance(root: Line; dir: Direction): tuple[node: Line, done: bool] =
    ## Rebalancing after a deletion.

    let node = root.links[opp(dir)]
    let balance = 2 * ord(dir) - 1
    if node.balance == -balance:
        root.balance = 0
        node.balance = 0
        result = (root.single(dir), false)
    elif node.balance == balance:
        root.adjustBalance(opp(dir), -balance)
        result = (root.double(dir), false)
    else:
        root.balance = -balance
        node.balance = balance
        result = (root.single(dir), true)


func removeR(root: Line; index: int): tuple[node: Line, done: bool] =
    ## Remove data (recursive way).

    if root.isNil:
        return (nil, false)

    var
        index = index
    if root.index == index:
        if root.links[Left].isNil:
            return (root.links[Right], false)
        if root.links[Right].isNil:
            return (root.links[Left], false)
        var heir = root.links[Left]
        while not heir.links[Right].isNil:
            heir = heir.links[Right]
            root.index = heir.index
            index = heir.index

    let dir = if root.index < index: Right else: Left
    var done: bool
    (root.links[dir], done) = root.links[dir].removeR(index)
    if done:
        return (root, true)
    dec root.balance, 2 * ord(dir) - 1
    result = case root.balance
            of -1, 1: (root, true)
            of 0: (root, false)
            else: root.removeBalance(dir)


method print(self: Line) {.base.} =
    echo self.index, "\t| ", self.text


method list(self: Line, lower_bound: int, upper_bound: int) {.base.} =
    # Return traps
    if self == nil: return

    if self.index  < lower_bound: return
    if upper_bound < self.index:  return

    if lower_bound < self.index:
        self.links[Left].list(lower_bound, upper_bound)
    if lower_bound <= self.index and self.index <= upper_bound:
        self.print()
    if self.index < upper_bound:
        self.links[Right].list(lower_bound, upper_bound)

proc read(self: Line, index: int): string =
    if self == nil: return
    if self.index == index:
      return self.text
    if index < self.index:
      return self.links[Left].read(index)
    if self.index < index:
      return self.links[Right].read(index)

method align(self: Line, increment: int, index: int): int {.base.} =
    if self == nil: return index
    var idx : int = index
    idx = self.links[Left].align(increment, idx)
    self.index = increment * idx
    idx += 1
    idx = self.links[Right].align(increment, idx)
    return idx


method len(self: Line, length: int): int {.base.} =
    if self == nil: return 0
    var len : int = length
    if self.links[Left] != nil:
        len = self.links[Left].len(len)
    len += 1
    if self.links[Right] != nil:
        len = self.links[Right].len(len)
    return len


method save(self: Line, file: var string, max: int): string {.base.} =
    if self == nil: return file
    var edited_file : string = file
    if self.links[Left]  != nil:
        edited_file = self.links[Left].save(edited_file, max)
    edited_file = edited_file  & self.text
    if self.index < max: edited_file = edited_file & "\n"
    if self.links[Right] != nil:
        edited_file = self.links[Right].save(edited_file, max)
    return edited_file

#---------------------------------------------------------------------------------------------------
##############
#  Document  #
##############

proc insert(self: Document, new_line: var Line) =
    if self.body == nil:
        self.lowest_index  = new_line.index
        self.highest_index = new_line.index
        self.body          = new_line
        return
    if new_line.index < self.lowest_index:
        self.lowest_index  = new_line.index
    if self.highest_index < new_line.index:
        self.highest_index = new_line.index
    self.body      = self.body.insertR(new_line).node
    self.modified  = true


proc remove(self: Document, removed_line: int) =
    if self.body == nil: 
        echo "DELETE Error: Document already empty."
        return
    if removed_line < self.lowest_index and self.highest_index < removed_line:
        echo "DELETE Error: Selected line out of document bounds."
        return
    discard self.body.removeR(removed_line).node
    self.modified = true


proc align(self: Document, increment: int, index: int) =
    self.lowest_index  = increment * index
    self.highest_index = increment * self.body.align(increment, index)


proc len(self: Document): int =
    if self.body == nil:
        return 0
    return self.body.len(0)


proc save(self: Document): tuple[file_path: string, text_body: string] =
    if self == nil: return
    var file_body : string
    return ( self.path & self.name & self.extension, self.body.save( file_body, self.highest_index) )

#---------------------------------------------------------------------------------------------------

###################
#  G L O B A L S  #
###################
var open_documents   : seq[Document]
var current_document : int = 0


###################
#  H E L P E R S  #
###################
proc is_int(token: string): bool =
    try:
        discard parseInt(token)
        return true
    except ValueError:
        return false

proc strip_first_token(input: string, token: string): string =
    if (len(input) - len(token)) < 1:
        return " "
    return input[len(token) .. ^1]

proc tokenize(input: string): seq[string] =
    return input.split(' ')[1 .. ^1]



#---------------------------------------------------------------------------------------------------

#####################
#  C O M M A N D S  #
#####################

# List out each line of text in current document
proc command_list(arguments: string) =
    if open_documents[current_document].body == nil:
        echo "\tNo text to list :'("
        return

    let tokens : seq[string] = arguments.tokenize()
    var
        start  : int = 0
        stop   : int = open_documents[current_document].highest_index

    if tokens != @[] and tokens != @[""]:
        for i, token in tokens:
            if is_int(token): continue
            echo "\tLIST Error: Improper Syntax!"
            echo "\tCorrect syntax: LIST < starting index (optional)> < ending index (optional)>"
            echo "\tArgument ", i, ", was ", token, ", not an integer.\n\tPlease, try again."
            return
        start = parseInt(tokens[0])
        if len(tokens) > 1: stop = parseInt(tokens[1])
        else: stop = start

    echo " "
    open_documents[current_document].body.list(start, stop)
    echo " "


# List UTE commands
proc command_help() =
    echo "\tCOMMANDS:\n\t---------"
    echo " LIST:     List out each line of text in current text file."
    echo "\tSyntax: LIST < starting index (optional)> < ending index (optional)>"
    echo " OPEN:     Open a text file from disk."
    echo "\tSyntax: OPEN < path/to/filename.extension >"
    echo " SAVE:     Save current text file to disk."
    echo "\tSyntax: SAVE < path/to/filename.extension (optional)>"
    echo " HELP:     List UTE commands."
    echo "\tSyntax: HELP (Wait, you already know this...)"
    echo " NEW:      Create a new text text file."
    echo "\tSyntax: NEW < filename(.extension) (optional)>"
    echo " FILE:     Switch to another open text file."
    echo "\tSyntax: FILE < filename(.extension)/index/ < / > (optional)>"
    echo " COPY:     Copy one line at given number to another."
    echo "\tSyntax: COPY < from line # > < to line # >"
    echo " DELETE:   Delete one line at given number to another."
    echo "\tSyntax: DELETE < line # >"
    echo " RENUM:    Change line number."
    echo "\tSyntax: RENUM < current line # > < new line # >"
    echo " ALIGN:  Align all line numbers by a given increment."
    echo "\tSyntax: ALIGN < number (optional, default=10)>"
    echo " QUIT:     Exit the editor."
    echo "\tSyntax: QUIT\n"


# Align all line numbers to a given increment
proc command_align(arguments: string) =
    let tokens    : seq[string] = arguments.tokenize()
    var increment : int = 10
    if len(tokens) > 0:
        if is_int(tokens[0]):
            increment = parseInt(tokens[0])
        else:
            echo "\tALIGN Error: Improper Syntax!"
            echo "\tCorrect Syntax: ALIGN < number (optional, default=10)>"
            echo "\tArgument, ", tokens[0], ", is not an integer.\n\tPlease, try again."
            return
    open_documents[current_document].align(increment, 1)
    echo " "


proc command_open(arguments: string) =
    let tokens : seq[string] = arguments.tokenize()
    if fileExists(tokens[0]) == false:
        echo "\tOPEN Error: Improper Input!"
        echo "\tCorrect syntax: OPEN < path/to/filename.extension >"
        echo "\tGiven argument, ", tokens[0], ", is not a valid file path.\n\tPlease, try again."
        return
    let file_path                  = splitFile(tokens[0])
    var new_document : Document    = Document(name: file_path.name, path: file_path.dir, extension: file_path.ext, modified: false)
    if len(new_document.path)==0:
        new_document.path = getCurrentDir()
    for index, doc in open_documents:
        if
            doc.name      == new_document.name and
            doc.path      == new_document.path and
            doc.extension == new_document.extension:
                echo "\tOPEN Error: Given file is already open."
                echo "\tSwitching to currently open file instead..."
                current_document = index
                echo "\tCurrent file, ", open_documents[current_document].name, open_documents[current_document].extension, ", is now being edited."
                return

    let text_file    : seq[string] = readFile(tokens[0]).split('\n')
    var increment    : int         = 10
    if len(tokens) > 1:
        if is_int(tokens[1]): increment = parseInt(tokens[1])
    for index, line in text_file:
        var new_line : Line = Line( index: (index+1) * increment, text: line )
        new_document.insert( new_line )

    open_documents.add(new_document)
    current_document = len(open_documents)-1
    echo "> Opened, and now currently editing: ", new_document.name, new_document.extension, " in ", new_document.path, ".\n"#\tHere are the first 5 lines:"
    #command_list("0 5")


proc command_save(arguments: string) =
    if open_documents[current_document].modified == false:
        echo "\tFile, ", open_documents[current_document].name & open_documents[current_document].extension, ", is already saved!\n"
    var
        tokens    : seq[string] = arguments.tokenize()
        file_path : tuple[dir: string, name: string, ext: string]
        file      : tuple[file_path: string, text_body: string]
    if len(tokens) == 0:
        if
            open_documents[current_document].name      == "" and
            open_documents[current_document].path      == "" and
            open_documents[current_document].extension == "":
                echo "\tSAVE Error: No filename or path given to save document!"
                echo "\tCorrect Syntax: SAVE < path/to/filename.extension (optional)>"
                return
        else:
            file = open_documents[current_document].save()
    else:
        file_path = splitFile(tokens[0])
        open_documents[current_document].name      = file_path.name
        open_documents[current_document].path      = file_path.dir
        open_documents[current_document].extension = file_path.ext
        file = open_documents[current_document].save()

    try: writeFile( file.file_path, file.text_body )
    except:
        echo "\tSAVE Error: Unable to write file!\n\tMake sure you have given a valid path and/or file name."
        echo "\tCorrect Syntax: SAVE < path/to/filename.extension (optional)>\n"
        return

    echo "> File ", open_documents[current_document].name & open_documents[current_document].extension, " saved successfully to directory ", open_documents[current_document].path, "!\n"


proc command_new(arguments: string) =
    var
        tokens    : seq[string] = arguments.tokenize()
        file_path : tuple[dir: string, name: string, ext: string]
        new_document : Document = Document()
    new_document.modified = true
    open_documents.add(new_document)
    if len(tokens) > 0:
        file_path = splitFile(tokens[0])
        open_documents[current_document].name      = file_path.name
        open_documents[current_document].path      = file_path.dir
        open_documents[current_document].extension = file_path.ext
    current_document = open_documents.high


proc command_file(arguments: string) =
    let tokens : seq[string] = arguments.tokenize()
    if is_int(tokens[0]) and parseInt(tokens[0]) in 0..open_documents.high:
        current_document = parseInt(tokens[0])
    elif tokens[0] == "<":
        current_document = open_documents.high mod current_document - 1
    elif tokens[0] == ">":
        current_document = open_documents.high mod current_document + 1
    else:
        echo "\tFILE Error: Unable to switch open file! Malformed argument."
        echo "\tCorrect Syntax: FILE < filename(.extension)/index/ < / > (optional)>\n"
        return
    echo "> Switched to ", open_documents[current_document].name & open_documents[current_document].extension, ", document #", current_document, "\n"


proc command_delete(arguments: string) =
    let tokens : seq[string] = arguments.tokenize()
    if is_int(tokens[0]) == false:
        echo "\tDELETE Error: Unable to delete line! Malformed argument."
        echo "\tCorrect Syntax: DELETE < line # >"
        return
    let line_num = parseInt(tokens[0])
    open_documents[current_document].remove(line_num)
    echo "> Deleted line number ", line_num, ".\n"


proc command_copy(arguments: string) =
    let tokens : seq[string] = arguments.tokenize()
    if len(tokens) < 2:
        echo "\tCOPY Error: Unable to copy! Malformed argument."
        echo "\tCorrect Syntax: COPY < from line # > < to line # >"
        return
    if not is_int(tokens[0]) or not is_int(tokens[1]):
        echo "\tCOPY Error: Unable to copy! Both arguments must be integers."
        echo "\tCorrect Syntax: COPY < from line # > < to line # >"
        return
    let
        from_line : int    = parseInt(tokens[0])
        to_line   : int    = parseInt(tokens[1])
        from_txt  : string = open_documents[current_document].body.read(from_line)
    if from_txt == nil:
        echo "\tCOPY Error: Unable to copy! Copy from line is nonexistent."
        return
    var copied_line : Line = Line(index: to_line, text: from_txt)
    open_documents[current_document].insert(copied_line)
    echo "> Copied line number ", from_line, " to ", to_line, ".\n"


#---------------------------------------------------------------------------------------------------
#####################
#  E V A L U A T E  #
#####################
proc evaluate(user_input: var string) =
    let
        tokens : seq[string] = user_input.split(' ')
        token  : string      = tokens[0]
    var text   : string      = strip_first_token(user_input, token)
    case toLowerAscii(token[0])
    of 'l': # List out each line of text in current file
        command_list(text)
    of 'o': # Open a text file from disk
        command_open(text)
    of 's': # Save current file to disk
        #echo "\tSAVE: todo..."
        command_save(text)
    of 'h': # List UTE commands
        command_help()
    of 'n': # Create a new text file
        command_new(text)
    of 'f': # Switch to another open file
        command_file(text)
    of 'c': # Copy one line number to another
        command_copy(text)
    of 'd': # Delete line at given number
        command_delete(text)
    of 'r': # Renumber a line
        echo "\tRENUM: todo..."
    of 'a': # Align all line numbers in current file to a given increment
        command_align(text)
    of 'q': # Exit the program
        echo "\tQUIT: todo->"
        echo "\t\t- Ask user to save modified document(s) before exit"
        quit(0)
    #elif is_int(user_input): # delete line

    elif is_int(token):
        let index    : int = parseInt(token)
        let len_body : int = open_documents[current_document].len()

        var new_line : Line = Line(index: index, text: text[1 .. ^1] )
        open_documents[current_document].insert(new_line)

    else:
        echo "\tUnknown command, ", token, ", otherwise, it is not a valid line number.\n"


###################
#                 #
#     M A I N     #
#                 #
###################
#write(stdout, "\x1b[2J")
echo "\t\t*** Nim Unstructured Text Editor ***\n"


#var new_document : Document = Document()
#open_documents.add(new_document)
#open_documents[current_document].length = 0
command_new("")

while true:
    var input : string = readLine(stdin)
    evaluate( input )

