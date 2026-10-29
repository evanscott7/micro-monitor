#!/bin/sh
# Wraps lighthouse.html (the artifact source) into a full document for the real screen.
cd "$(dirname "$0")"
{ printf '<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
  sed -n '1,/<\/style>/p' lighthouse.html
  printf '</head><body class="%s">\n' "${1:-kiosk}"
  sed -n '/<\/style>/,$p' lighthouse.html | sed '1d'
  printf '</body></html>\n'; } > screen.html
