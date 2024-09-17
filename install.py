#!/usr/bin/python

# Written by Nicholas Oliver Bahary
# on September 16, 2024.

import os
import json

source = "stow.json"

# Wrappers around shell commands.
stow = lambda n, t: os.system("stow {0} -t {1}".format(n, t))
ensuredir = lambda dir: os.system("mkdir -p " + dir)
move = lambda s, d=None: os.system(
    "mv {0} {1}".format(s, os.path.join(".", d) + os.path.sep if d else ".")
)

with open(source, "r") as sourcefile:
    sourcestr = sourcefile.read()
    sourcejson = json.loads(sourcestr)
    directories, files = sourcejson["directories"], sourcejson["files"]

    # Stow the directories.
    for target in directories:
        if not os.path.exists(target):
            continue
        name = os.path.basename(target)
        if not os.path.exists(name):
            move(target)
        ensuredir(target)
        stow(name, target)

    # Stow the files.
    for name, targets in files.items():
        if len(targets) == 0:
            continue
        basedir = None
        if len(targets) == 1:
            target = targets[0]
            if not os.path.exists(target):
                continue
            basedir, filename = os.path.split(target)
            if not os.path.exists(os.path.join(name, filename)):
                ensuredir(name)
                move(target, name)
        else:
            basedir = os.path.commonpath(targets)
            for target in targets:
                if not os.path.exists(target):
                    continue
                filepath = target[len(basedir) + 1 :]
                if not os.path.exists(os.path.join(name, filepath)):
                    relpath, filename = os.path.split(filepath)
                    ensuredir(os.path.join(name, relpath))
                    move(target, name)
        stow(name, basedir)
