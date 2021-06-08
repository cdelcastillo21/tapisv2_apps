import pylauncher4 as pyl4

# Launch pylauncher with IbrunLauncher, pre_post_processing set to True by default
# Note name of input file expected is jobs_list.csv
pyl4.IbrunLauncher("jobs_list.csv", cores="file", debug="job+host+task+exec", pre_post_process=True)
