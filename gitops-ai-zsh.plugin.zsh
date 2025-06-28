get_org() {
  git config --get remote.origin.url 2>/dev/null |
    sed -E 's#\.git$##' |
    awk -F'[:/]' '{print $(NF-1)}' |
    awk -F'-' '{
      for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)
      OFS="-"; print
    }'
}

generate_commit_msg() {
  local diff=$(git diff --cached | head -n 400)
  local org=$(get_org)
  local scope_part=""
  [[ -n $org ]] && scope_part="($org)"
  [[ -z $diff ]] && { echo "chore${scope_part}: empty commit"; return; }

  local model="gpt-4o-mini" response http_code msg
  response=$(jq -n --arg diff "$diff" --arg s "$scope_part" --arg m "$model" '{
      model:$m,
      messages:[
        {role:"system",content:"Write a single-line Conventional Commit message i.e. feat[organization]: new super feature to take over the world. Valid types: build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test. use $s for scope like the [organizatio] in the example.  if empty leave it blank."},
        {role:"user",content:$diff}
      ],
      max_tokens:80,
      temperature:0
    }' | curl -sS -w '\n%{http_code}' https://api.openai.com/v1/chat/completions \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${OPENAI_API_KEY_GITOPS}" \
          -d @-)
  http_code=${response##*$'\n'}
  response=${response%$'\n'*}

  if [[ $http_code == 200 ]]; then
    msg=$(printf '%s\n' "$response" | jq -er '.choices[0].message.content' 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n1)
    [[ -n $msg ]] && { echo "$msg"; return; }
  fi

  echo "chore${scope_part}: auto-commit"
}

gitops() {
  echo '===== gitops start ====='
  echo 'Staging all changes…'
  git add -A
  git diff --cached --quiet && { echo 'No changes to commit.'; echo '===== gitops done ====='; return; }

  local commit_msg=$(generate_commit_msg)
  echo "Commit message: $commit_msg"
  echo 'Committing…'
  git commit -m "$commit_msg" --no-verify || { echo 'Commit failed.'; echo '===== gitops done ====='; return 1; }
  echo 'Pulling latest with rebase…'
  git pull --rebase || { echo 'Pull with rebase failed.'; echo '===== gitops done ====='; return 1; }
  echo 'Pushing to remote…'
  git push || { echo 'Push failed.'; echo '===== gitops done ====='; return 1; }
  echo 'Git operations completed successfully.'
  echo '===== gitops done ====='
}

