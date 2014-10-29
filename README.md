# Docker omnibus

This repository contains [packer.io](http://www.packer.io/) templates and Chef code to build Docker images with prebuilt tools required to build omnibus packages.
The reason for pre building docker images is that compiling the tool chain for omnibus builds can take a very long time.

## Building the Docker images

Before building the images, bootstrap the Chef cookbooks using berkshelf: `berks vendor`

Make sure packer is in the `PATH`, then run the `build.sh` script. To build a specific image you can use packer directly,
see the `build.sh` script for details.

## Using the Docker image(s)

Although you can run `bundle exec omnibus` yourself, a small companion has been pre-installed in the docker image to make your life easier.
The `omnibus-autobuild` utility takes care of annoying stuff like checking out your omnibus project from git, publishing the artifact and sorting out file permissions.

`omnibus-autobuild` flags:

- `-p PROJECT` - The project to build. This is a mandatory parameter.
- `-o OUTPUT_DIR` - Copy the build artifact (anything in `pkg` directory) to `OUTPUT_DIR`
- `-r REPO_URL` - checkout a git repository from `REPO_URL` before building and use that repository as the build source.
- `-R REPO_PATH` - Use `REPO_PATH` as the build source. You should mount `REPO_PATH` as a host volume when running docker (see example bellow)
- `-P PUBLISH_GLOB` - Publish the files matching `PUBLISH_GLOB` to S3 using `omnibus publish s3`. See example bellow.

### Building from a host volume

### Building from a git repository

The following command will clone the git repo, build the `mcollective` omnibus project and copy the output to `/output` directory which is a host volume.

    docker run -v /tmp/pkg:/output --rm omnibus/centos:6 omnibus-autobuild -p mcollective -o /output -r http://github.com/avishai-ish-shalom/omnibus-mcollective.git

### Copying the build artifact to the host

As mentioned in the previous example, the `-o` flag of the `omnibus-autobuild` script will copy the build artifacts to the specified directory.
Use docker's `-v` parameter to mount a host volume on that directory.

### Publish the build artifact to S3

If you want to upload the generated packages to S3 instead of copying back to the host, you will need to enable the S3 publisher in your `omnibus.rb` file:

```ruby
publish_s3_access_key ENV['S3_ACCESS_KEY']
publish_s3_secret_key ENV['S3_SECRET_KEY']
```

Then specify the keys as environment variables and use the `-P` flag:

     docker run -e S3_ACCESS_KEY=your-aws-access-key -e S3_SECRET_KEY=your-aws-secret-key --rm omnibus/centos:6 omnibus-autobuild -p mcollective -r http://github.com/avishai-ish-shalom/omnibus-mcollective.git -P '*.rpm'
