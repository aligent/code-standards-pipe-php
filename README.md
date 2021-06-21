# Aligent Magento Code Standards Pipe

This pipe is used to perform PHP code standards checks.

## YAML Definition

Add the following your `bitbucket-pipelines.yml` file:

```yaml
      - step:
          name: "Code Standards check"
          script:
            - pipe: aligent/code-standards-pipe-php:7.4
              variables:
                STANDARDS: "Magento2"
                MAGENTO_USER: "USER"
                MAGENTO_PASS: "PASS"
```
## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| STANDARDS             | The PHPCS standards to run (Security checks will always be run |
| DEBUG                 | (Optional) Turn on extra debug information. Default: `false`. |
| MAGENTO_USER          | (Optional) Injects repo.magento.com user into auth.json |
| MAGENTO_PASS          | (Optional) Injects repo.magento.com password into auth.json|

## Development

Commits published to the `main` branch  will trigger an automated build for the each of the configured PHP version.
