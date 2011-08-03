#!/usr/bin/env ruby 

require 'fileutils'
require 'trollop'
load 'lib/indelible.rb' # make a gem out of this? https://github.com/technicalpickles/jeweler/

#VIEWER = " utils/newick-utils-1.5.0/src/nw_display"
VIEWER =    "bin/nw_display"
INDELIBLE = "bin/indelible" 

opts = Trollop::options do
  opt :show_tree,           "Show simulated tree",        :default => false
  opt :ntaxa,               "Number of taxa",             :default => 10
  opt :nbases,              "Number of base pairs",       :default => 100
  opt :modelfile,           "GTR data from raxml output", :default => "" 
  opt :indelparams,         "POWER LAW [#{IMKEYS.join ','}]",:default => IMKEYS.map{|s| INDEL_MODEL_PARAMS[s.to_sym]}.join(",") 
  opt :guidetree,           "guide to simulate of evol",  :default => "" 
  opt :birth_death_params,  "[#{BDKEYS.join(",")}]",      :default => BDKEYS.map{|s| BDPARAMS[s.to_sym]}.join(",")
end
p opts

# control you have the options you need
puts "Starting simulation of #{opts[:ntaxa]} taxa and #{opts[:nbases]} base pairs" 
dirname = opts[:ntaxa].to_s + "_taxa"
wdir = "out/#{dirname}"
controlfile = "#{wdir}/control.txt"
FileUtils.mkdir_p(wdir)

# generate control file
cf = IndelibleControlFile.new(controlfile, opts[:ntaxa], opts[:nbases])
cf.load_modelfile(opts[:modelfile]) unless opts[:modelfile].empty?
cf.load_indel_params(opts[:indelparams]) unless opts[:indelparams].empty?
if opts[:guidetree].empty?
  cf.load_birth_death_params(opts[:birth_death_params])
else
  cf.load_newick_str(File.open(opts[:guidetree]).readlines[0].gsub(':0.0;', ";").chomp)
end
cf.to_file

if opts[:show_tree] 
  raise "Couldnt find Indelible as #{INDELIBLE}" unless File.exists?(INDELIBLE)
  raise "Couldnt find nw_display as #{VIEWER}" unless File.exists?(VIEWER)
  # run simulation
  simulator = File.join Dir.pwd, INDELIBLE
  newick = ""
  Dir.chdir(wdir) do
    system("#{simulator} #{controlfile} > /dev/null")
    newick = File.open("trees.txt").readlines.last.split("\t").last.chomp 
  end
  # view the output
  out = "tree.newick"
  File.open(out, 'w'){|f| f.puts newick}
  system("#{VIEWER} #{out}")
  File.delete(out)
else
  puts "DONE, alignment TRUE.phy in #{wdir}" 
  puts "\n Control File \n\n"
  File.open(controlfile).readlines.each {|l| puts l}
end
