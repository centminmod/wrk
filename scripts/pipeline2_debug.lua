-- https://doc.networknt.com/tool/wrk-perf/
-- wrk -t2 -c10 -d10s -s scripts/pipeline2_debug.lua http://localhost -- / 5
-- https://github.com/networknt/microservices-framework-benchmark
-- https://en.wikipedia.org/wiki/HTTP_pipelining

init = function(args)
   request_uri = args[1]
   depth = tonumber(args[2]) or 1

   local r = {}
   for i=1,depth do
     r[i] = wrk.format(nil, request_uri)
   end
   req = table.concat(r)
end

request = function()
   return req
end

response = function (status, headers, body)
  io.write("------------------------------\n")
  io.write("Response with status: ".. status .."\n")
  io.write("------------------------------\n")

  io.write("[response] Body:\n")
  io.write(body .. "\n")
end