# Development setup

## Requirements

- Docker
- Make
- An [editorconfig](http://editorconfig.org) plugin for your editor of choice.

## First run

Note: Only tested on Mac OS X so far.

Assuming you have a functional make and docker on your system, just go to the project root and type:

    $ make

...and go for coffee — it will take a while unless you have the right docker images cached. It will:

1. Build the docker images for the different containers (Ruby environment, NodeJS environment, PostgreSQL), and fetch all dependencies.

2. Create the PostgreSQL database and run database migrations.

3. Run all docker containers.

4. Open the application home page in your browser.

Usually the Rails web server will still be booting when the last step of the list above is executed. So you might get an error page opened on your browser. Just reload the page and it should work.

(If it doesn't, take a look at the output of make and if everything looks OK then check `log/development.log` to debug the web application itself)

# Production setup

Building the `Dockerfile.production` image (via `make production-build`) is a first stab at production deployment. It gives you a self-contained stateless web application that requires only a some environment variables to run:

- `SECRET_KEY_BASE`: A random string that can be generated via `rails secret`. It should be the *same* for *every* instance running in production.

- `DATABASE_URL`: A pointer to the database (e.g: `postgres://myuser:mypass@localhost/somedatabase`).

You can also set the `PORT` environment variable to change the port where the web server will listen (defaults to 80). See `config/puma.rb` for more options you can tune/override via environment variables.

Putting it all together, after building the image you can run it like this:

    $ docker run \
        -p 8888:80 \
        -e SECRET_KEY_BASE=myprecioussecret \
        -e DATABASE_URL=postgres://user:password@host/database \
        interoperabilidad
