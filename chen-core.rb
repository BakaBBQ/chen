require 'google'

require 'erb'
require 'open-uri'
require 'CGI'

require_relative 'config'
module Chen; end

class String
  def numeric? 
    Float(self) != nil rescue false
  end unless method_defined?(:numberic?)
end

class Fixnum
  def numeric?
    return true
  end
end


Chen::SearchResult = Struct.new(:title, :url, :desc, :number)
Chen::Template = <<HERE
  {
      "estimated_results": "<%=results.estimated%>",
      "query_results": [
  		<%results.each do |r|%>
  		{
  			"title": 	"<%=r.title%>",
  			"url":		"<%=r.url%>",
  			"desc":		"<%=r.desc%>",
  			"number":	"<%=r.number%>"
  		}
  		<%unless r == results.last%>
  		,
  		<%end%>
  		<%end%>
		
  	]
  }
HERE

class Chen::Results < Array
  attr_accessor :estimated
  attr_accessor :query_string
end

class Chen::RemoteQuery
  attr_accessor  :default_host
  def default_host
    return @default_host || CHEN_CONFIG.default_host
  end
  
  def raw_query(url)
    content = open url
    return content.read
  end
  
  def query_with_params(host, keyword, page_number = 1, size = 8)
    keyword = CGI::escape(keyword)
    if(default_host && host.empty?)
      host = default_host
    end
    return raw_query("#{host}/api?str=#{keyword}&page=#{page_number}&number=#{size}")
  end
end



class Chen::Google < Google
  class << self
    def query(str, page_number = 1, size = 8)
      options = {
        page: page_number,
        size: size,
        readability: true,
        markdown: true
      }
      
      query_object = Chen::Google.new(str,options)
      
      return query_object.to_results
    end
    
    def query_to_json(str, page_number = 1, size = 10)
      if page_number == 0
        page_number = 1
      end
      
      results = query(str, page_number, size)
      doc = ERB.new(Chen::Template)
      return doc.result(binding)
    end
  end
  
  #copied mostly from the "show" method
  def to_results
    info = request :q => @query, :rsz => @opts[:size], :start => ((@opts[:page] - 1) * @opts[:size])
    results           = info[:results]
    query_strings     = info[:query_strings]
    coder             = HTMLEntities.new
    if(results['responseData']['cursor']['currentPageIndex'].nil?)
      new_one = Chen::Results.new
      new_one.estimated = 0
      return new_one
    end
    
      
    current_page      = results['responseData']['cursor']['currentPageIndex']+1
    max_result        = query_strings[:start] + query_strings[:rsz]
    estimated_results = results['responseData']['cursor']['resultCount']
    result_array      = results['responseData']['results']
    
    datas = Chen::Results.new
    datas.estimated = estimated_results
    result_array.each_with_index do |result, i|
      new_data = Chen::SearchResult.new
      new_data.tap do |d|
        d.title = result["titleNoFormatting"]
        d.url = result["url"]
        d.desc = result["content"].squeeze(" ")
        d.number = (i + query_strings[:start] + 1)
      end
      datas << new_data
    end
    return datas
  end
  
end
