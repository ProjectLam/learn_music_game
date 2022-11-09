extends Node2D

@onready var dicL1 = {}
@onready var errorCode = 0
@onready var parser = XMLParser.new()
@onready var xmlPBA = PackedByteArray()

func read_text():
	if parser.get_node_type() == parser.NODE_ELEMENT:
		var err = parser.read()
		if errorCode != OK:
			return "Errror!"
		var text = parser.get_node_data()
		err = parser.read()
		#if parser.get_node_type() == NODE_ELEMENT_END:
		#TODO check
		return text
	return ""

#TODO GOALs

#1 Iterate all the memebers of the Song class
# if they exist, then just read the text into them
#2 unkown nodes go into a catchall map
#2b potentially have a way to serialize attributes on these nodes, or maybe punt on this
#3 have a blacklist of items we want to skip (complex parsibles
#4 be able to have custom struct parsers for specific nodes

func _ready():
	errorCode = parser.open("res://song.xml.txt")
	if errorCode != OK:
		return #exit(errorCode)

	var song:Song = Song.new()
	#errorCode = parser.open_buffer(xmlPBA)
	#if errorCode != OK:
	#	return #exit(errorCode)
	for x in song.get_property_list():
		for key in x.keys():
			print(key)
			print(x[key])
			
	song.set("artistXXXXYear", "test1234")

	while parser.read() != ERR_FILE_EOF:
		print(parser.get_node_name(), ": ", parser.get_node_data())
		print(parser.get_node_name(), ": default---"+ parser.get_named_attribute_value_safe("value"))
		if(parser.get_node_name() == "artistName"):
			song.artistName =  read_text()

#		if(parser.get_node_name() == "phrases"):
#			print("------phrases-----------------")

#  <title>Comfortably Numb</title>
#  <arrangement>Bass</arrangement>
#  <part>1</part>
#  <offset>0</offset>
#  <centOffset>0</centOffset>
#  <songLength>385.999</songLength>
#  <songNameSort>Comfortably Numb</songNameSort>
#  <startBeat>0</startBeat>
#  <averageTempo>64</averageTempo>
#  <tuning string0="0" string1="0" string2="0" string3="0" string4="0" string5="0" />
#  <capo>0</capo>
#  <artistName>Pink Floyd</artistName>
#  <artistNameSort>Pink Floyd</artistNameSort>
#  <albumName>The Wall</albumName>
#  <albumNameSort>Wall, The</albumNameSort>
#  <albumYear>1979</albumYear>
#  <crowdSpeed>1</crowdSpeed>
#  <arrangementProperties represent="1" standardTuning="1" nonStandardChords="1" barreChords="0" powerChords="0" dropDPower="0" openChords="0" fingerPicking="0" pickDirection="0" doubleStops="0" palmMutes="0" harmonics="1" pinchHarmonics="0" hopo="1" tremolo="0" slides="1" unpitchedSlides="0" bends="0" tapping="0" vibrato="0" fretHandMutes="0" slapPop="0" twoFingerPicking="0" fifthsAndOctaves="1" syncopation="0" bassPick="0" sustain="1" bonusArr="0" Metronome="0" pathLead="0" pathRhythm="0" pathBass="1" routeMask="0" />
#  <lastConversionDateTime>8-18-15 23:57</lastConversionDateTime>

#TODO
#  <chordTemplates count="7">
#  <transcriptionTrack difficulty="-1">
#    <anchors count="83">
#  <ebeats count="412">
#    <ebeat time="0" measure="1" />
#  <levels count="8">
#    <level difficulty="0">
#      <notes count="63">
#        <note time="4.995" linkNext="0" accent="0" bend="0" fret="7" hammerOn="0" harmonic="0" hopo="0" ignore="0" leftHand="-1" mute="0" palmMute="0" pluck="-1" pullOff="0" slap="-1" slideTo="-1" string="0" sustain="1.564" tremolo="0" harmonicPinch="0" pickDirection="0" rightHand="-1" slideUnpitchTo="-1" tap="0" vibrato="0" />

		if parser.get_attribute_count() > 0:
			print("-attributes for -" + parser.get_node_name())

			for i in range(parser.get_attribute_count()):
				print(parser.get_attribute_name(i), ": ", parser.get_attribute_value(i))
				dicL1[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
