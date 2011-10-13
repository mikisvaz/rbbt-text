require 'rbbt/util/misc'
require 'tokyocabinet'

module DocumentRepo
  class OpenError < StandardError;end
  class KeyFormatError < StandardError;end

  TC_CONNECTIONS = {}
  def self.open_tokyocabinet(path, write)
    write = true if not File.exists?(path)
    flags = (write ? TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT : TokyoCabinet::BDB::OREADER)

    FileUtils.mkdir_p File.dirname(path) unless File.exists?(File.dirname(path))

    database = TC_CONNECTIONS[path] ||= TokyoCabinet::BDB.new
    database.close

    if !database.open(path, flags)
      ecode = database.ecode
      raise "Open error: #{database.errmsg(ecode)}. Trying to open file #{path}"
    end

    class << database
      attr_accessor :writable, :persistence_path

      def read
        return if not @writable
        self.close
        if !self.open(@persistence_path, TokyoCabinet::BDB::OREADER)
          ecode = self.ecode
          raise "Open error: #{self.errmsg(ecode)}. Trying to open file #{@persistence_path}"
        end
        @writable = false
        self
      end

      def write
        return if @writable
        self.close
        if !self.open(@persistence_path, TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT)
          ecode = self.ecode
          raise "Open error: #{self.errmsg(ecode)}. Trying to open file #{@persistence_path}"
        end
        @writable = true
        self
      end

      def write?
        @writable
      end

      def collect
        res = []
        each do |key, value|
          res << if block_given?
                   yield key, value
          else
            [key, value]
          end
        end
        res
      end

      def delete(key)
        out(key)
      end

      def values_at(*keys)
        keys.collect do |key|
          self[key]
        end
      end

      def merge!(hash)
        hash.each do |key,values|
          self[key] = values
        end
      end

    end

    database.persistence_path ||= path

    database.extend DocumentRepo

    database
  end

  def docid2fields(docid)
    docid.split(":", -1).values_at 0,1,2,3
  end

  def fields2docid(namespace = nil, id = nil, type = nil, hash = nil)
    [namespace, id, type, hash] * ":"
  end

  def docid(docid)
    get(docid)
  end

  def add(text, namespace, id, type, hash)
    read
    write unless write?
    docid = fields2docid(namespace, id, type, hash)
    self[docid] = text unless self.include? docid
    read
    docid
  end

  def find(namespace=nil, id = nil, type = nil, hash = nil)
    case
    when namespace.nil?
      self.keys
    when id.nil?
      range_start = [namespace] * ":" + ':'
      range_end   = [namespace] * ":" + ';'
      self.range(range_start, true, range_end, false)
    when (type and hash)
      [[namespace, id, type, hash] * ":"]
    when hash
      [[namespace, id, "", hash] * ":"]
    when type
      range_start = [namespace, id, type] * ":" + ':'
      range_end   = [namespace, id, type] * ":" + ';'
      self.range(range_start, true, range_end, false)
    else
      range_start = [namespace, id] * ":" + ':'
      range_end   = [namespace, id] * ":" + ';'
      self.range(range_start, true, range_end, false)
    end
  end

  def find_docid(docid)
    find(*docid2fields(docid))
  end

end
