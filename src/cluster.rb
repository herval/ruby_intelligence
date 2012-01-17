module Cluster

# assemble a list of words and their occurences. Since words like “the” will appear too much 
# and others like “flim-flam” might only appear once, you can reduce the total number of words included by 
# selecting only those words that are within maximum and minimum percentages.
def self.word_count(str, min_occurrence = 0.1, max_occurence = 0.5)
	words = {}
	all_words = get_words(str)

	for word in all_words
		words[word] ||= 0
		words[word] += 1
	end

	for word in words.keys
	  frac = words[word].to_f/all_words.size
	  words.delete(word) if frac < min_occurrence || frac > max_occurence
	end

	words
end

# retrieves a list of words
def self.get_words(str)
	# Remove all the HTML tags
	txt = str.gsub(/<[^>]+>/, "")
	# Split words by all non-alpha characters
	words = txt.split(/[^A-Z^a-z]+/)
	# Convert to lowercase
	return words.collect(&:downcase)
end

def self.pearson(v1, v2)
	# Add up all the preferences
	sum1 = v1.inject(&:+)
	sum2 = v2.inject(&:+)

	# Sum up the squares
	sum1Sq = v1.collect { |it| it**2 }.inject(&:+)
	sum2Sq = v2.collect { |it| it**2 }.inject(&:+)

	# Sum up the products
	pSum = (0...v1.size).collect { |i| v1[i] * v2[i] }.inject(&:+) 

	# Calculate Pearson score
	n = v1.size
	num = pSum - (sum1 * sum2 / n)
	den = Math.sqrt((sum1Sq - ((sum1**2)/n)) * (sum2Sq - (sum2**2)/n))
	 
	return 0 if den == 0
	return num/den
end

# clusters similar elements (calculated by the pearson distance) into clusters,
# grouping up until there's only one, big cluster
def self.hcluster(rows, func = :pearson)
	distances = {}
	currentclustid = -1
	
	# Clusters are initially just the rows
	clust = []
	rows.each_with_index { |r, i| clust << Bicluster.new(i, rows[i]) }

  while clust.size > 1
    lowestpair = [0,1]
    closest = method(func).call(clust[0].vec, clust[1].vec)

    # loop through every pair looking for the smallest distance
    for i in 0...clust.size
      for j in i+1...clust.size
        # distances is the cache of distance calculations
        if !distances.include?([clust[i].id, clust[j].id])
          distances[[clust[i].id, clust[j].id]] = method(func).call(clust[i].vec, clust[j].vec)
        end
        d = distances[[clust[i].id, clust[j].id]]
        if d < closest
          closest = d
          lowestpair = [i, j]
        end
      end
    end

    # calculate the average of the two clusters
    mergevec = []
    clust[0].vec.each_with_index { |v, i| mergevec[i] = (clust[lowestpair[0]].vec[i] + clust[lowestpair[1]].vec[i])/2.0 }

    # create the new cluster
    newcluster = Bicluster.new(currentclustid, mergevec, clust[lowestpair[0]], clust[lowestpair[1]], closest)

    # cluster ids that weren't in the original set are negative
    currentclustid -= 1
    clust.delete_at(lowestpair[1])
    clust.delete_at(lowestpair[0])
    clust << newcluster
  end

  return clust[0]
end



# randomly creates a set of clusters within the ranges of each of the variables. 
# With every iteration, the rows are each assigned to one of the centroids, 
# and the centroid data is updated to the average of all its assignees. 
  def self.kcluster(rows, k = 4, iterations = 100, func = :pearson)
    # Determine the minimum and maximum values for each point
    ranges = []
    for i in 0...rows[0].size
	    for row in rows
	    	ranges << [row.min, row.max]
	    end
	  end

    # Create k randomly placed centroids
    clusters = []
    for i in 0...rows[0].size
    	for j in 0...k
    		clusters[j] ||= []
    		clusters[j] << (rand() * (ranges[i][1] - ranges[i][0]) + ranges[i][0])
    	end
    end

    lastmatches = nil

    for t in 0...iterations
    	puts "iteration #{t+1}"
      bestmatches = []
      for i in 0...k
      	bestmatches << []
      end

      # Find which centroid is the closest for each row
      for j in 0...rows.size
      	row = rows[j]
        bestmatch = 0
        for i in 0...k
        	d = method(func).call(clusters[i], row)
        	if d < method(func).call(clusters[bestmatch], row)
        	  bestmatch = i
        	end
        end
        bestmatches[bestmatch] << j
      end

      # If the results are the same as last time, this is complete
      break if bestmatches == lastmatches
      lastmatches = bestmatches

			# Move the centroids to the average of their members
      for i in 0...k
        avgs = [0.0] * rows[0].size
        if bestmatches[i].size > 0
          for rowid in bestmatches[i]
            for m in 0...rows[rowid].size
              avgs[m] += rows[rowid][m]
            end
          end
          for j in 0...avgs.size
            avgs[j] /= bestmatches[i].size
          end
          clusters[i] = avgs
        end
      end
    end

    return bestmatches
  end

  # The Tanimoto coefficient is the ratio of the intersection set 
  # (only the items that are in both sets) to the union set (all the items in either set).
  # this is a useful distance calculation method in case of datasets of 0's and 1's instead of counts
  # (where Pearson doesn't work as well)
	def self.tanimoto(v1, v2)
		c1, c2, shr = 0, 0, 0
		for i in 0...v1.size
			c1 += 1 if v1[i] != 0
			c2 += 1 if v2[i] != 0
			shr += 1 if v1[i] != 0 && v2[i] != 0
		end
		return 1.0 - shr.to_f/(c1+c2-shr)
	end

end

# each cluster of things is a cluster of clusters
class Bicluster < Struct.new(:id, :vec, :left, :right, :distance)
end