require "stackprof"

options = {}
options[:mode] = ENV["STACKPROF_MODE"].to_sym if ENV.key?("STACKPROF_MODE")
options[:interval] = Integer(ENV["STACKPROF_INTERVAL"]) if ENV.key?("STACKPROF_INTERVAL")
options[:raw] = true if ENV["STACKPROF_RAW"]
options[:ignore_gc] = true if ENV["STACKPROF_IGNORE_GC"]
options[:clean_io_wait_and_gc] = true if ENV["STACKPROF_CLEAN_IO_WAIT_AND_GC"]

at_exit do
  StackProf.stop
  output_path = ENV.fetch("STACKPROF_OUT") do
    require "tempfile"
    Tempfile.create(["stackprof", ".json"]).path
  end
  flamegraph = StackProf.results(0, 0)

  # report = StackProf::Report.from_file('sample-data1.json')
  # pp report.print_timeline_flamegraph
  File.write('./aa.json', JSON.dump(flamegraph))
  $stderr.puts("StackProf results dumped at: aa.json")
end

StackProf.start(**options)
