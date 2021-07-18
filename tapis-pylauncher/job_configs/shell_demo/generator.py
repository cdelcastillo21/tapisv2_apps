import argparse
import json

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("iter", type=int)
  parser.add_argument("np", type=int)
  parser.add_argument("--message", type=str, default="Hello World!")
  parser.add_argument("--num-jobs", type=int, default=5)

  args = parser.parse_args()
  if args.iter == 1:
    print(f"Running generator.py with message: {args.message}")
    jobs = [{"cores": 1, "main": f"./main.sh {i}",
          "pre_process": f"./pre_process.sh {i}",
          "post_process": f"./post_process.sh {i}"} for i in range(args.num_jobs)]

    with open("jobs_list.json", "w") as fp: json.dump(jobs, fp)
