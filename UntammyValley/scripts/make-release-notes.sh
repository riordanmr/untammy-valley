git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso | awk -f scripts/git_log_to_html.awk >release-notes.html
