####################################
# USAGE
#
# in your rack.rb file
# require this file and then:
#
# couch = CouchRest.new
# LOG_DB = couch.database!('couchrest-logger')
# use CouchRest::Logger, LOG_DB
# 
# Note:
# to require just this middleware, if you have the gem installed do:
# require 'couchrest/middlewares/logger'
#
# For log processing examples, see examples at the bottom of this file

module CouchRest
  class Logger 
    
    def self.log
      Thread.current["couchrest.logger"] ||= {:queries => []}
    end
        
    def initialize(app, db=nil)
      @app = app
      @db = db
    end
    
    def self.record(log_info)
      log[:queries] << log_info
    end
    
    def log
      Thread.current["couchrest.logger"] ||= {:queries => []}
    end
    
    def reset_log
      Thread.current["couchrest.logger"] = nil
    end
 
    def call(env)
      reset_log
      log['started_at'] = Time.now
      log['env'] = env
      log['url'] = 'http://' + env['HTTP_HOST'] + env['REQUEST_URI'] 
      response = @app.call(env)
      log['ended_at'] = Time.now
      log['duration'] = log['ended_at'] - log['started_at']
      # let's report the log in a different thread so we don't slow down the app
      @db ? Thread.new(@db, log){|db, rlog| db.save_doc(rlog);} : p(log.inspect)
      response
    end
  end
end

# inject our logger into CouchRest HTTP abstraction layer
module HttpAbstraction
 
  def self.get(uri, headers=nil)
    start_query = Time.now
    log = {:method => :get, :uri => uri, :headers => headers}
    response = super(uri, headers=nil)
    end_query = Time.now
    log[:duration] = (end_query - start_query)
    CouchRest::Logger.record(log)
    response
  end 
  
  def self.post(uri, payload, headers=nil)
    start_query = Time.now
    log = {:method => :post, :uri => uri, :payload =>  (payload ? (JSON.load(payload) rescue 'parsing error') : nil), :headers => headers}
    response = super(uri, payload, headers=nil)
    end_query = Time.now
    log[:duration] = (end_query - start_query)
    CouchRest::Logger.record(log)
    response
  end
   
  def self.put(uri, payload, headers=nil)
    start_query = Time.now
    log = {:method => :put, :uri => uri, :payload => (payload ? (JSON.load(payload) rescue 'parsing error') : nil), :headers => headers}
    response = super(uri, payload, headers=nil)
    end_query = Time.now
    log[:duration] = (end_query - start_query)
    CouchRest::Logger.record(log)
    response
  end
  
  def self.delete(uri, headers=nil)
    start_query = Time.now
    log = {:method => :delete, :uri => uri, :headers => headers}
    response = super(uri, headers=nil)
    end_query = Time.now
    log[:duration] = (end_query - start_query)
    CouchRest::Logger.record(log)
    response
  end   
  
end 


# Advanced usage example 
#
#
# # DB VIEWS 
# by_url = {
#   :map => 
#     "function(doc) {
#       if(doc['url']){ emit(doc['url'], 1) };
#     }",
#  :reduce => 
#     'function (key, values, rereduce) {
#        return(sum(values));
#     };'
# }
# req_duration = {
#   :map => 
#     "function(doc) {
#       if(doc['duration']){ emit(doc['url'], doc['duration']) };
#     }",
#  :reduce => 
#     'function (key, values, rereduce) {
#        return(sum(values)/values.length);
#     };'
# }
# 
# query_duration = {
#   :map => 
#     "function(doc) {
#           if(doc['queries']){ 
#             doc.queries.forEach(function(query){
#     if(query['duration'] && query['method']){ 
#               emit(query['method'], query['duration'])
#     }
#             });
#           };
#          }" ,
#    :reduce => 
#       'function (key, values, rereduce) {
#         return(sum(values)/values.length);
#       };'
# }
# 
# action_queries = {
#   :map => 
#     "function(doc) {
#           if(doc['queries']){
#              emit(doc['url'], doc['queries'].length)
#           };
#          }",
#  :reduce => 
#     'function (key, values, rereduce) {
#       return(sum(values)/values.length);
#     };'
# }  
# 
# action_time_spent_in_db = {
#   :map => 
#     "function(doc) {
#           if(doc['queries']){
#             var totalDuration = 0;
#             doc.queries.forEach(function(query){
#               totalDuration += query['duration']
#             })
#              emit(doc['url'], totalDuration)
#           };
#          }",
#  :reduce => 
#     'function (key, values, rereduce) {
#       return(sum(values)/values.length);
#     };'
# }
# 
# show_queries =  %Q~function(doc, req) {
#                    var body = ""
#                    body += "<h1>" + doc['url'] + "</h1>"
#                    body += "<h2>Request duration in seconds: " + doc['duration'] + "</h2>"
#                    body += "<h3>" + doc['queries'].length + " queries</h3><ul>"
#                    if (doc.queries){
#                      doc.queries.forEach(function(query){
#                        body += "<li>"+ query['uri'] +"</li>"
#                      });
#                    };
#                    body += "</ul>"
#                    if(doc){ return { body: body} }
#                  }~
# 
# 
# couch = CouchRest.new
# LOG_DB = couch.database!('couchrest-logger')   
# design_doc = LOG_DB.get("_design/stats") rescue nil
# LOG_DB.delete_doc design_doc rescue nil
# LOG_DB.save_doc({
#   "_id" => "_design/stats",
#   :views => {
#     :by_url           => by_url,
#     :request_duration => req_duration,
#     :query_duration   => query_duration,
#     :action_queries   => action_queries,
#     :action_time_spent_in_db => action_time_spent_in_db
#   },
#  :shows => {
#    :queries => show_queries
#  }
# })
# 
# module CouchRest
#   class Logger
#     
#     def self.roundup(value)
#       begin
#         value = Float(value)
#         (value * 100).round.to_f / 100
#       rescue
#         value
#       end
#     end
#     
#     # Usage example:
#     # CouchRest::Logger.average_request_duration(LOG_DB)['rows'].first['value']
#     def self.average_request_duration(db)
#       raw = db.view('stats/request_duration', :reduce => true)
#       (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end
#     
#     def self.average_query_duration(db)
#       raw =  db.view('stats/query_duration', :reduce => true)
#       (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end   
#     
#     def self.average_get_query_duration(db)
#       raw = db.view('stats/query_duration', :key => 'get', :reduce => true)
#       (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end  
#     
#     def self.average_post_query_duration(db)
#       raw = db.view('stats/query_duration', :key => 'post', :reduce => true)
#       (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end 
#     
#     def self.average_queries_per_action(db)
#       raw = db.view('stats/action_queries', :reduce => true)
#       (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end
#     
#     def self.average_db_time_per_action(db)
#      raw = db.view('stats/action_time_spent_in_db', :reduce => true)
#      (raw.has_key?('rows') && !raw['rows'].empty?) ? roundup(raw['rows'].first['value']) : 'not available yet'
#     end
#     
#     def self.stats(db)
#       Thread.new(db){|db|
#         puts "===  STATS  ===\n"
#         puts "average request duration: #{average_request_duration(db)}\n"
#         puts "average query duration: #{average_query_duration(db)}\n"
#         puts "average queries per action : #{average_queries_per_action(db)}\n"
#         puts "average time spent in DB (per action): #{average_db_time_per_action(db)}\n"
#         puts "===============\n"   
#      }
#     end
#     
#   end
# end             