# Docker environment
Prerequisites
-----
You will require:

- Docker engine for your platfom ([Windows](https://docs.docker.com/docker-for-windows/) [Linux](https://docs.docker.com/engine/installation/#/on-linux) [Mac](https://docs.docker.com/docker-for-mac/install/))
- [Docker-compose](https://docs.docker.com/compose/install/)
- Git client
- [Make](https://en.wikipedia.org/wiki/Make_(software))
- [OpenSSL](https://www.openssl.org/)

Deployment steps
-----
 * Clone the Docker repo:

```
git clone \
... \
&& cd Umbrella-corp-site-docker
```

 * create .env file from dist: `cp .env.dist .env`
 * Insert ALL values in `.env` file (NOTICE: .env file is hiden.);
 * If you need access to ports for debuging, please uncomment port section in [docker-compose file]()
 * If you need access to DB via phpMyAdmin, please uncommect correspondent section in docker-compose.yml file
 * If you have real SSL certificates put them in ./nginx/ssl directory and make corrections in nginx configfile (place proper filenames).
 * Start spinup scenario

```
make docker-env
```
 
 * For additional commands
 
```
make help
```
