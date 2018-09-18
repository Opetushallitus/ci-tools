
# CI tools

- **build:** Docker-kontin buildaamiseen liittyvät skriptit ja Dockerfilet. Näistä voi olla useita variantteja.
- **common:** Kaikille buildeille yleisiä CI-skriptejä mm. ECR-kirjautumiseen ja AWS-työkalujen asentamiseen.
- **run:** Kontin sisään kopioitavat sovelluksen käynnistävät run-skriptit

## Käyttöesimerkkejä

Perusesimerkkejä:

- [konfo-backend](https://github.com/Opetushallitus/konfo-backend/blob/e7a6f10de3abbe2a99b8075a8093883b765f980e/.travis.yml#L21-L34): Yksi fatjar, yksi kontti-image

Erikoistapauksia:

- [tarjonta](https://github.com/Opetushallitus/tarjonta/blob/ee227a485b64d1bdae2144c64cd81420ef825d14/.travis.yml#L17-L53): Buildi joka tuottaa yhden kontin jonka sisällä on useampi war, sekä api-artifaktin Artifactoryyn.
- [haku](https://github.com/Opetushallitus/haku/blob/a3a9340620a17870c9d4deed01b53bf90f7f2856/.travis.yml#L41-L56): Kaksi kontti-imagea samasta buildistä.
