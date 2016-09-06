# Development setup

## Requirements

- Docker
- Make
- An [editorconfig](http://editorconfig.org) plugin for your editor of choice.

## First run

Note: Only tested on Mac OS X and Linux so far.

Assuming you have a functional make and docker on your system, you only need to have
a few credentials for external dependencies:

- OpenID client id and secrets (provided by ClaveUnica.cl for this project)
- AWS key and secret for S3 storage (you can use your own on development)
- Document Signer key and secret (provided by SEGPRES for document signing)

Those should be set as environment variables:

    $ export OP_CLIENT_ID=<our-clave-unica-client-id> OP_SECRET_KEY=<our-clave-unica-secret>
    $ export AWS_REGION=<aws-region> AWS_ACCESS_KEY_ID=<aws-key-id> AWS_SECRET_ACCESS_KEY=<aws-secret> S3_CODEGEN_BUCKET=<bucket-name>
    $ export SIGNER_API_TOKEN_KEY=<our-signer-key> SIGNER_API_SECRET=<our-signer-secret>

After those variables are set, you just need to run:

    $ make

...and go for coffee — it will take a while unless you have the right docker images cached. It will:

1. Build the docker images for the different containers (Ruby environment, NodeJS environment, PostgreSQL), and fetch all dependencies.

2. Create the PostgreSQL database and run database migrations.

3. Run all docker containers.

Note: The database migrations assumes that your postgres image have installed the "unaccent" extension, if you don't have it, install the postgresql-contrib package.

If you are on Mac OS X, you can now run `make mac-open` to auto-discover the IP of your docker machine and open a browser pointing to the web server. (If it doesn't work, take a look at the output of make and if everything looks OK then check `log/development.log` and `docker-compose logs` to debug the web application itself)

# Production setup

Production should run the latest [`egob/interoperabilidad`](https://hub.docker.com/r/egob/interoperabilidad/) image from DockerHub. It is built from the master branch as part of the [continuous integration process](https://semaphoreci.com/continuum/interoperabilidad) (via `make production-build` plus some tagging). The image gives you a self-contained stateless web application that requires only some environment variables to run:

- `SECRET_KEY_BASE`: A random string that can be generated via `rails secret`. It should be the *same* for *every* instance running in production.

- `DATABASE_URL`: A pointer to the database (e.g: `postgres://myuser:mypass@localhost/somedatabase`).

- `OP_CLIENT_ID`: Client ID to authenticate with https://www.claveunica.gob.cl/

- `OP_SECRET_KEY`: Client Secret to authenticate with https://www.claveunica.gob.cl/

- `OP_CALLBACK_URL`: URL for https://www.claveunica.gob.cl/ callback

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

- `MINSEGPRES_DIPRES_ID`: ID of MINSEGPRES in the DIPRES

- `SIGNER_APP_HOST`: URL for SIGNER API.

- `SIGNER_API_TOKEN_KEY`: Token Key to use SIGNER API.

- `SIGNER_API_SECRET`: Symmetric key to sign the JWT of the SIGNER API.

- `PROVIDER_CLIENT_TOKEN_EXPIRATION_IN_SECONDS`: Time to live for auth client tokens given to providers to use their own protected services.

- `AGREEMENT_CLIENT_TOKEN_EXPIRATION_IN_SECONDS`: Time to live for auth client tokens given to consumers after an agreement is signed to use protected services.

You can also set the `PORT` environment variable to change the port where the web server will listen (defaults to 80). See `config/puma.rb` for more options you can tune/override via environment variables.

Putting it all together, after building the image you can run it like this:

    $ docker run \
        -p 8888:80 \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
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


## Deployment

In addition to pulling the latest `egob/interoperabilidad` image from dockerhub and pointing the web load balancer to containers running the new image (as described above), a new release might include database changes. Those changes must be executed **before** spinning the new containers, and you can do that using the same new image but with a explicit `bundle exec rake db:create db:migrate` command. Here is a full command line example:

    $ docker run \
        -p 8888:80 \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
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
