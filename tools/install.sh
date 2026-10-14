#!/bin/bash

if [ ! -n "$CHANGE" ]; then
  CHANGE=~/.change
fi

if [ -d "$CHANGE" ]; then
  printf "You already have CHANGE installed.\n"
  printf "You'll need to remove $CHANGE if you want to re-install.\n"
  exit
fi

# TODO: replace arensonzenza with your GitHub organization/user
git clone https://github.com/arensonzenza/lifewallet-mobile-change-log.git $CHANGE

echo ""
echo "Entering sudo"
sudo chmod +x $CHANGE/changelog.sh
sudo ln -s $CHANGE/changelog.sh /usr/local/bin/change
