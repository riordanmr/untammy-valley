git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso >doc/commit-history.txt
awk             -f scripts/git_log_to_html.awk doc/commit-history.txt >doc/release-notes.md
awk -v fmt=html -f scripts/git_log_to_html.awk doc/commit-history.txt >doc/release-notes.html
