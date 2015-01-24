#!/bin/sh

# This hook compiles a style.scss file after each BufWritePost event on
# files ending in "scss".

sass style.scss style.css
