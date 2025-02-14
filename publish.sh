#!/bin/bash

function ask {
  read -r -p "$@ [y/N] " response
  case "$response" in
      [yY][eE][sS]|[yY])
          true
          ;;
      *)
          false
          ;;
  esac
}

function update_version {
    OLD_VERSION=$(cat ./package.json | jq -r '.version');
    OLD_VERSION_MAJOR=$(echo $OLD_VERSION | awk 'BEGIN{FS="."}{print $1}');
    OLD_VERSION_MINOR=$(echo $OLD_VERSION | awk 'BEGIN{FS="."}{print $2}');
    OLD_VERSION_BUG=$(echo $OLD_VERSION | awk 'BEGIN{FS="."}{print $3}');

    if [[ "$1" == "m" ]]; then
      NEW_VERSION_MAJOR=$OLD_VERSION_MAJOR;
      NEW_VERSION_MINOR=$(echo "$OLD_VERSION_MINOR" + 1 | bc);
      NEW_VERSION_BUG="0";
    elif [[ "$1" == "M" ]]; then
      NEW_VERSION_MAJOR=$(echo "$OLD_VERSION_MAJOR" + 1 | bc);
      NEW_VERSION_MINOR="0";
      NEW_VERSION_BUG="0";
    else
      NEW_VERSION_MAJOR=$OLD_VERSION_MAJOR;
      NEW_VERSION_MINOR=$OLD_VERSION_MINOR;
      NEW_VERSION_BUG=$(echo "$OLD_VERSION_BUG" + 1 | bc);
    fi

    NEW_VERSION="$NEW_VERSION_MAJOR.$NEW_VERSION_MINOR.$NEW_VERSION_BUG";

    echo $NEW_VERSION
}

VERSION=$(update_version)
if [[ "$1" == "m" ]]; then
  VERSION=$(update_version "m")
fi

if [[ `ask "Do you want to publish $VERSION?" && echo true` == true ]]; then
  echo "Updating version number in files..."
  sed -i "s/\"version\": \".*\"/\"version\": \"$VERSION\"/g" package.json
  sed -i "s/\/\/ SHARESIES v.*/\/\/ SHARESIES v$VERSION/g" index.js
  sed -i "s/const c_VERSION = '.*';/const c_VERSION = '$VERSION';/g" lib/constants.js

  if [[ -e /usr/local/bin/npmme ]]; then
    echo "Switching to correct npm..."
    /usr/local/bin/npmme
  fi

  echo "Running npm publish..."
  npm publish
  echo "Tagging revision..."
  git add .
  git commit -m "Set version to $VERSION"
  git tag -a v$VERSION -m "Published v$VERSION"
  git push origin v$VERSION

  npm install -g sharesies
else
  echo "Ok...";
fi
