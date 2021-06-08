#!/usr/bin/env python
"""
Python script to generate input for TX_FEMA Storm Simulations
Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
June 2021
"""
import argparse

# Generate storms list
def generate_storm_jobs_list(np, storms, np_j):
    jobs = []
    for s in storms:
        # Pre and post processing commands -> Serial execution
        pre = f'./pre_process.sh {s:03} {np_j}'
        post = f'./post_process.sh {s:03}'

        # Main command is the one that will be called using ibrun to launch parallel job
        main = f'./padcirc -I ./runs/s{s:03} -O ./runs/s{s:03} -W 1 > ./runs/s{s:03}/s{s:03}_adcirc.log'

        # Create dictionary of jobs to execute
        jobs.append({'np':np_j, 'pre':pre, 'main':main, 'post':post})

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
    pl_line = "{ppj},{pre};{main};{post}"
    with open("jobs_list.csv", 'w') as fp:
        # First command starts data processing process
        for i in range(len(jobs)):
            fp.write(pl_line.format(np=jobs[i].np, pre=jobs[i].pre,
                main=jobs[i].main, post=jobs[i].post)


if __name__ == "__main__":
    # Parse inputs
    parser = argparse.ArgumentParser()
    parser.add_argument('np', type=int, default=1,
                        help="Total number of processes available.")
    parser.add_argument('--storms', type=string, default="1",
        help="CSL list of storm #s to process.")
    parser.add_argument('--np_per_job', type=int, default=50,
        help="Number of processor to use per job.")
    args = parser.parse_args()

    # Get jobs list to execute
    jobs = generate_storm_jobs_list(args.np,
            [int(x) for x in args.storms_list.split(",")],
            args.np_j)

    # Generate pylauncher input file
    generate_pylauncher_input(jobs)
