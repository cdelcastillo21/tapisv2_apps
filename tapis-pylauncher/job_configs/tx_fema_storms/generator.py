#!/usr/bin/env python
"""
Python script to generate input for TX_FEMA Storm Simulations
Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
June 2021

Note this file controls which storms are scanned through
"""
import argparse

# Parameters for run (full run settings in comments)
STORMS = [1, 2, 3] # list(range(1,572))
NP_PER_JOB = 4     # 50


# Generate storms list
def generate_storm_jobs_list(np):
    jobs = []
    for s in STORMS:
        # Pre and post processing commands -> Serial execution
        # Note passing one less than total processes per job since one will be for writing data
        adcirc_run_proc = NP_PER_JOB-1
        pre = f'./pre_process.sh {s:03} {adcirc_run_proc}'
        post = f'./post_process.sh {s:03}'

        # Main command is the one that will be called using ibrun to launch parallel job
        main = f'./padcirc -I runs/s{s:03} -O runs/s{s:03} -W 1 > runs/s{s:03}/s{s:03}_adcirc.log'

        # Create dictionary of jobs to execute
        jobs.append({'np':NP_PER_JOB, 'pre':pre, 'main':main, 'post':post})

    return jobs


# Jobs is list of dictionary containing elements:
#    np
#    pre
#    main
#    post
# Generate input file in current directory
def generate_pylauncher_input(jobs, refresh_int=600):

    # Create parallel lines file. Each line has format:
    # [NUM_PROC],[PRE PROCESS COMMAND];[MAIN PARALLEL COMMAND];[POST PROCESS COMMAND]
    pl_line = "{np},{pre};{main};{post}\n"
    with open("jobs_list.csv", 'w') as fp:
        # First command starts data processing process
        for i in range(len(jobs)):
            fp.write(pl_line.format(np=jobs[i]['np'], pre=jobs[i]['pre'],
                main=jobs[i]['main'], post=jobs[i]['post']))


if __name__ == "__main__":
    # Parse inputs
    parser = argparse.ArgumentParser()
    parser.add_argument('iter', type=int, default=1,
                        help="Iteration of pylauncher execution loop.")
    parser.add_argument('np', type=int, default=1,
                        help="Total number of processes available.")
    args = parser.parse_args()

    # Get jobs list to execute
    # No retry logic implemented yet, so only execute if on first iteration of pylauncher
    # In future add logic to find failed jobs and retry them if iter>1.
    if args.iter==1:
        jobs = generate_storm_jobs_list(args.np)

        # Generate pylauncher input file
        generate_pylauncher_input(jobs)
