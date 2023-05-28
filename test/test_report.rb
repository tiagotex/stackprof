$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'minitest/autorun'

class ReportDumpTest < MiniTest::Test
  require 'stringio'

  def test_dump_to_stdout
    data = {}
    report = StackProf::Report.new(data)

    out, _err = capture_subprocess_io do
      report.print_dump
    end

    assert_dump data, out
  end

  def test_dump_to_file
    data = {}
    f = StringIO.new
    report = StackProf::Report.new(data)

    report.print_dump(f)

    assert_dump data, f.string
  end

  private

  def assert_dump(expected, marshal_data)
    assert_equal expected, Marshal.load(marshal_data)
  end
end

class ReportReadTest < MiniTest::Test
  require 'pathname'

  def test_from_file_read_json
    file = fixture("profile.json")
    report = StackProf::Report.from_file(file)

    assert_equal({ mode: "cpu" }, report.data)
  end

  def test_from_file_read_marshal
    file = fixture("profile.dump")
    report = StackProf::Report.from_file(file)

    assert_equal({ mode: "cpu" }, report.data)
  end

  private

  def fixture(name)
    Pathname.new(__dir__).join("fixtures", name)
  end
end

class ReportCleanupIoWaitAndGcStacks < MiniTest::Test
  def test_empty_data
    report = StackProf::Report.new({})

    report.cleanup_io_wait_and_gc_stacks

    assert_equal({}, report.data)
  end

  def test_cleaning_gc_stacks
    data = {
      frames: {
        1  => { name: "(garbage collection)", file: "" },
        3  => { name: "(marking)", file: "" },
        5  => { name: "(sweeping)", file: "" },
        90 => { name: "<main>", file: "test.rb" },
        91 => { name: "block in <main>", file: "test.rb", line: 3 },
        92 => { name: "block in <main>", file: "test.rb", line: 6 }
      },
      raw: [2, 90, 91, 1, 3, 90, 91, 92, 1, 2, 1, 3, 3, 2, 1, 5, 1, 1, 1, 2, 2, 90, 91, 1]
    }

    result = {
      frames: {
        1  => { name: "(garbage collection)", file: "" },
        3  => { name: "(marking)", file: "" },
        5  => { name: "(sweeping)", file: "" },
        90 => { name: "<main>", file: "test.rb" },
        91 => { name: "block in <main>", file: "test.rb", line: 3 },
        92 => { name: "block in <main>", file: "test.rb", line: 6 }
      },
      raw: [
        2, 90, 91, 1, 3, 90, 91, 92, 1, 5, 90, 91, 92, 1, 3, 3, 5, 90, 91, 92, 1, 5, 1, 4, 90, 91, 92, 1, 2, 2, 90, 91, 1
      ]
    }

    report = StackProf::Report.new(data)

    report.cleanup_io_wait_and_gc_stacks

    assert_equal(result, report.data)
  end

  def test_cleaning_io_wait_for_puma_single_mode
    file = Pathname.new(__dir__).join("fixtures", "profile_puma_single_mode.json")
    report = StackProf::Report.from_file(file)

    report.cleanup_io_wait_and_gc_stacks

    file = Pathname.new(__dir__).join("fixtures", "profile_puma_single_mode_clean.json")
    result = StackProf::Report.from_file(file).data

    assert_equal(result, report.data)
  end

  def test_cleaning_io_wait_for_puma_cluster_mode
    file = Pathname.new(__dir__).join("fixtures", "profile_puma_cluster_mode.json")
    report = StackProf::Report.from_file(file)

    report.cleanup_io_wait_and_gc_stacks

    File.write(Pathname.new(__dir__).join("fixtures", "profile_puma_cluster_mode_clean.json"), JSON.dump(report.data))
    file = Pathname.new(__dir__).join("fixtures", "profile_puma_cluster_mode_clean.json")
    result = StackProf::Report.from_file(file).data

    assert_equal(result, report.data)
  end
end
