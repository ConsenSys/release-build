# Release Build

This repository contains instructions to run a release build for your project.

See it in action in the [Cava repository](https://www.github.com/consensys/cava)

## Install Docker on your machine
### Share the location of your home folder (the program will mount your .gnupg and .ssh folders)

## Install gpg on your machine

### Edit the gpg agent to ensure pin entries use the tty:
> ~/.gnupg/gpg-agent.conf

Add the line: `pinentry-program /usr/local/bin/pinentry-tty` (adapt depending on where the program is located)

### Reload gpg-agent:

> gpg-connect-agent reloadagent /bye

## Install gpg-agent-forward

##1 Generate a SSH key/pair to ssh forward the gpg-agent. Give it a name such as 'releasekey'

> ssh-keygen -t rsa

Add the resulting identity to your ssh agent trusted identities:

> ssh-add -K &lt;private key&gt;

### Follow the instructions at https://github.com/transifex/docker-gpg-agent-forward, reproduced here:

> git clone git://github.com/transifex/docker-gpg-agent-forward
> cd docker-gpg-agent-forward
> make
> make install

The script runs `pinata-gpg-forward` for you.

## Create your release configuration

### Copy the release.config.sample file into &lt;your release&gt;.config

> cp release.config.sample &lt;your release&gt;.config

Fill in the information in &lt;your release&gt;.config

## Insert your Yubikey if you haven't already

### Prepare the Yubikey and test it works as expected:

> gpg --status-fd=2 -bsau &lt;YOUR KEY ID&gt;

Enter some text, press ^D
Enter your PIN, then touch the key if needed.
Repeat. Notice the PIN prompt should not show.

## run the release

> ./release.sh &lt;your release&gt;.config

### Follow the prompts and enter your Yubikey PINs when prompted

## Check the release took place

### Check the website was updated.

### Check bintray to make sure the files are there.

You may need to OK the publication of the files.

Check the .asc files are there.

Download the main distribution jar and its associated .asc file.

> gpg --verify &lt;downloaded file&gt;.asc &lt;downloaded file&gt;

If this is the first time, from the output, copy the RSA key used for signing and drop it in:

> gpg --keyserver pgp.mit.edu --recv-key &lt;RSA key ID&gt;

Then run again:

> gpg --verify &lt;downloaded file&gt;.asc &lt;downloaded file&gt;

### Check the tag on github.

## Prepare next iteration

### Edit the README with the new version
* Change the download badge
* Edit the Maven coordinates

### Change the version in build.gradle
