# Claude Instructions

## Commit and Push Protocol

Whenever the user says "commit and push", I will:

1. Add ALL files in the repository to git staging area using `git add .`
2. Commit everything with a descriptive message
3. Push to the remote repository to keep remote and local repos synchronized

This ensures the remote repo maintains the same state as the local repo with all changes included.