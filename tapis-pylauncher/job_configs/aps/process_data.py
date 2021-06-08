import os
import pdb
import glob
import json
import dask
import logging
import datetime
import argparse
import subprocess
import numpy as np
import pandas as pd
import xarray as xa
import random as rand
from adcirc_utils import *
from time import perf_counter, sleep
from array import array
from contextlib import contextmanager


logger = logging.getLogger()


@contextmanager
def timing(label: str):
  t0 = perf_counter()
  yield lambda: (label, t1 - t0)
  t1 = perf_counter()


def process_run_data(job_dir:str, nodes=[], param='wind_drag_parameter',
    purge_runs:bool=False, update_interval:int=20):

  # Get active jobs in directory
  active_runs = [x for x in os.listdir(os.path.join(job_dir, 'runs')) if not x.startswith('DONE-')]

  # Make raw data dir if doesn't exist
  raw_data_dir = os.path.join(job_dir, 'outputs', 'raw')

  # Loop through active jobs
  for idx, r in enumerate(active_runs):
    logger.info(f"Processing active run {r} - {idx+1}/{len(active_runs)}")

    # See if end timestamp is present yet. If so mark job as done and ready to clean up
    res = glob.glob(os.path.join(job_dir, 'runs', r, "ts_padcirc_*"))
    job_done = True if len(res)>0 else False

    # Read TS file info and collect data.j
    job_ts = np.zeros(3)
    for f in glob.glob(os.path.join(job_dir, 'runs', r, 'ts_*')):
      if str.startswith(f, 'ts_start_'):
        job_ts[0] = datetime.datetime.strptime(str.split(f, 'ts_start_')[1],
            "%Y-%m-%d-%H:%M:%S").timestamp()
      if str.startswith(f, 'ts_adcprep_'):
        job_ts[1] = datetime.datetime.strptime(str.split(f, 'ts_adcprep_')[1],
            "%Y-%m-%d-%H:%M:%S").timestamp()
      if str.startswith(f, 'ts_padcirc_'):
        job_ts[2] = datetime.datetime.strptime(str.split(f, 'ts_padcirc_')[1],
            "%Y-%m-%d-%H:%M:%S").timestamp()

    # Get param vals for sample
    f13 = read_fort13(os.path.join(job_dir, 'runs', r, 'fort.13'))
    n_vals = f13['ValuesPerNode'].sel(AttrName=param).item(0)
    p_vals = ','.join([str(f13[f'v{x}'].sel(AttrName=param).item(0)) for x in range(n_vals)])
    ncap_str_1 = f'defdim("param",{n_vals});p_vals[$param]={{{p_vals}}}'
    ncap_str_2 = 'defdim("jc",3);job_ts[$jc]={' + ','.join([str(x) for x in job_ts]) + '}'

    # Process fort.63 File with proc_fort.sh shell script
    sample_type = r.split('_')[1]
    sample_num = r.split('_')[2]
    logger.debug(f"Processing fort.63.nc file.")
    f63 = os.path.join(job_dir, 'runs', r, 'fort.63.nc')
    cf63 = os.path.join(raw_data_dir, '.'.join([sample_type, sample_num])  + '.fort.63.nc')
    proc = subprocess.Popen(["proc_fort.sh", sample_num, f63, cf63, ncap_str_1, ncap_str_2],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    out = out.decode('utf-8')
    # First 16 lines contain lmod print - no error
    err = '\n'.join(err.decode('utf-8').split('\n')[16:])

    if err!='':
      logger.error(f"Unable to clean fort.63.nc for run {r} - {err}")
    else:
      logger.info("Successfully cleaned fort.63.nc file.")
      # if job_done ts set, then read job completion timestamps
      if job_done:
        # Clean run directory if purge is set
        rdir = os.path.join(job_dir, 'runs', r)
        if purge_runs:
          logger.info(f"Purging run directory {rdir}")
          res = subprocess.run(["rm", "-rf", rdir])
        else:
          done_rdir = os.path.join(job_dir, 'runs', 'DONE-' + r)
          logger.info(f"Moving run directory {rdir} to DONE")
          res = subprocess.run(["mv", rdir, done_rdir])


def pull_data_netcdf(job:str, ds_name:str, configs:dict):

  sample_size = configs[ds_name].pop('samples', 100)
  sample_type = configs[ds_name].pop('sample_type', 'uniform')
  nodes = configs[ds_name].pop('nodes', [])
  start_time = configs[ds_name].pop('start_time', None)
  end_time = configs[ds_name].pop('end_time', None)
  randomize = configs[ds_name].pop('randomize', False)


  def pre_proc(ds, st=start_time, et=end_time, n=nodes):
    ds = ds.drop_vars(['adcirc_mesh', 'depth', 'element', 'ibtype', 'ibtypee', 'max_nvdll', 'max_nvell', 'nvdll', 'nvell'])
    st = ds['time'][0] if st==None else st
    et = ds['time'][-1] if et==None else et
    ds = ds.sel(time=slice(st, et))
    ds = ds.sel(node=nodes)
    ds = ds.assign_coords(param=[('\lambda_'+str(x)) for x in range(len(ds['p_vals']))])
    ds = ds.assign_coords(node=nodes)
    ds = ds.expand_dims({"sample":[ds['p_vals'].attrs['sample']]})
    output = xa.Dataset({"param_samples": ds['p_vals'],
                         "water_levels": ds['zeta'].transpose("node",...)})
    return output

  sample_type = (sample_type + '.') if sample_type != '' else sample_type
  sample_files = glob.glob(os.path.join(job, 'outputs', 'raw', sample_type + '*.nc'))
  sample_size = len(sample_files) if sample_size>len(sample_files) else sample_size
  sample_files = sample_files[0:sample_size]

  all_ds = []
  logger.info(f"Pulling data from {sample_size} data files.")
  # logger.info("Files = %s" % ','.join([sample_files]))
  for i, s in enumerate(sample_files):
    logger.info(f"Processing {s} - {i}/{sample_size}")
    try:
      ds = xa.open_dataset(s)
    except Exception as e:
      logger.error(f"Unable to load {s} - {e}")
      continue
    all_ds.append(pre_proc(ds))
    ds.close()

  if len(all_ds)>0:
    logger.info(f"Concatenating {len(all_ds)} datasets.")
    output = xa.concat(all_ds, "sample")

    fpath = os.path.join(job, 'outputs', 'requests', ds_name + '.nc')
    logger.info(f"Writing output dataset to {fpath}")
    output.to_netcdf(fpath)
    output.close()

    # Unknown error occuring with open_mfdataset
    # pdb.set_trace()
    # logger.info(f"Pulling data from {sample_size} data files.")
    # logger.info("Files = %s" % ','.join([sample_files]))
    # with xa.open_mfdataset(sample_files, parallel=True, preprocess=pre_proc) as ds:
    #   fpath = os.path.join(job, 'outputs', ds_name + '.nc')
    #   logger.info(f"Writing output netcdf file to {fpath}")
    #   output.to_netcdf(fpath)

    return output
  else:
    return None


def load_configs(config_dir:str):
  configs = os.listdir(config_dir)

  res = {}
  for conf in configs:
    if not (conf.startswith('.') or conf.endswith('.done') or conf.endswith('.error')):
      try:
        name = conf.split('.json')[0]
        with open(os.path.join(config_dir,conf), 'r') as cf:
          res[name] = json.load(cf)
      except Exception as e:
        logger.info(f"Unable to load config {conf} - {e}.")
  return res


def main_loop(job_dir:str, update_interval:int=30):
  logger.info(f"Loading base adcirc configs.")
  adcirc_configs = process_adcirc_configs(os.path.join(job_dir,'base_inputs'))

  # Make raw data dir if doesn't exist
  raw_data_dir = os.path.join(job_dir, 'outputs', 'raw')
  res = subprocess.run(["mkdir", "-p", raw_data_dir])

  # Make data output dir if doesn't exist
  data_dir = os.path.join(job_dir, 'outputs', 'requests')
  res = subprocess.run(["mkdir", "-p", data_dir])

  global_nodes = []
  while True:
    if len(glob.glob(os.path.join(job_dir, 'END-DP')))>0:
      res = subprocess.run(["rm", os.path.join(job_dir, 'END-DP')])
      logger.info("Found END-DP file - Terminating data processing.")
      break

    # Load data request configs
    configs = load_configs(os.path.join(job_dir, 'out_data_configs'))

    for name in configs.keys():
      logger.info(f"Found config {name}")
      if 'coordinates' in configs[name].keys():
        logger.info(f"Calculating nodes closest to coordiantes.")
        for coord in configs[name]['coordinates']:
          configs[name]['nodes'].append(find_closest(adcirc_configs['X'].values,
                                                     adcirc_configs['Y'].values,
                                                     coord[0], coord[1]))
          configs[name]['nodes'] = sorted(set(configs[name]['nodes']))

      if name=='global':
        logger.info(f"Found global config! Updating global node list.")
        global_nodes = configs[name]['nodes']
        configs.drop('global')

    # Process run data
    res = process_run_data(job_dir, nodes=global_nodes)

    # Now process each data pull request config. If successful, then delete request config
    for name in configs.keys():
      # try:
      msg = f"Processing data request {name}\n"
      msg += f"Processing data request {name}\n"
      msg += f"Nodes: {configs[name]['nodes']}\n"
      msg += f"Start Time: {configs[name]['start_time']}\n"
      msg += f"End Time: {configs[name]['end_time']}\n"
      logger.info(msg)
      with timing(name) as pull_data:
        res = pull_data_netcdf(job_dir, name, configs)
        logger.info(f"Processed data request {name} successfully! Moving to done status.")
      logger.info('Total [%s]: %.6f s' % pull_data())
      # res = subprocess.run(["mv", os.path.join(job_dir, 'out_data_configs', name+'.json'),
      #   os.path.join(job_dir, 'out_data_configs', name+'.json.done')])
      # except Exception as e:
      #   logger.info(f"Unable to pull data for request {name} - {e}. Moving to error status.")
      #   res = subprocess.run(["mv", os.path.join(job_dir, 'out_data_configs', name+'.json'),
      #     os.path.join(job_dir, 'out_data_configs', name+'.json.error')])

    # Sleep until we update data again
    logger.info(f"Sleeping for {update_interval} seconds.")
    sleep(update_interval)


if __name__ == "__main__":
    # Parse command line options
    parser = argparse.ArgumentParser()
    parser.add_argument('job_dir', type=str, help='Full path to job directory.')
    parser.add_argument('-m', '--mode', choices=['MAIN', 'PULL_DATA'], type=str,
        default='MAIN', help='Mode to run. Defauls to main execution.')
    parser.add_argument('-u', '--update_interval', type=int, default=300,
        help="Data pull wait time in seconds.")
    parser.add_argument('-lf', '--log_file', type=str, default=None, help="Path to log file.")
    parser.add_argument('-ll', '--log_level', type=str, default='INFO',
        choices=['DEBUG','INFO','WARNING','ERROR','CRITICAL'], help='Set the logging level')
    args = parser.parse_args()

    # Initialize logger
    if args.log_file!=None:
      logging.basicConfig(level=args.log_level, filename=args.log_file,
          format='%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    else:
      logging.basicConfig(level=args.log_level,
          format='%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    while True:
      # Keep Trying main loop
      main_loop(args.job_dir, update_interval=args.update_interval)
      try:
        if args.mode=='MAIN':
          # Call main loop
          main_loop(args.job_dir, update_interval=args.update_interval)
        else:
          raise Exception("Unrecognized mode {args.mode}")
      except Exception as e:
        # Shouldn't get here. But keep retrying if not in PULL_DATA Mode
        logger.critical("Unexpected error encountered!")



