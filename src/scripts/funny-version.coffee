#!/usr/bin/env coffee
config = require __dirname + '/../config'
_ = require 'lodash'

adjectives = """
  Graceful
  Shady
  Sneaky
  Clumsy
  Awkward
  Nimble
  Clever
  Dull
  Obtuse
  Meek
  Anemic
  Frightened
  Timid
  Vigilant
  Cautious
  Capable
  Adequate
  Absent-minded
  Adventurous
  Daring
  Indifferent
  Apologetic
  Hideous
  Horrid
  Dreadful
  Ghastly
  Revolting
  Nasty
  Cruel
  Cheeky
  Obnoxious
  Disrespectful
  Contrary
  Ornery
  Subtle
  Optimistic
  Courageous
  Cowardly
  Gullible
  Arrogant
  Haughty
  Naïve
  Curious
  Stubborn
  Brazen
  Modest
  Humble
  Proud
  Dishonest
  Righteous
  Greedy
  Wise
  Tricky
  Loyal
  Relaxed
  Tranquil
  Lazy
  Rambunctious
  Erratic
  Fidgety
  Lively
  Still
  Famished
  Surprised
  Startled
  Sullen
  Terrified
  Furious
  Annoyed
  Sullen
  Groggy
  Alert
  Tense
  Cranky
  Gloomy
  Irritable
  Lonely
  Exhausted
  Ecstatic
  Cheerful
  Delighted
  Blithe
  Content
  Carefree
  Demanding
  Challenging
  Effortless
  Simple
  Fantastic
  Marvelous
  Splendid
  Brilliant
  Superb
  Striking
  Stunning
  Gorgeous
  Picturesque
  Lovely
  Charming
  Enchanting
  Delicate
  Pleasant
  Monstrous
  Immense
  Enormous
  Massive
  Brawny
  Bulky
  Towering
  Rotund
  Cavernous
  Puny
  Minute
  Diminutive
  Microscopic
  Petite
  Slight
  Bitter
  Frosty
  Sweltering
  Scorching
  Blistering
  Muggy
  Stifling
  Oppressive
  Cozy
  Eternal
  Ceaseless
  Perpetual
  Endless
  Temporary
  Intimidating
  Menacing
  Miserable
  Dangerous
  Delinquent
  Vile
  Quarrelsome
  Hostile
  Malicious
  Savage
  Stern
  Somber
  Mysterious
  Shocking
  Infamous
  Ingenious
  Thrifty
  Generous
  Prudent
  Stingy
  Spoiled
  Anxious
  Nervous
  Impatient
  Worried
  Excited
  Courteous
  Compassionate
  Benevolent
  Polite
  Amusing
  Entertaining
  Creative
  Precise
  Eccentric
  Decrepit
  Ancient
  Rotten
  Whimsical
  Dense
  Desolate
  Disgusting
  Dismal
  Opulent
  Idyllic
  Lavish
  Edgy
  Trendy
  Peculiar
  Rancid
  Fetid
  Foul
  Filthy
  Repulsive
  Lousy
  Fluttering
  Soaring
  Sparkling
  Gilded
  Verdant
  Glowing
  Askew
  Dowdy
  Gaunt
  Sloppy
  Serious
  Grave
  Intense
  Severe
  Heavy
  Solemn
  Absurd
  Ridiculous
  Sluggish
  Dawdling
  Meandering
  Scarce
  Copious
  Muffled
  Lulling
  Creaky
  Shrill
  Piercing
  Slimy
  Grimy
  Gauzy
  Mangy
  Swollen
  Parched
  Crispy
  Spiky
  Slick
  Fuzzy
  Lumpy
  Plush
  Wrinkly
  Slick
  Glassy
  Snug
  Stiff
"""

animals = """
  alligator
  ant
  bear
  bee
  bird
  camel
  cat
  cheetah
  chicken
  chimpanzee
  cow
  crocodile
  deer
  dog
  dolphin
  duck
  eagle
  elephant
  fish
  fly
  fox
  frog
  giraffe
  goat
  goldfish
  hamster
  hippopotamus
  horse
  kangaroo
  kitten
  lion
  lobster
  monkey
  octopus
  owl
  panda
  pig
  puppy
  rabbit
  rat
  scorpion
  seal
  shark
  sheep
  snail
  snake
  spider
  squirrel
  tiger
  turtle
  wolf
  zebra
"""

adjectives = adjectives.split '\n'
adjectives = _.uniq _.compact _.map adjectives, (item) ->
  if item.trim() is '' then return null
  item.trim().toLowerCase()

animals = animals.split '\n'
animals = _.uniq _.compact _.map animals, (item) ->
  if item.trim() is '' then return null
  item.trim().toLowerCase()

module.exports = versions = {

  generate: ((alliteration=yes,spaceChar=' ') ->
    if !alliteration
      return _.first(_.shuffle(adjectives)) + spaceChar + _.first(_.shuffle(animals))

    potential = []

    while !potential.length
      animal = _.first(_.shuffle(animals))
      first = animal.substr(0,1)
      potential = _.compact _.map adjectives, (item) ->
        return null if item.substr(0,1) isnt first
        item

    return _.first(_.shuffle(potential)) + spaceChar + animal
  )

}

##
if !module.parent
  log versions.generate(true,'-')
  process.exit 0
