# Aligent Magento Code Standards Pipe


This pipe is used to perform PHP code standards checks.

## YAML Definition

Add the following your `bitbucket-pipelines.yml` file:

```yaml
      - step:
          name: "Code Standards check"
          script:
            - pipe: docker://ghcr.io/aligent/code-standards-pipe-php:8.4
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
        uses: docker://ghcr.io/aligent/code-standards-pipe-php:8.4
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
docker run -v $PWD:/build --workdir=/build ghcr.io/aligent/code-standards-pipe-php:<PHP_VERSION>
```

## CI/CD

Docker images are built and pushed to GitHub Container Registry (`ghcr.io/aligent/code-standards-pipe-php`) via GitHub Actions
(`.github/workflows/docker-build.yml`, using the shared `aligent/workflows` Docker build workflow). The workflow:

- Builds every configured PHP version, as both the full pipe image (`<PHP_VERSION>`) and the `standards-runtime` target (`<PHP_VERSION>-runtime`)
- Pushes images on commits to `main`; commits to `staging` push tags suffixed with `-experimental`
- Builds without pushing on pull requests
- Can be triggered manually

### Required Variables

| Variable | Description |
|----------|-------------|
| `ALPINE_VERSION` | Alpine version of the upstream `php:<PHP_VERSION>-alpine<ALPINE_VERSION>` image. The build fails if it is not set. |
