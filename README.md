:warning: **Warning:** This repository is public, do not put secrets in these files!

# CI tools

This repository contains helper scripts that are downloaded and executed during the builds. Used to unify the build process of dozens of services.

- **build:** Scripts and Dockerfiles for producing a container image. Several variants for different use cases.
- **common:** Scripts common for all builds, for logging in to ECR, install AWS tools etc.
- **run:** Scripts that are copied inside the container image, the ones that are invoked when the container is run.

## Usage examples

Basic use cases:

- [konfo-backend](https://github.com/Opetushallitus/konfo-backend/blob/bec81fdee21ed6df1d5e3b34cde0ccf039bcac2a/.travis.yml): Single (clojure) fatjar in a single container image
- [hakurekisteri](https://github.com/Opetushallitus/hakurekisteri/blob/9bdbb707f281e2d40df8f5c726a443763b0b2c4c/.travis.yml#L7-L16): Postgre database for unit tests

Special cases:

- [tarjonta](https://github.com/Opetushallitus/tarjonta/blob/ee227a485b64d1bdae2144c64cd81420ef825d14/.travis.yml#L17-L53): A build that provides one container image that contains several war files, as well as uploads an API artifact into Artifactory.
- [haku](https://github.com/Opetushallitus/haku/blob/a3a9340620a17870c9d4deed01b53bf90f7f2856/.travis.yml#L41-L56): Two container images from the same build.
- [ataru](https://github.com/Opetushallitus/ataru/blob/c85ffbce977086aeb05655db8aaf89322f4dbc56/.travis.yml): Two container images from the same build.
