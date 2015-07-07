#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# (C) Petr Skočík, 2015
# License: gpl2

require 'forwardable'

class Buffer 
  extend Forwardable

  def initialize
    @buf = ""
  end

  delegate [:<<, :size] => :@buf

  def gets(sep=$/)
    line, _, @buf = *@buf.partition(sep)
    return line ? line + _ : ""
  end

  def read(char_cnt)
    if char_cnt == nil
      ret = @buf
      @buf = ""
    else
      ret = @buf[0,char_cnt]
      @buf = @buf[char_cnt, @buf.size] || ""
    end
    return ret
  end
end

# Allow in-place rewriting by adding a dynamic additional buffer (=a ruby string)
#
# Everytime a write is requested, make sure what that would get overwritten is buffered up until the end of the original file
#
# Everytime a read is requested, check the buffer first

class Rewriter

  def initialize(filepath, &blk)
    @file_r = File.open(filepath, 'r')
    @file_w = File.open(filepath, 'r+')
    @file_size = @file_r.size
    @rbuffer = Buffer.new
    if block_given?
      lines(&blk)
      close
    end
  end
  def self.open(filepath,&blk)
    new(filepath,&blk)
  end
  
  def _past_original_eof?
    @file_r.tell >= @file_size
  end

  def _to_buffer(want_to_write)
    return 0 if _past_original_eof?
    can_write = @file_r.tell - @file_w.tell
    p can_write
    raise ScriptError if can_write < 0
    want_to_write - can_write
  end

  def write(string)
    buffer(_to_buffer(string.size))
    @file_w.write(string)
  end
  def read(char_cnt)
    buf_size = @rbuffer.size
    if char_cnt <= buf_size
      return @rbuffer.read(char_cnt)
    else
      from_file = !eof? && @file_r.read(char_cnt - buf_size)
      if from_file.nil?
        return nil if buf_size == 0
        buffered = @rbuffer.read(buf_size)
        return buffered
      end
    end
    return buffered + from_file
  end

  def gets(sep=$/)
    buffered = @rbuffer.gets(sep)
    return buffered if buffered =~ /#{sep}\Z/
    from_file = !eof? && @file_r.gets(sep)
    if !from_file
      return nil if buffered == ""
      return buffered
    end
    return buffered + from_file
  end

  def eof?
    @eof ||= (@rbuffer.size == 0  && @file_r.tell == @file_size)
  end

  def close
    @file_r.close
    @file_w.truncate(@file_w.tell)
    @file_w.close
  end

  private 
  def buffer(required_cnt)
    remaining = @file_size - @file_r.tell
    if required_cnt > remaining
      required_cnt = remaining
    end
    from_file = @file_r.read(required_cnt)
    @rbuffer << from_file if from_file
  end
  def lines
    i=0
    while line = gets
      transformed = yield(line,i)
      write(transformed)
      i+=1
    end
  end
end
if $0 == __FILE__
  filepath = ARGV[1]
  Rewriter.new(filepath) do |line,index|
    eval ARGV.first
  end
end
