
set -x

# Treat undefinied variables as an error
set -u

ROOT=/home/johnny

SERVER_PATH=$ROOT/automated-test-suite-www

BUILD_PATH=$ROOT/build
DEPLOY_BUILD_PATH=$ROOT/last_master_build

TESTSUITE_PATH=$BUILD_PATH/scripts/runtestsuite/runtestsuite.py
APPLESEED_PATH=$BUILD_PATH/sandbox/bin/Ship/appleseed.cli
TEST_SCENES_PATH=$BUILD_PATH/sandbox/tests/test\ scenes
BUILD_REPORT_PATH=$BUILD_PATH/build_report.txt
SCRIPTS_REPO_PATH=$ROOT/automated-test-suite

RUNNING_LOCK_FILE_PATH=$TEST_SCENES_PATH/running.txt

# We run the tests from a specific directory.
# A web server is pointing to this directory and the test scenes directory to expose the results.
mkdir -p "$TEST_SCENES_PATH"
mkdir -p "$SERVER_PATH"
cd "$TEST_SCENES_PATH"

# Stop this script if a job is already running.
{
if [ -f "$RUNNING_LOCK_FILE_PATH" ]; then
    echo "Job already running."
    exit 0
fi
}

cp "$SCRIPTS_REPO_PATH/webserver/index.html" "$SERVER_PATH/"

# The build is duplicated in case another build
# is being deployed while we run the tests.

# Duplicate the build.
rsync \
    -raz --stats --delete \
    --exclude 'src' \
    --exclude 'docs' \
    --exclude 'cmake' \
    "$DEPLOY_BUILD_PATH/" \
    "$BUILD_PATH/"

touch "$RUNNING_LOCK_FILE_PATH"
echo "running..." >> "$RUNNING_LOCK_FILE_PATH"

# Archive last report.
cp "$SERVER_PATH/report.html" "$SERVER_PATH/last_report.html"
cp "$SERVER_PATH/build_report.txt" "$SERVER_PATH/last_build_report.txt"
cp "$SERVER_PATH/job.txt" "$SERVER_PATH/last_job.txt"

# Update build report and show it to the world.
cp "$BUILD_REPORT_PATH" "$SERVER_PATH/build_report.txt"

# Run the tests.
# We use nice to reduce the test job process priority.
export LD_LIBRARY_PATH="$BUILD_PATH/sandbox/lib/Ship:$BUILD_PATH/prebuilt-linux-deps/lib"
rm "$SERVER_PATH/job.txt"
nice -n1 python $TESTSUITE_PATH -r -t $APPLESEED_PATH > "$SERVER_PATH/job.txt" 2>&1

cp report.html "$SERVER_PATH/report.html"

rm "$RUNNING_LOCK_FILE_PATH"

set +x
set +u
