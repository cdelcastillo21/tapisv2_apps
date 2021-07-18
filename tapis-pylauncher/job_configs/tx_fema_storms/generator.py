#!/usr/bin/env python
"""
Python script to generate input for TX_FEMA Storm Simulations
Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
June 2021

Note this file controls which storms are scanned through
"""

import argparse
# It turns out that some storm numbers are missing in the FEMA data. For example, there is a storm 501, but not 500.
# There are actually only ~450 storms with data, even though the highest number is 572
from storm_numbers import storm_nums
import json

# Generate storms list
def generate_storm_jobs_list(np_per_job, storms):
    jobs = []
    for s in storms:
        # Pre and post processing commands -> Serial execution
        # This comes out to one writer process for every two nodes (assuming SKX nodes with 48 cores each)
        n_writers = max(1, np_per_job//96)
        # Note passing n_writers less than total processes per job since some will be for writing data
        adcirc_run_proc = np_per_job-n_writers
        pre = f'./pre_process.sh {s:03} {adcirc_run_proc}'
        post = f'./post_process.sh {s:03}'

        # Main command is the one that will be called using ibrun to launch parallel job
        main = f'./padcirc -I runs/s{s:03} -O runs/s{s:03} -W {n_writers} > runs/s{s:03}/s{s:03}_adcirc.log'

        # Create list of jobs to execute
        storm_id = f"{s:03}"
        jobs.append({'cores':np_per_job, 'pre_process':pre, 'main':main, 'post_process':post, "id": storm_id})

    return jobs


# Jobs is list of dictionary containing elements:
#    np
#    pre
#    main
#    post
# Generate input file in current directory
"""
def generate_pylauncher_input(jobs, refresh_int=600):

    # Create parallel lines file. Each line has format:
    # [NUM_PROC],[PRE PROCESS COMMAND];[MAIN PARALLEL COMMAND];[POST PROCESS COMMAND]
    pl_line = "{np},{pre};{main};{post}\n"
    with open("jobs_list.csv", 'w') as fp:
        # First command starts data processing process
        for i in range(len(jobs)):
            fp.write(pl_line.format(np=jobs[i]['np'], pre=jobs[i]['pre'],
                main=jobs[i]['main'], post=jobs[i]['post']))
"""

if __name__ == "__main__":
    # Parse inputs
    parser = argparse.ArgumentParser()
    parser.add_argument('iter', type=int, default=1,
                        help="Iteration of pylauncher execution loop.")
    parser.add_argument('np', type=int, default=1,
                        help="Total number of processes available.")
    parser.add_argument("--np-per-job", default=48*10, type=int)
    parser.add_argument("--storm-inds", default=None, type=str)
    args = parser.parse_args()

    # Get jobs list to execute
    # No retry logic implemented yet, so only execute if on first iteration of pylauncher
    # In future add logic to find failed jobs and retry them if iter>1.
    if args.storm_inds is not None:
        storms = [storm_nums[int(i)] for i in args.storm_inds.split(",")]
    else:
        storms = storm_nums[-4:] # STORMS = storm_nums
    
    if args.iter==1:
        jobs = generate_storm_jobs_list(args.np_per_job, storms)
        with open("jobs_list.json", "w") as fp:
            json.dump(jobs, fp)

