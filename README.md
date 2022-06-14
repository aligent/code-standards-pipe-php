# Aligent Magento Code Standards Pipe


This pipe is used to perform PHP code standards checks.

## YAML Definition

Add the following your `bitbucket-pipelines.yml` file:

```yaml
      - step:
          name: "Code Standards check"
          script:
            - pipe: docker://aligent/code-standards-pipe-php:7.4
              variables:
                STANDARDS: "Magento2"
                SKIP_DEPENDENCIES: "true"
                MAGENTO_USER: "USER"
                MAGENTO_PASS: "PASS"
```

### Github Actions
This pipe has partial support for Github actions. Please ensure that `SKIP_DEPENDENCIES` = `true`, and that the PHP version
is correct for your project.

Create the following file as `.github/workflows/phpcs.yml`.

```yaml
name: Run PHP Code Style

on: pull_request
  
jobs:
  code-standards:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Code Standards Test
        uses: docker://aligent/code-standards-pipe-php:8.1
        env:
          STANDARDS: "Magento2"
          SKIP_DEPENDENCIES: "true"
```

## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| STANDARDS             | The PHPCS standards to run (Security checks will always be run) |
| DEBUG                 | (Optional) Turn on extra debug information. Default: `false`. |
| SKIP_DEPENDENCIES     | (Optional) Skip installing project composer dependencies. Default: `false`. For Github actions this should be set to `true`. |
| MAGENTO_USER          | (Optional) Injects repo.magento.com user into auth.json |
| MAGENTO_PASS          | (Optional) Injects repo.magento.com password into auth.json|
| EXCLUDE_EXPRESSION    | (Optional) A grep [regular expression](https://www.gnu.org/software/grep/manual/html_node/Basic-vs-Extended.html) to exclude files from standards testing|

## Local use
An intermediate build target `standards-runtime` is available which does not include the Bitbucket specific pip aspects. This essentially just provides a runtime for PHPCS which can be used by CLI tools and IDE integrations.


## Development

The following command can be used to invoke the pipe locally:
```
docker run -v $PWD:/build --workdir=/build aligent/code-standards-pipe-php:<PHP_VERSION>
```

Commits published to the `main` branch  will trigger an automated build for the each of the configured PHP version.
Commits to `staging` will do the same but image tags will be suffixed with `-experimiental`.
