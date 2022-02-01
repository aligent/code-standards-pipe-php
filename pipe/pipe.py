#!/usr/bin/env python3

from operator import sub
import os
import shutil
from sre_constants import SUCCESS
import subprocess
from sys import stdout
import sys
import uuid
from bitbucket import Bitbucket
from bitbucket_pipes_toolkit import Pipe, get_logger


logger = get_logger()
schema = {
        'MAGENTO_USER': {'type': 'string', 'required': False},
        'MAGENTO_PASS': {'type': 'string', 'required': False},
        'SKIP_DEPENDENCIES': {'type': 'string', 'required': False},
        'STANDARDS': {'type': 'string', 'required': False},
        'EXCLUDE_EXPRESSION': {'type': 'string', 'required': False},
        }


class PHPCodeStandards(Pipe):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.magento_user = self.get_variable('MAGENTO_USER')
        self.magento_password = self.get_variable('MAGENTO_PASSWORD')
        self.skip_dependencies = self.get_variable(
            'SKIP_DEPENDENCIES') if self.get_variable('SKIP_DEPENDENCIES') else False
        self.standards = f"Security,{self.get_variable('STANDARDS')}" if self.get_variable('STANDARDS') else 'Security'
        self.exclude_expression = self.get_variable('EXCLUDE_EXPRESSION')

    def setup_ssh_credentials(self):
        injected_ssh_config_dir = "/opt/atlassian/pipelines/agent/ssh"
        identity_file = f"{injected_ssh_config_dir}/id_rsa_tmp"
        known_servers_file = f"{injected_ssh_config_dir}/known_hosts"

        if not os.path.exists(identity_file):
            self.fail(message="No default SSH key configured in Pipelines.\n These are required to install internal composer packages. \n These should be generated in bitbucket settings at Pipelines > SSH Keys.")

        if not os.path.exists(known_servers_file):
            self.fail(message="No SSH known_hosts configured in Pipelines.")

        os.mkdir(os.path.expanduser("~/.ssh"))

        shutil.copy(identity_file, "~/.ssh/pipelines_id")

        # Read contents of pipe-injected known hosts and pipe into ~/.ssh/known_hosts
        with open(known_servers_file) as pipe_known_host_file:
            with open("~/.ssh/known_hosts", 'a') as known_host_file:
                for line in pipe_known_host_file:
                    known_host_file.write(line)

        with open("~/.ssh/config", 'a') as config_file:
            config_file.write("IdentityFile ~/.ssh/pipelines_id")

        composer_auth_update = subprocess.run(
            ["chmod", "-R", "go-rwx", "~/.ssh/"])

    def inject_composer_credentials(self):
        if not self.magento_user or not self.magento_password:
          self.log_info("No Magento Composer details configured. Skiping.")
          return

        self.log_debug("Injecting Magento Composer credentials into auth.json")

        composer_auth_update_command = [
            "jq", "'.\"http-basic\".\"repo.magento.com\".username = env.MAGENTO_USER | .\"http-basic\".\"repo.magento.com\".password = env.MAGENTO_PASS | del(.\"github-oauth\")'", "auth.json.sample", ">", "auth.json"]

        composer_auth_update = subprocess.run(composer_auth_update_command)
        composer_auth_update.check_returncode()

    def run_code_standards_check(self):
        target_branch = "origin/main"
        if os.getenv("BITBUCKET_PR_DESTINATION_BRANCH"):
            target_branch = f"origin/{os.getenv('BITBUCKET_PR_DESTINATION_BRANCH')}"

        self.log_info(f"Comparing HEAD against branch {target_branch}")

        # Output is termianted with newline char, remove it.
        merge_base = subprocess.check_output(["git",
                                              "merge-base",
                                              "HEAD",
                                              target_branch
                                              ]).decode(sys.stdout.encoding)[:-1]

        changed_files = subprocess.check_output(["git",
                                                "diff",
                                                "--relative",
                                                "--name-only",
                                                "--diff-filter=AM",
                                                merge_base,
                                                "--",
                                                "*.php",
                                                "*.phtml"
                                            ]).decode(sys.stdout.encoding)[:-1].split('\n')


        self.log_info(f"Comparing HEAD against merge base {merge_base}")
        if self.exclude_expression:
            import re
            def filter_paths(path):
                match = re.search(self.exclude_expression, path)
                if match:
                    self.log_info(f"Excluding: {path}")
                return False if match else True

            changed_files = list(filter(filter_paths, changed_files))

        if not changed_files:
            self.success("No changed files to scan", do_exit=True)
        
        if not os.path.exists("test-results"):
            os.mkdir("test-results")
        
        phpcs_command = ["/composer/vendor/bin/phpcs",
                        "--report=junit",
                        f"--standard={self.standards}"
                        ] + changed_files
                        
        phpcs = subprocess.run(phpcs_command,stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        self.standards_failure = False if phpcs.returncode == 0 else True 

        if self.standards_failure:
            phpcs_output = phpcs.stdout
        else: 
            phpcs_output = phpcs.stderr


        with open("test-results/phpcs.xml", 'a') as output_file:
            output_file.write(phpcs_output)

    def composer_install(self):
        composer_install_command= ["composer", "install", "--dev"]
        composer_install= subprocess.run(composer_install_command)
        composer_install.check_returncode()

    def run(self):
        super().run()
        self.setup_ssh_credentials()
        self.inject_composer_credentials()
        self.composer_install()
        self.run_code_standards_check()

        if self.standards_failure:
            self.fail(message=f"Failed code standards test")
        else:
            self.success(message=f"Passed code standards test")



if __name__ == '__main__':
    pipe= PHPCodeStandards(schema=schema, logger=logger)
    pipe.run()
