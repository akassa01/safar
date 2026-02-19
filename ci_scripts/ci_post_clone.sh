#!/bin/sh

# Generate Secrets.xcconfig from Xcode Cloud environment variables
echo "UNSPLASH_ACCESS_KEY = $UNSPLASH_ACCESS_KEY" > "$CI_PRIMARY_REPOSITORY_PATH/Secrets.xcconfig"
