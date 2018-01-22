# wrk - a HTTP benchmarking tool

  wrk is a modern HTTP benchmarking tool capable of generating significant
  load when run on a single multi-core CPU. It combines a multithreaded
  design with scalable event notification systems such as epoll and kqueue.

  An optional LuaJIT script can perform HTTP request generation, response
  processing, and custom reporting. Details are available in SCRIPTING and
  several examples are located in [scripts/](scripts/).

## Install

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

## Command Line Options

```
wrk
Usage: wrk <options> <url>                            
  Options:                                            
    -c, --connections <N>  Connections to keep open   
    -d, --duration    <T>  Duration of test           
    -t, --threads     <N>  Number of threads to use   
                                                      
    -b, --bind-ip     <S>  Source IP (or CIDR mask)   
                                                      
    -s, --script      <S>  Load Lua script file       
    -H, --header      <H>  Add header to request      
        --latency          Print latency statistics   
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
    Thread Stats   Avg      Stdev     Max   +/- Stdev
      Latency   407.49us  284.92us   4.07ms   66.39%
      Connect    52.79us   92.59us 773.00us   94.25%
      TTFB      405.60us  285.11us   4.07ms   66.36%
      TTLB        0.92us    0.34us  30.00us   89.43%
      Req/Sec   125.99k     7.61k  141.40k    70.00%
    1253135 requests in 5.00s, 4.79GB read
    Requests/sec: 250593.32
    Transfer/sec:      0.96GB

## json.lua

This forked version adds [scripts/json.lua](https://github.com/wg/wrk/pull/305) script to report results and latency distribution in JSON format.

Example:

    wrk -t2 -c100 -d5s -s scripts/json.lua http://localhost

  Output:

```
wrk -t2 -c100 -d5s -s scripts/json.lua http://localhost                                
Running 5s test @ http://localhost
  2 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   392.43us  234.56us   3.17ms   63.90%
    Req/Sec   126.95k     7.35k  138.96k    75.00%
  1262082 requests in 5.00s, 4.83GB read
Requests/sec: 252380.97
Transfer/sec:      0.97GB

JSON Output
-----------

{
        "requests": 1262082,
        "duration_in_microseconds": 5000702.00,
        "bytes": 5184620456,
        "requests_per_sec": 252380.97,
        "bytes_transfer_per_sec": 1036778527.49,
        "latency_distribution": [
                {
                        "percentile": 50,
                        "latency_in_microseconds": 403
                },
                {
                        "percentile": 75,
                        "latency_in_microseconds": 545
                },
                {
                        "percentile": 90,
                        "latency_in_microseconds": 685
                },
                {
                        "percentile": 99,
                        "latency_in_microseconds": 1011
                },
                {
                        "percentile": 99.999,
                        "latency_in_microseconds": 2361
                }
        ]
}
```

## Examples

Combining `--breakout`, `--latency` and `-s scripts/json.lua` forked additions

```
wrk -t2 -c200 -d30s --breakout --latency -s scripts/json.lua http://localhost 
Running 30s test @ http://localhost
  2 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     0.88ms  750.97us  21.61ms   71.06%
    Connect    54.91us  112.79us   1.58ms   97.51%
    TTFB        0.88ms  751.07us  21.60ms   71.06%
    TTLB        0.93us    0.46us 786.00us   89.81%
    Req/Sec   128.02k     7.83k  149.03k    84.33%
  Latency Distribution
     50%  687.00us
     75%    1.27ms
     90%    1.97ms
     99%    2.99ms
  7641549 requests in 30.00s, 29.24GB read
Requests/sec: 254708.86
Transfer/sec:      0.97GB

JSON Output
-----------

{
        "requests": 7641549,
        "duration_in_microseconds": 30001112.00,
        "bytes": 31391407292,
        "requests_per_sec": 254708.86,
        "bytes_transfer_per_sec": 1046341458.68,
        "latency_distribution": [
                {
                        "percentile": 50,
                        "latency_in_microseconds": 687
                },
                {
                        "percentile": 75,
                        "latency_in_microseconds": 1273
                },
                {
                        "percentile": 90,
                        "latency_in_microseconds": 1968
                },
                {
                        "percentile": 99,
                        "latency_in_microseconds": 2993
                },
                {
                        "percentile": 99.999,
                        "latency_in_microseconds": 12450
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
