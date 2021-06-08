import os
import argparse
import subprocess
from generator import gen_function


def init_job(np, refresh_int=600):
    # Current working directory should be job directory
    job_dir = os.getcwd()
    adcirc_base_input_dir = os.path.join(job_dir, 'base_inputs')
    scan_input_dir = os.path.join(job_dir, 'inputs')
    adcirc_exec = os.path.join(job_dir, 'execs', 'padcirc')

    # Run generator function to generate nodal attribute files to sweep
    run_names, run_procs, write_procs = gen_function(np, adcirc_base_input_dir, scan_input_dir)

    # Start data process in backgorund
    data_process = subprocess.Popen(['./launch_data_process.sh', '600', '>launch_data_process.log', str(refresh_int)])

    # Create parallel lines file. Each line has format:
    # [NUM_PROC],[PRE PROCESS COMMAND];[MAIN PARALLEL COMMAND];[POST PROCESS COMMAND]
    pl_file = os.path.join(job_dir, 'parallel_lines.csv')
    pl_line = "{ppj},pre_process.sh {run_name} {run_proc};"
    pl_line += "{adcirc_exec} -I {run_dir} -O {run_dir} -W {write_proc} > {run_dir}/run_adcirc.log;"
    pl_line += "post_process.sh {run_name} > {run_dir}/post_process.log\n"
    with open(pl_file, 'w') as fp:
        # First command starts data processing process
        for i in range(len(run_names)):
            fp.write(pl_line.format(ppj=int(run_procs[i]+write_procs[i]),
                                    run_name=run_names[i],
                                    adcirc_exec=adcirc_exec,
                                    run_dir=os.path.join(job_dir, "runs", "_".join(['run', run_names[i]])),
                                    run_proc=int(run_procs[i]),
                                    write_proc=int(write_procs[i])))

    # Create pylauncher launch script to launch csv file
    launch_script = "import pylauncher4 as pyl4\n"
    launch_script += f"pyl4.IbrunLauncher(\"{pl_file}\", cores=\"file\", "
    launch_script += "debug=\"job+host+task+exec\", pre_post_process=True)\n"
    with open(os.path.join(job_dir, 'launch.py'), 'w') as fp:
        fp.write(launch_script)
    fp.close()


if __name__ == "__main__":
    # Parse inputs
    parser = argparse.ArgumentParser()
    parser.add_argument('np', type=int, default=1,
                        help="Total number of processes available to scan job.")
    parser.add_argument('--refresh-int', type=int, default=600,
                        help="Data Processing Refresh Interval")
    args = parser.parse_args()

    # Initialize job
    init_job(args.np)
