# Atlas Docker Compose

This is an example setup using [Atlas](https://atlas.hashicorp.com) to configure
a [Docker](https://docker.com) host on [AWS](https://aws.amazon.com) so that
[Docker Compose](https://github.com/docker/fig) can be used to manage an application
on a remote host.

## Purpose

Docker compose, formerly fig, is great for local development and setting up
an application. I wanted to find a way to set up a remote environment to use
docker compose with that could be ephemeral and easily duplicated, this is
where Atlas came in to manage that setup.

My desire was to see how convenient this could be for throw away development
servers to have hosted on a cloud provider that is interacted with the same
way you would use Docker compose or fig locally.

## Requirements

You will need a few things set up to get everything running:

* AWS account
  * There are other providers that this could be translated to in the future
* Atlas account and your Atlas token
* [Packer](https://packer.io) for packaging the server into an AMI
* [Terraform](https://terraform.io) to manage the infrastructure needed
* [Docker Compose](https://github.com/docker/fig/releases/tag/1.1.0-rc2) to manage the app docker images and containers
  * A non fig version was used for this so `>= v1.1.0`, but it may still work with older versions of fig

## Setup

We are going to start out with setting everything up in Atlas. If you are not familiar
with Atlas please check out the [getting started](https://atlas.hashicorp.com/help/getting-started/getting-started-overview) guide.

If you are using this code you will need to replace my atlas user name everywhere
to be your atlas username ie. `s/mtchavez/joe-user/`

### Build Configuration

Atlas uses [Packer](https://packer.io) to manage what they call build configurations. Look into Packer
to see what all it can do for you. In our case we will be building and provisioning an EC2 AMI
that will run Ubuntu 14.04 with Docker set up.

You will need to have your environment set up with your AWS credentials. To push our build configuration
to Atlas and have it build our AMI we run the following:

```
cd ops
# Use -create when creating
packer push -create ubuntu-docker.json

# Otherwise just push new changes
packer push ubuntu-docker.json
```

If you go to your Atlas build configurations you can watch the progress and verify
that it has successfully built your AMI. Now that we have a provisioned Docker host
we need to use it by defining what our application infrasture is using Terraform.

## Infrastructure State

To manager our infrasture we will be using [Terraform](https://terraform.io) and
will be pushing our state to Atlas. The required infrasture here is pretty simple:

* A security group for our instance networking rules
* Define an instance to launch
* Our built AMI to use to launch our instance

To get our AMI we use Atlas to get our resource data which will have the AMI ID.

```
# Get build configuration
resource "atlas_artifact" "ubuntu-docker" {
    name = "mtchavez/ubuntu-docker"
    type = "aws.ami"
}
```

Then we reference it when defining our instance

```
resource "aws_instance" "docker-host" {
    ami = "${atlas_artifact.ubuntu-docker.metadata_full.region-us-west-2}"
    instance_type = "t2.micro"
    ...
}
```

From the `ops` directory you can verify your infrastructure state with `terraform plan`
to get a detailed output of what terraform will do when it runs. When you are ready to create
your infrastructure simple run `terraform apply`. This will build our instance
and you should see the public IP as output. We will need this to set up our
`DOCKER_HOST` for using Docker compose.

If you want to save your infrastructure state to Atlas you can run `terraform push`

## Docker Compose

Once your server is up and running you can now use Docker compose to push the sample
app to our remote instance. Make sure you have Docker compose

```
$ docker-compose --version
docker-compose 1.1.0-rc2
```

You will need to set up some Docker environment variables to set our new host
and to turn of TLS. You can do this manually or source a shell script with:

```
cd app
# Change 10.0.0.1 to the public IP of your instance
source bin/init_docker_shell 10.0.0.1
```

You should verify that the following variables are set correctly:

```
DOCKER_HOST=tcp://10.0.0.1:2376
DOCKER_TLS_VERIFY=
```

If you are not familiar with Docker compose or fig you can read up on that [here](http://www.fig.sh/).
Now we can use `docker-compose` to execute docker commands and manage our simple
Flask app that has a redis dependency and linked container.

To bring up our app remotely you can simply do `docker-compose up -d`. We can verify
our app is up and running correctly by listing out our processes:

```
$ docker-compose ps
   Name                  Command               State           Ports
-----------------------------------------------------------------------------
app_redis_1   /entrypoint.sh redis-serve ...   Up      0.0.0.0:6379->6379/tcp
app_web_1     python app.py                    Up      0.0.0.0:5000->5000/tcp
```

This shows us that we have redis and our app up and running with our app exposed
on port 5000. If we visit our `http://$HOST:5000` the app should be running
and incrementing page views using redis.
