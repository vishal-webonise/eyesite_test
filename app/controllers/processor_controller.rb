class ProcessorController < ApplicationController
  layout false
  def create
    rpt = {}
    if params[:drillid].present?
      rpt.merge!(params).symbolize_keys!.delete_if{|k,v| [:action, :controller, :format].include? k }
      eObj = {}
      eObj[:scoreStart] = rpt[:scoreEnd]
      session[:regimenStart] = rpt[:scoreStart] unless session[:regimenStart].present?
      drillNames = ["eyeRoute", "eyeMotion", "eyeTrack", "eyeFocus", "eyeSpeed", "eyeRecall", "eyeMemory"]
      drills = [50874, 51042, 50875, 50876, 50877, 50878, 50879]
      drillid = params[:drillid].to_i
      for x in 0...drills.size
        break if drillid == drills[x]
        next
      end
      # x is the index of which drill we just trained - having found it above. We increment it (below) to move to the next drill at the same level.
      x = x + 1
      eObj[:instruction] = "Instructions for #{drillNames[x]}"
      # eStr is a string to be written back to the client as the value of "levelEnded" - the text to display to the user. We load it up as we flow through logic below..
      eStr = ""
      if(rpt[:mode] == "PRACTICE")
        eStr += "\n\nPRACTICE MODE<br/><font size='9'>Click 'CONTINUE' or press the spacebar to redo this level.</font>"
      elsif(rpt[:score].to_i == 0) #(bonus && rpt[:bonus].to_i == 0)
        eObj[:lives] = eObj[:lives].to_i
        eStr += "\n\nPLAY MODE<br/><font size='11'>Didn't do so hot eh?"
        # lives - what to do when exhausted
        if(rpt[:lives].to_i == 0)
          eStr += "No more lives. Game over. We're going to start your regimen over.<br/>Click 'CONTINUE' or press the spacebar to begin."
          x = 0
          eObj[:scoreStart] = session[:regimenStart]
          eObj[:drillid] = drills[x]
          eObj[:drillName] = drillNames[x]
        else
          eStr+="I'm taking a life.. better try this level over.<br/>Click 'CONTINUE' or press the spacebar to redo this level.</font>"
          eObj[:lives] = rpt[:lives] - 1
        end
        eObj[:scoreStart] = rpt[:scoreStart]
      else
        eObj[:scoreStart] = rpt[:scoreEnd]
        # eStr="\n\n Don't get discouraged, this means we have found your training level."+
        # " Click 'Redo Level' or press the spacebar to try again. "+
        # "\ndrillid="+params[:drillid]+
        # "\nlevel="+params[:level]
      end
      # if there is a next-drill at this level, send back it's id. Otherwise, offer to proceed to next level.
      if drills[x]
        if rpt[:fail].to_i == 0
          eStr += "\n\nWell done."
        else
          eStr += "\n\nLevel complete for #{rpt[:drillName]}."
        end
        eStr += "\n\n<b>#{drillNames[x]}</b> is your next drill.\n"+
                "Click 'CONTINUE' or press the spacebar to load the next drill. "
                # + "\n\n(drillid=#{params[:drillid]}"
                # + "\n\n(next drillid=#{eObj[:drillid]})"
                # + "\n(level=#{rpt[:level]})"
      else
        eObj[:scoreStart] = rpt[:scoreEnd]
        if rpt[:level.to_i == 9]
          eStr+="\nCongratulations.\n\n"+
                "You have finished the Vision Gain regimen at the hightest level.\n"+
                "Your final score is <b>#{rpt[:scoreEnd]}</b>\n."+
                "Click 'CONTINUE' or press the spacebar to redo this level."
        else
          eObj[:level] = rpt[:level].to_i + 1
          eObj[:scoreStart] = 0
          eStr += "\nStarting <b>#{drillNames[x]}</b> at Level #{eObj[:level].to_i}"
        end
      end

      eObj[:drillid] = drills[x]
      eObj[:drillName] = drillNames[x] # t("eObj[:levelEnded] "+eObj[:levelEnded])

      eObj[:levelEnded] = eStr
      # eObj now contains all the info the drill needs to move the the next drill / offer to redo the level or move to the next level. We write it to the client as name/value below.
      eStr = ""
      for item in eObj
        logger.info { " #{item}" }
        eStr += "#{item[0].to_s}=#{item[1]}&"
      end
      logger.info { "FINAL: #{eStr}" }
      respond_to do |format|
        format.all { render text: eStr }
      end
    end
  end
end

