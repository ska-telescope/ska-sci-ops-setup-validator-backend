#!/usr/bin/env bats

# Load a library from the `${BATS_TEST_DIRNAME}/test_helper' directory.
#
# Globals:
#   none
# Arguments:
#   $1 - name of library to load
# Returns:
#   0 - on success
#   1 - otherwise
load_lib() {
  local name="$1"
  load "../../scripts/${name}/load"
}

load_lib bats-support
load_lib bats-assert

@test "HELP: run help" {
    run make -f ../tests/Makefile
    echo "$output"
    [ $status -eq 0 ]
}

@test 'HELP: check help output contains a target from each .mk file' {
  # 'targets' has one target from each mk file, which matches a single
  # line in the help output.
  local -r targets="ansible-publish|cpp-build|helm-lint|python-build|raw-publish-all|k8s-install-chart|update-make-and-commit|oci-build-all|long-help|bump-major-release|rpm-package|bats-test|dev-vscode|conan-publish-all|docs-build"

  # Count the number of targets in 'targets'
  run bash -c "echo '${targets}' | sed 's=|= =g' | wc -w"
  local -r n_targets=${output}

  # Count the number of matches in the help output.
  local -r log_txt="${BATS_TEST_TMPDIR}/log.txt"
  {
    make -f ../tests/Makefile
  } > "${log_txt}"
  run bash -c "grep -E '${targets}' ${log_txt} | wc -l"
  local -r n_matches=${output}

  # Check that both values are equal.
  echo "Output: ${n_matches} matches for ${n_targets} targets."
  [[ ${n_matches} -eq ${n_targets} ]]
}
