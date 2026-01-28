# Purpose
These are dot-files that are meant to be used in a typical Electrical Engineering work environment.

# Definition of a "typical" EE work environment:
* Multi-platform
    * At the time of writing this
        * Redhat 7, 8, 9
        * Suse
        * x86_64, ARM, PowerPC
* Offline
    * We usually can see either none, or a very limited view, of the general internet
    * For this reason, the distribution will contain a lot of files (plugins, for example)
      that would normally be updated at dot-files install time.
* No sudo / root access
    * Our work systems are locked down
    * Can't install arbitrary packages into system directories

# Flexibility
When possible, I want to offer a layered configuration structure with precedence.
From lowest->highest precedence:
* Global
* Corp
* Site
* Team
* User

# Opinionated
I want to offer a "way of working" to the EE community (and perhaps beyond) that I have continuously
worked on over my 30 years of experience. _But_, the end user should have the ability to apply overrides
without breaking future updates of the base system. *And*, the end user is encouraged to discuss and
upstream good/new "ways of working".

# Modern
Ideally will be used in conjunction with [EE Linux Tools](https://github.com/smprather/ee-linux-tools).
These dot-files rely on modern Linux utilities like RipGrep, Tmux, EZA, etc.
