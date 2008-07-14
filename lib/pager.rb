# paginate though 'gcharts/mp3-trk-dom-map' view and save

# get 1000 records
# truncate so that the key of the last record is not included in the page
#  that key will be the first of the next page
# (if the last key equals the first key, up the page size)
# group the results by key
# yield the group

require File.dirname(__FILE__) + '/couchrest'

module Enumerable
  def group_by
    inject({}) do |grouped, element|
      (grouped[yield(element)] ||= []) << element
      grouped
    end
  end unless [].respond_to?(:group_by)
  
  def group_by_fast
    inject({}) do |grouped, element|
      (grouped[yield(element)] ||= []) << element
      grouped
    end
  end
end

class CouchRest
  class Pager
    attr_accessor :db
    def initialize db
      @db = db
    end
    
    def all_docs(count=100, &block)
      startkey = nil
      keepgoing = true
      oldend = nil
      
      while docrows = request_all_docs(count+1, startkey)        
        startkey = docrows.last['key']
        docrows.pop if docrows.length > count
        if oldend == startkey
          break
        end
        yield(docrows)
        oldend = startkey
      end
    end
    
    def key_reduce(view, count, firstkey = nil, lastkey = nil, &block)
      # start with no keys
      startkey = firstkey
      # lastprocessedkey = nil
      keepgoing = true
      
      while keepgoing && viewrows = request_view(view, count, startkey)
        startkey = viewrows.first['key']
        endkey = viewrows.last['key']

        if (startkey == endkey)
          # we need to rerequest to get a bigger page
          # so we know we have all the rows for that key
          viewrows = @db.view(view, :key => startkey)['rows']
          # we need to do an offset thing to find the next startkey
          # otherwise we just get stuck
          lastdocid = viewrows.last['id']
          fornextloop = @db.view(view, :startkey => startkey, :startkey_docid => lastdocid, :count => 2)['rows']

          newendkey = fornextloop.last['key']
          if (newendkey == endkey)
            keepgoing = false
          else
            startkey = newendkey
          end
          rows = viewrows
        else
          rows = []
          for r in viewrows
            if (lastkey && r['key'] == lastkey)
              keepgoing = false
              break
            end
            break if (r['key'] == endkey)
            rows << r
          end   
          startkey = endkey
        end

        grouped = rows.group_by{|r|r['key']}
        grouped.each do |k, rs|
          vs = rs.collect{|r|r['value']}
          yield(k,vs)
        end
        
        # lastprocessedkey = rows.last['key']
      end
    end

    private
    
    def request_all_docs count, startkey = nil
      opts = {}
      opts[:count] = count if count
      opts[:startkey] = startkey if startkey      
      results = @db.documents(opts)
      rows = results['rows']
      rows unless rows.length == 0
    end

    def request_view view, count = nil, startkey = nil, endkey = nil
      opts = {}
      opts[:count] = count if count
      opts[:startkey] = startkey if startkey
      opts[:endkey] = endkey if endkey
      
      results = @db.view(view, opts)
      rows = results['rows']
      rows unless rows.length == 0
    end

  end
end