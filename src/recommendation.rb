module Recommendation

  # Returns a distance-based similarity score for person1 and person2
  def self.sim_distance(prefs, person1, person2)
    # Get the list of shared_items
    si = {}
    for item in prefs[person1].keys
      si[item] = 1.0 if prefs[person2].keys.include?(item)
    end

    # if they have no ratings in common, return 0
    return 0.0 if si.empty?

    # Add up the squares of all the differences
    sum_of_squares = 0.0
    for item in prefs[person1].keys
      next if !prefs[person2].keys.include?(item)
      sum_of_squares += ((prefs[person1][item]-prefs[person2][item]) ** 2)
    end
    return 1.0/(1.0+sum_of_squares)
  end

  # Returns the Pearson correlation coefficient for p1 and p2
  def self.sim_pearson(prefs,p1,p2)
    # Get the list of mutually rated items
    si = {}

    for item in prefs[p1].keys
      si[item] = 1 if prefs[p2].keys.include?(item)
    end

    # Find the number of elements
    n = si.size
   
    # if they are no ratings in common, return 0
    return 0 if n == 0

    # Add up all the preferences
    sum1 = si.keys.collect { |it| prefs[p1][it] }.inject(&:+)
    sum2 = si.keys.collect { |it| prefs[p2][it] }.inject(&:+)

    # Sum up the squares
    sum1Sq = si.keys.collect { |it| prefs[p1][it]**2 }.inject(&:+)
    sum2Sq = si.keys.collect { |it| prefs[p2][it]**2 }.inject(&:+)

    # Sum up the products
    pSum = si.keys.collect { |it| prefs[p1][it]*prefs[p2][it] }.inject(&:+) 

    # Calculate Pearson score
    num = pSum - (sum1*sum2/n)
    den = Math.sqrt((sum1Sq - ((sum1**2)/n)) * (sum2Sq - (sum2**2)/n))
     
    return 0 if den == 0
    return num/den
  end


  # Returns the best matches for person from the prefs dictionary.
  # Number of results and similarity function are optional params.
  def self.top_matches(prefs, person, n=5, sim_function = :sim_pearson)
    scores = []
    for other in prefs.keys.select { |p| p != person }
      scores << [method(sim_function).call(prefs, person, other), other]
    end

    # Sort the list so the highest scores appear at the top scores.sort( )
    scores = scores.sort.reverse
    return scores[0...n]
  end

  # Gets recommendations for a person by using a weighted average
  # of every other user's rankings
  def self.get_recommendations(prefs, person, similarity = :sim_pearson)
    totals={}
    sim_sums={}
    
    for other in prefs.keys
      # don't compare me to myself
      next if other == person
      sim = method(similarity).call(prefs, person, other)

      # ignore scores of zero or lower
      next if sim <=0
      
      for item in prefs[other].keys
        # only score movies I haven't seen yet
        if !prefs[person].keys.include?(item) || prefs[person][item] == 0
          # Similarity * Score 
          totals[item] ||= 0
          totals[item] += prefs[other][item] * sim
          
          # Sum of similarities 
          sim_sums[item] ||= 0
          sim_sums[item] += sim
        end
      end
    end

    # Create the normalized list
    rankings = totals.keys.collect { |it| [totals[it]/sim_sums[it], it] }

    # Return the sorted list 
    rankings = rankings.sort.reverse
    return rankings
  end

  # invert the hashmap
  def self.transform_prefs(prefs)
    result = {}
    
    for person in prefs.keys
      for item in prefs[person].keys
        result[item] ||= {}
        
        # Flip item and person
        result[item][person] = prefs[person][item]
      end
    end
    return result
  end

  # Create a dictionary of items showing which other items they
  # are most similar to. This should be run often and cached for reuse
  def self.calculate_similar_items(prefs, n = 10)
    result={}

    # Invert the preference matrix to be item-centric
    item_prefs = transform_prefs(prefs)

    c = 0
    for item in item_prefs.keys
      # Status updates for large datasets
      c+=1
      p "#{c}/#{item_prefs.keys.size}" if c % 100 == 0

      # Find the most similar items to this one
      scores = top_matches(item_prefs, item, n, :sim_distance)
      result[item]=scores
    end
    return result
  end



  def self.get_recommended_items(prefs, item_match, user)
    user_ratings = prefs[user]
    scores = {}
    total_sim = {}
    
    # Loop over items rated by this user
    for item in user_ratings.keys
      rating = user_ratings[item]
      
      # Loop over items similar to this one
      for similarity, item2 in item_match[item]

        # Ignore if this user has already rated this item
        next if user_ratings.keys.include?(item2)

        # Weighted sum of rating times similarity
        scores[item2] ||= 0
        scores[item2] += similarity * rating
        
        # Sum of all the similarities
        total_sim[item2] ||= 0
        total_sim[item2] += similarity
      end
    end

    # Divide each total score by total weighting to get an average 
    rankings= scores.keys.collect { |it| [scores[it]/total_sim[it], it] }

    # Return the rankings from highest to lowest
    return rankings.sort.reverse
  end
  
end
