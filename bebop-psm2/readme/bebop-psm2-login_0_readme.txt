
Access a computing node from a login node, because there is a little difference on library between computing nodes and the login node.

1. Request computing nodes
$ salloc -p bdwall -t [number of minutes] -N [number of nodes]
e.g. salloc -p bdwall -t 60 -N 1

2. Check the assigned computing nodes
$ squeue -u [user ID]
e.g. squeue -u tshu
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            716461    bdwall     bash     tshu  R    3:55:36      1 bdw-0031

3. Access the computing node
$ ssh [node name]
e.g. ssh bdw-0031

