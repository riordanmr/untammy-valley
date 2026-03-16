git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso | awk -f scripts/git_log_to_html.awk >doc/release-notes.md
git log --pretty=format:"%n%ad%n%s%n%b%n---" --date=iso | awk -v fmt=html -f scripts/git_log_to_html.awk >doc/release-notes.html
