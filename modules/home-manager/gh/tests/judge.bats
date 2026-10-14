#!/usr/bin/env bats

setup() {
  local here="$BATS_TEST_DIRNAME"
  export GH_GUARD_REAL_GH="$here/fakegh"
  export GH_GUARD_CURL="$here/fakecurl"
  export GH_GUARD_DENYLIST="$here/deny.txt"
  export GH_GUARD_ALLOWLIST="$here/no-allowlist.txt"
  export GH_GUARD_LOG="$BATS_TEST_TMPDIR/decisions.log"
  export GH_GUARD_JUDGE_PROMPT_FILE="$here/judge-prompt.txt"
  export GH_GUARD_LLM_USER_PATH="$BATS_TEST_TMPDIR/llm-config"
  export GH_GUARD_TEST_LLM_ARGS="$BATS_TEST_TMPDIR/llm-args"
  export GH_GUARD_TEST_LLM_INPUT="$BATS_TEST_TMPDIR/llm-input"
  export GH_GUARD_JUDGE_TIMEOUT=1
  export GH_GUARD_TEST_LLM_EXIT=0
  export GH_TOKEN=test-token GITHUB_TOKEN=test-token
  export OPENBAO_GH_CLAIM=dryvist/pub GH_REPO=dryvist/pub
  export PATH="$here/fakejudge:$PATH"
  : >"$GH_GUARD_LOG"
}

run_guard() {
  run bash "$BATS_TEST_DIRNAME/../scripts/gh-guard.sh" \
    issue create -R dryvist/pub --body "fix(auth): exercise judge parsing"
}

assert_tier() {
  local expected="$1" actual
  actual="$(awk -F '\t' 'END { print $2 }' "$GH_GUARD_LOG")"
  [ "$actual" = "$expected" ]
}

@test "judge allows exact allow verdict" {
  export GH_GUARD_TEST_LLM_OUTPUT=allow
  run_guard
  [ "$status" -eq 0 ]
  assert_tier clean
  grep -Fx -- "Test system prompt." "$GH_GUARD_TEST_LLM_ARGS"
  [ "$(cat "$GH_GUARD_TEST_LLM_INPUT")" = "fix(auth): exercise judge parsing" ]
  grep -Fx -- '  api_base: "http://127.0.0.1:11434/v1"' "$GH_GUARD_LLM_USER_PATH/extra-openai-models.yaml"
  grep -Fx -- '  api_key_name: openai' "$GH_GUARD_LLM_USER_PATH/extra-openai-models.yaml"
}

@test "judge blocks exact block verdict" {
  export GH_GUARD_TEST_LLM_OUTPUT=block
  run_guard
  [ "$status" -eq 1 ]
  assert_tier narrative
}

@test "judge blocks garbage output" {
  export GH_GUARD_TEST_LLM_OUTPUT='maybe allow'
  run_guard
  [ "$status" -eq 1 ]
  assert_tier narrative
}

@test "judge blocks empty output" {
  export GH_GUARD_TEST_LLM_OUTPUT=
  run_guard
  [ "$status" -eq 1 ]
  assert_tier narrative
}

@test "judge allows first line when a reason follows" {
  export GH_GUARD_TEST_LLM_OUTPUT=$' \tallow \r\nreason follows'
  run_guard
  [ "$status" -eq 0 ]
  assert_tier clean
}

@test "judge blocks uppercase verdict" {
  export GH_GUARD_TEST_LLM_OUTPUT=ALLOW
  run_guard
  [ "$status" -eq 1 ]
  assert_tier narrative
}

@test "judge blocks a failed llm invocation" {
  export GH_GUARD_TEST_LLM_OUTPUT=allow
  export GH_GUARD_TEST_LLM_EXIT=7
  run_guard
  [ "$status" -eq 1 ]
  assert_tier narrative
}
