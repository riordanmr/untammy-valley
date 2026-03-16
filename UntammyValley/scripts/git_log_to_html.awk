#!/usr/bin/awk -f
# git_log_to_html.awk
# This script converts the output of `git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso`
# into a simple HTML summary of commits, extracting version and build information when available.
# Mark Riordan  2026-03-13  mostly by Github Copilot
#
# Usage (Markdown default):
#   git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso | awk -f ./UntammyValley/scripts/git_log_to_html.awk >release-notes.md
# Usage (HTML):
#   git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso | awk -v fmt=html -f ./UntammyValley/scripts/git_log_to_html.awk >release-notes.html

function trim(value) {
    sub(/^[[:space:]]+/, "", value)
    sub(/[[:space:]]+$/, "", value)
    return value
}

function html_escape(value, escaped) {
    escaped = value
    gsub(/&/, "\\&amp;", escaped)
    gsub(/</, "\\&lt;", escaped)
    gsub(/>/, "\\&gt;", escaped)
    return escaped
}

function last_version(text,    value, remainder) {
    value = ""
    remainder = text
    while (match(remainder, /[0-9]+\.[0-9]+\.[0-9]+/)) {
        value = substr(remainder, RSTART, RLENGTH)
        remainder = substr(remainder, RSTART + RLENGTH)
    }
    return value
}

function last_integer(text,    value, remainder) {
    value = ""
    remainder = text
    while (match(remainder, /[0-9]+/)) {
        value = substr(remainder, RSTART, RLENGTH)
        remainder = substr(remainder, RSTART + RLENGTH)
    }
    return value
}

function first_integer(text,    value) {
    value = ""
    if (match(text, /[0-9]+/)) {
        value = substr(text, RSTART, RLENGTH)
    }
    return value
}

function update_version_from_key(line, key,    key_pos, remainder, candidate) {
    key_pos = index(tolower(line), tolower(key))
    if (!key_pos) {
        return
    }

    remainder = substr(line, key_pos + length(key))
    candidate = last_version(remainder)
    if (candidate != "") {
        parsed_version = candidate
    }
}

function update_build_from_key(line, key, stop_key,    lower_line, key_pos, stop_pos, remainder, candidate) {
    lower_line = tolower(line)
    key_pos = index(lower_line, tolower(key))
    if (!key_pos) {
        return
    }

    remainder = substr(line, key_pos + length(key))
    if (stop_key != "") {
        stop_pos = index(tolower(remainder), tolower(stop_key))
        if (stop_pos) {
            remainder = substr(remainder, 1, stop_pos - 1)
        }
    }

    # Handle phrasing like "CURRENT_PROJECT_VERSION from 54 to 55".
    if (match(tolower(remainder), /from[^0-9]*[0-9]+[^\n]*to[^0-9]*[0-9]+/)) {
        candidate = last_integer(substr(remainder, RSTART, RLENGTH))
        if (candidate != "") {
            parsed_build = candidate
            return
        }
    }

    candidate = first_integer(remainder)
    if (candidate != "") {
        parsed_build = candidate
    }
}

function update_project_marketing_current_format(line,    lower_line, key, key_pos, remainder, slash_pos, version_segment, build_segment, candidate) {
    lower_line = tolower(line)
    key = "project version and marketing version to"
    key_pos = index(lower_line, key)
    if (!key_pos) {
        return
    }

    remainder = substr(line, key_pos + length(key))
    slash_pos = index(remainder, "/")
    if (!slash_pos) {
        return
    }

    version_segment = substr(remainder, 1, slash_pos - 1)
    build_segment = substr(remainder, slash_pos + 1)

    candidate = last_version(version_segment)
    if (candidate != "") {
        parsed_version = candidate
    }

    if (index(tolower(build_segment), "current_project_version")) {
        candidate = first_integer(substr(build_segment, index(tolower(build_segment), "current_project_version") + length("current_project_version")))
        if (candidate != "") {
            parsed_build = candidate
        }
    }
}

function update_project_version_pair(line,    lower_line, current_pos, marketing_pos, tail, paren_text, comma_pos, build_segment, version_segment, candidate) {
    lower_line = tolower(line)
    current_pos = index(lower_line, "current_project_version")
    marketing_pos = index(lower_line, "marketing_version")
    if (!current_pos || !marketing_pos) {
        return
    }

    tail = substr(line, (current_pos < marketing_pos) ? current_pos : marketing_pos)
    if (!match(tail, /\([^)]*\)/)) {
        return
    }

    paren_text = substr(tail, RSTART + 1, RLENGTH - 2)
    comma_pos = index(paren_text, ",")
    if (!comma_pos) {
        return
    }

    build_segment = substr(paren_text, 1, comma_pos - 1)
    version_segment = substr(paren_text, comma_pos + 1)

    candidate = last_integer(build_segment)
    if (candidate != "") {
        parsed_build = candidate
    }

    candidate = last_version(version_segment)
    if (candidate != "") {
        parsed_version = candidate
    }
}

function update_bumped_project_marketing_pair(line,    lower_line, key, key_pos, remainder, slash_pos, build_segment, version_segment, candidate) {
    lower_line = tolower(line)
    key = "project version/marketing version bumped to"
    key_pos = index(lower_line, key)
    if (!key_pos) {
        return
    }

    remainder = substr(line, key_pos + length(key))
    slash_pos = index(remainder, "/")
    if (!slash_pos) {
        return
    }

    build_segment = substr(remainder, 1, slash_pos - 1)
    version_segment = substr(remainder, slash_pos + 1)

    candidate = last_integer(build_segment)
    if (candidate != "") {
        parsed_build = candidate
    }

    candidate = last_version(version_segment)
    if (candidate != "") {
        parsed_version = candidate
    }
}

function parse_version_build(text,    lines, line_count, i, line, lower_line, candidate, combo) {
    parsed_version = ""
    parsed_build = ""

    line_count = split(text, lines, /\n/)
    for (i = 1; i <= line_count; i++) {
        line = lines[i]
        lower_line = tolower(line)

        update_version_from_key(line, "MARKETING_VERSION")
        update_version_from_key(line, "marketing version")
        update_build_from_key(line, "CURRENT_PROJECT_VERSION", "MARKETING_VERSION")
        update_project_version_pair(line)
        update_bumped_project_marketing_pair(line)
        update_project_marketing_current_format(line)

        if (match(line, /[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*\([0-9]+\)/)) {
            combo = substr(line, RSTART, RLENGTH)
            candidate = last_version(combo)
            if (candidate != "") {
                parsed_version = candidate
            }
            candidate = last_integer(combo)
            if (candidate != "") {
                parsed_build = candidate
            }
        }

        if (match(lower_line, /(version|v)[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/)) {
            candidate = substr(line, RSTART, RLENGTH)
            candidate = last_version(candidate)
            if (candidate != "") {
                parsed_version = candidate
            }
        }

        if (match(lower_line, /build[^0-9]*[0-9]+/)) {
            candidate = substr(line, RSTART, RLENGTH)
            candidate = last_integer(candidate)
            if (candidate != "") {
                parsed_build = candidate
            }
        }
    }
}

function extract_date_time(date_line,    candidate) {
    if (match(date_line, /[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
        candidate = substr(date_line, RSTART, RLENGTH)
        return candidate
    }
    return trim(date_line)
}

function emit_record(    full_text, date_time, header_text, summary_text, version_text, build_text) {
    if (trim(record_date) == "") {
        return
    }

    full_text = record_subject
    if (record_body != "") {
        full_text = full_text "\n" record_body
    }

    parse_version_build(full_text)
    date_time = extract_date_time(record_date)
    summary_text = trim(record_subject)
    version_text = (parsed_version != "") ? parsed_version : "?"
    build_text = (parsed_build != "") ? parsed_build : "?"

    header_text = "Version " version_text " (" build_text ") " date_time

    if (fmt == "html") {
        print "<div class=\"commit\">"
        print "  <div class=\"meta\">" html_escape(header_text) "</div>"
        print "  <div class=\"subject\">" html_escape(summary_text) "</div>"
        print "</div>"
    } else {
        print "## " header_text
        print ""
        print summary_text
        print ""
    }

    record_date = ""
    record_subject = ""
    record_body = ""
    record_line_count = 0
}

BEGIN {
    fmt = tolower(trim(fmt))
    if (fmt == "") {
        fmt = "md"
    }
    if (fmt != "md" && fmt != "html") {
        fmt = "md"
    }

    if (fmt == "html") {
        print "<!DOCTYPE html>"
        print "<html lang=\"en\">"
        print "<head>"
        print "  <meta charset=\"utf-8\">"
        print "  <title>Commit Summary</title>"
        print "  <style>"
        print "    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.35; }"
        print "    .commit { margin-bottom: 1.2rem; }"
        print "    .meta { font-weight: 700; }"
        print "    .subject { margin-top: 0.15rem; }"
        print "  </style>"
        print "</head>"
        print "<body>"
        print "  <h1>Untammy Valley Commit Summary</h1>"
    } else {
        print "# Untammy Valley Commit Summary"
        print ""
    }
}

/^---[[:space:]]*$/ {
    emit_record()
    next
}

{
    if (record_line_count == 0 && trim($0) == "") {
        next
    }

    record_line_count++
    if (record_line_count == 1) {
        record_date = $0
    } else if (record_line_count == 2) {
        record_subject = $0
    } else {
        if (record_body != "") {
            record_body = record_body "\n"
        }
        record_body = record_body $0
    }
}

END {
    emit_record()
    if (fmt == "html") {
        print "</body>"
        print "</html>"
    }
}