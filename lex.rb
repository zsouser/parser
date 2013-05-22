class Lex 
  def initialize(str)
    if str.empty? 
      @str = []
    else
      code = str.split(";").first
      @str = str.split(";").first.strip.split("")
    end
    @ptr = 0
    @token = ""
  end
  def done?
    return @ptr >= @str.length
  end
  def next
    @token = ""
    while (@str[@ptr] == ' ' || @str[@ptr] == ',') do
      @ptr += 1
    end

    while (@str[@ptr] != ',' && @str[@ptr] != ' ' && @str[@ptr] != "\n" && !done?) do
      if @str[@ptr] == ':'
        @ptr += 1
        return :LABEL
      end

      @token = @token + @str[@ptr]
      @ptr += 1
      return :REG if ["r0","r1","r2","r3","r4","r5","r6","r7","R0","R1","R2","R3","R4","R5","R6","R7"].include? @token

    end
    case @token.strip
    when "MOVEI" then return :MOVEI
    when "MOVE" then return :MOVE if @str[@ptr] != "I"
    when "ADD" then return :ADD
    when "INC" then return :INC
    when "SUB" then return :SUB
    when "DEC" then return :DEC
    when "MUL" then return :MUL
    when "DIV" then return :DIV
    when "BEQ" then return :BEQ
    when "BLT" then return :BLT
    when "BGT" then return :BGT
    when "BR" then return :BR
    when "END" then return :END
    end
    num = true
    @token.strip.split("").each do |digit|
      num &= digit >= "0" && digit < "8"
    end
    return :NUM if num
    return :JUNK if @token.length > 5
    return :IDENT
  end
  def token
    @token
  end
  def line
    
    return @str.join("")
  end
end
