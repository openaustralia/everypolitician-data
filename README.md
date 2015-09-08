# everypolitician-data

This repo contains the data powering [EveryPolitician.org](http://everypolitician.org/), and other sites such as [Gender-Balance.org](gender-balance.org)

Information on how to _use_ the data can be found at http://everypolitician.org/technical.html, and high-level information about how to contribute is at http://everypolitician.org/contribute.html

This document is for developers actively working _on_ the project, rather than consuming data from it.

## Adding a new country

1. Make a new subdirectory in `data` named for the Country

    If this is for a legislature that does not map cleanly to an ISO 3166-1 country code (e.g. Wales, Kosovo), or you name the directly differently from what the Ruby [iso_country_codes gem understands](https://github.com/alexrabarts/iso_country_codes/blob/master/lib/iso_country_codes/iso_3166_1.rb) (e.g. Congo-Brazzaville), you will also need to supply a `meta.json` (see those examples for details)

2. Make a separate subdirectory within the Country for each distinct legislature or chamber

    i.e. both the upper and lower houses of a bicameral legislature should have separate directories, as should successor bodies (e.g. in Libya, the National Transitional Council, General National Congress, and Council of Deputies are all distinct).

3. Add a `meta.json` for the legislature. This *must* include fields for the legislature `name`, and how many `seats` it currently has. It *should* also contain a `wikidata` reference code. See, for example, [Poland](https://github.com/everypolitician/everypolitician-data/blob/master/data/Poland/Sejm/meta.json)

4. Provide a `Rakefile.rb` that knows how to build the data. This is an overly complicated process at the moment, because we’re in the middle of a transition from a simpler, older approach, to a more complex but more flexible approach. We’ve now gotten rid of the old approach, but haven’t yet successfully simplified the new one. The basic concept is that you provide instructions on how to generate or download some CSV files (at a mimimum a single file of Membership information and a file of Legislative Period / Term information), and these are them combined, turned into a consistent JSON format (based on Popolo), and then split up again into a series of period-based CSVs. This requires:

    1. A single line `Rakefile.rb`

      ```require_relative '../../../rakefile_local.rb'```

    2. A single line `sources/Rakefile.rb`

      ```require_relative '../../../../rakefile_merged.rb'```

    3. A `sources/instructions.json` file listing the data sources, and how to combine them. Proper documentation on this will follow later, but [the Australian House of Representatives](https://github.com/everypolitician/everypolitician-data/blob/master/data/Australia/Representatives/sources/instructions.json) is a reasonably good example to work from. 

## Building the data for a legislature

1. From within the `sources` directory for the legislature it should usually be enough to run `rake clean && bundle exec rake`. If you want to fetch fresh data from the source(s) (e.g. Morph.io), then use `rake clobber && bundle exec rake` instead.

2. Then, from within the main (i.e. parent) directory for the legislature, you should run the `rake clean && bundle exec rake` again. (These first two steps will be combined into a single step RSN).

3. Make sure that the changes look sensible, and then commit the new/refreshed data.

4. From the root directory of the project run `bundle exec rake` again. This updates the master `countries.json` map with this new information (and includes the sha of the commit, so needs to be run *after* step 3)

