# wrk - a HTTP benchmarking tool

  wrk is a modern HTTP benchmarking tool capable of generating significant
  load when run on a single multi-core CPU. It combines a multithreaded
  design with scalable event notification systems such as epoll and kqueue.

  An optional LuaJIT script can perform HTTP request generation, response
  processing, and custom reporting. Details are available in SCRIPTING and
  several examples are located in [scripts/](scripts/).

## Install wrk Forked Version

Installing wrk forked version as a separate command `wrk-cmm` side by side with existing `wrk` binary:

    git clone -b centminmod https://github.com/centminmod/wrk wrk-cmm
    cd wrk-cmm
    make
    \cp -af wrk /usr/local/bin/wrk-cmm

Installing wrk forked version as `wrk` binary (will overwrite existing `/usr/local/bin/wrk` binary if installed):

    git clone -b centminmod https://github.com/centminmod/wrk wrk-cmm
    cd wrk-cmm
    make
    \cp -af wrk /usr/local/bin/wrk

You can search wrk forked version code via https://sourcegraph.com/github.com/centminmod/wrk@centminmod

## Command Line Options

```
wrk-cmm -v
wrk 4.1.0-42-g08c17d7 [epoll] Copyright (C) 2012 Will Glozer
Usage: wrk <options> <url>                            
  Options:                                            
    -c, --connections <N>  Connections to keep open   
    -d, --duration    <T>  Duration of test           
    -t, --threads     <N>  Number of threads to use   
                                                      
    -b, --bind-ip     <S>  Source IP (or CIDR mask)   
                                                      
    -s, --script      <S>  Load Lua script file       
    -H, --header      <H>  Add header to request      
        --latency          Print latency statistics   
    -D  --delay-stats <T>  Stats collection delay     
        --breakout         Print breakout statistics  
        --timeout     <T>  Socket/request timeout     
    -v, --version          Print version details      
                                                      
  Numeric arguments may include a SI unit (1k, 1M, 1G)
  Time arguments may include a time unit (2s, 2m, 2h)
```

## Basic Usage

    wrk -t12 -c400 -d30s http://127.0.0.1:8080/index.html

  This runs a benchmark for 30 seconds, using 12 threads, and keeping
  400 HTTP connections open.

  Output:

    Running 30s test @ http://127.0.0.1:8080/index.html
      12 threads and 400 connections
      Thread Stats   Avg      Stdev     Max   +/- Stdev
        Latency   635.91us    0.89ms  12.92ms   93.69%
        Req/Sec    56.20k     8.07k   62.00k    86.54%
      22464657 requests in 30.00s, 17.76GB read
    Requests/sec: 748868.53
    Transfer/sec:    606.33MB

## Bind Source IP

This forked versions adds [source IP binding](https://github.com/wg/wrk/pull/262) support.

The -b (or --bind-ip) command line option can accept either single IP address, or CIDR mask, e.g.:

    wrk -b 127.0.0.2 http://localhost/
    wrk -b 127.0.0.1/28 http://localhost/

In addition, the IP_BIND_ADDRESS_NO_PORT socket option is being used on supported systems (Linux >= 4.2, glibc >= 2.23) in order to get even more concurrent connections due to an ability to share source port (see [1](https://kernelnewbies.org/Linux_4.2#head-8ccffc90738ffcb0c20caa96bae6799694b8ba3a), [2](https://git.kernel.org/torvalds/c/90c337da1524863838658078ec34241f45d8394d)).

Also, EADDRNOTAVAIL from connect() is now treated as a critical error, leading wrk to quit immediately.

## Breakout Statistics

This forked versions adds [breakout](https://github.com/wg/wrk/pull/293) statistics to show new metrics for connection times:

* Connect - the time between a request for a socket started and when a socket was established (includes TLS negotiation/handshake). This gives an idea how much proxy and TLS handshake negotiations may take.
* TTFB a.k.a. first byte - the time to first byte or the time between the connect happening and the receipt of the first byte of the http protocol (not document). This gives an idea how much time is spent during the request with the server processing the request then returning an answer.
* TTLB a.k.a. last byte - the time from when the first byte was received to the last byte being received. This give an idea of the bandwidth.

Example:

    wrk -t2 -c100 -d5s --breakout http://localhost

  Output:

    wrk -t2 -c100 -d5s --breakout http://localhost
    Running 5s test @ http://localhost
      2 threads and 100 connections
      Thread Stats   Avg     Stdev       Max       Min   +/- Stdev
      Thread Stats   Avg      Stdev     Max   +/- Stdev
        Latency     1.86ms    4.56ms   85.17ms   59.00us   93.61%
        Connect   673.39us  307.47us    1.23ms  158.00us   59.00%
        TTFB        1.85ms    4.56ms   85.17ms   56.00us   93.61%
        TTLB        2.06us    3.08us    0.92ms    1.00us   99.86%
        Req/Sec    63.17k     3.71k    70.95k    56.17k    59.00%
      628391 requests in 5.00s, 2.40GB read
    Requests/sec: 125642.59
    Transfer/sec:    492.23MB

## json.lua

This forked version adds [scripts/json.lua](https://github.com/wg/wrk/pull/305) script to report results and latency distribution in JSON format.

Example:

    wrk -t2 -c100 -d5s -s scripts/json.lua http://localhost

  Output:

```
wrk -t2 -c100 -d5s -s scripts/json.lua http://localhost                                
Running 5s test @ http://localhost
  2 threads and 100 connections
  Thread Stats   Avg     Stdev       Max       Min   +/- Stdev
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     2.07ms    5.15ms   86.85ms   52.00us   93.37%
    Req/Sec    63.37k     4.10k    71.18k    53.40k    62.00%
  630256 requests in 5.00s, 2.41GB read
Requests/sec: 126025.99
Transfer/sec:    493.73MB

JSON Output
-----------

{
        "requests": 630256,
        "duration_in_microseconds": 5001000.00,
        "bytes": 2589091648,
        "requests_per_sec": 126025.99,
        "bytes_transfer_per_sec": 517714786.64,
        "latency_distribution": [
                {
                        "percentile": 50,
                        "latency_in_microseconds": 599
                },
                {
                        "percentile": 75,
                        "latency_in_microseconds": 881
                },
                {
                        "percentile": 90,
                        "latency_in_microseconds": 4557
                },
                {
                        "percentile": 99,
                        "latency_in_microseconds": 27366
                },
                {
                        "percentile": 99.999,
                        "latency_in_microseconds": 84136
                }
        ]
}
```

## Multiple Paths

`scripts/multplepaths.lua` from https://github.com/timotta/wrk-scripts allows yout to test a list of url paths in `paths.txt` text file you create with one url path per line.

```
wrk-cmm -t2 -c50 -d20s --latency --breakout -s scripts/multiplepaths.lua http://localhost
multiplepaths: Found 2 paths
multiplepaths: Found 2 paths
multiplepaths: Found 2 paths
Running 20s test @ http://localhost
  2 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     5.83ms   25.29ms 260.85ms   96.40%
    Connect   302.54us  129.08us 538.00us   60.00%
    TTFB        5.82ms   25.30ms 260.84ms   96.40%
    TTLB       11.41us   25.62us   8.94ms   99.90%
    Req/Sec    39.53k     8.47k   48.10k    94.59%
  Latency Distribution
     50%  399.00us
     75%  823.00us
     90%    7.22ms
     95%   11.02ms
     99%  160.52ms
  1539109 requests in 20.00s, 33.10GB read
Requests/sec:  76947.77
Transfer/sec:      1.66GB
```

## Examples

Combining `--breakout`, `--latency` and `-s scripts/json.lua` forked additions

```
wrk -t2 -c200 -d30s --breakout --latency -s scripts/json.lua http://localhost 
Running 30s test @ http://localhost
  2 threads and 200 connections
  Thread Stats   Avg     Stdev       Max       Min   +/- Stdev
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     2.86ms    4.83ms  135.78ms   77.00us   89.93%
    Connect     1.35ms  598.49us    2.39ms  325.00us   57.00%
    TTFB        2.86ms    4.83ms  135.77ms   74.00us   89.93%
    TTLB        2.08us    2.93us    1.37ms    1.00us   99.85%
    Req/Sec    63.29k     2.06k    68.21k    51.87k    65.67%
  Latency Distribution
  50.00%    1.22ms
  75.00%    1.45ms
  90.00%    7.75ms
  95.00%   12.41ms
  99.00%   23.91ms
  99.99%   71.01ms
  3777565 requests in 30.00s, 14.45GB read
Requests/sec: 125908.95
Transfer/sec:    493.27MB

JSON Output
-----------

{
        "requests": 3777565,
        "duration_in_microseconds": 30002356.00,
        "bytes": 15518237020,
        "requests_per_sec": 125908.95,
        "bytes_transfer_per_sec": 517233947.23,
        "latency_distribution": [
                {
                        "percentile": 50,
                        "latency_in_microseconds": 1222
                },
                {
                        "percentile": 75,
                        "latency_in_microseconds": 1447
                },
                {
                        "percentile": 90,
                        "latency_in_microseconds": 7746
                },
                {
                        "percentile": 99,
                        "latency_in_microseconds": 23913
                },
                {
                        "percentile": 99.999,
                        "latency_in_microseconds": 124661
                }
        ]
}
```

## Tutorials & Articles

* https://www.digitalocean.com/community/tutorials/how-to-benchmark-http-latency-with-wrk-on-ubuntu-14-04

## Benchmarking Tips

  The machine running wrk must have a sufficient number of ephemeral ports
  available and closed sockets should be recycled quickly. To handle the
  initial connection burst the server's listen(2) backlog should be greater
  than the number of concurrent connections being tested.

  A user script that only changes the HTTP method, path, adds headers or
  a body, will have no performance impact. Per-request actions, particularly
  building a new HTTP request, and use of response() will necessarily reduce
  the amount of load that can be generated.

## Acknowledgements

  wrk contains code from a number of open source projects including the
  'ae' event loop from redis, the nginx/joyent/node.js 'http-parser',
  and Mike Pall's LuaJIT. Please consult the NOTICE file for licensing
  details.

## Cryptography Notice

  This distribution includes cryptographic software. The country in
  which you currently reside may have restrictions on the import,
  possession, use, and/or re-export to another country, of encryption
  software. BEFORE using any encryption software, please check your
  country's laws, regulations and policies concerning the import,
  possession, or use, and re-export of encryption software, to see if
  this is permitted. See <http://www.wassenaar.org/> for more
  information.

  The U.S. Government Department of Commerce, Bureau of Industry and
  Security (BIS), has classified this software as Export Commodity
  Control Number (ECCN) 5D002.C.1, which includes information security
  software using or performing cryptographic functions with symmetric
  algorithms. The form and manner of this distribution makes it
  eligible for export under the License Exception ENC Technology
  Software Unrestricted (TSU) exception (see the BIS Export
  Administration Regulations, Section 740.13) for both object code and
  source code.
