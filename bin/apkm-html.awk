#!/usr/bin/awk -f

#
# Converts markdown to HTML
#
# Implemented the basic syntax without nesting (list within list etc).
#
# See: https://www.markdownguide.org/cheat-sheet/
#

function empty() {
    return idx == 0
}

function peek() {
    return stk[idx]
}

function push(tag) {
    stk[++idx] = tag
    open_tag()
}

function pop(    tag) {
    tag = peek();
    if (!empty()) {
        close_tag();
        delete stk[idx--]
    }
    return tag
}

function print_buf() {

    buf = styles(buf);
    buf = images(buf);
    buf = links(buf);

    if (buf != "") {
        print buf;
    }
    buf = "";
}

function append(    str) {
    if (buf == "") {
        if (str ~ "\n") {
            str = substr(str, 2);
        }
        buf = str;
    } else {
        buf=buf " " str;
    }
}

function open_tag() {
    printf "<%s>\n", peek();
}

function close_tag() {
    print_buf();
    printf "</%s>\n", peek()
}

function make_tag(tag, text, key1, val1, key2, val2,    keyval1, keyval2) {

        if (key1 != "") {
            keyval1 = " " key1 "=\"" val1 "\"";
        }
        
        if (key2 != "") {
            keyval2 = " " key2 "=\"" val2 "\"";
        }
        
        if (text == "") {
            return "<" tag keyval1 keyval2 " />";
        } else {
            return "<" tag keyval1 keyval2 " >" text "</" tag ">";
        }
}

function em(buf) {

    while (buf ~ "_[^_]+_") {
        buf = apply_style(buf, "_", 1, "em");
    }

    while (buf ~ "\\*[^\\*]+\\*") {
        buf = apply_style(buf, "\\*", 1, "em");
    }
    
    return buf;
}

function strong(buf) {

    while (buf ~ "__[^_]+__") {
        buf = apply_style(buf, "__", 2, "strong");
    }
    
    while (buf ~ "\\*\\*[^\\*]+\\*\\*") {
        buf = apply_style(buf, "\\*\\*", 2, "strong");
    }
    
    return buf;
}

function code(buf) {

    while (buf ~ "`[^`]+`") {
        buf = apply_style(buf, "`", 1, "code");
    }
    
    return buf;
}

function styles(buf) {

    buf = strong(buf);
    buf = em(buf);
    buf = code(buf);
    
    return buf;
}

# one style at a time
function apply_style(str, char, len, tag,    out, found) {
    
    regex = char "[^" char "]+" char
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag(tag, found);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
}

function links(buf) {

    regex = "\\[[^]]+\\]\\([^)]*\\)"
    while (buf ~ regex) {
        buf = apply_link(buf, regex);
    }
    
    return buf;
}

# one link at a time
# ![label](http://example.com)
# <a href="http://example.com">label</a>
function apply_link(str, regex,    out, found, arr, href, label) {
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        split(found, arr, "\\]\\(");
        label = substr(arr[1], 2);
        href = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag("a", label, "href", href);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
}

function images(buf) {

    regex = "!\\[[^]]+\\]\\([^)]*\\)"
    while (buf ~ regex) {
        buf = apply_image(buf, regex);
    }
    
    return buf;
}

# one image at a time
# ![a label](image.png)
# <img src="image.png" alt="a label" />
function apply_image(str, regex,    out, found, arr, href, label) {
    
    if (match(str, regex) > 0) {
    
        found = substr(str, RSTART + len,   RLENGTH - 2*len);
        
        split(found, arr, "\\]\\(");
        label = substr(arr[1], 3);
        href = substr(arr[2], 1, length(arr[2]) - 1);
        
        out = out substr(str, 1, RSTART - 1);
        out = out make_tag("img", "", "src", href, "alt", label);
        out = out substr(str, RSTART + RLENGTH);
        
        return out;
    }
    
    return str;
}

function print_header() {

    print "<!DOCTYPE html>"
    print "<html>"
    print "<head>"
    print "<title></title>"
    print "</head>"
    print "<body>"
}

function print_footer() {
    print "</body>"
    print "</html>"
}

BEGIN {

    buf=""

    idx=0
    stk[0]="root";
    
    print_header();
}


/^[ ]*$/ {
    
    while (!empty()) {
        pop();
    }
    
    next;
}

/^===*[ ]*/ {

    # <h1>
    if (peek() == "p") {
        $0 = buf
        buf = ""
        pop();
        push("h1");
        append($0)
        pop();
    }
    
    next;
}

/^---*[ ]*/ {

    # <hr>
    if (empty()) {
        print make_tag("hr");
    }

    # <h2>
    if (peek() == "p") {
        $0 = buf
        buf = ""
        pop();
        push("h2");
        append($0)
        pop();
    }
    
    next;
}

/^\x23+[ ]+/ {

    match($0, "\x23+")
    n = RLENGTH > 6 ? 6 : RLENGTH

    if (empty()) {
    
        # remove leading hashes
        $0 = substr($0, n + 1)
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("h" n)
    }
    
    if (peek() == "h" n) {
        append($0)
    }
    next;
}

/^>[ ]+/ {

    if (empty()) {
    
        # remove leading hashes
        $0 = substr($0, 2)
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("blockquote")
    }
    
    if (peek() == "blockquote") {
        append($0)
    }
    
    next;
}

/^[ ]{4}[ ]*/ {

    if (empty()) {
        push("pre")
    }
    
    if (peek() == "pre") {
        append("\n" $0)
    }
    
    next;
}

/^[ ]*\*[ ]+/ {

    if (peek() == "li") {
        pop();
    }
    
    if (peek() == "ul") {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("li");
        
        append($0);
    }
    
    if (empty()) {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("ul");
        push("li");
        
        append($0);
    }
    
    next;
}

/^[ ]*[[:digit:]]+\.[ ]+/ {

    if (peek() == "li") {
        pop();
    }
    
    if (peek() == "ol") {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("li");
        
        append($0);
    }
    
    if (empty()) {
    
        # remove leading spaces
        sub(/^[ ]+/, "")
        # remove leading star
        $0 = substr($0, index($0, " "))
        # remove leading spaces
        sub(/^[ ]+/, "")
        
        push("ol");
        push("li");
        
        append($0);
    }
    
    next;
}

/^.+/ {
    if (empty()) {
        push("p")
    }
    
    if (!empty()) {
        append($0)
    }
}

END {
    print_footer();
}
