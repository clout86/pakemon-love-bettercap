# imma fork!
this is a fork of https://github.com/notnullgames/pakemon-love-bettercap 

theres a lot of extra utilites and display windows that are not being dsiplayed/used. 

still WIP migration from:  https://github.com/clout86/the-read-team/tree/main/planet_rendor


# pakemon

This is a gamified frontend for hacking tools, meant to run with limited input (joystick) like on a pizero made to look like a gameboy.

It needs love & docker installed to develop locally.

## setup

```
# get files and deps
git clone --recursive https://github.com/clout86/pakemon-love-bettercap.git
cd pakemon-love-bettercap
make setup


# run test-net + bettercap server + frontend, in hot-reloading mode
make run

# get a list of more things you can do with make
make
```

## environment variables

There are a few environment variables that control the system.

```sh
# the love app is running in (live-reloading) dev-mode
PAKEMON_DEV=1

# location & credentials for the bettercap backend, defaults to setup in docker-compose
PAKEMON_URL=http://pakemon:pakemon@localhost:8081
```

## credits

I am trying to keep track of all artwork used.

- [portrait images](https://www.spriters-resource.com/pc_computer/rpgmakervx/sheet/100109/)
