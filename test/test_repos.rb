# test_repos.rb

require 'minitest/autorun'
require 'repo_compiled'

class TestRepos < MiniTest::Test

  RepoC = RepoCompiled.new
  RepoR = Repo.new Dir.rfs, /^assets$/, /\.txt$/

  describe "selection sizes" do
    it "rfs" do
      assert_equal(
        [87413, 87457, 87453, 87459, 87488, 87486, 87728, 87713, 87725, 87727],
        RepoR.graph_data(10, "869129a").map(&:last)
      )
      assert_equal(
        [17510, 17565, 17510, 17523, 18439, 18354, 18326, 18301, 18307, 18568],
        RepoR.graph_data(10, "6e64015").map(&:last)
      )
    end

    it "compiled" do
      assert_equal(
        [228379, 228356, 227962, 227806, 227907,
          227737, 227810, 227680, 228177, 228177],
        RepoC.graph_data(10, "ad9ce5e").map(&:last)
      )
      assert_equal(
        [337520, 337364, 338294, 337921, 338812,
          338794, 338815, 338611, 338285, 338729],
        RepoC.graph_data.map(&:last)[-10..-1]
      )
      if ARGV[0]
        subset = RepoC.subset "cd6903f"
        content = subset.map do |c|
          [c.oid[0..6], c.time.to_minute(true), c.size.to_s].join ","
        end.join "\n"
        dir = Dir.db "data/repo"
        prev_content = File.read(dir + "/compiled.txt")
        File.write dir + "/compiled_.txt", content
        assert_equal prev_content, content
      end
    end
  end
end
