# apt-clone/

Keep here up-to-date apt configurations, to be able to restore preferred apps
quickly.


## How to update

The `update-clone-info` automates the invocation of `apt-clone`:

    ./update-clone-info
	

## Naming convention

The destination argument given to apt-clone is formed with the name of the
current machine (obtained by `uname -n` or by `hostname` in that order),
followed by the LSB ID and CODENAME of the distribution, obtained from
`/etc/lsb-release` if it exists.

* If the hostname cannot be determing, a full ISO date/time for the UTC is
used.  Hopefully, this prevents accidental overwriting of clone files from
another machine of unknown name.

* If the distribution id and codename are unknown, the string `unknown` is used
for that part.

