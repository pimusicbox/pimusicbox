import pkg_resources
from subprocess import call

dists = [d for d in pkg_resources.working_set]
for dist in dists:
    call("pip install --upgrade " + dist.project_name, shell=True)
