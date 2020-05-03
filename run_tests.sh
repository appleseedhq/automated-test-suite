
set -x

# Treat undefinied variables as an error
set -u

ROOT=/home/johnny

SERVER_PATH=$ROOT/automated-test-suite-www
CURRENT_JOB_PATH=$SERVER_PATH/current-job
PREVIOUS_JOB_PATH=$SERVER_PATH/previous-job

BUILD_PATH=$ROOT/build
DEPLOY_BUILD_PATH=$ROOT/last_master_build

TESTSUITE_PATH=$BUILD_PATH/scripts/runtestsuite/runtestsuite.py
APPLESEED_PATH=$BUILD_PATH/sandbox/bin/Ship/appleseed.cli
TEST_SCENES_PATH=$BUILD_PATH/sandbox/tests/test\ scenes
BUILD_REPORT_PATH=$BUILD_PATH/build_report.txt
SCRIPTS_REPO_PATH=$ROOT/automated-test-suite

RUNNING_LOCK_FILE_PATH=$SERVER_PATH/running.txt

# We run the tests from a specific directory.
# A web server is pointing to this directory and the test scenes directory to expose the results.
mkdir -p "$TEST_SCENES_PATH"

# Stop this script if a job is already running.
{
if [ -f "$RUNNING_LOCK_FILE_PATH" ]; then
    echo "Job already running."
    exit 0
fi
}

# Lock the job.
touch "$RUNNING_LOCK_FILE_PATH"
echo "running..." >> "$RUNNING_LOCK_FILE_PATH"

# Make sure the server index is up to date with the repo.
cp "$SCRIPTS_REPO_PATH/webserver/index.html" "$SERVER_PATH/"

# Last current job become previous job
rm -rf "$PREVIOUS_JOB_PATH"
mv "$CURRENT_JOB_PATH" "$PREVIOUS_JOB_PATH"

# The build is duplicated in case another build
# is being deployed while we run the tests.

# Duplicate the build.
rsync \
    -raz --stats --delete \
    "$DEPLOY_BUILD_PATH/" \
    "$BUILD_PATH/"

# Run the tests.
cd "$TEST_SCENES_PATH"
export LD_LIBRARY_PATH="$BUILD_PATH/sandbox/lib/Ship:$BUILD_PATH/prebuilt-linux-deps/lib"
# We use nice to reduce the test job process priority.
nice -n1 python $TESTSUITE_PATH -r -t $APPLESEED_PATH > testsuite_script_log.txt 2>&1

# Move test scenes in the current job folder.
# We place test scenes in the server to corretly
# server images and test logs.
mkdir -p "$CURRENT_JOB_PATH"
rsync \
    -raz --stats \
    "$TEST_SCENES_PATH/" \
    "$CURRENT_JOB_PATH/"

# We also need the travis report.
cp "$BUILD_REPORT_PATH" "$CURRENT_JOB_PATH/build_report.txt"

# Unlock the job.
rm "$RUNNING_LOCK_FILE_PATH"

set +x
set +u
