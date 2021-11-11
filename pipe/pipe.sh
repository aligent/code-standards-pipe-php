#!/usr/bin/env bash
#
set -e

source "$(dirname "$0")/common.sh"

validate() {
     DEBUG=${DEBUG:=false}
     SKIP_DEPENDENCIES=${SKIP_DEPENDENCIES:=false}
     STANDARDS=${STANDARDS:="Security"}
}

setup_ssh_creds() {
     # Setup pipeline SSH 
     INJECTED_SSH_CONFIG_DIR="/opt/atlassian/pipelines/agent/ssh"
     IDENTITY_FILE="${INJECTED_SSH_CONFIG_DIR}/id_rsa_tmp"
     KNOWN_SERVERS_FILE="${INJECTED_SSH_CONFIG_DIR}/known_hosts"
     if [ ! -f ${IDENTITY_FILE} ]; then
          info "No default SSH key configured in Pipelines.\n These are required to install internal composer packages. \n These should be generated in bitbucket settings at Pipelines > SSH Keys."
          return
     fi
     mkdir -p ~/.ssh
     touch ~/.ssh/authorized_keys
     cp ${IDENTITY_FILE} ~/.ssh/pipelines_id

     if [ ! -f ${KNOWN_SERVERS_FILE} ]; then
          fail "No SSH known_hosts configured in Pipelines."
     fi
     cat ${KNOWN_SERVERS_FILE} >> ~/.ssh/known_hosts
     if [ -f ~/.ssh/config ]; then
          debug "Appending to existing ~/.ssh/config file"
     fi
     echo "IdentityFile ~/.ssh/pipelines_id" >> ~/.ssh/config
     chmod -R go-rwx ~/.ssh/
}

inject_composer_creds() {
     if [[ -z "${MAGENTO_USER}" ]] | [[ -z "${MAGENTO_PASS}" ]]; then
          info "No Magento Composer details configured. Skiping."
     else
          echo "Injecting Magento Composer credentials into auth.json"
          jq '."http-basic"."repo.magento.com".username = env.MAGENTO_USER | ."http-basic"."repo.magento.com".password = env.MAGENTO_PASS | del(."github-oauth")' auth.json.sample > auth.json
          if $DEBUG; then
               echo "auth.json"
               cat auth.json
          fi
     fi
}


install_composer_dependencies() {
     echo "Installing composer dependencies"
     composer install --dev
}

run_standards_checks() {
     debug "Testing modified files in this branch..."

     TARGET_BRANCH='origin/master'
     if [ -n "$BITBUCKET_PR_DESTINATION_BRANCH" ]; then
          TARGET_BRANCH="origin/$BITBUCKET_PR_DESTINATION_BRANCH"
     fi

     if $DEBUG; then
          echo "State of working directory"
          git status
     fi

     echo "Comparing HEAD against branch $TARGET_BRANCH"
     MERGE_BASE=$(git merge-base HEAD $TARGET_BRANCH)

     CHANGED_FILES=$(git diff --relative --name-only --diff-filter=AM $MERGE_BASE -- '*.php' '*.phtml')

     echo "Comparing HEAD against merge base $MERGE_BASE"
     if [ ! -z "$EXCLUDE_EXPRESSION" ]; then
          EXCLUDED_FILES=$(echo $CHANGED_FILES | tr " " "\n" | grep -E $EXCLUDE_EXPRESSION) || true
          CHANGED_FILES=$(echo $CHANGED_FILES | tr " " "\n" | grep -vE $EXCLUDE_EXPRESSION) || true
          echo "Excluding files:"
          echo $EXCLUDED_FILES
     fi

     if [ -z "$CHANGED_FILES" ]; then
          echo "No changed files to scan"
     else
          debug "Changed files: "
          debug $CHANGED_FILES
          mkdir -p test-results

          /composer/vendor/bin/phpcs --report=junit \
               --standard=${STANDARDS},Security $CHANGED_FILES > test-results/phpcs.xml || /composer/vendor/bin/phpcs --standard=${STANDARDS},Security $CHANGED_FILES && echo "No violations found"
     fi

     if [[ "$?" == "0" ]]; then
          success "Success!"
     else
          fail "Error!"
     fi
}

validate
if [ $SKIP_DEPENDENCIES = false ]; then
     setup_ssh_creds
     inject_composer_creds
     install_composer_dependencies
fi
run_standards_checks
