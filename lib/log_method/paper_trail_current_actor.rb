class LogMethod::PaperTrailCurrentActor
  def self.call
    PaperTrail.request.whodunnit
  end
end

