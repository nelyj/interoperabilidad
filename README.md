# Interoperabilidad

- [Interoperabilidad](#interoperabilidad)
  - [Development setup](#development-setup)
    - [Requirements](#requirements)
    - [First run](#first-run)
  - [Production Setup](#production-setup)
    - [Deployment](#deployment)
      - [Run database migrations as first step](#run-database-migrations-as-first-step)
      - [Run workers separate from the web containers](#run-workers-separate-from-the-web-containers)
      - [Run the web containers](#run-the-web-containers)
    - [Details](#details)
    - [Managing and Upgrading Dependencies](#managing-and-upgrading-dependencies)
      - [Base Operative System & Ruby Version](#base-operative-system--ruby-version)
      - [System packages](#system-packages)
      - [NodeJS](#nodejs)
      - [Sway](#sway)
      - [PostgreSQL](#postgresql)
      - [Redis](#redis)
      - [Ruby Gems](#ruby-gems)

## Development setup

### Requirements

- Docker
- Make
- An [editorconfig](http://editorconfig.org) plugin for your editor of choice.
- Voltos for the shared ENV variables.

### First run

Note: Only tested on Mac OS X and Linux so far.

1. If you are using voltos, the firs step is to run `voltos use gobdigital-interoperabilidad` inside the project root folder.

    - To make things simpler, you can create a function inside your `.bashrc` or `.bashrc.local` and replace make with vmake in every command.

    ```bash
    function vmake(){
        voltos run make $1;
    }
    ```

1. Assuming you have a functional make and docker on your system, you only need to have a few credentials for external dependencies (Or use Voltos):

    - OpenID client id and secrets (provided by ClaveUnica.cl for this project)
    - AWS key and secret for S3 storage (you can use your own on development)
    - Document Signer key and secret (provided by SEGPRES for document signing)

    Those should be set as environment variables:

    ```bash
    export OP_CLIENT_ID=<our-clave-unica-client-id> OP_SECRET_KEY=<our-clave-unica-secret>

    export AWS_REGION=<aws-region> AWS_ACCESS_KEY_ID=<aws-key-id> AWS_SECRET_ACCESS_KEY=<aws-secret> S3_CODEGEN_BUCKET=<bucket-name>

    export SIGNER_API_TOKEN_KEY=<our-signer-key> SIGNER_API_SECRET=<our-signer-secret>
    ```

1. Set hostname alias `dev.interoperabilidad.digital.gob.cl` in the `/etc/hosts` file with the IP address `127.0.0.1`. By default this alias is configured in `OP_CALLBACK_URL` to login correctly with Clave Unica.

1. After those variables and host alias are set, you just need to run:

    ```bash
    make
    ````

    _...and go for coffee_

    This will take a while unless you have the right docker images cached.

    It will:

    1. Build the docker images for the different containers (Ruby environment, NodeJS environment, PostgreSQL), and fetch all dependencies.

    1. Create the PostgreSQL database and run database migrations.

    1. Run all docker containers.

 Note: The database migrations assumes that your postgres image have installed the "unaccent" extension, if you don't have it, install the postgresql-contrib package.

 Open http://dev.interoperabilidad.digital.gob.cl and you should see the application.

 If it doesn't work, take a look at the output of make and if everything looks OK then check `log/development.log` and `docker-compose logs` to debug the web application itself.

## Production Setup

Production should run the latest [`egob/interoperabilidad`](https://hub.docker.com/r/egob/interoperabilidad/) image from DockerHub. It is built from the master branch as part of the [continuous integration process](https://semaphoreci.com/continuum/interoperabilidad) (via `make production-build` plus some tagging). The image gives you a self-contained stateless web application that requires only some environment variables to run:

- `SECRET_KEY_BASE`: A random string that can be generated via `rails secret`. It should be the **same** for **every** instance running in production.

- `DATABASE_URL`: A pointer to the database (e.g: `postgres://myuser:mypass@localhost/somedatabase`).

- `REDIS_URL`: A pointer to the Redis instance (e.g: `redis://myuser:mypass@redis-host:6379`).

- `ISSUER_OIDC`: Is the URL for the issuer of ClaveUnica OpenID.

- `OP_CLIENT_ID`: Client ID to authenticate with https://www.claveunica.gob.cl/

- `OP_SECRET_KEY`: Client Secret to authenticate with https://www.claveunica.gob.cl/

- `OP_CALLBACK_URL`: URL for https://www.claveunica.gob.cl/ callback.

- `ROLE_SERVICE_URL`: URL for the Role Service.

- `ROLE_APP_ID`: APP_ID in the Role Service.

- `ROLLBAR_ACCESS_TOKEN`: Rollbar token, needed to log errors in production.

- `AWS_ACCESS_KEY_ID`: AWS Access Key, to use S3.

- `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key, to use S3.

- `AWS_REGION`: Region to use in S3 service.

- `S3_CODEGEN_BUCKET`: Pre-existing S3 Bucket where generated code (for API clients and server stubs) will be uploaded.

- `APP_HOST_URL`: Application host URL, for mailers use.

- `SMTP_ADDRESS`: SMTP server address.

- `SMTP_PORT`: SMTP server port.

- `SMTP_DOMAIN`: SMTP server domain.

- `SMTP_USER`: SMTP server user name.

- `SMTP_SECRET`: SMTP server password.

- `MINSEGPRES_DIPRES_ID`: ID of MINSEGPRES in the DIPRES.

- `SIGNER_APP_HOST`: URL for SIGNER API.

- `SIGNER_API_TOKEN_KEY`: Token Key to use SIGNER API.

- `SIGNER_API_SECRET`: Symmetric key to sign the JWT of the SIGNER API.

- `PROVIDER_CLIENT_TOKEN_EXPIRATION_IN_SECONDS`: Time to live for auth client tokens given to providers to use their own protected services.

- `AGREEMENT_CLIENT_TOKEN_EXPIRATION_IN_SECONDS`: Time to live for auth client tokens given to consumers after an agreement is signed to use protected services.

- `TRACEABILITY_ENDPOINT`: Address of the traceability dashboard.

- `TRAZABILIDAD_SECRET`: This secret is shared with `Plataforma de Interacciones` to check that it can access te endpoint containing traceability info.

- `URL_MOCK_SERVICE`: This is the Mock Service URL.

You can also set the `PORT` environment variable to change the port where the web server will listen (defaults to 80). See `config/puma.rb` for more options you can tune/override via environment variables.

Putting it all together, after building the image you can run it like this:

    docker run \
        -p 8888:80 \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
        -e REDIS_URL=redis://myuser:mypass@redis-host:6379 \
        -e OP_CLIENT_ID=MyClaveUnicaClientId \
        -e OP_SECRET_KEY=MyClaveUnicaSecretKey \
        -e OP_CALLBACK_URL=https://production.base.url.com \
        -e ROLE_SERVICE_URL=https://base.url.for.the.role.service.com \
        -e APP_ID=MyAppIdForTheRoleService \
        -e ROLLBAR_ACCESS_TOKEN=MyAccessTokenForRollbar \
        -e AWS_REGION=my-default-aws-region-for-s3 \
        -e AWS_ACCESS_KEY_ID=MyAWSAccessKeyId \
        -e AWS_SECRET_ACCESS_KEY=MyAWSSecretAccessKey \
        -e S3_CODEGEN_BUCKET=my-s3-bucket \
        # Etc, etc, more env variables here \
        egob/interoperabilidad

### Deployment

#### Run database migrations as first step

In addition to pulling the latest `egob/interoperabilidad` image from dockerhub and pointing the web load balancer to containers running the new image (as described above), a new release might include database changes. Those changes must be executed **before** spinning the new containers, and you can do that using the same new image but with a explicit `bundle exec rake db:create db:migrate` command. Here is a full command line example:

    docker run \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
        -e REDIS_URL=redis://myuser:mypass@redis-host:6379 \
        -e OP_CLIENT_ID=MyClaveUnicaClientId \
        -e OP_SECRET_KEY=MyClaveUnicaSecretKey \
        -e OP_CALLBACK_URL=https://production.base.url.com \
        -e ROLE_SERVICE_URL=https://base.url.for.the.role.service.com \
        -e APP_ID=MyAppIdForTheRoleService \
        -e ROLLBAR_ACCESS_TOKEN=MyAccessTokenForRollbar \
        -e AWS_REGION=my-default-aws-region-for-s3 \
        -e AWS_ACCESS_KEY_ID=MyAWSAccessKeyId \
        -e AWS_SECRET_ACCESS_KEY=MyAWSSecretAccessKey \
        -e S3_CODEGEN_BUCKET=my-s3-bucket \
        # Etc, etc, more env variables here \
        egob/interoperabilidad \
        bundle exec rake db:create db:migrate

You can also add the `--rm` flag to this command to remove this disposable container right after it executes.

#### Run workers separate from the web containers

The web containers will enqueue background jobs into a queue stored in redis. In order to process this queue, one or more worker processes must be run. The worker processes can be run using the same docker image but with a explicit `bundle exec sidekiq` command. Here is a full command line example:

    docker run \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
        -e REDIS_URL=redis://myuser:mypass@redis-host:6379 \
        -e OP_CLIENT_ID=MyClaveUnicaClientId \
        -e OP_SECRET_KEY=MyClaveUnicaSecretKey \
        -e OP_CALLBACK_URL=https://production.base.url.com \
        -e ROLE_SERVICE_URL=https://base.url.for.the.role.service.com \
        -e APP_ID=MyAppIdForTheRoleService \
        -e ROLLBAR_ACCESS_TOKEN=MyAccessTokenForRollbar \
        -e AWS_REGION=my-default-aws-region-for-s3 \
        -e AWS_ACCESS_KEY_ID=MyAWSAccessKeyId \
        -e AWS_SECRET_ACCESS_KEY=MyAWSSecretAccessKey \
        -e S3_CODEGEN_BUCKET=my-s3-bucket \
        # Etc, etc, more env variables here \
        egob/interoperabilidad \
        bundle exec sidekiq

#### Run the web containers

Don't forget to run the docker image with all the env variables and without special command in one or more machines and point a load balancer to it :smiley: .

### Details

As mentioned before, changes on the master branch are built, tested, and pushed to DockerHub dockerhub automatically by the CI pipeline. Here are the details on how that is done, in case we change the CI platform or need to push an image manually (although this is NOT recommended because you lose traceability from the binaries you are running to the source code used to build those binaries).

The building steps run by the CI pipeline (which is assumed to have a functional docker environment) are:

    make build
    make db
    make test

If all the above passes without errors the following steps are followed to build the docker image and push it to DockerHub:

    make production-build

    docker tag egob/interoperabilidad:latest egob/interoperabilidad:v1.$SEMAPHORE_BUILD_NUMBER

    docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

    docker push egob/interoperabilidad

You have to set the `DOCKER_*` environment variables to a user with permissions to push images to the `egob/interoperabilidad` at DockerHub.

Also note that the above uses the Semaphore's build number to set the version to "1.xxx" where xxx is such build number. If a new CI system is used, you should bump the major version. (ej: "2.yyy" where yyy is Jenkin's build number in a new CI setup based on Jenkins).

### Managing and Upgrading Dependencies

With development, CI, and production all based on Docker, you don't need anything special to run this application other than `make`, `docker` and `docker-compose` (the latest only required on dev and CI).

While the dependencies are all encapsulated, it might be necessary to upgrade this dependencies in case of new features or security patches. Here is the detail of such dependencies and where they are specified (in case you want to specify a new one or upgrade an existing one).

#### Base Operative System & Ruby Version

The base Docker image is specified on `Dockerfile.production` and `Dockerfile.development`. Both versions should be keep in sync. Also, the `bundle_cache` service on `docker-compose.yml` should use the same base image.

#### System packages

System packages are installed via `apt-get` on the `Dockerfile.production` and `Dockerfile.development` files. Both files are mostly identical, except for the way in which the applicaton itself is built into the image (After the line that says `#Our app:` ). If you need to add a new production dependency which is a system package, it should be added to both Dockerfiles.

#### NodeJS

Node is installed from binaries fetched from the official distribution (not system packages). It is also specified on both `Dockerfile.production` and `Dockerfile.development` and should be keep in sync.

#### Sway

A customized version of the nodejs sway packaged is used. The specific repository and commit are specified on both `Dockerfile.production` and `Dockerfile.development`. If a new version of sway should be used, both files should be changed in sync.

#### PostgreSQL

On development, the version of the PostgreSQL docker image is specified on the `postgresql` service inside `docker-compose.yml`. If a new version is going to be run in production, the development version should also be changed there.

#### Redis

On development, the version of the Redis docker image is specified on the `redis` service inside `docker-compose.yml`. If a new version is going to be run in production, the development version should also be changed there.

#### Ruby Gems

As with any modern Ruby application, all Ruby libraries used by the application are specified in the `Gemfile` while the specific versions are automatically compiled by the `bundle` command into the `Gemfile.lock` file. If you want to upgrade a particular library while keeping the general specification in the `Gemfile`, use the `bundle update <gem-name>` command. If you want to do a major upgrade of a particular component (for example, migrating to a major version of Rails) you will need to change the `Gemfile`.
