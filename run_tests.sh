
set -x

# Treat undefinied variables as an error
set -u

ROOT=/home/johnny

SERVER_PATH=$ROOT/automated-test-suite-www
CURRENT_JOB_PATH=$SERVER_PATH/current-job
PREVIOUS_JOB_PATH=$SERVER_PATH/previous-job

CURRENT_JOB_TEST_SCENES_PATH=$CURRENT_JOB_PATH/sandbox/tests/test\ scenes

DEPLOY_BUILD_PATH=$ROOT/last_master_build

TESTSUITE_PATH=$CURRENT_JOB_PATH/scripts/runtestsuite/runtestsuite.py
APPLESEED_PATH=$CURRENT_JOB_PATH/sandbox/bin/Ship/appleseed.cli
SCRIPTS_REPO_PATH=$ROOT/automated-test-suite

RUNNING_LOCK_FILE_PATH=$SERVER_PATH/running.txt

# Stop this script if a job is already running.
{
if [ -f "$RUNNING_LOCK_FILE_PATH" ]; then
    echo "Job already running."
    exit 0
fi
}

# Stop this script if no build was deployed since the last run.
{
if [ ! -f "$DEPLOY_BUILD_PATH" ]; then
    echo "No build"
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

# Copy the build in the current job.
mv "$DEPLOY_BUILD_PATH/" "$CURRENT_JOB_PATH/"

# Run the tests.
cd "$CURRENT_JOB_TEST_SCENES_PATH"
export LD_LIBRARY_PATH="$CURRENT_JOB_PATH/sandbox/lib/Ship:$CURRENT_JOB_PATH/prebuilt-linux-deps/lib"
# We use nice to reduce the test job process priority.
nice -n1 python $TESTSUITE_PATH -r -t $APPLESEED_PATH > testsuite_script_log.txt 2>&1

# Unlock the job.
rm "$RUNNING_LOCK_FILE_PATH"

set +x
set +u
