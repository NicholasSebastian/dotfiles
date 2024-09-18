#!/usr/bin/python

# Written by Nicholas Oliver Bahary
# on September 16, 2024.

import os
import json

source = "stow.json"


def ensuredir(dir):
    if not os.path.exists(dir):
        os.system("mkdir -p " + dir)


def move(src, dest=None):
    dest = os.path.join(".", dest) if dest else "."
    ensuredir(dest)
    return os.system("mv {0} {1}".format(src, dest + os.path.sep))


def stow(local, target):
    ensuredir(target)
    return os.system("stow {0} -t {1}".format(local, target))


def expand_path(path):
    return os.popen("echo " + path).read().rstrip()


def stow_directories(directories):
    for target in directories:
        target = expand_path(target)
        if not os.path.exists(target):
            continue
        name = os.path.basename(target)
        if not os.path.exists(name):
            move(target)
        stow(name, target)


def stow_files(files):
    for name, targets in files.items():
        if len(targets) == 0:
            continue
        basedir = None
        if len(targets) == 1:
            target = expand_path(targets[0])
            if not os.path.exists(target):
                continue
            basedir, filename = os.path.split(target)
            if not os.path.exists(os.path.join(name, filename)):
                move(target, name)
        else:
            basedir = expand_path(os.path.commonpath(targets))
            for target in targets:
                target = expand_path(target)
                if not os.path.exists(target):
                    continue
                filepath = target[len(basedir) + 1 :]
                if not os.path.exists(os.path.join(name, filepath)):
                    relpath, filename = os.path.split(filepath)
                    move(target, os.path.join(name, relpath))
        stow(name, basedir)


with open(source, "r") as sourcefile:
    sourcestr = sourcefile.read()
    sourcejson = json.loads(sourcestr)
    stow_directories(sourcejson["directories"])
    stow_files(sourcejson["files"])
