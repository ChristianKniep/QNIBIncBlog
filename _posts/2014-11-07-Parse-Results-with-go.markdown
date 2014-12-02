---
layout: post
title:  "Process benchmark results with golang"
date:   2014-11-07 8:00
categories: golang
tags: golang blog
---

Oh boy, I realy need to get out of the Moscovian airport, 15 hours is enough. But...

...at least it gave me some time to spare. After adding some MPI Benchmark results to my [recent write-up]({% post_url 2014-11-06-Containerized-MPI-workloads %}})
about my talk at HPC Advisory council I assume we all agree that the uglyness of my bash solution is endless.
Please cover your eyes, here we go one more time:

{% highlight bash %}
$ cat avg_2dig.sh
function doavg {
   echo "scale=2;($(echo $*|sed -e 's/ /+/g'))/$#"|bc
}

function avg2dig() {
    val=$(cat $1|egrep "^[0-9][0-9]?\s+[0-9\.]+$"|awk '{print $2}'|xargs)
    if [ "X${val}" != "X" ];then
        doavg  ${val}
    fi
}
$ source avg_2dig.sh
$ for x in $(find job_results/mpi/ -name osu_alltoall.out|xargs);do echo -n "$x -> ";avg2dig $x;done|grep 1.8.3
job_results/mpi/venus/omp-1.8.3/2014-11-06_22-03-59/osu_alltoall.out -> 1.46
job_results/mpi/centos/7/omp-1.8.3/2014-11-06_22-05-33/osu_alltoall.out -> 1.41
job_results/mpi/centos/6/omp-1.8.3/2014-11-06_22-05-45/osu_alltoall.out -> 1.43
job_results/mpi/ubuntu/12/omp-1.8.3/2014-11-06_22-07-02/osu_alltoall.out -> 1.42
{% endhighlight %}
  
2min of bash coding and I am up and running. But that should not be the last word about the parsing.

### One iteration to golang

What you are about to see is just one iteration towards happiness. I am going to reuse something I have done to parse the results of HPCG.
To warn you upfront, I do not use interfaces, but a straight forward chain of functions. I guess this is still ugly, but less ugly then the bash version.

Let's call it "agile programming", a perfect excuse to not get it right in the first place... :P

### Why oh why?

My first attempt was a small piece of python to parse the results. But since I had CentOS 6 and CentOS 7 I got python2.6 and python2.7.
Let the dependency hell begin... With golang I am able to build a static binary - no strings attached - and I can forget about the
target platform; at least if it is Linux 64bit, which is going to be the case. If not I can even crosscompile...

#### Basic concept

The fundamentals are easy. Within the job I fill a file ```job.cfg``` which stores key/value pairs given general information.

{% highlight bash %}
$ cat job.cfg
MPI_VER=omp-sys
BTL_OPTS=self,openib
DIRNAME=scripts/centos/7/omp-sys/mpi
OS_VER=7
OS_BASE=centos
SLURM_PARTITION=cos7
MPI_PATH=/usr/lib64/openmpi
START_DATE=2014-11-06_19:01:57
SLURM_NODELIST=cos7_[1-2]
SLURM_JOBID=627
WALL_CLOCK=0
{% endhighlight %}

Side note: Within golang I use my beloved docopt (I use it in python for some time now) to parse the command line arguments.

{% highlight bash %}
func main() {
    usage := `evaluate HPCG output

    Usage:
      eval-hpcg [options] <path>
      eval-hpcg -h | --help
      eval-hpcg --version

    Options:
      -h --help     Show this screen.
      --version     Show version.
    `
    var params map[string]string
    params = make(map[string]string)
    arguments, _ := docopt.Parse(usage, nil, true, "0.1", false)
    path := arguments["<path>"].(string)
    // enter directory
    walkDir(path, params)
}
{% endhighlight %}

The script (binary, that is!) is looking for a certain file (should be the job.cfg), provides the hook to evaluate certain output files (in a bit) and formats the result neatly.

{% highlight bash %}
$ go build && ./eval-osu-mpi ../../hpcac-job-results/mpi/
| MTIME:2014-11-07_09:01:21 | NODES:cos6_[1-2]      | MPI:omp-1.5.4  | WTIME:   2.0 | *WAIT_FOR_IT* |
| MTIME:2014-11-07_09:01:21 | NODES:cos6_[1-2]      | MPI:omp-1.6.4  | WTIME:   1.0 | *WAIT_FOR_IT* |
{% endhighlight %}

The ```*WAIT_FOR_IT*``` part is the customized part. For the MPI Benchmark we are looking out for files matching ```osu_(.*).out```.
Matching files are handed over to ```parseJobOut```, which will process the bugger.

{% highlight bash %}
func parseJobOut(file_path string, subtest string) map[string]string {
	job_res := make(map[string]string)
	file_descr, err := os.Open(file_path)
	if err != nil {
		panic(err)
	}
	defer file_descr.Close()

	var res list.List
	if subtest == "alltoall" {
		// define pattern to look for
		re := regexp.MustCompile("([0-9]+)[\t ]+([0-9.]+)")
		scanner := bufio.NewScanner(file_descr)
		for scanner.Scan() {
			mat := re.FindStringSubmatch(scanner.Text())
                        // MAGIC HERE...
                        // Looking for lines matching and casting them to float64
		}

		// Iterate through list and sum up total
		var total float64 = 0
		for e := res.Front(); e != nil; e = e.Next() {
			total += e.Value.(float64)
		}
		avg := total / float64(res.Len())
		job_res["a2a_avg"] = fmt.Sprintf("%f", avg)
		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}
	}
	return job_res
}
{% endhighlight %}

In the print function, we now present the a2a average as an additional column.

{% highlight bash %}
func printDir(path string, params map[string]string) {
	job_cfg := evalResultDir(path)
	wtime, _ := strconv.ParseFloat(job_cfg["wall_clock"], 64)
	a2a_avg, _ := strconv.ParseFloat(job_cfg["a2a_avg"], 64)
	_, present := job_cfg["yaml_date"]
	if present {
		fmt.Printf("| YTIME:%s |", job_cfg["yaml_date"])
	} else {
		fmt.Printf("| MTIME:%s |", job_cfg["mod_time"])
	}
	fmt.Printf(" NODES:%-15s |", job_cfg["slurm_nodelist"])
	fmt.Printf(" MPI:%-10s |", job_cfg["mpi_ver"])
	fmt.Printf(" WTIME:%6.1f |", wtime)
	fmt.Printf(" A2A_AVG:%6.2f |", a2a_avg)  // HERE!!!
	fmt.Printf("\n")
}
{% endhighlight %}

And off we go...
{% highlight bash %}
$ go build && ./eval-osu-mpi ../../hpcac-job-results/mpi/
| MTIME:2014-11-07_09:01:21 | NODES:cos6_[1-2]      | MPI:omp-1.5.4  | WTIME:   2.0 | A2A_AVG:  1.48 |
| MTIME:2014-11-07_09:01:21 | NODES:cos6_[1-2]      | MPI:omp-1.6.4  | WTIME:   1.0 | A2A_AVG:  1.38 |
| MTIME:2014-11-07_09:01:21 | NODES:cos6_[1-2]      | MPI:omp-1.8.3  | WTIME:   1.0 | A2A_AVG:  1.43 |
| MTIME:2014-11-06_21:42:21 | NODES:cos6_[1-2]      | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.47 |
| MTIME:2014-11-06_22:10:28 | NODES:cos6_[1-2]      | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.43 |
| MTIME:2014-11-07_09:01:21 | NODES:cos7_[1-2]      | MPI:omp-1.5.4  | WTIME:   1.0 | A2A_AVG:  1.44 |
| MTIME:2014-11-07_09:01:21 | NODES:cos7_[1-2]      | MPI:omp-1.6.4  | WTIME:   2.0 | A2A_AVG:  1.39 |
| MTIME:2014-11-07_09:01:21 | NODES:cos7_[1-2]      | MPI:omp-1.8.3  | WTIME:   1.0 | A2A_AVG:  1.41 |
| MTIME:2014-11-06_21:42:21 | NODES:cos7_[1-2]      | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.62 |
| MTIME:2014-11-06_22:10:28 | NODES:cos7_[1-2]      | MPI:omp-sys    | WTIME:   0.0 | A2A_AVG:  1.70 |
| MTIME:2014-11-06_22:10:28 | NODES:cos7_[1-2]      | MPI:omp-sys    | WTIME:   0.0 | A2A_AVG:  1.70 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-1.5.4  | WTIME:   2.0 | A2A_AVG:  1.39 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-1.5.4  | WTIME:   1.0 | A2A_AVG:  1.44 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-1.6.4  | WTIME:   2.0 | A2A_AVG:  1.47 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-1.8.3  | WTIME:   2.0 | A2A_AVG:  1.43 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  2.76 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  2.73 |
| MTIME:2014-11-07_09:01:21 | NODES:u12_[1-2]       | MPI:omp-sys    | WTIME:   2.0 | A2A_AVG:  2.75 |
| MTIME:2014-11-07_09:01:21 | NODES:venus[001-002]  | MPI:omp-1.5.4  | WTIME:   2.0 | A2A_AVG:  1.49 |
| MTIME:2014-11-07_09:01:21 | NODES:venus[001-002]  | MPI:omp-1.6.4  | WTIME:   1.0 | A2A_AVG:  1.40 |
| MTIME:2014-11-07_09:01:21 | NODES:venus[001-002]  | MPI:omp-1.8.3  | WTIME:   1.0 | A2A_AVG:  1.46 |
| MTIME:2014-11-06_21:42:21 | NODES:venus[001-002]  | MPI:omp-sys    | WTIME:  15.0 | A2A_AVG: 21.69 |
| MTIME:2014-11-06_21:42:21 | NODES:venus[001-002]  | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.71 |
| MTIME:2014-11-06_22:10:28 | NODES:venus[001-002]  | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.72 |
| MTIME:2014-11-06_22:10:28 | NODES:venus[001-002]  | MPI:omp-sys    | WTIME:   1.0 | A2A_AVG:  1.70 |
{% endhighlight %}

The sourcecode could be found [here](https://github.com/ChristianKniep/qnib.go/blob/master/eval-osu-mpi/main.go).

### Next

There is a lot of stuff that had to be improved... The plane is boarding in a bit.
To be continued. :)

- adding flag to group lines for a all pairs of nodes and MPI version. Calculating an average and std deviation to run a benchmark a couple of times and fetch the overall result.
- MTIME should be fetch from job.cfg to be the actual runtime of the job.
- ...