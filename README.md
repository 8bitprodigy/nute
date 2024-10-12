# N.U.T.E.

Nim Unstructured/Useless Text Editor

---

## Usage:

Run with `nute` and to enter text, type an integer, followed by a space, then your line of text, just like writing BASIC on an 80's microcomputer.

## Building:

```bash
nim c nute.nim
```

### Commands:

#### LIST:

List out each line of text in current text file.

##### Syntax:

    LIST < starting index (optional)> < ending index (optional)>

#### OPEN:

Open a text file from disk.

##### Syntax:

    OPEN < path/to/filename.extension >

#### SAVE:

Save current text file to disk.

##### Syntax:

    SAVE < path/to/filename.extension (optional)>

#### HELP:

List UTE commands.

##### Syntax:

    HELP (Wait, you already know this...)

#### NEW:

Create a new text text file.

##### Syntax:

    NEW < filename(.extension) (optional)>

#### FILE:

Switch to another open text file.

##### Syntax:

    FILE < filename(.extension)/index/ < / > (optional)>

#### COPY:

Copy one line at given number to another.

##### Syntax:

    COPY < from line # > < to line # >

#### DELETE:

Delete one line at given number to another.

##### Syntax:

    DELETE < line # >

#### RENUM:

Change line number.

##### Syntax:

    RENUM < current line # > < new line # >

#### ALIGN:

Align all line numbers by a given increment.

##### Syntax:

    ALIGN < number (optional, default=10)>

#### QUIT:

Exit the editor.

##### Syntax:

    QUIT

## License

This project is dedicated to the public domain where applicable, and 0BSD everywhere else. See `LICENSE` for terms.
