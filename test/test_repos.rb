# test_repos.rb

require 'minitest/autorun'
require 'repo_compiled'
require 'repo_rfs'

class TestRepos < MiniTest::Test

  RepoC = RepoCompiled.new
  RepoR = RepoRfs.new

  describe "selection sizes" do
    it "rfs" do
      assert_equal(
        [87413, 87457, 87453, 87459, 87488, 87486, 87728, 87713, 87725, 87727],
        RepoR.graph_data(10, "869129a").map(&:last)
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
    end
  end
end
