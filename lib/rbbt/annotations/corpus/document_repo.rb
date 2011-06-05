require 'rbbt/util/misc'
require 'tokyocabinet'

class DocumentRepo < TokyoCabinet::BDB
  class OpenError < StandardError;end
  class KeyFormatError < StandardError;end

  CONNECTIONS = {}

  def self.get(path, write = false)

    if !File.exists?(path) or not CONNECTIONS.include? path
      CONNECTIONS[path] = self.new(path, true)
    end

    d = CONNECTIONS[path] 
    
    if write and not d.write?
      d.write
    else
      d.read if d.write?
    end

    d
  end


  alias original_open open
  def open(write = false)
    flags = (write ? TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT : TokyoCabinet::BDB::OREADER)

    FileUtils.mkdir_p File.dirname(@path_to_db) unless File.exists?(File.dirname(@path_to_db))
    if !self.original_open(@path_to_db, flags)
      ecode = self.ecode
      raise OpenError, "Open error: #{self.errmsg(ecode)}. Trying to open file #{@path_to_db}"
    end

    @write = write

  end

  def write?
    @write
  end

  def write
    self.close
    self.open(true)
  end

  def read
    self.close
    self.open(false)
  end

  def initialize(path, write = false)
    super()

    @path_to_db = path

    if write || ! File.exists?(@path_to_db)
      self.setcache(100000) or raise "Error setting cache"
      self.open(true)
    else
      self.open(false)
    end
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
    write unless write?
    docid = fields2docid(namespace, id, type, hash)
    self[docid] = text unless self.include? docid
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
