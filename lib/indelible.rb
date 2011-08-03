#!/usr/bin/env ruby
# default values birth-death process
BDPARAMS = {:birth => 2.4, :death => 1.1, :sample => 0.25, :mut => 0.34} 
BDKEYS = %w(birth death sample mut)

# default values for indel model 
INDEL_MODEL_PARAMS = {:param => 1.5, :trunc => 5, :rate => 0.01}
IMKEYS = %w(param trunc rate)


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
  attr_accessor :newick_str, :birth, :death, :sample, :mut
  def initialize(ntaxa)
    @ntaxa = ntaxa
    @name = "my_tree"
    @newick_str = ""
    # birth - death parameters
    @birth = BDPARAMS[:birth]
    @death = BDPARAMS[:death]
    @sample = BDPARAMS[:sample]
    @mut = BDPARAMS[:mut]
    @seed = rand(54245)
  end
  def birth_death_params
    @birth.to_s + " " + @death.to_s + " " + @sample.to_s + " " + @mut.to_s
  end
  def load_birth_death_params(params)
    raise "birth_death must be [#{BDKEYS.join(",")}]" unless params.split(",").size == 4
    @birth, @death, @sample, @mut = params.split(',')
  end
  def to_s
    ret = String.new 
    if @newick_str.empty?
      ret << "[TREE] #{@name}\n"
      ret << "  [unrooted] #{@ntaxa} #{birth_death_params} \n"
      ret << "  [seed] #{@seed}\n"
    else
      ret << "[TREE] #{@name}\n"
      ret << "#{@newick_str}\n"
    end
  end
end

class IndelModel
  def initialize()
    @param = INDEL_MODEL_PARAMS[:param] 
    @truc = INDEL_MODEL_PARAMS[:truc] 
    @rate = INDEL_MODEL_PARAMS[:rate] 
  end
  def load_indel_params(params)
    raise "INDEL info must be [#{IMKEYS.join ','}]" unless params.split(',').size == 3
    @param, @truc, @rate = params.split(',')
  end
  def to_s
    ret = "" 
    ret << "  [indelmodel] POW #{@param} #{@truncate}\n"
    ret << "  [insertrate] #{@rate}\n"
    ret << "  [deleterate] #{@rate}\n"
  end
end

class IndelibleControlFile
  attr_accessor :model, :indelmodel, :tree
  def initialize(filename, ntaxa, nbases)
    @filename = filename
    @model = Model.new
    @tree = Tree.new(ntaxa)
    @indelmodel = IndelModel.new 
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
  def load_indel_params(params)
    @indelmodel.load_indel_params(params)
  end
  def load_birth_death_params(params)
    @tree.load_birth_death_params(params)
  end
  def load_newick_str(str)
    @tree.newick_str = str
  end
  def to_file
    File.open(@filename, "w+") do |f|
      f.puts '[TYPE] NUCLEOTIDE 1'
      f.puts @model.to_s
      f.puts @indelmodel.to_s
      f.puts @tree.to_s
      f.puts "[PARTITIONS] #{@partitionname}"
      f.puts "  [#{@tree.name} #{@model.label} #{@nbases}]" 
      f.puts "[EVOLVE]  #{@partitionname} 1 simulatedalignment" 
    end
  end
end

