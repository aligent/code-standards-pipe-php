# Aligent Magento Code Standards Pipe

This pipe is used to perform code standards checks on Magento applciations

## YAML Definition

Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:

```yaml
script:
  - pipe: aligent/code-standards-pipe-php:7.4
    variables:
      # STANDARDS: "Magento2" # Optional
      # DEBUG: "<boolean>" # Optional
```
## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| STANDARDS             | The PHPCS standards to run (Security checks will always be run |
| DEBUG                 | Turn on extra debug information. Default: `false`. |
