require './src/cluster'
require 'test/unit'
require './test/test_utils'

class ClusterTest  < Test::Unit::TestCase
  
  def setup
    @text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat 
    cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  end

  def test_get_words
    assert_equal Cluster.get_words(@text).size, 69
  end

  def test_word_count
    # should ignore everything, as no word appears less than 10% of the time or more than 50%
    assert_equal Cluster.word_count(@text), {}

    # only words that appear between 4% and 50% of the time
    assert_equal Cluster.word_count(@text, 0.04), {"ut"=>3, "in"=>3}
  end

  def test_hcluster
    blognames, words, data = read_data_file("test/blogdata.txt")
    clust = Cluster.hcluster(data)
    printclust(clust, blognames)
  end

  def test_kcluster
    blognames, words, data = read_data_file("test/blogdata.txt")
    kclust = Cluster.kcluster(data, 10, 5)

    for k in 0...kclust.size
      puts "Cluster #{k+1}: "
      for i in 0...kclust[k].size
        puts blognames[kclust[k][i]]
      end
      puts ""
    end
  end

  def test_tanimoto_hcluster
    blognames, words, data = read_data_file("test/zebo.txt")
    clust = Cluster.hcluster(data, :tanimoto)
    printclust(clust, blognames)
  end


end