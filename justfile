# Run the tests
test:
    swift test

# Build build/MenuStats.app
bundle:
    ./scripts/bundle.sh

# Rebuild, then restart the app
run: bundle
    -pkill -f MenuStats.app
    open build/MenuStats.app

# Remove build output
clean:
    rm -rf .build build
