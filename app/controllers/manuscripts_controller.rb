class ManuscriptsController < ApplicationController

  before_action :set_manuscript, only: [:show, :edit, :entry_candidates]

  def entry_candidates
    @candidate_ids = @manuscript.entry_candidates
    respond_to do |format|
      format.json
    end
  end

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

end
