module Segment::RangeIndex
  attr_accessor :corpus

  def [](*args)
    res = super(*args)
    SegID.setup(res, :corpus => corpus)
  end

  def self.index(segments, corpus = nil, persist_file = :memory)
    segments = segments.values.flatten if Hash === segments

    annotation_index = 
      Persist.persist("Segment_index", :fwt, :persist => (! (persist_file.nil? or persist_file == :memory)), :file => persist_file) do

        value_size = 0
        index_data = segments.collect{|segment| 
          next if segment.offset.nil?
          range = segment.range
          value_size = [segment.segid.length, value_size].max
          [segment.segid, [range.begin, range.end]]
        }.compact

        fwt = FixWidthTable.get :memory, value_size, true
        fwt.add_range index_data

        fwt
      end

    annotation_index.extend Segment::RangeIndex
    annotation_index.corpus = corpus
    annotation_index
  end

end
  
