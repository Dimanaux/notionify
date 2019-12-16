#!/usr/bin/env bash

rbenv exec bundle install || bundle install

pip3 install -r requirements.txt
