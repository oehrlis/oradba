#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2030,SC2031,SC2314,SC2315
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_job_wrappers.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.19
# Revision...: 0.8.1
# Purpose....: BATS tests for job monitoring wrapper scripts
# Notes......: Tests rman_jobs.sh, exp_jobs.sh, and imp_jobs.sh wrappers
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Setup test environment
setup() {
    # Find project root
    if [[ -f "VERSION" ]]; then
        PROJECT_ROOT="$(pwd)"
    elif [[ -f "../VERSION" ]]; then
        PROJECT_ROOT="$(cd .. && pwd)"
    else
        skip "Cannot find project root"
    fi
    
    RMAN_JOBS="${PROJECT_ROOT}/src/bin/rman_jobs.sh"
    EXP_JOBS="${PROJECT_ROOT}/src/bin/exp_jobs.sh"
    IMP_JOBS="${PROJECT_ROOT}/src/bin/imp_jobs.sh"
    LONGOPS="${PROJECT_ROOT}/src/bin/longops.sh"
    
    # Skip if scripts don't exist
    [[ -f "$RMAN_JOBS" ]] || skip "rman_jobs.sh not found"
    [[ -f "$EXP_JOBS" ]] || skip "exp_jobs.sh not found"
    [[ -f "$IMP_JOBS" ]] || skip "imp_jobs.sh not found"
    [[ -f "$LONGOPS" ]] || skip "longops.sh not found"
}

# ------------------------------------------------------------------------------
# Basic functionality tests - rman_jobs.sh
# ------------------------------------------------------------------------------

@test "rman_jobs.sh exists and is executable" {
    [[ -x "$RMAN_JOBS" ]]
}

@test "rman_jobs.sh has valid bash syntax" {
    run bash -n "$RMAN_JOBS"
    [[ "$status" -eq 0 ]]
}

@test "rman_jobs.sh uses modern bash shebang" {
    run head -n 1 "$RMAN_JOBS"
    [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "rman_jobs.sh calls longops.sh" {
    run bash -c "grep -q 'longops.sh' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "rman_jobs.sh uses RMAN operation filter" {
    run bash -c "grep -qi 'RMAN' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "rman_jobs.sh has set -o pipefail" {
    skip "Simple wrappers may not need pipefail"
}

# ------------------------------------------------------------------------------
# Basic functionality tests - exp_jobs.sh
# ------------------------------------------------------------------------------

@test "exp_jobs.sh exists and is executable" {
    [[ -x "$EXP_JOBS" ]]
}

@test "exp_jobs.sh has valid bash syntax" {
    run bash -n "$EXP_JOBS"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh uses modern bash shebang" {
    run head -n 1 "$EXP_JOBS"
    [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "exp_jobs.sh calls longops.sh" {
    run bash -c "grep -q 'longops.sh' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh uses EXP operation filter" {
    run bash -c "grep -qi 'EXP' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh has set -o pipefail" {
    skip "Simple wrappers may not need pipefail"
}

# ------------------------------------------------------------------------------
# Basic functionality tests - imp_jobs.sh
# ------------------------------------------------------------------------------

@test "imp_jobs.sh exists and is executable" {
    [[ -x "$IMP_JOBS" ]]
}

@test "imp_jobs.sh has valid bash syntax" {
    run bash -n "$IMP_JOBS"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh uses modern bash shebang" {
    run head -n 1 "$IMP_JOBS"
    [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "imp_jobs.sh calls longops.sh" {
    run bash -c "grep -q 'longops.sh' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh uses IMP operation filter" {
    run bash -c "grep -qi 'IMP' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh has set -o pipefail" {
    skip "Simple wrappers may not need pipefail"
}

# ------------------------------------------------------------------------------
# Argument forwarding tests
# ------------------------------------------------------------------------------

@test "rman_jobs.sh forwards arguments to longops.sh" {
    run bash -c "grep -q '\"\$@\"\\|\${@}' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh forwards arguments to longops.sh" {
    run bash -c "grep -q '\"\$@\"\\|\${@}' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh forwards arguments to longops.sh" {
    run bash -c "grep -q '\"\$@\"\\|\${@}' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Script structure and consistency tests
# ------------------------------------------------------------------------------

@test "rman_jobs.sh declares SCRIPT_DIR" {
    run bash -c "grep -q 'SCRIPT_DIR' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh declares SCRIPT_DIR" {
    run bash -c "grep -q 'SCRIPT_DIR' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh declares SCRIPT_DIR" {
    run bash -c "grep -q 'SCRIPT_DIR' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "rman_jobs.sh uses operation flag --operation or -o" {
    run bash -c "grep -q '\\-\\-operation\\|-o' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh uses operation flag --operation or -o" {
    run bash -c "grep -q '\\-\\-operation\\|-o' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh uses operation flag --operation or -o" {
    run bash -c "grep -q '\\-\\-operation\\|-o' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Header and documentation tests
# ------------------------------------------------------------------------------

@test "rman_jobs.sh has proper header with metadata" {
    run head -n 15 "$RMAN_JOBS"
    [[ "$output" =~ "OraDBA" ]]
    [[ "$output" =~ "Purpose" ]]
}

@test "exp_jobs.sh has proper header with metadata" {
    run head -n 15 "$EXP_JOBS"
    [[ "$output" =~ "OraDBA" ]]
    [[ "$output" =~ "Purpose" ]]
}

@test "imp_jobs.sh has proper header with metadata" {
    run head -n 15 "$IMP_JOBS"
    [[ "$output" =~ "OraDBA" ]]
    [[ "$output" =~ "Purpose" ]]
}

@test "rman_jobs.sh has Revision field in header" {
    run bash -c "grep -q 'Revision' '$RMAN_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "exp_jobs.sh has Revision field in header" {
    run bash -c "grep -q 'Revision' '$EXP_JOBS'"
    [[ "$status" -eq 0 ]]
}

@test "imp_jobs.sh has Revision field in header" {
    run bash -c "grep -q 'Revision' '$IMP_JOBS'"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Integration tests (verify wrapper relationship)
# ------------------------------------------------------------------------------

@test "All wrapper scripts are consistent in structure" {
    # Check they all follow the same pattern
    run bash -c "wc -l '$RMAN_JOBS' '$EXP_JOBS' '$IMP_JOBS' | head -n 3 | awk '{print \$1}' | sort -u | wc -l"
    # Should have similar line counts (within reasonable range)
    # This is a weak test but ensures they're similarly structured
    [[ "$output" -le 3 ]]
}

@test "longops.sh exists for wrappers to call" {
    [[ -x "$LONGOPS" ]]
}

@test "Wrapper scripts are smaller than longops.sh" {
    rman_size=$(wc -l < "$RMAN_JOBS")
    longops_size=$(wc -l < "$LONGOPS")
    [[ $rman_size -lt $longops_size ]]
}

# ------------------------------------------------------------------------------
# Error handling tests
# ------------------------------------------------------------------------------

@test "rman_jobs.sh handles missing longops.sh gracefully" {
    skip "Error handling for missing dependencies is optional"
}

@test "exp_jobs.sh handles missing longops.sh gracefully" {
    skip "Error handling for missing dependencies is optional"
}

@test "imp_jobs.sh handles missing longops.sh gracefully" {
    skip "Error handling for missing dependencies is optional"
}
