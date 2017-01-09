# docker-life

docker-life enables you to put your life in a docker container so you can take
it wherever you go.
Assuming your life is a collection of carefully collected, composable terminal
based or server based tools.

It creates a docker image with your tools, wraps it up for you, and sets up
some scripts to launch your image on OS X, Windows, and Linux. It also
downloads docker installers for you where installing Docker from a script is
not viable (ahem, Windows).

# Terminal arguments

```
./init.sh --help
```

# Dependencies

To build, you need
* docker
* bash 4+
* grep
* wget
* A docker image to base your image off of
* A partial docker file (no FROM statement) with commands to install your life

To run, you need any system where docker is supported.

# Using your image

Your image and scripts will be saved in `docker-life/` by default.

## Windows

Install docker using the provided installer at `installers\InstallDocker.msi`.
Click on the `windows.bat` script.

## OS X

Run the `osx.sh` script from the command line. This should launch docker
without installing it. If this does not work, use the installer at
`installers/Docker.dmg` and then run the script again.

## Linux

Run `scripts/install-arch.sh` or `scripts/install-generic-linux.sh`, depending
on if you are on Arch Linux.

The Arch install script merely uses the built in package manager, while the
generic Linux script downloads docker's helper script and runs it. Should
docker's servers ever become compromised, you could be running a malicious
script. Run it at your own risk.

After this, you can launch docker and start the image with `./unix.sh`


At this point, you should be in a familiar environment, so I hope you know what
to do from here.

# Example

An example partial docker file is available in `example/Dockerfile`.

Run
```
./init.sh --help
```

To view the default arguments, which are used in the example.
The init script can be run with no arguments to build the example.

The `Dockerfile` is essentially made up of terminal based commands that you
would normally use to install your system on a fresh install with `RUN` put
before them, but there may be extra steps with the docker image you choose to
base yours off of.

Find an appropriate image at [http://hub.docker.com](the docker hub).
