#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'chen-core.rb'
require 'sinatra'
require 'json'
require 'haml'
class ChenApiServer < Sinatra::Application
  set :bind, '0.0.0.0'
  set :port, 4567
  get '/' do
    haml :index
  end
  
  get '/api' do
    str = params[:str] || ''
    page = params[:page] || 1
    number = params[:number] || 8
    page = 1 unless page.numeric?
    number = 8 unless number.numeric?
    return Chen::Google.query_to_json(str, page.to_i, number.to_i)
  end
  
  get '/search' do
    str = params[:str] || ''
    page = params[:page] || 1
    number = params[:number] || 8
    @memory_time = Time.now
    q = Chen::RemoteQuery.new
    @json_result = q.query_with_params('', str, page, number)
    @parsed_result = JSON.parse @json_result.delete("\n").delete("\t")
    @current_page = page
    @current_str = str
    haml :search
  end
  
  get '/test' do
    params[:search]
  end
  
end
ChenApiServer.run!

