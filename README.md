# Aligent Magento Code Standards Pipe

This pipe is used to perform PHP code standards checks.

## YAML Definition

Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:

```yaml
script:
  - pipe: aligent/code-standards-pipe-php:<PHP VERSION>
    variables:
      # STANDARDS: "Magento2" # Optional
      # DEBUG: "<boolean>" # Optional
```
## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| STANDARDS             | The PHPCS standards to run (Security checks will always be run |
| DEBUG                 | Turn on extra debug information. Default: `false`. |

## Development

This repository contains a branch for each supported PHP version.
Commits published to these branches will trigger an automated build for the accompanying PHP version.
