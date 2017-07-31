require 'open-uri'
require 'json'

class WordsController < ApplicationController
  def game
    @grid = generate_grid(9)
    @start_time = Time.now
  end

  def score
    @grid = params[:grid]
    @attempt = params[:attempt]
    @start_time = Time.parse(params[:time]) # method .to_i doesn't work for time
    @end_time = Time.now
    @result = run_game(@attempt, @grid, @start_time, @end_time)
    if session[:total].nil?
      @total = session[:total] = @result[:score]
    else
      @total = session[:total] += @result[:score]
    end
  end

def generate_grid(grid_size)
  # TODO: generate random grid of letters
  grid = []
  i =   grid_size
  while i > 0
    grid << ("a".."z").to_a.sample # why we use an * on the other exercise?
    i -= 1
  end
  grid
end

def run_game(attempt, grid, start_time, end_time)
  # TODO: runs the game and return detailed hash of result
  outcome = {}
  # send word to be translated, in variable "attempt", to be translated via API. Receives a JSON response
  url = "https://api-platform.systran.net/"
  address = "translation/text/translate?source=en&target=fr&key=3f5229e9-6a1e-4b26-98bd-b3c281d9ef60&input="
  link = "#{url}#{address}#{attempt}"
  raw_json = open(link).read
  # convert API reponse in JSON format to ruby (parsing)
  readable = JSON.parse(raw_json)
  outcome[:translation] = readable["outputs"][0]["output"]
  outcome[:time] = (end_time - start_time)
  grid_result = grid_check?(attempt, grid)
  score_n_message(attempt, grid_result, outcome)
end

def score_n_message(attempt, grid_result, outcome)
  if grid_result
    english_word_check(attempt, outcome)
  else
    outcome[:score] = 0
    outcome[:message] = "not in the grid"
  end
  outcome
end

def english_word_check(attempt, outcome)
  if outcome[:translation] == attempt
    outcome[:score] = 0
    outcome[:translation] = nil
    outcome[:message] = "not an english word"
  else
    outcome[:score] = 100 * attempt.length * (1 / outcome[:time])
    outcome[:message] = "well done"
  end
  outcome
end

def grid_check?(attempt, grid)
  # verify if attempt belongs to grid and return true if it is
  grid = grid.downcase.split("")
  attempt.chars.all? { |letter| attempt.count(letter) <= grid.count(letter) }
end

end
