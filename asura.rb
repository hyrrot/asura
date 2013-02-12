# -*- coding: utf-8 -*-

require 'pty'
require 'expect'
require 'debugger'

#$expect_verbose = true

module Asura

  class IOTee
    attr_reader :io
    def initialize(io)
      @io = io
    end

    def read
      result = @io.read
      STDOUT.print result
      result
    end

    def method_missing(action, *args)
      @io.__send__ action, *args
    end
 
  end


  class AsuraCommand
    attr_reader :reader, :writer
    
    DEFAULT_PROMPT = /[\$#%]/

    def method_missing(cmd, *args)
      send_and_wait_prompt("#{cmd} #{args.join(' ')}")
    end

    def initialize(reader, writer, prompt = DEFAULT_PROMPT)
      @reader, @writer = reader, writer
      @prompts = [DEFAULT_PROMPT]
    end

    def prompt
      @prompts.last
    end

    # Add a new prompt to the prompt stack.
    def push_prompt(new_prompt)
      @prompts.push(new_prompt)
    end

    def pop_prompt
      @prompts.pop
    end
      
    def send_and_wait_prompt(str,timeout=9999999)
      send_and_wait(str, prompt, timeout)
    end

    def send_and_wait(str, pattern, timeout=9999999)
      self.writer.puts str
      self.writer.flush
      wait(pattern,timeout)
    end

    def send_and_capture(str, timeout=9999999)
      self.writer.puts str
      wait(str)
      wait(prompt, timeout)
    end

    def send(str)
      self.writer.puts str
    end

    def wait(str,timeout=9999999)
      result = self.reader.expect(str,timeout=9999999)
      raise RuntimeError unless result #FIXIT : Design of exceptions
      #STDOUT.print(result[0])
      result
    end


    def self.session(cmd)
      PTY.getpty(cmd) do |reader, writer|
        r = IOTee.new(reader)
        writer.sync = true
        yield self.new(r, writer)
      end
    end

    def generate_prompt
      array = (("a".."z").to_a + ("0".."9").to_a).join
      result = "__"
      32.times do
        result << array[rand(array.length)]
      end
      result << "__"
      result
    end

    def sudo_su(option,password=nil)
      self.send("sudo su #{option}")
      state = :INIT
      until state == :COMPLETED
        case state
          when :INIT
            result = self.wait(/([Pp]assword( for [a-zA-Z0-9]+)?: )|([#\$%] )/)
            case result[1]
              when /[\$#%] /
                state = :COMPLETED
              when /([Pp]assword( for [a-zA-Z0-9]+)?: )/
                state = :PASSWORD
            end
          when :PASSWORD
            raise RuntimeError unless password
            self.send_and_wait_prompt(password)
            state = :COMPLETED
        end
      end
      yield
      self.wait(prompt)
      self.send("exit")
    end

    def self.ssh(host,password=nil)
      self.session("ssh #{host}") do |pty|
        # Connect and log into host
        state = :INIT
        until state == :COMPLETED
          case state
            when :INIT
              result = pty.wait(/[\$#%]|(password: )|(\(yes\/no\)\? )/)
              case result[1]
                when /[\$#%]/
                  state = :COMPLETED
                when /password: /
                  state = :PASSWORD
                when /\(yes\/no\)\? /
                  state = :YESNO
              end
            when :PASSWORD
              raise RuntimeError unless password
              pty.send_and_wait_prompt(password)
              state = :COMPLETED
            when :YESNO
              result = pty.send_and_wait("yes", /[\$#%]|(password: )/)
              case result[1]
                when /[\$#%]/
                  state = :COMPLETED
                when /password: /
                  state = :PASSWORD
              end
          end
        end
        yield self.new(pty.reader, pty.writer)
      end
    end

    def bash(option="")
      send_and_wait("bash #{option}", DEFAULT_PROMPT)
      new_prompt = generate_prompt
      new_prompt_re = /#{Regexp.escape(new_prompt)}/
      send_and_wait_prompt("TERM=dumb")
      send_and_wait_prompt("export TERM")
      yield
      self.send "exit"
    end
  end
end


