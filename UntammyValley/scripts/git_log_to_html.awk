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

function is_iso_date_line(line) {
    return line ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]][0-9][0-9]:[0-9][0-9]:[0-9][0-9][[:space:]][+-][0-9][0-9][0-9][0-9][[:space:]]*$/
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

function first_nonzero(a, b) {
    if (a && b) {
        return (a < b) ? a : b
    }
    return a ? a : b
}

function truncate_before(text, key_a, key_b,    lower_text, cut_pos, pos_a, pos_b) {
    lower_text = tolower(text)
    pos_a = (key_a != "") ? index(lower_text, tolower(key_a)) : 0
    pos_b = (key_b != "") ? index(lower_text, tolower(key_b)) : 0
    cut_pos = first_nonzero(pos_a, pos_b)
    if (cut_pos) {
        return substr(text, 1, cut_pos - 1)
    }
    return text
}

function extract_after_key(line, key, kind, stop_key_a, stop_key_b,    lower_line, key_pos, segment, candidate) {
    lower_line = tolower(line)
    key_pos = index(lower_line, tolower(key))
    if (!key_pos) {
        return ""
    }

    segment = substr(line, key_pos + length(key))
    segment = truncate_before(segment, stop_key_a, stop_key_b)
    segment = substr(segment, 1, 120)
    if (kind == "version") {
        candidate = last_version(segment)
    } else {
        if (match(tolower(segment), /from[^0-9]*[0-9]+[^\n]*to[^0-9]*[0-9]+/)) {
            candidate = last_integer(substr(segment, RSTART, RLENGTH))
        } else if (match(segment, /[0-9]+[^0-9]*->[[:space:]]*[0-9]+|[0-9]+[^0-9]*→[[:space:]]*[0-9]+/)) {
            candidate = last_integer(substr(segment, RSTART, RLENGTH))
        } else {
            candidate = first_integer(segment)
        }
    }
    return candidate
}

function extract_project_marketing_paren_pair(line,    lower_line, key_pos, segment, pair_text, slash_pos, build_segment, version_segment, candidate) {
    lower_line = tolower(line)
    key_pos = index(lower_line, "project version/marketing version")
    if (!key_pos) {
        return
    }

    segment = substr(line, key_pos + length("project version/marketing version"))
    if (!match(segment, /\([^)]*\/[^)]*\)/)) {
        return
    }

    pair_text = substr(segment, RSTART + 1, RLENGTH - 2)
    slash_pos = index(pair_text, "/")
    if (!slash_pos) {
        return
    }

    build_segment = substr(pair_text, 1, slash_pos - 1)
    version_segment = substr(pair_text, slash_pos + 1)

    candidate = last_integer(build_segment)
    if (candidate != "") {
        parsed_build = candidate
    }
    candidate = last_version(version_segment)
    if (candidate != "") {
        parsed_version = candidate
    }
}

function extract_project_marketing_slash_pair(line,    lower_line, key, key_pos, segment, pair_text, slash_pos, left_segment, right_segment, left_version, right_version, left_build, right_build) {
    lower_line = tolower(line)

    key = "project version/marketing version"
    key_pos = index(lower_line, key)
    if (!key_pos) {
        key = "project version and marketing version to"
        key_pos = index(lower_line, key)
    }
    if (!key_pos) {
        return
    }

    segment = substr(line, key_pos + length(key))
    if (match(segment, /\([^)]*\/[^)]*\)/)) {
        return
    }

    if (match(segment, /[0-9]+[[:space:]]*\/[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/)) {
        pair_text = substr(segment, RSTART, RLENGTH)
    } else if (match(tolower(segment), /[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*\/[[:space:]]*current_project_version[^0-9]*[0-9]+/)) {
        pair_text = substr(segment, RSTART, RLENGTH)
    } else {
        return
    }

    slash_pos = index(pair_text, "/")
    if (!slash_pos) {
        return
    }

    left_segment = trim(substr(pair_text, 1, slash_pos - 1))
    right_segment = trim(substr(pair_text, slash_pos + 1))
    left_segment = substr(left_segment, 1, 120)
    right_segment = substr(right_segment, 1, 120)

    left_version = last_version(left_segment)
    right_version = last_version(right_segment)
    left_build = last_integer(left_segment)
    right_build = last_integer(right_segment)

    if (left_version != "" && right_build != "" && index(tolower(right_segment), "current_project_version") > 0) {
        parsed_version = left_version
        parsed_build = right_build
        return
    }

    if (right_version != "" && left_build != "") {
        parsed_version = right_version
        parsed_build = left_build
    }
}

function extract_transition_pair(line,    paren_text, comma_pos, build_segment, version_segment, build_candidate, version_candidate) {
    if (!match(line, /\([^)]*[0-9][^)]*[->→][^)]*[0-9][^)]*,[^)]*[0-9]+\.[0-9]+\.[0-9]+[^)]*[->→][^)]*[0-9]+\.[0-9]+\.[0-9]+[^)]*\)/)) {
        return
    }

    paren_text = substr(line, RSTART + 1, RLENGTH - 2)
    comma_pos = index(paren_text, ",")
    if (!comma_pos) {
        return
    }

    build_segment = substr(paren_text, 1, comma_pos - 1)
    version_segment = substr(paren_text, comma_pos + 1)

    build_candidate = last_integer(build_segment)
    version_candidate = last_version(version_segment)

    if (build_candidate != "") {
        parsed_build = build_candidate
    }
    if (version_candidate != "") {
        parsed_version = version_candidate
    }
}

function extract_current_marketing_slash_pair(line,    lower_line, current_pos, marketing_pos, segment, to_pos, pair_text, slash_pos, left_segment, right_segment, build_candidate, version_candidate) {
    lower_line = tolower(line)
    current_pos = index(lower_line, "current_project_version")
    marketing_pos = index(lower_line, "marketing_version")
    if (!current_pos || !marketing_pos) {
        return
    }

    segment = substr(line, marketing_pos + length("marketing_version"))
    to_pos = index(tolower(segment), "to")
    if (to_pos) {
        segment = substr(segment, to_pos + 2)
    }

    if (!match(segment, /[0-9]+[[:space:]]*\/[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/)) {
        return
    }

    pair_text = substr(segment, RSTART, RLENGTH)
    slash_pos = index(pair_text, "/")
    if (!slash_pos) {
        return
    }

    left_segment = trim(substr(pair_text, 1, slash_pos - 1))
    right_segment = trim(substr(pair_text, slash_pos + 1))
    left_segment = substr(left_segment, 1, 80)
    right_segment = substr(right_segment, 1, 80)

    build_candidate = last_integer(left_segment)
    version_candidate = last_version(right_segment)

    if (build_candidate != "") {
        parsed_build = build_candidate
    }
    if (version_candidate != "") {
        parsed_version = version_candidate
    }
}

function parse_line_for_version_build(line,    lower_line, candidate, combo) {
    lower_line = tolower(line)

    candidate = extract_after_key(line, "CURRENT_PROJECT_VERSION", "build", "MARKETING_VERSION", "marketing version")
    if (candidate != "") {
        parsed_build = candidate
    }

    candidate = extract_after_key(line, "MARKETING_VERSION", "version", "CURRENT_PROJECT_VERSION", "")
    if (candidate != "") {
        parsed_version = candidate
    }

    if (index(lower_line, "marketing_version") == 0) {
        candidate = extract_after_key(line, "marketing version", "version", "CURRENT_PROJECT_VERSION", "")
        if (candidate != "") {
            parsed_version = candidate
        }
    }

    extract_project_marketing_paren_pair(line)
    extract_project_marketing_slash_pair(line)
    extract_transition_pair(line)
    extract_current_marketing_slash_pair(line)

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

    if (index(lower_line, "marketing_version") == 0 && index(lower_line, "current_project_version") == 0 && match(lower_line, /(^|[^[:alnum:]_])(version|v)[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/)) {
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

function parse_version_build(text,    lines, line_count, i) {
    parsed_version = ""
    parsed_build = ""

    line_count = split(text, lines, /\n/)
    for (i = 1; i <= line_count; i++) {
        parse_line_for_version_build(lines[i])
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
    if (record_line_count > 0 && is_iso_date_line($0)) {
        emit_record()
    }

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