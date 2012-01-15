require './src/recommendation'
require 'test/unit'

class RecommendationTest  < Test::Unit::TestCase
  
  def setup
    @critics={
      'Lisa Rose' => {'Lady in the Water' => 2.5, 'Snakes on a Plane' => 3.5,
        'Just My Luck' => 3.0, 'Superman Returns' => 3.5, 'You, Me and Dupree' => 2.5,
        'The Night Listener' => 3.0},
     'Gene Seymour' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 3.5,
        'Just My Luck' => 1.5, 'Superman Returns' => 5.0, 'The Night Listener' => 3.0,
        'You, Me and Dupree' => 3.5},
     'Michael Phillips' => {'Lady in the Water' => 2.5, 'Snakes on a Plane' => 3.0,
        'Superman Returns' => 3.5, 'The Night Listener' => 4.0},
     'Claudia Puig' => {'Snakes on a Plane' => 3.5, 'Just My Luck' => 3.0,
        'The Night Listener' => 4.5, 'Superman Returns' => 4.0,
        'You, Me and Dupree' => 2.5},
     'Mick LaSalle' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 4.0,
        'Just My Luck' => 2.0, 'Superman Returns' => 3.0, 'The Night Listener' => 3.0,
        'You, Me and Dupree' => 2.0},
     'Jack Matthews' => {'Lady in the Water' => 3.0, 'Snakes on a Plane' => 4.0,
        'The Night Listener' => 3.0, 'Superman Returns' => 5.0, 'You, Me and Dupree' => 3.5},
     'Toby' => {'Snakes on a Plane' =>4.5,'You, Me and Dupree' =>1.0,'Superman Returns' => 4.0}}

  end

  def test_sim_distance
    assert_equal Recommendation.sim_distance(@critics, 'Lisa Rose','Gene Seymour'), 0.14814814814814814
  end

  def test_sim_pearson
    assert_equal Recommendation.sim_pearson(@critics, 'Lisa Rose','Gene Seymour'), 0.39605901719066977
  end

  def test_top_matches
    assert_equal Recommendation.top_matches(@critics,'Toby',n=3), 
          [[0.99124070716192991, 'Lisa Rose'], [0.92447345164190486, 'Mick LaSalle'], [0.89340514744156474, 'Claudia Puig']]
  end

  def test_get_recommendations
    assert_equal Recommendation.get_recommendations(@critics, 'Toby'),
          [[3.3477895267131017, "The Night Listener"], [2.8325499182641614, "Lady in the Water"], [2.530980703765565, "Just My Luck"]]

    assert_equal Recommendation.get_recommendations(@critics,'Toby', :sim_distance),
          [[3.5002478401415877, "The Night Listener"], [2.7561242939959363, "Lady in the Water"], [2.461988486074374, "Just My Luck"]]
  end

  # Find the set of movies most similar to Superman Returns by inverting the critics-movies mapping
  def test_top_matches_inverted
    movies = Recommendation.transform_prefs(@critics)
    assert_equal Recommendation.top_matches(movies,'Superman Returns'),
        [[0.6579516949597695, "You, Me and Dupree"], [0.4879500364742689, "Lady in the Water"], [0.11180339887498941, "Snakes on a Plane"], 
         [-0.1798471947990544, "The Night Listener"], [-0.42289003161103106, "Just My Luck"]]
  end

  # Get recommended critics for a movie. Maybe you’re trying to decide whom to invite to a premiere?
  def test_get_recommendations_inverted
    movies = Recommendation.transform_prefs(@critics)

    assert_equal Recommendation.get_recommendations(movies, 'Just My Luck'), 
      [[4.0, 'Michael Phillips'], [3.0, 'Jack Matthews']]
  end

  def test_calculate_similar_items
    assert_equal Recommendation.calculate_similar_items(@critics), 
        {"Lady in the Water"=> [[0.4, "You, Me and Dupree"], [0.2857142857142857, "The Night Listener"], 
                                [0.2222222222222222, "Snakes on a Plane"], [0.2222222222222222, "Just My Luck"], 
                                [0.09090909090909091, "Superman Returns"]],
        "Snakes on a Plane"=> [[0.2222222222222222, "Lady in the Water"], [0.18181818181818182, "The Night Listener"], 
                                [0.16666666666666666, "Superman Returns"], [0.10526315789473684, "Just My Luck"], 
                                [0.05128205128205128, "You, Me and Dupree"]], 
        "Just My Luck"=>[[0.2222222222222222, "Lady in the Water"], [0.18181818181818182, "You, Me and Dupree"], 
                         [0.15384615384615385, "The Night Listener"], [0.10526315789473684, "Snakes on a Plane"], 
                         [0.06451612903225806, "Superman Returns"]], 
        "Superman Returns"=>[[0.16666666666666666, "Snakes on a Plane"], [0.10256410256410256, "The Night Listener"], 
                             [0.09090909090909091, "Lady in the Water"], [0.06451612903225806, "Just My Luck"], 
                             [0.05333333333333334, "You, Me and Dupree"]], 
        "You, Me and Dupree"=>[[0.4, "Lady in the Water"], [0.18181818181818182, "Just My Luck"], 
                               [0.14814814814814814, "The Night Listener"], [0.05333333333333334, "Superman Returns"], 
                               [0.05128205128205128, "Snakes on a Plane"]], 
        "The Night Listener"=>[[0.2857142857142857, "Lady in the Water"], [0.18181818181818182, "Snakes on a Plane"], 
                               [0.15384615384615385, "Just My Luck"], [0.14814814814814814, "You, Me and Dupree"], 
                               [0.10256410256410256, "Superman Returns"]]}

  end

  def test_get_recommended_items
    # always a good idea to CACHE this, as the number of items will be a lot bigger than individual user's prefs
    items_sim = Recommendation.calculate_similar_items(@critics)

    assert_equal Recommendation.get_recommended_items(@critics, items_sim, 'Toby'),
          [[3.182634730538922, "The Night Listener"], [2.5983318700614575, "Just My Luck"], [2.4730878186968837, "Lady in the Water"]]
  end
end