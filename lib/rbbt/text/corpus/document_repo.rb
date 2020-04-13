require 'rbbt/util/misc'
require 'tokyocabinet'

class Corpus
  module DocumentRepo
    class OpenError < StandardError;end
    class KeyFormatError < StandardError;end

    TC_CONNECTIONS = {}
    def self.open_tokyocabinet(path, write)
      database = Persist.open_tokyocabinet(path, write, :single, TokyoCabinet::BDB)
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
      docid = fields2docid(namespace, id, type, hash)

      return docid if self.include?(docid)

      write_and_close do
        self[docid] = text
      end

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
end
