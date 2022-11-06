#!/bin/bash

if [[ -z "$FERRET_VERSION" && -z "$_FERRET_VERSION"  ]]; then
  if [ $1 = 'ferret' ]; then
    echo $(cat go.mod | grep 'github.com/MontFerret/ferret v' | awk -F 'v' '{print $2}')
  else
    echo $(git describe --tags --always --dirty)
  fi
else 
  echo $FERRET_VERSION$_FERRET_VERSION
fi