from pylauncher4 import FileCommandlineGenerator
import os

dir_path = os.path.dirname(os.path.realpath(__file__))

def test_json_init():
    infile = dir_path + "/jobs_list.json"
    gen = FileCommandlineGenerator(infile)
    njobs = len(gen)
    assert njobs == 4

    for i in range(njobs):
        job = gen.next()
        assert job["id"] is not None and job["pre_process"] is not None and job["post_process"] is not None
