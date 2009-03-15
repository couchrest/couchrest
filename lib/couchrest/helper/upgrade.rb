module CouchRest
  class Upgrade
    attr_accessor :olddb, :newdb, :dbname
    def initialize dbname, old_couch, new_couch
      @dbname = dbname
      @olddb = old_couch.database dbname
      @newdb = new_couch.database!(dbname)
      @bulk_docs = []
    end
    def clone!
      puts "#{dbname} - #{olddb.info['doc_count']} docs"
      streamer  = CouchRest::Streamer.new(olddb)
      streamer.view("_all_docs_by_seq") do |row|
        load_doc_for_row(row) if row
        maybe_flush_bulks
      end
      flush_bulks!
    end
    
    private
    
    def maybe_flush_bulks
      flush_bulks! if (@bulk_docs.length > 1000)
    end
    
    def flush_bulks!
      url = CouchRest.paramify_url "#{@newdb.uri}/_bulk_docs", {:all_or_nothing => true}
      puts "posting bulk to #{url}"
      puts @bulk_docs.collect{|b|b.id}
      begin
        CouchRest.post url, {:docs => @bulk_docs}      
      rescue Exception => e
        puts e.response
      end
    end
    
    def load_doc_for_row(row)
      if row["value"]["conflicts"]
        puts "doc #{row["id"]} has conflicts #{row.inspect}"
        # load the doc, and it's conflicts
        load_conflicts_doc(row)
      elsif row["value"]["deleted_conflicts"]
        puts "doc #{row["id"]} has deleted conflicts"
      elsif row["value"]["deleted"]
        # puts "doc #{row["id"]} is deleted"
        @bulk_docs << {"_id" => row["id"], "_deleted" => true}
      else
        load_normal_doc(row)
      end
    end
    
    def load_conflicts_doc(row)
      results = @olddb.get(row["id"], {:open_revs => "all", :attachments => true})
      results.select{|r|r["ok"]}.each do |r|
        doc = r["ok"]
        doc.delete('_rev')
        @bulk_docs << doc
      end
    end
    
    def load_normal_doc(row)
      # puts row["id"]
      doc = @olddb.get(row["id"], :attachments => true)
      if /^_/.match(doc.id) && !/^_design/.match(doc.id)
        puts "trimming invalid docid #{doc.id}"
        doc["_id"] = doc.id.sub('_','')
      end
      doc.delete("_rev");
      @bulk_docs << doc
    end
  end
end
