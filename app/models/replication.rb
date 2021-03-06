class Replication < ActiveRecord::Base
  validates_presence_of :study_id, :replicating_study_id
  validates :study_id, :uniqueness => {:scope => :replicating_study_id}
  validate :study_id_does_not_equal_replicating_study_id

  belongs_to :owner, :class_name => 'User', :foreign_key => :owner_id
  belongs_to :study, touch: true
  belongs_to :replicating_study, :class_name => 'Study', :foreign_key => :replicating_study_id

  def as_json(opts={})
    super(opts).tap do |h|
      h[:replicating_study] = replicating_study.as_json(:authors => opts[:authors], :year => opts[:year], :comments => opts[:comments], :model_updates => opts[:model_updates]) if opts[:replications]
      h[:study] = study.as_json(:authors => opts[:authors], :year => opts[:year], :comments => opts[:comments], :model_updates => opts[:model_updates]) if opts[:replication_of]
      h
    end
  end

  private

  def study_id_does_not_equal_replicating_study_id
    errors.add(:replicating_study_id, "must be different from study_id") if study_id == replicating_study_id
  end
end
