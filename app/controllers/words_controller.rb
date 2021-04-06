require 'open-uri'
require 'nokogiri'

class WordsController < ApplicationController
  def index
  end

  def result
  end

  private

  def make_hash(content, num)
    # split string into array of words
    all_words = content.split(/\s+/)

    # create hash from grouping by word
    words_hash = all_words.group_by { |word| word }

    # set value of each word to its frequency
    words_hash.each_key { |word| words_hash[word] = words_hash[word].length }

    # remove values set to whitespace or single character (with the exception of a and i)
    words_hash.delete_if { |key, _| (key.length <= 1) && key != 'a' && key != 'i' }

    # sort by value & reverse
    words_hash.sort_by(&:last).reverse.to_h.first(num).to_h
  end

  def insert_ws(content, rgx)
    # find spot where whitespace is needed and insert it
    break_needed = content.scan(rgx)
    break_needed.each do |l_b|
      replace = l_b[0] + ' ' + l_b[1]
      content.gsub!(l_b, replace)
    end
    content
  end

  def remove_ws(content, rgx)
    # find spot where whitespace is superfluous and remove it
    break_to_rm = content.scan(rgx)
    break_to_rm.each do |ws|
      replace = ws[0] + ws[2]
      content.gsub!(ws, replace)
    end
    content
  end

  def edit_content(content, num, stop_w = false)
    # call insert_ws if there is a character just before capital letter or parenthesis (due to line breaks)
    content = insert_ws(content, /\S[A-Z]/)
    content = insert_ws(content, /[a-z]\d/)
    content = insert_ws(content, /\w\[/)
    content = insert_ws(content, /\w\(/)

    # remove whitespace where there is too much
    content = remove_ws(content, /-\s[A-Z]/)

    # remove square brackets [and any word characters, whitespaces and . ' " ! ? \  , & : - inbetween ]
    content.gsub!(/\[(\w|\s|\.|'|"|!|\?|\\|,|&|:|-)+\]/, '')

    # downcase content & remove surrounding whitespace
    content = content.downcase.strip

    # find any of the special characters , ( ) . ! ? & : " and remove them
    content.gsub!(/,|\(|\)|\.|!|\?|&|:|"/, '')

    # if stop_w is set to true, remove words in stop-words.txt from list
    2.times { words_to_stop.each { |word| content.gsub!(/(\s|\A)#{word}(\s|!|\.|\?|\z)/, ' ') } if stop_w }

    # create hash with top words
    make_hash(content, num)
  end

  def words_to_stop
    # array of words to remove
    %w[after again against ain't all almost already also always am an and another any anybody anyhow anyone anything
       are aren't around as at be became because become becomes been before behind below beside besides between both
       but by c'mon came can can't cannot cant cause come comes could couldn't course did didn't do does doesn't don't
       done down each either else except few first for from get gets gettin' getting go goes going gone gon' gonna
       got gotta gotten had hadn't has hasn't have haven't having he he'll he's her here here's hers herself him
       himself his how i i'd i'll i'm i'ma i've if in into is isn't it it'd it'll it's its itself just know last
       later least left less let let's like liked look many may maybe me mean might more most mostly much must my
       myself name near need never new next no nobody none noone not nothing now of off often oh ok okay old on once
       one ones only or other others ought our ours out over own quite rather really right said same saw say saying
       says second see seem seems she she'll she's should shouldn't since some still such sure than that that's thats
       the their theirs them then there there's theres these they they'd they'll they're they've think third this
       those though three through to together too toward towards two under until unto up upon us very want wants was
       wasn't way we we'd we'll we're we've well went were weren't what what's when where where's wherever whether
       which who who's whole why will with without won't would wouldn't yeah yes yet you you'd you'll you're you've
       your yours yourself]
  end

  def scrape_lyrics(artist, title, num, stop_w = false)
    # open and read url, returns string if url is not found
    begin
      html_content = open("https://genius.com/#{artist}-#{title}-lyrics").read
      doc = Nokogiri::HTML(html_content)
    rescue
      return 'Song not found!'
    end

    # find part of document with song lyrics and store content in a string
    lyrics_whole = doc.css('div.Lyrics__Container-sc-1ynbvzw-2.jgQsqn')
    content_only = ''
    lyrics_whole.each { |element| content_only += element.content }

    # call edit_content, which will return a hash with the result of the search
    edit_content(content_only, num, stop_w)
  end
end
