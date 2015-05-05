
require_relative 'rakefile_common.rb'

file 'parldata.json' do
  venv_path = ENV['PARLDATA_VENV'] or raise "PARLDATA_VENV must be set to a virtualenv"
  venv_python = venv_path + "/bin/python"
  File.exist? venv_python or raise "No `python` binary found at #{venv_python}"

  [@PARLDATA].flatten.each_with_index do |house, i|
    fetcher = File.expand_path("../bin/parldataeu.py", __FILE__)
    cmd = [venv_python, fetcher, house].join ' '

    outfile = 'parldata'
    outfile << "-#{house.split('/').last}" unless i.zero?

    data = %x[ #{cmd} ]
    File.write("#{outfile}.json", data)
  end
end
CLOBBER.include('parldata.json')
  
file 'clean.json' => 'parldata.json' do
  json = JSON.load(File.read('parldata.json'), lambda { |h|
    if h.class == Hash 
      h.reject! { |_, v| v.nil? or v.empty? }
      h.reject! { |k, v| [:created_at, :updated_at, :_links].include? k }
    end
  }, { symbolize_names: true })

  json[:organizations].delete_if { |o| o[:classification] == 'committee' }
  File.write('clean.json', JSON.pretty_generate(json))
end
CLEAN.include('clean.json')

