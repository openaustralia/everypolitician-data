#!/bin/env ruby
# encoding: utf-8

#---------------------------------------------------------------------
# This should really be a scraper on morph but it blows its memory
# limits, so for now will just run locally
#---------------------------------------------------------------------

require 'colorize'
require 'csv'
require 'open-uri'
require 'pry'
# require 'scraperwiki'
require 'set'
require 'yajl/json_gem'

def json_load(file)
  JSON.parse(open(file).read, symbolize_names: true)
end

@terms = CSV.table('../terms.csv')

file = 'twfy.json' # or take remote filename
@json = json_load(file)
posts = @json[:posts].find_all { |p| p[:organization_id] == 'house-of-commons' }
@json[:memberships].delete_if { |m| m.key?(:start_date) && m[:start_date] < '1997-05-01' }

#----------



def display_name(name)
  if name.key? :lordname
    display = "#{name[:honorific_prefix]} #{name[:lordname]}"
    display += " of #{name[:lordofname]}" unless name[:lordofname].to_s.empty?
    return display
  end
  name[:given_name] + " " + name[:family_name]
end

def name_at(p, date)
  date = DateTime.now.to_date.to_s if date.to_s.empty?
  at_date = p[:other_names].find_all { |n| 
    n[:note].to_s == 'Main' && (n[:end_date] || '9999-99-99') >= date && (n[:start_date] || '0000-00-00') <= date 
  }
  raise "Too many names at #{date}: #{at_date}" if at_date.count > 1
  return display_name(at_date.first)
end

def term_id(m)
  s_date = m[:start_date]
  e_date = m[:end_date] || '2100-01-01'
  matched = @terms.find_all { |t| (s_date >= t[:start_date]) and (e_date <= (t[:end_date] || '2100-01-01')) }
  return matched.first[:id] if matched.count == 1
  puts "Too many terms".green if matched.count > 1
  puts "No terms".green if matched.count.zero?
  binding.pry
end


post_ids = posts.map { |p| p[:id] }.to_set

rows = @json[:memberships].find_all { |m| post_ids.include?  m[:post_id] }.map do |m|
  person = @json[:persons].find { |p| p[:id] == m[:person_id] }
  party  = @json[:organizations].find { |o| o[:id] == m[:on_behalf_of_id] }
  post   = @json[:posts].find { |p| p[:id] == m[:post_id] }

  data = {
    id: person[:id].split('/').last,
    name: name_at(person, m[:start_date]),
    identifier__historichansard: person[:identifiers].to_a.find(->{{}}) { |id| id[:scheme] == 'historichansard_person_id' }[:identifier],
    identifier__datadotparl: person[:identifiers].to_a.find(->{{}}) { |id| id[:scheme] == 'datadotparl_id' }[:identifier],
    constituency: post[:area][:name],
    constituency_id: post[:id],
    party: party[:name],
    party_id: party[:id],
    start_date: m[:start_date],
    start_reason: m[:start_reason],
    end_date: m[:end_date],
    end_reason: m[:end_reason],
    term: m[:legislative_period_id] || term_id(m),
  }
end

puts rows.first.keys.to_csv
puts rows.map { |r| r.values.to_csv }



