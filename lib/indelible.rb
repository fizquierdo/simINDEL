#!/usr/bin/env ruby
# Indelible stuff
INDELIBLE = "/home/izquiefo/software/indelible/INDELibleV1.03/src/indelible" 

class Model
  attr_accessor :statefreq, :rates, :label
  attr_reader :name, :parameters
  def initialize
    @statefreq = {:pi_A => 0.25, :pi_C => 0.25, :pi_G => 0.25, :pi_T => 0.25 }
    @name = "JC"
    @label = "modelname"
    @parameters = {}
    @rates ={:pinv => 0, :alpha => 0.50, :ngamcat => 4}
  end
  def load_GTR(ct, at , gt , ac , gc, ga)
    @name = "GTR"
    @parameters = {:a => ct,:b => at,:c => gt,:d => ac,:e => gc,:f => ga}
  end
  def to_s
    ret = String.new 
    ret << "[MODEL] #{@label}" + "\n"
    ret << "  [submodel]  #{@name} "
    if @name == "GTR" then
      [:a, :b, :c, :d, :e, :f].each{|p| ret << @parameters[p].to_s << " "}
      ret << "\n"
      # state frequencies
      ret << '  [statefreq] '
      [:pi_T, :pi_C, :pi_A, :pi_G].each{|p| ret << @statefreq[p].to_s << " "}
      ret << "\n"
      # rates
      ret << '  [rates] '
      [:pinv, :alpha, :ngamcat].each{|r| ret << @rates[r].to_s << " "}
      ret << "\n"
    else
      ret << "\n"
    end
  end
end

def get_value(line)
  line.split(":")[1].chomp.strip.to_s
end

class Tree
  attr_reader :name
  attr_accessor :newick_str
  def initialize(ntaxa)
    @ntaxa = ntaxa
    @name = "my_tree"
    @newick_str = ""
  end
  def to_s
    ret = String.new 
    if @newick_str.empty?
      ret << "[TREE] #{@name}" + "\n"
      ret << "  [unrooted] #{@ntaxa} 2.4 1.1 0.2566 0.34  // ntaxa birth death sample mut" + "\n"
      ret << "  [seed] 23575485" + "\n"
    else
      ret << "[TREE] #{@name}" + "\n"
      ret << "#{@newick_str}\n"
    end
  end
end

class IndelibleControlFile
  attr_accessor :model, :indelmodel, :tree
  def initialize(filename, ntaxa, nbases)
    @filename = filename
    @model = Model.new
    @tree = Tree.new(ntaxa)
    @indelmodel = {}
    @ntaxa = ntaxa
    @nbases = nbases
    @partitionname = "simulatedgene"
  end
  def load_modelfile(modelfile)
    p = Hash.new
    File.open(modelfile).readlines.each do |line|
      case line
      when /^rate A <-> C:/ then p[:ac] = get_value(line).to_f
      when /^rate A <-> G:/ then p[:ag] = get_value(line).to_f
      when /^rate A <-> T:/ then p[:at] = get_value(line).to_f
      when /^rate C <-> G:/ then p[:cg] = get_value(line).to_f
      when /^rate C <-> T:/ then p[:ct] = get_value(line).to_f
      when /^rate G <-> T:/ then p[:gt] = get_value(line).to_f
      when /^freq pi\(A\):/ then @model.statefreq[:pi_A]  = get_value(line).to_f
      when /^freq pi\(C\):/ then @model.statefreq[:pi_C]  = get_value(line).to_f
      when /^freq pi\(G\):/ then @model.statefreq[:pi_G]  = get_value(line).to_f
      when /^freq pi\(T\):/ then @model.statefreq[:pi_T]  = get_value(line).to_f
      when /^alpha:/        then @model.rates[:alpha] = get_value(line).to_f
      when /^Final tree written/ then @newickfile = get_value(line)
      end
    end
    @model.load_GTR(p[:ct], p[:at] , p[:gt] , p[:ac] , p[:cg], p[:ag])
  end
  def load_indelparams(indel_params)
    @indelmodel[:param] = indel_params[0]
    @indelmodel[:truncate] = indel_params[1]
    @indelmodel[:rate] = indel_params[2]
  end
  def to_file
    File.open(@filename, "w+") do |f|
      #type
      f.puts String.new('[TYPE] NUCLEOTIDE 1')
      #model
      f.puts @model.to_s
      #indelmodel TODO (do a class for Indelmodel?)
      f.puts "  [indelmodel] POW #{@indelmodel[:param]} #{@indelmodel[:truncate]}"
      f.puts "  [insertrate] #{@indelmodel[:rate]}"
      f.puts "  [deleterate] #{@indelmodel[:rate]}"
      #tree (could be a newick or parameters to simulate tree with a particular shape)
      f.puts @tree.to_s
      #partitions
      f.puts "[PARTITIONS] #{@partitionname}"
      f.puts "  [#{@tree.name} #{@model.label} #{@nbases}]" 
      #evolve
      f.puts "[EVOLVE]  #{@partitionname} 1 simulatedalignment" 
    end
  end
end

