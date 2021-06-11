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

Commits published to the `main` branch  will trigger an automated build for the each of the configured PHP version.
