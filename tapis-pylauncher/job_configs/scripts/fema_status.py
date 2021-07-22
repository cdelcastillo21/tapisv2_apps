import argparse as ap
import json
import os
import glob
import time
import sys
import subprocess
import re

def time_interval(seconds):
    days, seconds = divmod(int(seconds), 3600*24)
    return f"{days} days, "+ time.strftime("%H:%M:%S", time.gmtime(seconds))

def check_progress(job_dir, conf):
    gen_args = conf['parameters']['generator_args']
    # Hacky, but works for now
    nstorms = gen_args.count(",") + 1

    ncompleted = nstarted = 0
    progress_re = re.compile(".* (\d+\.\d+%) COMPLETE.*")
    # check running storms
    for dirname in glob.glob(job_dir+"/runs/s*/"):
        nstarted += 1
        logfile = dirname+"/adcirc.log"        
        storm = dirname.strip("/").split("/")[-1]
        if os.path.exists(logfile):
            output = subprocess.run(f"tail -10 {logfile}", shell=True, check=True, stdout=subprocess.PIPE)

            match = progress_re.match(str(output.stdout))
            if match is not None:
                print(f"Storm {storm} still running, progress: ", match[1])
            else:
                print(f"Storm {storm} still in pre-process stage.")
        elif os.path.exists(logfile.replace("/runs/", "/logs/runs/")):
            # the logfile was moved after the run was completed
            ncompleted += 1
        else:
            # something fishy is going on
            print(f"Cannot locate logfile for {storm}!")

    print(f"Started {nstarted} out of {nstorms}, completed {ncompleted}." +
        f"\nIncomplete: {nstarted-ncompleted}. Not Started: {nstorms-nstarted}.")

def check_job_status(job_dir, conf, start_time):
    hrs, mnts, seconds = map(int, conf["maxRunTime"].split(":"))
    max_runtime = hrs * 3600 + mnts * 60  + seconds
    runtime = time.time() - start_time
    if max_runtime < runtime:
        stderr_file = job_dir+"/" + conf["job_id"] + ".e" + str(conf["slurm"]["slurm_id"])
        if "CANCELLED" in str(subprocess.run(f"tail -10 {stderr_file}", shell=True, check=True, stdout=subprocess.PIPE).stdout):
            print("Job timed out!")
        else: print("Job Completed.")
    else:
        print(f"Job running for: {time_interval(runtime)}, (max {conf['maxRunTime']}).")

if __name__ == "__main__":
    parser = ap.ArgumentParser()
    parser.add_argument("job_dir")
    args = parser.parse_args()

    job_dir = args.job_dir
    conf_file = job_dir+"/job_config.json"
    if not os.path.exists(conf_file):
        raise ValueError(f"Cannot find job config file in {job_dir}")

    with open(conf_file, "r") as fp:
        conf = json.load(fp)

    print("Job Config", conf)

    # usually true
    submit_time = os.path.getmtime(conf_file)

    start_time = None
    for startfile in glob.glob(f"{job_dir}/start_*"):
        start_time = os.path.getmtime(startfile)
 
    if start_time is None:
        print("Job not yet started.")
        queue_time = time.time() - submit_time
    else:
        queue_time = start_time - submit_time

    print("Queued Time: ", time_interval(queue_time))

    if start_time is not None:
        check_progress(job_dir, conf)
        check_job_status(job_dir, conf, start_time)
