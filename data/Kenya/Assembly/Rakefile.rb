require_relative '../../../rakefile_popit.rb'

@POPIT = 'kenyan-politicians'
@LEGISLATURE = {
  name: 'National Assembly',
  seats: 400,
}

namespace :whittle do
  task :no_orphaned_memberships => :clean_orphaned_people
    
  task :delete_unwanted_orgs => :load do
    puts "Starting with #{@json[:organizations].count} orgs"
    keep = @json[:organizations].find_all { |o| o[:classification] == 'Political Party' }.map { |o| o[:id] }
    keep << 'core_organisation:1' # Parliament itself

    @json[:memberships].keep_if   { |m| keep.include? m[:organization_id] }
    @json[:organizations].keep_if { |o| keep.include? o[:id] }
    @json[:organizations].each do |o| 
      o[:classification] = 'party' if o[:classification] == 'Political Party'
      o[:classification] = 'legislature' if o[:id] == 'core_organisation:1'
    end
    puts "Ending with #{@json[:organizations].count} orgs"
  end

  # Delete anyone who has no Memberships to Parliament itself
  task :clean_orphaned_people => :delete_unwanted_orgs do
    puts "Starting with #{@json[:persons].count} people"
    @json[:persons].keep_if { |p| 
      @json[:memberships].find { |m| m[:person_id] == p[:id] and m[:organization_id] == 'core_organisation:1' }
    }
    puts "Ending with #{@json[:persons].count} people"
  end

  # task :write => :remove_interest_register
  # task :remove_interest_register => :clean_orphaned_people do
    # @json[:persons].each { |p| p.delete :interests_register }
  # end

end
  

