require 'rspec'
class Card

  attr_reader :suit, :value
  def initialize(suit, value)
    @suit = suit
    @value = value
    @game_done = false
  end

  def value
    return 10 if ["J", "Q", "K"].include?(@value)
    return 11 if @value == "A"
    return @value
  end

  def to_s
    "#{suit.to_s[0].capitalize}#{@value}"
  end

  def game_done!
    @game_done = true
  end

end


class DownCard < Card
  def initialize(suit, value)
    super(suit, value)
  end

  def value
    if @game_done
      super
    else
      0
    end
  end

  def to_s
    if @game_done
      super
    else
      "XX"
    end
  end

end


class Deck
  attr_reader :cards

  def initialize
    @cards = Deck.build_cards
  end

  def self.build_cards
    cards = []
    [:clubs, :diamonds, :spades, :hearts].each do |suit|
      (2..10).each do |number|
        cards << Card.new(suit, number)
      end
      ["J", "Q", "K", "A"].each do |facecard|
        cards << Card.new(suit, facecard)
      end
    end
    cards.shuffle
  end
end

class Hand
  attr_reader :cards

  def initialize
    @cards = []
  end
  def hit!(deck)
    @cards << deck.cards.shift
  end

  def value
    cards.inject(0) {|sum, card| sum += card.value }
  end

  def play_as_dealer(deck)
    @cards.each { |card| card.game_done! }
    if value < 16
      hit!(deck)
      play_as_dealer(deck)
    end
  end
end

class DealerHand < Hand
  def hit!(deck)
    if @cards.length == 0
      downcard = deck.cards.shift
      @cards << DownCard.new(downcard.suit, downcard.value)
    else
      @cards << deck.cards.shift
    end
  end
end
  
class Game
  attr_reader :player_hand, :dealer_hand
  def initialize
    @deck = Deck.new
    @player_hand = Hand.new
    @dealer_hand = DealerHand.new
    2.times { @player_hand.hit!(@deck) } 
    2.times { @dealer_hand.hit!(@deck) }
  end

  def hit
    @player_hand.hit!(@deck)
    if status[:player_value] > 21 then
      stand
    end
  end

  def stand
    @dealer_hand.play_as_dealer(@deck)
    @winner = determine_winner(@player_hand.value, @dealer_hand.value)
  end

  def status
    {:player_cards=> @player_hand.cards, 
     :player_value => @player_hand.value,
     :dealer_cards => @dealer_hand.cards,
     :dealer_value => @dealer_hand.value,
     :winner => @winner}
  end

  def determine_winner(player_value, dealer_value)
    return :dealer if player_value > 21
    return :player if dealer_value > 21
    if player_value == dealer_value
      :push
    elsif player_value > dealer_value
      :player
    else
      :dealer
    end
  end

  def inspect
    status
  end
end


describe Card do

  it "should accept suit and value when building" do
    card = Card.new(:clubs, 10)
    card.suit.should eq(:clubs)
    card.value.should eq(10)
  end

  it "should have a value of 10 for facecards" do
    facecards = ["J", "Q", "K"]
    facecards.each do |facecard|
      card = Card.new(:hearts, facecard)
      card.value.should eq(10)
    end
  end
  it "should have a value of 4 for the 4-clubs" do
    card = Card.new(:clubs, 4)
    card.value.should eq(4)
  end

  it "should return 11 for Ace" do
    card = Card.new(:diamonds, "A")
    card.value.should eq(11)
  end

  it "should be formatted nicely" do
    card = Card.new(:diamonds, "A")
    card.to_s.should eq("DA")
  end
end


describe DownCard do
  it "should show XX before the game is done" do
    downcard = DownCard.new(:diamonds, "K")
    downcard.to_s.should eq("XX")
  end

  it "should show the actual card after the game is done" do
    downcard = DownCard.new(:diamonds, "K")
    downcard.game_done!
    downcard.to_s.should eq("DK")
  end

  it "should return a value of 0 before the game is done" do
    downcard = DownCard.new(:hearts, 9)
    downcard.value.should eq(0)
  end

  it "should return the actual value after the game is done" do
    downcard = DownCard.new(:hearts, 9)
    downcard.game_done!
    downcard.value.should eq(9)
  end
end


describe Deck do

  it "should build 52 cards" do
    Deck.build_cards.length.should eq(52)
  end

  it "should have 52 cards when new deck" do
    Deck.new.cards.length.should eq(52)
  end

end


describe Hand do

  it "should calculate the value correctly" do
    deck = mock(:deck, :cards => [Card.new(:clubs, 4), Card.new(:diamonds, 10)])
    hand = Hand.new
    2.times { hand.hit!(deck) }
    hand.value.should eq(14)
  end

  it "should take from the top of the deck" do
    club4 = Card.new(:clubs, 4)
    diamond7 = Card.new(:diamonds, 7) 
    clubK = Card.new(:clubs, "K")

    deck = mock(:deck, :cards => [club4, diamond7, clubK])
    hand = Hand.new
    2.times { hand.hit!(deck) }
    hand.cards.should eq([club4, diamond7])

  end

  describe "#play_as_dealer" do
    it "should hit blow 16" do
      deck = mock(:deck, :cards => [Card.new(:clubs, 4), Card.new(:diamonds, 4), Card.new(:clubs, 2), Card.new(:hearts, 6)])
      hand = Hand.new
      2.times { hand.hit!(deck) }
      hand.play_as_dealer(deck)
      hand.value.should eq(16)
    end
    it "should not hit above" do
      deck = mock(:deck, :cards => [Card.new(:clubs, 8), Card.new(:diamonds, 9)])
      hand = Hand.new
      2.times { hand.hit!(deck) }
      hand.play_as_dealer(deck)
      hand.value.should eq(17)
    end
    it "should stop on 21" do
      deck = mock(:deck, :cards => [Card.new(:clubs, 4), 
                                    Card.new(:diamonds, 7), 
                                    Card.new(:clubs, "K")])
      hand = Hand.new
      2.times { hand.hit!(deck) }
      hand.play_as_dealer(deck)
      hand.value.should eq(21)
    end
  end
end


describe DealerHand do
  describe "#hit!" do
    it "should have a downcard on the first hit" do
      deck = Deck.new
      dealer_hand = DealerHand.new.hit!(deck)
      dealer_hand[0].to_s.should eq("XX")
    end
  end
end


describe Game do

  it "should have a players hand" do
    Game.new.player_hand.cards.length.should eq(2)
  end
  it "should have a dealers hand" do
    Game.new.dealer_hand.cards.length.should eq(2)
  end
  it "should have a status" do
    Game.new.status.should_not be_nil
  end
  it "should hit when I tell it to" do
    game = Game.new
    game.hit
    game.player_hand.cards.length.should eq(3)
  end

  it "should play the dealer hand when I stand" do
    game = Game.new
    game.stand
    game.status[:winner].should_not be_nil
  end

  it "should not show the full dealer hand before the game is done" do
    game = Game.new
    game.status[:dealer_cards].to_s.should include("XX")
  end

  it "should show the full dealer hand after the game is done" do
    game = Game.new
    game.stand
    game.status[:dealer_cards].to_s.should_not include("XX")
  end

  it "should #stand for the player if they bust" do
    game = Game.new
    game.should_receive(:stand)
    while game.status[:player_value] <= 21
      game.hit
    end
  end

  describe "#determine_winner" do
    it "should have dealer win when player busts" do
      Game.new.determine_winner(22, 15).should eq(:dealer) 
    end
    it "should player win if dealer busts" do
      Game.new.determine_winner(18, 22).should eq(:player) 
    end
    it "should have player win if player > dealer" do
      Game.new.determine_winner(18, 16).should eq(:player) 
    end
    it "should have push if tie" do
      Game.new.determine_winner(16, 16).should eq(:push) 
    end
  end
end
