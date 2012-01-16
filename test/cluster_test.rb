require './src/cluster'
require 'test/unit'

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
    blognames, words, data = read_blogdata_file
    clust = Cluster.hcluster(data)
    printclust(clust, blognames)
  end

  def read_blogdata_file
    file = File.open("test/blogdata.txt")
    
    header = file.gets
    colnames = header.split("\t")[1..-1]
    rownames = []
    data = []

    while (line = file.gets)
      i = line.split("\t")
      rownames << i[0]
      data << i[1..-1].collect { |v| v.to_f }
    end

    return [rownames, colnames, data]
  end


  def printclust(clust, labels = nil, n = 0)
    # indent to make a hierarchy layout
    res = ""
    res += (' ' * n)
    if clust.id < 0
      # negative id means that this is branch
      res += labels[clust.id]
      # res += '-'
    else
      # positive id means that this is an endpoint
      if labels.nil?
        res += clust.id.to_s
      else 
        res += labels[clust.id]
      end
    end
    puts res

    # now print the right and left branches
    if !clust.left.nil? 
      printclust(clust.left, labels, n+1)
    end

    if !clust.right.nil? 
      printclust(clust.right, labels, n+1)
    end
  end
end