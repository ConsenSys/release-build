#!/usr/bin/env bash

set -ue

if [ $# != 1 ]; then
    echo "Usage: $0 release.config" 1>&2
    exit 1;
fi

release_configuration=$1

if [ ! -r $release_configuration ]
then
    echo "Configuration file $release_configuration is missing or cannot be read"
    exit 1
fi

if ! ssh-add -l > /dev/null; then
    echo "No identities in ssh-agent (run ssh-add?)" >&2
    exit 1
fi

pinata-gpg-forward

workingdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $workingdir/$release_configuration

builddir=$(mktemp -d $TMPDIR/release-XXXXXX)
trap 'rm -rf $builddir' EXIT

rm -Rf $builddir/build-checkout
mkdir $builddir/build-checkout
git clone $git_repo $builddir/checkout
exitstatus=$?

if [ $exitstatus != 0 ]; then
  echo "Error while checking out the git repository"
  exit 1
fi

pushd $builddir/checkout
git checkout $git_branch
exitstatus=$?

if [ $exitstatus != 0 ]; then
  echo "Error while checking out the branch"
  exit 1
fi

git submodule update --init --recursive
exitstatus=$?

if [ $exitstatus != 0 ]; then
  echo "Error while updating submodules"
  exit 1
fi

popd

if [ $kotlin_docs = "true" ]; then
  build_docs=":dokka :javadoc"
else
  build_docs=":javadoc"
fi

cat<<-EOF > $builddir/run_release.sh
#!/bin/bash

set -xe
echo "running release now"
chmod og-rwx /root/.gnupg
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
export GPG_TTY=/dev/console
export TMPDIR=/tmp
git tag -a $tag_name -m "$tag_comment" -s
./gradlew build $build_docs 
./gradlew sign
./gradlew deploy 
./publishSite.sh $tag_name /checkout $git_branch --kotlin_docs=$kotlin_docs
git push origin $git_branch --tags
EOF
chmod +x $builddir/run_release.sh
cp $workingdir/publishSite.sh $builddir/publishSite.sh

docker build -t release_image:1.0 -f $workingdir/Dockerfile --build-arg git_name="$git_name" --build-arg git_email="$git_email" --build-arg gpg_key="$signing_key_id" $builddir
exitstatus=$?

if [ $exitstatus != 0 ]; then
  echo "Error while building the release image"
  exit 1
fi

docker run -it -v $ssh_private_key:/root/.ssh/id_rsa \
           -v $ssh_public_key:/root/.ssh/id_rsa.pub \
           -v gpg-agent:/root/.gnupg \
           -e BUILD_TAG_MODE="release" \
           -e BINTRAY_USER=$bintray_user \
           -e BINTRAY_KEY=$bintray_key \
           -e ENABLE_SIGNING=true \
           release_image:1.0

# Remove docker pgp-agent:
docker rm -f "pinata-gpg-agent" >/dev/null 2>&1 || true
