require 'stringio'
# TODO: タイトル末尾に CR が残ってしまう

class AozoraParser
  class ParseError < StandardError; end
  attr_reader :title, :author, :lines

  CR, LF = 13, 10
  HEAD_NOTE_REGEXP = /^---/
  BODY_IGNORES = []
  BODY_REMOVES = []

  def initialize
    @lines = []
  end

  def parse(arg)
    if arg.is_a? IO
      parse!(arg)
    elsif arg.is_a? String
      parse!(StringIO.new(arg))
    else
      raise ArgumentError 
    end
  end

  def parse!(io)
    spos = parse_head(io)
    if io.gets =~ HEAD_NOTE_REGEXP
      spos = parse_head_note(io)
    end
    epos = parse_foot(io)
    parse_body(io, spos, epos)
  end

  def parse_head(io)
    str = io.gets("\r\n\r\n")
    raise ParseError, 'too short lines.' if !str
    lines = str.split("\n")
    raise ParseError, 'too short lines.' if lines.size < 2
    @title, @author = lines
    io.pos
  end

  def parse_head_note(io)
    while line = io.gets
      return io.pos if line =~ HEAD_NOTE_REGEXP
    end
    raise ParseError, ''
  end

  def parse_foot(io)
    io.seek(0, IO::SEEK_END)
    buf = []
    while true 
      io.seek(-1, IO::SEEK_CUR)
      c = io.getc
      io.ungetc(c)
      buf << c
      buf.shift if buf.length == 9
      if buf == [10, 13, 10, 13, 10, 13, 10, 13]
        return io.pos
      end
    end
  end

  def parse_body(io, spos, epos)
    io.pos = spos
    while io.pos < epos
      line = io.gets
      line.chomp!
      # 行頭全角スペースは普通に省いちゃだめっぽい、数を検討する
      next if line == /^［＃(.*?)］$/u || line == ''
      line.gsub!(/^　+/, '')
      line.gsub!(/［＃(.*?)］/u, '')
      line.gsub!(/《(.*?)》/u, '')
      @lines << line
    end
  end

  def sentences
    sentences = []
    @lines.each do |line|
      line.gsub!(/(「.+?」)/u) do |m|
        m.gsub!(/。/, '.')
        m
      end
      line.split(/。/u).each do |s|
        s.gsub!(/\./, '。')
        sentences << s
      end
    end
    sentences
  end
end

