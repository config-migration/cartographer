#!/usr/bin/env bash


# Cleanup configuration system files.


shopt -s globstar


# __pycache__ is generated by the Python interpreter while running programs.
rm -rf /usr/local/lib/python3.8/**/__pycache__
rm -rf /usr/lib/python3/dist-packages/**/__pycache__
