# sysWatcher #

The sysWatcher project is a fully scriptable, generic event system. It uses custom triggers to invoke a script or to send an email with predetermined content. Event triggering is entirely handled by the plugin scripts, hence the term "generic".

## Installation ##

The installation process is necessary because sysWatcher depends on in-house scripts, which provide functions useful to plugins and the main script alike. Functions for date and time malipulation are provided, among others.

In your terminal, clone the sysWatcher repository using `git clone git://xroutine.net/sysWatcher.git`. You can also browse the repository here : [http://git.xroutine.net/sysWatcher.git](http://git.xroutine.net/sysWatcher.git)

Install the configuration and plugin files by typing `make install`. This creates and populates the directory **/usr/share/sysWatcher**.

Finally, copy sysWatcher.sh to the installation path of your choice.

*Note: sysWatcher consists entirely of shell script and configuration files, so no compiler commands are required.*

## Configuration ##

The main script, **sysWatcher.sh**, looks for **sysWatcher.conf**, first in the current directory (which may not be the installation directory), then in /etc, and finally in /usr/local/etc. It will stop looking for sysWatcher.conf at the first match.

**sysWatcher.conf** must contain at least three variables: **email**, **eventDir** and **varDir**:

+ **eventDir** tells sysWatcher which directory contains the plugin scripts.
+ **varDir** specifies a directory including items such as temporary timeout files.
+ **email** is the default recipient email.

More detailed configuration options are given in **sysWatcher.sh**.

## Requirements ##

A plugin script needs to include certain mandatory functions to work properly. More details are given within **sysWatcher.sh**.

For reasons of compatibility, only **bash** and **zsh** are supported. Some other shells such as **dash** lack some necessary features. It may be possible to use **ksh**, but this has not been tested.

sysWatcher.sh uses the **mail** command to send emails. For this to work you should have a mailing system (such as postfix) installed and configured.

## Running sysWatcher ##

You should schedule sysWatcher.sh as a regular job using cron or similar. This allows sysWatcher to run as often or as rarely as you wish.

### Adding a cron job ###

Open a terminal and type:

`sudo crontab -e`

This will open the cron table in your default text editor. Enter the following after the comments:

`*/1 * * * * /bin/bash /usr/sbin/sysWatcher.sh`

The above example assumes you want to run sysWatcher.sh every minute. Please note that the path may vary depending on where you choose to install sysWatcher (see the Installation section for more details). Read the man pages for **crontab(5)** and **cron(8)** for more details on scheduling with cron.

It should be quite easy to run sysWatcher as a standalone daemon, but this
might be less useful than scheduling it as a cron job.
