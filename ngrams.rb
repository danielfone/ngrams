#!/usr/bin/env ruby
# encoding: UTF-8

require 'n_gram'
require 'matrix'
require './llr.rb'
require 'set'

class Bigram
  attr_reader :bigrams, :a, :b, :count

  def initialize(bigrams,a,b,count)
    @bigrams = bigrams
    @a = a
    @b = b
    @count = count
  end

  def contains?(gram)
    a == gram or b == gram
  end

  def does_not_contain?(gram)
    a != gram and b != gram
  end

  def words
    b.split(' ').count + 1
  end

  def significance
    words * llr
  end

  def llr
    return @llr if defined? @llr
#    puts "Calculating LLR for bigram [#{a}],[#{b}]…"
    kab = count
#    puts "k[#{a}] & [#{b}]: #{kab} / #{bigrams.count}"
    kax = bigrams.with(a).without(b).total_count
#    puts "k[#{a}] ![#{b}]: #{kax} / #{bigrams.count}"
    kxb = bigrams.with(b).without(a).total_count
#    puts "k[#{b}] ![#{a}]: #{kxb} / #{bigrams.count}"
    kxx = bigrams.without(a).without(b).total_count
#    puts "k![#{a}] ![#{b}]: #{kxx} / #{bigrams.count}"
    @llr = LLR.calculate(Matrix[
      [kab, kxb],
      [kax, kxx]
    ]).round(3)

  end

  def to_s
    "#{count}\t#{llr}\t#{a} #{b}"
  end


end

class Bigrams < Array

  def add_bigram(a,b,count)
    self << Bigram.new(self, a, b, count)
  end

  def sort_by_count
    sort_by {|b| b.count }.reverse
  end

  def sort_by_llr
    sort_by {|b| b.llr }.reverse
  end

  def with(gram)
    dup.tap {|bb| bb.select! { |bigram| bigram.contains? gram } }
  end

  def without(gram)
    dup.tap {|bb| bb.select! { |bigram| bigram.does_not_contain? gram } }
  end

  def total_count
    map(&:count).inject(:+) or 0
  end

  def with_count(n)
    dup.tap {|bb| bb.select! { |b| b.count >= n } }
  end

  def with_llr(n)
    dup.tap {|bb| bb.select! { |b| b.llr >= n } }
  end

  def with_significance(n)
    dup.tap {|bb| bb.select! { |b| b.significance >= n } }
  end

  def keywords
    stopwords = File.read('stopwords.txt').split.to_set
    dup.tap {|bb| bb.reject! { |b| stopwords.include? b.a } }
  end

end

class LanguageText
  NGRAM_STOP = '|'

  def initialize(text)
    @text = text
  end

  def normalised_text
    return @normalised_text if defined? @normalised_text
    @normalised_text = @text.dup
    '()”“‘’'.each_char { |c| @normalised_text.delete! c }
    @normalised_text.downcase!
    @normalised_text.gsub!("\n", '')
    @normalised_text.gsub!("  ", ' ')
    @normalised_text.gsub!(/[;,.:\?!]/, " #{NGRAM_STOP}\n")
    @normalised_text.gsub!(/^ /, "")
    @normalised_text
  end

  def ngrams(n)
    NGram.new([normalised_text], n: n).ngrams_of_all_data[n].reject { |n,c| n[NGRAM_STOP] }
  end

  def multigrams(n)
    multigrams = Bigrams.new
    STDERR.puts "Calculating #{n}-grams…"
    ngrams(n).each do |ngram, count|
      a, b = ngram.split(' ', 2)
      multigrams.add_bigram a, b, count
    end
    multigrams
  end

  def interesting_phrases
    ngrams = []
    ngrams += multigrams(14).with_count(2) # .tap { |a| puts a.size }
    ngrams += multigrams(13).with_count(2) # .tap { |a| puts a.size }
    ngrams += multigrams(12).with_count(2) # .tap { |a| puts a.size }
    ngrams += multigrams(11).with_count(2) # .tap { |a| puts a.size }
    ngrams += multigrams(10).with_count(2) # .tap { |a| puts a.size }
    ngrams += multigrams(9).with_count(2)  # .tap { |a| puts a.size }
    ngrams += multigrams(8).with_count(2)  # .tap { |a| puts a.size }
    ngrams += multigrams(7).with_count(2)  # .tap { |a| puts a.size }
    ngrams += multigrams(6).with_count(3)  # .tap { |a| puts a.size }
    ngrams += multigrams(5).with_count(3)  # .tap { |a| puts a.size }
    ngrams += multigrams(4).with_count(3)  # .tap { |a| puts a.size }
    ngrams += multigrams(3).with_count(3).with_llr(10).tap { |a| puts a.size }
    ngrams += multigrams(2).with_count(3).with_llr(10).tap { |a| puts a.size }
  end
end

text = LanguageText.new STDIN.read
#puts text.ngrams(2)
#puts text.quadgrams.sort_by_count
puts text.interesting_phrases.sort_by {|ngram| ngram.llr }.reverse

puts 'Key words'
puts text.multigrams(1).with_count(2).keywords.sort_by(&:count).reverse
