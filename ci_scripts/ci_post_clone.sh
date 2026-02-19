#!/bin/sh

# Generate Secrets.xcconfig from Xcode Cloud environment variables
cat > "$CI_WORKSPACE/Secrets.xcconfig" << EOF
UNSPLASH_ACCESS_KEY = $UNSPLASH_ACCESS_KEY
EOF
