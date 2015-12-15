require "uri"
class HistoriesController < ApplicationController

  INDI_SEP = ";"
  PATH_START = ":"
  PATH_SEP = ","

  def list
  end

  def view

    # Gather the currently found ancestors...
    foundAncestorIds = []
    if cookies[:selectedAncestors] != nil
      foundAncestorIds = cookies[:selectedAncestors].split(INDI_SEP)
    end

    # ... make any changes to the list...
    changed = false
    if params["removeAll"] != nil
      foundAncestorIds = []
      changed = true
    end
    if params["add"] != nil && !foundAncestorIds.include?(params["add"])
      foundAncestorIds.push(params["add"])
      changed = true
    end
    if params["remove"] != nil
      foundAncestorIds.delete(params["remove"])
      changed = true
    end

    # ... and store the information.
    if foundAncestorIds != nil
      # We'll refresh the cookie, even if they're not making any changes.
      cookies[:selectedAncestors] = { :value => foundAncestorIds.join(INDI_SEP), :expires => 3.months.from_now }
    end

    # Look through the entire ancestry for LDS IDs, ie. find the ones who have a history on file.
    # The cookie will have the format: LDS_ID:ANCES_ID,m,f,f (eg. for history of #LDS_ID by ANCES' mother's father's father)
    lineagesForLdsIds = Hash.new
    if changed

      # retrieve IDs for upline

      newPeopleIds = foundAncestorIds
      lineageForNewPeopleIds = Hash.new
      newPeopleIds.each{ |id| lineageForNewPeopleIds[id.to_i] = [id] }
      while !newPeopleIds.empty?
        newPeople = Individual.find(newPeopleIds)
        newPeopleIds = Array.new

        # If we've found someone with a history, add to this hash.
        newPeople.each { |p| if p.lds_id != nil then lineagesForLdsIds[p.lds_id] = {:name => p.full_name, :lineage => lineageForNewPeopleIds[p.id] } end }

        # Detect loops (eg. William Parker 1614 is father's father)
        newPeople.each { 
          |p| if p.father != nil && lineageForNewPeopleIds.has_key?(p.father) 
              then 
                logger.error "Hm... " + p.father.to_s + " is already part of the ancestry: " 
                logger.error " " + lineageForNewPeopleIds[p.father].to_s 
                logger.error " " + lineageForNewPeopleIds[p.id].to_s + "f"
              end
        }
        newPeople.each { 
          |p| if p.mother != nil && lineageForNewPeopleIds.has_key?(p.mother) 
              then 
                logger.error "Hm... " + p.mother.to_s + " is already part of the ancestry: " 
                logger.error " " + lineageForNewPeopleIds[p.mother].to_s 
                logger.error " " + lineageForNewPeopleIds[p.id].to_s + "m"
              end 
        }

        # For any parent, add lineage to the hashes we're tracking.
        newPeople.each { 
          |p| if p.father != nil && !lineageForNewPeopleIds.has_key?(p.father) 
              then 
                lineageForNewPeopleIds[p.father] = lineageForNewPeopleIds[p.id] + ['f'] 
                newPeopleIds << p.father 
              end
        }
        newPeople.each { 
          |p| if p.mother != nil && !lineageForNewPeopleIds.has_key?(p.mother) 
              then 
                lineageForNewPeopleIds[p.mother] = lineageForNewPeopleIds[p.id] + ['m'] 
                newPeopleIds << p.mother 
              end
        }

      end

      idAndLineageArray = lineagesForLdsIds.collect{ | lds_id, data | lds_id + PATH_START + data[:name] + PATH_START + data[:lineage].join(PATH_SEP) }
      cookies[:allAncestorLdsIds] = { :value => idAndLineageArray.join(INDI_SEP), :expires => 3.months.from_now }

# This is the old way without tracking lineage.
#      allAncestors = []
#      while !newPeopleIds.empty?
#        newPeople = Individual.find(newPeopleIds)
#        allAncestors.concat(newPeople)
#        newPeopleIds = newPeople.collect { |p| [p.father, p.mother] } .flatten .compact
#      end
#      allAncestorLdsIds = allAncestors.collect { |p| p.lds_id } .compact

#      cookies[:allAncestorLdsIds] = { :value => allAncestorLdsIds.join(INDI_SEP), :expires => 3.months.from_now }

    else
      if cookies[:allAncestorLdsIds] != nil
        cookies[:allAncestorLdsIds].split(INDI_SEP).each { |data| 
          ldsId = data.split(PATH_START)[0]
          fullName = data.split(PATH_START)[1]
          lineage = data.split(PATH_START)[2]
          lineagesForLdsIds[ldsId] = { :name => fullName, :lineage => lineage.split(PATH_SEP) }
        }

# This is the old way without tracking lineage.
#        allAncestorLdsIds = cookies[:allAncestorLdsIds].split(INDI_SEP)
      end
    end


    # Make list with all selected ancestors.
    @foundAncestors = []
    if foundAncestorIds.length == 0
      @foundAncestorsOutput = "none"
    else

      @foundAncestors = Individual.find(:all, :conditions => ["id in (?)", foundAncestorIds])
      @foundAncestorsOutput = "<ul>"
      @foundAncestors.each { |person|
        @foundAncestorsOutput += "<li>"
        @foundAncestorsOutput += "#{person.full_name}"
        @foundAncestorsOutput += "</li>\n"
      }
      @foundAncestorsOutput += "</ul>\n"

    end



    # Make link for all those with histories.
    @historiesLineages = ""
    if foundAncestorIds.length == 0
      @diigoLink = "" #"After finding yourself or ancestors, you can look at their histories."
    else

      if lineagesForLdsIds.empty?


        @diigoLink = "We have no histories yet for any ancestors of people you've found.  <a href='http://thomas.tolmanfamily.org/history.asp'>See some other histories</a>, or even <a href='http://groups.diigo.com/groups/tolman-family'>add and highlight some more</a> (though you'll have to contact <a href='http://trentlarson.com'>Trent</a> to get them linked to this search).  If you want to see a sample, search for 'jean yvonne'."
      else

        @diigoIds = lineagesForLdsIds.keys.map{ |id| id.downcase}.join(" OR ")
        # I previously created a link thus:
        # diigoUrl = "http://groups.diigo.com/search?group_name=tolman-family&what=" + @diigoIds
        # ... then: "<a href='#{URI.escape(diigoUrl)}'>See all my ancestors' histories!</a>"

        # Now list the relationship to each person with a history.
        @historiesLineages = ""
        @historiesLineages += "Here are all your ancestors we've found who have histories online:\n"
        @historiesLineages += "<ul>"
        foundAncestorsIdsToNames = Hash.new
        @foundAncestors.each { |a| foundAncestorsIdsToNames[a.id] = a.full_name }
        lineagesForLdsIds.each { | ldsId, data |
          @historiesLineages += "<li>"
          @historiesLineages += "#{data[:name]}"
          if data[:lineage].size > 1 then
            startId = data[:lineage][0].to_i
            restRelations = data[:lineage][1..data[:lineage].size-1]
            restRelations.collect!{ |rel| if rel == 'f' then 'father' else 'mother' end }
            @historiesLineages += " who is #{foundAncestorsIdsToNames[startId]}'s #{restRelations.join('\'s ')}"
          end
          @historiesLineages += "</li>\n"
        }
        @historiesLineages += "</ul>\n"

      end

    end


    # Now list any search results.
    searchResults = []
    if !params["search"].nil?
      searchResults = Individual.find(:all, :conditions => ["full_name LIKE '%%#{params["search"]}%%'"], :order => "full_name")
    end

    if searchResults.length == 0
      @searchOutput = "none"
    else
      @searchOutput = ""
      searchResults.each { |person|
        @searchOutput += "<br/>\n"
        @searchOutput += "<a href='?add=#{person.id.to_s}'>Yes!  This is me or an ancestor of mine.</a> #{person.full_name} #{person.notes}"
      }
    end

  end

  def new
  end

  def edit
  end

end
