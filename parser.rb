#!/usr/bin/env ruby
require "lex.rb"
class Parser
  def initialize(filename)
    @fileName = filename
    @valid = true
    @end = false
    @branchesUsed = []
    @validBranches = []
    @errors = { "Wrong Operand Type" => [], "Too Few Operands" => [], "Invalid Opcode" => [], "Too Many Operands" => [], "Ill-Formed Operand" => []}
    @lineNum = 0
    @file = File.open("output-#{@fileName}","w")
    write "Welcome to the MAL interpreter. Below is the program with errors shown.\n\nAuthor: Zach Souser\nClass: CS 3210\n"

    IO.foreach(@fileName) do |line|
      parseLine line
    end

    write "\n\n-------------------------------\n\n"
    @errors.each do |group, list|
      @valid &= list.count == 0
      write "#{group} - #{list.count}\n"
    end
    @branchesUsed.each do |branch|
      @valid &= @validBranches.include? branch
      write "\n\n***** Branch #{branch} is invalid.\n" unless @valid
    end
    write "\n\n\nTotal number of lines: #{@lineNum}\n\n"
    write "This MAL code is "
    write @valid ? "VALID" : "INVALID"
    
    @file.close
  end
  def write str
    @file.write str
    puts str
  end
  def parseLine (line, print=true) 
    @lex = Lex.new line
    line = @lex.line
    return if line.empty?
    return if @lex.done?
    @lineNum += 1
    nxt = @lex.next
    write "#{line}\n" if print
    case nxt
    when :LABEL then doLabel line.split(":",2)[1].strip
    when :MOVEI then doMoveI
    when :MOVE then doMove
    when :ADD then doMath
    when :INC then doSingle
    when :SUB then doMath
    when :DEC then doSingle
    when :MUL then doMath
    when :DIV then doMath
    when :BEQ then doConditionalBranch
    when :BLT then doConditionalBranch
    when :BGT then doConditionalBranch
    when :BR then doBranch
    when :END then doEnd
    else invalid_opcode nxt
    end

  end
  def doMove
    oper1 = @lex.next
    if oper1 == :REG || oper1 == :IDENT
      oper2 = @lex.next
      if oper2 == :REG || oper2 == :IDENT
        return if @lex.done?
        extra = 0
        while !@lex.done? do
          nxt = @lex.next
          extra += 1 unless nxt == :COMMENT
        end
        too_many_operands extra + 2, 2
      elsif oper2 == :NUM
      	wrong_operand_type oper2
      else
        ill_formed_operand oper2
      end
    elsif oper1 == :NUM
      wrong_operand_type oper1
    else
      ill_formed_operand oper1
    end
  end
  def doMoveI
    oper1 = @lex.next
    if oper1 == :NUM
      oper2 = @lex.next
      if oper2 == :REG || oper2 == :IDENT
        return if @lex.done?
        extra = 0
        while !@lex.done? do
          @lex.next
          extra += 1
        end
        too_many_operands extra + 2, 2
      elsif oper2 == :NUM
      	wrong_operand_type oper2
      else
        ill_formed_operand oper2
      end
    elsif oper1 == :IDENT || oper1 == :REG
      wrong_operand_type oper1
    else
      ill_formed_operand oper1
    end
  end
  def doMath
    oper1 = @lex.next
    puts @lex.token
    if oper1 == :REG || oper1 == :IDENT
      return too_few_operands 1, 3 if @lex.done?
      oper2 = @lex.next
      if oper2 == :REG || oper2 == :IDENT
        return too_few_operands 2, 3 if @lex.done?
        oper3 = @lex.next
        if oper3 == :REG || oper3 == :IDENT
          return if @lex.done?
          extra = 0
          while !@lex.done? do
            nxt = @lex.next
            extra += 1 unless nxt == :COMMENT
          end
          too_many_operands extra + 3, 2
        elsif oper3 == :NUM
          wrong_operand_type oper3
        else
          ill_formed_operand oper3
        end
      elsif oper2 == :NUM
        wrong_operand_type oper2
      else
        ill_formed_operand oper2
      end
    elsif oper1 == :NUM
      wrong_operand_type oper1
    else
      ill_formed_operand oper1
    end  
  end
  def doSingle
    nxt = @lex.next
    if nxt == :REG || nxt == :IDENT
      return if @lex.done?
      extra = 0
      while !@lex.done? do
        @lex.next
        extra += 1
      end
      too_many_operands 1 + extra, 1
    elsif nxt == :NUM
      wrong_operand_type nxt
    else
      ill_formed_operand nxt
    end
  end
  def doBranch
    nxt = @lex.next
    if nxt == :IDENT
      @branchesUsed.push @lex.token
      return if @lex.done?
      extra = 0
      while !@lex.done? do
        @lex.next
        extra += 1
      end
      too_many_operands 1 + extra, 1
    elsif nxt == :NUM
      wrong_operand_type nxt
    else
      ill_formed_operand nxt
    end
  end
  def doConditionalBranch
    oper1 = @lex.next
    if oper1 == :REG || oper1 == :IDENT
      return too_few_operands 1, 3 if @lex.done?
      oper2 = @lex.next
      if oper2 == :REG || oper2 == :IDENT
        return too_few_operands 2, 3 if @lex.done?
        oper3 = @lex.next
        if oper3 == :REG || oper3 == :IDENT
          return if @lex.done?
          extra = 0
          while !@lex.done? do
            @lex.next
            extra += 1
          end
          too_many_operands extra + 3, 2
        elsif oper3 == :NUM
          wrong_operand_type oper3
        else
          ill_formed_operand oper3
        end
      elsif oper2 == :NUM
        wrong_operand_type oper2
      else
        ill_formed_operand oper2
      end
    elsif oper1 == :NUM
      wrong_operand_type oper1
    else
      ill_formed_operand oper1
    end
  end
  def doEnd
   	too_many_operands 1, 0 unless @lex.done?
  end
  def doLabel line
    @validBranches.push @lex.token
    parseLine line, false
  end
  def invalid_opcode code
    (@errors["Invalid Opcode"]).push @lineNum
    write "--> Invalid opcode #{code}\n"
  end
  def ill_formed_operand oper
    (@errors["Ill-Formed Operand"]).push @lineNum
    write "--> Ill formed operand #{oper}\n"
  end
  def too_few_operands act, exp
    (@errors["Too Few Operands"]).push @lineNum
    write "--> Too few operands. Found #{act} expected #{exp}\n"
  end
  def too_many_operands act, exp
    (@errors["Too Many Operands"]).push @lineNum
    write "--> Too many operands. Found #{act} expected #{exp}\n"
  end
  def wrong_operand_type type
  	(@errors["Wrong Operand Type"]).push @lineNum
  	write "--> Wrong operand type. Found #{type}\n"
  end
end

p = Parser.new(ARGV[0]) if ARGV.length >= 1
